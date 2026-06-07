import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Nominatim (OpenStreetMap) 免费地理编码服务
/// 无需 API Key，限 1 次/秒
class NominatimService {
  static final NominatimService instance = NominatimService._();
  NominatimService._();

  static const String _baseUrl = 'https://nominatim.openstreetmap.org';
  static const String _userAgent = 'BearBill/1.1.0 (Flutter)';

  /// 反向地理编码: 经纬度 → 地址（WGS84 坐标）
  Future<NominatimAddress?> reverseGeocode(double lat, double lon) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/reverse?format=jsonv2&lat=$lat&lon=$lon&zoom=18&addressdetails=1&accept-language=zh-CN',
      );
      final resp = await http.get(url, headers: {
        'User-Agent': _userAgent,
      }).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data['error'] != null) return null;

        final addr = data['address'] ?? {};
        return NominatimAddress(
          formattedAddress: data['display_name'] ?? '',
          province: addr['state'] ?? addr['province'] ?? '',
          city: addr['city'] ?? addr['town'] ?? addr['county'] ?? '',
          district: addr['suburb'] ?? addr['district'] ?? addr['city_district'] ?? '',
          township: addr['neighbourhood'] ?? addr['residential'] ?? '',
          street: addr['road'] ?? '',
          number: addr['house_number'] ?? '',
          name: data['name'] ?? '',
        );
      }
    } catch (e) {
      if (kDebugMode) print('Nominatim 反向编码异常: $e');
    }
    return null;
  }

  /// 搜索地点: 关键词 → 地点列表
  Future<List<NominatimPoi>> searchPoi(String keyword, {double? lat, double? lon}) async {
    try {
      String urlStr =
          '$_baseUrl/search?q=${Uri.encodeComponent(keyword)}&format=jsonv2&limit=10&accept-language=zh-CN&addressdetails=1';
      if (lat != null && lon != null) {
        urlStr += '&viewbox=${lon - 0.05},${lat + 0.05},${lon + 0.05},${lat - 0.05}&bounded=1';
      }
      final resp = await http.get(Uri.parse(urlStr), headers: {
        'User-Agent': _userAgent,
      }).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as List;
        return data.map((poi) {
          return NominatimPoi(
            name: poi['display_name']?.toString().split(',').first ?? '',
            address: poi['display_name'] ?? '',
            type: poi['type']?.toString() ?? '',
            lat: double.tryParse(poi['lat']?.toString() ?? '0') ?? 0,
            lon: double.tryParse(poi['lon']?.toString() ?? '0') ?? 0,
            distance: '',
          );
        }).toList();
      }
    } catch (e) {
      if (kDebugMode) print('Nominatim 搜索异常: $e');
    }
    return [];
  }

  /// 周边搜索: 经纬度 → 附近 POI
  Future<List<NominatimPoi>> searchAround(double lat, double lon, {String? keyword}) async {
    final query = keyword ?? '地点';
    return searchPoi(query, lat: lat, lon: lon);
  }
}

/// Nominatim 地址信息
class NominatimAddress {
  final String formattedAddress;
  final String province;
  final String city;
  final String district;
  final String township;
  final String street;
  final String number;
  final String name;

  NominatimAddress({
    required this.formattedAddress,
    required this.province,
    required this.city,
    required this.district,
    required this.township,
    required this.street,
    required this.number,
    this.name = '',
  });

  String get shortAddress {
    final parts = <String>[];
    if (district.isNotEmpty) parts.add(district);
    if (township.isNotEmpty) parts.add(township);
    if (street.isNotEmpty) parts.add(street);
    if (number.isNotEmpty) parts.add(number);
    return parts.isEmpty ? formattedAddress : parts.join();
  }

  String get fullAddress => formattedAddress;
}

/// Nominatim POI 信息
class NominatimPoi {
  final String name;
  final String address;
  final String type;
  final double lat;
  final double lon;
  final String distance;

  NominatimPoi({
    required this.name,
    required this.address,
    required this.type,
    required this.lat,
    required this.lon,
    this.distance = '',
  });
}
