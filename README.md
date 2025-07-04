# 外汇汇率推送服务

[![CI/CD Pipeline](https://github.com/logdns/allex/actions/workflows/ci.yml/badge.svg)](https://github.com/logdns/allex/actions/workflows/ci.yml)
[![GitHub release](https://img.shields.io/github/release/logdns/allex.svg)](https://github.com/logdns/allex/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Node.js Version](https://img.shields.io/badge/node-%3E%3D16.0.0-brightgreen.svg)](https://nodejs.org/)

这是一个自动获取外汇汇率并推送到企业微信、钉钉、飞书的服务。每5小时自动推送美元、英镑、欧元、港币兑人民币的汇率信息。

## 功能特点

- 🔄 每5小时自动推送汇率更新
- 💱 支持美元、英镑、欧元、港币兑人民币汇率
- 📱 同时推送到企业微信、钉钉、飞书
- 📝 使用Markdown格式美化显示
- 🕐 显示香港时间和下次更新时间
- 🐳 支持Docker部署
- 🔧 支持多种部署方式（宝塔面板、PM2、Node.js等）

## 快速开始

### 1. 克隆项目
```bash
git clone <your-repo-url>
cd forex-notifier
```

### 2. 安装依赖
```bash
npm install
```

### 3. 配置环境变量
```bash
cp .env.example .env
# 编辑 .env 文件，填入实际的Webhook URL
```

### 4. 启动服务
```bash
npm start
```

### 5. 测试推送
访问 `http://localhost:3000/cron` 或运行：
```bash
npm run test
```

## 部署方式

本项目支持多种部署方式：

- 📋 [宝塔面板部署](./BAOTA_DEPLOYMENT.md) - 宝塔面板用户推荐
- 🐳 [Docker部署](./DEPLOYMENT.md#docker部署) - 容器化部署
- 🚀 [PM2部署](./DEPLOYMENT.md#pm2部署) - 生产环境推荐
- 📦 [完整部署指南](./DEPLOYMENT.md) - 查看所有部署方式

## 配置说明

### 环境变量配置

在 `.env` 文件中配置以下变量：

```bash
# 服务端口
PORT=3000

# 企业微信机器人 Webhook URL
WECHAT_WEBHOOK_URL=https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=YOUR_KEY

# 钉钉机器人 Webhook URL
DINGTALK_WEBHOOK_URL=https://oapi.dingtalk.com/robot/send?access_token=YOUR_TOKEN

# 飞书机器人 Webhook URL
FEISHU_WEBHOOK_URL=https://open.feishu.cn/open-apis/bot/v2/hook/YOUR_TOKEN
```

### 机器人配置步骤

#### 1. 企业微信机器人
1. 在企业微信群中添加机器人
2. 选择"自定义机器人"
3. 复制生成的 Webhook URL

#### 2. 钉钉机器人
1. 在钉钉群中添加自定义机器人
2. 设置安全设置（建议选择"自定义关键词"，添加"汇率"）
3. 复制生成的 Webhook URL

#### 3. 飞书机器人
1. 在飞书群中添加自定义机器人
2. 设置机器人名称和描述
3. 复制生成的 Webhook URL

## 可用脚本

```bash
npm start          # 启动服务
npm run dev        # 开发模式启动（使用nodemon）
npm run cron       # 手动执行一次推送
npm test           # 运行测试
npm run pm2:start  # 使用PM2启动
npm run docker:build # 构建Docker镜像
npm run docker:run   # 运行Docker容器
```

## API接口

- `GET /` - 服务状态页面
- `GET /cron` - 手动触发推送
- `GET /status` - 获取服务状态（JSON格式）

## 定时任务配置

项目支持多种定时任务配置方式，详细说明请查看 [部署指南](./DEPLOYMENT.md)。

**快速配置：**
- **crontab**: `0 */5 * * * cd /path/to/project && node cron.js`
- **PM2**: `pm2 start ecosystem.config.js --env production`
- **宝塔面板**: 在计划任务中添加Shell脚本，每5小时执行

## 推送消息格式

推送的消息将以Markdown格式显示，包含：

- 📊 汇率标题和更新时间
- 🇺🇸 美元兑人民币汇率（买入价/卖出价）
- 🇬🇧 英镑兑人民币汇率（买入价/卖出价）
- 🇪🇺 欧元兑人民币汇率（买入价/卖出价）
- 🇭🇰 港币兑人民币汇率（买入价/卖出价）
- ⏰ 下次更新时间

## 数据来源

汇率数据来源于中国银行官网：https://www.boc.cn/sourcedb/whpj/

## 注意事项

1. 所有汇率均以100单位外币兑换人民币显示
2. 如果某个平台的 Webhook URL 未配置，该平台将跳过推送
3. 推送失败不会影响其他平台的推送
4. 建议在测试环境先验证配置是否正确

## 测试

可以通过访问 `https://your-worker-domain.workers.dev/cron` 来手动触发一次推送测试。

## 故障排除

1. 检查 Webhook URL 是否正确配置
2. 确认机器人权限是否足够
3. 查看应用日志输出
4. 验证网络连接是否正常
5. 检查防火墙设置
6. 确认定时任务配置

## 版本发布

### 自动发布

使用提供的发布脚本：

```bash
# Linux/macOS
./release.sh patch   # 补丁版本 (1.0.0 -> 1.0.1)
./release.sh minor   # 次版本 (1.0.0 -> 1.1.0)
./release.sh major   # 主版本 (1.0.0 -> 2.0.0)

# Windows
release.bat patch
release.bat minor
release.bat major
```

### 手动发布

```bash
# 更新版本号
npm version patch

# 提交更改
git add .
git commit -m "chore: release version x.x.x"
git tag -a vx.x.x -m "Release version x.x.x"

# 推送到GitHub
git push origin main
git push origin vx.x.x
```

## 贡献指南

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 支持

- 📖 [项目文档](https://github.com/logdns/allex)
- 🐛 [问题反馈](https://github.com/logdns/allex/issues)
- 💬 [讨论区](https://github.com/logdns/allex/discussions)
- 📧 联系作者：[GitHub @logdns](https://github.com/logdns)

## 更新日志

查看 [CHANGELOG.md](CHANGELOG.md) 了解版本更新历史。

---

⭐ 如果这个项目对您有帮助，请给个Star支持一下！

选择适合您环境的部署方式，推荐使用Docker或PM2进行生产环境部署。
