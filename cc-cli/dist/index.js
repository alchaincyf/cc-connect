#!/usr/bin/env node
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const commander_1 = require("commander");
const session_1 = require("./session");
const hooks_1 = require("./hooks");
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
    .command('install-hooks')
    .description('安装 Claude Code Hooks 配置（推荐）')
    .option('--show', '仅显示配置，不安装')
    .action(async (options) => {
    try {
        if (options.show) {
            console.log('\nClaude Code Hooks 配置:\n');
            console.log(JSON.stringify((0, hooks_1.generateHooksConfig)(), null, 2));
            return;
        }
        const isInstalled = (0, hooks_1.checkHooksInstalled)();
        if (isInstalled) {
            console.log('\nHooks 配置已存在。');
            console.log('如需重新安装，请先手动编辑 ~/.claude/settings.json 移除 hooks 配置。\n');
            return;
        }
        await (0, hooks_1.installHooksConfig)();
        console.log('\n✓ Hooks 配置安装成功！');
        console.log('\n现在可以运行 `cc start` 启动会话。');
        console.log('Claude Code 的事件将自动同步到手机端。\n');
    }
    catch (error) {
        console.error('安装失败:', error);
        process.exit(1);
    }
});
program
    .command('check-hooks')
    .description('检查 Hooks 配置状态')
    .action(() => {
    const isInstalled = (0, hooks_1.checkHooksInstalled)();
    if (isInstalled) {
        console.log('\n✓ Claude Code Hooks 已配置\n');
    }
    else {
        console.log('\n✗ Claude Code Hooks 未配置');
        console.log('运行 `cc install-hooks` 安装配置\n');
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