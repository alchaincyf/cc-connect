# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## 构建命令

### iOS App
```bash
# 构建（Xcode 命令行）
xcodebuild -project "Peanut.xcodeproj" -scheme "Peanut" -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4' build

# 或直接用 Xcode 打开
open "Peanut.xcodeproj"
```

### CLI 工具 (cc-cli/)
```bash
# 全局安装
npm install -g peanut-cc@latest

# 安装 Hooks 配置（首次必须）
peanut install-hooks

# 启动会话（显示配对二维码）
peanut start

# 带参数运行
peanut start -n "会话名称" -s "wss://自定义服务器"

# 开发：重新编译 TypeScript
cd cc-cli && npm run build

# 本地开发测试
cd cc-cli && npm link
```

### 中继服务 (relay-server/)
```bash
cd relay-server
npm install          # 安装依赖
npm run dev          # 本地开发 (wrangler dev)
npm run deploy       # 部署到 Cloudflare Workers
npm run tail         # 查看实时日志
```

---

## 系统架构（v2 - 基于 Hooks）

```
┌─────────────┐                      ┌─────────────┐
│   iOS App   │  ◄───── 同步 ──────► │   CC CLI    │
│  (SwiftUI)  │      WebSocket       │  (Node.js)  │
└─────────────┘                      └──────┬──────┘
       │                                    │
       │                             ┌──────▼──────┐
       │ APNs                        │ Hook Server │ ◄── HTTP POST
       ▼                             │  (19789)    │
┌─────────────┐                      └──────┬──────┘
│ 云端中继服务 │                            │
│ (CF Workers)│                      ┌──────▼──────┐
└─────────────┘                      │ Claude Code │
                                     │   Hooks     │
                                     └─────────────┘
```

### 组件说明
- **iOS App**：SwiftUI 界面，展示输出、发送输入
- **CC CLI**：Node.js 工具，启动本地 Hook 服务器，接收 Claude Code 事件
- **Hook Server**：本地 HTTP 服务器（端口 19789），接收 Claude Code Hooks 事件
- **云端中继**：Cloudflare Workers + Durable Objects，WebSocket 路由和消息转发

### 核心改进：Hooks 架构

**v2 架构使用 Claude Code 官方的 Hooks API** 替代不可靠的 PTY 输出解析。

**优势**：
- 结构化 JSON 数据，不需要解析终端输出
- 准确的状态识别（Stop、Notification 事件）
- 可靠的权限请求检测（`permission_prompt` matcher）
- 官方支持，不受终端输出格式变化影响

---

## Claude Code Hooks 集成（重要）

### 架构原理

Claude Code 官方提供 Hooks 系统，在特定事件发生时触发自定义脚本。
我们利用这个机制获取结构化的状态信息，替代不可靠的 PTY 输出解析。

```
Claude Code 执行任务
    ↓ 触发 Hook 事件
Hook 脚本 (peanut-hook-notify)
    ↓ HTTP POST
CLI Hook Server (端口 19789)
    ↓ 处理事件
WebSocket 发送到手机
    ↓
iOS App 显示
```

### Hook 事件类型

| 事件 | 触发时机 | 用途 |
|------|----------|------|
| `Stop` | Claude 完成响应 | 知道何时发送完整消息 |
| `Notification` | 权限请求、空闲等 | 识别需要用户响应的状态 |
| `PreToolUse` | 工具调用前 | 获取工具调用信息 |
| `PostToolUse` | 工具调用后 | 获取工具结果 |
| `UserPromptSubmit` | 用户提交输入 | 记录用户输入 |

### Notification 子类型

| Matcher | 说明 |
|---------|------|
| `permission_prompt` | 权限请求（需要 y/n/a 响应） |
| `idle_prompt` | 空闲等待输入（60秒无操作） |
| `elicitation_dialog` | 选择对话（需要数字选择） |

### 安装 Hooks 配置

```bash
# 安装 CLI
npm install -g peanut-cc@latest

# 安装 Hooks 配置（推荐）
peanut install-hooks

# 查看配置内容
peanut install-hooks --show

# 检查安装状态
peanut check-hooks
```

安装后会在 `~/.claude/settings.json` 中添加 hooks 配置。

### Hooks 配置示例

```json
{
  "hooks": {
    "Stop": [{
      "hooks": [{
        "type": "command",
        "command": "peanut-hook-notify stop",
        "timeout": 5
      }]
    }],
    "Notification": [
      {
        "matcher": "permission_prompt",
        "hooks": [{
          "type": "command",
          "command": "peanut-hook-notify notification permission"
        }]
      }
    ],
    "PreToolUse": [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "peanut-hook-notify pre-tool"
      }]
    }]
  }
}
```

### CLI 端文件结构

```
cc-cli/src/
├── index.ts       # CLI 入口，命令: start, install-hooks, check-hooks
├── session.ts     # 会话管理，启动 Hook Server
├── hooks.ts       # Hook 服务器和事件处理
├── hook-notify.ts # Hook 脚本（被 Claude Code 调用）
├── websocket.ts   # WebSocket 客户端
└── parser.ts      # 备用解析器（Hooks 未配置时使用）
```

### 数据流

**Hooks 模式（推荐）**：
```
Claude Code Hook → peanut-hook-notify → HTTP POST → Hook Server → WebSocket → iOS
```

**备用模式（Hooks 未配置）**：
```
PTY 输出 → 简单解析 → WebSocket → iOS
```

---

## 代码架构

### iOS App (cc connect/)

**架构模式**：MVVM + @Observable Store

```
App/CCConnectApp.swift      # @main 入口，SwiftData 模型容器
Models/
  ├── Session.swift         # @Model 会话模型，SwiftData 持久化
  └── AppState.swift        # @Observable 全局状态单例
Network/
  └── WebSocketManager.swift # URLSession WebSocket，自动重连，消息解析
Views/
  ├── Onboarding/           # 首次启动流程、QR 码扫描
  ├── Session/              # 会话列表、聊天式详情页
  └── Settings/             # 设置页
DesignSystem/
  ├── Colors.swift          # 语义化配色（亮/暗自适应）
  ├── Typography.swift      # 字体系统
  └── Components.swift      # CCPrimaryButton 等可复用组件
```

**关键类型**：
- `Session` (@Model) - 会话数据，关联 `messages: [Message]`，支持 `liveConnectionState` 运行时状态
- `CCMessage` - 结构化消息，支持多种交互类型
- `CCMessageType` - 消息类型枚举，支持核心/状态/交互/系统四大类
- `InteractionOption` - 交互选项，支持快捷键、动作类型
- `ConnectionState` - 连接状态枚举：disconnected → connecting → connected → reconnecting

### CLI 工具 (cc-cli/src/)

```
index.ts       # Commander CLI 入口
               # 命令: start, install-hooks, check-hooks
session.ts     # 会话管理：启动 Hook Server + PTY，显示二维码
hooks.ts       # Hook 服务器（端口 19789）和事件处理
hook-notify.ts # Hook 脚本，被 Claude Code 调用
parser.ts      # 备用解析器（Hooks 未配置时使用）
websocket.ts   # WebSocket 客户端，自动重连，心跳
```

**CLI 命令**：
- `peanut start` - 启动会话，显示配对二维码
- `peanut install-hooks` - 安装 Claude Code Hooks 配置
- `peanut check-hooks` - 检查 Hooks 配置状态

**配对码格式**：`cc://<sessionId>:<secret>:<name>`

### 中继服务 (relay-server/src/)

```
index.ts      # Cloudflare Worker + SessionDO Durable Object
              # - WebSocket 路由: /ws/:sessionId
              # - 客户端标签: 'cli' 或 'app'
              # - 消息交叉转发
```

---

## 核心数据流

### Hooks 模式（推荐）

```
Claude Code 执行
    ↓ 触发 Hook 事件
peanut-hook-notify 脚本
    ↓ HTTP POST (JSON)
CLI hooks.ts 处理
    ↓ 转换为 ProcessedEvent
WebSocket 发送
    ↓
Cloudflare DO 转发
    ↓
iOS WebSocketManager 接收
    ↓ 更新 claudeState + messages
SwiftUI View 自动刷新
```

### 状态同步

```typescript
// CLI 发送的状态消息
{
  type: "status",
  status: "idle" | "working" | "waiting_permission" | "waiting_input",
  content: "状态描述"
}

// CLI 发送的消息
{
  type: "message",
  message: {
    type: "claude" | "permission_request" | ...,
    content: "消息内容",
    options?: [...],  // 交互选项
    tool?: {...}      // 工具信息
  }
}
```

**远程输入流程**：App 发送 `{"type":"input","text":"..."}` → 中继转发 → CLI `shell.write()`

---

## 消息类型系统 (v2)

### 设计原则
1. **开放性** - 消息类型使用字符串而非严格枚举，便于扩展
2. **前向兼容** - 未识别的输出以 `raw` 类型传递，不丢失信息
3. **交互支持** - 支持权限请求、选择对话、确认等交互类型
4. **颜色保留** - 保留 ANSI 颜色信息供客户端渲染

### 消息类型分类

| 分类 | 类型 | 说明 | 需要响应 |
|------|------|------|----------|
| **核心** | `claude` | Claude 的文本回复 | ❌ |
| | `user_input` | 用户输入 | ❌ |
| | `tool_call` | 工具调用 | ❌ |
| | `tool_result` | 工具结果 | ❌ |
| | `tool_error` | 工具错误 | ❌ |
| **状态** | `thinking` | 思考中 (Pondering...) | ❌ |
| | `status_bar` | 底部状态栏 | ❌ |
| | `task_status` | 任务状态更新 | ❌ |
| **交互** | `question` | 简单问题 | ✅ |
| | `permission_request` | 权限请求 | ✅ |
| | `selection_dialog` | 多选项对话 | ✅ |
| | `confirmation` | 确认对话 (y/n) | ✅ |
| **系统** | `system` | 系统消息 | ❌ |
| | `error` | 错误消息 | ❌ |
| | `logo` | Claude Code Logo | ❌ |
| | `raw` | 未识别的原始输出 | ❌ |

### 交互选项结构

```typescript
interface InteractionOption {
  id: string;             // 选项 ID
  label: string;          // 显示文本
  description?: string;   // 详细描述
  isDefault?: boolean;    // 是否默认选项
  actionType?: ActionType;// 动作类型
  hotkey?: string;        // 快捷键 (y/n/a)
}
```

### 动作类型映射

| ActionType | CLI 输入 | 说明 |
|------------|----------|------|
| `accept` | `y` | 接受/允许 |
| `reject` | `n` | 拒绝/取消 |
| `always_allow` | `a` | 始终允许 |
| `always_deny` | `d` | 始终拒绝 |
| `skip` | `\n` | 跳过 |
| `select` | `{id}` | 选择选项 |

---

## 模块路由

| 模块 | 路径 | 职责 |
|------|------|------|
| App | `cc connect/App/` | 应用入口 |
| Views | `cc connect/Views/` | 页面视图 |
| Models | `cc connect/Models/` | 数据模型（SwiftData） |
| Network | `cc connect/Network/` | WebSocket 通信 |
| DesignSystem | `cc connect/DesignSystem/` | 设计系统 |
| CLI | `cc-cli/src/` | Node.js 命令行工具 |
| 中继 | `relay-server/src/` | Cloudflare Workers |

---

## 文档索引

| 需要了解 | 去读这个文件 |
|----------|-------------|
| 产品需求 | `docs/03-PRD.md` |
| 技术架构详情 | `docs/04-技术设计.md` |
| 页面设计 | `docs/design/02-核心页面线框图.md` |
| 竞品分析 | `docs/research/竞品深度分析报告.md` |
| 消息类型定义 | `cc-cli/src/parser.ts` |
| iOS 消息结构 | `cc connect/Network/WebSocketManager.swift` |
| 交互组件 | `cc connect/Views/Session/SwiftTermView.swift` |

---

## 开发规范

### 技术栈
- **iOS**：SwiftUI + SwiftData（iOS 17+）
- **网络**：URLSession WebSocket（原生）
- **CLI**：Node.js 18+ + TypeScript + node-pty
- **中继**：Cloudflare Workers + Durable Objects

### 代码风格
- Swift：async/await 优先，类型明确，少用强制解包
- TypeScript：严格模式

### 国际化
```swift
Text(String(localized: "key_name"))
```
支持：zh-Hans、en

---

## 核心原则

1. **不过度设计**：解决当前问题，不为假想需求写代码
2. **不破坏现有功能**：改动前理解上下文，确保编译通过
3. **不硬编码敏感信息**：API Key 放配置文件或环境变量
4. **不跳过用户确认**：重大改动必须先确认

---

## 常见问题排查（重要）

### 问题：App 收不到 Claude Code 的回复

**排查步骤**：

1. **检查 Hook 服务器端口是否被占用**
   ```bash
   lsof -i :19789
   # 如果有进程占用，杀掉它：
   kill -9 $(lsof -t -i:19789)
   ```

2. **检查 Hooks 配置是否使用正确的脚本名**
   ```bash
   grep "hook-notify" ~/.claude/settings.json
   # 应该显示 "peanut-hook-notify"，不是 "peanut-hook-notify"
   # 如果是旧名称，重新安装：
   peanut install-hooks
   ```

3. **检查 Hooks 是否已安装**
   ```bash
   peanut check-hooks
   ```

4. **检查 WebSocket 连接**
   - App 日志应该显示 "✅ WebSocket 已连接"
   - CLI 应该显示 "[已连接] 手机客户端已配对"

### 问题：端口 19789 被占用

**原因**：上次 `peanut start` 没有正常退出，进程残留。

**解决**：
```bash
kill -9 $(lsof -t -i:19789)
# 或
pkill -f "peanut"
```

### 问题：品牌重命名后消息不同步

**原因**：用户的 Hooks 配置仍然引用旧脚本名 `peanut-hook-notify`。

**解决**：
```bash
peanut install-hooks
```

### 关键代码逻辑

**消息同步的两种模式**：

1. **Hooks 模式（推荐）**
   - 条件：`checkHooksInstalled() == true` 且 `hookServerRunning == true`
   - 流程：Claude Code → Hooks → peanut-hook-notify → HTTP POST → Hook Server → WebSocket → App

2. **备用模式（PTY 解析）**
   - 条件：Hooks 未配置 或 Hook 服务器未启动
   - 流程：PTY 输出 → fallbackStateDetection() → WebSocket → App

**关键检查点**：
```typescript
// session.ts 中的备用模式判断
const hooksInstalled = checkHooksInstalled();
if (hooksInstalled && hookServerRunning) {
  return; // 使用 Hooks 模式，跳过备用检测
}
// 否则使用备用模式
```

**`checkHooksInstalled()` 逻辑**：
1. 检查 `~/.claude/settings.json` 是否存在
2. 检查是否有 `hooks.Stop` 配置
3. **重要**：检查配置是否使用正确的脚本名 `peanut-hook-notify`
4. 如果使用旧脚本名 `peanut-hook-notify`，返回 `false` 以启用备用模式

### 开发时的注意事项

1. **修改 relay-server 要极其谨慎**
   - Cloudflare Durable Objects 的 WebSocket 状态管理很敏感
   - 不要在 `acceptWebSocket()` 之前关闭连接
   - 消息转发逻辑要简单，避免异步竞态

2. **重命名后要更新所有引用**
   - package.json 的 bin 命令
   - hooks.ts 的 `getHookScriptPath()`
   - `checkHooksInstalled()` 中的脚本名检查
   - README、App 引导页的命令示例

3. **测试消息同步问题时**
   - 先检查端口占用
   - 再检查 Hooks 配置
   - 最后才考虑代码问题

---

## 当前状态

| 项目 | 内容 |
|------|------|
| **阶段** | Phase 3 开发 - 性能优化完成 |
| **进度** | v1.3.0 性能优化 + Bug 修复 |
| **上次决策** | 优化消息列表性能，修复重复连接 Bug |

### 最新完成 (2026-01-27)

**v1.3.0 - 性能优化 & Bug 修复**

- ✅ **修复重复会话/WebSocket 连接 Bug**
  - `ScanView.swift` - 扫码前检查是否已存在相同 ID 的会话，存在则更新而非新建
  - `SessionDetailView.swift` - 添加 `hasConnected` 标志防止重复连接
  - `WebSocketManager.swift` - 连接前检查是否已连接同一会话，断开时清理会话引用

- ✅ **消息列表性能优化**
  - 历史消息跳过动画（`skipAnimation` 参数）
  - 新消息动画时长从 0.3s 减少到 0.2s
  - 移除 Claude 消息指示条的渐变和阴影效果
  - 移除错误消息行的阴影效果
  - 滚动动画从 0.25s 减少到 0.15s

- ✅ **智能滚动优化**
  - 进入会话时自动滚动到底部（无动画）
  - 历史消息首次加载完成后滚动到底部
  - 只有新消息到达时才触发带动画的滚动
  - 使用 `hasScrolledToBottom` 状态避免重复滚动

- ✅ **新 App 图标**
  - 使用 lovlogo 生成的金属质感花生图标
  - 尺寸 1024x1024，压缩至 358KB

- ✅ **强制深色模式**
  - `CCConnectApp.swift` 添加 `.preferredColorScheme(.dark)`
  - 玻璃拟态效果在深色模式下表现更佳

### Design System v4.0 - Glassmorphism 玻璃拟态

- ✅ **Colors.swift** - 深邃科技黑背景 + 玻璃效果色 + 发光色系统
- ✅ **Glass View Modifiers** - `.glassBackground()`, `.glassCard()`, `.glowBorder()`
- ✅ **MessageComponents.swift** - 玻璃消息组件 + 简化的出现动画
- ✅ **Components.swift** - 玻璃核心组件（简化边框设计）
- ✅ **SessionListView/DetailView** - 玻璃列表页和详情页

### 之前版本

**v1.2.x** - 品牌统一 (Peanut)、Hooks 兼容性修复、端口占用提示
**v1.1.x** - Hooks 架构、Markdown 渲染、Bug 修复
**v1.0.x** - 初始版本，PTY 解析模式

### 架构要点

**CLI 端 Hooks 模式处理流程**
```
Claude Code Hook 事件
    ↓ peanut-hook-notify 脚本
HTTP POST → hooks.ts Hook Server
    ↓ processHookEvent()
转换为 ProcessedEvent
    ↓ handleHookEvent()
WebSocket 发送 status/message
```

**CLI 端备用模式**
```
PTY 输出 → fallbackStateDetection()
         → 简单的提示符检测
         → 发送基本消息
```

**iOS 端消息处理**
```
收到 status → 更新 claudeState + statusBarText
收到 message → parseAndAddMessage() → messages.append()
交互类型 → 设置 currentInteraction + claudeState
```

---

## Claude Code 参考资料

### 官方文档
| 资料 | URL | 说明 |
|------|-----|------|
| 概览 | https://code.claude.com/docs/en/overview | Claude Code 整体介绍 |
| 交互模式 | https://code.claude.com/docs/en/interactive-mode | 键盘快捷键、权限模式 |
| CLI 参考 | https://code.claude.com/docs/en/cli-reference | 命令行参数、输出格式 |
| Hooks | https://code.claude.com/docs/en/hooks | 钩子系统、消息结构 |
| GitHub | https://github.com/anthropics/claude-code | 源码仓库 |

### 关键交互模式

**权限模式** (`Shift+Tab` 切换)
- `default` - 标准确认
- `plan` - 计划模式，执行前审批
- `acceptEdits` - 自动接受编辑
- `dontAsk` - 不询问
- `bypassPermissions` - 绕过权限

**Hooks 事件类型**
| 事件 | 触发时机 | 用途 |
|------|----------|------|
| `PreToolUse` | 工具执行前 | 拦截/修改工具调用 |
| `PostToolUse` | 工具执行后 | 处理结果 |
| `PermissionRequest` | 权限对话框 | 自定义权限处理 |
| `Notification` | 通知发送时 | `permission_prompt`, `elicitation_dialog` |
| `UserPromptSubmit` | 用户提交 | 验证/修改输入 |
| `Stop` | 任务结束 | 结束处理 |

**工具类型**
```
Bash, Write, Edit, Read, Glob, Grep,
WebFetch, WebSearch, Task, TodoWrite,
mcp__<server>__<tool>  # MCP 工具
```

### 终端输出格式

```
⏺ Claude 消息        # Claude 回复
⏺ Read(path)        # 工具调用
└ Read 254 lines    # 工具结果
└ Error ...         # 错误
❯ 用户输入           # 输入提示
· 任务状态...        # 当前任务
⏵⏵ status bar       # 状态栏
? Allow/Deny        # 权限请求
1) 选项一            # 选择对话
```

---

## 偏好记录

### 产品偏好
- 极简上手方向，不需要端到端加密
- 完整留档开发过程
- 聊天气泡形式，移动端友好

### 代码偏好
- 消息类型使用字符串保持开放性
- 未知类型前向兼容，不丢失信息
- 交互选项结构化，支持快捷键

### 适配策略
- 工具识别使用通用正则 `(\w+)\(`，自动支持新工具
- 消息类型可扩展，添加新 case 即可
- 保留 `raw` 字段用于调试

---

## CLI 状态检测（备用模式）

> **注意**：v1.1.0 开始主要使用 Hooks 架构获取状态。
> 以下内容是 Hooks 未配置时的备用模式。

### 思考状态检测

Claude Code 使用多种有趣词汇表示思考状态：

```typescript
const thinkingKeywords = [
  'Composing', 'Thinking', 'Pondering', 'Processing',
  'Finagling', 'Schlepping', 'Brewing', 'Levitating',
  'Analyzing', 'Writing', 'Reading', 'Editing'
  // ... 更多词汇
];
```

### 备用模式处理逻辑

备用模式使用简化的 PTY 解析：
1. 检测提示符 `❯` → 表示 Claude 完成响应
2. 检测 `⏺` 开头 → Claude 消息
3. 检测思考关键词 → 发送状态更新

### 消息分类

| 分类 | 发送类型 | 效果 |
|------|----------|------|
| `thinking` 等状态 | `status` | 更新状态栏，不加入消息列表 |
| `claude`, `tool_call` 等 | `message` | 添加到消息列表 |

---

## iOS 选项响应机制

### 选择对话响应

选择对话的选项需要发送**数字**（1, 2, 3）到终端，不是 opt_id。

```swift
// WebSocketManager.swift
func respondToInteraction(option: InteractionOption) {
    if option.actionType == .select {
        // 优先使用 hotkey（数字）
        input = option.hotkey ?? option.id
    }
}
```

**选项结构**：
- `hotkey` 字段存储数字（"1", "2", "3"）
- `actionType` 为 `.select` 时使用 hotkey
- 回车键选择默认选项

---

## MUJI 设计规范

### 色彩系统

| 用途 | 深色模式 | 浅色模式 |
|------|----------|----------|
| 背景主色 | #121212 | #FAFAFA |
| 背景次色 | #1A1A1A | #FFFFFF |
| 强调色（Claude） | #D4A574 淡木色 | #8B7355 深木色 |
| 成功色 | #7CAE7A | #5D8A5B |

### 视觉风格

- 用 2px 细线替代图标作为消息类型指示器
- 大量留白（xxxl: 56pt, xxxxl: 72pt）
- 去除多余装饰，强调内容本身

---

## npm 发布流程

### Token 配置

Token 存储在两个位置（都已加入 .gitignore）：

1. **项目级 `.env`** - 备份记录
   ```bash
   NPM_TOKEN=npm_xxx...
   ```

2. **cc-cli/.npmrc** - 实际使用
   ```
   //registry.npmjs.org/:_authToken=npm_xxx...
   ```

### 发布命令

```bash
cd cc-cli

# 方式一：使用项目 .npmrc（推荐）
# 先确保 .npmrc 文件存在且包含正确 token
npm publish --access public

# 方式二：一次性创建 .npmrc 并发布
echo "//registry.npmjs.org/:_authToken=TOKEN_HERE" > .npmrc
npm publish --access public
```

### 版本更新流程

```bash
cd cc-cli

# 1. 修改 package.json 中的 version
# 2. 编译并发布
npm run build
npm publish --access public
```

### 当前版本

- **包名**: peanut-cc
- **最新版本**: 1.2.2
- **安装命令**: `npm install -g peanut-cc@latest`
- **首次配置**: `peanut install-hooks`（必须）
- **可执行文件**: `peanut`, `peanut-hook-notify`

---

**创作者**：花叔
