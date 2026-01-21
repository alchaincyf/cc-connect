# CC Connect

在手机上远程控制 Claude Code 的 CLI 工具。

## 功能

- 在终端启动 Claude Code 并生成配对二维码
- 通过 iOS App 扫码连接，实现远程控制
- 实时同步 Claude Code 的输出到手机
- 支持在手机上发送指令、处理权限请求

## 安装

```bash
npm install -g cc-connect
```

## 使用

```bash
# 启动会话（显示配对二维码）
cc start

# 自定义会话名称
cc start -n "我的项目"

# 使用自定义中继服务器
cc start -s "wss://your-relay-server.com"
```

## 配套 App

扫描二维码需要配套的 iOS App：**CC Connect**

App 功能：
- 扫码快速配对
- 实时查看 Claude Code 输出
- 远程发送指令
- 一键处理权限请求

## 工作原理

```
┌─────────────┐                      ┌─────────────┐
│   iOS App   │  ◄───── 同步 ──────► │   cc start  │
│             │      WebSocket       │             │
└─────────────┘                      └──────┬──────┘
       │                                    │ PTY
       │                             ┌──────▼──────┐
       ▼                             │ Claude Code │
┌─────────────┐                      └─────────────┘
│ 云端中继服务 │
└─────────────┘
```

1. `cc start` 启动 Claude Code，包装在 PTY 中
2. 解析输出为结构化消息，通过 WebSocket 发送
3. 云端中继服务转发消息到 iOS App
4. App 可发送指令回传到 CLI

## 系统要求

- Node.js >= 18.0.0
- 已安装 Claude Code (`npm install -g @anthropic/claude-code`)

## 许可证

MIT

## 作者

花叔 ([@alchaincyf](https://github.com/alchaincyf))
