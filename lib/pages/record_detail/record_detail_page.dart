import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_design_system.dart';
import '../../theme/app_theme.dart';
import '../../utils/utils.dart' as utils;
import '../add_record/add_record_page.dart';

Color _hexToColor(String hex) {
  final buffer = StringBuffer();
  if (hex.length == 6 || hex.length == 7) buffer.write('ff');
  buffer.write(hex.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

class RecordDetailPage extends StatefulWidget {
  final String recordId;

  const RecordDetailPage({super.key, required this.recordId});

  @override
  State<RecordDetailPage> createState() => _RecordDetailPageState();
}

class _RecordDetailPageState extends State<RecordDetailPage> {
  RecordModel? _record;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecord();
  }

  Future<void> _loadRecord() async {
    final record = await DatabaseService.instance.getRecordById(widget.recordId);
    setState(() {
      _record = record;
      _loading = false;
    });
  }

  Future<void> _editRecord() async {
    if (_record == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddRecordPage(editRecord: _record),
      ),
    );

    if (result == true && mounted) {
      // 通知 AppProvider 刷新账单列表
      context.read<AppProvider>().onRecordDeleted();
      // 刷新当前详情页
      _loadRecord();
    }
  }

  Future<void> _deleteRecord() async {
    if (_record == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('确认删除'),
        content: Text(
          '确定要删除「${_record!.categoryName}」¥${utils.FormatUtils.formatAmount(_record!.amount)} 吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              '删除',
              style: TextStyle(color: DS.primaryContainer),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseService.instance.deleteRecord(_record!.id);
      if (!mounted) return;
      context.read<AppProvider>().onRecordDeleted();
      NotificationService.instance.refreshTodaySummary();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.delete_outline, size: 18, color: Colors.white),
                SizedBox(width: 6),
                Text('已删除'),
              ],
            ),
            duration: const Duration(seconds: 1),
          ),
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('账单详情')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_record == null) {
      return Scaffold(
        appBar: AppBar(title: Text('账单详情')),
        body: const Center(child: Text('账单不存在')),
      );
    }

    final category = getCategoryById(
      _record!.categoryId,
      isExpense: _record!.type == 'expense',
    );
    final mood = _record!.mood != null ? getMoodById(_record!.mood!) : null;

    return Scaffold(
      backgroundColor: DS.background,
      appBar: AppBar(
        title: Text(_record!.type == 'income' ? '收入详情' : '支出详情'),
        backgroundColor:
            _record!.type == 'income' ? AppTheme.success : DS.primary,
      ),
      body: Column(
        children: [
          _buildAmountHero(category),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(DS.base),
              child: Column(
                children: [
                  if (mood != null)
                    _buildDetailRow(
                      '心情',
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(mood.emoji, style: TextStyle(fontSize: 22)),
                          SizedBox(width: 6),
                          Text(
                            mood.label,
                            style: DS.bodyMd.copyWith(color: DS.onSurface),
                          ),
                        ],
                      ),
                    ),
                  _buildDetailRow(
                    '备注',
                    Text(
                      _record!.remark != null && _record!.remark!.isNotEmpty
                          ? _record!.remark!
                          : '无备注',
                      style: DS.bodyMd.copyWith(color: DS.onSurface),
                    ),
                  ),
                  _buildDetailRow(
                    '记录时间',
                    Text(
                      '${utils.DateUtils.formatDate(_record!.createdAt)} ${_record!.createdAt.hour.toString().padLeft(2, '0')}:${_record!.createdAt.minute.toString().padLeft(2, '0')}',
                      style: DS.labelSm.copyWith(color: DS.onSurfaceVariant),
                    ),
                  ),
                  if (_record!.location != null && _record!.location!.isNotEmpty)
                    _buildDetailRow(
                      '位置',
                      Text(
                        _record!.location!,
                        style: DS.bodyMd.copyWith(color: DS.onSurface),
                      ),
                    ),
                  if (_record!.images.isNotEmpty) _buildImageSection(),
                ],
              ),
            ),
          ),
          _buildActionBar(),
        ],
      ),
    );
  }

  Widget _buildAmountHero(CategoryModel? category) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(DS.md),
      decoration: BoxDecoration(
        color: _record!.type == 'income'
            ? AppTheme.successLight
            : DS.surfaceContainerHigh,
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: DS.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(DS.radiusFull),
              border: Border.all(
                color: _hexToColor(category?.color ?? '#B0B0B0'),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                category?.icon ?? '📦',
                style: TextStyle(fontSize: 32),
              ),
            ),
          ),
          SizedBox(height: DS.gutter),
          Text(
            category?.name ?? '未分类',
            style: DS.bodyMd.copyWith(
              fontWeight: FontWeight.w600,
              color: DS.onSurface,
            ),
          ),
          SizedBox(height: DS.base),
          Text(
            '${_record!.type == 'income' ? '+' : '-'}¥${utils.FormatUtils.formatAmount(_record!.amount)}',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: _record!.type == 'income'
                  ? AppTheme.success
                  : DS.primaryContainer,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          SizedBox(height: DS.gutter),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                utils.DateUtils.formatDayCN(_record!.date),
                style: DS.labelMd.copyWith(color: DS.onSurface),
              ),
              SizedBox(width: 8),
              Text(
                utils.DateUtils.getWeekday(DateTime.parse(_record!.date)),
                style: DS.labelSm.copyWith(color: DS.onSurfaceVariant),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            _record!.date,
            style: DS.labelSm.copyWith(color: DS.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, Widget value) {
    return Container(
      margin: EdgeInsets.only(bottom: DS.base),
      padding: EdgeInsets.all(DS.gutter),
      decoration: DS.glassDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: DS.labelSm.copyWith(color: DS.onSurfaceVariant),
            ),
          ),
          Expanded(child: value),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      margin: EdgeInsets.only(bottom: DS.base),
      padding: EdgeInsets.all(DS.gutter),
      decoration: DS.glassDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '图片',
            style: DS.labelSm.copyWith(color: DS.onSurfaceVariant),
          ),
          SizedBox(height: 10),
          SizedBox(
            height: 76,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _record!.images.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _showFullImage(index),
                  child: Container(
                    margin: EdgeInsets.only(right: 8),
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(DS.radiusXs),
                      image: DecorationImage(
                        image: FileImage(File(_record!.images[index])),
                        fit: BoxFit.cover,
                      ),
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

  void _showFullImage(int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => _FullImageViewer(
        images: _record!.images,
        initialIndex: initialIndex,
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: EdgeInsets.all(DS.base),
      decoration: BoxDecoration(
        color: DS.surfaceContainerLowest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _editRecord,
              icon: Icon(Icons.edit),
              label: Text('编辑'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.info,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DS.radiusSm),
                ),
              ),
            ),
          ),
          SizedBox(width: DS.base),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _deleteRecord,
              icon: Icon(Icons.delete),
              label: Text('删除'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DS.primaryContainer,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DS.radiusSm),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 全屏图片查看器 - 支持左右滑动切换
class _FullImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullImageViewer({required this.images, required this.initialIndex});

  @override
  State<_FullImageViewer> createState() => _FullImageViewerState();
}

class _FullImageViewerState extends State<_FullImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.file(
                File(widget.images[index]),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 64, color: Colors.grey[600]),
                      SizedBox(height: 12),
                      Text(
                        '图片加载失败',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
