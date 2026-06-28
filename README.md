# 🐻 小熊记账本

一个基于 Flutter 开发的软萌粉糖色系移动端记账应用

---

## ✨ 功能特性

### 📊 核心功能
- **账单管理** - 支持支出/收入记录，分类选择，心情标签，图片附件
- **AI 对话记账** - 自然语言输入，智能识别分类/金额/备注/日期，支持语音输入
- **多账本管理** - 创建/切换/删除账本，数据隔离，独立统计
- **统计分析** - 甜甜圈图分类统计、周趋势图、月度对比、热力日历
- **年度总结** - 年度收支总览、12 个月趋势柱状图、年度分类 Top 5
- **心愿罐** - 设定储蓄目标，存钱进度追踪，完成庆祝动画
- **预算设置** - 月度预算设置，快捷金额，每日可用计算，超支提醒
- **账单导出** - CSV 格式导出，月份选择，文件保存到本地
- **成就系统** - 24个预定义成就，解锁状态追踪，进度百分比，徽章展示
- **等级系统** - 6级小熊形态变化，经验值累积，自动升级
- **打卡功能** - 连续记账天数统计，断签重置，已记账自动跳过提醒
- **主题颜色** - 8 种预设主题色 + 自定义调色盘（HSV 滑块），全应用同步
- **消费地图** - 地图标注消费位置，足迹可视化
- **自动记账** - 监听支付宝/银行通知，识别后跳转记账页确认
- **本地存储** - SQLite 数据库，数据安全，离线可用

### 🤖 AI 记账功能
- **自然语言解析** - 输入"午餐25"自动识别分类、金额、备注、日期
- **语音输入** - 百度语音识别，按住说话，上滑取消，静音自动停止
- **首页话筒** - 首页按住话筒直接说话，说完自动进入 AI 对话
- **智能追问** - 只说"交通"会追问金额，补上后自动记账
- **多维查询** - 按分类/心情/位置/日期范围查询账单
- **心情选择** - 确认前可选心情 emoji
- **GPS 定位** - 自动获取位置，支持地图选点

### 🎨 UI/UX 特色
- **主题色系统** - 支持 8 种预设颜色（粉/蓝/绿/橙/黄/红/紫/黑）+ 自定义调色盘
- **Emoji 图标** - 所有分类、心情、成就均使用 Emoji
- **动画效果** - 浮动、缩放、渐变动画，提升交互体验
- **空状态引导** - 无数据时显示友好提示和操作引导
- **二次确认** - 删除操作均有确认弹窗，防止误删
- **年月快速选择** - 账单和统计页支持点击月份文字弹出年月选择器

## 🚀 快速开始

### 环境要求

- Flutter SDK 3.24.0+
- Dart SDK 3.5.0+
- Android SDK (API 21-36)
- JDK 17+
- Gradle 8.2+

> 📖 详细环境配置请查看 [docs/CONFIGURATION.md](docs/CONFIGURATION.md)

### 配置 API 密钥

本项目使用三个第三方 API 服务，所有密钥统一配置在 `lib/config/api_keys.dart` 中：

```bash
cp lib/config/api_keys.dart.template lib/config/api_keys.dart
# 编辑 api_keys.dart，填入以下密钥
```

| 服务 | 用途 | 申请地址 |
|------|------|---------|
| **高德地图** | 地图定位、反向地理编码 | https://console.amap.com/ |
| **大模型** (GLM/通义/DeepSeek) | AI 智能记账解析 | 见 api_keys.dart.template |
| **百度语音** | 语音输入识别 | https://console.bce.baidu.com/ |

> 📖 详见 [docs/CONFIGURATION.md](docs/CONFIGURATION.md#api-密钥配置)

### 构建应用

```bash
flutter build apk --release
```

APK 输出位置：`build/app/outputs/flutter-apk/app-release.apk`

> ⚠️ Windows 用户名包含中文时需先配置环境变量。详见 [docs/CONFIGURATION.md](docs/CONFIGURATION.md#中文路径问题)

### 运行调试

```bash
flutter pub get
flutter run
```

## 📚 文档导航

| 文档 | 说明 |
|------|------|
| [📖 完整配置指南](docs/CONFIGURATION.md) | 环境配置、API 密钥、依赖路径、构建详解 |
| [🔧 维护指南](docs/MAINTENANCE.md) | 缓存管理、清理命令、常见问题 |
| [📍 依赖路径速查](docs/DEPENDENCIES_PATH.md) | 所有外部依赖的详细路径和引用位置 |

## 🛠️ 技术栈

- **框架**: Flutter 3.24.0 / Dart 3.5.0
- **状态管理**: Provider ^6.1.1
- **本地数据库**: sqflite ^2.3.0
- **图表组件**: fl_chart ^0.66.0
- **地图**: flutter_map + latlong2
- **AI 大模型**: GLM-4-Flash（可切换通义/DeepSeek）
- **语音识别**: 百度语音 REST API + Android 原生 AudioRecord
- **定位**: geolocator + 高德地图

## 📄 许可证

本项目仅供学习和个人使用。

---

<div align="center">

**Made with ❤️ using Flutter**

[⬆ 回到顶部](#-小熊记账本)

</div>
