#!/usr/bin/env node

const { executePushTask } = require('./server');

// 执行推送任务
async function main() {
  console.log('定时任务开始执行:', new Date().toISOString());
  
  try {
    const result = await executePushTask();
    if (result.success) {
      console.log('定时任务执行成功');
      process.exit(0);
    } else {
      console.error('定时任务执行失败:', result.error);
      process.exit(1);
    }
  } catch (error) {
    console.error('定时任务异常:', error);
    process.exit(1);
  }
}

main();
