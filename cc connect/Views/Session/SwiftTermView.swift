//
//  SwiftTermView.swift
//  cc connect
//
//  Design System v2.0 - 终端会话视图
//  此文件保持向后兼容，实际组件已迁移到 DesignSystem/
//

import SwiftUI

// MARK: - Terminal Session View (Legacy Wrapper)

/// 终端会话视图 - 向后兼容的包装器
/// 实际实现已迁移到 SessionDetailView
struct TerminalSessionView: View {
    @Bindable var session: Session
    @StateObject private var wsManager = WebSocketManager()

    @State private var inputText = ""
    @State private var showPermissionSheet = false
    @State private var pendingPermission: CCMessage?

    @FocusState private var isInputFocused: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            CCColor.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // 消息列表
                ChatMessageList(messages: wsManager.messages, onTap: dismissKeyboard)

                // 交互区域
                if let interaction = wsManager.currentInteraction,
                   interaction.type != .permissionRequest {
                    InteractionBar(
                        message: interaction,
                        onSelectOption: { option in
                            wsManager.respondToInteraction(option: option)
                            dismissKeyboard()
                        },
                        onInput: { text in
                            wsManager.sendInput(text)
                            dismissKeyboard()
                        }
                    )
                }

                // 输入栏
                ChatInputBar(
                    text: $inputText,
                    isFocused: $isInputFocused,
                    onSend: sendMessage,
                    onInterrupt: { wsManager.sendInterrupt() }
                )
            }

            // 状态栏浮层
            if let statusText = wsManager.statusBarText {
                StatusBarOverlay(text: statusText)
                    .padding(.bottom, 70)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.2), value: wsManager.statusBarText)
            }
        }
        .navigationTitle(session.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ConnectionStatusBadge(state: wsManager.connectionState)
            }
        }
        .onAppear { connectWebSocket() }
        .onDisappear { wsManager.disconnect() }
        .onChange(of: wsManager.currentInteraction) { _, newValue in
            if let interaction = newValue, interaction.type == .permissionRequest {
                pendingPermission = interaction
                showPermissionSheet = true
            }
        }
        .sheet(isPresented: $showPermissionSheet) {
            if let permission = pendingPermission {
                CCPermissionSheet(
                    message: permission,
                    onAllow: {
                        wsManager.sendInput("y")
                        pendingPermission = nil
                    },
                    onDeny: {
                        wsManager.sendInput("n")
                        pendingPermission = nil
                    },
                    onAlwaysAllow: {
                        wsManager.sendInput("a")
                        pendingPermission = nil
                    }
                )
            }
        }
    }

    private func dismissKeyboard() {
        isInputFocused = false
    }

    private func connectWebSocket() {
        guard let secret = session.secret else { return }
        wsManager.connect(
            serverURL: ServerConfig.relayServer,
            sessionId: session.id,
            secret: secret,
            session: session
        )
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        wsManager.sendInput(text)
        inputText = ""
        dismissKeyboard()
    }
}

// MARK: - Legacy Components (保持向后兼容)

/// 消息列表 - 使用新设计系统
struct ChatMessageList: View {
    let messages: [CCMessage]
    var onTap: (() -> Void)? = nil

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(messages) { message in
                        ChatBubble(message: message)
                            .id(message.id)
                    }
                }
                .padding()
            }
            .background(CCColor.bgPrimary)
            .contentShape(Rectangle())
            .onTapGesture { onTap?() }
            .onChange(of: messages.count) { _, _ in
                if let lastMessage = messages.last {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
}

/// 消息气泡 - 使用新设计系统
struct ChatBubble: View {
    let message: CCMessage

    var body: some View {
        // 使用新的消息行组件
        CCMessageRow(message: message)
    }
}

/// 交互栏 - 使用新设计系统
struct InteractionBar: View {
    let message: CCMessage
    let onSelectOption: (InteractionOption) -> Void
    let onInput: (String) -> Void

    var body: some View {
        CCInteractionBar(
            message: message,
            onSelectOption: onSelectOption,
            onInput: onInput
        )
    }
}

/// 选项按钮 - 向后兼容
struct OptionButton: View {
    let option: InteractionOption
    let action: () -> Void

    var body: some View {
        CCQuickActionButton(
            title: option.label,
            action: action,
            hotkey: option.hotkey,
            style: styleForOption(option)
        )
    }

    private func styleForOption(_ option: InteractionOption) -> CCQuickActionButton.ActionStyle {
        switch option.actionType {
        case .accept, .alwaysAllow:
            return .accept
        case .reject, .alwaysDeny:
            return .reject
        case .skip:
            return .neutral
        default:
            return option.isDefault == true ? .default : .neutral
        }
    }
}

/// 快捷回复栏 - 向后兼容
struct QuickReplyBar: View {
    let options: [String]
    let onSelect: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: CCSpacing.sm) {
                ForEach(options, id: \.self) { option in
                    CCQuickActionButton(title: option, action: { onSelect(option) })
                }
            }
            .padding(.horizontal, CCSpacing.lg)
            .padding(.vertical, CCSpacing.sm)
        }
        .background(CCColor.bgSecondary)
    }
}

/// 输入栏 - 使用新设计系统
struct ChatInputBar: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    let onSend: () -> Void
    let onInterrupt: () -> Void

    var body: some View {
        CCChatInputBar(
            text: $text,
            isFocused: isFocused,
            onSend: onSend,
            onInterrupt: onInterrupt
        )
    }
}

/// 连接状态徽章 - 使用新设计系统
struct ConnectionStatusBadge: View {
    let state: ConnectionState

    var body: some View {
        CCConnectionBadge(state: state)
    }
}

/// Claude Code Logo - 使用新设计系统
struct ClaudeCodeLogoView: View {
    var body: some View {
        CCLogoView()
    }
}

/// 颜色文本渲染 - 保持原有实现
struct ColoredTextView: View {
    let content: String
    let colorHints: [ColorHint]?
    var defaultColor: Color = CCColor.textPrimary

    var body: some View {
        if let hints = colorHints, !hints.isEmpty {
            Text(buildAttributedString())
        } else {
            Text(content)
                .foregroundColor(defaultColor)
        }
    }

    private func buildAttributedString() -> AttributedString {
        var attributed = AttributedString(content)
        guard let hints = colorHints else { return attributed }

        let sortedHints = hints.sorted { $0.start < $1.start }

        for hint in sortedHints {
            let startIndex = content.index(content.startIndex, offsetBy: min(hint.start, content.count), limitedBy: content.endIndex) ?? content.endIndex
            let endIndex = content.index(content.startIndex, offsetBy: min(hint.end, content.count), limitedBy: content.endIndex) ?? content.endIndex

            if startIndex < endIndex {
                if let attrStart = AttributedString.Index(startIndex, within: attributed),
                   let attrEnd = AttributedString.Index(endIndex, within: attributed) {
                    attributed[attrStart..<attrEnd].foregroundColor = hint.color.swiftUIColor
                }
            }
        }

        return attributed
    }
}

/// 状态栏浮层 - 使用新设计系统
struct StatusBarOverlay: View {
    let text: String

    var body: some View {
        CCStatusOverlay(text: text)
    }
}
