# 🐻 小熊记账本

一个基于 Flutter 开发的软萌粉糖色系移动端记账应用

---

## ✨ 功能特性

### 📊 核心功能
- **账单管理** - 支持支出/收入记录，分类选择，心情标签，图片附件
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
- **本地存储** - SQLite 数据库，数据安全，离线可用

### 🎨 UI/UX 特色
- **主题色系统** - 支持 8 种预设颜色（粉/蓝/绿/橙/黄/红/紫/黑）+ 自定义调色盘
- **Emoji 图标** - 所有分类、心情、成就均使用 Emoji
- **动画效果** - 浮动、缩放、渐变动画，提升交互体验
- **空状态引导** - 无数据时显示友好提示和操作引导
- **二次确认** - 删除操作均有确认弹窗，防止误删
- **年月快速选择** - 账单和统计页支持点击月份文字弹出年月选择器

## 🚀 快速开始

### 支持平台

| 平台 | 状态 |
|------|------|
| 📱 Android | ✅ 已支持 |
| 🍎 iOS | ✅ 已支持 |

### 环境要求

- Flutter SDK 3.24.0+
- Dart SDK 3.5.0+
- Android SDK (API 21-36)
- JDK 17+
- Gradle 8.2+
- Xcode 15+ (仅 iOS 构建需要)

> 📖 详细环境配置请查看 [docs/CONFIGURATION.md](docs/CONFIGURATION.md)

### 配置 API 密钥

```bash
cp lib/config/api_keys.dart.template lib/config/api_keys.dart
# 编辑 api_keys.dart，填入你的高德地图 API Key
# 申请地址: https://lbs.amap.com
```

> 📖 详见 [docs/CONFIGURATION.md](docs/CONFIGURATION.md#api-密钥配置)

### 构建应用

#### Android APK

```bash
# Windows
./build-apk.cmd

# 或手动执行
flutter build apk --release
```

> ⚠️ **注意**: 如果 Windows 用户名包含中文，需要先配置环境变量。详见 [docs/CONFIGURATION.md](docs/CONFIGURATION.md#中文路径问题)

#### iOS IPA

```bash
# 构建未签名 IPA
flutter build ios --release --no-codesign

# 使用 AltStore 或 Sideloadly 签名后安装到设备
```

> 📖 iOS 应用需要签名后才能安装到设备。详见 [docs/CONFIGURATION.md](docs/CONFIGURATION.md#ios-签名)

### 运行调试

```bash
# 获取依赖
flutter pub get

# 运行到设备/模拟器
flutter run
```

### GitHub Actions 自动构建

本项目使用 GitHub Actions 实现自动化构建：

- ✅ **自动触发**：推送到 `main` 分支或创建 `v*` tag 时自动构建
- ✅ **并行构建**：Android 和 iOS 同时构建，节省时间
- ✅ **自动发布**：推送 tag 时自动创建 Release 页面

#### 使用方法

1. **查看构建状态**：在 GitHub 仓库页面点击 **Actions** 标签
2. **发布新版本**：
   ```bash
   git tag v1.0.3
   git push origin v1.0.3
   ```

## 📚 文档导航

| 文档 | 说明 |
|------|------|
| [📖 完整配置指南](docs/CONFIGURATION.md) | 环境配置、依赖路径、构建详解 |
| [🔧 维护指南](docs/MAINTENANCE.md) | 缓存管理、清理命令、常见问题 |
| [📍 依赖路径速查](docs/DEPENDENCIES_PATH.md) | 所有外部依赖的详细路径和引用位置 |

## 🛠️ 技术栈

- **框架**: [Flutter](https://flutter.dev) 3.24.0 / [Dart](https://dart.dev) 3.5.0
- **状态管理**: [Provider](https://pub.dev/packages/provider) ^6.1.1
- **本地数据库**: [sqflite](https://pub.dev/packages/sqflite) ^2.3.0
- **图表组件**: [fl_chart](https://pub.dev/packages/fl_chart) ^0.66.0
- **UI 组件**: 
  - [flutter_slidable](https://pub.dev/packages/flutter_slidable) ^3.0.1 - 滑动删除
  - [share_plus](https://pub.dev/packages/share_plus) ^7.2.1 - 分享功能
  - [path_provider](https://pub.dev/packages/path_provider) ^2.1.3 - 路径提供者
  - [uuid](https://pub.dev/packages/uuid) ^4.2.1 - UUID 生成
  - [intl](https://pub.dev/packages/intl) ^0.18.1 - 国际化/日期格式化

## 📦 主要依赖

```yaml
dependencies:
  # 核心框架
  flutter:
    sdk: flutter
  
  # 本地存储
  sqflite: ^2.3.0              # SQLite 数据库
  path: ^1.8.3                 # 路径处理
  path_provider: ^2.1.3        # 路径提供者
  
  # 状态管理
  provider: ^6.1.1             # 状态管理
  
  # UI 组件
  fl_chart: ^0.66.0            # 图表库
  flutter_slidable: ^3.0.1     # 滑动组件
  share_plus: ^7.2.1           # 分享功能
  intl: ^0.18.1                # 国际化/日期格式化
  
  # 工具类
  uuid: ^4.2.1                 # UUID 生成
  collection: ^1.18.0          # 集合工具
```

> 📍 所有依赖的详细说明和路径请参考 [docs/DEPENDENCIES_PATH.md](docs/DEPENDENCIES_PATH.md)

## 🔗 相关链接

- [Flutter 官方文档](https://flutter.dev/docs)
- [Dart 语言指南](https://dart.dev/guides)
- [Android 开发文档](https://developer.android.com/docs)

## 📄 许可证

本项目仅供学习和个人使用。

---

<div align="center">

**Made with ❤️ using Flutter**

[⬆ 回到顶部](#-小熊记账本)

</div>
