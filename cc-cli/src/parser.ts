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

// ============================================================================
// 类型定义 - 使用字符串类型保持开放性
// ============================================================================

/**
 * 消息类型 - 可扩展的字符串类型
 * 核心类型有明确定义，未知类型以 'unknown' 或 'raw' 传递
 */
export type MessageType =
  // 核心消息类型
  | 'claude'              // Claude 的文本回复
  | 'user_input'          // 用户输入
  | 'tool_call'           // 工具调用开始
  | 'tool_result'         // 工具执行结果
  | 'tool_error'          // 工具执行错误
  // 状态类型
  | 'thinking'            // 思考中 (Pondering..., Thinking...)
  | 'status_bar'          // 底部状态栏
  | 'task_status'         // 任务状态更新
  // 交互类型 - 需要用户响应
  | 'question'            // 简单问题 (y/n)
  | 'permission_request'  // 权限请求对话
  | 'selection_dialog'    // 多选项对话 (elicitation_dialog)
  | 'confirmation'        // 确认对话
  // 系统类型
  | 'system'              // 系统消息
  | 'error'               // 错误消息
  | 'logo'                // Claude Code Logo
  | 'raw'                 // 未识别的原始输出
  | string;               // 允许未来扩展

/**
 * 交互动作类型 - 用户可执行的操作
 */
export type ActionType =
  | 'accept'              // 接受/允许
  | 'reject'              // 拒绝/取消
  | 'select'              // 选择选项
  | 'input'               // 输入文本
  | 'skip'                // 跳过
  | 'always_allow'        // 始终允许
  | 'always_deny'         // 始终拒绝
  | string;               // 允许扩展

/**
 * 交互选项
 */
export interface InteractionOption {
  id: string;             // 选项 ID
  label: string;          // 显示文本
  description?: string;   // 详细描述
  isDefault?: boolean;    // 是否默认选项
  actionType?: ActionType;// 对应的动作类型
  hotkey?: string;        // 快捷键 (y/n/a 等)
}

/**
 * ANSI 颜色
 */
export type ANSIColor = 'red' | 'green' | 'yellow' | 'blue' | 'magenta' | 'cyan' | 'white' | 'gray';

/**
 * 颜色标记
 */
export interface ColorHint {
  start: number;
  end: number;
  color: ANSIColor;
}

/**
 * 工具信息
 */
export interface ToolInfo {
  name: string;           // 工具名称: Read, Write, Bash, Edit, Grep...
  args?: string;          // 工具参数
  filePath?: string;      // 文件路径（如适用）
  command?: string;       // 命令（Bash 工具）
  description?: string;   // 工具描述
}

/**
 * 权限请求信息
 */
export interface PermissionInfo {
  tool?: string;          // 请求权限的工具
  action?: string;        // 请求的操作
  resource?: string;      // 操作的资源（文件路径等）
  risk?: 'low' | 'medium' | 'high'; // 风险级别
}

/**
 * 解析后的消息 - 核心数据结构
 */
export interface ParsedMessage {
  // 必需字段
  type: MessageType;
  content: string;
  timestamp: number;

  // 工具相关
  tool?: ToolInfo;

  // 交互相关 - 需要用户响应时填充
  requiresResponse?: boolean;       // 是否需要用户响应
  options?: InteractionOption[];    // 可选选项
  permission?: PermissionInfo;      // 权限请求详情
  defaultAction?: ActionType;       // 默认操作
  timeout?: number;                 // 超时时间（毫秒）

  // 显示相关
  colorHints?: ColorHint[];         // 颜色标记
  isLogo?: boolean;                 // Logo 标识
  thinkingPhase?: string;           // 思考阶段名称

  // 元数据 - 用于扩展
  metadata?: Record<string, unknown>;

  // 原始数据 - 调试用
  raw?: string;
}

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

  // 确认模式
  confirmation: /\(y\/n\)|\[Y\/n\]|\[yes\/no\]|Continue\?|Proceed\?/i,

  // 选项列表模式
  optionList: /^\s*[-•]\s+(.+)$/,

  // 编号选项
  numberedOption: /^\s*(\d+)[.)]\s+(.+)$/,

  // 错误标记
  errorMark: /Error|错误|failed|失败|exception|crash/i,

  // 问题模式
  question: /[?？]\s*$/,

  // 不完整状态
  incompleteStatus: /^[·•]?\s*(thinking|waiting|loading)\)?$/i,
};

// ANSI 颜色映射
const ANSI_COLOR_MAP: Record<string, ANSIColor> = {
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
let lastMessageType: MessageType = 'system';
let pendingOptions: InteractionOption[] = [];
let isCollectingOptions = false;

// ============================================================================
// 颜色处理
// ============================================================================

function extractColorsAndClean(str: string): { text: string; colors: ColorHint[] } {
  const colors: ColorHint[] = [];
  let result = '';
  let currentColor: ANSIColor | null = null;
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
function rgbToBasicColor(r: number, g: number, b: number): ANSIColor | null {
  // 红色系
  if (r > 180 && g < 100 && b < 100) return 'red';
  if (r > 200 && g > 100 && b < 150) return 'red'; // 橙红
  // 绿色系
  if (g > 150 && r < 100 && b < 100) return 'green';
  // 蓝色系
  if (b > 150 && r < 100 && g < 150) return 'blue';
  // 黄色系
  if (r > 180 && g > 150 && b < 100) return 'yellow';
  // 紫色系
  if (r > 150 && b > 150 && g < 100) return 'magenta';
  // 青色系
  if (g > 150 && b > 150 && r < 100) return 'cyan';
  // 灰色系
  if (Math.abs(r - g) < 30 && Math.abs(g - b) < 30 && r < 180 && r > 80) return 'gray';
  // 白色
  if (r > 200 && g > 200 && b > 200) return 'white';

  return null;
}

function cleanTerminalOutput(str: string): string {
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

function removeDecorations(str: string): string {
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

function extractOptions(content: string): InteractionOption[] {
  const options: InteractionOption[] = [];

  // y/n 模式
  if (PATTERNS.confirmation.test(content)) {
    options.push(
      { id: 'yes', label: '是', hotkey: 'y', actionType: 'accept', isDefault: true },
      { id: 'no', label: '否', hotkey: 'n', actionType: 'reject' }
    );
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
    options.push(
      { id: 'yes', label: '是', hotkey: 'y', actionType: 'accept' },
      { id: 'no', label: '否', hotkey: 'n', actionType: 'reject' },
      { id: 'continue', label: '继续', actionType: 'skip' }
    );
  }

  return options;
}

function extractNumberedOptions(lines: string[]): InteractionOption[] {
  const options: InteractionOption[] = [];

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

function parseLine(line: string): ParsedMessage | null {
  const { text: cleanedLine, colors } = extractColorsAndClean(line);
  const trimmed = cleanedLine.trim();
  if (!trimmed) return null;

  // 过滤无意义的短内容（思考动画的逐字符更新等）
  // 只保留有意义的特殊字符或足够长的文本
  const meaningfulChars = trimmed.replace(/[✻✽✶✳✢·•⏺●❯>⏵\s]/g, '');
  if (meaningfulChars.length === 0) return null;
  if (meaningfulChars.length < 3 && !/^[⏺●❯]/.test(trimmed)) return null;

  // 过滤掉残留的颜色代码
  if (/^[0-9;]+m/.test(trimmed)) return null;

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
    if (!content || content.length < 2) return null;

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

  // 4. 思考状态 - 只匹配明确的思考行（带动画符号 + 关键词）
  const thinkingKeywords = /^[✻✽✶✳✢·•]\s*(Composing|Thinking|Pondering|Processing|Finagling|Schlepping|Brewing|Levitating)/i;
  if (thinkingKeywords.test(trimmed)) {
    const phase = trimmed.match(/(Composing|Thinking|Pondering|Processing|Finagling|Schlepping|Brewing|Levitating)/i)?.[1] || 'Thinking';
    return {
      ...baseMessage,
      type: 'thinking',
      content: trimmed,
      thinkingPhase: phase,
    };
  }

  // 5. 忽略不完整状态和动画符号
  if (PATTERNS.incompleteStatus.test(trimmed)) return null;
  if (trimmed.includes('esc to interrupt')) return null;
  // 过滤单独的动画符号和思考动画行
  if (/^[✻✽✶✳✢·•]+\s*\w*…?$/.test(trimmed)) return null;
  // 过滤残留的思考状态（如 "✶ · thinking)"）
  if (/^[✻✽✶✳✢·•]+\s*·?\s*thinking\)?$/i.test(trimmed)) return null;

  // 6. 过滤系统提示（Tip 消息）
  if (/^⎿\s*Tip:/i.test(trimmed)) return null;
  // 过滤 IDE 状态消息
  if (/^◯\s*(IDE|\/ide)/i.test(trimmed)) return null;

  // 7. 权限请求检测
  if (PATTERNS.permissionRequest.test(trimmed)) {
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

  // 6. 编号选项检测（选择对话）
  const numberedMatch = trimmed.match(PATTERNS.numberedOption);
  if (numberedMatch || PATTERNS.selectionDialog.test(trimmed)) {
    isCollectingOptions = true;
    pendingOptions.push({
      id: `opt_${pendingOptions.length}`,
      label: numberedMatch ? numberedMatch[2] : trimmed,
      hotkey: numberedMatch ? numberedMatch[1] : undefined,
      actionType: 'select',
    });
    // 暂不返回，等待收集完所有选项
    return null;
  }

  // 7. 如果正在收集选项，遇到非选项行则结束收集
  if (isCollectingOptions && pendingOptions.length > 0) {
    const options = [...pendingOptions];
    pendingOptions = [];
    isCollectingOptions = false;

    return {
      ...baseMessage,
      type: 'selection_dialog',
      content: '请选择',
      requiresResponse: true,
      options,
    };
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
    if (!content) return null;

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
      if (/^Try ["']/.test(content)) return null;
      if (/^\/\w+/.test(content)) return null; // 命令提示如 /ide
      return { ...baseMessage, type: 'user_input', content };
    }
    return null;
  }

  // 12. 任务状态
  if (PATTERNS.taskStatus.test(trimmed)) {
    const content = trimmed.replace(PATTERNS.taskStatus, '').trim();
    if (!content) return null;
    if (/^(thinking|waiting|loading|processing)$/i.test(content)) return null;
    return { ...baseMessage, type: 'task_status', content };
  }

  // 13. 未识别的输出 - 以 raw 类型传递，但要过滤噪音
  // 只发送有意义的内容（至少 10 个字符，或包含中文）
  const hasChinese = /[\u4e00-\u9fa5]/.test(trimmed);
  const hasEnglishWords = /[a-zA-Z]{3,}/.test(trimmed);

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
function mergeMessages(messages: ParsedMessage[]): ParsedMessage[] {
  if (messages.length === 0) return [];

  const result: ParsedMessage[] = [];
  let current: ParsedMessage | null = null;

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
    } else {
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
export function parseOutput(rawData: string): ParsedMessage[] {
  const cleaned = cleanTerminalOutput(rawData);
  outputBuffer += cleaned;

  const lines = outputBuffer.split('\n');
  outputBuffer = lines.pop() || '';

  const rawMessages: ParsedMessage[] = [];
  for (const line of lines) {
    const cleanLine = removeDecorations(line);
    const parsed = parseLine(cleanLine);
    if (parsed) rawMessages.push(parsed);
  }

  // 合并连续的同类型消息（claude 和 raw 类型）
  return mergeMessages(rawMessages);
}

/**
 * 刷新缓冲区
 */
export function flushBuffer(): ParsedMessage[] {
  // 如果有待处理的选项，先输出
  if (pendingOptions.length > 0) {
    const options = [...pendingOptions];
    pendingOptions = [];
    isCollectingOptions = false;
    return [{
      type: 'selection_dialog',
      content: '请选择',
      timestamp: Date.now(),
      requiresResponse: true,
      options,
    }];
  }

  if (!outputBuffer.trim()) {
    outputBuffer = '';
    return [];
  }

  const cleanLine = removeDecorations(outputBuffer);
  outputBuffer = '';
  const parsed = parseLine(cleanLine);
  return parsed ? [parsed] : [];
}

/**
 * 重置解析器状态
 */
export function resetParser(): void {
  outputBuffer = '';
  lastMessageType = 'system';
  pendingOptions = [];
  isCollectingOptions = false;
}

/**
 * 格式化用户响应为 Claude Code 可接受的输入
 */
export function formatUserResponse(action: ActionType, optionId?: string): string {
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
