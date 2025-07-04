const http = require('http');
const url = require('url');
require('dotenv').config();

// 配置常量
const PORT = process.env.PORT || 3000;
const WECHAT_WEBHOOK_URL = process.env.WECHAT_WEBHOOK_URL || 'YOUR_WECHAT_WEBHOOK_URL';
const DINGTALK_WEBHOOK_URL = process.env.DINGTALK_WEBHOOK_URL || 'YOUR_DINGTALK_WEBHOOK_URL';
const FEISHU_WEBHOOK_URL = process.env.FEISHU_WEBHOOK_URL || 'YOUR_FEISHU_WEBHOOK_URL';

// 获取汇率数据
async function getRates() {
  try {
    const response = await fetch('https://www.boc.cn/sourcedb/whpj/');
    const html = await response.text();
    
    const result = {};
    const currencies = ['美元', '港币', '英镑', '欧元'];
    
    const regex = /<td>(.*?)<\/td>/g;
    let match;
    let currentCurrency = null;
    let count = 0;

    while ((match = regex.exec(html)) !== null) {
      const value = match[1].trim();
      if (currencies.includes(value)) {
        currentCurrency = value;
        count = 0;
        result[currentCurrency] = {};
      } else if (currentCurrency) {
        count++;
        if (count === 1) result[currentCurrency].buyRate = value;
        if (count === 3) result[currentCurrency].sellRate = value;
      }
    }
    
    return result;
  } catch (error) {
    console.error('获取汇率数据失败:', error);
    return {};
  }
}

// 获取香港时间
function getHongKongTime() {
  return new Date().toLocaleString('zh-HK', {
    timeZone: 'Asia/Hong_Kong',
    hour12: false,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit'
  });
}

// 格式化Markdown消息
function formatMarkdownMessage(rates) {
  const timeStr = getHongKongTime();
  const nextUpdateTime = new Date(Date.now() + 5 * 60 * 60 * 1000);
  const nextUpdateStr = nextUpdateTime.toLocaleString('zh-HK', { timeZone: 'Asia/Hong_Kong' });
  
  let message = `# 💱 外汇汇率更新\n\n`;
  message += `**更新时间**: ${timeStr} (香港时间)\n\n`;
  
  const currencyEmojis = {
    '美元': '🇺🇸',
    '英镑': '🇬🇧', 
    '欧元': '🇪🇺',
    '港币': '🇭🇰'
  };
  
  ['美元', '英镑', '欧元', '港币'].forEach(currency => {
    const emoji = currencyEmojis[currency] || '💰';
    if (rates[currency]) {
      message += `## ${emoji} ${currency}兑人民币\n`;
      message += `- **买入价**: ${rates[currency].buyRate || '无数据'} CNY\n`;
      message += `- **卖出价**: ${rates[currency].sellRate || '无数据'} CNY\n`;
      message += `- **单位**: 每100${currency}\n\n`;
    } else {
      message += `## ${emoji} ${currency}兑人民币\n`;
      message += `- ❌ 暂无数据\n\n`;
    }
  });
  
  message += `---\n`;
  message += `📅 **下次更新时间**: ${nextUpdateStr} (香港时间)\n`;
  message += `⏰ **更新频率**: 每5小时自动推送`;
  
  return message;
}

// 企业微信推送函数
async function sendToWechat(message) {
  if (!WECHAT_WEBHOOK_URL || WECHAT_WEBHOOK_URL === 'YOUR_WECHAT_WEBHOOK_URL') {
    console.log('企业微信 Webhook URL 未配置，跳过推送');
    return;
  }
  
  try {
    const response = await fetch(WECHAT_WEBHOOK_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        msgtype: 'markdown',
        markdown: {
          content: message
        }
      }),
    });
    
    if (!response.ok) {
      throw new Error(`企业微信推送失败: ${response.status}`);
    }
    console.log('企业微信推送成功');
  } catch (error) {
    console.error('企业微信推送错误:', error);
  }
}

// 钉钉推送函数
async function sendToDingtalk(message) {
  if (!DINGTALK_WEBHOOK_URL || DINGTALK_WEBHOOK_URL === 'YOUR_DINGTALK_WEBHOOK_URL') {
    console.log('钉钉 Webhook URL 未配置，跳过推送');
    return;
  }
  
  try {
    const response = await fetch(DINGTALK_WEBHOOK_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        msgtype: 'markdown',
        markdown: {
          title: '外汇汇率更新',
          text: message
        }
      }),
    });
    
    if (!response.ok) {
      throw new Error(`钉钉推送失败: ${response.status}`);
    }
    console.log('钉钉推送成功');
  } catch (error) {
    console.error('钉钉推送错误:', error);
  }
}

// 飞书推送函数
async function sendToFeishu(message) {
  if (!FEISHU_WEBHOOK_URL || FEISHU_WEBHOOK_URL === 'YOUR_FEISHU_WEBHOOK_URL') {
    console.log('飞书 Webhook URL 未配置，跳过推送');
    return;
  }
  
  try {
    const response = await fetch(FEISHU_WEBHOOK_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        msg_type: 'interactive',
        card: {
          elements: [
            {
              tag: 'markdown',
              content: message
            }
          ],
          header: {
            title: {
              content: '💱 外汇汇率更新',
              tag: 'plain_text'
            }
          }
        }
      }),
    });
    
    if (!response.ok) {
      throw new Error(`飞书推送失败: ${response.status}`);
    }
    console.log('飞书推送成功');
  } catch (error) {
    console.error('飞书推送错误:', error);
  }
}

// 执行推送任务
async function executePushTask() {
  try {
    console.log('开始执行汇率推送任务...');
    const rates = await getRates();
    const message = formatMarkdownMessage(rates);
    
    // 同时推送到企业微信、钉钉、飞书
    await Promise.all([
      sendToWechat(message),
      sendToDingtalk(message),
      sendToFeishu(message)
    ]);
    
    console.log('汇率推送任务完成');
    return { success: true, message: '推送成功' };
  } catch (error) {
    console.error('推送任务执行失败:', error);
    return { success: false, error: error.message };
  }
}

// 创建HTTP服务器
const server = http.createServer(async (req, res) => {
  const parsedUrl = url.parse(req.url, true);
  const path = parsedUrl.pathname;
  
  // 设置CORS头
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  
  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }
  
  if (path === '/') {
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    res.end(`
      <h1>外汇汇率推送服务</h1>
      <p>服务运行正常</p>
      <p><a href="/cron">手动触发推送</a></p>
      <p><a href="/status">查看状态</a></p>
    `);
  } else if (path === '/cron') {
    const result = await executePushTask();
    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
    res.end(JSON.stringify(result));
  } else if (path === '/status') {
    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
    res.end(JSON.stringify({
      status: 'running',
      time: new Date().toISOString(),
      config: {
        wechat: WECHAT_WEBHOOK_URL !== 'YOUR_WECHAT_WEBHOOK_URL',
        dingtalk: DINGTALK_WEBHOOK_URL !== 'YOUR_DINGTALK_WEBHOOK_URL',
        feishu: FEISHU_WEBHOOK_URL !== 'YOUR_FEISHU_WEBHOOK_URL'
      }
    }));
  } else {
    res.writeHead(404, { 'Content-Type': 'text/plain' });
    res.end('Not Found');
  }
});

server.listen(PORT, () => {
  console.log(`外汇汇率推送服务启动成功，端口: ${PORT}`);
  console.log(`访问 http://localhost:${PORT} 查看服务状态`);
  console.log(`访问 http://localhost:${PORT}/cron 手动触发推送`);
});

// 优雅关闭
process.on('SIGTERM', () => {
  console.log('收到SIGTERM信号，正在关闭服务器...');
  server.close(() => {
    console.log('服务器已关闭');
    process.exit(0);
  });
});

module.exports = { executePushTask };
