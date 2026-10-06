# 液态玻璃官方哲学重构 · 设计文档

日期：2026-10-04
状态：已获老大批准（"按照你的想法做，完工后我审核"）

## 背景与问题

前几轮把液态玻璃做在了**内容卡片**上（13 处 `GlassPanel`），并把"看不见"的问题
归因于背景太素，靠加彩色光斑（`GlassBackdrop`）解决。对照官方
`liquid_glass_widgets` 1.8.1 文档后确认方向错了：

1. 官方设计哲学明确：**玻璃只用于导航/控制层**（顶栏、底栏、悬浮按钮、弹窗），
   内容区（列表、卡片）保持不透明。理由：玻璃靠折射背后内容才有戏，
   内容卡片自己变玻璃 = 白底叠白雾 = 看不见。
2. 官方 `GlassTabBar.bottom` **原生自带按住拖动切换**（`tab_bar_drag_gesture_mixin.dart`），
   含 magic-lens 指示器与 jelly 物理动画。项目手搓的 `barTabFromX` 底栏拖动
   与 `EdgeTabSwipeOverlay` 边缘滑动属于重复造轮子。
3. 官方标注 `GlassQuality.premium` **仅适合静态表面，在 ListView/滚动列表中可能渲染异常**。
   项目曾给 13 处滚动列表卡片全上 premium，正好踩中官方警告。
4. 参考案例中的 `whynotmake-it/flutter_liquid_glass`（即 `liquid_glass_renderer`）
   已被 `liquid_glass_widgets` vendored（官方 README 致谢声明），无需引入第二个包。

## 决策记录（老大已确认）

| 议题 | 决策 |
|---|---|
| 改造范围 | 按官方哲学重构（方案 1） |
| 导航层范围 | 顶栏 + 底栏 + 悬浮"记一笔" + 弹窗，全部玻璃化 |
| 内容区 | 完全回归实心卡（撤销 13 处 GlassPanel） |
| 玻璃折射源 | 内容滚动穿到底栏下（沉浸式），不用光斑背景 |
| 底栏外观 | 浮动药丸式（官方默认），接受与"贴底满宽"的外观变化 |
| 开关语义 | 开关控制新旧两套：开=玻璃导航层，关=现有旧树（可回退） |
| 顶栏形态 | 叠一条玻璃悬浮条（不换官方 GlassAppBar，保留现有头部排版） |

## 架构

### 双树策略

`MainTabPage` 依据 `shouldUseLiquidGlass(context)` 分叉：

- **开启态**：官方 `GlassScaffold` 骨架
  - `body`: 现有 `IndexedStack`（5 页状态不丢，切 tab 不重建）
  - `bottomBar`: `GlassTabBar.bottom`（5 个 `GlassTab`）
  - `GlassScaffold` 自带：内容穿到底栏下的沉浸式滚动、滚动边缘渐隐、
    状态栏图标自适应、安全区处理、bar 隔离（`GlassIsolationScope`）
- **关闭态**：完全保留现有树（`Scaffold` + `_buildBottomBar` + `barTabFromX` 拖动）

### 内容区回归

- 13 处 `GlassPanel` → 退回 `Container(decoration: DS.glassDecoration)` 原样
- `GlassCard` → 退回液态玻璃之前的原实现
- 删除 `GlassBackdrop`（光斑背景是"玻璃看不见"的补丁，新方案不需要）

### 手搓滑动的去留

- 开启态：官方 tab bar 自带拖动切换，边缘滑动带删除
- 关闭态：保留 `barTabFromX` 底栏按住拖动（已有 5 条测试），老用户不丢功能
- 删除 `EdgeTabSwipeOverlay`、`resolveTabSwipeTarget` 及对应测试（官方接管）

### 删除 / 保留清单

| 删除 | 保留 |
|---|---|
| `lib/theme/glass_backdrop.dart` | `lib/theme/glass_materials.dart`（喂官方组件材质参数） |
| `lib/widgets/bear_glass.dart`（BearGlass / GlassPanel） | `shouldUseLiquidGlass()`（判定入口） |
| `EdgeTabSwipeOverlay` / `resolveTabSwipeTarget` | `barTabFromX`（关闭态底栏拖动） |
| 13 处 GlassPanel 使用点 | 设置页开关 + 持久化逻辑 |

## 组件设计

### 底栏

- 开启：`GlassTabBar.bottom`，5 个 `GlassTab`（首页/账单/统计/心愿/我的），
  浮动药丸、magic-lens 指示器、原生拖动切换、jelly 动画
- 关闭：现有 `_buildBottomBar` 原样 + `barTabFromX` 拖动

### 顶栏玻璃条（第二批）

- 新增 `GlassTopStrip`：叠在页面顶部的一条细玻璃条，显示页面标题
- 滚动时淡入、回到顶部淡出（`NotificationListener<ScrollNotification>`，
  不给每页塞 ScrollController）——对应 iOS 26"滚动出现玻璃条"行为
- 现有头部（问候卡/月份选择等）完全不动，玻璃条只叠在上层

### 悬浮按钮（第二批）

- "记一笔"：玻璃容器包住现有图标+文字，点击行为不变
- 话筒按钮：同样玻璃化，`onPanStart/Update/End` 录音手势原样保留

### 弹窗（第二批）

- 新增 `GlassDialogShell`：统一玻璃外壳（圆角、材质、关闭态回退白底），
  内容沿用现有
- 项目共 37 处 `showDialog`（30 个内联 `AlertDialog` + 4 个自定义 Dialog 类）
  + 4 处 `showModalBottomSheet`
- 分批策略：先转高频弹窗（确认类、记账相关、预算设置），其余保持白底
  Material 弹窗照常工作，后续按批补
- 4 个 BottomSheet 用玻璃外壳包

## 落地分批

- **第一批**：底栏 + 沉浸式（视觉冲击最大，先验）
- **第二批**：顶栏玻璃条 + 悬浮按钮 + 高频弹窗

## 验证方式

- 单元/组件测试：开关两态各自的底栏形态、拖动切换、tab 切换回调
- 真机验证（adb）：底栏按住拖动、内容滚到底栏下可见、开关切换对比截图
- 关闭态回归：现有 179 条测试全绿（老用户体验零变化）

## 风险与回退

| 风险 | 应对 |
|---|---|
| 官方 tab bar 在真机渲染异常 | 关闭态树完整保留，一键回退 |
| `GlassScaffold` 与现有页面结构冲突（如 SafeArea/RefreshIndicator） | 分批落地，第一批只动底栏；页面内部结构不动 |
| 低端设备性能 | 开关可关；官方 `adaptiveQuality: true` 已在 `wrap()` 启用 |
| 弹窗改造量大 | 只转高频弹窗，其余保持可用 |
