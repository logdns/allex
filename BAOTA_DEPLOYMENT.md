# 宝塔面板部署指南

本指南详细介绍如何在宝塔面板中部署外汇汇率推送服务。

## 前置要求

1. 已安装宝塔面板（7.x或更高版本）
2. 已安装Node.js管理器插件
3. 服务器可以访问外网
4. 已获取企业微信、钉钉、飞书的Webhook URL

## 部署步骤

### 1. 安装Node.js环境

1. 登录宝塔面板
2. 进入 **软件商店** -> **运行环境**
3. 找到 **Node.js版本管理器** 并安装
4. 安装Node.js 18.x版本（推荐）

### 2. 创建项目目录

1. 进入 **文件** 管理
2. 在 `/www/wwwroot/` 下创建新目录 `forex-notifier`
3. 进入该目录

### 3. 上传项目文件

**方法一：通过文件管理器上传**
1. 将所有项目文件打包成zip
2. 通过宝塔文件管理器上传并解压

**方法二：通过Git克隆（推荐）**
1. 在宝塔终端中执行：
```bash
cd /www/wwwroot/
git clone <your-repo-url> forex-notifier
cd forex-notifier
```

### 4. 安装项目依赖

1. 在宝塔终端中执行：
```bash
cd /www/wwwroot/forex-notifier
npm install
```

### 5. 配置环境变量

1. 复制环境变量模板：
```bash
cp .env.example .env
```

2. 编辑 `.env` 文件，填入实际的Webhook URL：
```bash
nano .env
```

内容示例：
```
PORT=3000
WECHAT_WEBHOOK_URL=https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=YOUR_ACTUAL_KEY
DINGTALK_WEBHOOK_URL=https://oapi.dingtalk.com/robot/send?access_token=YOUR_ACTUAL_TOKEN
FEISHU_WEBHOOK_URL=https://open.feishu.cn/open-apis/bot/v2/hook/YOUR_ACTUAL_TOKEN
NODE_ENV=production
```

### 6. 测试服务

1. 启动服务测试：
```bash
node server.js
```

2. 在浏览器中访问：`http://your-server-ip:3000`
3. 测试推送：访问 `http://your-server-ip:3000/cron`

### 7. 配置Node.js项目管理

1. 进入宝塔面板 -> **Node.js项目**
2. 点击 **添加Node.js项目**
3. 填写项目信息：
   - **项目名称**：forex-notifier
   - **项目目录**：/www/wwwroot/forex-notifier
   - **启动文件**：server.js
   - **端口**：3000
   - **Node版本**：选择已安装的18.x版本

4. 点击 **提交** 创建项目

### 8. 配置反向代理（可选）

如果需要通过域名访问：

1. 进入 **网站** -> **添加站点**
2. 填写域名信息
3. 进入站点设置 -> **反向代理**
4. 添加反向代理：
   - **代理名称**：forex-notifier
   - **目标URL**：http://127.0.0.1:3000
   - **发送域名**：$host

### 9. 配置定时任务

**方法一：使用宝塔计划任务**

1. 进入 **计划任务**
2. 点击 **添加任务**
3. 填写任务信息：
   - **任务类型**：Shell脚本
   - **任务名称**：外汇汇率推送
   - **执行周期**：N小时（5小时）
   - **脚本内容**：
   ```bash
   cd /www/wwwroot/forex-notifier && node cron.js
   ```

**方法二：使用PM2管理（推荐）**

1. 安装PM2：
```bash
npm install -g pm2
```

2. 启动服务：
```bash
cd /www/wwwroot/forex-notifier
pm2 start ecosystem.config.js --env production
```

3. 保存PM2配置：
```bash
pm2 save
pm2 startup
```

### 10. 配置防火墙

1. 进入 **安全** -> **防火墙**
2. 添加端口规则：
   - **端口**：3000
   - **协议**：TCP
   - **策略**：允许

### 11. 配置SSL证书（可选）

如果使用域名访问：

1. 进入网站设置 -> **SSL**
2. 选择证书类型（Let's Encrypt免费证书或上传证书）
3. 部署证书

## 监控和维护

### 查看服务状态

1. **通过宝塔Node.js管理器**：
   - 查看项目运行状态
   - 查看日志输出

2. **通过PM2（如果使用）**：
```bash
pm2 status
pm2 logs forex-notifier
```

3. **通过浏览器**：
   - 访问 `/status` 端点查看服务状态

### 日志管理

1. 应用日志位置：`/www/wwwroot/forex-notifier/logs/`
2. 宝塔系统日志：通过面板查看
3. PM2日志：`pm2 logs`

### 服务重启

1. **通过宝塔面板**：
   - Node.js项目管理 -> 重启项目

2. **通过PM2**：
```bash
pm2 restart forex-notifier
```

3. **通过命令行**：
```bash
cd /www/wwwroot/forex-notifier
npm run start
```

## 故障排除

### 常见问题

1. **端口被占用**
   - 检查端口使用情况：`netstat -tlnp | grep 3000`
   - 修改 `.env` 文件中的端口号

2. **依赖安装失败**
   - 检查Node.js版本：`node --version`
   - 清除npm缓存：`npm cache clean --force`
   - 重新安装：`rm -rf node_modules && npm install`

3. **推送失败**
   - 检查Webhook URL配置
   - 验证网络连接
   - 查看错误日志

4. **定时任务不执行**
   - 检查cron任务配置
   - 验证脚本路径
   - 查看任务执行日志

### 性能优化

1. **启用Gzip压缩**
2. **配置CDN加速**
3. **优化服务器配置**
4. **监控资源使用情况**

## 安全建议

1. **定期更新依赖包**
2. **配置访问限制**
3. **启用HTTPS**
4. **定期备份配置**
5. **监控异常访问**

## 备份和恢复

### 备份

1. **项目文件备份**：
```bash
tar -czf forex-notifier-backup-$(date +%Y%m%d).tar.gz /www/wwwroot/forex-notifier
```

2. **数据库备份**（如果使用）：
   - 通过宝塔数据库管理导出

### 恢复

1. **恢复项目文件**：
```bash
tar -xzf forex-notifier-backup-YYYYMMDD.tar.gz -C /
```

2. **重新安装依赖**：
```bash
cd /www/wwwroot/forex-notifier
npm install
```

3. **重启服务**

通过以上步骤，您就可以在宝塔面板中成功部署外汇汇率推送服务了。
