// 企业微信机器人 Webhook URL
const WECHAT_WEBHOOK_URL = 'YOUR_WECHAT_WEBHOOK_URL';

// 钉钉机器人 Webhook URL
const DINGTALK_WEBHOOK_URL = 'YOUR_DINGTALK_WEBHOOK_URL';

// 飞书机器人 Webhook URL
const FEISHU_WEBHOOK_URL = 'YOUR_FEISHU_WEBHOOK_URL';

async function handleRequest(request) {
  const url = new URL(request.url);
  const path = url.pathname;

  if (path === '/cron') {
    return handleCron();
  } else {
    return new Response('Not Found', { status: 404 });
  }
}

// 专注于定时推送到企业微信、钉钉、飞书

async function handleCron() {
  try {
    const rates = await getRates();
    const message = formatMarkdownMessage(rates);

    // 同时推送到企业微信、钉钉、飞书
    await Promise.all([
      sendToWechat(message),
      sendToDingtalk(message),
      sendToFeishu(message)
    ]);

    return new Response('Cron job completed - sent to all platforms');
  } catch (error) {
    console.error('Error in handleCron:', error);
    return new Response('Error', { status: 500 });
  }
}

async function getRates() {
  const url = 'https://www.boc.cn/sourcedb/whpj/';
  const response = await fetch(url);
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
}

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

// 自动推送服务，无需订阅管理

addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request));
});