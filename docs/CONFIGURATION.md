# 小熊记账本 - 项目配置与构建指南

## 项目概述

小熊记账本是一个基于 Flutter 开发的 Android 记账应用，当前 UI 基线为 `Luminous Finance` 玻璃态设计系统。

当前版本：`v1.3.4`
当前应用版本号来源：`pubspec.yaml` 中的 `version: 1.3.4+8`

## 核心能力

- 账单记录、分类、心情、图片附件
- AI 对话记账与语音输入
- 多账本管理与统计分析
- 年度总结、预算、心愿罐、消费地图
- 自动记账：监听支付宝/银行卡通知，识别后跳转记账页确认
- 本地 SQLite 存储，支持完整数据导入导出

## 环境要求

- Flutter SDK 3.24.0+
- Dart SDK 3.5.0+
- Android SDK API 21-36
- JDK 17+
- Gradle 8.2+

项目仅支持 Android，不构建 iOS。

## API 密钥配置

本项目使用多个第三方 API，密钥统一配置在 `lib/config/api_keys.dart`。

### 配置步骤

```bash
cp lib/config/api_keys.dart.template lib/config/api_keys.dart
```

然后编辑 `lib/config/api_keys.dart`，填入以下内容：

| 服务 | 用途 | 申请地址 |
|------|------|---------|
| 高德地图 | 地图定位、反向地理编码 | https://console.amap.com/ |
| 大模型（GLM/通义/DeepSeek） | AI 智能记账解析 | 见模板文件说明 |
| 百度语音 | 语音输入识别 | https://console.bce.baidu.com/ |

说明：

- `lib/config/api_keys.dart` 已在 `.gitignore` 中忽略
- 模板文件会保留在仓库中，真实密钥只保存在本地

## Android 构建规则

当前项目构建规则以 `android/app/build.gradle` 为准：

- 仅导出 `arm64-v8a`
- ABI split 已开启
- 不生成通用 APK
- release 构建走本地签名配置

关键配置如下：

- `compileSdk 36`
- `minSdk 21`
- `targetSdk 36`
- `coreLibraryDesugaringEnabled true`
- `splits.abi.include 'arm64-v8a'`

### 版本号规则

Android 版本号从 `pubspec.yaml` 自动解析：

```yaml
version: 1.3.4+8
```

- `1.3.4` 对应 `versionName`
- `7` 对应 `versionCode`

说明：

- 覆盖安装主要依赖 `versionCode`
- `versionCode` 必须持续递增
- `settings_list.dart` 关于页版本展示也要和 `pubspec.yaml` 同步

## Release 签名配置

release 构建依赖以下本地私有文件：

- `android/key.properties`
- `android/app/bear_bill_release.jks`

说明：

- 这两个文件属于本地敏感材料，不应提交到仓库
- `.gitignore` 已忽略 `android/key.properties` 与 `android/app/*.jks`
- `key.properties` 中的 `storeFile` 当前指向 `app/bear_bill_release.jks`

## 自动记账说明

当前自动记账主路径是通知监听，不是无障碍。

实现链路：

1. Android 侧 `NotificationListenerServiceImpl` 监听通知
2. 通过 `bear_bill/auto_record` MethodChannel 传给 Flutter
3. `AutoRecordService.instance.init()` 在 `main.dart` 启动时初始化
4. Flutter 侧统一走 `AutoRecordService` 解析
5. 识别后生成候选记录，跳转记账页由用户确认

当前特性：

- 优先使用本地解析，减少对网络与 API 配额的依赖
- 支持支付宝与主流银行卡通知场景
- 支付候选记录默认不直接入库，避免误识别产生脏数据
- 点击通知后也会回到统一解析链路，避免旧入口粗解析错单

注意：

- 当前主路径已经不再依赖无障碍服务
- 若文案里仍看到无障碍相关描述，应视为遗留信息，不代表当前实现

## 快速开始

### 安装依赖

```bash
flutter pub get
```

### 运行调试

```bash
flutter run
```

### 执行测试

```bash
flutter test
```

### 构建 arm64 Release APK

```bash
flutter build apk --release --target-platform android-arm64
```

输出文件：

```text
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

发布归档命名规则：

```text
releases/bear_bill_{x.y.z}_{YYYYMMDD}_{HHmm}.apk
```

## Windows 中文路径问题

如果 Windows 用户名包含中文，Gradle 或 Kotlin 编译可能失败。建议将 Flutter、Gradle、Pub 缓存迁移到纯英文路径，并配置以下环境变量：

- `GRADLE_USER_HOME`
- `PUB_CACHE`
- `JAVA_HOME`
- `ANDROID_HOME`

## 项目结构

```text
bear_bill/
├── docs/
│   ├── CONFIGURATION.md
│   ├── DEPENDENCIES_PATH.md
│   ├── MAINTENANCE.md
│   └── UI_REDESIGN.md
├── lib/
│   ├── main.dart
│   ├── config/
│   ├── models/
│   ├── pages/
│   ├── providers/
│   ├── services/
│   ├── theme/
│   └── utils/
├── android/
├── assets/
├── README.md
└── pubspec.yaml
```

重点服务文件：

- `lib/services/auto_record_service.dart`
- `lib/services/database_backup_service.dart`
- `lib/services/notification_service.dart`
- `lib/services/storage_service.dart`

## 常见检查命令

```bash
flutter doctor -v
flutter pub get
flutter test
flutter build apk --release --target-platform android-arm64
```
