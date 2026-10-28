import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassContainer, GlassQuality;
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../../services/amap_location_service.dart';
import '../../../theme/app_design_system.dart';
import '../../../theme/glass_materials.dart';
import '../../../providers/theme_provider.dart';
import 'package:provider/provider.dart';

/// Map picker page - similar to WeChat's location picker
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

  LatLng _center = const LatLng(39.9042, 116.4074); // GCJ-02 coordinates, used for map display
  String _address = '';
  String _placeName = '';
  bool _isLoading = false;
  bool _isSearching = false;
  bool _isLocating = false; // Flag: GPS locating in progress
  List<Map<String, dynamic>> _searchResults = [];
  Timer? _searchDebounce;
  Timer? _geocodeDebounce;

  @override
  void initState() {
    super.initState();
    if (widget.initialCenter != null) {
      // initialCenter comes from GPS (WGS84); convert to GCJ-02 for map display
      final gcj = AmapLocationService.wgs84ToGcj02(
        widget.initialCenter!.latitude,
        widget.initialCenter!.longitude,
      );
      _center = LatLng(gcj.$1, gcj.$2);
      _placeName = widget.initialName ?? '';
      // Pass the original WGS84 coordinates for API queries
      _reverseGeocode(widget.initialCenter!);
    } else {
      _locateMe();
    }
  }

  /// Move the map to the current location
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

      // Prefer the last known position (returns quickly)
      Position? position = await Geolocator.getLastKnownPosition();

      // Without a cached position, request a fresh fix (retries with decreasing accuracy)
      // forceAndroidLocationManager=true avoids depending on Google Play Services (better compatibility with domestic devices)
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
        // GPS returns WGS84 coordinates; convert to GCJ-02 for map display
        final gcj = AmapLocationService.wgs84ToGcj02(position.latitude, position.longitude);
        final latLng = LatLng(gcj.$1, gcj.$2);
        setState(() {
          _center = latLng;
        });
        _mapController.move(latLng, 16);
        // Pass the original WGS84 coordinates for API queries
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

  /// Reverse geocoding: coordinates -> address
  Future<void> _reverseGeocode(LatLng point) async {
    try {
      String? address;

      // Prefer the Amap API (accurate Chinese addresses, includes nearby POIs)
      final amap = AmapLocationService.instance;
      if (amap.isConfigured) {
        final result = await amap.reverseGeocode(point.latitude, point.longitude);
        if (result != null) {
          address = result.fullAddress;
          if (mounted && _placeName.isEmpty) {
            // Prefer the nearest POI name (residential area, shop, landmark)
            if (result.nearbyPois.isNotEmpty) {
              _placeName = result.nearbyPois.first;
            } else {
              _placeName = result.shortAddress;
            }
          }
        }
      }

      // Fallback: Android native Geocoder
      if ((address == null || address.trim().isEmpty) && Platform.isAndroid) {
        try {
          address = await _locationChannel.invokeMethod<String>(
            'reverseGeocode',
            {'latitude': point.latitude, 'longitude': point.longitude},
          );
        } catch (_) {}
      }

      // Fallback: Nominatim
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

  /// Search for a place
  Future<void> _searchPlace(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);
    try {
      List<Map<String, dynamic>> results = [];

      // Prefer Amap POI search (most complete Chinese POI data)
      final amap = AmapLocationService.instance;
      if (amap.isConfigured) {
        // The map center is already GCJ-02, so pass it to the Amap API directly
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

      // Fallback: Android native Geocoder (returns WGS84, needs conversion to GCJ-02)
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

      // Fallback: Nominatim (returns WGS84, needs conversion to GCJ-02)
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

  /// Select a search result
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

  /// Confirm the selection (returns WGS84 coordinates)
  void _confirmSelection() {
    final name = _placeName.isNotEmpty ? _placeName : _address;
    // The map center is GCJ-02; convert back to WGS84 for storage
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

  /// Floating panel above the map: glass mode = real refractive glass
  /// (refracting the map below), disabled mode = [fallback] solid container (zero drift)
  Widget _panel({
    required Widget child,
    required BoxDecoration fallback,
    double radius = 24,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
    EdgeInsetsGeometry? margin,
    double? maxHeight,
  }) {
    final constraints =
        maxHeight != null ? BoxConstraints(maxHeight: maxHeight) : null;
    if (!shouldUseLiquidGlass(context)) {
      return Container(
        margin: margin,
        padding: padding,
        constraints: constraints,
        decoration: fallback,
        child: child,
      );
    }
    return Container(
      margin: margin,
      constraints: constraints,
      child: GlassContainer(
        shape: GlassMaterials.shape(radius),
        settings: GlassMaterials.bar(),
        quality: GlassQuality.premium,
        useOwnLayer: true,
        padding: padding,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>(); // theme rebuild
    return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 16,
              onPositionChanged: (pos, hasGesture) {
                _center = pos.center;
                // Only reverse geocode when the user drags the map manually
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
                // Geocode immediately only in edit mode (with initial coordinates); GPS mode is handled by _locateMe()
                if (widget.initialCenter != null && !_isLocating) {
                  final wgs84 = AmapLocationService.gcj02ToWgs84(_center.latitude, _center.longitude);
                  _reverseGeocode(LatLng(wgs84.$1, wgs84.$2));
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://webrd0{s}.is.autonavi.com/appmaptile?lang=zh_cn&size=1&scale=2&style=8&x={x}&y={y}&z={z}',
                subdomains: const ['1', '2', '3', '4'],
                userAgentPackageName: 'com.bearbill.bear_bill',
                maxZoom: 18,
              ),
            ],
          ),

          // Center pin marker (fixed in place)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _panel(
                  radius: 12,
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  fallback: BoxDecoration(
                    color: DS.surfaceContainerLowest,
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
                          ? DS.onSurface
                          : DS.outline,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: 4),
                Icon(
                  Icons.location_on,
                  color: DS.emphasis,
                  size: 40,
                  shadows: const [
                    Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                // Shadow ellipse at the base
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

          // Top search bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Column(
              children: [
                _panel(
                  radius: 24,
                  fallback: BoxDecoration(
                    color: DS.surfaceContainerLowest,
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
                        icon: Icon(Icons.arrow_back, color: DS.onSurface),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            // The theme's solid fill would cover the glass; make it transparent
                            filled: true,
                            fillColor: shouldUseLiquidGlass(context)
                                ? Colors.transparent
                                : null,
                            hintText: '搜索地点',
                            border: InputBorder.none,
                            hintStyle: const TextStyle(fontSize: 15),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
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
                          color: _isSearching ? DS.outline : DS.emphasis,
                        ),
                        onPressed: () => _searchPlace(_searchController.text),
                      ),
                    ],
                  ),
                ),

                // Search results list
                if (_searchResults.isNotEmpty)
                  _panel(
                    radius: 16,
                    margin: EdgeInsets.only(top: 4),
                    maxHeight: 240,
                    fallback: BoxDecoration(
                      color: DS.surfaceContainerLowest,
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
                      padding: EdgeInsets.symmetric(vertical: 4),
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => Divider(height: 1),
                      itemBuilder: (context, index) {
                        final r = _searchResults[index];
                        return ListTile(
                          dense: true,
                          leading: Icon(Icons.place, color: DS.emphasis, size: 20),
                          title: Text(
                            r['name'] ?? '',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            r['distance'] != null && r['distance'] != ''
                                ? '${r['address'] ?? ''} · ${r['distance']}m'
                                : (r['address'] ?? ''),
                            style: TextStyle(fontSize: 12, color: DS.outline),
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

          // Bottom-right button group
          Positioned(
            right: 16,
            bottom: 120,
            child: Column(
              children: [
                // Locate button
                _panel(
                  radius: 999,
                  fallback: BoxDecoration(
                    color: DS.surfaceContainerLowest,
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
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.my_location, color: DS.emphasis),
                    onPressed: _isLoading ? null : _locateMe,
                  ),
                ),
              ],
            ),
          ),

          // Bottom info bar + confirm button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _panel(
              radius: 24,
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              fallback: BoxDecoration(
                color: DS.surfaceContainerLowest,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                      Icon(Icons.place, color: DS.emphasis, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _placeName.isNotEmpty ? _placeName : '未知位置',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: DS.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_address.isNotEmpty && _address != _placeName)
                              Text(
                                _address,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: DS.outline,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    '坐标: ${_center.latitude.toStringAsFixed(5)}, ${_center.longitude.toStringAsFixed(5)}',
                    style: TextStyle(fontSize: 11, color: DS.outline),
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _confirmSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DS.emphasis,
                        foregroundColor: DS.isDark ? DS.background : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        '确认选择此位置',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.05),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: DS.emphasis),
                        SizedBox(height: 12),
                        Text('正在定位...', style: TextStyle(fontSize: 14)),
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
