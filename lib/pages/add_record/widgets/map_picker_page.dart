import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../../services/amap_location_service.dart';
import '../../../theme/app_theme.dart';

/// 地图选点页面 - 类似微信位置选择
class MapPickerPage extends StatefulWidget {
  final LatLng? initialCenter;
  final String? initialName;

  const MapPickerPage({super.key, this.initialCenter, this.initialName});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  static const MethodChannel _locationChannel =
      MethodChannel('bear_bill/location');

  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  LatLng _center = const LatLng(39.9042, 116.4074); // GCJ-02 坐标，用于地图显示
  String _address = '';
  String _placeName = '';
  bool _isLoading = false;
  bool _isSearching = false;
  bool _isLocating = false; // GPS 定位进行中标记
  List<Map<String, dynamic>> _searchResults = [];
  Timer? _searchDebounce;
  Timer? _geocodeDebounce;

  @override
  void initState() {
    super.initState();
    if (widget.initialCenter != null) {
      // initialCenter 来自 GPS (WGS84)，转为 GCJ-02 用于地图显示
      final gcj = AmapLocationService.wgs84ToGcj02(
        widget.initialCenter!.latitude,
        widget.initialCenter!.longitude,
      );
      _center = LatLng(gcj.$1, gcj.$2);
      _placeName = widget.initialName ?? '';
      // 传入原始 WGS84 坐标用于 API 查询
      _reverseGeocode(widget.initialCenter!);
    } else {
      _locateMe();
    }
  }

  /// 定位到当前位置
  Future<void> _locateMe() async {
    _isLocating = true;
    setState(() => _isLoading = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        _showMsg('请先开启系统定位服务');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (permission == LocationPermission.deniedForever) {
          await Geolocator.openAppSettings();
        }
        _showMsg('请允许位置权限以获取定位');
        return;
      }

      // 优先使用上次已知位置（快速返回）
      Position? position = await Geolocator.getLastKnownPosition();

      // 如果没有缓存位置，再请求实时定位（多次尝试，精度递减）
      // forceAndroidLocationManager=true 避免依赖 Google Play Services（国产手机兼容性更好）
      if (position == null) {
        final accuracies = [
          LocationAccuracy.high,
          LocationAccuracy.medium,
          LocationAccuracy.low,
        ];
        for (final acc in accuracies) {
          try {
            position = await Geolocator.getCurrentPosition(
              desiredAccuracy: acc,
              timeLimit: const Duration(seconds: 15),
              forceAndroidLocationManager: true,
            );
            break;
          } catch (_) {}
        }
      }

      if (position != null) {
        // GPS 返回 WGS84 坐标，转换为 GCJ-02 用于地图显示
        final gcj = AmapLocationService.wgs84ToGcj02(position.latitude, position.longitude);
        final latLng = LatLng(gcj.$1, gcj.$2);
        setState(() {
          _center = latLng;
        });
        _mapController.move(latLng, 16);
        // 传入原始 WGS84 坐标用于 API 查询
        await _reverseGeocode(LatLng(position.latitude, position.longitude));
      } else {
        _showMsg('未获取到定位结果，请手动选择位置');
      }
    } catch (e) {
      _showMsg('定位失败，请手动选择位置');
    } finally {
      _isLocating = false;
      setState(() => _isLoading = false);
    }
  }

  /// 反向地理编码：坐标 → 地址
  Future<void> _reverseGeocode(LatLng point) async {
    try {
      String? address;

      // 优先使用高德 API（中国地址精准，含附近 POI）
      final amap = AmapLocationService.instance;
      if (amap.isConfigured) {
        final result = await amap.reverseGeocode(point.latitude, point.longitude);
        if (result != null) {
          address = result.fullAddress;
          if (mounted && _placeName.isEmpty) {
            // 优先用最近的 POI 名称（小区、商店、地标）
            if (result.nearbyPois.isNotEmpty) {
              _placeName = result.nearbyPois.first;
            } else {
              _placeName = result.shortAddress;
            }
          }
        }
      }

      // 回退: Android 原生 Geocoder
      if ((address == null || address.trim().isEmpty) && Platform.isAndroid) {
        try {
          address = await _locationChannel.invokeMethod<String>(
            'reverseGeocode',
            {'latitude': point.latitude, 'longitude': point.longitude},
          );
        } catch (_) {}
      }

      // 回退: Nominatim
      if (address == null || address.trim().isEmpty) {
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse'
          '?format=jsonv2&lat=${point.latitude}&lon=${point.longitude}'
          '&accept-language=zh-CN,zh',
        );
        final resp = await http.get(url, headers: {
          'User-Agent': 'bear_bill/1.0',
        }).timeout(const Duration(seconds: 8));
        if (resp.statusCode == 200) {
          final data = json.decode(resp.body);
          address = data['display_name'] as String?;
        }
      }

      if (mounted) {
        setState(() {
          _address = address ?? '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
          if (_placeName.isEmpty) {
            _placeName = _address;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _address = '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
        });
      }
    }
  }

  /// 搜索地点
  Future<void> _searchPlace(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);
    try {
      List<Map<String, dynamic>> results = [];

      // 优先使用高德 POI 搜索（中国 POI 数据最全）
      final amap = AmapLocationService.instance;
      if (amap.isConfigured) {
        // 地图中心已经是 GCJ-02，直接传给高德 API
        final pois = await amap.searchPoi(
          query,
          gcjLat: _center.latitude,
          gcjLon: _center.longitude,
        );
        for (final poi in pois) {
          results.add({
            'name': poi.name,
            'address': poi.address,
            'lat': poi.lat,
            'lon': poi.lon,
            'distance': poi.distance,
          });
        }
      }

      // 回退: Android 原生 Geocoder（返回 WGS84，需转 GCJ-02）
      if (results.isEmpty && Platform.isAndroid) {
        try {
          final List<dynamic>? addresses = await _locationChannel.invokeMethod(
            'searchLocation',
            {'query': query},
          );
          if (addresses != null && addresses.isNotEmpty) {
            for (final addr in addresses) {
              final wgsLat = (addr['latitude'] as num).toDouble();
              final wgsLon = (addr['longitude'] as num).toDouble();
              final gcj = AmapLocationService.wgs84ToGcj02(wgsLat, wgsLon);
              results.add({
                'name': addr['featureName'] ?? addr['addressLine'] ?? query,
                'address': addr['addressLine'] ?? '',
                'lat': gcj.$1,
                'lon': gcj.$2,
              });
            }
          }
        } catch (_) {}
      }

      // 回退: Nominatim（返回 WGS84，需转 GCJ-02）
      if (results.isEmpty) {
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search'
          '?format=jsonv2&q=${Uri.encodeComponent(query)}'
          '&limit=10&accept-language=zh-CN,zh',
        );
        final resp = await http.get(url, headers: {
          'User-Agent': 'bear_bill/1.0',
        }).timeout(const Duration(seconds: 8));
        if (resp.statusCode == 200) {
          final List<dynamic> data = json.decode(resp.body);
          for (final item in data) {
            final wgsLat = double.tryParse(item['lat']?.toString() ?? '') ?? 0;
            final wgsLon = double.tryParse(item['lon']?.toString() ?? '') ?? 0;
            final gcj = AmapLocationService.wgs84ToGcj02(wgsLat, wgsLon);
            results.add({
              'name': item['display_name']?.split(',')?.first ?? query,
              'address': item['display_name'] ?? '',
              'lat': gcj.$1,
              'lon': gcj.$2,
            });
          }
        }
      }

      if (mounted) {
        setState(() => _searchResults = results);
      }
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  /// 选择搜索结果
  void _selectSearchResult(Map<String, dynamic> result) {
    final latLng = LatLng(result['lat'], result['lon']);
    setState(() {
      _center = latLng;
      _placeName = result['name'] ?? '';
      _address = result['address'] ?? '';
      _searchResults = [];
      _searchController.clear();
    });
    _mapController.move(latLng, 16);
  }

  /// 确认选择（返回 WGS84 坐标）
  void _confirmSelection() {
    final name = _placeName.isNotEmpty ? _placeName : _address;
    // 地图中心是 GCJ-02，转回 WGS84 存储
    final wgs84 = AmapLocationService.gcj02ToWgs84(_center.latitude, _center.longitude);
    Navigator.pop(context, {
      'name': name,
      'address': _address,
      'latitude': wgs84.$1,
      'longitude': wgs84.$2,
    });
  }

  void _showMsg(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 地图
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 16,
              onPositionChanged: (pos, hasGesture) {
                _center = pos.center;
                // 仅在用户手动拖动地图时触发反向地理编码
                if (hasGesture) {
                  setState(() => _placeName = '');
                  _geocodeDebounce?.cancel();
                  _geocodeDebounce = Timer(const Duration(milliseconds: 500), () {
                    final wgs84 = AmapLocationService.gcj02ToWgs84(
                      _center.latitude, _center.longitude,
                    );
                    _reverseGeocode(LatLng(wgs84.$1, wgs84.$2));
                  });
                }
              },
              onMapReady: () {
                // 仅在编辑模式（有初始坐标）时立即编码，GPS 定位模式由 _locateMe() 处理
                if (widget.initialCenter != null && !_isLocating) {
                  final wgs84 = AmapLocationService.gcj02ToWgs84(_center.latitude, _center.longitude);
                  _reverseGeocode(LatLng(wgs84.$1, wgs84.$2));
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://webrd0{s}.is.autonavi.com/appmaptile?lang=zh_cn&size=1&scale=1&style=8&x={x}&y={y}&z={z}',
                subdomains: const ['1', '2', '3', '4'],
                userAgentPackageName: 'com.bearbill.bear_bill',
                maxZoom: 18,
              ),
            ],
          ),

          // 中心定位标记（固定不动）
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    _placeName.isNotEmpty ? _placeName : '拖动地图选择位置',
                    style: TextStyle(
                      fontSize: 12,
                      color: _placeName.isNotEmpty
                          ? AppTheme.textPrimary
                          : AppTheme.textHint,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.location_on,
                  color: AppTheme.primary,
                  size: 40,
                  shadows: const [
                    Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                // 底部阴影圆
                Container(
                  width: 16,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),

          // 顶部搜索栏
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: '搜索地点',
                            border: InputBorder.none,
                            hintStyle: TextStyle(fontSize: 15),
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          textInputAction: TextInputAction.search,
                          onSubmitted: _searchPlace,
                          onChanged: (v) {
                            _searchDebounce?.cancel();
                            if (v.trim().isEmpty) {
                              setState(() => _searchResults = []);
                            } else {
                              _searchDebounce = Timer(
                                const Duration(milliseconds: 500),
                                () => _searchPlace(v),
                              );
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.search,
                          color: _isSearching ? AppTheme.textHint : AppTheme.primary,
                        ),
                        onPressed: () => _searchPlace(_searchController.text),
                      ),
                    ],
                  ),
                ),

                // 搜索结果列表
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    constraints: const BoxConstraints(maxHeight: 240),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final r = _searchResults[index];
                        return ListTile(
                          dense: true,
                          leading: Icon(Icons.place, color: AppTheme.primary, size: 20),
                          title: Text(
                            r['name'] ?? '',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            r['distance'] != null && r['distance'] != ''
                                ? '${r['address'] ?? ''} · ${r['distance']}m'
                                : (r['address'] ?? ''),
                            style: TextStyle(fontSize: 12, color: AppTheme.textHint),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _selectSearchResult(r),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // 右下角按钮组
          Positioned(
            right: 16,
            bottom: 120,
            child: Column(
              children: [
                // 定位按钮
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.my_location, color: AppTheme.primary),
                    onPressed: _isLoading ? null : _locateMe,
                  ),
                ),
              ],
            ),
          ),

          // 底部信息栏 + 确认按钮
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.place, color: AppTheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _placeName.isNotEmpty ? _placeName : '未知位置',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_address.isNotEmpty && _address != _placeName)
                              Text(
                                _address,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textHint,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '坐标: ${_center.latitude.toStringAsFixed(5)}, ${_center.longitude.toStringAsFixed(5)}',
                    style: TextStyle(fontSize: 11, color: AppTheme.textHint),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _confirmSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '确认选择此位置',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 加载指示器
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.05),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppTheme.primary),
                        const SizedBox(height: 12),
                        const Text('正在定位...', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _geocodeDebounce?.cancel();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }
}
