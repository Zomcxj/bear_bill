import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart' as config;
import 'api_quota_service.dart';

/// 高德地图 Web API 服务
/// 使用前请到 https://lbs.amap.com 注册并申请 Web 服务 API Key
/// 密钥配置在 lib/config/api_keys.dart（已加入 .gitignore）
class AmapLocationService {
  static final AmapLocationService instance = AmapLocationService._();
  AmapLocationService._();

  static String get _apiKey => config.amapApiKey;

  /// GCJ-02 坐标转 WGS84 坐标（逆向转换，近似算法）
  static (double lat, double lon) gcj02ToWgs84(double lat, double lon) {
    final gcj = wgs84ToGcj02(lat, lon);
    return (lat * 2 - gcj.$1, lon * 2 - gcj.$2);
  }

  /// WGS84 坐标转 GCJ-02 坐标（国测局坐标系）
  /// 高德 API 要求 GCJ-02 坐标，GPS 返回 WGS84 坐标
  static (double lat, double lon) wgs84ToGcj02(double lat, double lon) {
    const double a = 6378245.0; // 克拉索夫斯基椭球长半轴
    const double ee = 0.00669342162296594; // 偏心率平方

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

  /// 反向地理编码: 经纬度 → 地址（传入 WGS84 坐标，内部自动转换为 GCJ-02）
  /// extensions=all 会返回附近 POI（小区、商店、地标等）
  Future<AmapAddress?> reverseGeocode(double lat, double lon) async {
    // 检查配额
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
          // 记录使用次数
          await ApiQuotaService.instance.recordAmapUsage();
          final regeocode = data['regeocode'];
          final addressComponent = regeocode['addressComponent'] ?? {};

          // 提取附近 POI（小区、商店、地标）
          final pois = <String>[];
          final poisData = regeocode['pois'] as List<dynamic>? ?? [];
          for (final poi in poisData.take(5)) {
            final name = poi['name']?.toString() ?? '';
            if (name.isNotEmpty) pois.add(name);
          }
          // 也提取 AOI（更精确的建筑/小区）
          final aoisData = regeocode['aois'] as List<dynamic>? ?? [];
          for (final aoi in aoisData.take(3)) {
            final name = aoi['name']?.toString() ?? '';
            if (name.isNotEmpty && !pois.contains(name)) pois.add(name);
          }

          return AmapAddress(
            formattedAddress: regeocode['formatted_address'] ?? '',
            province: addressComponent['province'] ?? '',
            city: addressComponent['city'] ?? '',
            district: addressComponent['district'] ?? '',
            township: addressComponent['township'] ?? '',
            street: (addressComponent['streetNumber'] ?? {})['street'] ?? '',
            number: (addressComponent['streetNumber'] ?? {})['number'] ?? '',
            nearbyPois: pois,
          );
        } else {
          if (kDebugMode) print('高德反向编码失败: ${data['info'] ?? data}');
        }
      }
    } catch (e) {
      if (kDebugMode) print('高德反向编码异常: $e');
    }
    return null;
  }

  /// POI 搜索: 关键词 → 地点列表
  /// [gcjLat]/[gcjLon] 为 GCJ-02 坐标（高德坐标系），用于距离排序
  Future<List<AmapPoi>> searchPoi(String keyword, {double? gcjLat, double? gcjLon}) async {
    // 检查配额
    final quota = await ApiQuotaService.instance.checkAmapQuota();
    if (!quota.allowed) {
      if (kDebugMode) print('高德 API 配额已用完: ${quota.message}');
      return [];
    }

    try {
      String urlStr =
          'https://restapi.amap.com/v3/place/text'
          '?key=$_apiKey&keywords=${Uri.encodeComponent(keyword)}&output=json&offset=10';
      // 直接传 GCJ-02 坐标给高德 API（无需转换）
      if (gcjLat != null && gcjLon != null) {
        urlStr += '&location=$gcjLon,$gcjLat&sortrule=distance';
      }
      final resp = await http.get(Uri.parse(urlStr)).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data['status'] == '1' && data['pois'] != null) {
          // 记录使用次数
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

  /// 周边搜索: 经纬度 → 附近 POI（传入 WGS84 坐标，内部自动转换为 GCJ-02）
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

  /// 是否已配置 API Key
  bool get isConfigured => _apiKey != 'YOUR_AMAP_API_KEY';
}

/// 高德地址信息
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

  /// 获取简短地址（不包含省、市前缀）
  String get shortAddress {
    final parts = <String>[];
    if (district.isNotEmpty) parts.add(district);
    if (township.isNotEmpty) parts.add(township);
    if (street.isNotEmpty) parts.add(street);
    if (number.isNotEmpty) parts.add(number);
    return parts.isEmpty ? formattedAddress : parts.join();
  }

  /// 获取完整地址
  String get fullAddress => formattedAddress;
}

/// 高德 POI 信息
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
