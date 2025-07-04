# 项目结构说明

```
forex-notifier/
├── README.md                    # 项目说明文档
├── DEPLOYMENT.md               # 详细部署指南
├── BAOTA_DEPLOYMENT.md         # 宝塔面板专用部署指南
├── PROJECT_STRUCTURE.md        # 项目结构说明（本文件）
├── package.json                # Node.js项目配置
├── .env.example               # 环境变量模板
├── .env                       # 环境变量配置（需要创建）
├── .gitignore                 # Git忽略文件
├── .dockerignore              # Docker忽略文件
│
├── 核心文件/
│   ├── server.js              # Node.js服务器主文件
│   ├── worker.js              # Cloudflare Workers版本
│   ├── cron.js                # 定时任务执行文件
│   └── test.js                # 测试文件
│
├── 部署相关/
│   ├── Dockerfile             # Docker镜像构建文件
│   ├── docker-compose.yml     # Docker Compose配置
│   ├── ecosystem.config.js    # PM2配置文件
│   ├── deploy.sh              # Linux/macOS部署脚本
│   └── deploy.bat             # Windows部署脚本
│
└── 运行时目录/
    └── logs/                  # 日志文件目录（运行时创建）
        ├── combined.log       # 综合日志
        ├── error.log          # 错误日志
        ├── out.log            # 输出日志
        └── cron.log           # 定时任务日志
```

## 文件说明

### 核心文件

#### `server.js`
- Node.js HTTP服务器主文件
- 提供Web接口和推送功能
- 支持手动触发推送和状态查询
- 适用于传统服务器部署

#### `worker.js`
- Cloudflare Workers版本
- 无服务器环境运行
- 仅保留核心推送功能
- 适用于Cloudflare Workers部署

#### `cron.js`
- 独立的定时任务执行文件
- 可通过crontab或计划任务调用
- 执行一次推送后自动退出
- 适用于定时任务场景

#### `test.js`
- 服务测试文件
- 检查环境变量配置
- 测试推送功能
- 验证服务是否正常工作

### 配置文件

#### `package.json`
- Node.js项目配置
- 定义依赖包和脚本命令
- 包含项目元信息

#### `.env.example`
- 环境变量配置模板
- 包含所有必需的配置项
- 需要复制为`.env`并填入实际值

#### `ecosystem.config.js`
- PM2进程管理器配置
- 定义应用启动参数
- 配置日志和重启策略

### 部署文件

#### `Dockerfile`
- Docker镜像构建配置
- 基于Node.js Alpine镜像
- 包含健康检查和安全配置

#### `docker-compose.yml`
- Docker Compose编排配置
- 定义服务和网络配置
- 包含定时任务容器（可选）

#### `deploy.sh` / `deploy.bat`
- 自动化部署脚本
- 支持多种部署方式
- 包含环境检查和配置向导

### 文档文件

#### `README.md`
- 项目主要说明文档
- 快速开始指南
- 基本配置说明

#### `DEPLOYMENT.md`
- 详细的部署指南
- 涵盖所有部署方式
- 包含故障排除指南

#### `BAOTA_DEPLOYMENT.md`
- 宝塔面板专用部署指南
- 详细的步骤说明
- 包含监控和维护指南

## 使用流程

### 1. 初始化项目
```bash
# 克隆项目
git clone <repo-url>
cd forex-notifier

# 安装依赖
npm install

# 配置环境变量
cp .env.example .env
# 编辑 .env 文件
```

### 2. 选择部署方式

#### 快速部署（推荐）
```bash
# Linux/macOS
./deploy.sh nodejs

# Windows
deploy.bat nodejs
```

#### 手动部署
```bash
# 直接启动
npm start

# 使用PM2
npm run pm2:start

# 使用Docker
npm run docker:build
npm run docker:run
```

### 3. 配置定时任务

#### 使用脚本配置
```bash
# Linux/macOS
./deploy.sh cron

# Windows
deploy.bat cron
```

#### 手动配置
```bash
# Linux crontab
0 */5 * * * cd /path/to/forex-notifier && node cron.js

# Windows计划任务
schtasks /create /tn "ForexNotifier" /tr "node cron.js" /sc hourly /mo 5
```

### 4. 监控和维护

#### 查看服务状态
- 访问 `http://localhost:3000/status`
- 使用 `pm2 status`（如果使用PM2）
- 使用 `docker ps`（如果使用Docker）

#### 查看日志
- 应用日志：`logs/` 目录
- PM2日志：`pm2 logs forex-notifier`
- Docker日志：`docker logs forex-notifier`

#### 手动测试
```bash
# 运行测试
npm test

# 手动触发推送
npm run cron
# 或访问 http://localhost:3000/cron
```

## 环境要求

### 基础要求
- Node.js 16.0.0+
- npm 或 yarn
- 网络连接（访问中国银行网站和各平台API）

### 可选要求
- Docker（用于容器化部署）
- PM2（用于进程管理）
- Git（用于版本控制）

## 注意事项

1. **环境变量安全**：不要将包含真实Webhook URL的`.env`文件提交到版本控制
2. **日志管理**：定期清理日志文件，避免占用过多磁盘空间
3. **网络依赖**：确保服务器能够访问中国银行网站和各平台的API
4. **时区设置**：服务使用香港时间，确保服务器时区设置正确
5. **资源监控**：监控服务器资源使用情况，及时处理异常

## 故障排除

### 常见问题
1. **推送失败**：检查Webhook URL配置和网络连接
2. **定时任务不执行**：检查cron配置和脚本权限
3. **服务启动失败**：检查端口占用和依赖安装
4. **数据获取失败**：检查网络连接和数据源可用性

### 调试方法
1. 查看应用日志
2. 运行测试脚本
3. 手动执行推送
4. 检查环境变量配置
