import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassContainer, GlassQuality, LiquidRoundedSuperellipse;

import '../theme/app_design_system.dart';
import '../theme/glass_materials.dart';

/// 子页面玻璃顶栏（导航层）
///
/// 官方设计哲学：玻璃只用于导航/控制层，顶栏属于导航层。
/// 开启玻璃时用真玻璃材质渲染「返回键 + 标题 + 操作区」；
/// 关闭时回退标准 [AppBar]，零视觉漂移。
///
/// 用 [standard] 而非 [GlassQuality.premium]：顶栏浮在滚动内容之上，
/// 与 FAB 同理——premium 的 texture capture 在此上下文不可用。
class GlassSubPageBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassSubPageBar({
    super.key,
    required this.title,
    this.actions,
    this.fallbackBackground,
    this.fallbackForeground,
    this.leading,
  });

  final String title;
  final List<Widget>? actions;

  /// 关闭态 AppBar 背景色（null → 跟随主题，修复深色模式常量黑问题）
  final Color? fallbackBackground;

  /// 关闭态 AppBar 前景色（null → 跟随主题）
  final Color? fallbackForeground;

  /// 自定义返回区（null → 默认返回键）
  final Widget? leading;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    if (!shouldUseLiquidGlass(context)) {
      return AppBar(
        title: Text(title),
        actions: actions,
        leading: leading,
        backgroundColor: fallbackBackground,
        foregroundColor: fallbackForeground,
      );
    }

    final topInset = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: kToolbarHeight + topInset,
      child: Padding(
        padding: EdgeInsets.only(
          top: topInset + DS.xs,
          left: DS.sm,
          right: DS.sm,
        ),
        child: GlassContainer(
          shape: const LiquidRoundedSuperellipse(borderRadius: DS.radiusFull),
          settings: GlassMaterials.bar(),
          quality: GlassQuality.standard,
          padding: const EdgeInsets.symmetric(horizontal: DS.xs),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 标题真居中：不随左右按钮宽度偏移
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 56),
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: DS.headlineSm.copyWith(
                    fontSize: 18,
                    color: DS.onSurface,
                  ),
                ),
              ),
              Row(
                children: [
                  leading ??
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new,
                          size: 18,
                          color: DS.onSurface,
                        ),
                        onPressed: () => Navigator.maybePop(context),
                      ),
                  const Spacer(),
                  ...?actions,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
