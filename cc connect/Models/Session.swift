//
//  Session.swift
//  cc connect
//
//  Created by alchain on 2026/1/21.
//

import Foundation
import SwiftData

// MARK: - Session Status
enum SessionStatus: String, Codable {
    case running = "running"
    case waiting = "waiting"
    case idle = "idle"
    case error = "error"
    case disconnected = "disconnected"

    var displayText: String {
        switch self {
        case .running:
            return "运行中"
        case .waiting:
            return "等待输入"
        case .idle:
            return "空闲"
        case .error:
            return "错误"
        case .disconnected:
            return "已断开"
        }
    }
}

// MARK: - Message Type (持久化用)
enum MessageType: String, Codable {
    case claude = "claude"      // Claude 回复
    case userInput = "user_input" // 用户输入
    case toolCall = "tool_call"   // 工具调用
    case toolResult = "tool_result" // 工具结果
    case system = "system"        // 系统消息
    case error = "error"          // 错误
    case raw = "raw"              // 其他
}

// MARK: - 运行时连接状态（不持久化）
enum LiveConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case reconnecting(attempt: Int)
    case failed(String)
}

// MARK: - Claude Code 工作状态（基于 Hooks 架构）
enum ClaudeState: Equatable {
    case idle               // 等待用户输入
    case working            // 正在工作/思考
    case waitingPermission  // 等待权限确认
    case waitingInput       // 等待用户选择/输入

    var displayText: String {
        switch self {
        case .idle: return "等待输入"
        case .working: return "处理中..."
        case .waitingPermission: return "需要确认权限"
        case .waitingInput: return "等待响应"
        }
    }

    var isActive: Bool {
        self == .working
    }
}

// MARK: - Session Model
@Model
final class Session {
    @Attribute(.unique) var id: String
    var name: String
    var status: SessionStatus
    var lastActivity: Date
    var isConnected: Bool
    var deviceName: String?
    var secret: String?

    @Relationship(deleteRule: .cascade, inverse: \Message.session)
    var messages: [Message] = []

    /// 运行时连接状态（不持久化）
    @Transient var liveConnectionState: LiveConnectionState = .disconnected

    /// 待发送的启动命令（扫码后设置，连接后发送）
    @Transient var pendingStartupCommand: String?

    /// Claude 是否正在思考（不持久化）
    @Transient var isThinking: Bool = false

    /// Claude 工作状态（基于 Hooks，不持久化）
    @Transient var claudeState: ClaudeState = .idle

    /// 是否活跃连接
    var isActive: Bool {
        if case .connected = liveConnectionState {
            return true
        }
        if case .reconnecting = liveConnectionState {
            return true
        }
        return false
    }

    /// 最近一条消息预览（用于列表显示）
    var lastMessagePreview: String? {
        // 找最近的 claude 或 user_input 消息
        let relevantMessages = messages
            .filter { $0.type == .claude || $0.type == .userInput }
            .sorted { $0.timestamp > $1.timestamp }

        guard let lastMessage = relevantMessages.first else { return nil }

        // 截取前 50 个字符，移除换行
        let content = lastMessage.content
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if content.count > 50 {
            return String(content.prefix(50)) + "..."
        }
        return content.isEmpty ? nil : content
    }

    init(
        id: String = UUID().uuidString,
        name: String = "新会话",
        status: SessionStatus = .disconnected,
        lastActivity: Date = Date(),
        isConnected: Bool = false,
        deviceName: String? = nil,
        secret: String? = nil
    ) {
        self.id = id
        self.name = name
        self.status = status
        self.lastActivity = lastActivity
        self.isConnected = isConnected
        self.deviceName = deviceName
        self.secret = secret
    }
}

// MARK: - Message Model
@Model
final class Message {
    var id: String
    var type: MessageType
    var content: String
    var timestamp: Date

    var session: Session?

    init(
        id: String = UUID().uuidString,
        type: MessageType,
        content: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.content = content
        self.timestamp = timestamp
    }
}

// MARK: - Pairing Info (Not persisted)
struct PairingInfo: Codable {
    let sessionId: String
    let secret: String
    let sessionName: String?  // 会话名称（可选，从工作目录提取）

    var qrCodeData: String {
        if let name = sessionName {
            let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name
            return "cc://\(sessionId):\(secret):\(encoded)"
        }
        return "cc://\(sessionId):\(secret)"
    }

    /// 解析配对码
    /// 格式: cc://sessionId:secret 或 cc://sessionId:secret:name
    static func parse(from qrCode: String) -> PairingInfo? {
        guard qrCode.hasPrefix("cc://") else { return nil }
        let data = String(qrCode.dropFirst(5))
        let parts = data.split(separator: ":", maxSplits: 2, omittingEmptySubsequences: false)
        guard parts.count >= 2 else { return nil }

        let sessionId = String(parts[0])
        let secret = String(parts[1])

        // 解析可选的会话名称
        var sessionName: String? = nil
        if parts.count >= 3 {
            let encodedName = String(parts[2])
            sessionName = encodedName.removingPercentEncoding ?? encodedName
        }

        return PairingInfo(
            sessionId: sessionId,
            secret: secret,
            sessionName: sessionName
        )
    }
}

// WSMessage 定义已移至 Network/WebSocketManager.swift
