import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../services/amap_location_service.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/utils.dart' as utils;
import 'widgets/category_filter_bar.dart';

/// 消费地图足迹页面
class MapFootprintPage extends StatefulWidget {
  const MapFootprintPage({super.key});

  @override
  State<MapFootprintPage> createState() => _MapFootprintPageState();
}

class _MapFootprintPageState extends State<MapFootprintPage> {
  final MapController _mapController = MapController();
  List<RecordModel> _allRecords = [];
  List<_MapCluster> _clusters = [];
  String? _selectedCategoryId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final appProvider = context.read<AppProvider>();
    final records = await DatabaseService.instance.getRecordsWithLocation(
      bookId: appProvider.currentBookId,
    );

    setState(() {
      _allRecords = records;
      _isLoading = false;
    });
    _updateClusters();
  }

  void _updateClusters() {
    var records = _allRecords;

    // 分类筛选
    if (_selectedCategoryId != null) {
      records = records.where((r) => r.categoryId == _selectedCategoryId).toList();
    }

    // 聚类: 100m 内的记录合并
    final clusters = <_MapCluster>[];
    final used = <int>{};

    for (int i = 0; i < records.length; i++) {
      if (used.contains(i)) continue;
      final r1 = records[i];
      if (r1.latitude == null || r1.longitude == null) continue;

      final clusterRecords = <RecordModel>[r1];
      used.add(i);

      for (int j = i + 1; j < records.length; j++) {
        if (used.contains(j)) continue;
        final r2 = records[j];
        if (r2.latitude == null || r2.longitude == null) continue;

        final distance = _haversineDistance(
          r1.latitude!, r1.longitude!,
          r2.latitude!, r2.longitude!,
        );

        if (distance <= 100) {
          clusterRecords.add(r2);
          used.add(j);
        }
      }

      // 计算聚类中心
      final avgLat = clusterRecords.map((r) => r.latitude!).reduce((a, b) => a + b) / clusterRecords.length;
      final avgLng = clusterRecords.map((r) => r.longitude!).reduce((a, b) => a + b) / clusterRecords.length;

      clusters.add(_MapCluster(
        center: LatLng(avgLat, avgLng),
        records: clusterRecords,
      ));
    }

    setState(() => _clusters = clusters);
  }

  /// Haversine 公式计算两点距离（米）
  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0; // 地球半径（米）
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRad(double deg) => deg * pi / 180.0;

  void _onCategoryFilter(String? categoryId) {
    setState(() => _selectedCategoryId = categoryId);
    _updateClusters();
  }

  void _showClusterDetail(_MapCluster cluster) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ClusterDetailSheet(cluster: cluster),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      appBar: AppBar(
        title: const Text(
          '消费地图',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 分类筛选条
                CategoryFilterBar(
                  selectedCategoryId: _selectedCategoryId,
                  onFilter: _onCategoryFilter,
                ),
                // 地图
                Expanded(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _clusters.isNotEmpty
                          ? _clusters.first.center
                          : const LatLng(39.9042, 116.4074),
                      initialZoom: _clusters.length == 1 ? 15 : 12,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://webrd0{s}.is.autonavi.com/appmaptile?lang=zh_cn&size=1&scale=1&style=8&x={x}&y={y}&z={z}',
                        subdomains: ['1', '2', '3', '4'],
                        userAgentPackageName: 'com.bearbill.bear_bill',
                        maxZoom: 18,
                      ),
                      MarkerLayer(
                        markers: _clusters.map((cluster) {
                          final isSingle = cluster.records.length == 1;
                          return Marker(
                            point: cluster.center,
                            width: isSingle ? 36 : 44,
                            height: isSingle ? 36 : 44,
                            child: GestureDetector(
                              onTap: () => _showClusterDetail(cluster),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSingle
                                      ? AppTheme.primary
                                      : AppTheme.primaryDark,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: isSingle
                                      ? Text(
                                          cluster.records.first.categoryIcon,
                                          style: const TextStyle(fontSize: 18),
                                        )
                                      : Text(
                                          '${cluster.records.length}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                // 底部统计
                _buildBottomStats(),
              ],
            ),
    );
  }

  Widget _buildBottomStats() {
    final totalRecords = _clusters.fold<int>(0, (sum, c) => sum + c.records.length);
    final totalAmount = _clusters.fold<double>(0, (sum, c) {
      return sum + c.records.fold<double>(0, (s, r) => s + r.amount);
    });

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: Border(top: BorderSide(color: AppTheme.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('标记数', '${_clusters.length}'),
          _buildStatItem('记录数', '$totalRecords'),
          _buildStatItem('总金额', '¥${utils.FormatUtils.formatAmount(totalAmount)}'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryDark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}

/// 地图聚类数据
class _MapCluster {
  final LatLng center;
  final List<RecordModel> records;

  const _MapCluster({required this.center, required this.records});
}

/// 聚类详情底部弹窗
class _ClusterDetailSheet extends StatelessWidget {
  final _MapCluster cluster;

  const _ClusterDetailSheet({required this.cluster});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖拽指示器
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.textHint.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.place, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${cluster.records.length} 条记录',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '¥${cluster.records.fold<double>(0, (s, r) => s + r.amount).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.divider),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: cluster.records.length,
              itemBuilder: (context, index) {
                final r = cluster.records[index];
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(r.categoryIcon, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  title: Text(
                    r.categoryName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    '${r.date}${r.remark != null && r.remark!.isNotEmpty ? ' · ${r.remark}' : ''}',
                    style: TextStyle(fontSize: 12, color: AppTheme.textHint),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    '${r.type == 'expense' ? '-' : '+'}¥${r.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: r.type == 'expense' ? AppTheme.primaryDark : AppTheme.success,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
