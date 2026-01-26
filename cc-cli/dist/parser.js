"use strict";
/**
 * Claude Code 输出解析器 v2
 *
 * 设计原则：
 * 1. 开放性 - 消息类型使用字符串而非枚举，便于扩展
 * 2. 前向兼容 - 未识别的输出以 raw 类型传递，不丢失信息
 * 3. 交互支持 - 支持权限请求、选择对话、确认等交互类型
 * 4. 颜色保留 - 保留 ANSI 颜色信息供客户端渲染
 *
 * Claude Code 输出格式：
 * ⏺ Claude 消息        - Claude 说话
 * ⏺ Read(path)        - 工具调用
 * └ Read 254 lines    - 工具结果
 * └ Error ...         - 工具错误
 * ❯ 用户输入           - 用户输入提示
 * · 任务状态...        - 当前任务
 * ⏵⏵ status bar       - 底部状态栏
 * ? 选择提示           - 权限/选择对话
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.parseOutput = parseOutput;
exports.flushBuffer = flushBuffer;
exports.resetParser = resetParser;
exports.formatUserResponse = formatUserResponse;
// ============================================================================
// 识别模式
// ============================================================================
const PATTERNS = {
    // Claude 消息: ⏺ 或 ● 开头（排除工具调用）
    claudeMessage: /^[⏺●]\s+(?![\w]+\()/,
    // 工具调用: ⏺ ToolName(...) - 更通用的模式，支持任意工具名
    toolCall: /^[⏺●]\s+(\w+)\(([^)]*)\)/,
    // 工具结果: └ 或 │ 或 ├ 开头
    toolResult: /^[└│├]\s*/,
    // 用户输入提示符
    userPrompt: /^[❯>]\s*/,
    // 任务状态
    taskStatus: /^[·•]\s*/,
    // 状态栏
    statusBar: /^[⏵>]{2}/,
    // Logo 字符
    logo: /^[▗▘▝▖\s]+$/,
    // 思考动画
    thinkingAnimation: /^(Percolating|Levitating|Brewing|Thinking|Pondering|Contemplating|Processing|Analyzing|Reasoning)\.\.\./i,
    // 权限请求模式
    permissionRequest: /^(\?|⚠️|🔐|Allow|Deny|Permission)/i,
    // 选择对话模式
    selectionDialog: /^\s*\[(\d+)\]|\s*\(([a-z])\)/i,
    // 确认模式 - 包含选择对话的问题
    confirmation: /\(y\/n\)|\[Y\/n\]|\[yes\/no\]|Continue\?|Proceed\?|Do you want to proceed\?/i,
    // 选项列表模式
    optionList: /^\s*[-•]\s+(.+)$/,
    // 编号选项 - 支持 "> 1. Yes" 和 "  1. Yes" 格式
    numberedOption: /^\s*[>❯]?\s*(\d+)[.)]\s+(.+)$/,
    // 错误标记
    errorMark: /Error|错误|failed|失败|exception|crash/i,
    // 问题模式
    question: /[?？]\s*$/,
    // 不完整状态
    incompleteStatus: /^[·•]?\s*(thinking|waiting|loading)\)?$/i,
};
// ANSI 颜色映射
const ANSI_COLOR_MAP = {
    '31': 'red', '91': 'red',
    '32': 'green', '92': 'green',
    '33': 'yellow', '93': 'yellow',
    '34': 'blue', '94': 'blue',
    '35': 'magenta', '95': 'magenta',
    '36': 'cyan', '96': 'cyan',
    '37': 'white',
    '90': 'gray',
};
// ============================================================================
// 解析状态
// ============================================================================
let outputBuffer = '';
let lastMessageType = 'system';
let pendingOptions = [];
let isCollectingOptions = false;
let pendingDialogQuestion = '';
// ============================================================================
// 颜色处理
// ============================================================================
function extractColorsAndClean(str) {
    const colors = [];
    let result = '';
    let currentColor = null;
    let colorStart = 0;
    // 更完整的 ANSI 转义序列匹配（包括 24-bit RGB 颜色）
    const ansiPattern = /\x1b\[[0-9;]*m/g;
    let lastIndex = 0;
    let match;
    while ((match = ansiPattern.exec(str)) !== null) {
        // 添加转义序列之前的文本
        result += str.slice(lastIndex, match.index);
        lastIndex = match.index + match[0].length;
        // 解析颜色代码
        const codeStr = match[0].slice(2, -1); // 去掉 \x1b[ 和 m
        const codes = codeStr.split(';');
        // 处理颜色代码
        let i = 0;
        while (i < codes.length) {
            const code = codes[i];
            // 重置
            if (code === '0' || code === '' || code === '39' || code === '49') {
                if (currentColor && result.length > colorStart) {
                    colors.push({ start: colorStart, end: result.length, color: currentColor });
                }
                currentColor = null;
            }
            // 24-bit 颜色: 38;2;R;G;B (前景) 或 48;2;R;G;B (背景)
            else if ((code === '38' || code === '48') && codes[i + 1] === '2') {
                // 跳过 RGB 值
                i += 4; // 跳过 38/48, 2, R, G, B
                // 尝试从 RGB 映射到基本颜色
                if (codes[i - 2] && codes[i - 1] && codes[i]) {
                    const r = parseInt(codes[i - 2]);
                    const g = parseInt(codes[i - 1]);
                    const b = parseInt(codes[i]);
                    const mapped = rgbToBasicColor(r, g, b);
                    if (mapped && code === '38') {
                        if (currentColor && result.length > colorStart) {
                            colors.push({ start: colorStart, end: result.length, color: currentColor });
                        }
                        currentColor = mapped;
                        colorStart = result.length;
                    }
                }
                continue;
            }
            // 256 色: 38;5;N 或 48;5;N
            else if ((code === '38' || code === '48') && codes[i + 1] === '5') {
                i += 2; // 跳过 38/48, 5, N
                continue;
            }
            // 基本颜色
            else if (ANSI_COLOR_MAP[code]) {
                if (currentColor && result.length > colorStart) {
                    colors.push({ start: colorStart, end: result.length, color: currentColor });
                }
                currentColor = ANSI_COLOR_MAP[code];
                colorStart = result.length;
            }
            i++;
        }
    }
    // 添加剩余文本
    result += str.slice(lastIndex);
    if (currentColor && result.length > colorStart) {
        colors.push({ start: colorStart, end: result.length, color: currentColor });
    }
    return { text: result, colors };
}
// RGB 转基本颜色
function rgbToBasicColor(r, g, b) {
    // 红色系
    if (r > 180 && g < 100 && b < 100)
        return 'red';
    if (r > 200 && g > 100 && b < 150)
        return 'red'; // 橙红
    // 绿色系
    if (g > 150 && r < 100 && b < 100)
        return 'green';
    // 蓝色系
    if (b > 150 && r < 100 && g < 150)
        return 'blue';
    // 黄色系
    if (r > 180 && g > 150 && b < 100)
        return 'yellow';
    // 紫色系
    if (r > 150 && b > 150 && g < 100)
        return 'magenta';
    // 青色系
    if (g > 150 && b > 150 && r < 100)
        return 'cyan';
    // 灰色系
    if (Math.abs(r - g) < 30 && Math.abs(g - b) < 30 && r < 180 && r > 80)
        return 'gray';
    // 白色
    if (r > 200 && g > 200 && b > 200)
        return 'white';
    return null;
}
function cleanTerminalOutput(str) {
    let result = str;
    // 1. 完整的 ANSI 转义序列
    result = result.replace(/\x1b\][^\x07]*\x07/g, ''); // OSC 序列
    result = result.replace(/\x1b[PX^_][^\x1b]*\x1b\\/g, ''); // DCS/PM/APC 序列
    result = result.replace(/\x1b\[[0-9;?]*[A-Za-z]/g, ''); // CSI 序列（包括颜色）
    result = result.replace(/\x1b[\x20-\x2F]*[\x30-\x7E]/g, ''); // 其他转义
    // 2. 清理残留的颜色代码（当 \x1b[ 被拆分时留下的）
    // 匹配像 38;2;215;119;87m 或 48;2;0;0;0m 或 39m 这样的残留
    // 这些是 ANSI 颜色代码被拆分后的残留部分
    result = result.replace(/[34]8;2;[0-9]+;[0-9]+;[0-9]+m/g, ''); // 24-bit 颜色
    result = result.replace(/[34]8;5;[0-9]+m/g, ''); // 256 色
    result = result.replace(/[0-9]{1,2}m/g, ''); // 基本颜色代码残留 (如 39m, 0m, 1m)
    result = result.replace(/;[0-9]+m/g, ''); // 以分号开头的残留
    result = result.replace(/[0-9]+;[0-9]+;[0-9]+;[0-9]+;[0-9]+m/g, ''); // 长序列残留
    // 3. 其他控制字符
    result = result.replace(/\?[0-9]+[hl]/g, '');
    result = result.replace(/[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]/g, '');
    // 4. 行尾处理
    result = result.replace(/\r\n/g, '\n');
    result = result.replace(/\r/g, '\n');
    return result;
}
function removeDecorations(str) {
    let result = str;
    result = result.replace(/[━─│┃┌┐└┘├┤┬┴┼╔╗╚╝╠╣╦╩╬═║╭╮╯╰]/g, '');
    result = result.replace(/[▀▄█▌▐░▒▓]/g, '');
    result = result.replace(/[▗▘▝▖]/g, '');
    result = result.replace(/[ \t]{3,}/g, '  ');
    result = result.replace(/\n{3,}/g, '\n\n');
    return result.trim();
}
// ============================================================================
// 选项提取
// ============================================================================
function extractOptions(content) {
    const options = [];
    // y/n 模式
    if (PATTERNS.confirmation.test(content)) {
        options.push({ id: 'yes', label: '是', hotkey: 'y', actionType: 'accept', isDefault: true }, { id: 'no', label: '否', hotkey: 'n', actionType: 'reject' });
        return options;
    }
    // 方括号选项: [option1/option2/option3]
    const bracketMatch = content.match(/\[([^\]]+)\]/);
    if (bracketMatch) {
        const parts = bracketMatch[1].split('/');
        parts.forEach((part, i) => {
            const label = part.trim();
            options.push({
                id: `opt_${i}`,
                label,
                hotkey: label[0]?.toLowerCase(),
                isDefault: i === 0,
            });
        });
        return options;
    }
    // 默认问题选项
    if (PATTERNS.question.test(content)) {
        options.push({ id: 'yes', label: '是', hotkey: 'y', actionType: 'accept' }, { id: 'no', label: '否', hotkey: 'n', actionType: 'reject' }, { id: 'continue', label: '继续', actionType: 'skip' });
    }
    return options;
}
function extractNumberedOptions(lines) {
    const options = [];
    for (const line of lines) {
        const match = line.match(PATTERNS.numberedOption);
        if (match) {
            options.push({
                id: `num_${match[1]}`,
                label: match[2].trim(),
                hotkey: match[1],
                actionType: 'select',
            });
        }
    }
    return options;
}
// ============================================================================
// 解析器核心
// ============================================================================
function parseLine(line) {
    const { text: cleanedLine, colors } = extractColorsAndClean(line);
    const trimmed = cleanedLine.trim();
    if (!trimmed)
        return null;
    // 过滤无意义的短内容（思考动画的逐字符更新等）
    // 只保留有意义的特殊字符或足够长的文本
    const meaningfulChars = trimmed.replace(/[✻✽✶✳✢·•⏺●❯>⏵\s]/g, '');
    if (meaningfulChars.length === 0)
        return null;
    if (meaningfulChars.length < 3 && !/^[⏺●❯]/.test(trimmed))
        return null;
    // 过滤掉残留的颜色代码
    if (/^[0-9;]+m/.test(trimmed))
        return null;
    // 过滤思考动画的逐字符更新残留
    // 这些是 Claude Code 思考动画（如 "Thinking...", "Pondering..."）被逐字符输出时产生的碎片
    const thinkingFragments = [
        // Thinking 的碎片
        'ati', 'ting', 'nking', 'hinking', 'Thinking', 'inking',
        // Pondering 的碎片
        'iat', 'giat', 'ering', 'dering', 'ndering', 'ondering', 'Pondering',
        // 其他思考词的碎片
        'essing', 'cessing', 'ocessing', 'rocessing', 'Processing',
        'ewing', 'rewing', 'Brewing',
        'ting', 'ating', 'itating', 'vitating', 'evitating', 'Levitating',
        'posing', 'mposing', 'omposing', 'Composing',
        'gling', 'agling', 'nagling', 'inagling', 'Finagling',
        'pping', 'epping', 'lepping', 'hlepping', 'chlepping', 'Schlepping',
    ];
    // 检查是否是单独的思考碎片（不以特殊符号开头）
    if (!(/^[⏺●❯└│├]/.test(trimmed))) {
        const lowerTrimmed = trimmed.toLowerCase();
        for (const frag of thinkingFragments) {
            if (lowerTrimmed === frag.toLowerCase() ||
                lowerTrimmed === frag.toLowerCase() + '...' ||
                lowerTrimmed === frag.toLowerCase() + '…') {
                return null;
            }
        }
    }
    // 过滤带时间的状态碎片（如 "ought for 3s)", "for 3s)"）
    if (/^(ought\s+)?for\s+\d+s\)?$/i.test(trimmed))
        return null;
    if (/^\d+s\)?$/.test(trimmed))
        return null;
    const timestamp = Date.now();
    const baseMessage = {
        timestamp,
        colorHints: colors.length > 0 ? colors : undefined,
        raw: line,
    };
    // 1. Logo - 只匹配完整的 logo 行
    if (PATTERNS.logo.test(trimmed) && trimmed.length > 10) {
        return { ...baseMessage, type: 'logo', content: trimmed, isLogo: true };
    }
    // 2. 状态栏 - ⏵⏵ 开头
    if (PATTERNS.statusBar.test(trimmed)) {
        const content = trimmed.replace(/^[⏵>]{2}\s*/, '').trim();
        if (content.length > 5) {
            return { ...baseMessage, type: 'status_bar', content };
        }
        return null;
    }
    // 3. Claude 消息 - ⏺ 或 ● 开头（优先于思考状态检测）
    if (/^[⏺●]/.test(trimmed)) {
        const content = trimmed.replace(/^[⏺●]\s*/, '').trim();
        if (!content || content.length < 2)
            return null;
        // 过滤 Claude Code 的系统提示消息
        if (/^Welcome\s+to\s+Claude\s+Code/i.test(content))
            return null;
        // 过滤默认AI助手欢迎消息
        if (/你好.*我是你的AI助手.*有什么可以帮助你的/i.test(content))
            return null;
        if (/Hello.*I'm\s+Claude.*How\s+can\s+I\s+(help|assist)/i.test(content))
            return null;
        // 只有明确的确认对话 (y/n) 才标记为需要回复
        // 普通问号结尾的句子不是需要回复的问题
        if (PATTERNS.confirmation.test(content)) {
            const options = extractOptions(content);
            return {
                ...baseMessage,
                type: 'confirmation',
                content,
                requiresResponse: true,
                options,
            };
        }
        lastMessageType = 'claude';
        return { ...baseMessage, type: 'claude', content };
    }
    // 4. 思考状态 - 匹配所有 Claude Code 的思考动画关键词
    // Claude Code 使用各种有趣的词汇表示思考中
    const thinkingKeywords = /^[✻✽✶✳✢·•]?\s*(Composing|Thinking|Pondering|Processing|Finagling|Schlepping|Brewing|Levitating|Shenaniganing|Boogieing|Crunching|Musing|Ruminating|Cogitating|Contemplating|Deliberating|Meditating|Reflecting|Percolating|Digesting|Analyzing|Computing|Calculating|Evaluating|Considering|Mulling|Weighing)/i;
    if (thinkingKeywords.test(trimmed)) {
        // 提取思考阶段名称
        const match = trimmed.match(/(Composing|Thinking|Pondering|Processing|Finagling|Schlepping|Brewing|Levitating|Shenaniganing|Boogieing|Crunching|Musing|Ruminating|Cogitating|Contemplating|Deliberating|Meditating|Reflecting|Percolating|Digesting|Analyzing|Computing|Calculating|Evaluating|Considering|Mulling|Weighing)/i);
        const phase = match ? match[1] : 'Thinking';
        return {
            ...baseMessage,
            type: 'thinking',
            content: phase + '...',
            thinkingPhase: phase,
        };
    }
    // 4.1 过滤带时间/token 统计的状态行（如 "· Crunched for 54s"）
    if (/^[·•✻✽✶✳✢]?\s*\w+ed?\s+(for\s+\d+s|·|\d+\s*tokens)/i.test(trimmed)) {
        const match = trimmed.match(/(\w+)(?:ed|ing)/i);
        return {
            ...baseMessage,
            type: 'thinking',
            content: (match ? match[1] : 'Working') + '...',
            thinkingPhase: match ? match[1] : 'Working',
        };
    }
    // 5. 忽略不完整状态和动画符号
    if (PATTERNS.incompleteStatus.test(trimmed))
        return null;
    if (trimmed.includes('esc to interrupt'))
        return null;
    // 过滤单独的动画符号和思考动画行
    if (/^[✻✽✶✳✢·•]+\s*\w*…?$/.test(trimmed))
        return null;
    // 过滤残留的思考状态（如 "✶ · thinking)"）
    if (/^[✻✽✶✳✢·•]+\s*·?\s*thinking\)?$/i.test(trimmed))
        return null;
    // 6. 过滤系统提示（Tip 消息）
    if (/^⎿\s*Tip:/i.test(trimmed))
        return null;
    // 过滤 IDE 状态消息和系统提示
    if (/^[◯○]\s*(IDE|VSCode|MCP|\/ide)/i.test(trimmed))
        return null;
    // 过滤欢迎消息
    if (/^[✻✽✶✳]\s*Welcome\s+to\s+Claude\s+Code/i.test(trimmed))
        return null;
    if (/^\/help\s+for\s+help/i.test(trimmed))
        return null;
    if (/^\/status\s+for\s+your\s+current\s+setup/i.test(trimmed))
        return null;
    // 过滤工作目录提示
    if (/^cwd:\s*\//i.test(trimmed))
        return null;
    // 6.1 过滤帮助提示和系统消息
    // 这些不是权限请求，只是 Claude Code 的界面提示
    // 匹配多种格式：`? for shortcuts`, `? shortcuts`, `?for shortcuts` 等
    if (/^\??\s*(for\s+)?(shortcuts|help|commands)/i.test(trimmed))
        return null;
    // 过滤单独的 `?` 符号或 `? ` 后跟提示
    if (/^\?\s*$/.test(trimmed))
        return null;
    // 过滤 IDE 连接状态提示（出现在底部状态栏）
    if (/^[◯○]\s*(IDE|VSCode|MCP)\s*(connected|disconnected|connecting)/i.test(trimmed))
        return null;
    // 过滤自动更新失败提示
    if (/^[✗×]\s*Auto-update\s+failed/i.test(trimmed))
        return null;
    if (/Try\s+(claude\s+doctor|npm\s+i\s+-g)/i.test(trimmed))
        return null;
    // 7. 权限请求检测 - 必须是真正的权限请求
    // 真正的权限请求格式：
    // - "? Allow Claude to read files"
    // - "Allow Bash to run command?"
    // - "Permission denied" 等
    // 注意排除系统状态提示
    const isRealPermissionRequest = (/^(\?\s*)?(Allow|Deny|Permission)/i.test(trimmed) ||
        /^⚠️/.test(trimmed) ||
        /^🔐/.test(trimmed) ||
        /Allow.*\?$/i.test(trimmed)) &&
        // 排除系统状态栏消息
        !/for\s+(shortcuts|help)|IDE\s*(dis)?connected|Auto-update/i.test(trimmed);
    if (isRealPermissionRequest) {
        const options = extractOptions(trimmed);
        return {
            ...baseMessage,
            type: 'permission_request',
            content: trimmed,
            requiresResponse: true,
            options: options.length > 0 ? options : [
                { id: 'allow', label: '允许', hotkey: 'y', actionType: 'accept' },
                { id: 'deny', label: '拒绝', hotkey: 'n', actionType: 'reject' },
                { id: 'always', label: '始终允许', hotkey: 'a', actionType: 'always_allow' },
            ],
            permission: {
                action: trimmed,
            },
        };
    }
    // 6. AskUserQuestion 导航栏检测（如 "← □ 发布平台 □切入角度 ✓Submit→"）
    // 这是 Claude Code 的多步问答导航，过滤掉
    if (/^[←→]?\s*[□■✓✗]/.test(trimmed) || /Submit[→]?$/i.test(trimmed)) {
        return null;
    }
    // 6.1 选择对话问题检测
    // 格式：中文问题以 ? 结尾，或英文问题
    const isSelectionQuestion = /Do you want to (proceed|continue)\?/i.test(trimmed) ||
        /Choose an option/i.test(trimmed) ||
        /Select.*:/i.test(trimmed) ||
        // 中文问题：以 ？ 结尾，且内容有意义
        (/[？?]$/.test(trimmed) && /[\u4e00-\u9fa5]/.test(trimmed) && trimmed.length > 5);
    if (isSelectionQuestion && !isCollectingOptions) {
        isCollectingOptions = true;
        pendingDialogQuestion = trimmed;
        return null;
    }
    // 6.2 编号选项检测（选择对话的选项）
    // 格式："> 1. 公众号/博客" 或 "  2. 小红书/微博" 或 "  5. Type something."
    const numberedMatch = trimmed.match(PATTERNS.numberedOption);
    if (numberedMatch) {
        isCollectingOptions = true;
        const optionNumber = numberedMatch[1];
        const optionLabel = numberedMatch[2].trim();
        const isSelected = /^[>❯]/.test(trimmed);
        pendingOptions.push({
            id: `opt_${optionNumber}`,
            label: optionLabel,
            hotkey: optionNumber,
            actionType: 'select',
            isDefault: isSelected,
        });
        return null;
    }
    // 6.3 选项描述行检测（纯缩进的描述文本）
    // 如果正在收集选项，且当前行是纯缩进文本（可能是选项描述）
    if (isCollectingOptions && pendingOptions.length > 0) {
        // 检查是否是描述行：前面有缩进，且不是选项格式
        if (/^\s{2,}[\u4e00-\u9fa5a-zA-Z]/.test(line) && !numberedMatch) {
            // 将描述追加到最后一个选项
            const lastOption = pendingOptions[pendingOptions.length - 1];
            if (lastOption) {
                const desc = trimmed;
                lastOption.description = lastOption.description
                    ? `${lastOption.description} ${desc}`
                    : desc;
            }
            return null;
        }
    }
    // 6.4 选项收集结束标志
    // "Enter to select · Tab/Arrow keys to navigate · Esc to cancel"
    if (/Enter to select|Esc to cancel|Tab.*navigate/i.test(trimmed)) {
        if (isCollectingOptions && pendingOptions.length > 0) {
            const options = [...pendingOptions];
            const question = pendingDialogQuestion || '请选择';
            pendingOptions = [];
            pendingDialogQuestion = '';
            isCollectingOptions = false;
            return {
                ...baseMessage,
                type: 'selection_dialog',
                content: question,
                requiresResponse: true,
                options,
            };
        }
        // 如果没有收集到选项，过滤掉这行提示
        return null;
    }
    // 6.5 如果正在收集选项，遇到非选项/非描述行，可能需要结束
    if (isCollectingOptions && pendingOptions.length > 0) {
        // 检查是否还可能有更多选项（空行继续等待）
        if (/^\s*$/.test(trimmed)) {
            return null;
        }
        // 遇到其他内容，但不立即结束，等待 "Enter to select" 标志
    }
    // 保持原有逻辑用于旧格式兼容
    // 6.6 旧格式：如果正在收集但遇到明确的非选项内容
    if (isCollectingOptions && pendingOptions.length > 0 && !numberedMatch) {
        // 如果是明显的其他类型消息，结束收集
        if (/^[⏺●❯└│├]/.test(trimmed)) {
            const options = [...pendingOptions];
            const question = pendingDialogQuestion || '请选择';
            pendingOptions = [];
            pendingDialogQuestion = '';
            isCollectingOptions = false;
            return {
                ...baseMessage,
                type: 'selection_dialog',
                content: question,
                requiresResponse: true,
                options,
            };
        }
    }
    // 8. 工具调用
    const toolMatch = trimmed.match(PATTERNS.toolCall);
    if (toolMatch) {
        const toolName = toolMatch[1];
        const toolArg = toolMatch[2];
        lastMessageType = 'tool_call';
        return {
            ...baseMessage,
            type: 'tool_call',
            content: toolName,
            tool: {
                name: toolName,
                args: toolArg || undefined,
                filePath: toolArg || undefined,
            },
        };
    }
    // 9. 工具结果
    if (PATTERNS.toolResult.test(trimmed)) {
        const content = trimmed.replace(PATTERNS.toolResult, '').trim();
        if (!content)
            return null;
        // 检测错误
        if (PATTERNS.errorMark.test(content)) {
            return { ...baseMessage, type: 'tool_error', content };
        }
        // 检测 Next: 提示
        if (content.startsWith('Next:')) {
            return {
                ...baseMessage,
                type: 'task_status',
                content: content.replace('Next:', '下一步:'),
            };
        }
        return { ...baseMessage, type: 'tool_result', content };
    }
    // 11. 用户输入提示符
    if (PATTERNS.userPrompt.test(trimmed)) {
        const content = trimmed.replace(PATTERNS.userPrompt, '').trim();
        if (content) {
            // 过滤 Claude Code 的提示语（Try "...", 帮助提示等）
            if (/^Try ["']/.test(content))
                return null;
            if (/^\/\w+/.test(content))
                return null; // 命令提示如 /ide
            return { ...baseMessage, type: 'user_input', content };
        }
        return null;
    }
    // 12. 任务状态
    if (PATTERNS.taskStatus.test(trimmed)) {
        const content = trimmed.replace(PATTERNS.taskStatus, '').trim();
        if (!content)
            return null;
        if (/^(thinking|waiting|loading|processing)$/i.test(content))
            return null;
        return { ...baseMessage, type: 'task_status', content };
    }
    // 13. 未识别的输出 - 以 raw 类型传递，但要过滤噪音
    // 只发送有意义的内容（至少 10 个字符，或包含中文）
    const hasChinese = /[\u4e00-\u9fa5]/.test(trimmed);
    const hasEnglishWords = /[a-zA-Z]{3,}/.test(trimmed);
    // 额外过滤：底部状态栏的系统消息
    if (/IDE\s*(dis)?connected|Auto-update\s+failed/i.test(trimmed))
        return null;
    // 过滤带时间戳或分隔符的系统消息
    if (/^\d{4}-\d{2}-\d{2}|^[-=]{3,}|^[╭╰─]+$/i.test(trimmed))
        return null;
    if (trimmed.length >= 10 || hasChinese || hasEnglishWords) {
        // 额外过滤：如果主要是特殊字符和数字，跳过
        const alphanumericRatio = (trimmed.match(/[a-zA-Z0-9\u4e00-\u9fa5]/g) || []).length / trimmed.length;
        if (alphanumericRatio > 0.3) {
            return { ...baseMessage, type: 'raw', content: trimmed };
        }
    }
    return null;
}
// ============================================================================
// 消息合并
// ============================================================================
/**
 * 合并连续的同类型消息
 * - claude 后面的 raw 会合并到 claude 里（因为 Claude 输出只有第一行有 ⏺）
 * - 连续的 raw 会合并
 */
function mergeMessages(messages) {
    if (messages.length === 0)
        return [];
    const result = [];
    let current = null;
    for (const msg of messages) {
        if (!current) {
            current = { ...msg };
            continue;
        }
        // 决定是否合并
        let shouldMerge = false;
        // 1. 相同类型的 raw 或 tool_result 合并
        if (current.type === msg.type && (msg.type === 'raw' || msg.type === 'tool_result')) {
            shouldMerge = true;
        }
        // 2. claude 后面跟着 raw，合并到 claude（Claude 流式输出特性）
        else if (current.type === 'claude' && msg.type === 'raw') {
            shouldMerge = true;
        }
        // 3. 连续的 claude 消息合并
        else if (current.type === 'claude' && msg.type === 'claude') {
            shouldMerge = true;
        }
        if (shouldMerge) {
            current.content += '\n' + msg.content;
            // 合并颜色标记
            if (msg.colorHints && msg.colorHints.length > 0) {
                const offset = current.content.length - msg.content.length;
                const adjustedHints = msg.colorHints.map(h => ({
                    ...h,
                    start: h.start + offset,
                    end: h.end + offset,
                }));
                current.colorHints = [...(current.colorHints || []), ...adjustedHints];
            }
        }
        else {
            // 类型不兼容，保存当前消息，开始新消息
            result.push(current);
            current = { ...msg };
        }
    }
    // 添加最后一条消息
    if (current) {
        result.push(current);
    }
    return result;
}
// ============================================================================
// 导出函数
// ============================================================================
/**
 * 解析终端输出
 */
function parseOutput(rawData) {
    const cleaned = cleanTerminalOutput(rawData);
    outputBuffer += cleaned;
    const lines = outputBuffer.split('\n');
    outputBuffer = lines.pop() || '';
    const rawMessages = [];
    for (const line of lines) {
        const cleanLine = removeDecorations(line);
        const parsed = parseLine(cleanLine);
        if (parsed)
            rawMessages.push(parsed);
    }
    // 合并连续的同类型消息（claude 和 raw 类型）
    return mergeMessages(rawMessages);
}
/**
 * 刷新缓冲区
 */
function flushBuffer() {
    const results = [];
    // 如果有待处理的选项，先输出
    if (pendingOptions.length > 0) {
        const options = [...pendingOptions];
        const question = pendingDialogQuestion || '请选择';
        pendingOptions = [];
        pendingDialogQuestion = '';
        isCollectingOptions = false;
        results.push({
            type: 'selection_dialog',
            content: question,
            timestamp: Date.now(),
            requiresResponse: true,
            options,
        });
    }
    if (outputBuffer.trim()) {
        const cleanLine = removeDecorations(outputBuffer);
        outputBuffer = '';
        const parsed = parseLine(cleanLine);
        if (parsed)
            results.push(parsed);
    }
    else {
        outputBuffer = '';
    }
    return results;
}
/**
 * 重置解析器状态
 */
function resetParser() {
    outputBuffer = '';
    lastMessageType = 'system';
    pendingOptions = [];
    isCollectingOptions = false;
    pendingDialogQuestion = '';
}
/**
 * 格式化用户响应为 Claude Code 可接受的输入
 */
function formatUserResponse(action, optionId) {
    switch (action) {
        case 'accept':
            return 'y';
        case 'reject':
            return 'n';
        case 'always_allow':
            return 'a';
        case 'always_deny':
            return 'd';
        case 'skip':
            return '\n';
        case 'select':
            return optionId || '1';
        default:
            return action;
    }
}
//# sourceMappingURL=parser.js.map