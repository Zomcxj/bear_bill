# 小熊记账本 - 项目配置与构建指南

## 📋 目录
- [项目概述](#项目概述)
- [环境要求](#环境要求)
- [外部依赖库路径配置](#外部依赖库路径配置)
- [快速开始](#快速开始)
- [Android 环境配置](#android-环境配置)
- [常见问题解决](#常见问题解决)
- [构建 APK](#构建-apk)
- [项目结构](#项目结构)

---

## 项目概述

**小熊记账本** 是一个基于 Flutter 开发的移动端记账应用，采用软萌粉糖色系主题设计。

### 核心功能
- 📊 **账单记录与管理** - 支持支出/收入记录，分类选择，心情标签，图片附件
- 🤖 **AI 对话记账** - 自然语言输入，语音识别，智能分类/金额/日期解析
- 📒 **多账本管理** - 创建/切换/删除账本，数据隔离，独立统计
- 📈 **统计分析** - 甜甜圈图分类统计、周趋势图、月度对比、热力日历
- 📅 **年度总结** - 年度收支总览、12 个月趋势柱状图、年度分类 Top 5
- 💰 **心愿罐储蓄目标** - 设定目标，存钱进度追踪，完成庆祝动画
- 🎯 **预算设置** - 月度预算设置，快捷金额，每日可用计算
- 📤 **账单导出** - CSV 格式导出，月份选择，文件保存到本地
- 🏆 **成就系统** - 24个预定义成就，解锁状态追踪，进度百分比，徽章展示
- 👑 **等级系统** - 6级小熊形态变化，经验值累积，自动升级
- 📅 **打卡功能** - 连续记账天数统计，断签重置，已记账自动跳过提醒
- 🎨 **主题颜色** - 8 种预设主题色 + 自定义调色盘（HSV 滑块），全应用同步
- 🗺️ **消费地图** - 地图标注消费位置，足迹可视化
- 🔔 **自动记账** - 监听微信/支付宝通知，自动解析并记录
- 🎤 **语音输入** - 百度语音识别，按住说话，上滑取消，静音自动停止
- 💾 **本地 SQLite 存储** - 数据安全，离线可用

### 技术栈
- **框架**: Flutter 3.24.0 / Dart 3.5.0
- **状态管理**: Provider ^6.1.1
- **本地数据库**: sqflite ^2.3.0
- **图表组件**: fl_chart ^0.66.0
- **地图**: flutter_map + latlong2
- **AI 大模型**: GLM-4-Flash（可切换通义/DeepSeek）
- **语音识别**: 百度语音 REST API + Android 原生 AudioRecord
- **定位**: geolocator + 高德地图
- **UI 组件**: flutter_slidable, share_plus, path_provider, uuid, intl

---

## 环境要求

### 必需软件
1. **Flutter SDK**: 3.24.0 或更高版本
2. **Dart SDK**: 3.5.0 或更高版本
3. **Android Studio**: 最新版
4. **Android SDK**: API Level 21-36
5. **JDK**: 17 或更高版本

### 可选工具
- VS Code（推荐安装 Flutter 和 Dart 插件）
- Git

---

## API 密钥配置

本项目使用多个第三方 API 服务。所有密钥统一配置在 `lib/config/api_keys.dart` 中。

### 配置步骤

1. 复制模板文件：
   ```bash
   cp lib/config/api_keys.dart.template lib/config/api_keys.dart
   ```
2. 编辑 `lib/config/api_keys.dart`，填入以下密钥：

| 服务 | 申请地址 | 用途 | 所需密钥 |
|------|---------|------|---------|
| **高德地图** | https://console.amap.com/ | 地图定位、反向地理编码 | `amapApiKey` |
| **大模型** | 见下方说明 | AI 智能记账解析 | `aiBaseUrl` + `aiApiKey` + `aiModel` |
| **百度语音** | https://console.bce.baidu.com/ | 语音输入识别 | `baiduSpeechAppId` + `baiduSpeechApiKey` + `baiduSpeechSecretKey` |

### 大模型厂商切换

`api_keys.dart` 中的 `aiBaseUrl`、`aiApiKey`、`aiModel` 支持切换不同厂商：

| 厂商 | aiBaseUrl | aiModel | 申请地址 |
|------|-----------|---------|---------|
| 智谱 GLM | https://open.bigmodel.cn/api/paas/v4/chat/completions | glm-4-flash | https://open.bigmodel.cn/ |
| 阿里通义 | https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions | qwen-turbo | https://dashscope.aliyun.com/ |
| DeepSeek | https://api.deepseek.com/v1/chat/completions | deepseek-chat | https://platform.deepseek.com/ |

> **安全说明**: `lib/config/api_keys.dart` 已加入 `.gitignore`，不会被提交到版本库。模板文件 `api_keys.dart.template` 会保留在仓库中供其他开发者参考。

---

## 外部依赖库路径配置

本项目依赖以下外部工具和 SDK。

> **说明**: 以下路径为示例，请根据你的实际安装位置进行调整。

### 📦 核心依赖清单

| 依赖项 | 示例路径 | 版本 | 用途 | 配置文件位置 |
|--------|---------|------|------|-------------|
| **Flutter SDK** | `<YOUR_FLUTTER_SDK>` | 3.24.0 | Flutter 框架核心 | 系统 PATH 环境变量 |
| **Android SDK** | `<YOUR_ANDROID_SDK>` | API 36 | Android 构建工具 | `android/local.properties` |
| **JDK 17** | `<YOUR_JDK_PATH>` | 17.0+ | Java 运行时 | `android/gradle.properties` |
| **Android Studio** | `<YOUR_ANDROID_STUDIO>` | 2025.3.2 | IDE & SDK 管理 | 无需配置 |
| **Gradle Cache** | `<YOUR_GRADLE_CACHE>` | 8.2+ | Gradle 缓存 | `android/gradle.properties` |
| **Pub Cache** | `<YOUR_PUB_CACHE>` | - | Flutter 包缓存 | 系统环境变量 |

---

### 🔧 详细配置说明

#### 1. Flutter SDK

**路径**: `<YOUR_FLUTTER_SDK>`（例如：`D:/Softwaredata/flutter` 或 `C:/src/flutter`）

**配置方式**:
- 添加到系统 PATH 环境变量
- 验证命令: `flutter --version`

**在项目中的引用**:
```yaml
# pubspec.yaml (第 8-9 行)
environment:
  sdk: '>=3.0.0 <4.0.0'  # Dart SDK 版本约束
```

**包含内容**:
- Flutter 框架
- Dart SDK 3.5.0
- Flutter Engine
- DevTools

---

#### 2. Android SDK

**路径**: `<YOUR_ANDROID_SDK>`（例如：`D:/Softwaredata/Android/SDK` 或 `%LOCALAPPDATA%/Android/Sdk`）

**配置位置**: `android/local.properties`
```properties
sdk.dir=<YOUR_ANDROID_SDK>
```

**在项目中的引用**:
```groovy
// android/app/build.gradle (第 27, 41 行)
android {
    compileSdk 36          // 编译 SDK 版本
    
    defaultConfig {
        minSdk 21          // 最低支持版本
        targetSdk 36       // 目标 SDK 版本
    }
}
```

**包含组件**:
```
<YOUR_ANDROID_SDK>/
├── build-tools/36.1.0     # 构建工具
├── platform-tools/        # ADB, Fastboot
├── platforms/android-36   # Android 14 平台
├── cmdline-tools/         # 命令行工具
├── emulator/              # 模拟器
└── licenses/              # 许可证文件
```

**重要提示**:
- 需要接受 Android SDK 许可证：`flutter doctor --android-licenses`
- 至少需要安装 `platforms/android-36` 和 `build-tools/36.1.0`

---

#### 3. JDK 17

**路径**: `<YOUR_JDK_PATH>`（例如：`D:/Softwaredata/Java/jdk-17` 或 `C:/Program Files/Java/jdk-17`）

**配置位置**: `android/gradle.properties`
```properties
org.gradle.java.home=<YOUR_JDK_PATH>
```

**在项目中的引用**:
```groovy
// android/app/build.gradle (第 30-31, 35 行)
android {
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
    
    kotlinOptions {
        jvmTarget = '17'
    }
}
```

**验证命令**:
```bash
java -version
# 输出: java version "17.x.x"
```

---

#### 4. GradleCache (Gradle 缓存)

**路径**: `<YOUR_GRADLE_CACHE>`（例如：`D:/Softwaredata/GradleCache` 或 `C:/Users/YourName/.gradle`）

**配置位置**: `android/gradle.properties`
```properties
org.gradle.user.home=<YOUR_GRADLE_CACHE>
org.gradle.daemon=false
kotlin.incremental=false
kotlin.compiler.execution.strategy=in-process
```

**在项目中的引用**:
```properties
# android/gradle/wrapper/gradle-wrapper.properties (第 1-5 行)
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https://mirrors.cloud.tencent.com/gradle/gradle-8.2-all.zip
```

**缓存结构**:
```
<YOUR_GRADLE_CACHE>/
├── caches/                # 依赖库缓存
├── wrapper/dists/         # Gradle 发行版 (gradle-8.2)
├── daemon/                # Gradle 守护进程
└── workers/               # 工作进程
```

**作用**:
- 存储 Gradle 发行版（避免重复下载）
- 缓存项目依赖库
- 加速构建过程

---

#### 5. PubCache (Flutter 包缓存)

**路径**: `<YOUR_PUB_CACHE>`（例如：`D:/Softwaredata/PubCache` 或 `%LOCALAPPDATA%/Pub/Cache`）

**配置方式**:
- 系统环境变量: `PUB_CACHE = <YOUR_PUB_CACHE>`
- 或在终端中临时设置

**在项目中的引用**:
```yaml
# pubspec.yaml (第 11-31 行)
dependencies:
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
  intl: ^0.18.1                # 国际化
  
  # 其他
  uuid: ^4.2.1                 # UUID 生成
  collection: ^1.18.0          # 集合工具
```

**缓存结构**:
```
<YOUR_PUB_CACHE>/
├── hosted/pub.dev/            # 下载的包
│   ├── sqflite-2.4.1/
│   ├── provider-6.1.1/
│   ├── fl_chart-0.66.2/
│   └── ...
├── hosted-hashes/             # 哈希校验
└── _temp/                     # 临时文件
```

**查看已安装的包**:
```bash
flutter pub deps
```

---

#### 6. Android Studio

**路径**: `<YOUR_ANDROID_STUDIO>`（例如：`D:/Softwaredata/Android/Android Studio`）

**配置方式**:
- 无需特殊配置，Flutter 自动检测
- 用于 Android SDK 管理和设备模拟

**Flutter 插件**:
- Flutter plugin: 提供 Flutter 开发支持
- Dart plugin: 提供 Dart 语言支持

**验证**:
```bash
flutter doctor
# 应该显示: [√] Android Studio (version 2025.3.2)
```

---

### 🔗 依赖关系图

```
项目构建流程:
│
├── 1. Flutter SDK (<YOUR_FLUTTER_SDK>)
│   └── 读取 pubspec.yaml
│       └── 从 PubCache 加载 Dart 包
│
├── 2. Android 工具链
│   ├── Android SDK (<YOUR_ANDROID_SDK>)
│   │   └── 提供编译平台和构建工具
│   │
│   ├── JDK 17 (<YOUR_JDK_PATH>)
│   │   └── 编译 Java/Kotlin 代码
│   │
│   └── Gradle (在 <YOUR_GRADLE_CACHE> 中)
│       └── 执行构建任务
│           ├── 从 GradleCache 加载依赖
│           └── 调用 Android SDK 打包 APK
│
└── 3. 输出 APK
    └── build/app/outputs/flutter-apk/app-release.apk
```

---

### ⚙️ 环境变量配置总结

#### 系统环境变量（永久生效）

| 变量名 | 示例值 | 说明 |
|--------|---|------|
| `PATH` | 添加 `<YOUR_FLUTTER_SDK>/bin` | Flutter 命令 |
| `ANDROID_HOME` | `<YOUR_ANDROID_SDK>` | Android SDK 路径 |
| `JAVA_HOME` | `<YOUR_JDK_PATH>` | JDK 路径 |
| `GRADLE_USER_HOME` | `<YOUR_GRADLE_CACHE>` | Gradle 缓存 |
| `PUB_CACHE` | `<YOUR_PUB_CACHE>` | Flutter 包缓存 |

#### 项目级配置

| 文件 | 配置项 | 示例值 |
|------|--------|-----|
| `android/local.properties` | `sdk.dir` | `<YOUR_ANDROID_SDK>` |
| `android/gradle.properties` | `org.gradle.user.home` | `<YOUR_GRADLE_CACHE>` |
| 终端临时变量 | `GRADLE_USER_HOME` | `<YOUR_GRADLE_CACHE>` |
| 终端临时变量 | `PUB_CACHE` | `<YOUR_PUB_CACHE>` |

---

### ✅ 验证所有依赖

运行以下命令验证所有依赖是否正确配置：

```bash
# 1. 检查 Flutter
flutter doctor -v

# 2. 检查 Android 工具链
flutter doctor --android-licenses

# 3. 检查依赖包
flutter pub get
flutter pub deps

# 4. 测试构建
flutter build apk --release
```

**期望输出**:
```
[√] Flutter (Channel stable, 3.24.0, ...)
[√] Android toolchain - develop for Android devices
[√] Android Studio (version 2025.3.2)
[√] Connected device
```

---

### 💡 常见问题

#### Q1: 如何查看所有依赖的实际路径？

```bash
# 查看 Flutter 包路径
flutter pub cache list

# 查看 Gradle 缓存
ls <YOUR_GRADLE_CACHE>/caches
```

#### Q2: 如何清理缓存重新下载？

```bash
# 清理 Pub 缓存
flutter pub cache clean
flutter pub get

# 清理 Gradle 缓存
Remove-Item <YOUR_GRADLE_CACHE>/caches/* -Recurse -Force
flutter clean
flutter build apk --release
```

#### Q3: 如何更新某个依赖？

```bash
# 更新所有依赖
flutter pub upgrade

# 更新特定包
flutter pub upgrade sqflite

# 查看可更新的包
flutter pub outdated
```

---

## 快速开始

### 1. 克隆项目
```bash
git clone <repository-url>
cd bear_bill
```

### 2. 安装依赖
```bash
flutter pub get
```

### 3. 运行项目
```bash
# Android 设备/模拟器
flutter run -d android

# Windows 桌面
flutter run -d windows
```

---

## Android 环境配置

### ⚠️ 重要：Windows 中文用户名问题

如果你的 Windows 用户名包含中文字符，会导致 Gradle 构建失败。需要配置环境变量来避免此问题。

### 解决方案

#### 步骤 1: 创建缓存目录
在 `<YOUR_GRADLE_CACHE>` 和 `<YOUR_PUB_CACHE>` 目录下创建两个缓存目录（已完成）：

```powershell
# 在 PowerShell 中执行（已移动完成）
# mkdir <YOUR_GRADLE_CACHE>
# mkdir <YOUR_PUB_CACHE>
```

#### 步骤 2: 配置环境变量

**方法一：系统环境变量（推荐）**

1. 右键“此电脑” → “属性” → “高级系统设置”
2. 点击“环境变量”
3. 在“系统变量”中新建：
   - 变量名: `GRADLE_USER_HOME`
   - 变量值: `<YOUR_GRADLE_CACHE>`
4. 新建另一个变量：
   - 变量名: `PUB_CACHE`
   - 变量值: `<YOUR_PUB_CACHE>`
5. 重启所有终端窗口

**方法二：临时设置（仅当前会话）**

```powershell
$env:GRADLE_USER_HOME="<YOUR_GRADLE_CACHE>"
$env:PUB_CACHE="<YOUR_PUB_CACHE>"
```

#### 步骤 3: 验证配置
```powershell
echo $env:GRADLE_USER_HOME
echo $env:PUB_CACHE
```

应该输出：
```
<YOUR_GRADLE_CACHE>
<YOUR_PUB_CACHE>
```

#### 步骤 4: 重新获取依赖
```bash
flutter clean
flutter pub get
```

---

## 常见问题解决

### 问题 1: Gradle 守护进程启动失败

**错误信息**:
```
Unable to start the daemon process.
ClassNotFoundException: org.gradle.instrumentation.agent.Agent
```

**原因**: 用户路径包含中文字符

**解决方案**:
按照上述 [Android 环境配置](#android-环境配置) 步骤设置环境变量。

### 问题 2: Kotlin 编译失败

**错误信息**:
```
Could not connect to Kotlin compile daemon
source file or directory not found: C:/Users/中文字符/...
```

**解决方案**:
1. 确保已设置 `PUB_CACHE` 和 `GRADLE_USER_HOME`
2. 清理缓存并重新构建：
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --release
   ```

### 问题 3: Android 许可证未接受

**错误信息**:
```
Android license status unknown.
```

**解决方案**:
```bash
flutter doctor --android-licenses
```
然后按提示接受所有许可证。

### 问题 4: 构建速度慢

**优化方案**:
1. 使用 SSD 存储项目
2. 增加 Gradle JVM 内存（已在 `android/gradle.properties` 中配置）
3. 禁用 Gradle 守护进程（已在配置中设置为 `false`）

---

## 构建 APK

```bash
flutter build apk --release
```

构建成功后，APK 文件位于：
```
build/app/outputs/flutter-apk/app-release.apk
```

### 详细步骤

#### 1. 设置环境变量（如需要）
```powershell
$env:GRADLE_USER_HOME="<YOUR_GRADLE_CACHE>"
$env:PUB_CACHE="<YOUR_PUB_CACHE>"
```

#### 2. 清理项目
```bash
flutter clean
```

#### 3. 获取依赖
```bash
flutter pub get
```

#### 4. 构建 Release APK
```bash
flutter build apk --release
```

#### 5. 构建 App Bundle（用于 Google Play）
```bash
flutter build appbundle --release
```

### 查看构建产物

```powershell
# 查看 APK 文件
dir build/app/outputs/flutter-apk/

# 查看文件大小
(Get-Item build/app/outputs/flutter-apk/app-release.apk).Length / 1MB
```

---

## 项目结构

```
bear_bill/
├── docs/                      # 项目文档
│   ├── CONFIGURATION.md       # 完整配置指南
│   ├── MAINTENANCE.md         # 维护指南
│   └── DEPENDENCIES_PATH.md   # 依赖路径速查
├── lib/                       # Flutter 源代码
│   ├── main.dart              # 应用入口
│   ├── config/                # 配置文件
│   │   └── api_keys.dart      # API 密钥（gitignore）
│   ├── models/                # 数据模型 (Record, Book, Wish, User, Achievement, Mood)
│   ├── pages/                 # 页面
│   │   ├── home/              # 首页（含话筒语音按钮）
│   │   ├── add_record/        # 记账页（含地图选点）
│   │   ├── ai_chat/           # AI 对话记账（含语音输入、心情、定位）
│   │   ├── bill_list/         # 账单列表
│   │   ├── statistics/        # 统计页
│   │   ├── wish_jar/          # 心愿罐
│   │   ├── profile/           # 个人中心（含自动记账设置）
│   │   ├── record_detail/     # 账单详情
│   │   ├── budget/            # 预算设置
│   │   ├── export/            # 账单导出
│   │   ├── multi_book/        # 多账本管理
│   │   └── map_footprint/     # 消费地图
│   ├── services/              # 服务层
│   │   ├── database_service.dart      # SQLite 数据库
│   │   ├── glm_service.dart           # AI 大模型解析
│   │   ├── baidu_speech_service.dart  # 百度语音识别
│   │   ├── amap_location_service.dart # 高德地图定位
│   │   ├── auto_record_service.dart   # 自动记账（通知监听）
│   │   └── notification_service.dart  # 通知服务
│   ├── providers/             # 状态管理 (AppProvider, ThemeProvider)
│   ├── theme/                 # 主题配置 (AppTheme)
│   └── utils/                 # 工具类 (DateUtils, FormatUtils)
├── android/                   # Android 原生配置（含 MethodChannel 语音录音）
├── assets/                    # 静态资源
├── pubspec.yaml               # Flutter 依赖配置
├── README.md                  # 项目介绍
└── CLAUDE.md                  # Claude Code 项目规则
```

---

## 许可证

本项目仅供学习和个人使用。