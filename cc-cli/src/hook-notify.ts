#!/usr/bin/env node
/**
 * cc-hook-notify - Claude Code Hook 通知脚本
 *
 * 这个脚本由 Claude Code 的 Hooks 系统调用，
 * 将事件转发到 cc-cli 的本地 HTTP 服务器。
 *
 * 用法:
 *   cc-hook-notify <event-type> [sub-type]
 *
 * 事件类型:
 *   stop              - Claude 完成响应
 *   notification      - 通知事件（需要 sub-type: permission/idle/elicitation）
 *   pre-tool          - 工具调用前
 *   post-tool         - 工具调用后
 *   user-prompt       - 用户提交输入
 *
 * Claude Code 通过 stdin 传递 JSON 数据。
 */

import * as http from 'http';

const HOOK_SERVER_PORT = 19789;
const HOOK_SERVER_HOST = '127.0.0.1';

/**
 * 从 stdin 读取 JSON 数据
 */
async function readStdin(): Promise<string> {
  return new Promise((resolve) => {
    let data = '';
    process.stdin.setEncoding('utf-8');

    // 设置超时，避免无限等待
    const timeout = setTimeout(() => {
      resolve(data);
    }, 1000);

    process.stdin.on('data', (chunk) => {
      data += chunk;
    });

    process.stdin.on('end', () => {
      clearTimeout(timeout);
      resolve(data);
    });

    // 如果 stdin 是 TTY（没有管道输入），立即返回
    if (process.stdin.isTTY) {
      clearTimeout(timeout);
      resolve('{}');
    }
  });
}

/**
 * 发送事件到本地 Hook 服务器
 */
async function sendEvent(data: object): Promise<void> {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify(data);

    const options = {
      hostname: HOOK_SERVER_HOST,
      port: HOOK_SERVER_PORT,
      path: '/hook',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData),
      },
      timeout: 3000,
    };

    const req = http.request(options, (res) => {
      res.on('data', () => {});
      res.on('end', () => {
        resolve();
      });
    });

    req.on('error', (err) => {
      // 服务器可能未启动，静默失败
      resolve();
    });

    req.on('timeout', () => {
      req.destroy();
      resolve();
    });

    req.write(postData);
    req.end();
  });
}

/**
 * 主函数
 */
async function main() {
  const args = process.argv.slice(2);
  const eventType = args[0];
  const subType = args[1];

  if (!eventType) {
    console.error('用法: cc-hook-notify <event-type> [sub-type]');
    process.exit(1);
  }

  // 读取 Claude Code 传递的 JSON 数据
  const stdinData = await readStdin();

  let inputData: Record<string, any> = {};
  try {
    if (stdinData.trim()) {
      inputData = JSON.parse(stdinData);
    }
  } catch {
    // 无法解析 JSON，使用空对象
  }

  // 补充事件类型信息
  switch (eventType) {
    case 'stop':
      inputData.hook_event_name = 'Stop';
      break;
    case 'notification':
      inputData.hook_event_name = 'Notification';
      if (subType === 'permission') {
        inputData.notification_type = 'permission_prompt';
      } else if (subType === 'idle') {
        inputData.notification_type = 'idle_prompt';
      } else if (subType === 'elicitation') {
        inputData.notification_type = 'elicitation_dialog';
      }
      break;
    case 'pre-tool':
      inputData.hook_event_name = 'PreToolUse';
      break;
    case 'post-tool':
      inputData.hook_event_name = 'PostToolUse';
      break;
    case 'user-prompt':
      inputData.hook_event_name = 'UserPromptSubmit';
      break;
    default:
      console.error(`未知事件类型: ${eventType}`);
      process.exit(1);
  }

  // 发送到本地服务器
  await sendEvent(inputData);

  // 正常退出
  process.exit(0);
}

main().catch((err) => {
  console.error('Hook 脚本错误:', err);
  process.exit(1);
});
