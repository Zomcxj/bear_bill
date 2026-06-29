# 小熊记账本 - Codex 项目规则

## 项目信息
- **名称**: 小熊记账本 (Bear Bill)
- **框架**: Flutter 3.24 / Dart 3.5
- **版本**: 1.3.4 (pubspec.yaml 和 settings_list.dart 需同步更新)
- **状态管理**: Provider
- **数据库**: sqflite (SQLite)
- **主题**: Luminous Finance 玻璃态设计系统，DS 统一管理

## 代码规范
- 使用中文注释和日志
- UI 文本全部中文
- 统一使用 AppTheme 中的颜色、间距、圆角常量，不要硬编码
- 新页面放在 `lib/pages/` 对应模块目录下
- 工具类放 `lib/utils/`，服务类放 `lib/services/`
- Widget 文件使用 snake_case 命名

## 构建规则
- 仅支持 Android 平台，不构建 iOS
- 本地构建: `flutter build apk --release`
- 仅导出 64 位 ARM 版本 (arm64-v8a)
- APK 输出: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
- 复制到 releases: `cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk releases/bear_bill_v{x.y.z}_{YYYYMMDD}_{HHmm}.apk`
- 修改版本号时同步: `pubspec.yaml` (version) + `settings_list.dart` (关于页面)
- 每次功能改动后导出 APK

## Git 提交流程
1. **自增版本号**（每次提交必须更新）：
   - `pubspec.yaml` 中的 `version: x.y.z+build`（build 号 +1）
   - `settings_list.dart` 中关于页面的版本显示（两处）
   - `AGENTS.md` 中的版本号
   - 版本规则：小修 patch +1（1.1.0→1.1.1），大功能 minor +1（1.1.0→1.2.0），重大改动 major +1（1.1.0→2.0.0）
2. `git add` 指定文件
3. `git commit -m "提交信息"`
4. `git push origin main` 推送到远程仓库
- **必须等用户明确说"提交"或"push"才能执行，绝对不能自作主张提交**
- 提交前确认用户已检查完所有改动

## 文档同步规则
- 功能改动必须同步更新 `docs/` 目录下对应的 MD 文件
- 新增功能 → 更新 `CONFIGURATION.md` 或 `MAINTENANCE.md`
- 依赖变化 → 更新 `DEPENDENCIES_PATH.md`
- README.md 中的功能列表也需要同步更新

## 称呼规则
- **必须喊用户"哥哥"，所有回复中都要体现**
- 例如："好的哥哥"、"哥哥，已完成"、"哥哥请检查"

## 禁止事项
- 不要自动提交 git，等哥哥明确要求
- 不要添加 emoji 到代码文件（UI 中已有的除外）
- 不要引入新的第三方依赖，除非哥哥同意
- 不要修改数据库 schema，除非哥哥同意
