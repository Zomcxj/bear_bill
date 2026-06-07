@echo off
chcp 65001 >nul
echo ========================================
echo   小熊记账本 - APK 构建脚本
echo ========================================
echo.

:: 设置环境变量（避免中文路径问题）
set GRADLE_USER_HOME=D:\Softwaredata\GradleCache
set PUB_CACHE=D:\Softwaredata\PubCache

echo [1/4] 清理项目...
call flutter clean
echo.

echo [2/4] 获取依赖...
call flutter pub get
echo.

echo [3/4] 构建 Release APK...
call flutter build apk --release
echo.

echo [4/4] 构建完成！
echo.
echo APK 位置: build\app\outputs\flutter-apk\app-release.apk
echo.

:: 显示文件大小
for %%A in (build\app\outputs\flutter-apk\app-release.apk) do (
    echo 文件大小: %%~zA bytes
)
echo.
pause
