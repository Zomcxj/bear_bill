# UI 设计系统说明

## 当前设计基线

小熊记账本当前 UI 基线为 `Luminous Finance` 玻璃态设计系统，不再是早期的纯“软萌粉糖风”页面集合。

当前版本：`v1.3.7`

## 视觉语言

| 维度 | 当前设计 |
|------|----------|
| 主题 | Luminous Finance + Glassmorphism |
| 背景 | 微灰白底，配合毛玻璃层次 |
| 卡片 | 玻璃态卡片、柔和描边、半透明表面 |
| 字体 | Plus Jakarta Sans + Manrope |
| 圆角 | 统一由设计系统常量管理 |
| 间距 | 统一由设计系统常量管理 |
| 图标 | Material Icons + 业务 Emoji |

说明：

- 颜色、间距、圆角应统一走 `AppTheme` / `DS`
- 不建议在页面内硬编码视觉常量

## 主要导航结构

底部导航当前为 5 个 tab，和 `main.dart` 的 `IndexedStack` 一致：

1. 首页
2. 账单
3. 统计
4. 心愿
5. 我的

## 当前已落地范围

### 基础设施

- `lib/theme/app_design_system.dart`
- `lib/theme/app_theme.dart`

### 公共组件

- `lib/widgets/glass_card.dart`
- `lib/widgets/pill_button.dart`
- `lib/widgets/app_card.dart`

### 主要页面

- 首页
- 账单页
- 统计页
- 心愿罐
- 我的
- AI 对话记账页
- 预算、导出、多账本、消费地图、账单详情等附属页面

## 设置页与关于页现状

设置页当前信息：

- 自动记账入口：`通知监听`
- 关于页版本：`v1.3.7`

对应文件：

- `lib/pages/profile/widgets/settings_list.dart`

说明：

- 关于页文案建议改为当前品牌口径，避免继续使用早期“软萌粉糖风”定位
- 当前整体 UI 基线为 `Luminous Finance` 玻璃态视觉风格
- README、关于页、设计文档中的视觉描述与自动记账说明应保持一致

## 自动记账相关 UI 口径

如果文档或页面提到自动记账，当前正确口径应为：

- 监听支付宝/银行卡通知
- 识别后跳转记账页确认
- 不是无障碍主路径
- 不是直接静默入账

## 测试与验证

当前仓库里和设计系统相关的验证至少包括：

- `test/theme/ds_test.dart`
- `test/widgets/app_card_test.dart`
- `test/widgets/glass_card_test.dart`

说明：

- 设计系统层已经有基础自动化测试
- 页面视觉改动后，优先保证设计 token 与基础组件不回退

## 当前构建验证口径

当前发布构建规则：

```bash
flutter build apk --release --target-platform android-arm64 --split-per-abi
```

当前产物路径：

```text
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

发布归档命名规则：

```text
releases/bear_bill_{x.y.z}_{YYYYMMDD}_{HHmm}.apk
```

## 维护建议

- 新页面优先复用现有玻璃态组件
- 颜色、圆角、间距只从设计系统取值
- 若 README、关于页、页面内文案描述视觉风格不一致，应一并修正

## 液态玻璃（官方哲学）

设置页「液态玻璃」开关控制新旧两套 UI，默认关闭：

- **关闭态**：原有视觉与交互完全保留（贴底满宽白底栏、实心卡片），老用户体验零变化
- **开启态**：按 iOS 26 官方设计哲学重构——**玻璃只用于导航/控制层**，内容区保持不透明

### 为什么内容区不做玻璃

玻璃效果依赖折射背后的内容才可见；内容卡片自身变玻璃等于"白底叠白雾"，
视觉上几乎无变化（早期版本踩过这个坑）。iOS 26 的玻璃感来自
"导航层浮动在彩色内容之上"，因此：

- 内容区：实心卡片（`DS.glassDecoration`），滚动内容从玻璃导航层下方穿过
- 导航层：底栏、顶栏玻璃条、子页面顶栏、悬浮按钮、确认弹窗使用真玻璃材质

### 开启态组件

| 位置 | 实现 | 说明 |
|---|---|---|
| 底栏 | 官方 `GlassTabBar.bottom` | 浮动药丸、magic-lens 指示器、原生按住拖动切换、jelly 物理动画 |
| 骨架 | 官方 `GlassScaffold` | 沉浸式滚动、边缘渐隐、状态栏图标自适应、安全区 |
| 顶栏 | `GlassTopStrip` | 滚动淡入、回顶淡出（iOS 26 行为），不拦截点击 |
| 子页面顶栏 | `GlassSubPageBar` | 胶囊玻璃条（返回键 + 居中标题 + 操作区），关闭态回退标准 `AppBar` |
| 悬浮按钮 | `GlassContainer` 包裹 | 「记一笔」药丸 + 话筒圆形，手势行为不变 |
| 确认弹窗 | `showGlassConfirmDialog` | 官方 `GlassDialog`，关闭态回退 `AlertDialog` |
| 通用弹窗 | `showGlassDialog` / `showGlassPanel` | 前者走官方 `GlassDialog`（1~3 按钮）；后者自绘按钮区，供超过 3 个按钮或自定义布局的弹窗使用 |
| 日期选择 | `showGlassDatePicker` | 底部悬浮玻璃托盘（取消/标题/确定 + Cupertino 滚轮），关闭态保留原白底样式 |
| 时间选择 | `showReminderDialog` | 记账提醒设置：悬浮玻璃托盘 + 时/分滚轮，关闭态保留原白底样式 |
| 数字键盘 | `CustomKeyboard` | 记一笔：悬浮玻璃托盘 + 玻璃片键面（高光渐变/描边/投影/按压反馈），关闭态保留原白底样式 |
| 关于 / 字号调整 / 帮助 / 预算 | `showGlassDialog` 系列 | 帮助内容固定高度滚动；字号/关于走自绘玻璃选项行与文案 |

### 内容卡内 CTA 的"玻璃着色层"

官方 SKILL 两条铁律仍然成立：

1. **玻璃是"托盘"不是"包裹层"**——只用于导航/控制层；内容卡片保持干净可读
2. **绝不把折射玻璃嵌进折射玻璃**——`GlassButton` 放进 `GlassCard` 会双重折射

但内容卡内的主 CTA（心愿卡「存入」、键盘「完成」等）已从"实心配色"升级为
**玻璃着色层**：不建折射图层（避免玻璃套玻璃），而是用"高光渐变 + 描边 +
轻投影"在卡片表面上模拟玻璃片质感，与键盘键面同一套视觉语言。
关闭态仍保持实心主色胶囊，零漂移。

### 玻璃片"显形"规律（亮/暗两套）

纯白半透明在白卡上是隐形的。玻璃着色层按表面明暗选择描边：

- **浅色表面**：深色细边（黑 10~12%）+ 顶部高光渐变 + 轻投影
- **深色表面**：白色细边（白 16~25%）

即"深色表面用亮边、浅色表面用深边"。`GlassPanelButton` 的非 primary
样式、键盘键面、存入按钮、字号选项行均遵循此规律。

### 为什么内容区按钮不做玻璃

官方 SKILL 明文规定两条铁律：

1. **玻璃是"托盘"不是"包裹层"**——只用于导航/控制层；内容卡片保持干净可读
2. **绝不把折射玻璃嵌进折射玻璃**——`GlassButton` 放进 `GlassCard` 会双重折射、
   卡住 jelly 动画、浪费 GPU

因此内容卡内的 CTA（心愿卡「存入」、记账键盘「完成」等）不套 `GlassButton`，
改为**玻璃着色层**（详见上文"内容卡内 CTA 的玻璃着色层"一节）。

### 关键约束

- 材质参数集中在 `lib/theme/glass_materials.dart`，不自由发挥
- 滚动内容用 `GlassQuality.standard`；官方明确 premium 仅适合静态表面
  （在 ListView/CustomScrollView 中可能渲染异常）；贴底静态托盘/键盘用 `premium`
- **弹窗/独立路由里的 `GlassContainer` 必须显式 `useOwnLayer: true`**：
  默认 grouped 模式会静默忽略 per-widget `settings`，玻璃材质参数不生效
- 关闭态底栏的按住拖动由自研 `barTabFromX` 提供（`lib/widgets/tab_swipe.dart`）

### 黄线根因与全局修复（重要历史）

玻璃控件（`GlassDialog` / `GlassTabBar` / 分段控件 / 自绘弹窗）是纯自绘、
**无 Material 祖先**，会继承 `MaterialApp` 兜底样式：

- Flutter 在 `widgets/app.dart` 把 `_errorTextStyle`（`material/app.dart:45`，
  `decorationColor: Color(0xFFFFFF00)` + `TextDecorationStyle.double`）设为
  **根 `DefaultTextStyle`**（仅用于兜底，正常页面被 Material 的
  `bodyMedium` 覆盖；玻璃控件自身 style 没写 `decoration` 就漏继承）
- 症状：玻璃弹窗/底栏/分段控件文本下有 1px 黄色双下划线（`#FFFF00`）
- 修复：`main.dart` 的 `MaterialApp.builder` 根部包
  `DefaultTextStyle(style: TextStyle(decoration: TextDecoration.none))`，
  一处根治所有玻璃控件；深层 Material 各自覆盖不受影响
- A/B 实测确认：玻璃开 + 无障碍关 → 有黄线；玻璃关 → 无黄线（排除输入法/无障碍）

### 材质与圆角取值依据（对齐官方 + 参考案例）

- **导航层材质用 `GlassMaterials.bar()`**：对齐官方 `kBottomBarGlassDefaults`
  的 iOS 26 调校（thickness 30 / 折射率 1.59 / 135° 光源 / 24% 白底 /
  chromaticAberration 0.3 / saturation 0.7）。这是 Apple News / Safari
  底栏实测参数；用更淡的自调参数（12% 白 + blur 20）会导致药丸过透明、
  文字发虚。
- **底栏圆角用真胶囊哨兵值 `GlassDefaults.capsuleRadius`**（官方注释：
  jelly 膨胀期间 shader 仍钳制为胶囊；有限半径如 32 在膨胀时会显方）。
  参考案例站导航药丸同为胶囊（samasante `borderRadius: 999`、
  archisvaze `50px`）。
- **悬浮按钮/顶栏条**同用 `bar()` 材质 + 胶囊/圆形，与底栏质感统一。
- 内容卡圆角保持 `DS.radiusMd`(16)，参考站卡片 18–24，处于同一量级。

### 文件清单

- `lib/theme/glass_materials.dart`：材质参数 + `shouldUseLiquidGlass()` 判定
- `lib/widgets/tab_swipe.dart`：`barTabFromX`（关闭态底栏拖动换算）
- `lib/widgets/glass_top_strip.dart`：顶栏玻璃条 + `glassStripOpacityFor()`
- `lib/widgets/glass_dialog_shell.dart`：`showGlassConfirmDialog()` /
  `showGlassDialog()` / `showGlassPanel()` / `GlassPanelButton` /
  `GlassDialogField` + 输入装饰
- `lib/widgets/glass_date_picker.dart`：`showGlassDatePicker()`（玻璃日期托盘）
- `lib/widgets/glass_sub_page_bar.dart`：子页面玻璃顶栏
- `lib/pages/add_record/widgets/custom_keyboard.dart`：玻璃数字键盘 + 按压反馈
- `lib/pages/profile/widgets/reminder_dialog.dart`：记账提醒玻璃托盘
- `lib/pages/profile/widgets/font_size_dialog.dart`：字号调整（玻璃选项行）
- `lib/main.dart`：`_buildGlassTree()` / `_buildLegacyTree()` 双树分叉 +
  `MaterialApp.builder` 黄线根治 + 字号 textScaler
