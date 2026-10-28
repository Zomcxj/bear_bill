import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/theme_provider.dart';
import '../../../theme/app_design_system.dart';
import '../../../theme/glass_materials.dart';
import '../../../widgets/glass_dialog_shell.dart';

/// 玻璃风格选择对话框：三档并存、可即时切换
///
/// - 经典实色：不启用玻璃（与"玻璃关闭"逐像素一致）
/// - 轻薄玻璃：现有 iOS 26 底栏材质
/// - 厚玻璃：强模糊 + 1px 描边 + 双层阴影 + 实心主题色选中态
void showGlassStyleDialog(BuildContext context) {
  final provider = context.read<ThemeProvider>();
  final options = <_StyleOption>[
    const _StyleOption(
      style: AppGlassStyle.classic,
      title: '经典实色',
      subtitle: '不使用玻璃效果 · 纯色卡片',
    ),
    const _StyleOption(
      style: AppGlassStyle.thin,
      title: '轻薄玻璃',
      subtitle: 'iOS 26 底栏材质 · 克制通透',
    ),
    const _StyleOption(
      style: AppGlassStyle.thick,
      title: '厚玻璃',
      subtitle: '强模糊 + 描边 + 双层阴影',
    ),
  ];

  showGlassDialog(
    context: context,
    title: '玻璃风格',
    maxWidth: 360,
    content: StatefulBuilder(
      builder: (ctx, setDialogState) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in options)
            _GlassStyleTile(
              title: option.title,
              subtitle: option.subtitle,
              selected: provider.glassStyle == option.style,
              onTap: () {
                provider.setGlassStyle(option.style);
                setDialogState(() {});
              },
            ),
        ],
      ),
    ),
    // 点选即时生效，无需确认按钮，只留一个关闭
    buildActions: (dialogContext) => [
      GlassDialogButton(
        label: '关闭',
        onPressed: () => Navigator.pop(dialogContext),
      ),
    ],
  );
}

class _StyleOption {
  const _StyleOption({
    required this.style,
    required this.title,
    required this.subtitle,
  });

  final AppGlassStyle style;
  final String title;
  final String subtitle;
}

class _GlassStyleTile extends StatelessWidget {
  const _GlassStyleTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glass = shouldUseLiquidGlass(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: DS.sm),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DS.base * 2,
            vertical: DS.sm,
          ),
          decoration: BoxDecoration(
            color: selected
                ? DS.emphasis.withOpacity(0.14)
                : (glass
                    ? Colors.white.withOpacity(0.06)
                    : DS.surfaceContainerLow),
            borderRadius: BorderRadius.circular(DS.radiusMd),
            border: selected
                ? Border.all(color: DS.emphasis, width: 1.5)
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: DS.labelMd.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: DS.labelSm.copyWith(color: DS.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, size: 20, color: DS.emphasis),
            ],
          ),
        ),
      ),
    );
  }
}
