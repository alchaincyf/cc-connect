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

    var qrCodeData: String {
        "cc://\(sessionId):\(secret)"
    }

    static func parse(from qrCode: String) -> PairingInfo? {
        guard qrCode.hasPrefix("cc://") else { return nil }
        let data = String(qrCode.dropFirst(5))
        let parts = data.split(separator: ":")
        guard parts.count == 2 else { return nil }
        return PairingInfo(
            sessionId: String(parts[0]),
            secret: String(parts[1])
        )
    }
}

// WSMessage 定义已移至 Network/WebSocketManager.swift
