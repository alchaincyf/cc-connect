#!/usr/bin/env node
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const commander_1 = require("commander");
const session_1 = require("./session");
const package_json_1 = require("../package.json");
const program = new commander_1.Command();
program
    .name('cc')
    .description('CC Connect - Claude Code 移动控制台')
    .version(package_json_1.version);
program
    .command('start')
    .description('启动 Claude Code 并生成配对二维码')
    .option('-n, --name <name>', '会话名称', '新会话')
    .option('-s, --server <url>', '中继服务器地址', 'wss://cc-connect.alchaincyf.workers.dev')
    .action(async (options) => {
    try {
        await (0, session_1.startSession)(options);
    }
    catch (error) {
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
//# sourceMappingURL=index.js.map