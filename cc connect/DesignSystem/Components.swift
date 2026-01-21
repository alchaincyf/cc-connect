//
//  Components.swift
//  cc connect
//
//  Design System v2.0 - 核心组件
//

import SwiftUI

// MARK: - Buttons

/// 主按钮
struct CCPrimaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var icon: String? = nil

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            HStack(spacing: CCSpacing.xs) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.9)
                }
                if let icon = icon, !isLoading {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.ccHeadline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: CCSize.buttonHeight)
            .background(isDisabled ? CCColor.textDisabled : CCColor.accentPrimary)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: CCRadius.sm))
        }
        .disabled(isDisabled || isLoading)
    }
}

/// 次要按钮
struct CCSecondaryButton: View {
    let title: String
    let action: () -> Void
    var icon: String? = nil

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            HStack(spacing: CCSpacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                }
                Text(title)
                    .font(.ccHeadline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: CCSize.buttonHeight)
            .background(CCColor.bgTertiary)
            .foregroundColor(CCColor.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: CCRadius.sm))
            .overlay(
                RoundedRectangle(cornerRadius: CCRadius.sm)
                    .stroke(CCColor.borderDefault, lineWidth: 1)
            )
        }
    }
}

/// 危险按钮
struct CCDangerButton: View {
    let title: String
    let action: () -> Void
    var icon: String? = nil

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        }) {
            HStack(spacing: CCSpacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.ccHeadline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: CCSize.buttonHeight)
            .background(CCColor.accentDanger)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: CCRadius.sm))
        }
    }
}

/// 快捷操作按钮（用于权限请求等）
struct CCQuickActionButton: View {
    let title: String
    let action: () -> Void
    var hotkey: String? = nil
    var style: ActionStyle = .default

    enum ActionStyle {
        case `default`
        case accept
        case reject
        case neutral
    }

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        }) {
            HStack(spacing: CCSpacing.xs) {
                if let hotkey = hotkey {
                    Text("[\(hotkey)]")
                        .font(.ccCaption)
                        .opacity(0.8)
                }
                Text(title)
                    .font(.ccHeadline)
            }
            .frame(height: CCSize.buttonHeightCompact)
            .frame(minWidth: CCSize.quickActionMinWidth)
            .padding(.horizontal, CCSpacing.lg)
            .background(backgroundColor)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: CCRadius.sm))
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .accept:
            return CCColor.accentSuccess
        case .reject:
            return CCColor.accentDanger
        case .neutral:
            return CCColor.bgTertiary
        case .default:
            return CCColor.accentPrimary
        }
    }
}

/// 文本按钮
struct CCTextButton: View {
    let title: String
    let action: () -> Void
    var color: Color = CCColor.accentPrimary

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.ccSubheadline)
                .foregroundColor(color)
        }
    }
}

// MARK: - Status Indicator

/// 连接状态指示器（带脉冲动画）
struct CCStatusIndicator: View {
    let status: SessionStatus
    var size: CGFloat = CCSize.statusDot

    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // 主圆点
            Circle()
                .fill(CCColor.statusColor(for: status))
                .frame(width: size, height: size)

            // 脉冲环（仅 running 和 waiting 状态）
            if status == .running || status == .waiting {
                Circle()
                    .stroke(CCColor.statusColor(for: status).opacity(0.5), lineWidth: 2)
                    .frame(width: size * 1.6, height: size * 1.6)
                    .scaleEffect(isAnimating ? 1.5 : 1)
                    .opacity(isAnimating ? 0 : 1)
            }
        }
        .onAppear {
            if status == .running || status == .waiting {
                withAnimation(
                    .easeOut(duration: 1)
                    .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
        }
        .onChange(of: status) { oldValue, newValue in
            if newValue == .running || newValue == .waiting {
                isAnimating = false
                withAnimation(
                    .easeOut(duration: 1)
                    .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            } else {
                isAnimating = false
            }
        }
    }
}

/// 连接状态徽章
struct CCConnectionBadge: View {
    let state: ConnectionState

    var body: some View {
        HStack(spacing: CCSpacing.xs) {
            Circle()
                .fill(statusColor)
                .frame(width: CCSize.statusDotSmall, height: CCSize.statusDotSmall)
            Text(statusText)
                .font(.ccCaption)
                .foregroundColor(CCColor.textSecondary)
        }
        .padding(.horizontal, CCSpacing.sm)
        .padding(.vertical, CCSpacing.xs)
        .background(CCColor.bgTertiary)
        .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch state {
        case .connected:
            return CCColor.accentSuccess
        case .connecting, .reconnecting:
            return CCColor.accentWarning
        case .disconnected, .failed:
            return CCColor.accentDanger
        }
    }

    private var statusText: String {
        switch state {
        case .connected:
            return "已连接"
        case .connecting:
            return "连接中"
        case .reconnecting(let attempt):
            return "重连(\(attempt))"
        case .disconnected:
            return "未连接"
        case .failed:
            return "失败"
        }
    }
}

// MARK: - Input Components

/// 聊天输入栏
struct CCChatInputBar: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    let onSend: () -> Void
    let onInterrupt: () -> Void

    var body: some View {
        HStack(spacing: CCSpacing.sm) {
            // 中断按钮
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onInterrupt()
            }) {
                Image(systemName: CCIcon.interrupt)
                    .font(.system(size: CCSize.interruptButtonSize))
                    .foregroundColor(CCColor.accentDanger.opacity(0.8))
            }

            // 输入框
            TextField("输入消息...", text: $text, axis: .vertical)
                .font(.ccBody)
                .padding(.horizontal, CCSpacing.inputPadding)
                .padding(.vertical, CCSpacing.sm)
                .background(CCColor.bgTertiary)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .focused(isFocused)
                .lineLimit(1...4)
                .onSubmit(onSend)

            // 发送按钮
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onSend()
            }) {
                Image(systemName: CCIcon.send)
                    .font(.system(size: CCSize.sendButtonSize))
                    .foregroundColor(text.isEmpty ? CCColor.textDisabled : CCColor.accentPrimary)
            }
            .disabled(text.isEmpty)
        }
        .padding(.horizontal, CCSpacing.lg)
        .padding(.vertical, CCSpacing.sm)
        .background(CCColor.bgPrimary)
    }
}

// MARK: - Cards

/// 代码块组件
struct CCCodeBlock: View {
    let code: String
    var language: String? = nil
    var fileName: String? = nil
    var lineNumbers: Bool = true
    var maxLines: Int = 10
    var onCopy: (() -> Void)? = nil

    @State private var isExpanded = false

    private var lines: [String] {
        code.components(separatedBy: "\n")
    }

    private var displayLines: [String] {
        if isExpanded || lines.count <= maxLines {
            return lines
        }
        return Array(lines.prefix(maxLines))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 头部
            if fileName != nil || onCopy != nil {
                HStack {
                    if let fileName = fileName {
                        Text(fileName)
                            .font(.ccCodeSmall)
                            .foregroundColor(CCColor.textSecondary)
                    }
                    Spacer()
                    if let onCopy = onCopy {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            onCopy()
                        }) {
                            HStack(spacing: CCSpacing.xxs) {
                                Image(systemName: CCIcon.copy)
                                Text("复制")
                            }
                            .font(.ccCaption)
                            .foregroundColor(CCColor.accentPrimary)
                        }
                    }
                }
                .padding(.horizontal, CCSpacing.sm)
                .padding(.vertical, CCSpacing.xs)
                .background(CCColor.bgTertiary)
            }

            // 代码内容
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 0) {
                    // 行号
                    if lineNumbers {
                        VStack(alignment: .trailing, spacing: 0) {
                            ForEach(Array(displayLines.enumerated()), id: \.offset) { index, _ in
                                Text("\(index + 1)")
                                    .font(.ccCodeXSmall)
                                    .foregroundColor(CCColor.terminalComment)
                                    .frame(minWidth: 30, alignment: .trailing)
                                    .padding(.trailing, CCSpacing.sm)
                            }
                        }
                        .padding(.vertical, CCSpacing.sm)

                        Divider()
                            .background(CCColor.borderMuted)
                    }

                    // 代码
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(displayLines.enumerated()), id: \.offset) { _, line in
                            Text(line.isEmpty ? " " : line)
                                .font(.ccCode)
                                .foregroundColor(CCColor.terminalText)
                        }
                    }
                    .padding(CCSpacing.sm)
                }
            }
            .background(CCColor.terminalBg)

            // 展开/收起
            if lines.count > maxLines {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack {
                        Spacer()
                        Text(isExpanded ? "收起" : "展开 \(lines.count) 行")
                            .font(.ccCaption)
                        Image(systemName: isExpanded ? CCIcon.collapse : CCIcon.expand)
                            .font(.ccCaption)
                        Spacer()
                    }
                    .foregroundColor(CCColor.accentPrimary)
                    .padding(.vertical, CCSpacing.xs)
                    .background(CCColor.bgTertiary)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: CCRadius.sm))
        .overlay(
            RoundedRectangle(cornerRadius: CCRadius.sm)
                .stroke(CCColor.borderMuted, lineWidth: 1)
        )
    }
}

/// 状态栏浮层
struct CCStatusOverlay: View {
    let text: String

    var body: some View {
        HStack(spacing: CCSpacing.sm) {
            ProgressView()
                .scaleEffect(0.8)
                .tint(CCColor.accentClaude)

            Text(text)
                .font(.ccCaption)
                .foregroundColor(CCColor.textSecondary)
        }
        .padding(.horizontal, CCSpacing.lg)
        .padding(.vertical, CCSpacing.sm)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
}

// MARK: - Utility Extensions

extension Date {
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// MARK: - Haptic Feedback

enum CCHaptic {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func heavy() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
