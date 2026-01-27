#!/usr/bin/env node
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const commander_1 = require("commander");
const session_1 = require("./session");
const hooks_1 = require("./hooks");
const package_json_1 = require("../package.json");
const program = new commander_1.Command();
program
    .name('peanut')
    .description('Peanut - Claude Code 移动控制台')
    .version(package_json_1.version);
program
    .command('start')
    .description('启动 Claude Code 并生成配对二维码')
    .option('-n, --name <name>', '会话名称（默认使用当前目录名）')
    .option('-s, --server <url>', '中继服务器地址', 'wss://cc-connect.alchaincyf.workers.dev')
    .option('-p, --port <port>', 'Hook 服务器端口（多会话时使用不同端口）', '19789')
    .action(async (options) => {
    try {
        // 将端口字符串转为数字
        if (options.port) {
            options.port = parseInt(options.port, 10);
        }
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
        console.log('\n现在可以运行 `peanut start` 启动会话。');
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
        console.log('运行 `peanut install-hooks` 安装配置\n');
    }
});
program
    .command('kill')
    .description('清理所有 Peanut 进程和占用的端口')
    .option('-p, --port <port>', '指定要清理的端口', '19789')
    .action((options) => {
    const port = parseInt(options.port, 10);
    try {
        const { execSync } = require('child_process');
        const pidOutput = execSync(`lsof -t -i:${port} 2>/dev/null || true`, { encoding: 'utf-8' }).trim();
        if (pidOutput) {
            const pids = pidOutput.split('\n').filter((p) => p);
            for (const pid of pids) {
                try {
                    execSync(`kill -9 ${pid} 2>/dev/null || true`);
                    console.log(`✓ 已清理进程 PID: ${pid}`);
                }
                catch {
                    console.log(`✗ 无法清理进程 PID: ${pid}`);
                }
            }
            console.log(`\n端口 ${port} 已释放，可以重新启动 peanut start`);
        }
        else {
            console.log(`端口 ${port} 未被占用`);
        }
    }
    catch (error) {
        console.error('清理失败:', error);
        process.exit(1);
    }
});
program
    .command('status')
    .description('查看当前会话状态')
    .action(() => {
    const { execSync } = require('child_process');
    try {
        const pidOutput = execSync(`lsof -i:19789 2>/dev/null || true`, { encoding: 'utf-8' }).trim();
        if (pidOutput) {
            console.log('\n[运行中] Peanut 会话正在端口 19789 上运行\n');
            console.log(pidOutput);
        }
        else {
            console.log('\n[未运行] 没有活动的 Peanut 会话');
            console.log('运行 `peanut start` 启动新会话\n');
        }
    }
    catch {
        console.log('\n[未运行] 没有活动的 Peanut 会话\n');
    }
});
program.parse();
//# sourceMappingURL=index.js.map