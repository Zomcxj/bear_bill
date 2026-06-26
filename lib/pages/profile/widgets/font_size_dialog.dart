import 'package:flutter/material.dart';

import '../../../main.dart';
import '../../../services/storage_service.dart';
import '../../../theme/app_design_system.dart';
import '../../../theme/app_theme.dart';

/// 显示字号调整对话框
Future<void> showFontSizeDialog(BuildContext context) async {
  final storage = StorageService.instance;
  String currentSize = storage.getString('fontSize') ?? '标准';

  final sizeOptions = ['小', '标准', '大'];
  final sizeMap = {
    '小': 0.7,
    '标准': 0.8,
    '大': 0.9,
  };

  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.text_fields, color: DS.primary),
            SizedBox(width: 8),
            Text('字号调整'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: sizeOptions.map((size) {
            return RadioListTile<String>(
              value: size,
              groupValue: currentSize,
              title: Row(
                children: [
                  Text(
                    '预览文字',
                    style: TextStyle(
                      fontSize: 14 * sizeMap[size]!,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    '($size)',
                    style: DS.labelSm.copyWith(color: DS.onSurfaceVariant),
                  ),
                ],
              ),
              activeColor: DS.primary,
              onChanged: (value) {
                setState(() => currentSize = value!);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () {
              storage.setString('fontSize', currentSize);
              Navigator.pop(context);

              FontSizeNotifier.instance.notifyFontSizeChanged();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('已设置为「$currentSize」字号'),
                  backgroundColor: AppTheme.success,
                ),
              );
            },
            child:
                Text('确认', style: TextStyle(color: DS.primary)),
          ),
        ],
      ),
    ),
  );
}
