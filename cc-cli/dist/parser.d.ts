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
/**
 * 消息类型 - 可扩展的字符串类型
 * 核心类型有明确定义，未知类型以 'unknown' 或 'raw' 传递
 */
export type MessageType = 'claude' | 'user_input' | 'tool_call' | 'tool_result' | 'tool_error' | 'thinking' | 'status_bar' | 'task_status' | 'question' | 'permission_request' | 'selection_dialog' | 'confirmation' | 'system' | 'error' | 'logo' | 'raw' | string;
/**
 * 交互动作类型 - 用户可执行的操作
 */
export type ActionType = 'accept' | 'reject' | 'select' | 'input' | 'skip' | 'always_allow' | 'always_deny' | string;
/**
 * 交互选项
 */
export interface InteractionOption {
    id: string;
    label: string;
    description?: string;
    isDefault?: boolean;
    actionType?: ActionType;
    hotkey?: string;
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
    name: string;
    args?: string;
    filePath?: string;
    command?: string;
    description?: string;
}
/**
 * 权限请求信息
 */
export interface PermissionInfo {
    tool?: string;
    action?: string;
    resource?: string;
    risk?: 'low' | 'medium' | 'high';
}
/**
 * 解析后的消息 - 核心数据结构
 */
export interface ParsedMessage {
    type: MessageType;
    content: string;
    timestamp: number;
    tool?: ToolInfo;
    requiresResponse?: boolean;
    options?: InteractionOption[];
    permission?: PermissionInfo;
    defaultAction?: ActionType;
    timeout?: number;
    colorHints?: ColorHint[];
    isLogo?: boolean;
    thinkingPhase?: string;
    metadata?: Record<string, unknown>;
    raw?: string;
}
/**
 * 解析终端输出
 */
export declare function parseOutput(rawData: string): ParsedMessage[];
/**
 * 刷新缓冲区
 */
export declare function flushBuffer(): ParsedMessage[];
/**
 * 重置解析器状态
 */
export declare function resetParser(): void;
/**
 * 格式化用户响应为 Claude Code 可接受的输入
 */
export declare function formatUserResponse(action: ActionType, optionId?: string): string;
//# sourceMappingURL=parser.d.ts.map