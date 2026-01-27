//
//  MessageComponents.swift
//  cc connect
//
//  Design System v3.0 - MUJI 风格消息组件
//  极简、留白、克制的视觉语言
//

import SwiftUI

// MARK: - Message Row (MUJI Style)

/// MUJI 风格的消息行 - 极简设计
struct CCMessageRow: View {
    let message: CCMessage

    var body: some View {
        switch message.type {
        case .logo:
            CCLogoView()
        case .userInput:
            CCUserMessageRow(message: message)
        case .toolCall:
            CCToolCallRow(message: message)
        case .toolResult:
            CCToolResultRow(message: message)
        case .toolError, .error:
            CCErrorRow(message: message)
        case .system:
            CCSystemRow(message: message)
        default:
            CCClaudeMessageRow(message: message)
        }
    }
}

// MARK: - Claude Message Row

/// Claude 消息行 - 极简设计，支持 Markdown 渲染
struct CCClaudeMessageRow: View {
    let message: CCMessage

    var body: some View {
        HStack(alignment: .top, spacing: CCSpacing.md) {
            // 左侧指示线（替代图标，更克制）
            Rectangle()
                .fill(CCColor.accentClaude)
                .frame(width: 2)

            // 内容 - 使用 Markdown 渲染
            CCMarkdownView(content: message.content, textColor: CCColor.textPrimary)

            Spacer(minLength: 0)
        }
        .padding(.vertical, CCSpacing.sm)
    }
}

// MARK: - User Message Row

/// 用户消息行 - 极简右对齐，无气泡
struct CCUserMessageRow: View {
    let message: CCMessage

    var body: some View {
        HStack(alignment: .top, spacing: CCSpacing.md) {
            Spacer(minLength: 80)

            // 内容 - 无气泡，纯文本
            Text(message.content)
                .font(.ccBody)
                .foregroundColor(CCColor.textSecondary)
                .textSelection(.enabled)
                .lineSpacing(4)

            // 右侧指示线
            Rectangle()
                .fill(CCColor.textTertiary)
                .frame(width: 2)
        }
        .padding(.vertical, CCSpacing.sm)
    }
}

// MARK: - Tool Call Row

/// 工具调用行 - 简化版，单行显示
struct CCToolCallRow: View {
    let message: CCMessage
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: CCSpacing.xs) {
            // 工具名称 + 参数，单行紧凑显示
            HStack(spacing: CCSpacing.xs) {
                Text("→")
                    .font(.ccCode)
                    .foregroundColor(CCColor.textTertiary)

                Text(message.toolName ?? "工具")
                    .font(.ccCode)
                    .foregroundColor(CCColor.textSecondary)

                if let filePath = message.filePath {
                    Text(filePath)
                        .font(.ccCodeSmall)
                        .foregroundColor(CCColor.textTertiary)
                        .lineLimit(1)
                }

                Spacer()
            }

            // 代码内容（如果有且较长）
            if !message.content.isEmpty && message.content.count > 50 {
                Text(message.content)
                    .font(.ccCodeSmall)
                    .foregroundColor(CCColor.textTertiary)
                    .lineLimit(isExpanded ? nil : 2)
                    .padding(.leading, CCSpacing.lg)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isExpanded.toggle()
                        }
                    }
            }
        }
        .padding(.vertical, CCSpacing.xs)
    }
}

// MARK: - Tool Result Row

/// 工具结果行 - 极简，缩进显示
struct CCToolResultRow: View {
    let message: CCMessage
    @State private var isExpanded = false

    var body: some View {
        HStack(alignment: .top, spacing: CCSpacing.xs) {
            Text("←")
                .font(.ccCode)
                .foregroundColor(CCColor.textTertiary)

            Text(message.content)
                .font(.ccCodeSmall)
                .foregroundColor(CCColor.textTertiary)
                .lineLimit(isExpanded ? nil : 2)
                .textSelection(.enabled)
                .onTapGesture {
                    if message.content.count > 100 {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isExpanded.toggle()
                        }
                    }
                }

            Spacer(minLength: 0)
        }
        .padding(.vertical, CCSpacing.xs)
    }
}

// MARK: - Error Row

/// 错误消息行 - 简约错误提示
struct CCErrorRow: View {
    let message: CCMessage

    var body: some View {
        HStack(alignment: .top, spacing: CCSpacing.md) {
            // 左侧红色指示线
            Rectangle()
                .fill(CCColor.accentDanger)
                .frame(width: 2)

            // 内容 - 柔和红色文字，无背景
            Text(message.content)
                .font(.ccBody)
                .foregroundColor(CCColor.accentDanger)
                .textSelection(.enabled)

            Spacer(minLength: 0)
        }
        .padding(.vertical, CCSpacing.sm)
    }
}

// MARK: - System Row

/// 系统消息行 - 极简居中显示
struct CCSystemRow: View {
    let message: CCMessage

    var body: some View {
        HStack {
            Spacer()
            Text(message.content)
                .font(.ccCaption)
                .foregroundColor(CCColor.textTertiary)
            Spacer()
        }
        .padding(.vertical, CCSpacing.md)
    }
}

// MARK: - Logo View

/// Peanut Logo - 简约版
struct CCLogoView: View {
    var body: some View {
        Text("Peanut")
            .font(.ccSubheadline)
            .foregroundColor(CCColor.textTertiary)
            .padding(.vertical, CCSpacing.lg)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Message List

/// 消息列表视图 - 大量留白，呼吸感
struct CCMessageList: View {
    let messages: [CCMessage]
    var onTap: (() -> Void)? = nil

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: CCSpacing.sm) {
                    ForEach(messages) { message in
                        CCMessageRow(message: message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, CCSpacing.xl)  // 更大的水平边距
                .padding(.vertical, CCSpacing.lg)
            }
            .background(CCColor.bgPrimary)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap?()
            }
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

// MARK: - Interaction Bar

/// 交互栏（权限请求、选择对话等）
struct CCInteractionBar: View {
    let message: CCMessage
    let onSelectOption: (InteractionOption) -> Void
    let onInput: (String) -> Void

    @State private var customInput = ""

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(CCColor.borderDefault)

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
                .padding(.horizontal, CCSpacing.lg)
                .padding(.top, CCSpacing.sm)
            }

            // 选项按钮
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: CCSpacing.sm) {
                    ForEach(message.availableOptions) { option in
                        CCQuickActionButton(
                            title: option.label,
                            action: { onSelectOption(option) },
                            hotkey: option.hotkey,
                            style: styleForOption(option)
                        )
                    }
                }
                .padding(.horizontal, CCSpacing.lg)
                .padding(.vertical, CCSpacing.sm)
            }
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
