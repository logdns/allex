@echo off
setlocal enabledelayedexpansion

REM 外汇汇率推送服务Windows部署脚本

echo ========================================
echo 外汇汇率推送服务部署脚本 (Windows)
echo ========================================
echo.

if "%1"=="" (
    call :show_help
    exit /b 1
)

if "%1"=="help" call :show_help && exit /b 0
if "%1"=="nodejs" call :deploy_nodejs && exit /b 0
if "%1"=="pm2" call :deploy_pm2 && exit /b 0
if "%1"=="docker" call :deploy_docker && exit /b 0
if "%1"=="test" call :test_service && exit /b 0
if "%1"=="cron" call :setup_task && exit /b 0

echo [ERROR] 未知选项: %1
call :show_help
exit /b 1

:show_help
echo 用法: %0 [选项]
echo.
echo 选项:
echo   nodejs     - Node.js直接部署
echo   pm2        - 使用PM2部署
echo   docker     - 使用Docker部署
echo   test       - 测试服务
echo   cron       - 设置Windows计划任务
echo   help       - 显示此帮助信息
echo.
echo 示例:
echo   %0 nodejs   # Node.js部署
echo   %0 pm2      # PM2部署
echo   %0 docker   # Docker部署
exit /b 0

:check_node
echo [INFO] 检查Node.js版本...
node --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Node.js未安装，请先安装Node.js
    exit /b 1
)
for /f "tokens=1 delims=." %%a in ('node --version') do (
    set NODE_MAJOR=%%a
    set NODE_MAJOR=!NODE_MAJOR:v=!
)
if !NODE_MAJOR! LSS 16 (
    echo [ERROR] Node.js版本过低，需要16.0.0或更高版本
    exit /b 1
)
echo [INFO] Node.js版本检查通过
exit /b 0

:install_dependencies
echo [INFO] 安装项目依赖...
npm install
if errorlevel 1 (
    echo [ERROR] 依赖安装失败
    exit /b 1
)
echo [INFO] 依赖安装完成
exit /b 0

:setup_env
echo [INFO] 配置环境变量...
if not exist .env (
    copy .env.example .env >nul
    echo [INFO] 已创建 .env 文件
    echo [WARNING] 请编辑 .env 文件，填入实际的Webhook URL
    echo.
    echo 请配置以下环境变量：
    echo 1. WECHAT_WEBHOOK_URL - 企业微信机器人Webhook URL
    echo 2. DINGTALK_WEBHOOK_URL - 钉钉机器人Webhook URL
    echo 3. FEISHU_WEBHOOK_URL - 飞书机器人Webhook URL
    echo.
    set /p edit_env="是否现在编辑 .env 文件? (y/n): "
    if /i "!edit_env!"=="y" (
        notepad .env
    )
) else (
    echo [INFO] .env 文件已存在
)
exit /b 0

:create_log_dir
if not exist logs (
    mkdir logs
    echo [INFO] 已创建日志目录
)
exit /b 0

:test_service
echo [INFO] 测试服务...
node test.js
exit /b 0

:deploy_nodejs
echo === Node.js 部署 ===
call :check_node
if errorlevel 1 exit /b 1

call :install_dependencies
if errorlevel 1 exit /b 1

call :setup_env
call :create_log_dir

echo [INFO] 启动服务...
start /b npm start

timeout /t 3 /nobreak >nul

REM 检查服务是否启动成功
curl -f http://localhost:3000/status >nul 2>&1
if errorlevel 1 (
    echo [ERROR] 服务启动失败，请检查日志
    exit /b 1
) else (
    echo [INFO] 服务启动成功！
    echo [INFO] 访问 http://localhost:3000 查看服务状态
    echo [INFO] 访问 http://localhost:3000/cron 手动触发推送
)
exit /b 0

:deploy_pm2
echo === PM2 部署 ===
pm2 --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] PM2未安装，请先安装PM2: npm install -g pm2
    exit /b 1
)

call :check_node
if errorlevel 1 exit /b 1

call :install_dependencies
if errorlevel 1 exit /b 1

call :setup_env
call :create_log_dir

echo [INFO] 使用PM2启动服务...
pm2 start ecosystem.config.js --env production
pm2 save

echo [INFO] PM2部署完成！
echo [INFO] 使用 'pm2 status' 查看服务状态
echo [INFO] 使用 'pm2 logs forex-notifier' 查看日志
exit /b 0

:deploy_docker
echo === Docker 部署 ===
docker --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker未安装，请先安装Docker
    exit /b 1
)

call :setup_env

echo [INFO] 构建Docker镜像...
docker build -t forex-notifier .
if errorlevel 1 (
    echo [ERROR] Docker镜像构建失败
    exit /b 1
)

echo [INFO] 启动Docker容器...
docker run -d --name forex-notifier --restart unless-stopped -p 3000:3000 --env-file .env -v %cd%/logs:/app/logs forex-notifier
if errorlevel 1 (
    echo [ERROR] Docker容器启动失败
    exit /b 1
)

timeout /t 3 /nobreak >nul

docker ps | findstr forex-notifier >nul
if errorlevel 1 (
    echo [ERROR] Docker容器启动失败
    exit /b 1
) else (
    echo [INFO] Docker部署成功！
    echo [INFO] 容器已启动，端口: 3000
    echo [INFO] 使用 'docker logs forex-notifier' 查看日志
)
exit /b 0

:setup_task
echo === 设置Windows计划任务 ===
set TASK_NAME=ForexNotifier
set SCRIPT_PATH=%cd%\cron.js

REM 检查任务是否已存在
schtasks /query /tn "%TASK_NAME%" >nul 2>&1
if not errorlevel 1 (
    echo [WARNING] 计划任务已存在，正在删除旧任务...
    schtasks /delete /tn "%TASK_NAME%" /f >nul
)

REM 创建新的计划任务（每5小时执行一次）
echo [INFO] 创建计划任务...
schtasks /create /tn "%TASK_NAME%" /tr "node \"%SCRIPT_PATH%\"" /sc hourly /mo 5 /st 00:00 /f
if errorlevel 1 (
    echo [ERROR] 计划任务创建失败
    exit /b 1
)

echo [INFO] 计划任务创建成功！
echo [INFO] 任务名称: %TASK_NAME%
echo [INFO] 执行频率: 每5小时
echo [INFO] 使用 'schtasks /query /tn "%TASK_NAME%"' 查看任务详情
exit /b 0
