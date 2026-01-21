# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## 构建命令

### iOS App
```bash
# 构建（Xcode 命令行）
xcodebuild -project "cc connect.xcodeproj" -scheme "cc connect" -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build

# 或直接用 Xcode 打开
open "cc connect.xcodeproj"
```

### CLI 工具 (cc-cli/)
```bash
# 运行（会显示配对二维码）
node cc-cli/dist/index.js start

# 带参数运行
node cc-cli/dist/index.js start -n "会话名称" -s "wss://自定义服务器"

# 开发：重新编译 TypeScript
cd cc-cli && npm run build
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

## 系统架构

```
┌─────────────┐                      ┌─────────────┐
│   iOS App   │  ◄───── 同步 ──────► │   CC CLI    │
│  (SwiftUI)  │      WebSocket       │  (Node.js)  │
└─────────────┘                      └──────┬──────┘
       │                                    │ PTY包装
       │ APNs                        ┌──────▼──────┐
       ▼                             │ Claude Code │
┌─────────────┐                      └─────────────┘
│ 云端中继服务 │
│ (CF Workers)│
└─────────────┘
```

### 组件说明
- **iOS App**：SwiftUI 界面，展示输出、发送输入
- **CC CLI**：Node.js 工具，PTY 包装 Claude Code，解析输出为结构化消息
- **云端中继**：Cloudflare Workers + Durable Objects，WebSocket 路由和消息转发

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
index.ts      # Commander CLI 入口，命令: cc start [-n name] [-s server]
session.ts    # 会话管理：生成 sessionId/secret，启动 PTY，显示二维码
parser.ts     # 输出解析器 v2：支持交互类型、颜色保留、开放扩展
websocket.ts  # WebSocket 客户端，自动重连，心跳
```

**配对码格式**：`cc://<sessionId>:<secret>`

### 中继服务 (relay-server/src/)

```
index.ts      # Cloudflare Worker + SessionDO Durable Object
              # - WebSocket 路由: /ws/:sessionId
              # - 客户端标签: 'cli' 或 'app'
              # - 消息交叉转发
```

---

## 核心数据流

```
Claude Code 输出
    ↓ node-pty 捕获
CLI parser.ts 解析为 CCMessage
    ↓ WebSocket
Cloudflare DO 转发
    ↓ WebSocket
iOS WebSocketManager 接收
    ↓ @Published messages
SwiftUI View 自动刷新
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

## 当前状态

| 项目 | 内容 |
|------|------|
| **阶段** | Phase 3 开发 - 设计系统重构完成 |
| **进度** | 设计系统 v2.0 完成，待编译验证 |
| **上次决策** | 完整重构交互和视觉设计 |

### 最新完成 (2026-01-21)

**设计系统 v2.0 重构（核心改进）**
- ✅ **色彩系统重构** - GitHub Dark 风格，深色优先，自适应亮/暗模式
- ✅ **字体系统重构** - 界面字体 + 代码字体完整规范
- ✅ **间距系统** - 4pt 基础网格，语义化命名
- ✅ **图标系统** - SF Symbols 统一映射
- ✅ **核心组件** - 按钮、状态指示器、输入栏、代码块
- ✅ **消息组件** - IDE 风格消息行（非聊天气泡）
- ✅ **权限请求 Sheet** - 强制弹出，视觉突出
- ✅ **页面重构** - 会话列表、会话详情、引导页

**设计亮点**
- Claude 品牌色：#CA8A04（琥珀金）
- 权限请求使用 Sheet 强制打断
- 触觉反馈（Haptic Feedback）全面支持
- 向后兼容旧组件 API

**设计文档**
- 完整规范：`docs/design/00-设计系统规范.md`

### 待完成
- [ ] Xcode 编译验证
- [ ] 深色/浅色模式测试
- [ ] 真机测试体验
- [ ] 细节打磨和调整

### 架构要点

**CLI 端消息处理流程**
```
PTY 输出 → rawOutputBuffer 累积
         → 300ms 稳定窗口（或遇到 ❯ 提示符 50ms）
         → resetParser() + parseOutput() + flushBuffer()
         → mergeMessages() 合并连续同类型
         → 过滤噪音 + 分类（可发送/状态）
         → 发送 message 或 status 类型到 iOS
```

**iOS 端消息处理**
```
收到 message → parseAndAddMessage() → messages.append() + persistMessage()
收到 status → 只更新 statusBarText
进入会话 → loadHistoryMessages() 从 SwiftData 加载
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

**创作者**：花叔
