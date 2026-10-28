import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../services/amap_location_service.dart';
import '../../../theme/app_design_system.dart';
import '../../../widgets/glass_dialog_shell.dart';
import 'map_picker_page.dart';

/// Result of a location selection
class LocationResult {
  final String? name;
  final double? latitude;
  final double? longitude;

  const LocationResult({this.name, this.latitude, this.longitude});
}

/// Location selection helper
mixin LocationHelper<T extends StatefulWidget> on State<T> {
  static const _locationChannel = MethodChannel('bear_bill/location');

  void showLocationSnackBar(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
      );
    }
  }

  /// Fetch the device location via GPS
  Future<LocationResult?> fetchDeviceLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        showLocationSnackBar('请先开启系统定位服务，再重新尝试定位');
        return null;
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
        showLocationSnackBar('请允许位置权限以获取定位');
        return null;
      }

      showLocationSnackBar('正在定位...');

      Position? position = await Geolocator.getLastKnownPosition();

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

      if (position == null) {
        showLocationSnackBar('未获取到定位结果，请尝试地图选点');
        return null;
      }

      final coordStr =
          '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
      String address = coordStr;
      try {
        final amap = AmapLocationService.instance;
        if (amap.isConfigured) {
          final result =
              await amap.reverseGeocode(position.latitude, position.longitude);
          if (result != null && result.fullAddress.isNotEmpty) {
            address = result.fullAddress;
          }
        }
        if (address == coordStr && Platform.isAndroid) {
          final nativeResult = await _locationChannel.invokeMethod<String>(
            'reverseGeocode',
            {
              'latitude': position.latitude,
              'longitude': position.longitude,
            },
          );
          if (nativeResult != null &&
              nativeResult.trim().length > 4) {
            // Filter out the coarse "China"-level address returned by domestic ROMs with no Google backend
            address = nativeResult.trim();
          }
        }
      } catch (e) {
        if (kDebugMode) print('反向编码异常: $e');
      }

      showLocationSnackBar('定位成功');
      return LocationResult(
        name: address,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      showLocationSnackBar('定位失败，请尝试地图选点');
      return null;
    }
  }

  /// Pick a point on the map
  Future<LocationResult?> openMapPicker({String? currentLocation}) async {
    LatLng? initialCenter;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          final position = await Geolocator.getLastKnownPosition();
          if (position != null) {
            initialCenter = LatLng(position.latitude, position.longitude);
          }
        }
      }
    } catch (_) {}

    if (!mounted) return null;

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerPage(
          initialCenter: initialCenter,
          initialName: currentLocation,
        ),
      ),
    );

    if (result != null) {
      final name = result['name'] as String? ?? '';
      final lat = result['latitude'] as double?;
      final lng = result['longitude'] as double?;
      return LocationResult(
        name: name.isNotEmpty ? name : currentLocation,
        latitude: lat,
        longitude: lng,
      );
    }
    return null;
  }

  /// Location selection dialog
  /// Note: the action must run after the dialog closes; do not pop in onTap and
  /// assign afterwards, otherwise showDialog's future completes first and the
  /// caller receives null (the result is lost to a race)
  Future<LocationResult?> showLocationDialog() async {
    final choice = await showGlassDialog<String>(
      context: context,
      title: '📍 添加位置',
      maxWidth: 320,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.edit_location, color: DS.emphasis),
            title: Text('手动输入'),
            subtitle: Text('直接输入地点名称'),
            onTap: () => Navigator.pop(context, 'manual'),
          ),
          Divider(height: 1),
          ListTile(
            leading:
                Icon(Icons.my_location, color: DS.secondaryContainer),
            title: Text('GPS定位'),
            subtitle: Text('获取当前设备位置'),
            onTap: () => Navigator.pop(context, 'gps'),
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.map, color: DS.secondary),
            title: Text('地图选点'),
            subtitle: Text('打开地图搜索和选择位置'),
            onTap: () => Navigator.pop(context, 'map'),
          ),
        ],
      ),
      buildActions: (ctx) => [
        GlassDialogButton(
          label: '取消',
          onPressed: () => Navigator.pop(ctx),
        ),
      ],
    );

    switch (choice) {
      case 'manual':
        return showManualInputDialog();
      case 'gps':
        return fetchDeviceLocation();
      case 'map':
        return openMapPicker();
    }
    return null;
  }

  /// Enter a location manually
  Future<LocationResult?> showManualInputDialog({String? current}) async {
    final controller = TextEditingController(text: current ?? '');
    String? name;
    await showGlassDialog(
      context: context,
      title: '输入位置',
      maxWidth: 320,
      content: GlassDialogField(
        controller: controller,
        autofocus: true,
        hintText: '输入地点、地址或门店名',
      ),
      buildActions: (ctx) => [
        GlassDialogButton(
          label: '取消',
          onPressed: () => Navigator.pop(ctx),
        ),
        GlassDialogButton(
          label: '保存',
          isPrimary: true,
          onPressed: () {
            name = controller.text.trim();
            Navigator.pop(ctx);
          },
        ),
      ],
    );
    if (name != null && name!.isNotEmpty) {
      return LocationResult(name: name);
    }
    return null;
  }
}
