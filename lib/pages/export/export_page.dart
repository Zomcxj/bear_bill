import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../services/database_service.dart';
import '../../theme/app_design_system.dart';
import '../../theme/app_theme.dart';
import '../../utils/utils.dart';
import '../../providers/theme_provider.dart';

/// 账单导出页 - CSV导出、文件保存
class ExportPage extends StatefulWidget {
  const ExportPage({super.key});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  static const MethodChannel _fileChannel = MethodChannel('bear_bill/files');
  String _selectedMonth = '';
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    setState(() {
      _selectedMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _doExport() async {
    setState(() => _exporting = true);

    try {
      final appProvider = context.read<AppProvider>();
      final records = await DatabaseService.instance.getMonthRecords(
        _selectedMonth,
        bookId: appProvider.currentBookId,
      );
      if (!mounted) return;

      if (records.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('该月份没有账单记录')),
        );
        setState(() => _exporting = false);
        return;
      }

      // 生成 CSV 内容
      final csvContent = _generateCSV(records);

      final fileName = 'bill_$_selectedMonth.csv';
      final targetPath = await _pickExportPath(fileName, csvContent);
      if (targetPath == null || targetPath.isEmpty) {
        setState(() => _exporting = false);
        return;
      }

      setState(() => _exporting = false);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.success, size: 24),
                SizedBox(width: 8),
                Text('导出成功'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('共导出 ${records.length} 条记录'),
                SizedBox(height: 8),
                Text(
                  '文件位置：\n$targetPath',
                  style: DS.labelSm.copyWith(color: DS.onSurfaceVariant),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('确定'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _exporting = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败：$e')),
        );
      }
    }
  }

  Future<String?> _pickExportPath(String fileName, String csvContent) async {
    if (Platform.isAndroid) {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(path.join(tempDir.path, fileName));
      await tempFile.writeAsString(csvContent);
      return _fileChannel.invokeMethod<String>(
        'exportFile',
        {
          'sourcePath': tempFile.path,
          'suggestedFileName': fileName,
        },
      );
    }

    final targetPath = await FilePicker.platform.saveFile(
      dialogTitle: '选择导出位置',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (targetPath == null || targetPath.isEmpty) {
      return null;
    }

    final file = File(targetPath);
    await file.writeAsString(csvContent);
    return targetPath;
  }

  String _generateCSV(List<dynamic> records) {
    final buffer = StringBuffer();

    // CSV 头部
    buffer.writeln('日期,时间,类型,分类,金额,备注,心情,标签,位置');

    // CSV 数据行
    for (final record in records) {
      final type = record.type == 'income' ? '收入' : '支出';
      final category = getCategoryById(record.categoryId, isExpense: record.type == 'expense');
      final mood = record.mood != null ? getMoodById(record.mood!)?.emoji ?? '' : '';
      final tags = record.tags.isNotEmpty ? record.tags.join(';') : '';

      buffer.writeln([
        _sanitizeCsvField(record.date),
        _sanitizeCsvField('${record.createdAt.hour.toString().padLeft(2, '0')}:${record.createdAt.minute.toString().padLeft(2, '0')}'),
        _sanitizeCsvField(type),
        _sanitizeCsvField(category?.name ?? '未分类'),
        record.amount.toStringAsFixed(2),
        _sanitizeCsvField((record.remark ?? '').replaceAll(',', '，')),
        _sanitizeCsvField(mood),
        _sanitizeCsvField(tags),
        _sanitizeCsvField(record.location ?? ''),
      ].join(','));
    }

    return buffer.toString();
  }

  /// 防止 CSV 注入：对以特殊字符开头的字段添加前缀
  static String _sanitizeCsvField(String field) {
    if (field.isEmpty) return field;
    final first = field[0];
    if (first == '=' || first == '+' || first == '-' || first == '@' ||
        first == '\t' || first == '\r') {
      return "'$field";
    }
    return field;
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>(); // theme rebuild
    return Scaffold(
      backgroundColor: DS.background,
      appBar: AppBar(
        title: Text('账单导出'),
        backgroundColor: DS.primary,
      ),
      body: Padding(
        padding: EdgeInsets.all(DS.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 说明卡片
            _buildInfoCard(),

            SizedBox(height: DS.md),

            // 月份选择
            _buildMonthSelector(),

            SizedBox(height: DS.md),

            // 导出按钮
            _buildExportButton(),

            Spacer(),

            // 温馨提示
            _buildTips(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(DS.gutter),
      decoration: BoxDecoration(
        color: DS.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(DS.radiusMd),
        border: Border.all(color: DS.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.download, size: 40, color: DS.primary),
          SizedBox(width: DS.gutter),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '导出账单数据',
                  style: DS.headlineSm.copyWith(color: DS.onSurface),
                ),
                SizedBox(height: 4),
                Text(
                  '将账单导出为 CSV 格式，方便在 Excel 中查看和分析',
                  style: DS.labelSm.copyWith(color: DS.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '选择月份：',
          style: DS.labelMd.copyWith(color: DS.onSurface),
        ),
        SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: _selectedMonth),
          readOnly: true,
          onTap: () async {
            DateTime tempDate = DateTime.now();
            final picked = await showCupertinoModalPopup<DateTime>(
              context: context,
              builder: (context) => Container(
                height: 320,
                color: DS.surfaceContainerLowest,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CupertinoButton(
                          child: Text('取消'),
                          onPressed: () => Navigator.pop(context),
                        ),
                        CupertinoButton(
                          child: Text('确定', style: TextStyle(fontWeight: FontWeight.w600)),
                          onPressed: () => Navigator.pop(context, tempDate),
                        ),
                      ],
                    ),
                    Expanded(
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.date,
                        initialDateTime: DateTime.now(),
                        minimumDate: DateTime(2020),
                        maximumDate: DateTime.now(),
                        onDateTimeChanged: (date) => tempDate = date,
                      ),
                    ),
                  ],
                ),
              ),
            );

            if (picked != null && mounted) {
              setState(() {
                _selectedMonth = '${picked.year}-${picked.month.toString().padLeft(2, '0')}';
              });
            }
          },
          decoration: InputDecoration(
            hintText: '点击选择月份',
            prefixIcon: Icon(Icons.calendar_today, color: DS.primary),
            suffixIcon: Icon(Icons.arrow_drop_down),
            filled: true,
            fillColor: DS.surfaceContainerLowest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DS.radiusSm),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExportButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _exporting ? null : _doExport,
        icon: _exporting
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(Icons.file_download),
        label: Text(_exporting ? '导出中...' : '开始导出'),
        style: ElevatedButton.styleFrom(
          backgroundColor: DS.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DS.radiusFull),
          ),
        ),
      ),
    );
  }

  Widget _buildTips() {
    return Container(
      padding: EdgeInsets.all(DS.gutter),
      decoration: BoxDecoration(
        color: AppTheme.infoLight,
        borderRadius: BorderRadius.circular(DS.radiusSm),
        border: Border.all(color: AppTheme.info.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppTheme.info, size: 20),
              SizedBox(width: 8),
              Text(
                '温馨提示',
                style: DS.labelMd.copyWith(color: DS.onSurface),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '• 导出时可自行选择保存位置\n'
            '• 文件格式为 CSV，可用 Excel 打开\n'
            '• 包含日期、金额、分类、备注等完整信息\n'
            '• 建议定期备份重要账单数据',
            style: DS.labelSm.copyWith(
              color: DS.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
