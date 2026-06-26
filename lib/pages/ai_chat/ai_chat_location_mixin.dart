import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../services/amap_location_service.dart';
import '../../theme/app_design_system.dart';
import '../add_record/widgets/map_picker_page.dart';
import 'ai_chat_page.dart';

/// AI 记账页 - 定位相关功能
mixin AiChatLocationMixin on State<AiChatPage> {
  final Map<String, String?> msgLocations = {};
  final Map<String, double?> msgLat = {};
  final Map<String, double?> msgLng = {};
  final Map<String, bool> msgLocationLoading = {};

  Future<void> fetchLocationForMsg(String msgId) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => msgLocationLoading[msgId] = false);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => msgLocationLoading[msgId] = false);
        return;
      }

      Position? position = await Geolocator.getLastKnownPosition();
      try {
        position ??= await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        ).timeout(const Duration(seconds: 12));
      } catch (_) {}

      if (!mounted || position == null) {
        if (mounted) setState(() => msgLocationLoading[msgId] = false);
        return;
      }

      msgLat[msgId] = position.latitude;
      msgLng[msgId] = position.longitude;

      String? address;
      try {
        final amapResult = await AmapLocationService.instance
            .reverseGeocode(position.latitude, position.longitude)
            .timeout(const Duration(seconds: 5), onTimeout: () => null);
        address = amapResult?.shortAddress;
      } catch (_) {}

      if (address == null || address.isEmpty) {
        try {
          final result = await const MethodChannel('bear_bill/location')
              .invokeMethod<String>('reverseGeocode', {
            'latitude': position.latitude,
            'longitude': position.longitude,
          });
          address = result;
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          msgLocations[msgId] = address;
          msgLocationLoading[msgId] = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => msgLocationLoading[msgId] = false);
    }
  }

  void showLocationOptions(String msgId, VoidCallback onRefresh) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.my_location, color: DS.primary),
              title: Text('重新获取 GPS 定位'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  msgLocationLoading[msgId] = true;
                  msgLocations[msgId] = null;
                });
                fetchLocationForMsg(msgId);
              },
            ),
            ListTile(
              leading: Icon(Icons.map, color: DS.primary),
              title: Text('地图选点'),
              onTap: () {
                Navigator.pop(ctx);
                openMapPicker(msgId);
              },
            ),
            if (msgLocations[msgId] != null)
              ListTile(
                leading: Icon(Icons.clear, color: DS.outline),
                title: Text('清除位置'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    msgLocations[msgId] = null;
                    msgLat[msgId] = null;
                    msgLng[msgId] = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> openMapPicker(String msgId) async {
    LatLng? initialCenter;
    if (msgLat[msgId] != null && msgLng[msgId] != null) {
      initialCenter = LatLng(msgLat[msgId]!, msgLng[msgId]!);
    }

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerPage(initialCenter: initialCenter),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        msgLocations[msgId] = result['address'] as String?;
        msgLat[msgId] = result['latitude'] as double?;
        msgLng[msgId] = result['longitude'] as double?;
        msgLocationLoading[msgId] = false;
      });
    }
  }
}
