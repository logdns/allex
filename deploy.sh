#!/bin/bash

# 外汇汇率推送服务快速部署脚本
# 支持多种部署方式

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_title() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# 检查命令是否存在
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 未安装，请先安装 $1"
        exit 1
    fi
}

# 检查Node.js版本
check_node_version() {
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$NODE_VERSION" -lt 16 ]; then
            print_error "Node.js版本过低，需要16.0.0或更高版本"
            exit 1
        fi
        print_message "Node.js版本检查通过: $(node --version)"
    else
        print_error "Node.js未安装"
        exit 1
    fi
}

# 安装依赖
install_dependencies() {
    print_title "安装项目依赖"
    npm install
    print_message "依赖安装完成"
}

# 配置环境变量
setup_env() {
    print_title "配置环境变量"
    
    if [ ! -f .env ]; then
        cp .env.example .env
        print_message "已创建 .env 文件"
        print_warning "请编辑 .env 文件，填入实际的Webhook URL"
        
        # 提示用户配置
        echo ""
        echo "请配置以下环境变量："
        echo "1. WECHAT_WEBHOOK_URL - 企业微信机器人Webhook URL"
        echo "2. DINGTALK_WEBHOOK_URL - 钉钉机器人Webhook URL"
        echo "3. FEISHU_WEBHOOK_URL - 飞书机器人Webhook URL"
        echo ""
        
        read -p "是否现在编辑 .env 文件? (y/n): " edit_env
        if [ "$edit_env" = "y" ] || [ "$edit_env" = "Y" ]; then
            ${EDITOR:-nano} .env
        fi
    else
        print_message ".env 文件已存在"
    fi
}

# 创建日志目录
create_log_dir() {
    if [ ! -d "logs" ]; then
        mkdir -p logs
        print_message "已创建日志目录"
    fi
}

# 测试服务
test_service() {
    print_title "测试服务"
    node test.js
}

# Node.js部署
deploy_nodejs() {
    print_title "Node.js 部署"
    
    check_node_version
    install_dependencies
    setup_env
    create_log_dir
    
    print_message "启动服务..."
    npm start &
    
    sleep 3
    
    # 检查服务是否启动成功
    if curl -f http://localhost:3000/status > /dev/null 2>&1; then
        print_message "服务启动成功！"
        print_message "访问 http://localhost:3000 查看服务状态"
        print_message "访问 http://localhost:3000/cron 手动触发推送"
    else
        print_error "服务启动失败，请检查日志"
    fi
}

# PM2部署
deploy_pm2() {
    print_title "PM2 部署"
    
    check_command pm2
    check_node_version
    install_dependencies
    setup_env
    create_log_dir
    
    print_message "使用PM2启动服务..."
    pm2 start ecosystem.config.js --env production
    pm2 save
    
    print_message "PM2部署完成！"
    print_message "使用 'pm2 status' 查看服务状态"
    print_message "使用 'pm2 logs forex-notifier' 查看日志"
}

# Docker部署
deploy_docker() {
    print_title "Docker 部署"
    
    check_command docker
    setup_env
    
    print_message "构建Docker镜像..."
    docker build -t forex-notifier .
    
    print_message "启动Docker容器..."
    docker run -d \
        --name forex-notifier \
        --restart unless-stopped \
        -p 3000:3000 \
        --env-file .env \
        -v $(pwd)/logs:/app/logs \
        forex-notifier
    
    sleep 3
    
    if docker ps | grep forex-notifier > /dev/null; then
        print_message "Docker部署成功！"
        print_message "容器已启动，端口: 3000"
        print_message "使用 'docker logs forex-notifier' 查看日志"
    else
        print_error "Docker容器启动失败"
    fi
}

# Docker Compose部署
deploy_docker_compose() {
    print_title "Docker Compose 部署"
    
    check_command docker-compose
    setup_env
    
    print_message "启动Docker Compose..."
    docker-compose up -d
    
    sleep 5
    
    if docker-compose ps | grep forex-notifier | grep Up > /dev/null; then
        print_message "Docker Compose部署成功！"
        print_message "使用 'docker-compose logs' 查看日志"
        print_message "使用 'docker-compose down' 停止服务"
    else
        print_error "Docker Compose启动失败"
    fi
}

# 设置定时任务
setup_cron() {
    print_title "设置定时任务"
    
    CRON_JOB="0 */5 * * * cd $(pwd) && node cron.js >> logs/cron.log 2>&1"
    
    # 检查是否已存在相同的定时任务
    if crontab -l 2>/dev/null | grep -q "node cron.js"; then
        print_warning "定时任务已存在"
    else
        # 添加定时任务
        (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
        print_message "定时任务已添加（每5小时执行一次）"
    fi
    
    print_message "当前定时任务："
    crontab -l | grep "node cron.js" || print_warning "未找到相关定时任务"
}

# 显示帮助信息
show_help() {
    echo "外汇汇率推送服务部署脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  nodejs     - Node.js直接部署"
    echo "  pm2        - 使用PM2部署"
    echo "  docker     - 使用Docker部署"
    echo "  compose    - 使用Docker Compose部署"
    echo "  cron       - 设置定时任务"
    echo "  test       - 测试服务"
    echo "  help       - 显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 nodejs   # Node.js部署"
    echo "  $0 pm2      # PM2部署"
    echo "  $0 docker   # Docker部署"
}

# 主函数
main() {
    case "$1" in
        nodejs)
            deploy_nodejs
            ;;
        pm2)
            deploy_pm2
            ;;
        docker)
            deploy_docker
            ;;
        compose)
            deploy_docker_compose
            ;;
        cron)
            setup_cron
            ;;
        test)
            test_service
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
}

# 检查参数
if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

main "$@"
