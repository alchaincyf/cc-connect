import Foundation
import Combine
import SwiftUI

/// WebSocket 连接状态
enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case reconnecting(attempt: Int)
    case failed(String)
}

// MARK: - 消息类型系统 (可扩展设计)
// 注意: ClaudeState 定义在 Session.swift 中

/// Claude Code 消息类型 - 使用字符串保持开放性
/// 核心类型有明确定义，未知类型可通过 rawValue 传递
enum CCMessageType: String, Codable, CaseIterable {
    // 核心消息类型
    case claude             // Claude 的文本回复
    case userInput = "user_input"  // 用户输入
    case toolCall = "tool_call"    // 工具调用
    case toolResult = "tool_result" // 工具结果
    case toolError = "tool_error"  // 工具错误

    // 状态类型
    case thinking           // 思考中
    case statusBar = "status_bar"  // 状态栏
    case taskStatus = "task_status" // 任务状态

    // 交互类型 - 需要用户响应
    case question           // 简单问题
    case permissionRequest = "permission_request" // 权限请求
    case selectionDialog = "selection_dialog"     // 选择对话
    case confirmation       // 确认对话

    // 系统类型
    case system             // 系统消息
    case error              // 错误消息
    case logo               // Claude Code Logo
    case raw                // 未识别的原始输出

    /// 是否需要用户响应
    var requiresResponse: Bool {
        switch self {
        case .question, .permissionRequest, .selectionDialog, .confirmation:
            return true
        default:
            return false
        }
    }

    /// 是否是交互类型
    var isInteractive: Bool {
        requiresResponse
    }
}

/// 用户动作类型
enum ActionType: String, Codable {
    case accept         // 接受/允许
    case reject         // 拒绝/取消
    case select         // 选择选项
    case input          // 输入文本
    case skip           // 跳过
    case alwaysAllow = "always_allow"   // 始终允许
    case alwaysDeny = "always_deny"     // 始终拒绝

    /// 对应的 CLI 输入
    var cliInput: String {
        switch self {
        case .accept: return "y"
        case .reject: return "n"
        case .alwaysAllow: return "a"
        case .alwaysDeny: return "d"
        case .skip: return "\n"
        case .select, .input: return ""
        }
    }
}

/// 交互选项
struct InteractionOption: Codable, Identifiable, Equatable {
    var id: String
    var label: String
    var description: String?
    var isDefault: Bool?
    var actionType: ActionType?
    var hotkey: String?

    init(id: String, label: String, description: String? = nil, isDefault: Bool? = nil, actionType: ActionType? = nil, hotkey: String? = nil) {
        self.id = id
        self.label = label
        self.description = description
        self.isDefault = isDefault
        self.actionType = actionType
        self.hotkey = hotkey
    }
}

/// 工具信息
struct ToolInfo: Codable, Equatable {
    var name: String
    var args: String?
    var filePath: String?
    var command: String?
    var description: String?
}

/// 权限请求信息
struct PermissionInfo: Codable, Equatable {
    var tool: String?
    var action: String?
    var resource: String?
    var risk: String? // low, medium, high
}

/// ANSI 颜色类型
enum ANSIColor: String, Codable {
    case red, green, yellow, blue, magenta, cyan, white, gray

    var swiftUIColor: Color {
        switch self {
        case .red: return .red
        case .green: return .green
        case .yellow: return .yellow
        case .blue: return .blue
        case .magenta: return .purple
        case .cyan: return .cyan
        case .white: return .primary
        case .gray: return .gray
        }
    }
}

/// 颜色标记
struct ColorHint: Codable, Equatable {
    let start: Int
    let end: Int
    let color: ANSIColor
}

// MARK: - 核心消息结构

/// 结构化消息 - 从 CLI 接收
struct CCMessage: Codable, Identifiable, Equatable {
    // 必需字段
    let id: UUID
    let type: CCMessageType
    let content: String
    let timestamp: Int64

    // 工具相关
    var tool: ToolInfo?

    // 交互相关
    var requiresResponse: Bool?
    var interactionOptions: [InteractionOption]?
    var permission: PermissionInfo?
    var defaultAction: ActionType?
    var timeout: Int?

    // 显示相关
    var colorHints: [ColorHint]?
    var isLogo: Bool?
    var thinkingPhase: String?

    // 兼容旧字段
    var toolName: String?
    var filePath: String?
    var options: [String]?

    // 元数据
    var metadata: [String: String]?
    var raw: String?

    init(
        id: UUID = UUID(),
        type: CCMessageType,
        content: String,
        timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        tool: ToolInfo? = nil,
        requiresResponse: Bool? = nil,
        interactionOptions: [InteractionOption]? = nil,
        permission: PermissionInfo? = nil,
        colorHints: [ColorHint]? = nil,
        isLogo: Bool? = nil,
        thinkingPhase: String? = nil,
        toolName: String? = nil,
        filePath: String? = nil,
        options: [String]? = nil
    ) {
        self.id = id
        self.type = type
        self.content = content
        self.timestamp = timestamp
        self.tool = tool
        self.requiresResponse = requiresResponse
        self.interactionOptions = interactionOptions
        self.permission = permission
        self.colorHints = colorHints
        self.isLogo = isLogo
        self.thinkingPhase = thinkingPhase
        self.toolName = toolName
        self.filePath = filePath
        self.options = options
    }

    /// 是否需要用户交互
    var needsUserAction: Bool {
        requiresResponse == true || type.requiresResponse
    }

    /// 获取可用的交互选项
    var availableOptions: [InteractionOption] {
        // 优先使用 interactionOptions
        if let opts = interactionOptions, !opts.isEmpty {
            return opts
        }
        // 兼容旧的 options 字段
        if let opts = options {
            return opts.enumerated().map { index, label in
                InteractionOption(id: "opt_\(index)", label: label)
            }
        }
        // 根据类型返回默认选项
        switch type {
        case .confirmation:
            return [
                InteractionOption(id: "yes", label: "是", actionType: .accept, hotkey: "y"),
                InteractionOption(id: "no", label: "否", actionType: .reject, hotkey: "n")
            ]
        case .permissionRequest:
            return [
                InteractionOption(id: "allow", label: "允许", actionType: .accept, hotkey: "y"),
                InteractionOption(id: "deny", label: "拒绝", actionType: .reject, hotkey: "n"),
                InteractionOption(id: "always", label: "始终允许", actionType: .alwaysAllow, hotkey: "a")
            ]
        case .question:
            return [
                InteractionOption(id: "yes", label: "是", actionType: .accept),
                InteractionOption(id: "no", label: "否", actionType: .reject),
                InteractionOption(id: "continue", label: "继续", actionType: .skip)
            ]
        default:
            return []
        }
    }

    static func == (lhs: CCMessage, rhs: CCMessage) -> Bool {
        lhs.id == rhs.id
    }
}

/// WebSocket 管理器
@MainActor
class WebSocketManager: NSObject, ObservableObject {
    @Published var connectionState: ConnectionState = .disconnected {
        didSet {
            syncToSession()
        }
    }
    @Published var messages: [CCMessage] = []
    @Published var currentInteraction: CCMessage? = nil  // 当前需要响应的交互（问题/权限/选择）
    @Published var statusBarText: String? = nil          // 状态栏文本（如 Thinking...）
    @Published var isThinking: Bool = false              // Claude 是否正在思考
    @Published var claudeState: ClaudeState = .idle      // Claude 工作状态（基于 Hooks）

    /// 兼容旧属性名
    var currentQuestion: CCMessage? {
        get { currentInteraction }
        set { currentInteraction = newValue }
    }

    private var webSocket: URLSessionWebSocketTask?

    /// 最近发送的用户输入，用于去重
    private var recentUserInputs: [String] = []
    private let maxRecentInputs = 10
    private var urlSession: URLSession?
    private var pingTimer: Timer?
    private var reconnectAttempt = 0
    private let maxReconnectAttempts = 5

    private var sessionId: String = ""
    private var secret: String = ""
    private var serverURL: String = ""

    /// 关联的会话（用于状态同步和消息持久化）
    weak var session: Session?

    /// 连接到中继服务器
    func connect(serverURL: String, sessionId: String, secret: String, session: Session? = nil) {
        self.serverURL = serverURL
        self.sessionId = sessionId
        self.secret = secret
        self.reconnectAttempt = 0
        self.session = session

        // 加载历史消息
        loadHistoryMessages()

        performConnect()
    }

    /// 从 SwiftData 加载历史消息
    private func loadHistoryMessages() {
        guard let session = session else { return }

        // 将 SwiftData Message 转换为 CCMessage
        let sortedMessages = session.messages.sorted { $0.timestamp < $1.timestamp }
        messages = sortedMessages.map { msg in
            CCMessage(
                type: ccMessageType(from: msg.type),
                content: msg.content,
                timestamp: Int64(msg.timestamp.timeIntervalSince1970 * 1000)
            )
        }
        print("📚 加载了 \(messages.count) 条历史消息")
    }

    /// 将 MessageType 转换为 CCMessageType
    private func ccMessageType(from type: MessageType) -> CCMessageType {
        switch type {
        case .claude: return .claude
        case .userInput: return .userInput
        case .toolCall: return .toolCall
        case .toolResult: return .toolResult
        case .system: return .system
        case .error: return .error
        case .raw: return .raw
        }
    }

    /// 将 CCMessageType 转换为 MessageType
    private func messageType(from type: CCMessageType) -> MessageType {
        switch type {
        case .claude: return .claude
        case .userInput: return .userInput
        case .toolCall: return .toolCall
        case .toolResult: return .toolResult
        case .system: return .system
        case .error: return .error
        default: return .raw
        }
    }

    /// 保存消息到 SwiftData
    private func persistMessage(_ ccMessage: CCMessage) {
        guard let session = session else { return }

        let message = Message(
            id: ccMessage.id.uuidString,
            type: messageType(from: ccMessage.type),
            content: ccMessage.content,
            timestamp: Date(timeIntervalSince1970: TimeInterval(ccMessage.timestamp) / 1000)
        )
        message.session = session
        session.messages.append(message)
        session.lastActivity = Date()
    }

    private func performConnect() {
        connectionState = reconnectAttempt > 0 ? .reconnecting(attempt: reconnectAttempt) : .connecting

        let urlString = "\(serverURL)/ws/\(sessionId)?token=\(secret)&type=app"

        print("🔌 连接 WebSocket: \(urlString)")

        guard let url = URL(string: urlString) else {
            connectionState = .failed("Invalid URL")
            return
        }

        urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        webSocket = urlSession?.webSocketTask(with: url)
        webSocket?.resume()

        receiveMessage()
        startPingTimer()
    }

    /// 发送用户输入到 CLI
    func sendInput(_ text: String) {
        print("📤 发送: \(text)")

        // 记录到最近输入列表，用于过滤回显
        recentUserInputs.append(text)
        if recentUserInputs.count > maxRecentInputs {
            recentUserInputs.removeFirst()
        }

        // 添加到本地消息列表并持久化
        let userMessage = CCMessage(type: .userInput, content: text)
        messages.append(userMessage)
        persistMessage(userMessage)

        // 发送到服务器
        let message: [String: Any] = [
            "type": "input",
            "text": text
        ]

        if let data = try? JSONSerialization.data(withJSONObject: message),
           let string = String(data: data, encoding: .utf8) {
            webSocket?.send(.string(string)) { error in
                if let error = error {
                    print("❌ 发送失败: \(error)")
                }
            }
        }

        // 清除当前交互状态
        currentInteraction = nil
    }

    /// 响应交互（选择选项）
    func respondToInteraction(option: InteractionOption) {
        // 根据选项类型生成输入
        let input: String
        if let actionType = option.actionType {
            if actionType == .select {
                // 选择类型：优先使用 hotkey（数字），其次 id
                input = option.hotkey ?? option.id
            } else if actionType.cliInput.isEmpty {
                // 其他类型 cliInput 为空时用 hotkey 或 id
                input = option.hotkey ?? option.id
            } else {
                input = actionType.cliInput
            }
        } else if let hotkey = option.hotkey {
            input = hotkey
        } else {
            input = option.id
        }

        print("📤 响应交互: \(option.label) -> \(input)")

        // 添加用户响应到消息列表
        let userMessage = CCMessage(type: .userInput, content: option.label)
        messages.append(userMessage)

        // 发送到服务器
        let message: [String: Any] = [
            "type": "input",
            "text": input
        ]

        if let data = try? JSONSerialization.data(withJSONObject: message),
           let string = String(data: data, encoding: .utf8) {
            webSocket?.send(.string(string)) { error in
                if let error = error {
                    print("❌ 发送响应失败: \(error)")
                }
            }
        }

        // 清除当前交互
        currentInteraction = nil
    }

    /// 发送动作响应
    func respondWithAction(_ action: ActionType, optionId: String? = nil) {
        let input = action.cliInput.isEmpty ? (optionId ?? "") : action.cliInput
        sendInput(input)
    }

    /// 发送中断信号
    func sendInterrupt() {
        print("🛑 发送中断信号")
        let message: [String: Any] = ["type": "interrupt"]

        if let data = try? JSONSerialization.data(withJSONObject: message),
           let string = String(data: data, encoding: .utf8) {
            webSocket?.send(.string(string)) { _ in }
        }
    }

    /// 断开连接
    func disconnect() {
        stopPingTimer()
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
        urlSession = nil
        connectionState = .disconnected
    }

    /// 清空消息
    func clearMessages() {
        messages.removeAll()
        currentInteraction = nil
    }

    /// 同步状态到关联的会话
    private func syncToSession() {
        guard let session = session else { return }

        switch connectionState {
        case .disconnected:
            session.liveConnectionState = .disconnected
        case .connecting:
            session.liveConnectionState = .connecting
        case .connected:
            session.liveConnectionState = .connected
        case .reconnecting(let attempt):
            session.liveConnectionState = .reconnecting(attempt: attempt)
        case .failed(let reason):
            session.liveConnectionState = .failed(reason)
        }
    }

    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                switch result {
                case .success(let message):
                    switch message {
                    case .string(let text):
                        self.handleMessage(text)
                    case .data(let data):
                        if let text = String(data: data, encoding: .utf8) {
                            self.handleMessage(text)
                        }
                    @unknown default:
                        break
                    }
                    self.receiveMessage()

                case .failure(let error):
                    print("❌ WebSocket 接收错误: \(error)")
                    self.handleDisconnect()
                }
            }
        }
    }

    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else {
            return
        }

        switch type {
        case "message":
            // 新格式：结构化消息
            if let messageData = json["message"] as? [String: Any] {
                parseAndAddMessage(messageData)
            }

        case "paired":
            print("🎉 已配对!")
            let msg = CCMessage(type: .system, content: "已连接到 Claude Code")
            messages.append(msg)

        case "cli_disconnected":
            connectionState = .failed("CLI 已断开")
            let msg = CCMessage(type: .system, content: "CLI 连接已断开")
            messages.append(msg)

        case "pong":
            break // 心跳响应，忽略

        case "ping":
            // 服务器发来的 ping，回复 pong
            webSocket?.send(.string("{\"type\":\"pong\"}")) { _ in }

        case "status":
            // 状态更新（基于 Hooks 架构）
            if let statusType = json["status"] as? String {
                switch statusType {
                case "idle":
                    claudeState = .idle
                    isThinking = false
                    session?.isThinking = false
                case "working", "thinking":
                    claudeState = .working
                    isThinking = true
                    session?.isThinking = true
                case "waiting_permission":
                    claudeState = .waitingPermission
                    isThinking = false
                case "waiting_input":
                    claudeState = .waitingInput
                    isThinking = false
                default:
                    break
                }
            }
            if let content = json["content"] as? String, !content.isEmpty {
                statusBarText = content
                print("📊 状态: \(content.prefix(50))")
            }

        default:
            print("⚠️ 未知消息类型: \(type)")
        }
    }

    private func parseAndAddMessage(_ data: [String: Any]) {
        guard let typeStr = data["type"] as? String,
              let content = data["content"] as? String else {
            return
        }

        // 尝试解析类型，未知类型使用 .raw
        let type = CCMessageType(rawValue: typeStr) ?? .raw

        // 过滤重复的用户输入消息（PTY 回显）
        if type == .userInput {
            if recentUserInputs.contains(content) {
                print("🔄 过滤重复用户输入: \(content.prefix(30))")
                return
            }
        }

        // 过滤思考状态关键词消息（不应该作为消息显示）
        let thinkingKeywords = ["Moseying", "Thinking", "Pondering", "Processing",
                                "Composing", "Analyzing", "Writing", "Reading",
                                "Brewing", "Levitating", "Finagling", "Schlepping"]
        let contentLower = content.lowercased()
        let isThinkingMessage = thinkingKeywords.contains { keyword in
            contentLower.hasPrefix(keyword.lowercased()) &&
            content.trimmingCharacters(in: .whitespacesAndNewlines).count < 30
        }
        if isThinkingMessage && type == .raw {
            print("🔄 过滤思考状态消息: \(content)")
            return
        }

        let timestamp = data["timestamp"] as? Int64 ?? Int64(Date().timeIntervalSince1970 * 1000)
        let requiresResponse = data["requiresResponse"] as? Bool
        let isLogo = data["isLogo"] as? Bool
        let thinkingPhase = data["thinkingPhase"] as? String

        // 解析工具信息
        var tool: ToolInfo? = nil
        if let toolData = data["tool"] as? [String: Any] {
            tool = ToolInfo(
                name: toolData["name"] as? String ?? "",
                args: toolData["args"] as? String,
                filePath: toolData["filePath"] as? String,
                command: toolData["command"] as? String,
                description: toolData["description"] as? String
            )
        }

        // 解析交互选项
        var interactionOptions: [InteractionOption]? = nil
        if let optionsData = data["options"] as? [[String: Any]] {
            interactionOptions = optionsData.compactMap { opt -> InteractionOption? in
                guard let id = opt["id"] as? String,
                      let label = opt["label"] as? String else { return nil }
                return InteractionOption(
                    id: id,
                    label: label,
                    description: opt["description"] as? String,
                    isDefault: opt["isDefault"] as? Bool,
                    actionType: (opt["actionType"] as? String).flatMap { ActionType(rawValue: $0) },
                    hotkey: opt["hotkey"] as? String
                )
            }
        }

        // 兼容旧的 options 字段（字符串数组）
        let legacyOptions = data["options"] as? [String]

        // 解析颜色标记
        var colorHints: [ColorHint]? = nil
        if let colorData = data["colorHints"] as? [[String: Any]] {
            colorHints = colorData.compactMap { hint -> ColorHint? in
                guard let start = hint["start"] as? Int,
                      let end = hint["end"] as? Int,
                      let colorStr = hint["color"] as? String,
                      let color = ANSIColor(rawValue: colorStr) else {
                    return nil
                }
                return ColorHint(start: start, end: end, color: color)
            }
        }

        // 解析权限信息
        var permission: PermissionInfo? = nil
        if let permData = data["permission"] as? [String: Any] {
            permission = PermissionInfo(
                tool: permData["tool"] as? String,
                action: permData["action"] as? String,
                resource: permData["resource"] as? String,
                risk: permData["risk"] as? String
            )
        }

        // 状态栏消息 - 更新状态栏文本而不添加到消息列表
        if type == .statusBar {
            statusBarText = content
            print("📊 状态栏更新: \(content)")
            return
        }

        // 思考状态 - 更新状态栏和思考标志
        if type == .thinking {
            statusBarText = thinkingPhase ?? content
            isThinking = true
            session?.isThinking = true
            print("💭 思考中: \(thinkingPhase ?? content)")
            return
        }

        // 构建消息
        let message = CCMessage(
            type: type,
            content: content,
            timestamp: timestamp,
            tool: tool,
            requiresResponse: requiresResponse,
            interactionOptions: interactionOptions,
            permission: permission,
            colorHints: colorHints,
            isLogo: isLogo,
            thinkingPhase: thinkingPhase,
            toolName: tool?.name ?? (data["toolName"] as? String),
            filePath: tool?.filePath ?? (data["filePath"] as? String),
            options: legacyOptions
        )

        // 如果是交互类型，设置当前交互
        if type.requiresResponse || requiresResponse == true {
            currentInteraction = message
            // 更新 Claude 状态
            if type == .permissionRequest {
                claudeState = .waitingPermission
            } else {
                claudeState = .waitingInput
            }
            print("🔔 需要用户响应: \(type.rawValue)")
        }

        // 非思考/状态栏消息时，清除状态栏和思考标志，更新为空闲状态
        statusBarText = nil
        isThinking = false
        session?.isThinking = false
        // 如果不是交互消息，设置为空闲状态
        if !type.requiresResponse && requiresResponse != true {
            claudeState = .idle
        }

        messages.append(message)
        persistMessage(message)

        print("📨 收到消息: [\(type.rawValue)] \(content.prefix(50))...")
    }

    private func handleDisconnect() {
        stopPingTimer()

        if reconnectAttempt < maxReconnectAttempts {
            reconnectAttempt += 1
            connectionState = .reconnecting(attempt: reconnectAttempt)

            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.performConnect()
            }
        } else {
            connectionState = .failed("连接失败，请重试")
        }
    }

    private func startPingTimer() {
        stopPingTimer()
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sendPing()
            }
        }
    }

    private func stopPingTimer() {
        pingTimer?.invalidate()
        pingTimer = nil
    }

    private func sendPing() {
        webSocket?.send(.string("{\"type\":\"ping\"}")) { _ in }
    }
}

extension WebSocketManager: URLSessionWebSocketDelegate {
    nonisolated func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        print("✅ WebSocket 已连接")
        Task { @MainActor in
            self.connectionState = .connected
            self.reconnectAttempt = 0

            // 发送待处理的启动命令（如果有）
            if let command = self.session?.pendingStartupCommand {
                print("🚀 发送启动命令: \(command)")
                // 延迟一小段时间确保连接稳定
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.sendInput(command)
                    self.session?.pendingStartupCommand = nil
                }
            }
        }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        print("⚠️ WebSocket 已断开")
        Task { @MainActor in
            self.handleDisconnect()
        }
    }
}
