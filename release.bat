@echo off
setlocal enabledelayedexpansion

REM 外汇汇率推送服务Windows发布脚本

echo ========================================
echo 外汇汇率推送服务发布脚本 (Windows)
echo ========================================
echo.

if "%1"=="" (
    call :show_help
    exit /b 1
)

if "%1"=="help" call :show_help && exit /b 0
if "%1"=="--help" call :show_help && exit /b 0
if "%1"=="-h" call :show_help && exit /b 0

if "%1"=="major" call :main major && exit /b 0
if "%1"=="minor" call :main minor && exit /b 0
if "%1"=="patch" call :main patch && exit /b 0

echo [ERROR] 无效的版本类型: %1
call :show_help
exit /b 1

:show_help
echo 用法: %0 [版本类型]
echo.
echo 版本类型:
echo   major  - 主版本号 (1.0.0 -^> 2.0.0)
echo   minor  - 次版本号 (1.0.0 -^> 1.1.0)
echo   patch  - 补丁版本号 (1.0.0 -^> 1.0.1)
echo.
echo 示例:
echo   %0 patch   # 发布补丁版本
echo   %0 minor   # 发布次版本
echo   %0 major   # 发布主版本
exit /b 0

:check_git
git --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Git未安装，请先安装Git
    exit /b 1
)
exit /b 0

:check_git_repo
git rev-parse --git-dir >nul 2>&1
if errorlevel 1 (
    echo [WARNING] 当前目录不是Git仓库，正在初始化...
    git init
    echo [INFO] Git仓库初始化完成
)
exit /b 0

:check_working_directory
git status --porcelain >nul 2>&1
if not errorlevel 1 (
    for /f %%i in ('git status --porcelain') do (
        echo [WARNING] 工作区有未提交的更改
        git status --short
        echo.
        set /p continue_release="是否继续? (y/n): "
        if /i not "!continue_release!"=="y" (
            echo [INFO] 发布已取消
            exit /b 0
        )
        goto :continue_check
    )
)
:continue_check
exit /b 0

:setup_remote
set REMOTE_URL=https://github.com/logdns/allex.git

git remote get-url origin >nul 2>&1
if not errorlevel 1 (
    for /f %%i in ('git remote get-url origin') do set CURRENT_URL=%%i
    if not "!CURRENT_URL!"=="!REMOTE_URL!" (
        echo [WARNING] 远程仓库URL不匹配
        echo [INFO] 当前: !CURRENT_URL!
        echo [INFO] 期望: !REMOTE_URL!
        set /p update_remote="是否更新远程仓库URL? (y/n): "
        if /i "!update_remote!"=="y" (
            git remote set-url origin "!REMOTE_URL!"
            echo [INFO] 远程仓库URL已更新
        )
    )
) else (
    echo [INFO] 添加远程仓库...
    git remote add origin "!REMOTE_URL!"
    echo [INFO] 远程仓库已添加
)
exit /b 0

:get_current_version
if exist package.json (
    for /f "tokens=2 delims=:, " %%a in ('findstr "version" package.json') do (
        set VERSION=%%a
        set VERSION=!VERSION:"=!
        echo !VERSION!
        exit /b 0
    )
)
echo 1.0.0
exit /b 0

:update_version
set VERSION_TYPE=%1

call :get_current_version
set CURRENT_VERSION=!VERSION!
echo [INFO] 当前版本: !CURRENT_VERSION!

if exist package.json (
    npm version %VERSION_TYPE% --no-git-tag-version
    if errorlevel 1 (
        echo [ERROR] 版本更新失败
        exit /b 1
    )
    
    call :get_current_version
    set NEW_VERSION=!VERSION!
    echo [INFO] 新版本: !NEW_VERSION!
) else (
    echo [ERROR] package.json文件不存在
    exit /b 1
)
exit /b 0

:generate_changelog
set VERSION=%1
set CHANGELOG_FILE=CHANGELOG.md

for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (
    set DATE=%%c-%%a-%%b
)

if not exist "!CHANGELOG_FILE!" (
    (
        echo # 更新日志
        echo.
        echo 所有重要的项目更改都将记录在此文件中。
        echo.
        echo ## [!VERSION!] - !DATE!
        echo.
        echo ### 新增
        echo - 外汇汇率推送服务
        echo - 支持企业微信、钉钉、飞书推送
        echo - Markdown格式消息显示
        echo - 多种部署方式支持
        echo.
        echo ### 功能
        echo - 每5小时自动推送汇率更新
        echo - 支持美元、英镑、欧元、港币兑人民币汇率
        echo - 宝塔面板、Docker、PM2等多种部署方式
        echo - 自动化部署脚本
        echo.
    ) > "!CHANGELOG_FILE!"
) else (
    REM 创建临时文件并更新changelog
    (
        echo # 更新日志
        echo.
        echo 所有重要的项目更改都将记录在此文件中。
        echo.
        echo ## [!VERSION!] - !DATE!
        echo.
        echo ### 更改
        echo - 版本更新
        echo.
    ) > temp_changelog.md
    
    REM 跳过原文件前3行并追加到临时文件
    more +4 "!CHANGELOG_FILE!" >> temp_changelog.md
    move temp_changelog.md "!CHANGELOG_FILE!"
)

echo [INFO] 更新日志已生成: !CHANGELOG_FILE!
exit /b 0

:commit_changes
set VERSION=%1
set COMMIT_MESSAGE=chore: release version %VERSION%

echo [INFO] 添加文件到Git...
git add .

echo [INFO] 提交更改...
git commit -m "%COMMIT_MESSAGE%"
if errorlevel 1 (
    echo [ERROR] 提交失败
    exit /b 1
)

echo [INFO] 创建版本标签...
git tag -a "v%VERSION%" -m "Release version %VERSION%"
if errorlevel 1 (
    echo [ERROR] 标签创建失败
    exit /b 1
)
exit /b 0

:push_to_github
set VERSION=%1

echo [INFO] 推送到GitHub...

REM 推送主分支
git push origin main
if errorlevel 1 (
    git push origin master
    if errorlevel 1 (
        echo [ERROR] 推送分支失败
        exit /b 1
    )
)

REM 推送标签
git push origin "v%VERSION%"
if errorlevel 1 (
    echo [ERROR] 推送标签失败
    exit /b 1
)

echo [INFO] 推送完成！
echo [INFO] GitHub仓库: https://github.com/logdns/allex
echo [INFO] 发布页面: https://github.com/logdns/allex/releases/tag/v%VERSION%
exit /b 0

:main
set VERSION_TYPE=%1

echo === 外汇汇率推送服务发布流程 ===
echo.

REM 检查环境
call :check_git
if errorlevel 1 exit /b 1

call :check_git_repo
call :check_working_directory
call :setup_remote

REM 更新版本
call :update_version %VERSION_TYPE%
if errorlevel 1 exit /b 1

call :get_current_version
set NEW_VERSION=!VERSION!

REM 生成更新日志
call :generate_changelog !NEW_VERSION!

REM 提交更改
call :commit_changes !NEW_VERSION!
if errorlevel 1 exit /b 1

REM 推送到GitHub
call :push_to_github !NEW_VERSION!
if errorlevel 1 exit /b 1

echo === 发布完成 ===
echo [INFO] 版本 !NEW_VERSION! 已成功发布到GitHub！
exit /b 0
