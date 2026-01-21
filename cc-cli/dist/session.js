"use strict";
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
const parser_1 = require("./parser");
const state = {
    id: (0, nanoid_1.nanoid)(16),
    secret: (0, nanoid_1.nanoid)(32),
    name: '新会话',
    shell: null,
    wsClient: null,
};
// ============================================================================
// 输出缓冲系统 - 解决流式输出拆分问题
// ============================================================================
// 原始输出缓冲
let rawOutputBuffer = '';
let flushTimer = null;
const FLUSH_DELAY = 300; // 等待 300ms 输出稳定后再处理
// 消息去重
const recentMessages = new Set();
const MAX_RECENT_MESSAGES = 30;
function getMessageKey(msg) {
    // 只用内容的前 100 字符做去重
    return `${msg.type}:${msg.content.substring(0, 100)}`;
}
function isDuplicateMessage(msg) {
    const key = getMessageKey(msg);
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
async function startSession(options) {
    state.name = options.name;
    console.log('\n🚀 CC Connect - 远程终端控制\n');
    console.log('━'.repeat(50));
    // 1. 先启动 PTY shell
    console.log('\n📟 正在启动终端 (PTY)...');
    try {
        startShell();
        console.log('✅ 终端已就绪\n');
    }
    catch (error) {
        console.error('❌ 终端启动失败:', error.message);
        return;
    }
    // 2. 连接到中继服务器
    console.log('📡 正在连接到中继服务器...');
    try {
        state.wsClient = new websocket_1.WebSocketClient(options.server, state.id, state.secret);
        await state.wsClient.connect();
        console.log('✅ 服务器连接成功\n');
    }
    catch (error) {
        console.log('⚠️  无法连接到中继服务器\n');
        console.error(error);
        return;
    }
    // 3. 显示配对二维码
    displayQRCode();
    // 4. 设置消息处理
    state.wsClient.onMessage((msg) => {
        handleRemoteMessage(msg);
    });
    state.wsClient.onDisconnect(() => {
        console.log('\n⚠️  与服务器的连接已断开');
    });
    console.log('\n⏳ 请用手机扫描二维码连接...\n');
    // 处理退出
    process.on('SIGINT', cleanup);
    process.on('SIGTERM', cleanup);
}
function startShell() {
    const shell = process.env.SHELL || '/bin/zsh';
    // 使用 node-pty 创建真正的 PTY
    state.shell = pty.spawn(shell, [], {
        name: 'xterm-256color',
        cols: process.stdout.columns || 80,
        rows: process.stdout.rows || 24,
        cwd: process.cwd(),
        env: process.env,
    });
    // Shell 输出 -> 本地显示 + 发送到手机
    state.shell.onData((data) => {
        process.stdout.write(data);
        sendOutput(data);
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
    state.shell.onExit(({ exitCode }) => {
        console.log(`\n终端已退出 (code: ${exitCode})`);
        cleanup();
    });
}
function displayQRCode() {
    const pairingCode = `cc://${state.id}:${state.secret}`;
    console.log('📱 扫描下方二维码连接手机 App:\n');
    qrcode_terminal_1.default.generate(pairingCode, { small: true }, (code) => {
        console.log(code);
    });
    console.log(`\n💡 或手动输入配对码: ${pairingCode}\n`);
    console.log('━'.repeat(50));
}
function handleRemoteMessage(msg) {
    switch (msg.type) {
        case 'input':
            // 来自手机的输入 -> 直接写入 PTY
            if (msg.text && state.shell) {
                // Claude Code: Enter=发送, Shift+Enter=换行
                const text = msg.text.trim();
                if (text) {
                    // 先写入文字，稍后发送 Enter
                    state.shell.write(text);
                    setTimeout(() => {
                        state.shell?.write('\r'); // Enter 键发送
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
            console.log('\n✅ 手机已连接！现在可以通过手机控制此终端。\n');
            console.log('💡 提示: 手机发送 "claude" 可启动 Claude Code\n');
            break;
        default:
            // 忽略未知消息
            break;
    }
}
// 完整移除所有终端控制序列和特殊字符
function stripTerminalSequences(str) {
    let result = str;
    // 1. OSC (Operating System Command) 序列: ESC ] ... (BEL 或 ST)
    //    包括窗口标题、超链接等: \x1b]0;...\x07 或 \x1b]...\x1b\\
    result = result.replace(/\x1b\][\x00-\x06\x08-\x1a\x1c-\xff]*(?:\x07|\x1b\\)/g, '');
    // 更宽松的 OSC 匹配（处理不完整的序列）
    result = result.replace(/\x1b\][^\x07\x1b]*(?:\x07|\x1b\\)?/g, '');
    // 处理 ]0; 等残留（有时 ESC 被吞掉）
    result = result.replace(/\][0-9];[^\x07\x1b\n]*/g, '');
    // 2. CSI (Control Sequence Introducer) 序列: ESC [ ... 或 0x9B ...
    //    包括颜色、光标移动、清屏等
    result = result.replace(/\x1b\[[0-9;?]*[A-Za-z]/g, '');
    result = result.replace(/\x9b[0-9;?]*[A-Za-z]/g, '');
    // 3. DCS (Device Control String): ESC P ... ST
    result = result.replace(/\x1bP[^\x1b]*\x1b\\/g, '');
    // 4. 其他 ESC 序列
    result = result.replace(/\x1b[NOPXZcn^_\[\]()#%*+\-./][^\x1b]*/g, '');
    // 简单的 ESC 后跟单字符
    result = result.replace(/\x1b[=>78MDEFH]/g, '');
    // 任何残留的 ESC 序列
    result = result.replace(/\x1b[^m\n]*/g, '');
    // 5. 控制字符 (保留换行、回车、制表符)
    result = result.replace(/[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]/g, '');
    // 6. 方框绘制字符转换为简单字符
    const boxDrawingMap = {
        '━': '-', '─': '-', '│': '|', '┃': '|',
        '┌': '+', '┐': '+', '└': '+', '┘': '+',
        '├': '+', '┤': '+', '┬': '+', '┴': '+', '┼': '+',
        '╔': '+', '╗': '+', '╚': '+', '╝': '+',
        '╠': '+', '╣': '+', '╦': '+', '╩': '+', '╬': '+',
        '═': '=', '║': '|',
        '▀': ' ', '▄': ' ', '█': '#', '▌': '|', '▐': '|',
        '░': '.', '▒': '#', '▓': '#',
        '●': '*', '○': 'o', '◆': '*', '◇': 'o',
        '■': '#', '□': '[]', '▪': '*', '▫': '-',
        '►': '>', '◄': '<', '▲': '^', '▼': 'v',
        '★': '*', '☆': '*',
        '·': '.', '•': '*', '‣': '>',
        '…': '...', '—': '-', '–': '-',
    };
    for (const [char, replacement] of Object.entries(boxDrawingMap)) {
        result = result.split(char).join(replacement);
    }
    // 7. 清理多余的连续横线/空行
    result = result.replace(/[-=]{10,}/g, '----------');
    result = result.replace(/\n{3,}/g, '\n\n');
    return result;
}
/**
 * 累积输出到缓冲区，延迟处理
 * 解决流式输出导致消息被拆分的问题
 */
function sendOutput(data) {
    if (!state.wsClient?.isConnected)
        return;
    // 累积到缓冲区
    rawOutputBuffer += data;
    // 重置定时器 - 每次有新数据就重新等待
    if (flushTimer) {
        clearTimeout(flushTimer);
    }
    // 检查是否有明确的结束标志（提示符），立即处理
    const hasPrompt = /❯\s*$/.test(rawOutputBuffer) || /^❯/m.test(rawOutputBuffer);
    const delay = hasPrompt ? 50 : FLUSH_DELAY;
    flushTimer = setTimeout(() => {
        flushOutputBuffer();
    }, delay);
}
// 值得发送到手机的消息类型
// 注意：不包含 user_input，因为 iOS 端已经本地显示了用户输入
const SENDABLE_TYPES = new Set([
    'claude', // Claude 的回复
    // 'user_input',    // 不发送 - iOS 已本地显示
    'tool_call', // 工具调用
    'tool_result', // 工具结果
    'tool_error', // 工具错误
    'question', // 需要回答的问题
    'permission_request', // 权限请求
    'selection_dialog', // 选择对话
    'confirmation', // 确认对话
    'error', // 错误
]);
// 状态类消息（只更新状态，不添加到消息列表）
const STATUS_TYPES = new Set([
    'thinking',
    'status_bar',
    'task_status',
]);
/**
 * 处理缓冲区内容
 */
function flushOutputBuffer() {
    if (!rawOutputBuffer || !state.wsClient?.isConnected)
        return;
    const bufferToProcess = rawOutputBuffer;
    rawOutputBuffer = '';
    flushTimer = null;
    // 重置 parser 状态，用完整的缓冲区内容解析
    (0, parser_1.resetParser)();
    const messages = (0, parser_1.parseOutput)(bufferToProcess);
    const flushed = (0, parser_1.flushBuffer)();
    const allMessages = [...messages, ...flushed];
    if (allMessages.length === 0)
        return;
    // 过滤和分类消息
    const messagesToSend = [];
    let latestStatus = null;
    for (const msg of allMessages) {
        // 过滤噪音：内容太短或主要是特殊字符
        if (msg.content.length < 5)
            continue;
        if (/^[\s·•✻✽✶✳✢…↵]+$/.test(msg.content))
            continue;
        // 过滤残缺的思考状态
        if (/thinking\)?|thought for/i.test(msg.content) && msg.content.length < 30)
            continue;
        if (SENDABLE_TYPES.has(msg.type)) {
            messagesToSend.push(msg);
        }
        else if (STATUS_TYPES.has(msg.type)) {
            latestStatus = msg; // 只保留最新的状态
        }
        // raw 类型：只有内容有意义才发送
        else if (msg.type === 'raw') {
            // 过滤明显的噪音
            if (/^[a-z]{2,4}↵/i.test(msg.content))
                continue; // 如 "tin↵", "dul↵"
            if (/·\s*thinking/i.test(msg.content))
                continue;
            if (msg.content.length > 20) {
                messagesToSend.push(msg);
            }
        }
    }
    // 调试日志
    if (messagesToSend.length > 0 || latestStatus) {
        console.log(`\n[DEBUG] 处理结果: ${messagesToSend.length} 条消息, 状态: ${latestStatus?.type || '无'}`);
        for (const m of messagesToSend) {
            const preview = m.content.replace(/\n/g, '↵').substring(0, 80);
            console.log(`  [${m.type}] ${preview}...`);
        }
    }
    // 发送状态更新（如果有）
    if (latestStatus) {
        state.wsClient.send({
            type: 'status',
            status: latestStatus.type,
            content: latestStatus.content,
        });
    }
    // 发送消息（去重）
    for (const msg of messagesToSend) {
        if (isDuplicateMessage(msg)) {
            console.log(`[DEBUG] 跳过重复: [${msg.type}]`);
            continue;
        }
        state.wsClient.send({
            type: 'message',
            message: msg,
        });
    }
}
function cleanup() {
    console.log('\n正在清理...');
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