# UI 设计系统说明

## 当前设计基线

小熊记账本当前 UI 基线为 `Luminous Finance` 玻璃态设计系统，不再是早期的纯“软萌粉糖风”页面集合。

当前版本：`v1.3.6`

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
- 关于页版本：`v1.3.6`

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
flutter build apk --release --target-platform android-arm64
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
