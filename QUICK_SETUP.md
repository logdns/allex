# 快速连接到 GitHub allex 仓库

## 🚀 一键执行命令

请打开命令行（cmd 或 PowerShell），导航到项目目录，然后**逐行**执行以下命令：

```cmd
# 1. 导航到项目目录
cd c:\Users\xiaofeng\Desktop\dev

# 2. 初始化Git仓库（如果还没有）
git init

# 3. 配置Git用户信息
git config user.name "logdns"
git config user.email "logdns@users.noreply.github.com"

# 4. 添加远程仓库
git remote add origin https://github.com/logdns/allex.git

# 5. 添加所有文件
git add .

# 6. 提交初始版本
git commit -m "feat: initial commit - forex notifier service v1.0.0"

# 7. 设置主分支
git branch -M main

# 8. 推送到GitHub
git push -u origin main

# 9. 创建版本标签
git tag -a v1.0.0 -m "Release version 1.0.0"

# 10. 推送标签
git push origin v1.0.0
```

## 📋 执行后的验证

1. 访问 https://github.com/logdns/allex
2. 确认所有文件已上传
3. 检查是否有 v1.0.0 标签

## 🏷️ 创建GitHub Release

1. 在GitHub仓库页面点击 "Releases"
2. 点击 "Create a new release"
3. 选择标签：`v1.0.0`
4. 发布标题：`v1.0.0 - 外汇汇率推送服务首次发布`
5. 发布描述：

```markdown
## 🎉 外汇汇率推送服务首次发布

### ✨ 新增功能
- 📱 支持企业微信、钉钉、飞书三大平台推送
- 💱 支持美元、英镑、欧元、港币兑人民币汇率查询
- 📝 使用Markdown格式美化消息显示
- ⏰ 每5小时自动推送汇率更新
- 🕐 显示香港时间和下次更新时间

### 🚀 部署支持
- 🐳 Docker容器化部署
- 📦 Docker Compose一键部署
- 🚀 PM2进程管理部署
- 🖥️ Node.js直接部署
- ☁️ Cloudflare Workers无服务器部署
- 🎛️ 宝塔面板可视化部署

### 📖 快速开始

1. 克隆项目：`git clone https://github.com/logdns/allex.git`
2. 安装依赖：`npm install`
3. 配置环境变量：`cp .env.example .env`
4. 启动服务：`npm start`

详细部署指南请查看项目文档。

### 🔧 技术栈
- Node.js 16+ 运行环境
- 原生HTTP模块，轻量级设计
- Docker多平台支持
- 完整的CI/CD流水线
```

6. 点击 "Publish release"

## ⚠️ 可能遇到的问题

### 认证问题
如果推送时遇到认证问题，GitHub现在要求使用Personal Access Token：

1. 访问 GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. 点击 "Generate new token (classic)"
3. 选择权限：`repo`, `workflow`, `write:packages`
4. 复制生成的token
5. 在推送时使用token作为密码

### 远程仓库已存在内容
如果遇到推送被拒绝的错误：
```cmd
git pull origin main --allow-unrelated-histories
git push origin main
```

## 🎯 完成后的状态

✅ 项目已连接到 https://github.com/logdns/allex  
✅ 代码已推送到GitHub  
✅ 版本标签 v1.0.0 已创建  
✅ 可以创建正式的GitHub Release  

## 📞 需要帮助？

如果在执行过程中遇到任何问题，请告诉我具体的错误信息，我会帮您解决！
