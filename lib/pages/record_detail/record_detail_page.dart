import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
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
        title: const Text('确认删除'),
        content: Text(
          '确定要删除「${_record!.categoryName}」¥${utils.FormatUtils.formatAmount(_record!.amount)} 吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              '删除',
              style: TextStyle(color: AppTheme.primaryDark),
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
          const SnackBar(
            content: Text('已删除 🗑️'),
            duration: Duration(seconds: 1),
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
        appBar: AppBar(title: const Text('账单详情')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_record == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('账单详情')),
        body: const Center(child: Text('账单不存在')),
      );
    }

    final category = getCategoryById(
      _record!.categoryId,
      isExpense: _record!.type == 'expense',
    );
    final mood = _record!.mood != null ? getMoodById(_record!.mood!) : null;

    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      appBar: AppBar(
        title: Text(_record!.type == 'income' ? '收入详情' : '支出详情'),
        backgroundColor:
            _record!.type == 'income' ? AppTheme.success : AppTheme.primary,
      ),
      body: Column(
        children: [
          _buildAmountHero(category),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                children: [
                  if (mood != null)
                    _buildDetailRow(
                      '心情',
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(mood.emoji, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 6),
                          Text(
                            mood.label,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                            ),
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
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  _buildDetailRow(
                    '记录时间',
                    Text(
                      '${utils.DateUtils.formatDate(_record!.createdAt)} ${_record!.createdAt.hour.toString().padLeft(2, '0')}:${_record!.createdAt.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  if (_record!.location != null && _record!.location!.isNotEmpty)
                    _buildDetailRow(
                      '位置',
                      Text(
                        _record!.location!,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
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
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: _record!.type == 'income'
            ? AppTheme.successLight
            : AppTheme.primaryLight,
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(
                color: _hexToColor(category?.color ?? '#B0B0B0'),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                category?.icon ?? '📦',
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            category?.name ?? '未分类',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${_record!.type == 'income' ? '+' : '-'}¥${utils.FormatUtils.formatAmount(_record!.amount)}',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: _record!.type == 'income'
                  ? AppTheme.success
                  : AppTheme.primaryDark,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                utils.DateUtils.formatDayCN(_record!.date),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                utils.DateUtils.getWeekday(DateTime.parse(_record!.date)),
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _record!.date,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, Widget value) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(child: value),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '图片',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 76,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _record!.images.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _showFullImage(index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
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
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
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
              icon: const Icon(Icons.edit),
              label: const Text('编辑'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.info,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _deleteRecord,
              icon: const Icon(Icons.delete),
              label: const Text('删除'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
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
          style: const TextStyle(color: Colors.white, fontSize: 16),
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
                      const SizedBox(height: 12),
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
