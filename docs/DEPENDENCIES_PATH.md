# 外部依赖路径速查表

> **说明**: 以下路径为示例，请根据你的实际安装位置进行调整。
> - `<YOUR_XXX>` 表示需要替换为你的实际路径
> - 括号中提供了常见示例供参考

## 🔧 核心 SDK 和工具
### 1. Flutter SDK
- **路径**: `<YOUR_FLUTTER_SDK>`（例如：`D:/Softwaredata/flutter`）
- **版本**: 3.24.0
- **包含**: Dart SDK 3.5.0, Flutter Engine
- **配置**: 系统 PATH 环境变量
- **验证**: `flutter --version`

### 2. Android SDK
- **路径**: `<YOUR_ANDROID_SDK>`（例如：`D:/Softwaredata/Android/SDK`）
- **版本**: API Level 36 (Android 14)
- **配置文件**: `android/local.properties`
  ```properties
  sdk.dir=<YOUR_ANDROID_SDK>
  ```
- **关键组件**:
  - `build-tools/36.1.0` - 构建工具
  - `platforms/android-36` - 平台文件
  - `platform-tools/` - ADB, Fastboot
- **验证**: `adb version`

### 3. JDK 17
- **路径**: `<YOUR_JDK_PATH>`（例如：`D:/Softwaredata/Java/jdk-17`）
- **版本**: Java 17 (LTS)
- **配置文件**: 
  - `android/gradle.properties`
  - 系统环境变量 `JAVA_HOME`
- **项目引用**: `android/app/build.gradle` (第 30-36 行)
  ```groovy
  compileOptions {
      sourceCompatibility JavaVersion.VERSION_17
      targetCompatibility JavaVersion.VERSION_17
  }
  kotlinOptions {
      jvmTarget = '17'
  }
  ```
- **验证**: `java -version`

### 4. Android Studio
- **路径**: `<YOUR_ANDROID_STUDIO>`（例如：`D:/Softwaredata/Android/Android Studio`）
- **版本**: 2025.3.2
- **用途**: IDE, SDK Manager, 模拟器
- **插件**: Flutter, Dart
- **验证**: `flutter doctor`

---

## 📦 缓存目录

### 5. GradleCache
- **路径**: `<YOUR_GRADLE_CACHE>`（例如：`D:/Softwaredata/GradleCache`）
- **配置文件**: `android/gradle.properties`
  ```properties
  org.gradle.user.home=<YOUR_GRADLE_CACHE>
  org.gradle.daemon=false
  kotlin.incremental=false
  kotlin.compiler.execution.strategy=in-process
  ```
- **Gradle Wrapper**: `android/gradle/wrapper/gradle-wrapper.properties`
  ```properties
  distributionBase=GRADLE_USER_HOME
  distributionPath=wrapper/dists
  distributionUrl=https://mirrors.cloud.tencent.com/gradle/gradle-8.2-all.zip
  ```
- **结构**:
  ```
  GradleCache/
  ├── caches/              # 依赖库缓存
  ├── wrapper/dists/       # Gradle 8.2
  ├── daemon/              # 守护进程
  └── workers/             # 工作进程
  ```
- **大小**: ~2-5 GB

### 6. Pub Cache
- **路径**: `<YOUR_PUB_CACHE>`（例如：`D:/Softwaredata/PubCache`）
- **配置方式**: 
  - 系统环境变量: `PUB_CACHE`
  - 或终端中临时设置
- **结构**:
  ```
  PubCache/
  ├── hosted/pub.dev/      # 下载的包
  ├── hosted-hashes/       # 哈希校验
  └── _temp/               # 临时文件
  ```
- **大小**: ~500 MB - 2 GB

---

## 📚 Flutter 依赖包 (pubspec.yaml)

### 核心依赖
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

### 依赖包实际位置
所有包都缓存在: `<YOUR_PUB_CACHE>/hosted/pub.dev/`

例如:
- `sqflite-2.4.1/`
- `provider-6.1.1/`
- `fl_chart-0.66.2/`
- `flutter_slidable-3.1.2/`
- `share_plus-7.2.2/`

### 查看已安装的包
```bash
flutter pub deps --style=compact
```

---

## 🔗 配置文件中的路径引用

> **注意**: 以下配置示例使用 `D:/Softwaredata` 作为示例路径，请替换为你的实际路径。

### android/local.properties
```properties
sdk.dir=<YOUR_ANDROID_SDK>
flutter.sdk=<YOUR_FLUTTER_SDK>
flutter.buildMode=release
flutter.versionName=1.0.0
flutter.versionCode=1
```

### android/gradle.properties
```properties
org.gradle.jvmargs=-Xmx1G -Xms256m -Dfile.encoding=UTF-8
org.gradle.daemon=false
org.gradle.user.home=<YOUR_GRADLE_CACHE>
kotlin.incremental=false
kotlin.compiler.execution.strategy=in-process
android.useAndroidX=true
android.enableJetifier=true
android.nonTransitiveRClass=true
```

---

## 🗺️ 依赖关系图

```
┌─────────────────────────────────────┐
│      小熊记账本项目                  │
│            bear_bill/               │
└──────────────┬──────────────────────┘
               │
               ├─ 读取 pubspec.yaml
               │  └─ 从 PubCache 加载包
               │     └─ <YOUR_PUB_CACHE>
               │
               ├─ Flutter 编译
               │  └─ <YOUR_FLUTTER_SDK>
               │
               └─ Android 构建
                  ├─ Gradle (8.2)
                  │  └─ <YOUR_GRADLE_CACHE>
                  │
                  ├─ JDK 17
                  │  └─ <YOUR_JDK_PATH>
                  │
                  └─ Android SDK
                     └─ <YOUR_ANDROID_SDK>
                        ├─ build-tools/36.1.0
                        ├─ platforms/android-36
                        └─ platform-tools/
```

---

## ✅ 验证清单

### 检查所有路径是否存在
```powershell
# PowerShell 脚本 - 替换为你的实际路径
$paths = @(
    "<YOUR_FLUTTER_SDK>",
    "<YOUR_ANDROID_SDK>",
    "<YOUR_JDK_PATH>",
    "<YOUR_ANDROID_STUDIO>",
    "<YOUR_GRADLE_CACHE>",
    "<YOUR_PUB_CACHE>"
)

foreach ($path in $paths) {
    $exists = Test-Path $path
    $status = if ($exists) { "✅" } else { "❌" }
    Write-Host "$status $path"
}
```

### 运行 Flutter Doctor
```bash
flutter doctor -v
```

**期望输出**:
```
[√] Flutter (Channel stable, 3.24.0, ...)
    • Flutter version 3.24.0 at <YOUR_FLUTTER_SDK>
    
[√] Android toolchain - develop for Android devices
    • Android SDK at <YOUR_ANDROID_SDK>
    
[√] Android Studio (version 2025.3.2)
    • Android Studio at <YOUR_ANDROID_STUDIO>
```

---

## 🔧 常用命令

### 查看依赖信息
```bash
# Flutter 版本
flutter --version

# Dart 版本
dart --version

# 已安装的包
flutter pub deps

# 过时的包
flutter pub outdated

# Gradle 版本
cd android
./gradlew --version
```

### 清理和重建
```bash
# 清理 Flutter
flutter clean

# 清理 Pub 缓存
flutter pub cache clean

# 清理 Gradle 缓存
Remove-Item <YOUR_GRADLE_CACHE>/caches/* -Recurse -Force

# 重新获取依赖
flutter pub get

# 重新构建
flutter build apk --release
```

---

## 📊 空间占用统计

> **说明**: 以下为示例路径，实际大小因版本和缓存而异。

| 组件 | 示例路径 | 预估大小 |
|------|------|---------|
| Flutter SDK | `<YOUR_FLUTTER_SDK>` | ~1.5 GB |
| Android SDK | `<YOUR_ANDROID_SDK>` | ~8 GB |
| JDK 17 | `<YOUR_JDK_PATH>` | ~400 MB |
| Android Studio | `<YOUR_ANDROID_STUDIO>` | ~2.5 GB |
| GradleCache | `<YOUR_GRADLE_CACHE>` | ~3 GB |
| PubCache | `<YOUR_PUB_CACHE>` | ~800 MB |
| **总计** | | **~16.2 GB** |

### 查看实际占用
```powershell
Get-ChildItem D:/Softwaredata -Directory | 
Where-Object { $_.Name -in @('flutter', 'Android', 'Java', 'GradleCache', 'PubCache') } |
ForEach-Object { 
    $size = (Get-ChildItem $_.FullName -Recurse -ErrorAction SilentlyContinue | 
             Measure-Object -Property Length -Sum).Sum / 1GB
    [PSCustomObject]@{
        Name = $_.Name
        Path = $_.FullName
        Size_GB = [math]::Round($size, 2)
    }
} | Sort-Object Size_GB -Descending
```

---

## 💡 维护建议

### 定期清理
1. **每月清理一次 Gradle 缓存**
   ```bash
   flutter clean
   Remove-Item <YOUR_GRADLE_CACHE>/caches/* -Recurse -Force
   flutter pub get
   ```

2. **每季度清理未使用的 Android 平台**
   - 打开 Android Studio → SDK Manager
   - 删除不需要的 API 版本

3. **清理过时的 Flutter 包**
   ```bash
   flutter pub cache repair
   ```

### 备份重要数据
- 备份 `pubspec.yaml` - 依赖列表
- 备份 `android/` 配置 - 构建配置
- 不需要备份缓存目录（可以重新下载）
