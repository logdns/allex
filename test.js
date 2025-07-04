const { executePushTask } = require('./server');

async function test() {
  console.log('开始测试外汇汇率推送服务...\n');
  
  // 测试环境变量配置
  console.log('=== 环境变量检查 ===');
  console.log('WECHAT_WEBHOOK_URL:', process.env.WECHAT_WEBHOOK_URL ? '已配置' : '未配置');
  console.log('DINGTALK_WEBHOOK_URL:', process.env.DINGTALK_WEBHOOK_URL ? '已配置' : '未配置');
  console.log('FEISHU_WEBHOOK_URL:', process.env.FEISHU_WEBHOOK_URL ? '已配置' : '未配置');
  console.log('');
  
  // 测试推送功能
  console.log('=== 推送功能测试 ===');
  try {
    const result = await executePushTask();
    if (result.success) {
      console.log('✅ 推送测试成功');
    } else {
      console.log('❌ 推送测试失败:', result.error);
    }
  } catch (error) {
    console.log('❌ 推送测试异常:', error.message);
  }
  
  console.log('\n测试完成');
}

test();
