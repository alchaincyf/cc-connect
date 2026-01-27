/**
 * Claude Code Hooks 集成模块
 *
 * 通过 Claude Code 官方的 Hooks API 获取结构化事件，
 * 替代不可靠的 PTY 输出解析。
 *
 * 架构：
 * 1. Claude Code 执行任务时触发 Hook
 * 2. Hook 脚本通过 HTTP POST 发送事件到本地服务器
 * 3. 本地服务器处理事件并转发到手机
 */

import * as http from 'http';
import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';

// ============================================================================
// 类型定义
// ============================================================================

/**
 * Claude Code Hook 事件类型
 */
export type HookEventType =
  | 'Stop'              // Claude 完成响应
  | 'Notification'      // 通知（权限请求、空闲等）
  | 'PreToolUse'        // 工具调用前
  | 'PostToolUse'       // 工具调用后
  | 'UserPromptSubmit'  // 用户提交输入
  | 'SessionStart'      // 会话开始
  | 'SessionEnd';       // 会话结束

/**
 * Notification 事件的子类型
 */
export type NotificationType =
  | 'permission_prompt'   // 权限请求
  | 'idle_prompt'         // 空闲等待输入
  | 'elicitation_dialog'  // 选择对话
  | 'auth_success';       // 认证成功

/**
 * Hook 事件基础结构（Claude Code 发送的 JSON）
 */
export interface HookEventInput {
  session_id: string;
  transcript_path: string;
  cwd: string;
  permission_mode: string;
  hook_event_name: HookEventType;

  // Stop 事件特有
  stop_hook_active?: boolean;

  // Notification 事件特有
  message?: string;
  notification_type?: NotificationType;

  // Tool 事件特有
  tool_name?: string;
  tool_input?: Record<string, any>;
  tool_response?: Record<string, any>;
  tool_use_id?: string;

  // UserPromptSubmit 事件特有
  prompt?: string;

  // SessionStart 事件特有
  source?: string;
  model?: string;
}

/**
 * 处理后的事件（发送到手机）
 */
export interface ProcessedEvent {
  type: 'hook_event';
  event: HookEventType;
  timestamp: number;

  // 消息内容
  message?: {
    type: string;
    content: string;
    tool?: {
      name: string;
      args?: string;
      result?: string;
    };
    requiresResponse?: boolean;
    options?: Array<{
      id: string;
      label: string;
      hotkey?: string;
      actionType?: string;
    }>;
  };

  // 状态更新
  status?: {
    type: 'idle' | 'working' | 'waiting_permission' | 'waiting_input';
    message?: string;
  };
}

// ============================================================================
// Hook 事件处理器
// ============================================================================

type EventHandler = (event: ProcessedEvent) => void;

let eventHandler: EventHandler | null = null;
let httpServer: http.Server | null = null;

/**
 * 处理 Stop 事件 - Claude 完成响应
 */
function handleStopEvent(input: HookEventInput): ProcessedEvent {
  // 读取 transcript 获取 Claude 的回复
  let claudeResponse = '';
  try {
    if (input.transcript_path && fs.existsSync(input.transcript_path)) {
      const transcript = fs.readFileSync(input.transcript_path, 'utf-8');
      const lines = transcript.trim().split('\n');

      // 从后往前找最后一条 assistant 消息
      for (let i = lines.length - 1; i >= 0; i--) {
        try {
          const entry = JSON.parse(lines[i]);
          if (entry.type === 'assistant' && entry.message?.content) {
            // 提取文本内容
            const content = entry.message.content;
            if (Array.isArray(content)) {
              claudeResponse = content
                .filter((c: any) => c.type === 'text')
                .map((c: any) => c.text)
                .join('\n');
            } else if (typeof content === 'string') {
              claudeResponse = content;
            }
            break;
          }
        } catch {
          // 跳过无法解析的行
        }
      }
    }
  } catch (err) {
    console.error('[Hook] 读取 transcript 失败:', err);
  }

  return {
    type: 'hook_event',
    event: 'Stop',
    timestamp: Date.now(),
    message: claudeResponse ? {
      type: 'claude',
      content: claudeResponse,
    } : undefined,
    status: {
      type: 'idle',
      message: '等待输入',
    },
  };
}

/**
 * 处理 Notification 事件
 */
function handleNotificationEvent(input: HookEventInput): ProcessedEvent {
  const notificationType = input.notification_type;
  const message = input.message || '';

  if (notificationType === 'permission_prompt') {
    // 权限请求
    return {
      type: 'hook_event',
      event: 'Notification',
      timestamp: Date.now(),
      message: {
        type: 'permission_request',
        content: message,
        requiresResponse: true,
        options: [
          { id: 'allow', label: '允许', hotkey: 'y', actionType: 'accept' },
          { id: 'deny', label: '拒绝', hotkey: 'n', actionType: 'reject' },
          { id: 'always', label: '始终允许', hotkey: 'a', actionType: 'always_allow' },
        ],
      },
      status: {
        type: 'waiting_permission',
        message,
      },
    };
  }

  if (notificationType === 'idle_prompt') {
    // 空闲等待输入
    return {
      type: 'hook_event',
      event: 'Notification',
      timestamp: Date.now(),
      status: {
        type: 'idle',
        message: '等待输入',
      },
    };
  }

  if (notificationType === 'elicitation_dialog') {
    // 选择对话 - 需要从 transcript 获取选项
    return {
      type: 'hook_event',
      event: 'Notification',
      timestamp: Date.now(),
      message: {
        type: 'selection_dialog',
        content: message,
        requiresResponse: true,
      },
      status: {
        type: 'waiting_input',
        message,
      },
    };
  }

  // 其他通知
  return {
    type: 'hook_event',
    event: 'Notification',
    timestamp: Date.now(),
    status: {
      type: 'working',
      message,
    },
  };
}

/**
 * 处理 PreToolUse 事件
 */
function handlePreToolUseEvent(input: HookEventInput): ProcessedEvent {
  const toolName = input.tool_name || 'Unknown';
  const toolInput = input.tool_input || {};

  let args = '';
  if (toolName === 'Bash' && toolInput.command) {
    args = toolInput.command;
  } else if (toolName === 'Read' && toolInput.file_path) {
    args = toolInput.file_path;
  } else if (toolName === 'Write' && toolInput.file_path) {
    args = toolInput.file_path;
  } else if (toolName === 'Edit' && toolInput.file_path) {
    args = toolInput.file_path;
  } else if (toolInput.file_path) {
    args = toolInput.file_path;
  }

  return {
    type: 'hook_event',
    event: 'PreToolUse',
    timestamp: Date.now(),
    message: {
      type: 'tool_call',
      content: toolName,
      tool: {
        name: toolName,
        args,
      },
    },
    status: {
      type: 'working',
      message: `执行 ${toolName}...`,
    },
  };
}

/**
 * 处理 PostToolUse 事件
 */
function handlePostToolUseEvent(input: HookEventInput): ProcessedEvent {
  const toolName = input.tool_name || 'Unknown';
  const toolResponse = input.tool_response;

  let result = '';
  if (toolResponse) {
    if (typeof toolResponse === 'string') {
      result = toolResponse;
    } else if (toolResponse.success !== undefined) {
      result = toolResponse.success ? '成功' : '失败';
    } else {
      result = JSON.stringify(toolResponse).substring(0, 200);
    }
  }

  return {
    type: 'hook_event',
    event: 'PostToolUse',
    timestamp: Date.now(),
    message: {
      type: 'tool_result',
      content: `${toolName} 完成`,
      tool: {
        name: toolName,
        result,
      },
    },
  };
}

/**
 * 处理 UserPromptSubmit 事件
 */
function handleUserPromptEvent(input: HookEventInput): ProcessedEvent {
  return {
    type: 'hook_event',
    event: 'UserPromptSubmit',
    timestamp: Date.now(),
    message: {
      type: 'user_input',
      content: input.prompt || '',
    },
    status: {
      type: 'working',
      message: '处理中...',
    },
  };
}

/**
 * 处理 Hook 事件
 */
function processHookEvent(input: HookEventInput): ProcessedEvent | null {
  switch (input.hook_event_name) {
    case 'Stop':
      return handleStopEvent(input);
    case 'Notification':
      return handleNotificationEvent(input);
    case 'PreToolUse':
      return handlePreToolUseEvent(input);
    case 'PostToolUse':
      return handlePostToolUseEvent(input);
    case 'UserPromptSubmit':
      return handleUserPromptEvent(input);
    default:
      return null;
  }
}

// ============================================================================
// HTTP 服务器 - 接收 Hook 事件
// ============================================================================

const HOOK_SERVER_PORT = 19789; // 本地 Hook 服务器端口

/**
 * 启动 Hook 事件监听服务器
 */
export function startHookServer(handler: EventHandler): Promise<number> {
  return new Promise((resolve, reject) => {
    eventHandler = handler;

    httpServer = http.createServer((req, res) => {
      // CORS 头
      res.setHeader('Access-Control-Allow-Origin', '*');
      res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
      res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

      if (req.method === 'OPTIONS') {
        res.writeHead(200);
        res.end();
        return;
      }

      if (req.method === 'POST' && req.url === '/hook') {
        let body = '';
        req.on('data', chunk => {
          body += chunk.toString();
        });
        req.on('end', () => {
          try {
            const input = JSON.parse(body) as HookEventInput;
            const processed = processHookEvent(input);

            if (processed && eventHandler) {
              eventHandler(processed);
            }

            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ success: true }));
          } catch (err) {
            console.error('[Hook Server] 处理事件失败:', err);
            res.writeHead(400, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ error: 'Invalid JSON' }));
          }
        });
      } else {
        res.writeHead(404);
        res.end('Not Found');
      }
    });

    httpServer.on('error', (err: NodeJS.ErrnoException) => {
      if (err.code === 'EADDRINUSE') {
        console.error(`[Hook Server] 端口 ${HOOK_SERVER_PORT} 已被占用`);
      }
      reject(err);
    });

    httpServer.listen(HOOK_SERVER_PORT, '127.0.0.1', () => {
      resolve(HOOK_SERVER_PORT);
    });
  });
}

/**
 * 停止 Hook 服务器
 */
export function stopHookServer(): void {
  if (httpServer) {
    httpServer.close();
    httpServer = null;
  }
  eventHandler = null;
}

// ============================================================================
// Hook 配置生成
// ============================================================================

/**
 * 生成 Claude Code Hooks 配置
 */
export function generateHooksConfig(): object {
  // Hook 脚本路径
  const hookScriptPath = getHookScriptPath();

  return {
    hooks: {
      // Claude 完成响应时
      Stop: [{
        hooks: [{
          type: 'command',
          command: `"${hookScriptPath}" stop`,
          timeout: 5,
        }],
      }],

      // 通知事件（权限请求、空闲等）
      Notification: [
        {
          matcher: 'permission_prompt',
          hooks: [{
            type: 'command',
            command: `"${hookScriptPath}" notification permission`,
            timeout: 5,
          }],
        },
        {
          matcher: 'idle_prompt',
          hooks: [{
            type: 'command',
            command: `"${hookScriptPath}" notification idle`,
            timeout: 5,
          }],
        },
        {
          matcher: 'elicitation_dialog',
          hooks: [{
            type: 'command',
            command: `"${hookScriptPath}" notification elicitation`,
            timeout: 5,
          }],
        },
      ],

      // 工具调用
      PreToolUse: [{
        matcher: '*',
        hooks: [{
          type: 'command',
          command: `"${hookScriptPath}" pre-tool`,
          timeout: 5,
        }],
      }],

      PostToolUse: [{
        matcher: '*',
        hooks: [{
          type: 'command',
          command: `"${hookScriptPath}" post-tool`,
          timeout: 5,
        }],
      }],

      // 用户输入
      UserPromptSubmit: [{
        hooks: [{
          type: 'command',
          command: `"${hookScriptPath}" user-prompt`,
          timeout: 5,
        }],
      }],
    },
  };
}

/**
 * 获取 Hook 脚本路径
 */
function getHookScriptPath(): string {
  // 使用全局安装的脚本路径
  return 'peanut-hook-notify';
}

/**
 * 安装 Hooks 配置到 Claude Code
 */
export async function installHooksConfig(): Promise<void> {
  const claudeSettingsPath = path.join(os.homedir(), '.claude', 'settings.json');
  const claudeDir = path.dirname(claudeSettingsPath);

  // 确保 .claude 目录存在
  if (!fs.existsSync(claudeDir)) {
    fs.mkdirSync(claudeDir, { recursive: true });
  }

  // 读取现有配置
  let existingConfig: Record<string, any> = {};
  if (fs.existsSync(claudeSettingsPath)) {
    try {
      existingConfig = JSON.parse(fs.readFileSync(claudeSettingsPath, 'utf-8'));
    } catch {
      console.warn('无法解析现有配置，将创建新配置');
    }
  }

  // 合并 hooks 配置
  const hooksConfig = generateHooksConfig();
  const newConfig = {
    ...existingConfig,
    ...hooksConfig,
  };

  // 备份原配置
  if (fs.existsSync(claudeSettingsPath)) {
    const backupPath = claudeSettingsPath + '.backup';
    fs.copyFileSync(claudeSettingsPath, backupPath);
    console.log(`已备份原配置到: ${backupPath}`);
  }

  // 写入新配置
  fs.writeFileSync(claudeSettingsPath, JSON.stringify(newConfig, null, 2));
  console.log(`已安装 Hooks 配置到: ${claudeSettingsPath}`);
}

/**
 * 检查 Hooks 是否已配置
 */
export function checkHooksInstalled(): boolean {
  const claudeSettingsPath = path.join(os.homedir(), '.claude', 'settings.json');

  if (!fs.existsSync(claudeSettingsPath)) {
    return false;
  }

  try {
    const config = JSON.parse(fs.readFileSync(claudeSettingsPath, 'utf-8'));
    return config.hooks?.Stop !== undefined;
  } catch {
    return false;
  }
}

export { HOOK_SERVER_PORT };
