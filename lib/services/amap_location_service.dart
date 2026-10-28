import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart' as config;
import 'api_quota_service.dart';

/// AMap (Gaode) Web API service
/// Register at https://lbs.amap.com and apply for a Web Service API Key before use
/// The key is configured in lib/config/api_keys.dart (already in .gitignore)
class AmapLocationService {
  static final AmapLocationService instance = AmapLocationService._();
  AmapLocationService._();

  static String get _apiKey => config.amapApiKey;

  /// Convert GCJ-02 coordinates to WGS84 (inverse conversion, approximate algorithm)
  static (double lat, double lon) gcj02ToWgs84(double lat, double lon) {
    final gcj = wgs84ToGcj02(lat, lon);
    return (lat * 2 - gcj.$1, lon * 2 - gcj.$2);
  }

  /// Convert WGS84 coordinates to GCJ-02 (China's national surveying coordinate system)
  /// The AMap API requires GCJ-02, while GPS returns WGS84
  static (double lat, double lon) wgs84ToGcj02(double lat, double lon) {
    const double a = 6378245.0; // Semi-major axis of the Krasovsky 1940 ellipsoid
    const double ee = 0.00669342162296594; // Squared eccentricity

    double dLat = _transformLat(lon - 105.0, lat - 35.0);
    double dLon = _transformLon(lon - 105.0, lat - 35.0);
    double radLat = lat / 180.0 * pi;
    double magic = sin(radLat);
    magic = 1 - ee * magic * magic;
    double sqrtMagic = sqrt(magic);
    dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * pi);
    dLon = (dLon * 180.0) / (a / sqrtMagic * cos(radLat) * pi);
    return (lat + dLat, lon + dLon);
  }

  static double _transformLat(double x, double y) {
    double ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y +
        0.1 * x * y + 0.2 * sqrt(x.abs());
    ret += (20.0 * sin(6.0 * x * pi) + 20.0 * sin(2.0 * x * pi)) * 2.0 / 3.0;
    ret += (20.0 * sin(y * pi) + 40.0 * sin(y / 3.0 * pi)) * 2.0 / 3.0;
    ret += (160.0 * sin(y / 12.0 * pi) + 320 * sin(y * pi / 30.0)) * 2.0 / 3.0;
    return ret;
  }

  static double _transformLon(double x, double y) {
    double ret = 300.0 + x + 2.0 * y + 0.1 * x * x +
        0.1 * x * y + 0.1 * sqrt(x.abs());
    ret += (20.0 * sin(6.0 * x * pi) + 20.0 * sin(2.0 * x * pi)) * 2.0 / 3.0;
    ret += (20.0 * sin(x * pi) + 40.0 * sin(x / 3.0 * pi)) * 2.0 / 3.0;
    ret += (150.0 * sin(x / 12.0 * pi) + 300.0 * sin(x / 30.0 * pi)) * 2.0 / 3.0;
    return ret;
  }

  /// Reverse geocoding: coordinates → address (pass WGS84; converted to GCJ-02 internally)
  /// extensions=all also returns nearby POIs (residential areas, shops, landmarks, etc.)
  Future<AmapAddress?> reverseGeocode(double lat, double lon) async {
    // Check quota
    final quota = await ApiQuotaService.instance.checkAmapQuota();
    if (!quota.allowed) {
      if (kDebugMode) print('高德 API 配额已用完: ${quota.message}');
      return null;
    }

    try {
      final gcj = wgs84ToGcj02(lat, lon);
      final url = Uri.parse(
        'https://restapi.amap.com/v3/geocode/regeo'
        '?key=$_apiKey&location=${gcj.$2},${gcj.$1}&extensions=all&output=json',
      );
      final resp = await http.get(url).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data['status'] == '1' && data['regeocode'] != null) {
          // Record usage
          await ApiQuotaService.instance.recordAmapUsage();
          return AmapAddress.fromRegeo(data['regeocode']);
        } else {
          if (kDebugMode) print('高德反向编码失败: ${data['info'] ?? data}');
        }
      }
    } catch (e) {
      if (kDebugMode) print('高德反向编码异常: $e');
    }
    return null;
  }

  /// POI search: keyword → list of places
  /// [gcjLat]/[gcjLon] are GCJ-02 coordinates (AMap system) used for distance sorting
  Future<List<AmapPoi>> searchPoi(String keyword, {double? gcjLat, double? gcjLon}) async {
    // Check quota
    final quota = await ApiQuotaService.instance.checkAmapQuota();
    if (!quota.allowed) {
      if (kDebugMode) print('高德 API 配额已用完: ${quota.message}');
      return [];
    }

    try {
      String urlStr =
          'https://restapi.amap.com/v3/place/text'
          '?key=$_apiKey&keywords=${Uri.encodeComponent(keyword)}&output=json&offset=10';
      // Pass GCJ-02 coordinates straight to the AMap API (no conversion needed)
      if (gcjLat != null && gcjLon != null) {
        urlStr += '&location=$gcjLon,$gcjLat&sortrule=distance';
      }
      final resp = await http.get(Uri.parse(urlStr)).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data['status'] == '1' && data['pois'] != null) {
          // Record usage
          await ApiQuotaService.instance.recordAmapUsage();
          return (data['pois'] as List).map((poi) {
            final loc = (poi['location'] ?? '').toString().split(',');
            return AmapPoi(
              name: poi['name'] ?? '',
              address: poi['address'] ?? '',
              type: poi['type'] ?? '',
              lon: double.tryParse(loc.isNotEmpty ? loc[0] : '0') ?? 0,
              lat: double.tryParse(loc.length > 1 ? loc[1] : '0') ?? 0,
              distance: poi['distance']?.toString() ?? '',
            );
          }).toList();
        } else {
          if (kDebugMode) print('高德POI搜索失败: ${data['info'] ?? data}');
        }
      }
    } catch (e) {
      if (kDebugMode) print('高德POI搜索异常: $e');
    }
    return [];
  }

  /// Nearby search: coordinates → nearby POIs (pass WGS84; converted to GCJ-02 internally)
  Future<List<AmapPoi>> searchAround(double lat, double lon, {String? keyword}) async {
    try {
      final gcj = wgs84ToGcj02(lat, lon);
      String urlStr =
          'https://restapi.amap.com/v3/place/around'
          '?key=$_apiKey&location=${gcj.$2},${gcj.$1}&output=json&offset=20&sortrule=distance';
      if (keyword != null && keyword.isNotEmpty) {
        urlStr += '&keywords=${Uri.encodeComponent(keyword)}';
      }
      final resp = await http.get(Uri.parse(urlStr)).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data['status'] == '1' && data['pois'] != null) {
          return (data['pois'] as List).map((poi) {
            final loc = (poi['location'] ?? '').toString().split(',');
            return AmapPoi(
              name: poi['name'] ?? '',
              address: poi['address'] ?? '',
              type: poi['type'] ?? '',
              lon: double.tryParse(loc.isNotEmpty ? loc[0] : '0') ?? 0,
              lat: double.tryParse(loc.length > 1 ? loc[1] : '0') ?? 0,
              distance: poi['distance']?.toString() ?? '',
            );
          }).toList();
        }
      }
    } catch (e) {
      if (kDebugMode) print('高德周边搜索异常: $e');
    }
    return [];
  }

  /// Whether the API key is configured
  bool get isConfigured => _apiKey != 'YOUR_AMAP_API_KEY';
}

/// Safe string access: some AMap fields (e.g. city for municipalities) return an array, so fall back to an empty string
String _str(dynamic value) => value is String ? value : '';

/// AMap address info
class AmapAddress {
  final String formattedAddress;
  final String province;
  final String city;
  final String district;
  final String township;
  final String street;
  final String number;
  final List<String> nearbyPois;

  AmapAddress({
    required this.formattedAddress,
    required this.province,
    required this.city,
    required this.district,
    required this.township,
    required this.street,
    required this.number,
    this.nearbyPois = const [],
  });

  /// Parse from the AMap regeo response (city is an empty array for municipalities, hence the safe fallback)
  factory AmapAddress.fromRegeo(Map<dynamic, dynamic> regeocode) {
    final component = (regeocode['addressComponent'] ?? {}) as Map;
    final pois = <String>[];
    for (final poi in ((regeocode['pois'] ?? []) as List).take(5)) {
      final name = poi['name']?.toString() ?? '';
      if (name.isNotEmpty) pois.add(name);
    }
    for (final aoi in ((regeocode['aois'] ?? []) as List).take(3)) {
      final name = aoi['name']?.toString() ?? '';
      if (name.isNotEmpty && !pois.contains(name)) pois.add(name);
    }
    final streetNumber = (component['streetNumber'] ?? {}) as Map;
    return AmapAddress(
      formattedAddress: _str(regeocode['formatted_address']),
      province: _str(component['province']),
      city: _str(component['city']),
      district: _str(component['district']),
      township: _str(component['township']),
      street: _str(streetNumber['street']),
      number: _str(streetNumber['number']),
      nearbyPois: pois,
    );
  }

  /// Get the short address (without the province/city prefix)
  String get shortAddress {
    final parts = <String>[];
    if (district.isNotEmpty) parts.add(district);
    if (township.isNotEmpty) parts.add(township);
    if (street.isNotEmpty) parts.add(street);
    if (number.isNotEmpty) parts.add(number);
    return parts.isEmpty ? formattedAddress : parts.join();
  }

  /// Get the full address
  String get fullAddress => formattedAddress;
}

/// AMap POI info
class AmapPoi {
  final String name;
  final String address;
  final String type;
  final double lat;
  final double lon;
  final String distance;

  AmapPoi({
    required this.name,
    required this.address,
    required this.type,
    required this.lat,
    required this.lon,
    required this.distance,
  });
}
