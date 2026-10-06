import 'package:flutter/material.dart';

import '../../../main.dart';
import '../../../services/storage_service.dart';
import '../../../theme/app_design_system.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/glass_materials.dart';
import '../../../widgets/glass_dialog_shell.dart';

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

  await showGlassDialog(
    context: context,
    title: '字号调整',
    maxWidth: 320,
    content: StatefulBuilder(
      builder: (context, setDialogState) => Column(
        mainAxisSize: MainAxisSize.min,
        children: sizeOptions.map((size) {
          final selected = currentSize == size;
          // 玻璃弹窗里没有 Material 祖先，RadioListTile 的
          // 圆点/涟漪/高亮样式会退化（显示异常），玻璃态改为
          // 自绘玻璃选项行；关闭态保留原 RadioListTile 零漂移。
          if (!shouldUseLiquidGlass(context)) {
            return RadioListTile<String>(
              value: size,
              groupValue: currentSize,
              contentPadding: EdgeInsets.zero,
              title: Row(
                children: [
                  Text(
                    '预览文字',
                    style: TextStyle(
                      fontSize: 14 * sizeMap[size]!,
                      fontWeight: FontWeight.w500,
                      color: DS.onSurface,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    '($size)',
                    style: DS.labelSm.copyWith(color: DS.onSurfaceVariant),
                  ),
                ],
              ),
              activeColor: DS.emphasis,
              onChanged: (value) {
                setDialogState(() => currentSize = value!);
              },
            );
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: DS.sm),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setDialogState(() => currentSize = size),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(
                  horizontal: DS.sm,
                  vertical: DS.sm,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: DS.isDark
                        ? [
                            Colors.white.withOpacity(selected ? 0.28 : 0.10),
                            Colors.white.withOpacity(selected ? 0.10 : 0.04),
                          ]
                        : [
                            Colors.white.withOpacity(selected ? 0.70 : 0.35),
                            Colors.white.withOpacity(selected ? 0.40 : 0.15),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(DS.radiusFull),
                  border: Border.all(
                    color: DS.isDark
                        ? Colors.white.withOpacity(0.18)
                        : Colors.black.withOpacity(0.10),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      '预览文字',
                      style: TextStyle(
                        fontSize: 14 * sizeMap[size]!,
                        fontWeight: FontWeight.w500,
                        color: DS.onSurface,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '($size)',
                      style: DS.labelSm.copyWith(color: DS.onSurfaceVariant),
                    ),
                    const Spacer(),
                    // 自绘选中圆点（radio 隐喻）
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? DS.onSurface
                              : (DS.isDark
                                  ? Colors.white.withOpacity(0.35)
                                  : Colors.black.withOpacity(0.25)),
                          width: 1.5,
                        ),
                        color: selected ? DS.onSurface : Colors.transparent,
                      ),
                      child: selected
                          ? Center(
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: DS.background,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ),
    buildActions: (ctx) => [
      GlassDialogButton(
        label: '取消',
        onPressed: () => Navigator.pop(ctx),
      ),
      GlassDialogButton(
        label: '确认',
        isPrimary: true,
        onPressed: () {
          storage.setString('fontSize', currentSize);
          Navigator.pop(ctx);

          FontSizeNotifier.instance.notifyFontSizeChanged();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已设置为「$currentSize」字号'),
              backgroundColor: AppTheme.success,
            ),
          );
        },
      ),
    ],
  );
}
