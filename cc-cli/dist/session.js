"use strict";
/**
 * 会话管理模块
 *
 * 新架构：基于 Claude Code Hooks 获取状态
 * - Hook 事件提供结构化的状态信息
 * - PTY 输出仅用于终端显示
 * - 更准确的权限请求和完成状态检测
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.startSession = startSession;
const pty = __importStar(require("node-pty"));
const nanoid_1 = require("nanoid");
const qrcode_terminal_1 = __importDefault(require("qrcode-terminal"));
const websocket_1 = require("./websocket");
const hooks_1 = require("./hooks");
const path = __importStar(require("path"));
// Hook 服务器是否成功运行（用于决定是否启用备用模式）
let hookServerRunning = false;
// 获取当前工作目录名作为默认会话名称
function getDefaultSessionName() {
    const cwd = process.cwd();
    const dirName = path.basename(cwd);
    if (!dirName || dirName === '/' || dirName === process.env.USER) {
        return 'Terminal';
    }
    return dirName;
}
const state = {
    id: (0, nanoid_1.nanoid)(16),
    secret: (0, nanoid_1.nanoid)(32),
    name: getDefaultSessionName(),
    shell: null,
    wsClient: null,
};
// ============================================================================
// 消息去重
// ============================================================================
const recentMessages = new Set();
const MAX_RECENT_MESSAGES = 50;
function getMessageKey(content, type) {
    return `${type}:${content.substring(0, 100)}`;
}
function isDuplicate(content, type) {
    const key = getMessageKey(content, type);
    if (recentMessages.has(key)) {
        return true;
    }
    recentMessages.add(key);
    if (recentMessages.size > MAX_RECENT_MESSAGES) {
        const first = recentMessages.values().next().value;
        if (first)
            recentMessages.delete(first);
    }
    return false;
}
// ============================================================================
// 会话启动
// ============================================================================
async function startSession(options) {
    state.name = options.name;
    // 检查 Hooks 是否已配置
    const hooksInstalled = (0, hooks_1.checkHooksInstalled)();
    if (!hooksInstalled) {
        console.log('\n[提示] Claude Code Hooks 未配置。');
        console.log('运行以下命令安装 Hooks 配置以获得最佳体验:');
        console.log('  huashu-cc install-hooks\n');
    }
    // 1. 启动 Hook 服务器
    try {
        await (0, hooks_1.startHookServer)(handleHookEvent);
        hookServerRunning = true;
    }
    catch (err) {
        hookServerRunning = false;
        // Hook 服务器启动失败时静默使用备用模式
    }
    // 2. 启动 PTY shell
    try {
        startShell();
    }
    catch (error) {
        console.error('终端启动失败:', error.message);
        (0, hooks_1.stopHookServer)();
        return;
    }
    // 3. 连接到中继服务器
    try {
        state.wsClient = new websocket_1.WebSocketClient(options.server, state.id, state.secret);
        await state.wsClient.connect();
    }
    catch (error) {
        console.error('无法连接到中继服务器');
        (0, hooks_1.stopHookServer)();
        return;
    }
    // 4. 显示配对二维码
    displayQRCode();
    // 5. 设置消息处理
    state.wsClient.onMessage((msg) => {
        handleRemoteMessage(msg);
    });
    state.wsClient.onDisconnect(() => {
        // 静默处理断开
    });
    // 处理退出
    process.on('SIGINT', cleanup);
    process.on('SIGTERM', cleanup);
}
// ============================================================================
// PTY Shell - 仅用于终端显示和输入
// ============================================================================
function startShell() {
    const shell = process.env.SHELL || '/bin/zsh';
    state.shell = pty.spawn(shell, [], {
        name: 'xterm-256color',
        cols: process.stdout.columns || 80,
        rows: process.stdout.rows || 24,
        cwd: process.cwd(),
        env: process.env,
    });
    // Shell 输出 -> 本地终端显示（不再用于解析）
    state.shell.onData((data) => {
        process.stdout.write(data);
        // 备用模式：如果 Hook 服务器未启动，使用简单的状态检测
        fallbackStateDetection(data);
    });
    // 本地键盘输入 -> Shell
    if (process.stdin.isTTY) {
        process.stdin.setRawMode(true);
    }
    process.stdin.resume();
    process.stdin.on('data', (data) => {
        state.shell?.write(data.toString());
    });
    // 窗口大小变化
    process.stdout.on('resize', () => {
        state.shell?.resize(process.stdout.columns || 80, process.stdout.rows || 24);
    });
    // Shell 退出
    state.shell.onExit(() => {
        cleanup();
    });
}
// ============================================================================
// 备用状态检测 - 仅当 Hooks 未运行时使用
// ============================================================================
let outputBuffer = '';
let bufferTimer = null;
// 最近发送的用户输入，用于过滤 PTY 回显
const recentUserInputs = new Set();
const MAX_RECENT_INPUTS = 10;
// 思考状态关键词（这些不应该作为消息发送）
const THINKING_KEYWORDS = [
    'Composing', 'Thinking', 'Pondering', 'Processing',
    'Finagling', 'Schlepping', 'Brewing', 'Levitating',
    'Analyzing', 'Writing', 'Reading', 'Editing',
    'Moseying', 'Percolating', 'Ruminating', 'Cogitating',
    'Noodling', 'Contemplating', 'Deliberating', 'Mulling'
];
function fallbackStateDetection(data) {
    // 如果 Hook 服务器已运行，不使用备用模式
    if (hookServerRunning)
        return;
    if (!state.wsClient?.isConnected)
        return;
    // 累积输出
    outputBuffer += data;
    // 重置定时器
    if (bufferTimer) {
        clearTimeout(bufferTimer);
    }
    // 简单的提示符检测
    const hasPrompt = /❯\s*$/.test(outputBuffer);
    if (hasPrompt) {
        bufferTimer = setTimeout(() => {
            processFallbackOutput();
        }, 100);
    }
    else {
        bufferTimer = setTimeout(() => {
            processFallbackOutput();
        }, 500);
    }
}
function processFallbackOutput() {
    if (!outputBuffer)
        return;
    const buffer = outputBuffer;
    outputBuffer = '';
    bufferTimer = null;
    const cleaned = stripAnsiCodes(buffer);
    // 过滤掉只包含思考状态关键词的输出
    const isThinkingOnly = THINKING_KEYWORDS.some(keyword => {
        const regex = new RegExp(`^[\\s\\*\\+]*${keyword}\\.{0,3}\\s*$`, 'i');
        return regex.test(cleaned.trim());
    });
    if (isThinkingOnly) {
        // 只发送状态更新，不发送消息
        return;
    }
    // 检测 Claude 消息（⏺ 开头）
    const claudeMatch = cleaned.match(/⏺\s+(.+?)(?=\n❯|\n⏺|$)/s);
    if (claudeMatch) {
        const content = claudeMatch[1].trim();
        if (content.length > 20 && !isDuplicate(content, 'claude')) {
            // 过滤工具调用
            if (!/^\w+\(/.test(content)) {
                // 过滤思考状态词汇
                const startsWithThinking = THINKING_KEYWORDS.some(keyword => content.toLowerCase().startsWith(keyword.toLowerCase()));
                if (!startsWithThinking) {
                    sendToPhone({
                        type: 'claude',
                        content,
                        timestamp: Date.now(),
                    });
                }
            }
        }
    }
}
// ============================================================================
// Hook 事件处理 - 主要的状态获取方式
// ============================================================================
function handleHookEvent(event) {
    if (!state.wsClient?.isConnected)
        return;
    // 发送状态更新
    if (event.status) {
        state.wsClient.send({
            type: 'status',
            status: event.status.type,
            content: event.status.message || '',
        });
    }
    // 发送消息
    if (event.message) {
        const msg = event.message;
        // 去重检查
        if (isDuplicate(msg.content, msg.type)) {
            return;
        }
        const parsedMessage = {
            type: msg.type,
            content: msg.content,
            timestamp: event.timestamp,
            requiresResponse: msg.requiresResponse,
            options: msg.options,
            tool: msg.tool,
        };
        state.wsClient.send({
            type: 'message',
            message: parsedMessage,
        });
    }
}
// ============================================================================
// 远程消息处理
// ============================================================================
function handleRemoteMessage(msg) {
    switch (msg.type) {
        case 'input':
            // 来自手机的输入 -> 直接写入 PTY
            if (msg.text && state.shell) {
                const text = msg.text.trim();
                if (text) {
                    state.shell.write(text);
                    setTimeout(() => {
                        state.shell?.write('\r');
                    }, 50);
                }
            }
            break;
        case 'interrupt':
            // 中断信号 (Ctrl+C)
            state.shell?.write('\x03');
            break;
        case 'resize':
            // 调整终端大小
            if (msg.cols && msg.rows) {
                state.shell?.resize(msg.cols, msg.rows);
            }
            break;
        case 'ping':
            state.wsClient?.send({ type: 'pong' });
            break;
        case 'paired':
            // 手机已连接
            console.log('\n[已连接] 手机客户端已配对\n');
            break;
        default:
            break;
    }
}
// ============================================================================
// UI 显示
// ============================================================================
function displayQRCode() {
    const encodedName = encodeURIComponent(state.name);
    const pairingCode = `cc://${state.id}:${state.secret}:${encodedName}`;
    console.log('\n用手机扫描二维码连接:\n');
    qrcode_terminal_1.default.generate(pairingCode, { small: true }, (code) => {
        console.log(code);
    });
    console.log(`\n会话: ${state.name}\n`);
}
// ============================================================================
// 工具函数
// ============================================================================
function sendToPhone(message) {
    state.wsClient?.send({
        type: 'message',
        message,
    });
}
function stripAnsiCodes(str) {
    return str
        .replace(/\x1b\][^\x07\x1b]*(?:\x07|\x1b\\)?/g, '')
        .replace(/\x1b\[[0-9;?]*[A-Za-z]/g, '')
        .replace(/\x1b[^m\n]*m?/g, '')
        .replace(/[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]/g, '');
}
function cleanup() {
    hookServerRunning = false;
    (0, hooks_1.stopHookServer)();
    if (state.shell) {
        state.shell.kill();
        state.shell = null;
    }
    if (state.wsClient) {
        state.wsClient.close();
        state.wsClient = null;
    }
    process.exit(0);
}
//# sourceMappingURL=session.js.map