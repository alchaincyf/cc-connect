//
//  Components.swift
//  cc connect
//
//  Design System v4.0 - Glassmorphism 玻璃拟态核心组件
//

import SwiftUI

// MARK: - Buttons

/// 主按钮 - 玻璃发光效果
struct CCPrimaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var icon: String? = nil

    var body: some View {
        Button(action: {
            CCHaptic.light()
            action()
        }) {
            HStack(spacing: CCSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.9)
                }
                if let icon = icon, !isLoading {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                }
                Text(title)
                    .font(.ccHeadline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: CCSize.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: CCRadius.lg)
                    .fill(
                        LinearGradient(
                            colors: isDisabled
                                ? [CCColor.textDisabled, CCColor.textDisabled]
                                : [CCColor.accentPrimary, CCColor.accentPrimary.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .foregroundColor(.white)
            .overlay(
                RoundedRectangle(cornerRadius: CCRadius.lg)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.3), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: isDisabled ? Color.clear : CCColor.glowPrimary, radius: 12, x: 0, y: 4)
        }
        .disabled(isDisabled || isLoading)
    }
}

/// 次要按钮 - 玻璃边框
struct CCSecondaryButton: View {
    let title: String
    let action: () -> Void
    var icon: String? = nil

    var body: some View {
        Button(action: {
            CCHaptic.light()
            action()
        }) {
            HStack(spacing: CCSpacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                }
                Text(title)
                    .font(.ccHeadline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: CCSize.buttonHeight)
            .foregroundColor(CCColor.textPrimary)
            .glassBackground(cornerRadius: CCRadius.lg)
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
            CCHaptic.medium()
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
            .background(
                RoundedRectangle(cornerRadius: CCRadius.md)
                    .fill(CCColor.accentDanger.opacity(0.2))
            )
            .foregroundColor(CCColor.accentDanger)
            .overlay(
                RoundedRectangle(cornerRadius: CCRadius.md)
                    .stroke(CCColor.accentDanger.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: CCColor.accentDanger.opacity(0.2), radius: 8, x: 0, y: 2)
        }
    }
}

/// 快捷操作按钮
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
            CCHaptic.medium()
            action()
        }) {
            HStack(spacing: CCSpacing.xs) {
                if let hotkey = hotkey {
                    Text("[\(hotkey)]")
                        .font(.ccCaption)
                        .opacity(0.7)
                }
                Text(title)
                    .font(.ccHeadline)
            }
            .frame(height: CCSize.buttonHeightCompact)
            .frame(minWidth: CCSize.quickActionMinWidth)
            .padding(.horizontal, CCSpacing.lg)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: CCRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: CCRadius.md)
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(color: shadowColor, radius: 6, x: 0, y: 2)
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .accept:
            return CCColor.accentSuccess.opacity(0.2)
        case .reject:
            return CCColor.accentDanger.opacity(0.2)
        case .neutral:
            return CCColor.glassBg
        case .default:
            return CCColor.accentPrimary.opacity(0.2)
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .accept:
            return CCColor.accentSuccess
        case .reject:
            return CCColor.accentDanger
        case .neutral:
            return CCColor.textSecondary
        case .default:
            return CCColor.accentPrimary
        }
    }

    private var borderColor: Color {
        switch style {
        case .accept:
            return CCColor.accentSuccess.opacity(0.3)
        case .reject:
            return CCColor.accentDanger.opacity(0.3)
        case .neutral:
            return CCColor.glassBorder
        case .default:
            return CCColor.accentPrimary.opacity(0.3)
        }
    }

    private var shadowColor: Color {
        switch style {
        case .accept:
            return CCColor.glowSuccess.opacity(0.3)
        case .reject:
            return CCColor.accentDanger.opacity(0.2)
        case .neutral:
            return Color.clear
        case .default:
            return CCColor.glowPrimary.opacity(0.3)
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

/// 连接状态指示器（带发光脉冲动画）
struct CCStatusIndicator: View {
    let status: SessionStatus
    var size: CGFloat = CCSize.statusDot

    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // 发光层
            if status == .running || status == .waiting {
                Circle()
                    .fill(CCColor.statusGlowColor(for: status))
                    .frame(width: size * 2, height: size * 2)
                    .blur(radius: 8)
                    .scaleEffect(isAnimating ? 1.2 : 0.8)
                    .opacity(isAnimating ? 0.6 : 0.3)
            }

            // 主圆点
            Circle()
                .fill(CCColor.statusColor(for: status))
                .frame(width: size, height: size)

            // 脉冲环
            if status == .running || status == .waiting {
                Circle()
                    .stroke(CCColor.statusColor(for: status).opacity(0.5), lineWidth: 1.5)
                    .frame(width: size * 1.8, height: size * 1.8)
                    .scaleEffect(isAnimating ? 1.5 : 1)
                    .opacity(isAnimating ? 0 : 0.8)
            }
        }
        .onAppear {
            if status == .running || status == .waiting {
                withAnimation(
                    .easeInOut(duration: 1.2)
                    .repeatForever(autoreverses: true)
                ) {
                    isAnimating = true
                }
            }
        }
        .onChange(of: status) { oldValue, newValue in
            if newValue == .running || newValue == .waiting {
                isAnimating = false
                withAnimation(
                    .easeInOut(duration: 1.2)
                    .repeatForever(autoreverses: true)
                ) {
                    isAnimating = true
                }
            } else {
                isAnimating = false
            }
        }
    }
}

/// 连接状态徽章 - 简洁胶囊
struct CCConnectionBadge: View {
    let state: ConnectionState

    var body: some View {
        HStack(spacing: CCSpacing.xs) {
            Circle()
                .fill(statusColor)
                .frame(width: CCSize.statusDotSmall, height: CCSize.statusDotSmall)
                .shadow(color: statusColor.opacity(0.6), radius: 4, x: 0, y: 0)

            Text(statusText)
                .font(.ccCaption)
                .foregroundColor(CCColor.textSecondary)
        }
        .padding(.horizontal, CCSpacing.sm)
        .padding(.vertical, 6)
        .background(CCColor.bgTertiary.opacity(0.6))
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

/// 聊天输入栏 - 简洁设计
struct CCChatInputBar: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    let onSend: () -> Void
    let onInterrupt: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 顶部细线分隔
            Rectangle()
                .fill(CCColor.borderMuted)
                .frame(height: 0.5)

            HStack(spacing: CCSpacing.sm) {
                // 中断按钮 - 简洁无边框
                Button(action: {
                    CCHaptic.medium()
                    onInterrupt()
                }) {
                    Image(systemName: CCIcon.interrupt)
                        .font(.system(size: 16))
                        .foregroundColor(CCColor.textTertiary)
                        .frame(width: 32, height: 32)
                        .background(CCColor.bgTertiary.opacity(0.5))
                        .clipShape(Circle())
                }

                // 输入框 - 简洁无边框
                TextField("输入消息...", text: $text, axis: .vertical)
                    .font(.ccBody)
                    .foregroundColor(CCColor.textPrimary)
                    .focused(isFocused)
                    .lineLimit(1...4)
                    .padding(.horizontal, CCSpacing.md)
                    .padding(.vertical, CCSpacing.sm)
                    .background(CCColor.bgTertiary.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: CCRadius.lg))
                    .onSubmit(onSend)

                // 发送按钮 - 简洁设计
                Button(action: {
                    CCHaptic.light()
                    onSend()
                }) {
                    Image(systemName: CCIcon.send)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(text.isEmpty ? CCColor.textDisabled : .white)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(text.isEmpty ? CCColor.bgTertiary.opacity(0.5) : CCColor.accentPrimary)
                        )
                        .shadow(color: text.isEmpty ? Color.clear : CCColor.glowPrimary.opacity(0.4), radius: 8, x: 0, y: 2)
                }
                .disabled(text.isEmpty)
            }
            .padding(.horizontal, CCSpacing.md)
            .padding(.vertical, CCSpacing.sm)
        }
        .background(CCColor.bgSecondary)
    }
}

// MARK: - Cards

/// 代码块组件 - 终端风格
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
                        HStack(spacing: CCSpacing.xs) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 10))
                            Text(fileName)
                                .font(.ccCodeSmall)
                        }
                        .foregroundColor(CCColor.textTertiary)
                    }
                    Spacer()
                    if let onCopy = onCopy {
                        Button(action: {
                            CCHaptic.light()
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
                .padding(.horizontal, CCSpacing.md)
                .padding(.vertical, CCSpacing.xs)
                .background(CCColor.bgTertiary.opacity(0.5))
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

                        Rectangle()
                            .fill(CCColor.borderMuted)
                            .frame(width: 1)
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
                    .background(CCColor.bgTertiary.opacity(0.5))
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: CCRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: CCRadius.md)
                .stroke(CCColor.borderMuted, lineWidth: 1)
        )
    }
}

/// 状态栏浮层 - 玻璃胶囊
struct CCStatusOverlay: View {
    let text: String

    var body: some View {
        HStack(spacing: CCSpacing.sm) {
            // 脉冲点
            CCPulsingDots()

            Text(text)
                .font(.ccCaption)
                .foregroundColor(CCColor.textSecondary)
        }
        .padding(.horizontal, CCSpacing.lg)
        .padding(.vertical, CCSpacing.sm)
        .glassBackground(cornerRadius: CCRadius.full)
        .shadow(color: CCColor.glassShadow.opacity(0.2), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Thinking Indicator

/// Claude 思考状态指示器
struct CCThinkingIndicator: View {
    @State private var animationPhase = 0

    var body: some View {
        HStack(spacing: CCSpacing.sm) {
            // 左侧发光指示线
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [CCColor.accentClaude, CCColor.accentClaude.opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 3)
                .shadow(color: CCColor.glowClaude, radius: 6, x: 0, y: 0)

            // 脉冲点动画
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(CCColor.accentClaude)
                        .frame(width: 6, height: 6)
                        .opacity(animationPhase == index ? 1.0 : 0.3)
                        .shadow(color: animationPhase == index ? CCColor.glowClaude : Color.clear, radius: 4, x: 0, y: 0)
                }
            }

            Spacer()
        }
        .frame(height: 24)
        .padding(.vertical, CCSpacing.xs)
        .padding(.horizontal, CCSpacing.sm)
        .glassBackground(cornerRadius: CCRadius.lg)
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.15)) {
                    animationPhase = (animationPhase + 1) % 3
                }
            }
        }
    }
}

/// 脉冲点动画
struct CCPulsingDots: View {
    @State private var animationPhase = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(CCColor.accentClaude)
                    .frame(width: 5, height: 5)
                    .opacity(animationPhase == index ? 1.0 : 0.3)
                    .shadow(color: animationPhase == index ? CCColor.glowClaude : Color.clear, radius: 3, x: 0, y: 0)
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.2)) {
                    animationPhase = (animationPhase + 1) % 3
                }
            }
        }
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
