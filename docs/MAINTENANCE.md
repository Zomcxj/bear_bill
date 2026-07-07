# 维护指南

本文档记录小熊记账本当前版本的日常维护方式、故障排查路径与缓存清理命令。

## 日常检查

推荐先跑这几条：

```bash
flutter pub get
flutter test
flutter build apk --release --target-platform android-arm64
```

当前项目测试基线应保持全绿。

## 缓存与构建清理

### Flutter 清理

```bash
flutter clean
flutter pub get
```

### Pub 缓存清理

```bash
flutter pub cache clean
flutter pub get
```

### Gradle 缓存清理

```powershell
Remove-Item <YOUR_GRADLE_CACHE>/caches/* -Recurse -Force
```

## Release 构建排查

当前 release 包只构建 arm64：

```bash
flutter build apk --release --target-platform android-arm64
```

输出路径：

```text
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

### 若 release 构建失败，优先检查

1. `android/key.properties` 是否存在
2. `android/app/bear_bill_release.jks` 是否存在
3. `key.properties` 中的 `storeFile` 路径是否正确
4. `pubspec.yaml` 的版本号是否符合 `x.y.z+build` 格式
5. JDK、Android SDK、Gradle 缓存路径是否可访问

说明：

- 签名文件属于本地敏感材料
- 不能把真实密码写进文档、issue、提交说明

## 自动记账维护

当前自动记账主链路：

1. Android 通知监听服务捕获通知
2. MethodChannel 传给 Flutter
3. `AutoRecordService` 解析通知
4. 生成候选记录
5. 由用户确认后入账

这意味着排查时要区分三类问题：

- 通知没有被捕获
- 通知捕获了，但候选记录没有生成
- 候选生成了，但确认流程没有走通

### 自动记账排查清单

1. 检查应用通知权限，尤其是 Android 13+ 的 `POST_NOTIFICATIONS`
2. 检查系统通知监听权限是否已授予
3. 检查通知监听服务是否运行
4. 检查自动记账开关是否已开启
5. 检查点击通知后是否回到统一解析链路

### 当前实现特征

- 主路径不是无障碍
- 默认优先本地解析，网络解析只是兜底
- 候选记录不会直接入库，避免误记账
- 支付宝/银行卡双事件存在 1 秒内优先级处理逻辑

## 数据备份与恢复

当前正式备份路径是应用内导入导出：

- 设置页 -> 导出数据
- 设置页 -> 导入数据

对应实现文件：

- `lib/services/database_backup_service.dart`

备份内容包括：

- 数据库文件
- WAL / SHM 文件
- 图片附件
- 头像
- 本地文本存储文件

## 常见问题

### 1. Gradle 守护进程或 Kotlin 编译失败

常见原因：Windows 用户目录含中文，或缓存目录损坏。

建议操作：

```bash
flutter clean
flutter pub get
```

如仍失败，再清理 Gradle / Pub 缓存。

### 2. 自动记账没有反应

优先排查：

- 是否开启通知权限
- 是否开启通知监听权限
- 自动记账开关是否启用
- 是否是余额变动而非真实支付通知

### 3. 版本号改了但装不上覆盖包

原因通常不是 `versionName`，而是 `versionCode` 没有递增。

当前规则：

- `pubspec.yaml` 中 `version` 的 `+` 后数字必须递增

### 4. README 或 docs 与代码不一致

优先以以下文件为准：

- `pubspec.yaml`
- `android/app/build.gradle`
- `lib/pages/profile/widgets/settings_list.dart`
- `lib/main.dart`
- `lib/services/auto_record_service.dart`

## 敏感文件维护规范

以下内容只保留在本地：

- `lib/config/api_keys.dart`
- `android/key.properties`
- `android/app/*.jks`

以下目录属于构建产物：

- `build/`
- `release/`
- `releases/`

## 建议的定期维护节奏

- 每次功能改动后：跑 `flutter test`
- 每次发布前：跑 release 构建并确认产物路径
- 每月一次：清理 Gradle 缓存与无效构建产物
- 文档变更后：同步 README 与 `docs/` 口径
