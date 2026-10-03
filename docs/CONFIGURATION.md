# 小熊记账本 - 项目配置与构建指南

## 项目概述

小熊记账本是一个基于 Flutter 开发的 Android 记账应用，当前 UI 基线为 `Luminous Finance` 玻璃态设计系统。

当前版本：`v1.3.7`
当前应用版本号来源：`pubspec.yaml` 中的 `version: 1.3.7+11`

## 核心能力

- 账单记录、分类、心情、图片附件
- AI 对话记账与语音输入
- 多账本管理与统计分析
- 年度总结、预算、心愿罐、消费地图
- 自动记账：监听支付宝/银行卡通知，识别后跳转记账页确认
- 本地 SQLite 存储，支持完整数据导入导出

## 环境要求

- Flutter SDK 3.47+
- Dart SDK 3.0.0+（`pubspec.yaml` 约束 `>=3.0.0 <4.0.0`）
- Android SDK API 21-36
- JDK 17
- Gradle 9.2.0
- AGP 9.0.1 / Kotlin 2.3.20

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

- release 构建走本地签名配置（`key.properties`）
- `android/app/build.gradle` 中**不写** `splits.abi`，也不写 `minifyEnabled` / `proguardFiles`
- 上述项全部由 Flutter Gradle 插件在构建期注入，手写会与插件配置冲突（AGP 8.11+ 报 `Conflicting configuration`）

关键配置如下：

- `compileSdk 36`
- `minSdk 21`（`flutter.minSdkVersion`）
- `targetSdk 36`
- `coreLibraryDesugaringEnabled true`
- AGP 9 新 DSL：顶层 `kotlin { compilerOptions { jvmTarget = JVM_17 } }`（`android.kotlinOptions` 已移除）

### 代码压缩与 R8 规则接线

Flutter Gradle 插件（`FlutterPlugin.kt`）在 release 构建时自动完成：

```kotlin
releaseBuildType.isMinifyEnabled = true
releaseBuildType.isShrinkResources = ...
releaseBuildType.proguardFiles.add(getDefaultProguardFile("proguard-android-optimize.txt"))
releaseBuildType.proguardFiles.add(flutterProguardRules)
if (File("${project.projectDir}/proguard-rules.pro").exists()) {
    releaseBuildType.proguardFiles.add(proguardRulesPro)  // 文件名固定，放 android/app/ 下即生效
}
```

因此 `android/app/proguard-rules.pro` **无需在 build.gradle 中声明也会被自动接入**。当前该文件内容：

```proguard
-keep class * extends androidx.room.RoomDatabase {
    <init>();
}
```

用途：WorkManager 内部依赖 Room，Room 通过反射 `newInstance()` 实例化 `WorkDatabase_Impl`。`room-runtime` 自带的 consumer 规则只保留类名、不保留成员，R8 9.x（AGP 9.0.1）会删除无静态引用的无参构造函数，导致 `InitializationProvider` 阶段抛 `InstantiationException`——此时 Flutter 引擎尚未启动，表现为应用一直白屏。

验证规则是否生效（构建产物）：

- `build/app/outputs/mapping/release/configuration.txt` — 应包含 `proguard-rules.pro` 来源标注
- `build/app/outputs/mapping/release/seeds.txt` — 应出现 `WorkDatabase_Impl: WorkDatabase_Impl()`

### ABI 控制

插件在未开启 split 时，会把 `abiFilters` 设为 Flutter 支持的全部 ABI（arm64-v8a / armeabi-v7a / x86_64），此时 `--target-platform android-arm64` 只限制 AOT 编译目标，**不会**从 APK 中剔除插件依赖带来的其他 ABI `.so`。

- 只出 arm64 单包：加 `--split-per-abi`，产物为 `app-arm64-v8a-release.apk`
- 只出 universal 胖包：不加该参数，产物为 `app-release.apk`（含 3 个 ABI 的 `.so`）

### versionCode 与 ABI 编码（重要）

`--split-per-abi` 默认会把 versionCode 改写为 `abiCode * 1000 + versionCode`（arm64-v8a 的 abiCode = 2），即 `pubspec.yaml` 的 `1.3.7+11` 在 APK 里会变成 **2011**：

| 构建方式 | APK 内 versionCode | 说明 |
|---|---|---|
| `--target-platform android-arm64`（不带 split） | `11` | 与 `pubspec.yaml` 一致 |
| `--split-per-abi`（未设该开关时） | `2011` | 与 build 号脱钩 |

一旦手机上装过 `2011` 的 split 包，再装 `11` 的包会被系统判为版本降级而拒绝安装（`INSTALL_FAILED_VERSION_DOWNGRADE`），只能先卸载。`android/gradle.properties` 因此设置了 `force-version-code-ignoring-abi=true`，强制忽略 ABI 编码，使所有 APK 的 versionCode 始终等于 `pubspec.yaml` 的 build 号，保持版本号规则单一来源。该开关仅在 `--split-per-abi` 时生效，不影响其他构建。

出包后务必核对：

```bash
D:/Softwaredata/Android/SDK/build-tools/<ver>/aapt2 dump badging <apk> | grep versionCode
```

### APK 体积翻倍（native 库改为 STORED）

升级到 Flutter 3.47 / AGP 9.0.1 后，arm64 release 包从 ~11MB 涨到 ~21MB，原因是 native 库打包方式变化：

| | `extractNativeLibs` | 存储方式 | libflutter.so | APK 体积 |
|---|---|---|---|---|
| 1.3.7 及之前（AGP 8.2） | `true` | DEFLATE 压缩 | 4.76 MB（raw 10.22 MB） | ~11 MB |
| 现在（AGP 9.0.1） | `false` | STORED 不压缩、页对齐 | 11.20 MB | ~21 MB |

- raw 体积只涨了约 1 MB（引擎本身变化），其余是“不再压缩”导致
- `extractNativeLibs=false` 让系统直接 mmap APK 内的 `.so`，**安装后占用磁盘反而更小**、启动更快，代价是 APK 分发体积变大
- 若需要压回分发体积，在 `android/app/build.gradle` 的 `release` 里加 `packagingOptions { jniLibs { useLegacyPackaging = true } }`（会退回压缩 + 安装时解压）

另：新依赖引入 `lib/arm64-v8a/libdartjni.so`（约 0.13 MB），属正常。

### 版本号规则

Android 版本号从 `pubspec.yaml` 自动解析：

```yaml
version: 1.3.7+11
```

- `1.3.7` 对应 `versionName`
- `11` 对应 `versionCode`

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
flutter build apk --release --target-platform android-arm64 --split-per-abi
```

输出文件：

```text
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

注意：若漏掉 `--split-per-abi`，产物名为 `app-release.apk`，且 APK 内会混入 armeabi-v7a / x86_64 的插件 `.so`。

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
flutter build apk --release --target-platform android-arm64 --split-per-abi
```
