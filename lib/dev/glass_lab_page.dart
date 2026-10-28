import 'package:flutter/cupertino.dart' show showCupertinoDialog;
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../theme/app_design_system.dart';
import '../theme/glass_materials.dart';

/// 【临时验证页】官方包交互能力真机实验场（验证完整体删除）
///
/// 验证目标：
/// A. `GlassButton(style: transparent)` 能否"只留物理不画玻璃"（替代手搓按压）
/// B. `GlassMaterialize` 玻璃成形/溶解动画的观感
/// C. `showCupertinoDialog` vs `showDialog` 弹窗进场对比 + Materialize 进场
/// D. `SpringBuilder` 弹簧工具可用性
///
/// 本页不受"玻璃开关/零漂移"约束（验证页直接强制玻璃，发布前删除）。
class GlassLabPage extends StatefulWidget {
  const GlassLabPage({super.key});

  @override
  State<GlassLabPage> createState() => _GlassLabPageState();
}

class _GlassLabPageState extends State<GlassLabPage> {
  bool _showPanel = false;
  bool _springUp = false;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: dark ? const Color(0xFF101014) : const Color(0xFFF3F1EC),
      appBar: AppBar(
        title: const Text('玻璃实验室'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('A. 按压物理对比（按住试试）'),
          _sectionCard(
            dark: dark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _label('A1 官方纯物理（transparent，无玻璃壳）', dark),
                Center(
                  child: GlassButton.custom(
                    style: GlassButtonStyle.transparent,
                    onTap: () {},
                    width: 180,
                    height: 48,
                    shape: const LiquidRoundedSuperellipse(borderRadius: 24),
                    child: Center(
                      child: Text('官方纯物理',
                          style: TextStyle(
                              fontSize: 15,
                              color: dark ? Colors.white : Colors.black87)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _label('A2 现有手搓（wish 存入同款，无反馈）', dark),
                Center(
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 180,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: dark
                              ? [
                                  Colors.white.withOpacity(0.36),
                                  Colors.white.withOpacity(0.12),
                                ]
                              : [
                                  Colors.white.withOpacity(0.69),
                                  Colors.white.withOpacity(0.45),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: dark
                              ? Colors.white.withOpacity(0.16)
                              : Colors.black.withOpacity(0.10),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: dark
                                ? Colors.black.withOpacity(0.20)
                                : Colors.black.withOpacity(0.06),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text('现有手搓',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: dark ? Colors.white : Colors.black87)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _label('A3 官方带玻璃壳（filled，参考组）', dark),
                Center(
                  child: GlassButton.custom(
                    style: GlassButtonStyle.filled,
                    useOwnLayer: true,
                    quality: GlassQuality.standard,
                    onTap: () {},
                    width: 180,
                    height: 48,
                    shape: const LiquidRoundedSuperellipse(borderRadius: 24),
                    child: Center(
                      child: Text('官方玻璃壳',
                          style: TextStyle(
                              fontSize: 15,
                              color: dark ? Colors.white : Colors.black87)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle('B. GlassMaterialize 成形/溶解'),
          _sectionCard(
            dark: dark,
            child: Column(
              children: [
                TextButton(
                  onPressed: () => setState(() => _showPanel = !_showPanel),
                  child: Text(_showPanel ? '隐藏面板' : '显示面板'),
                ),
                const SizedBox(height: 8),
                GlassMaterialize(
                  visible: _showPanel,
                  child: GlassContainer(
                    shape: GlassMaterials.shape(24),
                    settings: GlassMaterials.bar(),
                    quality: GlassQuality.standard,
                    useOwnLayer: true,
                    padding: const EdgeInsets.all(DS.lg),
                    child: const Column(
                      children: [
                        Text('成形的面板',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 6),
                        Text('玻璃先成形，内容后清晰',
                            style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle('C. 弹窗进场动画对比'),
          _sectionCard(
            dark: dark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton(
                  onPressed: () => _openDialog(_DialogKind.material),
                  child: const Text('C1 showDialog（现状）'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => _openDialog(_DialogKind.cupertino),
                  child: const Text('C2 showCupertinoDialog'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => _openDialog(_DialogKind.materialize),
                  child: const Text('C3 General + Materialize'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle('D. SpringBuilder 弹簧'),
          _sectionCard(
            dark: dark,
            child: Center(
              child: GestureDetector(
                onTap: () => setState(() => _springUp = !_springUp),
                child: SpringBuilder(
                  value: _springUp ? 1.08 : 1.0,
                  spring: GlassSpring.bouncy(duration: const Duration(milliseconds: 260)),
                  builder: (context, value, child) => Transform.scale(
                    scale: value,
                    child: child,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    decoration: BoxDecoration(
                      color: dark
                          ? Colors.white.withOpacity(0.14)
                          : Colors.black.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Text('点我弹一下',
                        style: TextStyle(fontSize: 15)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _openDialog(_DialogKind kind) async {
    Widget dialog() => GlassDialog(
          title: '玻璃弹窗',
          message: '验证进场动画（$kind）',
          quality: GlassQuality.standard,
          maxWidth: 300,
          actions: [
            GlassDialogAction(
              label: '关闭',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );

    switch (kind) {
      case _DialogKind.material:
        await showDialog(context: context, builder: (_) => dialog());
      case _DialogKind.cupertino:
        await showCupertinoDialog(context: context, builder: (_) => dialog());
      case _DialogKind.materialize:
        await showGeneralDialog(
          context: context,
          barrierDismissible: true,
          barrierLabel: 'lab',
          pageBuilder: (_, __, ___) => dialog(),
          transitionBuilder: (_, animation, __, child) =>
              GlassMaterializeTransition(animation: animation, child: child),
          transitionDuration: GlassDefaults.materializeDuration,
        );
    }
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      );

  Widget _label(String text, bool dark) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: TextStyle(
                fontSize: 12,
                color: dark ? Colors.white54 : Colors.black45)),
      );

  Widget _sectionCard({required bool dark, required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: dark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: child,
      );
}

enum _DialogKind { material, cupertino, materialize }
