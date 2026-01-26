/**
 * 会话管理模块
 *
 * 新架构：基于 Claude Code Hooks 获取状态
 * - Hook 事件提供结构化的状态信息
 * - PTY 输出仅用于终端显示
 * - 更准确的权限请求和完成状态检测
 */
interface SessionOptions {
    name: string;
    server: string;
}
export declare function startSession(options: SessionOptions): Promise<void>;
export {};
//# sourceMappingURL=session.d.ts.map