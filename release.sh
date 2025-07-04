#!/bin/bash

# 外汇汇率推送服务发布脚本
# 用于自动化版本发布到GitHub

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

# 检查Git是否安装
check_git() {
    if ! command -v git &> /dev/null; then
        print_error "Git未安装，请先安装Git"
        exit 1
    fi
}

# 检查是否在Git仓库中
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_warning "当前目录不是Git仓库，正在初始化..."
        git init
        print_message "Git仓库初始化完成"
    fi
}

# 检查工作区状态
check_working_directory() {
    if [ -n "$(git status --porcelain)" ]; then
        print_warning "工作区有未提交的更改"
        git status --short
        echo ""
        read -p "是否继续? (y/n): " continue_release
        if [ "$continue_release" != "y" ] && [ "$continue_release" != "Y" ]; then
            print_message "发布已取消"
            exit 0
        fi
    fi
}

# 设置远程仓库
setup_remote() {
    local remote_url="https://github.com/logdns/allex.git"
    
    if git remote get-url origin > /dev/null 2>&1; then
        local current_url=$(git remote get-url origin)
        if [ "$current_url" != "$remote_url" ]; then
            print_warning "远程仓库URL不匹配"
            print_message "当前: $current_url"
            print_message "期望: $remote_url"
            read -p "是否更新远程仓库URL? (y/n): " update_remote
            if [ "$update_remote" = "y" ] || [ "$update_remote" = "Y" ]; then
                git remote set-url origin "$remote_url"
                print_message "远程仓库URL已更新"
            fi
        fi
    else
        print_message "添加远程仓库..."
        git remote add origin "$remote_url"
        print_message "远程仓库已添加"
    fi
}

# 获取当前版本
get_current_version() {
    if [ -f package.json ]; then
        grep '"version"' package.json | sed 's/.*"version": "\(.*\)".*/\1/'
    else
        echo "1.0.0"
    fi
}

# 更新版本号
update_version() {
    local version_type=$1
    local current_version=$(get_current_version)
    
    print_message "当前版本: $current_version"
    
    if [ -f package.json ]; then
        case $version_type in
            major)
                npm version major --no-git-tag-version
                ;;
            minor)
                npm version minor --no-git-tag-version
                ;;
            patch)
                npm version patch --no-git-tag-version
                ;;
            *)
                print_error "无效的版本类型: $version_type"
                print_message "支持的类型: major, minor, patch"
                exit 1
                ;;
        esac
        
        local new_version=$(get_current_version)
        print_message "新版本: $new_version"
        echo $new_version
    else
        print_error "package.json文件不存在"
        exit 1
    fi
}

# 生成更新日志
generate_changelog() {
    local version=$1
    local changelog_file="CHANGELOG.md"
    local date=$(date +"%Y-%m-%d")
    
    if [ ! -f "$changelog_file" ]; then
        cat > "$changelog_file" << EOF
# 更新日志

所有重要的项目更改都将记录在此文件中。

## [${version}] - ${date}

### 新增
- 外汇汇率推送服务
- 支持企业微信、钉钉、飞书推送
- Markdown格式消息显示
- 多种部署方式支持

### 功能
- 每5小时自动推送汇率更新
- 支持美元、英镑、欧元、港币兑人民币汇率
- 宝塔面板、Docker、PM2等多种部署方式
- 自动化部署脚本

EOF
    else
        # 在现有changelog前面插入新版本
        local temp_file=$(mktemp)
        echo "# 更新日志" > "$temp_file"
        echo "" >> "$temp_file"
        echo "所有重要的项目更改都将记录在此文件中。" >> "$temp_file"
        echo "" >> "$temp_file"
        echo "## [${version}] - ${date}" >> "$temp_file"
        echo "" >> "$temp_file"
        echo "### 更改" >> "$temp_file"
        echo "- 版本更新" >> "$temp_file"
        echo "" >> "$temp_file"
        
        # 跳过原文件的前3行（标题和描述）
        tail -n +4 "$changelog_file" >> "$temp_file"
        mv "$temp_file" "$changelog_file"
    fi
    
    print_message "更新日志已生成: $changelog_file"
}

# 提交更改
commit_changes() {
    local version=$1
    local commit_message="chore: release version $version"
    
    print_message "添加文件到Git..."
    git add .
    
    print_message "提交更改..."
    git commit -m "$commit_message"
    
    print_message "创建版本标签..."
    git tag -a "v$version" -m "Release version $version"
}

# 推送到GitHub
push_to_github() {
    local version=$1
    
    print_message "推送到GitHub..."
    
    # 推送主分支
    git push origin main || git push origin master
    
    # 推送标签
    git push origin "v$version"
    
    print_message "推送完成！"
    print_message "GitHub仓库: https://github.com/logdns/allex"
    print_message "发布页面: https://github.com/logdns/allex/releases/tag/v$version"
}

# 显示帮助信息
show_help() {
    echo "外汇汇率推送服务发布脚本"
    echo ""
    echo "用法: $0 [版本类型]"
    echo ""
    echo "版本类型:"
    echo "  major  - 主版本号 (1.0.0 -> 2.0.0)"
    echo "  minor  - 次版本号 (1.0.0 -> 1.1.0)"
    echo "  patch  - 补丁版本号 (1.0.0 -> 1.0.1)"
    echo ""
    echo "示例:"
    echo "  $0 patch   # 发布补丁版本"
    echo "  $0 minor   # 发布次版本"
    echo "  $0 major   # 发布主版本"
}

# 主函数
main() {
    local version_type=$1
    
    if [ -z "$version_type" ]; then
        show_help
        exit 1
    fi
    
    if [ "$version_type" = "help" ] || [ "$version_type" = "--help" ] || [ "$version_type" = "-h" ]; then
        show_help
        exit 0
    fi
    
    print_title "外汇汇率推送服务发布流程"
    
    # 检查环境
    check_git
    check_git_repo
    check_working_directory
    setup_remote
    
    # 更新版本
    local new_version=$(update_version "$version_type")
    
    # 生成更新日志
    generate_changelog "$new_version"
    
    # 提交更改
    commit_changes "$new_version"
    
    # 推送到GitHub
    push_to_github "$new_version"
    
    print_title "发布完成"
    print_message "版本 $new_version 已成功发布到GitHub！"
}

main "$@"
