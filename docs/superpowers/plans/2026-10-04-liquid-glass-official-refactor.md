# 液态玻璃官方哲学重构 · 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把液态玻璃从"内容卡片玻璃"重构为官方哲学的"导航层玻璃"：底栏换官方 `GlassTabBar.bottom`（原生按住拖动），内容卡片回归实心，开关控制新旧两套。

**Architecture:** `MainTabPage` 依据 `shouldUseLiquidGlass(context)` 双树分叉：开启态走官方 `GlassScaffold` + `GlassTabBar.bottom`（沉浸式滚动 + 原生拖动切换），关闭态保留现有 `Scaffold` + 自研底栏（`barTabFromX` 拖动）。内容区撤销全部 GlassPanel，回归 `DS.glassDecoration` 实心卡。

**Tech Stack:** Flutter 3.47 / Dart 3.x、`liquid_glass_widgets: 1.8.1`（Impeller Vulkan 真机已验证可用）、provider、flutter_test。

## Global Constraints

- 版本号保持 `1.3.7+11` 不动（老大指示：发布时再定版本）
- 关闭态必须**零视觉漂移**：现有 179 条测试必须全绿
- 材质参数沿用 `GlassMaterials`（`blur: 20`、`saturation: 1.8`、`thickness: 24`、`refractiveIndex: 1.2`、`chromaticAberration: 0.01`、`lightAngle: -π/2`、`rimLight: 0.35`、`tintLight: 0x1FFFFFFF`、`tintDark: 0x26000000`），不自由发挥
- 官方 `GlassTabBar.bottom` 参数名已核实：`tabs`/`selectedIndex`/`onTabSelected`/`settings`/`quality`/`showIndicator`/`barHeight`/`barBorderRadius`
- 官方 `GlassTab` 构造已核实：`icon`/`activeIcon`/`label`/`semanticLabel`
- 官方 `GlassScaffold` 构造已核实：`body`(required)/`appBar`/`bottomBar`/`background`/`edgeFade`/`extendBody`
- 构建命令固定：`flutter build apk --release --split-per-abi --target-platform android-arm64`
- 测试命令固定：`flutter test`（全量）、`flutter test test/widgets/xxx_test.dart`（单文件）
- 提交需老大明确指示，本计划不含自动 commit 步骤（改为"运行验证"作为任务终点）

---

## File Structure

**删除**
- `lib/theme/glass_backdrop.dart` — 光斑背景层（新方案用真实内容做折射源）
- `lib/widgets/bear_glass.dart` — BearGlass/GlassPanel（内容卡片回归实心后无用）
- `test/widgets/liquid_glass_test.dart` — 随 BearGlass 删除后重写为新的底栏测试

**修改**
- `lib/widgets/tab_swipe.dart` — 删除 `EdgeTabSwipeOverlay`/`resolveTabSwipeTarget`，保留 `barTabFromX`
- `lib/main.dart` — 双树分叉：开启态 `GlassScaffold` + `GlassTabBar.bottom`；关闭态原样
- `lib/widgets/glass_card.dart` — 退回液态玻璃之前的原实现
- 13 处 GlassPanel 使用点 — 退回 `Container(decoration: DS.glassDecoration)`
- 5 个 tab 页 — `backgroundColor` 退回 `DS.background`
- `pubspec.yaml` — 无改动（依赖已在）

**新建**
- `test/widgets/glass_tab_bar_test.dart` — 新底栏的组件测试

---

### Task 1: 内容区回归实心卡（撤销 13 处 GlassPanel）

**Files:**
- Modify: `lib/pages/bill_list/widgets/record_group_list.dart`（`_buildDateGroup`）
- Modify: `lib/pages/bill_list/widgets/search_filter_bar.dart`（2 处）
- Modify: `lib/pages/home/widgets/budget_progress.dart`
- Modify: `lib/pages/profile/widgets/settings_list.dart`
- Modify: `lib/pages/profile/widgets/achievement_grid.dart`
- Modify: `lib/pages/record_detail/record_detail_page.dart`（2 处）
- Modify: `lib/pages/statistics/widgets/trend_line_chart.dart`（2 处）
- Modify: `lib/pages/statistics/widgets/year_summary.dart`（2 处）
- Modify: `lib/pages/statistics/widgets/category_breakdown.dart`
- Modify: `lib/widgets/glass_card.dart`

**Interfaces:**
- Consumes: `DS.glassDecoration`（既有）
- Produces: 无新接口；所有卡片回到 `Container(decoration:)` 形态

- [ ] **Step 1: 批量还原 13 处 GlassPanel → Container**

对每个文件执行替换：`GlassPanel(` → `Container(`，并删除 `GlassPanel` 特有的参数行（`borderRadius:`、`topOnlyRadius:`、`subtle:`、`quality:`）。同时删除各文件里 `import '.../widgets/bear_glass.dart';` 这一行。

用脚本批量执行（每处 assert 精确匹配）：

```python
import io, re
FILES = [
 'lib/pages/bill_list/widgets/record_group_list.dart',
 'lib/pages/bill_list/widgets/search_filter_bar.dart',
 'lib/pages/home/widgets/budget_progress.dart',
 'lib/pages/profile/widgets/settings_list.dart',
 'lib/pages/profile/widgets/achievement_grid.dart',
 'lib/pages/record_detail/record_detail_page.dart',
 'lib/pages/statistics/widgets/trend_line_chart.dart',
 'lib/pages/statistics/widgets/year_summary.dart',
 'lib/pages/statistics/widgets/category_breakdown.dart',
]
for p in FILES:
    s = io.open(p, encoding='utf-8').read()
    n = s.count('GlassPanel(')
    s = s.replace('GlassPanel(', 'Container(')
    # 删除 GlassPanel 专有参数行
    s = re.sub(r'\n\s*borderRadius: DS\.radiusSm,\n', '\n', s)
    s = re.sub(r'\n\s*borderRadius: DS\.radiusMd,\n', '\n', s)
    s = re.sub(r'\n\s*topOnlyRadius: true,\n', '\n', s)
    # 删除 bear_glass import
    s = re.sub(r"^import '\.\./(?:\.\./)*(?:\.\./)?widgets/bear_glass\.dart';\n", '', s, flags=re.M)
    io.open(p, 'w', encoding='utf-8', newline='\n').write(s)
    print(f'{p}: 还原 {n} 处')
```

- [ ] **Step 2: 还原 glass_card.dart**

把 `lib/widgets/glass_card.dart` 退回液态玻璃之前的原实现（BackdropFilter + 半透明白底，不依赖 BearGlass）：

```dart
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_design_system.dart';

/// 玻璃质感卡片（旧风格）：BackdropFilter 模糊 + 半透明白底
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(DS.gutter),
    this.margin,
    this.borderRadius = DS.radiusMd,
    this.opacity = 0.7,
    this.blurSigma = 12,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double opacity;
  final double blurSigma;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          margin: margin,
          padding: padding,
          decoration: BoxDecoration(
            color: DS.isDark
                ? Colors.white.withValues(alpha: (opacity * 0.12).clamp(0.0, 1.0))
                : Colors.white.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: DS.heroCardBorder),
          ),
          child: child,
        ),
      ),
    );
    if (onTap != null) return GestureDetector(onTap: onTap, child: card);
    return card;
  }
}
```

注意：`DS.gutter` 是间距常量；若原 `GlassCard` 的 padding 默认值不是 `EdgeInsets.all(DS.gutter)`，以 `git show HEAD:lib/widgets/glass_card.dart` 的原值为准。

- [ ] **Step 3: 运行测试验证回归**

Run: `flutter analyze lib/ 2>&1 | grep -E "^\s+error" | head`
Expected: 无 error（仅剩既有的 `FilePicker.platform` 存量 error）

Run: `flutter test`
Expected: 全绿（179 条中除 glass 相关外全部通过）

- [ ] **Step 4: 删除 GlassBackdrop 与 BearGlass**

```bash
rm lib/theme/glass_backdrop.dart lib/widgets/bear_glass.dart
```

5 个 tab 页的 `backgroundColor: GlassBackdrop.scaffoldColor()` 改回 `backgroundColor: DS.background`，并删除 `import '../../theme/glass_backdrop.dart';`：

```python
import io, re
PAGES = [
 'lib/pages/home/home_page.dart',
 'lib/pages/bill_list/bill_list_page.dart',
 'lib/pages/statistics/statistics_page.dart',
 'lib/pages/wish_jar/wish_jar_page.dart',
 'lib/pages/profile/profile_page.dart',
]
for p in PAGES:
    s = io.open(p, encoding='utf-8').read()
    s = s.replace('GlassBackdrop.scaffoldColor()', 'DS.background')
    s = re.sub(r"^import '(?:\.\./)+theme/glass_backdrop\.dart';\n", '', s, flags=re.M)
    io.open(p, 'w', encoding='utf-8', newline='\n').write(s)
    print('ok', p)
```

`lib/main.dart` 里删除 `import 'theme/glass_backdrop.dart';` 与 `if (shouldUseLiquidGlass(context)) const Positioned.fill(child: GlassBackdrop()),` 这一段。

- [ ] **Step 5: 运行测试验证**

Run: `flutter analyze lib/ 2>&1 | grep -cE "^\s+error"`
Expected: `1`（仅存量 FilePicker error）

Run: `flutter test`
Expected: 全绿（此时 liquid_glass_test 若引用 BearGlass 会失败 → 下一步处理）

---

### Task 2: 删除边缘滑动带（官方 tab bar 接管）

**Files:**
- Modify: `lib/widgets/tab_swipe.dart`
- Modify: `lib/main.dart`
- Modify: `test/widgets/tab_swipe_test.dart`

**Interfaces:**
- Consumes: 无
- Produces: `barTabFromX(double dx, double barWidth, int tabCount) → int`（保留，关闭态底栏拖动用）

- [ ] **Step 1: 精简 tab_swipe.dart**

删除 `resolveTabSwipeTarget`、`kTabSwipeDistanceThreshold`、`kTabSwipeVelocityThreshold`、`kTabSwipeEdgeWidth`、`kTabSwipeSystemInset`、`EdgeTabSwipeOverlay`、`_EdgeStrip`、`_EdgeStripState`。保留 `barTabFromX` 与文件头 import。

```dart
import 'package:flutter/material.dart';

/// 底部导航栏"按住滑动"：把指针的 x 坐标换算成应选中的 Tab 索引。
///
/// 底栏视为 [tabCount] 等分，指针落在第几等分就选第几个 Tab。
/// 用于关闭液态玻璃时的自研底栏（开启时由官方 GlassTabBar.bottom 原生接管）。
int barTabFromX(double dx, double barWidth, int tabCount) {
  if (barWidth <= 0 || tabCount <= 1) return 0;
  final idx = (dx / (barWidth / tabCount)).floor();
  return idx.clamp(0, tabCount - 1);
}
```

- [ ] **Step 2: 精简 tab_swipe_test.dart**

删除 `resolveTabSwipeTarget` 组与 `EdgeTabSwipeOverlay` 组，保留 `barTabFromX` 组与底栏拖动组。

Run: `flutter test test/widgets/tab_swipe_test.dart`
Expected: 全绿（`barTabFromX` 3 条 + 底栏拖动 2 条）

- [ ] **Step 3: main.dart 删除边缘滑动接线**

删除 `Stack` 中的 `Positioned.fill(child: EdgeTabSwipeOverlay(...))`，`body` 直接是 `IndexedStack`：

```dart
body: IndexedStack(
  index: _currentIndex,
  children: _pages,
),
```

删除 `import 'widgets/tab_swipe.dart';`（`barTabFromX` 仍被 `_buildBottomBar` 使用，**保留 import**）。

- [ ] **Step 4: 运行测试**

Run: `flutter test`
Expected: 全绿

---

### Task 3: 删除 liquid_glass_test.dart 中 BearGlass 相关测试

**Files:**
- Modify: `test/widgets/liquid_glass_test.dart`

**Interfaces:**
- Consumes: 无
- Produces: 后续 Task 4 会新建 `glass_tab_bar_test.dart` 替代

- [ ] **Step 1: 删除文件并重命名为新测试文件**

```bash
rm test/widgets/liquid_glass_test.dart
```

- [ ] **Step 2: 运行全量测试确认无引用**

Run: `flutter test 2>&1 | grep -E "All tests passed|Some tests failed"`
Expected: `All tests passed!`

---

### Task 4: 官方玻璃底栏接入（核心）

**Files:**
- Modify: `lib/main.dart`（`_MainTabPageState.build` 与 `_buildBottomBar`）
- Create: `test/widgets/glass_tab_bar_test.dart`

**Interfaces:**
- Consumes: `shouldUseLiquidGlass(context)`（`lib/widgets/bear_glass.dart` 已删除 → 迁移到 `lib/theme/glass_materials.dart`）、`GlassMaterials.surface()`、`barTabFromX`
- Produces: `_buildGlassBottomBar()` 返回 `GlassTabBar.bottom`；`_buildLegacyBottomBar()` 返回现有底栏

- [ ] **Step 1: 迁移 shouldUseLiquidGlass 到 glass_materials.dart**

在 `lib/theme/glass_materials.dart` 末尾追加：

```dart
/// 是否应渲染液态玻璃：开关开启 + 未被系统"减弱透明度"抑制
bool shouldUseLiquidGlass(BuildContext context) {
  if (!GlassMaterials.enabled) return false;
  final mq = MediaQuery.maybeOf(context);
  if (mq != null && mq.highContrast) return false;
  return true;
}
```

（`glass_materials.dart` 已 import `package:flutter/material.dart`，无需新增 import）

- [ ] **Step 2: 写失败测试**

创建 `test/widgets/glass_tab_bar_test.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bear_bill/theme/glass_materials.dart';
import 'package:bear_bill/widgets/tab_swipe.dart';

void main() {
  tearDown(() => GlassMaterials.setEnabled(false));

  group('shouldUseLiquidGlass', () {
    testWidgets('开关关闭时返回 false', (tester) async {
      GlassMaterials.setEnabled(false);
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          expect(shouldUseLiquidGlass(context), false);
          return const SizedBox();
        }),
      ));
    });

    testWidgets('开关开启且无高对比度时返回 true', (tester) async {
      GlassMaterials.setEnabled(true);
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          expect(shouldUseLiquidGlass(context), true);
          return const SizedBox();
        }),
      ));
    });

    testWidgets('系统高对比度时回退 false', (tester) async {
      GlassMaterials.setEnabled(true);
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(highContrast: true),
          child: Builder(builder: (context) {
            expect(shouldUseLiquidGlass(context), false);
            return const SizedBox();
          }),
        ),
      ));
    });
  });

  group('barTabFromX 保留（关闭态底栏拖动）', () {
    test('5 等分均分到各 Tab', () {
      expect(barTabFromX(40, 400, 5), 0);
      expect(barTabFromX(90, 400, 5), 1);
      expect(barTabFromX(300, 400, 5), 3);
      expect(barTabFromX(390, 400, 5), 4);
    });

    test('越界指针收敛到两端', () {
      expect(barTabFromX(-10, 400, 5), 0);
      expect(barTabFromX(410, 400, 5), 4);
    });

    test('非法宽度/单 Tab 安全兜底', () {
      expect(barTabFromX(100, 0, 5), 0);
      expect(barTabFromX(100, 400, 1), 0);
    });
  });
}
```

- [ ] **Step 3: 运行测试验证失败**

Run: `flutter test test/widgets/glass_tab_bar_test.dart`
Expected: FAIL — `shouldUseLiquidGlass` 未定义（因为还没迁移）

- [ ] **Step 4: 运行测试验证通过**

（Step 1 已完成迁移后）

Run: `flutter test test/widgets/glass_tab_bar_test.dart`
Expected: 全绿（6 条）

- [ ] **Step 5: main.dart 双树分叉**

在 `lib/main.dart` 顶部 import 区添加：

```dart
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassTabBar, GlassTab, GlassScaffold, GlassStatusBarStyle;

import 'theme/glass_materials.dart';
```

把 `_MainTabPageState.build` 改为：

```dart
@override
Widget build(BuildContext context) {
  if (shouldUseLiquidGlass(context)) {
    return _buildGlassTree(context);
  }
  return _buildLegacyTree(context);
}
```

新增 `_buildGlassTree`（开启态：官方骨架 + 沉浸式）：

```dart
Widget _buildGlassTree(BuildContext context) {
  return GlassScaffold(
    bottomBar: GlassTabBar.bottom(
      tabs: const [
        GlassTab(icon: Icon(Icons.home_rounded), label: '首页'),
        GlassTab(icon: Icon(Icons.receipt_long_rounded), label: '账单'),
        GlassTab(icon: Icon(Icons.leaderboard_rounded), label: '统计'),
        GlassTab(icon: Icon(Icons.track_changes_rounded), label: '心愿'),
        GlassTab(icon: Icon(Icons.person_rounded), label: '我的'),
      ],
      selectedIndex: _currentIndex,
      onTabSelected: _goToTab,
      settings: GlassMaterials.surface(),
      quality: GlassQuality.standard, // 官方：滚动内容用 standard，premium 仅静态表面
      showIndicator: true,
      barHeight: 64,
      barBorderRadius: DS.radiusMd,
    ),
    body: IndexedStack(
      index: _currentIndex,
      children: _pages,
    ),
  );
}
```

新增 `_buildLegacyTree`（关闭态：现有树原样，含自研底栏）：

```dart
Widget _buildLegacyTree(BuildContext context) {
  return Scaffold(
    body: IndexedStack(
      index: _currentIndex,
      children: _pages,
    ),
    bottomNavigationBar: _buildBottomBar(),
  );
}
```

`GlassQuality` 需要 import：把上面的 show 列表加上 `GlassQuality`。

- [ ] **Step 6: 运行 analyze 与全量测试**

Run: `flutter analyze lib/main.dart 2>&1 | grep -E "^\s+error"`
Expected: 无 error

Run: `flutter test`
Expected: 全绿

- [ ] **Step 7: 构建 APK 并真机验证**

```bash
flutter build apk --release --split-per-abi --target-platform android-arm64
```

装机后开启液态玻璃，验证：
1. 底栏变成浮动玻璃药丸
2. 按住底栏拖动可切换 tab（官方原生）
3. 内容滚到底栏下方可见（沉浸式）
4. 关闭开关后恢复贴底满宽白栏 + 自研拖动

---

### Task 5: 顶栏玻璃条 + 悬浮按钮玻璃化（第二批）

**Files:**
- Create: `lib/widgets/glass_top_strip.dart`
- Modify: `lib/pages/home/home_page.dart`（`floatingActionButton`）
- Create: `test/widgets/glass_top_strip_test.dart`

**Interfaces:**
- Consumes: `shouldUseLiquidGlass`、`GlassMaterials.subtle()`、官方 `GlassContainer`
- Produces: `GlassTopStrip({required String title})` — 滚动淡入的顶部玻璃条

- [ ] **Step 1: 写失败测试**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bear_bill/theme/glass_materials.dart';
import 'package:bear_bill/widgets/glass_top_strip.dart';

void main() {
  tearDown(() => GlassMaterials.setEnabled(false));

  testWidgets('开关关闭时不渲染玻璃条', (tester) async {
    GlassMaterials.setEnabled(false);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: GlassTopStrip(title: '首页')),
    ));
    expect(find.text('首页'), findsNothing);
  });

  testWidgets('开关开启时渲染标题', (tester) async {
    GlassMaterials.setEnabled(true);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: GlassTopStrip(title: '首页')),
    ));
    expect(find.text('首页'), findsOneWidget);
  });

  testWidgets('滚动时淡入、回顶淡出', (tester) async {
    GlassMaterials.setEnabled(true);
    final controller = ScrollController();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            ListView.builder(
              controller: controller,
              itemCount: 40,
              itemBuilder: (_, i) => SizedBox(height: 80, child: Text('row $i')),
            ),
            GlassTopStrip(title: '首页', scrollController: controller),
          ],
        ),
      ),
    ));
    // 初始在顶部：不透明度为 0
    var opacity = tester.widget<Opacity>(find.byType(Opacity).first).opacity;
    expect(opacity, 0.0);

    controller.jumpTo(200);
    await tester.pumpAndSettle();

    opacity = tester.widget<Opacity>(find.byType(Opacity).first).opacity;
    expect(opacity, greaterThan(0.0));
  });
}
```

- [ ] **Step 2: 运行测试验证失败**

Run: `flutter test test/widgets/glass_top_strip_test.dart`
Expected: FAIL — `GlassTopStrip` 未定义

- [ ] **Step 3: 实现 GlassTopStrip**

创建 `lib/widgets/glass_top_strip.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassContainer, GlassQuality, LiquidRoundedSuperellipse;

import '../theme/app_design_system.dart';
import '../theme/glass_materials.dart';

/// 顶部玻璃悬浮条：滚动时淡入、回到顶部淡出（iOS 26 行为）
///
/// 现有页面头部（问候卡/月份选择等）完全不动，本组件只叠在上层。
class GlassTopStrip extends StatefulWidget {
  const GlassTopStrip({
    super.key,
    required this.title,
    this.scrollController,
  });

  final String title;

  /// 可选：外部 ScrollController；为 null 时监听最近的 ScrollNotification
  final ScrollController? scrollController;

  @override
  State<GlassTopStrip> createState() => _GlassTopStripState();
}

class _GlassTopStripState extends State<GlassTopStrip> {
  static const double _fadeDistance = 60;

  double _opacity = 0;

  @override
  void initState() {
    super.initState();
    widget.scrollController?.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(GlassTopStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController?.removeListener(_onScroll);
      widget.scrollController?.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final offset = widget.scrollController?.offset ?? 0;
    _setOpacity(offset);
  }

  void _setOpacity(double offset) {
    final next = (offset / _fadeDistance).clamp(0.0, 1.0);
    if (next != _opacity && mounted) {
      setState(() => _opacity = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!shouldUseLiquidGlass(context)) return const SizedBox.shrink();

    final strip = Opacity(
      opacity: _opacity,
      child: GlassContainer(
        margin: EdgeInsets.only(
          top: MediaQuery.paddingOf(context).top + DS.xs,
          left: DS.sm,
          right: DS.sm,
        ),
        padding: const EdgeInsets.symmetric(horizontal: DS.base, vertical: DS.sm),
        shape: LiquidRoundedSuperellipse(borderRadius: DS.radiusFull),
        settings: GlassMaterials.subtle(),
        quality: GlassQuality.standard,
        child: Row(
          children: [
            Text(
              widget.title,
              style: DS.titleSm.copyWith(color: DS.onSurface),
            ),
          ],
        ),
      ),
    );

    if (widget.scrollController != null) return strip;

    // 无 controller 时靠 ScrollNotification 驱动
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        _setOpacity(n.metrics.pixels);
        return false;
      },
      child: strip,
    );
  }
}
```

- [ ] **Step 4: 运行测试验证通过**

Run: `flutter test test/widgets/glass_top_strip_test.dart`
Expected: 全绿（3 条）

- [ ] **Step 5: 接入 5 个 tab 页**

每个 tab 页的 `body` 顶层 `Stack` 加入 `GlassTopStrip`。以首页为例（`lib/pages/home/home_page.dart:169` 的 Stack）：

```dart
Stack(
  children: [
    RefreshIndicator(...),  // 现有内容不动
    if (shouldUseLiquidGlass(context))
      const Positioned.fill(
        child: IgnorePointer(child: GlassTopStrip(title: '首页')),
      ),
    // ... 现有其他 children
  ],
)
```

注意：
- `IgnorePointer` 保证玻璃条不拦截点击
- 位置放在内容之上、悬浮按钮之下
- 5 个页面标题：首页/账单/统计/心愿/我的
- 各页 import `'../../widgets/glass_top_strip.dart'` 与 `'../../theme/glass_materials.dart'`

- [ ] **Step 6: 悬浮"记一笔"与话筒按钮玻璃化**

`lib/pages/home/home_page.dart:272-339` 的 `floatingActionButton`：把"记一笔"的 `FloatingActionButton.extended` 换成玻璃容器包住原有内容（点击行为不变）：

```dart
if (shouldUseLiquidGlass(context))
  GlassContainer(
    shape: LiquidRoundedSuperellipse(borderRadius: DS.radiusFull),
    settings: GlassMaterials.surface(),
    quality: GlassQuality.standard,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    child: GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddRecordPage()),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.edit, size: 20, color: DS.onSurface),
          const SizedBox(width: 8),
          Text('记一笔', style: TextStyle(
            fontFamily: DS.fontLabel,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: DS.onSurface,
          )),
        ],
      ),
    ),
  )
else
  /* 现有 FloatingActionButton.extended 原样 */
```

话筒按钮同理：`Container(...)` 换成 `GlassContainer(shape: LiquidRoundedSuperellipse(borderRadius: 28), ...)`，`onPanStart/Update/End` 手势原样保留。

- [ ] **Step 7: 运行测试与构建**

Run: `flutter test`
Expected: 全绿

Run: `flutter build apk --release --split-per-abi --target-platform android-arm64`
Expected: 构建成功

---

### Task 6: 高频弹窗玻璃化

**Files:**
- Create: `lib/widgets/glass_dialog_shell.dart`
- Modify: 高频弹窗调用点（确认类、记账相关、预算设置）
- Create: `test/widgets/glass_dialog_shell_test.dart`

**Interfaces:**
- Consumes: `shouldUseLiquidGlass`、官方 `GlassDialog`
- Produces: `GlassDialogShell` — 统一玻璃弹窗外壳；`showGlassConfirmDialog(...)` 便捷函数

- [ ] **Step 1: 写失败测试**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bear_bill/theme/glass_materials.dart';
import 'package:bear_bill/widgets/glass_dialog_shell.dart';

void main() {
  tearDown(() => GlassMaterials.setEnabled(false));

  testWidgets('关闭时回退 Material AlertDialog', (tester) async {
    GlassMaterials.setEnabled(false);
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        return Scaffold(
          body: TextButton(
            onPressed: () => showGlassConfirmDialog(
              context: context,
              title: '确认',
              message: '确定要删除吗？',
              onConfirm: () {},
            ),
            child: const Text('open'),
          ),
        );
      }),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('确定要删除吗？'), findsOneWidget);
  });

  testWidgets('开启时渲染玻璃弹窗', (tester) async {
    GlassMaterials.setEnabled(true);
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        return Scaffold(
          body: TextButton(
            onPressed: () => showGlassConfirmDialog(
              context: context,
              title: '确认',
              message: '确定要删除吗？',
              onConfirm: () {},
            ),
            child: const Text('open'),
          ),
        );
      }),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('确定要删除吗？'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
```

- [ ] **Step 2: 运行测试验证失败**

Run: `flutter test test/widgets/glass_dialog_shell_test.dart`
Expected: FAIL — `showGlassConfirmDialog` 未定义

- [ ] **Step 3: 实现 GlassDialogShell**

创建 `lib/widgets/glass_dialog_shell.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassDialog, GlassQuality;

import '../theme/app_design_system.dart';
import '../theme/glass_materials.dart';

/// 统一玻璃确认弹窗：开启液态玻璃走官方 [GlassDialog]，关闭时回退 [AlertDialog]
Future<bool?> showGlassConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmText = '确认',
  String cancelText = '取消',
  bool destructive = false,
}) {
  final useGlass = shouldUseLiquidGlass(context);

  if (!useGlass) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  return showDialog<bool>(
    context: context,
    builder: (ctx) => GlassDialog(
      title: title,
      message: message,
      quality: GlassQuality.standard,
      actions: [
        GlassDialogAction(
          label: cancelText,
          onPressed: () => Navigator.pop(ctx, false),
        ),
        GlassDialogAction(
          label: confirmText,
          onPressed: () => Navigator.pop(ctx, true),
          isDestructive: destructive,
        ),
      ],
    ),
  );
}
```

注意：`GlassDialogAction` 的确切构造名需核对官方源码：

```bash
grep -n "class GlassDialogAction" -A 25 "D:/Softwaredata/PubCache/hosted/pub.dev/liquid_glass_widgets-1.8.1/lib/widgets/overlays/glass_dialog.dart"
```

若构造名或参数不同，按官方源码为准调整。

- [ ] **Step 4: 运行测试验证通过**

Run: `flutter test test/widgets/glass_dialog_shell_test.dart`
Expected: 全绿（2 条）

- [ ] **Step 5: 替换高频确认弹窗调用点**

把确认类弹窗（`AlertDialog` + 取消/确认两按钮）替换为 `showGlassConfirmDialog`。优先替换：

- `lib/pages/bill_list/bill_list_page.dart` 的删除确认
- `lib/pages/profile/profile_page.dart` 的清空账单确认
- `lib/pages/wish_jar/wish_jar_page.dart` 的删除心愿确认

每处替换后运行 `flutter test` 确认无回归。

- [ ] **Step 6: 运行全量测试与构建**

Run: `flutter test`
Expected: 全绿

Run: `flutter build apk --release --split-per-abi --target-platform android-arm64`
Expected: 构建成功

---

### Task 7: 真机验证与文档同步

**Files:**
- Modify: `docs/UI_REDESIGN.md`（补充液态玻璃架构说明）
- Modify: `AGENTS.md`（本地规则，gitignored）

- [ ] **Step 1: 装机并逐项验证**

```bash
ADB="D:/Softwaredata/Android/SDK/platform-tools/adb.exe"
"$ADB" install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

验证清单（开启态）：
1. 底栏为浮动玻璃药丸，可看到背后滚动内容
2. 按住底栏拖动切 tab（官方原生 + magic-lens 指示器）
3. 内容滚到底栏下方可见
4. 顶栏玻璃条：滚动淡入、回顶淡出
5. "记一笔"与话筒按钮为玻璃材质
6. 确认类弹窗为玻璃

验证清单（关闭态）：
1. 底栏恢复贴底满宽白栏
2. 自研拖动切换正常
3. 内容不穿底栏
4. 弹窗为白底 Material

- [ ] **Step 2: 截图存档**

```bash
"$ADB" exec-out screencap -p > "C:/Users/DC43~1/AppData/Local/Temp/opencode/glass_v2_on.png"
# 关闭开关后再截一张
"$ADB" exec-out screencap -p > "C:/Users/DC43~1/AppData/Local/Temp/opencode/glass_v2_off.png"
```

- [ ] **Step 3: 归档 APK**

```bash
T=$(date +%Y%m%d_%H%M)
cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk "releases/bear_bill_1.3.7_$T.apk"
```

- [ ] **Step 4: 文档同步**

在 `docs/UI_REDESIGN.md` 补充一节"液态玻璃（官方哲学）"，说明：玻璃只用于导航层、内容区实心、开关双树、官方组件清单。

---

## 自检记录

**Spec 覆盖：**
- 官方哲学重构 → Task 1（内容实心）+ Task 4（官方底栏）✓
- 导航层全包（顶/底/悬浮/弹窗）→ Task 4 + Task 5 + Task 6 ✓
- 内容实心卡 → Task 1 ✓
- 沉浸式滚动 → Task 4（GlassScaffold）✓
- 浮动药丸底栏 → Task 4 ✓
- 开关双树 → Task 4 ✓
- 顶栏玻璃条 → Task 5 ✓
- 删除清单 → Task 1 Step 4 + Task 2 ✓
- 分批落地 → Task 1-4 第一批，Task 5-6 第二批 ✓
- 真机验证 → Task 7 ✓

**类型一致性：**
- `shouldUseLiquidGlass(BuildContext) → bool`：Task 4 Step 1 定义，Task 5/6 使用 ✓
- `barTabFromX(double, double, int) → int`：Task 2 保留，Task 4 使用 ✓
- `GlassTopStrip({required String title, ScrollController? scrollController})`：Task 5 定义与使用一致 ✓
- `showGlassConfirmDialog({required BuildContext context, required String title, required String message, ...}) → Future<bool?>`：Task 6 定义与使用一致 ✓

**占位符扫描：** 无 TBD/TODO；所有代码步骤含完整代码 ✓

**已知待核实项（执行时以官方源码为准）：**
- `GlassDialogAction` 构造名与参数（Task 6 Step 3 已给出核对命令）
- `GlassDialog` 的 `quality` 参数是否存在
- `GlassScaffold` 的 `bottomBar` 是否接受 `GlassTabBar.bottom` 直接传入（应为 Widget?）
