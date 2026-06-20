# UI 重构方案 — Luminous Finance 设计系统

## 设计风格

| 维度 | 旧风格 | 新设计 |
|------|--------|--------|
| 主题 | 软萌粉糖色系 | Corporate Modern + Glassmorphism |
| 主色 | 粉色 #FFB6C1 | 黑色 #000000 + 天蓝 #00668a / #40c2fd |
| 辅色 | 暖橙/棕 | 粉色 #d3579a (tertiary 强调) |
| 背景 | 纯色 #FFF5F5 | #f7f9fb 微灰白 |
| 卡片 | 实色白底圆角 | 毛玻璃 rgba(255,255,255,0.7) + backdrop-blur |
| 按钮 | 圆角矩形 | 胶囊形 pill-shaped |
| 图标 | emoji | Material Symbols Outlined |
| 字体 | 系统字体 | Plus Jakarta Sans + Manrope |
| 圆角 | 16px | 8/16/32/48/full 五级 |
| 间距 | 8/12/16/24px | 4/8/12/16/24/40/64px |

## 底部导航

5 tab 毛玻璃底栏：
- home 首页
- receipt_long 账单
- leaderboard 统计
- track_changes 目标 (心愿罐)
- person 我的

活跃 tab: 黑色圆形填充 + 白色图标
非活跃: 灰色 outline 图标

## 实施状态

### Phase 1 — 基础设施 ✅
- [x] 配置 pubspec.yaml 字体引入 (Plus Jakarta Sans + Manrope)
- [x] 新建 lib/theme/app_design_system.dart (DS 类，全部 Token)
- [x] 更新 app_theme.dart

### Phase 2 — 公共组件 ✅
- [x] 重写底部导航栏 (5 tab 毛玻璃)
- [x] GlassCard 组件 (lib/widgets/glass_card.dart)
- [x] PillButton 组件 (lib/widgets/pill_button.dart)

### Phase 3 — 页面重写 ✅
- [x] 首页 home_page.dart + 4 个子组件
- [x] 记账页 add_record_page.dart + 7 个子组件
- [x] 统计页 statistics_page.dart + 7 个子组件
- [x] 账单页 bill_list_page.dart + 5 个子组件
- [x] 心愿罐 wish_jar_page.dart + 3 个子组件
- [x] 我的页 profile_page.dart + 6 个子组件
- [x] 其他页面: budget_page, export_page, multi_book_page, map_footprint, record_detail

### Phase 4 — AI 记账 ✅
- [x] ai_chat_page.dart + 2 个子组件

### 构建验证 ✅
- [x] flutter analyze: 0 errors, 281 info
- [x] APK 构建成功: 10.5MB (arm64)
- [x] releases/bear_bill_v1.3.0_ui_redesign_20260620_1807.apk
