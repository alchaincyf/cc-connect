//
//  MessageComponents.swift
//  cc connect
//
//  Design System v2.0 - 消息组件
//  IDE 风格的消息行布局
//

import SwiftUI

// MARK: - Message Row (IDE Style)

/// IDE 风格的消息行
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

/// Claude 消息行
struct CCClaudeMessageRow: View {
    let message: CCMessage

    var body: some View {
        HStack(alignment: .top, spacing: CCSpacing.sm) {
            // 图标
            Image(systemName: CCIcon.claude)
                .font(.system(size: 14))
                .foregroundColor(CCColor.accentClaude)
                .frame(width: 24, alignment: .center)

            // 内容
            VStack(alignment: .leading, spacing: CCSpacing.xxs) {
                // 标签
                Text("Claude")
                    .font(.ccCaption)
                    .foregroundColor(CCColor.accentClaude)

                // 消息内容
                Text(message.content)
                    .font(.ccBody)
                    .foregroundColor(CCColor.textPrimary)
                    .textSelection(.enabled)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, CCSpacing.xs)
    }
}

// MARK: - User Message Row

/// 用户消息行（右对齐）
struct CCUserMessageRow: View {
    let message: CCMessage

    var body: some View {
        HStack(alignment: .top, spacing: CCSpacing.sm) {
            Spacer(minLength: 60)

            // 内容
            VStack(alignment: .trailing, spacing: CCSpacing.xxs) {
                Text(message.content)
                    .font(.ccBody)
                    .foregroundColor(.white)
                    .textSelection(.enabled)
            }
            .padding(.horizontal, CCSpacing.md)
            .padding(.vertical, CCSpacing.sm)
            .background(CCColor.accentPrimary)
            .clipShape(RoundedRectangle(cornerRadius: CCRadius.md))

            // 图标
            Image(systemName: CCIcon.userInput)
                .font(.system(size: 14))
                .foregroundColor(CCColor.accentPrimary)
                .frame(width: 24, alignment: .center)
        }
        .padding(.vertical, CCSpacing.xs)
    }
}

// MARK: - Tool Call Row

/// 工具调用行
struct CCToolCallRow: View {
    let message: CCMessage
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 头部
            HStack(spacing: CCSpacing.sm) {
                Image(systemName: CCIcon.toolCall)
                    .font(.system(size: 14))
                    .foregroundColor(CCColor.accentInfo)
                    .frame(width: 24, alignment: .center)

                Text(message.toolName ?? "工具")
                    .font(.ccCodeBold)
                    .foregroundColor(CCColor.accentInfo)

                if let filePath = message.filePath {
                    Text(filePath)
                        .font(.ccCodeSmall)
                        .foregroundColor(CCColor.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                // 复制按钮
                Button(action: {
                    UIPasteboard.general.string = message.content
                    CCHaptic.light()
                }) {
                    Image(systemName: CCIcon.copy)
                        .font(.system(size: 12))
                        .foregroundColor(CCColor.textTertiary)
                }
            }
            .padding(.vertical, CCSpacing.xs)

            // 代码内容（如果有）
            if !message.content.isEmpty {
                CCCodeBlock(
                    code: message.content,
                    fileName: message.filePath,
                    maxLines: 6
                )
                .padding(.leading, 24 + CCSpacing.sm)
            }
        }
    }
}

// MARK: - Tool Result Row

/// 工具结果行
struct CCToolResultRow: View {
    let message: CCMessage
    @State private var isExpanded = false

    var body: some View {
        HStack(alignment: .top, spacing: CCSpacing.sm) {
            // 图标
            Image(systemName: CCIcon.toolResult)
                .font(.system(size: 14))
                .foregroundColor(CCColor.accentSuccess)
                .frame(width: 24, alignment: .center)

            // 内容
            VStack(alignment: .leading, spacing: CCSpacing.xxs) {
                Text(message.content)
                    .font(.ccCodeSmall)
                    .foregroundColor(CCColor.textSecondary)
                    .lineLimit(isExpanded ? nil : 3)
                    .textSelection(.enabled)

                if message.content.count > 200 {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Text(isExpanded ? "收起" : "展开")
                            .font(.ccCaption)
                            .foregroundColor(CCColor.accentPrimary)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, CCSpacing.xs)
    }
}

// MARK: - Error Row

/// 错误消息行
struct CCErrorRow: View {
    let message: CCMessage

    var body: some View {
        HStack(alignment: .top, spacing: CCSpacing.sm) {
            // 图标
            Image(systemName: CCIcon.error)
                .font(.system(size: 14))
                .foregroundColor(CCColor.accentDanger)
                .frame(width: 24, alignment: .center)

            // 内容
            VStack(alignment: .leading, spacing: CCSpacing.xxs) {
                Text("错误")
                    .font(.ccCaption)
                    .foregroundColor(CCColor.accentDanger)

                Text(message.content)
                    .font(.ccBody)
                    .foregroundColor(CCColor.accentDanger)
                    .textSelection(.enabled)
            }
            .padding(CCSpacing.sm)
            .background(CCColor.dangerBg)
            .clipShape(RoundedRectangle(cornerRadius: CCRadius.sm))

            Spacer(minLength: 0)
        }
        .padding(.vertical, CCSpacing.xs)
    }
}

// MARK: - System Row

/// 系统消息行（居中显示）
struct CCSystemRow: View {
    let message: CCMessage

    var body: some View {
        HStack {
            Spacer()
            Text(message.content)
                .font(.ccCaption)
                .foregroundColor(CCColor.textTertiary)
                .padding(.horizontal, CCSpacing.md)
                .padding(.vertical, CCSpacing.xs)
                .background(CCColor.bgTertiary)
                .clipShape(Capsule())
            Spacer()
        }
        .padding(.vertical, CCSpacing.xs)
    }
}

// MARK: - Logo View

/// Claude Code Logo
struct CCLogoView: View {
    var body: some View {
        HStack(spacing: CCSpacing.sm) {
            Image(systemName: CCIcon.claude)
                .font(.title2)
                .foregroundColor(CCColor.accentClaude)

            Text("Claude Code")
                .font(.ccHeadline)
                .foregroundColor(CCColor.accentClaude)
        }
        .padding(.vertical, CCSpacing.md)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Message List

/// 消息列表视图
struct CCMessageList: View {
    let messages: [CCMessage]
    var onTap: (() -> Void)? = nil

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(messages) { message in
                        CCMessageRow(message: message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, CCSpacing.lg)
                .padding(.vertical, CCSpacing.md)
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
