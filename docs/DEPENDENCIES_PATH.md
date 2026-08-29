# 外部依赖路径速查表

以下路径均为示例，请替换为你自己的实际安装位置。

## 核心 SDK 和工具

### Flutter SDK

- 路径：`<YOUR_FLUTTER_SDK>`
- 版本：3.24.0+
- 用途：Flutter 与 Dart 工具链
- 验证：`flutter --version`

### Android SDK

- 路径：`<YOUR_ANDROID_SDK>`
- 版本：API 21-36
- 配置文件：`android/local.properties`
- 验证：`flutter doctor`

```properties
sdk.dir=<YOUR_ANDROID_SDK>
```

### JDK 17

- 路径：`<YOUR_JDK_PATH>`
- 版本：17+
- 配置方式：`JAVA_HOME` 或 `android/gradle.properties`
- 验证：`java -version`

### Android Studio

- 路径：`<YOUR_ANDROID_STUDIO>`
- 用途：SDK 管理、调试、模拟器

## 缓存目录

### Gradle 缓存

- 路径：`<YOUR_GRADLE_CACHE>`
- 配置位置：`android/gradle.properties`

```properties
org.gradle.user.home=<YOUR_GRADLE_CACHE>
org.gradle.daemon=false
kotlin.incremental=false
kotlin.compiler.execution.strategy=in-process
```

### Pub 缓存

- 路径：`<YOUR_PUB_CACHE>`
- 配置方式：系统环境变量 `PUB_CACHE`

## pubspec 依赖概览

当前 `pubspec.yaml` 的主要依赖包括：

### 数据与存储

- `sqflite`
- `path`
- `path_provider`
- `shared_preferences`
- `archive`

### 状态与 UI

- `provider`
- `fl_chart`
- `flutter_slidable`
- `share_plus`
- `intl`

### 文件与媒体

- `file_picker`
- `image_picker`

### 通知、权限、定位、语音

- `flutter_local_notifications`
- `timezone`
- `permission_handler`
- `geolocator`
- `speech_to_text`
- `http`

### 其他

- `uuid`
- `collection`
- `latlong2`
- `flutter_map`

## Android 原生依赖

`android/app/build.gradle` 当前还依赖：

- `com.android.tools:desugar_jdk_libs:2.1.4`
- `androidx.work:work-runtime-ktx:2.9.0`

## 配置文件中的关键路径

### android/local.properties

```properties
sdk.dir=<YOUR_ANDROID_SDK>
flutter.sdk=<YOUR_FLUTTER_SDK>
```

### android/gradle.properties

```properties
org.gradle.jvmargs=-Xmx1G -Xms256m -Dfile.encoding=UTF-8
org.gradle.user.home=<YOUR_GRADLE_CACHE>
android.useAndroidX=true
android.enableJetifier=true
```

### Android 签名相关本地文件

- `android/key.properties`
- `android/app/bear_bill_release.jks`

说明：

- 这两个文件只应保留在本地
- 不能把真实签名信息写进文档、提交记录或公开仓库

## 构建产物路径

当前项目仅导出 arm64 APK：

```text
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

发布归档目录：

```text
releases/
```

归档命名规则：

```text
releases/bear_bill_{x.y.z}_{YYYYMMDD}_{HHmm}.apk
```

## 版本来源

版本号从 `pubspec.yaml` 自动解析：

```yaml
version: 1.3.7+11
```

不要再手动依赖旧的：

- `flutter.versionName=1.0.0`
- `flutter.versionCode=1`

它们在当前项目里只是 fallback，不是主来源。

## 本地忽略文件

当前 `.gitignore` 里和本地环境强相关的内容包括：

- `lib/config/api_keys.dart`
- `android/key.properties`
- `android/app/*.jks`
- `release/`
- `releases/`
- `plan/`
- `task_plan.md`

说明：

- 这些内容要么是敏感文件，要么是本地产物
- 排查问题时要区分“已被跟踪的历史文件”和“当前应忽略的本地文件”

## 常用验证命令

```bash
flutter doctor -v
flutter pub deps --style=compact
flutter pub outdated
flutter test
flutter build apk --release --target-platform android-arm64
```
