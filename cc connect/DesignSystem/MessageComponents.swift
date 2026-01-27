//
//  MessageComponents.swift
//  cc connect
//
//  Design System v4.0 - Glassmorphism 玻璃拟态消息组件
//  科技感、层次感、现代感
//

import SwiftUI

// MARK: - Message Row

/// 消息行路由
struct CCMessageRow: View {
    let message: CCMessage
    var skipAnimation: Bool = false  // 历史消息跳过动画

    var body: some View {
        switch message.type {
        case .logo:
            CCLogoView()
        case .userInput:
            CCUserMessageRow(message: message, skipAnimation: skipAnimation)
        case .toolCall:
            CCToolCallRow(message: message)
        case .toolResult:
            CCToolResultRow(message: message)
        case .toolError, .error:
            CCErrorRow(message: message)
        case .system:
            CCSystemRow(message: message)
        default:
            CCClaudeMessageRow(message: message, skipAnimation: skipAnimation)
        }
    }
}

// MARK: - Claude Message Row

/// Claude 消息 - 玻璃卡片 + 左侧发光指示条
struct CCClaudeMessageRow: View {
    let message: CCMessage
    var skipAnimation: Bool = false  // 历史消息跳过动画
    @State private var isVisible = false

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // 左侧发光指示条
            RoundedRectangle(cornerRadius: 2)
                .fill(CCColor.accentClaude)
                .frame(width: 3)

            // 内容区域
            VStack(alignment: .leading, spacing: CCSpacing.sm) {
                CCMarkdownView(content: message.content, textColor: CCColor.textPrimary)
            }
            .padding(.horizontal, CCSpacing.md)
            .padding(.vertical, CCSpacing.sm)

            Spacer(minLength: 0)
        }
        .padding(.vertical, CCSpacing.xs)
        .padding(.horizontal, CCSpacing.sm)
        .glassBackground(cornerRadius: CCRadius.lg)
        .opacity(skipAnimation || isVisible ? 1 : 0)
        .offset(y: skipAnimation || isVisible ? 0 : 10)
        .onAppear {
            guard !skipAnimation else { return }
            withAnimation(.easeOut(duration: 0.2)) {
                isVisible = true
            }
        }
    }
}

// MARK: - User Message Row

/// 用户消息 - 右对齐蓝色气泡（无边框，更简洁）
struct CCUserMessageRow: View {
    let message: CCMessage
    var skipAnimation: Bool = false  // 历史消息跳过动画
    @State private var isVisible = false

    var body: some View {
        HStack {
            Spacer(minLength: 60)

            Text(message.content)
                .font(.ccBody)
                .foregroundColor(.white)
                .textSelection(.enabled)
                .lineSpacing(4)
                .padding(.horizontal, CCSpacing.lg)
                .padding(.vertical, CCSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: CCRadius.lg)
                        .fill(CCColor.accentPrimary.opacity(0.85))
                )
        }
        .padding(.vertical, CCSpacing.xs)
        .opacity(skipAnimation || isVisible ? 1 : 0)
        .offset(y: skipAnimation || isVisible ? 0 : 10)
        .onAppear {
            guard !skipAnimation else { return }
            withAnimation(.easeOut(duration: 0.2)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Tool Call Row

/// 工具调用 - 紧凑玻璃卡片
struct CCToolCallRow: View {
    let message: CCMessage
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: CCSpacing.xs) {
            HStack(spacing: CCSpacing.sm) {
                // 工具图标
                Image(systemName: "terminal.fill")
                    .font(.system(size: 12))
                    .foregroundColor(CCColor.terminalFunction)

                // 工具名称
                Text(message.toolName ?? "Tool")
                    .font(.ccCodeSmall)
                    .fontWeight(.medium)
                    .foregroundColor(CCColor.terminalFunction)

                // 文件路径
                if let filePath = message.filePath {
                    Text(filePath)
                        .font(.ccCodeSmall)
                        .foregroundColor(CCColor.textTertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()

                // 展开按钮
                if message.content.count > 50 {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(CCColor.textTertiary)
                }
            }

            // 命令/代码内容
            if !message.content.isEmpty {
                Text(message.content)
                    .font(.ccCodeSmall)
                    .foregroundColor(CCColor.terminalText)
                    .lineLimit(isExpanded ? nil : 2)
            }
        }
        .padding(.horizontal, CCSpacing.md)
        .padding(.vertical, CCSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CCRadius.md)
                .fill(CCColor.terminalBg.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: CCRadius.md)
                .stroke(CCColor.borderMuted, lineWidth: 1)
        )
        .onTapGesture {
            if message.content.count > 50 {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }
        }
    }
}

// MARK: - Tool Result Row

/// 工具结果 - 缩进显示
struct CCToolResultRow: View {
    let message: CCMessage
    @State private var isExpanded = false

    var body: some View {
        HStack(alignment: .top, spacing: CCSpacing.sm) {
            // 返回箭头
            Image(systemName: "arrow.turn.down.right")
                .font(.system(size: 10))
                .foregroundColor(CCColor.accentSuccess)

            // 结果内容
            Text(message.content)
                .font(.ccCodeSmall)
                .foregroundColor(CCColor.textSecondary)
                .lineLimit(isExpanded ? nil : 2)
                .textSelection(.enabled)

            Spacer(minLength: 0)
        }
        .padding(.leading, CCSpacing.lg)
        .padding(.vertical, CCSpacing.xs)
        .onTapGesture {
            if message.content.count > 100 {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }
        }
    }
}

// MARK: - Error Row

/// 错误消息 - 红色边框（简化版，去除阴影提升性能）
struct CCErrorRow: View {
    let message: CCMessage

    var body: some View {
        HStack(alignment: .top, spacing: CCSpacing.sm) {
            // 错误图标
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundColor(CCColor.accentDanger)

            // 错误内容
            Text(message.content)
                .font(.ccBody)
                .foregroundColor(CCColor.accentDanger)
                .textSelection(.enabled)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, CCSpacing.md)
        .padding(.vertical, CCSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CCRadius.md)
                .fill(CCColor.dangerBg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CCRadius.md)
                .stroke(CCColor.accentDanger.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - System Row

/// 系统消息 - 居中淡化显示
struct CCSystemRow: View {
    let message: CCMessage

    var body: some View {
        HStack {
            Spacer()
            Text(message.content)
                .font(.ccCaption)
                .foregroundColor(CCColor.textTertiary)
                .padding(.horizontal, CCSpacing.lg)
                .padding(.vertical, CCSpacing.xs)
                .background(
                    Capsule()
                        .fill(CCColor.bgTertiary.opacity(0.5))
                )
            Spacer()
        }
        .padding(.vertical, CCSpacing.sm)
    }
}

// MARK: - Logo View

/// Peanut Logo - 科技感渐变
struct CCLogoView: View {
    var body: some View {
        HStack(spacing: CCSpacing.sm) {
            // Logo 图标
            Image(systemName: "sparkles")
                .font(.system(size: 16))
                .foregroundStyle(
                    LinearGradient(
                        colors: [CCColor.accentClaude, CCColor.accentPrimary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Peanut")
                .font(.ccHeadline)
                .foregroundStyle(
                    LinearGradient(
                        colors: [CCColor.textPrimary, CCColor.textSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
        .padding(.vertical, CCSpacing.xl)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Message List

/// 消息列表视图
struct CCMessageList: View {
    let messages: [CCMessage]
    var onTap: (() -> Void)? = nil
    var scrollToBottomTrigger: Bool = false  // 外部触发滚动到底部
    var initialMessageCount: Int = 0  // 初始加载的消息数量（历史消息）

    @State private var hasScrolledToBottom = false  // 是否已经滚动到底部

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: CCSpacing.md) {
                    ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
                        CCMessageRow(
                            message: message,
                            skipAnimation: index < initialMessageCount  // 历史消息跳过动画
                        )
                        .id(message.id)
                    }

                    // 底部占位，确保最后一条消息可以滚动到可见区域
                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding(.horizontal, CCSpacing.lg)
                .padding(.vertical, CCSpacing.lg)
            }
            .background(CCColor.bgPrimary)
            .scrollDismissesKeyboard(.interactively)  // 滑动时可以收起键盘
            .contentShape(Rectangle())
            .onTapGesture {
                onTap?()
            }
            .onChange(of: messages.count) { oldCount, newCount in
                // 历史消息首次加载完成，滚动到底部（无动画）
                if !hasScrolledToBottom && newCount > 0 {
                    hasScrolledToBottom = true
                    if let lastMessage = messages.last {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
                // 新消息到达时滚动（有动画）
                else if newCount > oldCount && hasScrolledToBottom {
                    scrollToBottom(proxy: proxy)
                }
            }
            .onChange(of: scrollToBottomTrigger) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onAppear {
                // 如果已有消息，立即滚动到底部
                if !messages.isEmpty {
                    hasScrolledToBottom = true
                    if let lastMessage = messages.last {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastMessage = messages.last {
            withAnimation(.easeOut(duration: 0.15)) {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

// MARK: - Interaction Bar

/// 交互栏 - 简洁底栏
struct CCInteractionBar: View {
    let message: CCMessage
    let onSelectOption: (InteractionOption) -> Void
    let onInput: (String) -> Void

    @State private var customInput = ""

    var body: some View {
        VStack(spacing: 0) {
            // 顶部细线
            Rectangle()
                .fill(CCColor.borderMuted)
                .frame(height: 0.5)

            VStack(spacing: CCSpacing.sm) {
                // 提示内容
                if !message.content.isEmpty && message.type != .selectionDialog {
                    HStack(spacing: CCSpacing.sm) {
                        Image(systemName: iconForType)
                            .font(.system(size: 14))
                            .foregroundColor(colorForType)

                        Text(message.content)
                            .font(.ccSubheadline)
                            .foregroundColor(CCColor.textPrimary)
                            .lineLimit(2)

                        Spacer()
                    }
                }

                // 选项按钮
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: CCSpacing.sm) {
                        ForEach(message.availableOptions) { option in
                            CCGlassButton(
                                title: option.label,
                                hotkey: option.hotkey,
                                style: styleForOption(option),
                                action: { onSelectOption(option) }
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, CCSpacing.md)
            .padding(.vertical, CCSpacing.sm)
        }
        .background(CCColor.bgSecondary)
    }

    private var iconForType: String {
        switch message.type {
        case .permissionRequest:
            return CCIcon.permission
        case .confirmation:
            return CCIcon.question
        case .selectionDialog:
            return CCIcon.sessions
        default:
            return CCIcon.system
        }
    }

    private var colorForType: Color {
        switch message.type {
        case .permissionRequest:
            return CCColor.accentWarning
        case .confirmation:
            return CCColor.accentInfo
        default:
            return CCColor.textSecondary
        }
    }

    private func styleForOption(_ option: InteractionOption) -> CCGlassButton.ButtonStyle {
        switch option.actionType {
        case .accept, .alwaysAllow:
            return .success
        case .reject, .alwaysDeny:
            return .danger
        case .skip:
            return .secondary
        default:
            return option.isDefault == true ? .primary : .secondary
        }
    }
}

// MARK: - Glass Button

/// 玻璃按钮组件 - 简洁无边框设计
struct CCGlassButton: View {
    let title: String
    var hotkey: String? = nil
    var style: ButtonStyle = .primary
    let action: () -> Void

    enum ButtonStyle {
        case primary
        case secondary
        case success
        case danger
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
                        .opacity(0.6)
                }
                Text(title)
                    .font(.ccSubheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(foregroundColor)
            .padding(.horizontal, CCSpacing.md)
            .padding(.vertical, CCSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: CCRadius.md)
                    .fill(backgroundColor)
            )
        }
        .buttonStyle(.plain)
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            return CCColor.accentPrimary
        case .secondary:
            return CCColor.bgTertiary.opacity(0.8)
        case .success:
            return CCColor.accentSuccess
        case .danger:
            return CCColor.accentDanger
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary, .success, .danger:
            return .white
        case .secondary:
            return CCColor.textSecondary
        }
    }
}
