#!/usr/bin/env node

import { Command } from 'commander';
import { startSession } from './session';
import { version } from '../package.json';

const program = new Command();

program
  .name('cc')
  .description('CC Connect - Claude Code 移动控制台')
  .version(version);

program
  .command('start')
  .description('启动 Claude Code 并生成配对二维码')
  .option('-n, --name <name>', '会话名称', '新会话')
  .option('-s, --server <url>', '中继服务器地址', 'wss://cc-connect.alchaincyf.workers.dev')
  .action(async (options) => {
    try {
      await startSession(options);
    } catch (error) {
      console.error('启动失败:', error);
      process.exit(1);
    }
  });

program
  .command('status')
  .description('查看当前会话状态')
  .action(() => {
    console.log('功能开发中...');
  });

program.parse();
