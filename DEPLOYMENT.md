# 外汇汇率推送服务 - 部署指南

本文档提供多种部署方式，包括宝塔面板、Docker、Node.js等部署方案。

## 目录
- [宝塔面板部署](#宝塔面板部署)
- [Docker部署](#docker部署)
- [Node.js直接部署](#nodejs直接部署)
- [Cloudflare Workers部署](#cloudflare-workers部署)
- [PM2部署](#pm2部署)

## 宝塔面板部署

### 前置要求
- 已安装宝塔面板
- 已安装Node.js管理器
- 服务器可访问外网

### 部署步骤

1. **创建项目目录**
   ```bash
   mkdir /www/wwwroot/forex-notifier
   cd /www/wwwroot/forex-notifier
   ```

2. **上传项目文件**
   - 通过宝塔文件管理器上传所有项目文件
   - 或使用Git克隆项目

3. **安装依赖**
   ```bash
   npm install
   ```

4. **配置环境变量**
   - 在宝塔面板中设置环境变量
   - 或创建 `.env` 文件

5. **配置定时任务**
   - 进入宝塔面板 -> 计划任务
   - 添加Shell脚本任务
   - 执行周期：每5小时
   - 脚本内容：
   ```bash
   cd /www/wwwroot/forex-notifier && node server.js
   ```

6. **启动服务**
   - 使用宝塔Node.js管理器启动项目
   - 或使用PM2管理进程

## Docker部署

### 1. 构建Docker镜像

创建 `Dockerfile`：
```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install --production

COPY . .

EXPOSE 3000

CMD ["node", "server.js"]
```

构建镜像：
```bash
docker build -t forex-notifier .
```

### 2. 使用Docker Compose

创建 `docker-compose.yml`：
```yaml
version: '3.8'

services:
  forex-notifier:
    build: .
    container_name: forex-notifier
    restart: unless-stopped
    environment:
      - NODE_ENV=production
      - WECHAT_WEBHOOK_URL=${WECHAT_WEBHOOK_URL}
      - DINGTALK_WEBHOOK_URL=${DINGTALK_WEBHOOK_URL}
      - FEISHU_WEBHOOK_URL=${FEISHU_WEBHOOK_URL}
    volumes:
      - ./logs:/app/logs
    ports:
      - "3000:3000"
```

启动服务：
```bash
docker-compose up -d
```

### 3. 设置定时任务

在宿主机上设置crontab：
```bash
# 编辑crontab
crontab -e

# 添加定时任务（每5小时执行一次）
0 */5 * * * docker exec forex-notifier node cron.js
```

## Node.js直接部署

### 1. 环境准备
```bash
# 安装Node.js (推荐18+版本)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# 验证安装
node --version
npm --version
```

### 2. 项目部署
```bash
# 克隆项目
git clone <your-repo-url>
cd forex-notifier

# 安装依赖
npm install

# 配置环境变量
cp .env.example .env
# 编辑 .env 文件，填入实际的Webhook URL

# 启动服务
npm start
```

### 3. 配置系统服务

创建systemd服务文件：
```bash
sudo nano /etc/systemd/system/forex-notifier.service
```

内容：
```ini
[Unit]
Description=Forex Notifier Service
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/path/to/forex-notifier
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
```

启用服务：
```bash
sudo systemctl enable forex-notifier
sudo systemctl start forex-notifier
sudo systemctl status forex-notifier
```

## Cloudflare Workers部署

### 1. 安装Wrangler CLI
```bash
npm install -g wrangler
```

### 2. 登录Cloudflare
```bash
wrangler login
```

### 3. 创建wrangler.toml
```toml
name = "forex-notifier"
main = "worker.js"
compatibility_date = "2023-12-01"

[triggers]
crons = ["0 */5 * * *"]

[vars]
WECHAT_WEBHOOK_URL = "your_wechat_webhook_url"
DINGTALK_WEBHOOK_URL = "your_dingtalk_webhook_url"
FEISHU_WEBHOOK_URL = "your_feishu_webhook_url"
```

### 4. 部署
```bash
wrangler deploy
```

## PM2部署

### 1. 安装PM2
```bash
npm install -g pm2
```

### 2. 创建PM2配置文件

创建 `ecosystem.config.js`：
```javascript
module.exports = {
  apps: [{
    name: 'forex-notifier',
    script: 'server.js',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'development'
    },
    env_production: {
      NODE_ENV: 'production'
    }
  }]
};
```

### 3. 启动服务
```bash
# 启动应用
pm2 start ecosystem.config.js --env production

# 保存PM2配置
pm2 save

# 设置开机自启
pm2 startup
```

### 4. 配置定时任务
```bash
# 安装pm2-cron
pm2 install pm2-cron

# 添加定时任务
pm2 start cron.js --cron "0 */5 * * *" --name "forex-cron"
```

## 环境变量配置

无论使用哪种部署方式，都需要配置以下环境变量：

```bash
# 企业微信Webhook URL
WECHAT_WEBHOOK_URL=https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=YOUR_KEY

# 钉钉Webhook URL
DINGTALK_WEBHOOK_URL=https://oapi.dingtalk.com/robot/send?access_token=YOUR_TOKEN

# 飞书Webhook URL
FEISHU_WEBHOOK_URL=https://open.feishu.cn/open-apis/bot/v2/hook/YOUR_TOKEN
```

## 监控和日志

### 日志配置
建议配置日志轮转和监控：

```bash
# 使用logrotate管理日志
sudo nano /etc/logrotate.d/forex-notifier
```

内容：
```
/path/to/forex-notifier/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 www-data www-data
}
```

### 健康检查
可以添加健康检查端点来监控服务状态。

## 故障排除

1. **检查网络连接**
2. **验证Webhook URL配置**
3. **查看应用日志**
4. **检查防火墙设置**
5. **确认定时任务配置**

选择适合您环境的部署方式，推荐使用Docker或PM2进行生产环境部署。
