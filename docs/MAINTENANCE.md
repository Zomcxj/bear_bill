# 🔧 维护指南

本文档涵盖项目的缓存管理、清理命令及常见问题解决方案。

> **注意**: 文档中的 `<YOUR_XXX>` 为占位符，请替换为你自己的路径。例如：
> - `<YOUR_GRADLE_CACHE>` → `D:/Softwaredata/GradleCache` 或 `C:/Users/YourName/.gradle`
> - `<YOUR_PUB_CACHE>` → `D:/Softwaredata/PubCache` 或 `%LOCALAPPDATA%/Pub/Cache`

---

## 📋 目录

- [缓存路径配置](#缓存路径配置)
- [清理命令](#清理命令)
- [常见问题](#常见问题)

---

## 💾 缓存路径配置

### 当前缓存位置

| 缓存类型 | 路径 | 大小 |
|---------|------|------|
| Gradle 缓存 | `<YOUR_GRADLE_CACHE>` | ~3 GB |
| Flutter Pub 缓存 | `<YOUR_PUB_CACHE>` | ~800 MB |

### 配置文件

#### android/gradle.properties
```properties
org.gradle.user.home=<YOUR_GRADLE_CACHE>
org.gradle.daemon=false
kotlin.incremental=false
kotlin.compiler.execution.strategy=in-process
```

#### build-apk.cmd
```cmd
set PUB_CACHE=<YOUR_PUB_CACHE>
set GRADLE_USER_HOME=<YOUR_GRADLE_CACHE>
```

### 环境变量（可选）

如需永久生效，可设置系统环境变量：

| 变量名 | 值 |
|--------|---|
| `GRADLE_USER_HOME` | `<YOUR_GRADLE_CACHE>` |
| `PUB_CACHE` | `<YOUR_PUB_CACHE>` |

---

## 🧹 清理命令

### Flutter 清理

```bash
# 清理构建文件
flutter clean

# 清理 Pub 缓存
flutter pub cache clean

# 重新获取依赖
flutter pub get
```

### Gradle 清理

```powershell
# PowerShell - 清理 Gradle 缓存
Remove-Item <YOUR_GRADLE_CACHE>/caches/* -Recurse -Force

# 清理特定版本
Remove-Item <YOUR_GRADLE_CACHE>/caches/transforms-3 -Recurse -Force
Remove-Item <YOUR_GRADLE_CACHE>/caches/jars-9 -Recurse -Force
```

### Android SDK 清理

通过 Android Studio：
1. 打开 Android Studio
2. Tools → SDK Manager
3. 删除不需要的 API 版本和构建工具

### 查看空间占用

```powershell
# PowerShell 脚本 - 查看各组件占用
$paths = @(
    "<YOUR_FLUTTER_SDK>",
    "<YOUR_ANDROID_SDK>",
    "<YOUR_JDK_PATH>",
    "<YOUR_GRADLE_CACHE>",
    "<YOUR_PUB_CACHE>"
)

foreach ($path in $paths) {
    if (Test-Path $path) {
        $size = (Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue | 
                 Measure-Object -Property Length -Sum).Sum / 1GB
        [PSCustomObject]@{
            Path = $path
            Size_GB = [math]::Round($size, 2)
        }
    }
}
```

---

## ❓ 常见问题

### Q1: 构建失败，提示找不到缓存

**错误信息**:
```
Could not load compiled classes for settings file
```

**解决方案**:
1. 检查环境变量是否正确设置
2. 确认文件夹存在于 `<YOUR_GRADLE_CACHE>` 和 `<YOUR_PUB_CACHE>`
3. 清理并重新构建：
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --release
   ```

### Q2: Gradle 守护进程启动失败

**错误信息**:
```
Unable to start the daemon process.
ClassNotFoundException: org.gradle.instrumentation.agent.Agent
```

**原因**: 用户路径包含中文字符

**解决方案**:
已在 `build-apk.cmd` 中自动设置环境变量，直接运行即可：
```cmd
.\build-apk.cmd
```

或手动设置：
```powershell
$env:GRADLE_USER_HOME="<YOUR_GRADLE_CACHE>"
$env:PUB_CACHE="<YOUR_PUB_CACHE>"
```

### Q3: Kotlin 编译失败

**错误信息**:
```
Could not connect to Kotlin compile daemon
source file or directory not found: C:/Users/中文字符/...
```

**解决方案**:
1. 确保已设置 `PUB_CACHE` 和 `GRADLE_USER_HOME`
2. 清理缓存并重新构建

### Q4: 如何定期维护缓存？

**建议频率**:
- **每月**: 清理 Gradle 缓存
  ```bash
  flutter clean
  Remove-Item <YOUR_GRADLE_CACHE>/caches/* -Recurse -Force
  flutter pub get
  ```

- **每季度**: 清理未使用的 Android 平台
  - 打开 Android Studio → SDK Manager
  - 删除不需要的 API 版本

- **每半年**: 清理过时的 Flutter 包
  ```bash
  flutter pub cache repair
  ```

### Q5: 如何备份重要数据？

**需要备份**:
- ✅ `pubspec.yaml` - 依赖列表
- ✅ `android/` 配置 - 构建配置
- ✅ `lib/` - 源代码

**无需备份**:
- ❌ 缓存目录（可以重新下载）
- ❌ build/ 目录（可以重新构建）
