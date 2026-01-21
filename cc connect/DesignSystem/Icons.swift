//
//  Icons.swift
//  cc connect
//
//  Design System v2.0 - 图标系统
//  基于 SF Symbols，保持 iOS 原生体验
//

import SwiftUI

// MARK: - Icon Names

/// CC Connect 设计系统图标
enum CCIcon {

    // MARK: - Message Types (消息类型)

    /// Claude 消息
    static let claude = "sparkles"

    /// 用户输入
    static let userInput = "keyboard"

    /// 工具调用
    static let toolCall = "wrench.and.screwdriver"

    /// 工具结果
    static let toolResult = "checkmark.circle"

    /// 错误
    static let error = "exclamationmark.triangle"

    /// 系统消息
    static let system = "info.circle"

    /// 问题
    static let question = "bubble.left.and.bubble.right"

    // MARK: - Permissions (权限)

    /// 权限请求
    static let permission = "lock.shield"

    /// 允许
    static let allow = "checkmark.circle.fill"

    /// 拒绝
    static let deny = "xmark.circle.fill"

    /// 始终允许
    static let alwaysAllow = "checkmark.shield.fill"

    // MARK: - Status (状态)

    /// 已连接
    static let connected = "antenna.radiowaves.left.and.right"

    /// 运行中
    static let running = "bolt.fill"

    /// 等待输入
    static let waiting = "clock.fill"

    /// 空闲
    static let idle = "moon.fill"

    /// 断开连接
    static let disconnected = "antenna.radiowaves.left.and.right.slash"

    // MARK: - Actions (操作)

    /// 发送
    static let send = "arrow.up.circle.fill"

    /// 中断
    static let interrupt = "stop.circle.fill"

    /// 扫码
    static let scan = "qrcode.viewfinder"

    /// 复制
    static let copy = "doc.on.doc"

    /// 删除
    static let delete = "trash"

    /// 添加
    static let add = "plus.circle"

    /// 设置
    static let settings = "gearshape"

    /// 返回
    static let back = "chevron.left"

    /// 展开
    static let expand = "chevron.down"

    /// 收起
    static let collapse = "chevron.up"

    // MARK: - Navigation (导航)

    /// 会话列表
    static let sessions = "list.bullet"

    /// 历史记录
    static let history = "clock"

    /// 活跃
    static let active = "bolt.fill"

    // MARK: - Misc (其他)

    /// 空状态
    static let empty = "antenna.radiowaves.left.and.right"

    /// 品牌 Logo
    static let logo = "bolt.fill"

    /// 帮助
    static let help = "questionmark.circle"
}

// MARK: - Icon View

/// 统一的图标视图
struct CCIconView: View {
    let icon: String
    var size: CGFloat = CCSize.iconMD
    var color: Color = CCColor.textPrimary

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.6))
            .frame(width: size, height: size)
            .foregroundColor(color)
    }
}

// MARK: - Message Type Icon

/// 根据消息类型获取图标配置
struct MessageTypeIcon {
    let icon: String
    let color: Color

    static func forType(_ type: CCMessageType) -> MessageTypeIcon {
        switch type {
        case .claude:
            return MessageTypeIcon(icon: CCIcon.claude, color: CCColor.accentClaude)
        case .userInput:
            return MessageTypeIcon(icon: CCIcon.userInput, color: CCColor.accentPrimary)
        case .toolCall:
            return MessageTypeIcon(icon: CCIcon.toolCall, color: CCColor.accentInfo)
        case .toolResult:
            return MessageTypeIcon(icon: CCIcon.toolResult, color: CCColor.accentSuccess)
        case .toolError, .error:
            return MessageTypeIcon(icon: CCIcon.error, color: CCColor.accentDanger)
        case .question:
            return MessageTypeIcon(icon: CCIcon.question, color: CCColor.accentClaude)
        case .permissionRequest:
            return MessageTypeIcon(icon: CCIcon.permission, color: CCColor.accentWarning)
        case .system, .logo, .raw, .statusBar, .thinking, .taskStatus, .selectionDialog, .confirmation:
            return MessageTypeIcon(icon: CCIcon.system, color: CCColor.textSecondary)
        }
    }
}

// MARK: - Status Icon

/// 根据会话状态获取图标配置
struct StatusIcon {
    let icon: String
    let color: Color

    static func forStatus(_ status: SessionStatus) -> StatusIcon {
        switch status {
        case .running:
            return StatusIcon(icon: CCIcon.running, color: CCColor.accentSuccess)
        case .waiting:
            return StatusIcon(icon: CCIcon.waiting, color: CCColor.accentWarning)
        case .idle:
            return StatusIcon(icon: CCIcon.idle, color: CCColor.textTertiary)
        case .error:
            return StatusIcon(icon: CCIcon.error, color: CCColor.accentDanger)
        case .disconnected:
            return StatusIcon(icon: CCIcon.disconnected, color: CCColor.textDisabled)
        }
    }
}

// MARK: - Convenience Extensions

extension Image {
    /// 创建 CC 图标
    static func ccIcon(_ name: String) -> Image {
        Image(systemName: name)
    }
}

extension View {
    /// 应用图标样式
    func ccIconStyle(size: CGFloat = CCSize.iconMD, color: Color = CCColor.textPrimary) -> some View {
        self
            .font(.system(size: size * 0.6))
            .foregroundColor(color)
    }
}
