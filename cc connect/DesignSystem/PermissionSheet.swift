//
//  PermissionSheet.swift
//  cc connect
//
//  Design System v2.0 - 权限请求 Sheet
//  强制打断用户，确保重要操作不被忽略
//

import SwiftUI

// MARK: - Permission Sheet

/// 权限请求 Sheet（强制弹出）
struct CCPermissionSheet: View {
    let message: CCMessage
    let onAllow: () -> Void
    let onDeny: () -> Void
    let onAlwaysAllow: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: CCSpacing.xl) {
            // 拖动指示器
            Capsule()
                .fill(CCColor.borderDefault)
                .frame(width: 36, height: 5)
                .padding(.top, CCSpacing.sm)

            // 图标和标题
            VStack(spacing: CCSpacing.md) {
                Image(systemName: CCIcon.permission)
                    .font(.system(size: 40))
                    .foregroundColor(CCColor.accentWarning)

                Text(titleText)
                    .font(.ccTitle3)
                    .foregroundColor(CCColor.textPrimary)
                    .multilineTextAlignment(.center)
            }

            // 命令/内容预览
            if let command = extractCommand() {
                CommandPreview(command: command)
            } else if !message.content.isEmpty {
                Text(message.content)
                    .font(.ccBody)
                    .foregroundColor(CCColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, CCSpacing.lg)
            }

            Spacer()

            // 操作按钮
            VStack(spacing: CCSpacing.sm) {
                // 允许按钮
                Button(action: {
                    CCHaptic.medium()
                    onAllow()
                    dismiss()
                }) {
                    HStack(spacing: CCSpacing.sm) {
                        Text("[Y]")
                            .font(.ccCodeSmall)
                            .opacity(0.8)
                        Text("允许")
                            .font(.ccHeadline)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: CCSize.buttonHeightLarge)
                    .background(CCColor.accentSuccess)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: CCRadius.md))
                }

                // 拒绝和始终允许
                HStack(spacing: CCSpacing.sm) {
                    // 拒绝按钮
                    Button(action: {
                        CCHaptic.medium()
                        onDeny()
                        dismiss()
                    }) {
                        HStack(spacing: CCSpacing.xs) {
                            Text("[N]")
                                .font(.ccCodeSmall)
                                .opacity(0.8)
                            Text("拒绝")
                                .font(.ccHeadline)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: CCSize.buttonHeight)
                        .background(CCColor.accentDanger)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: CCRadius.md))
                    }

                    // 始终允许按钮
                    if let onAlwaysAllow = onAlwaysAllow {
                        Button(action: {
                            CCHaptic.medium()
                            onAlwaysAllow()
                            dismiss()
                        }) {
                            HStack(spacing: CCSpacing.xs) {
                                Text("[A]")
                                    .font(.ccCodeSmall)
                                    .opacity(0.6)
                                Text("始终允许")
                                    .font(.ccHeadline)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: CCSize.buttonHeight)
                            .background(CCColor.bgTertiary)
                            .foregroundColor(CCColor.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: CCRadius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: CCRadius.md)
                                    .stroke(CCColor.borderDefault, lineWidth: 1)
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, CCSpacing.lg)
            .padding(.bottom, CCSpacing.xl)
        }
        .background(CCColor.bgElevated)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .interactiveDismissDisabled() // 禁止下滑关闭
    }

    private var titleText: String {
        switch message.type {
        case .permissionRequest:
            return "Claude 想要执行操作"
        case .confirmation:
            return "确认操作"
        default:
            return "请选择"
        }
    }

    private func extractCommand() -> String? {
        // 尝试从消息内容中提取命令
        let content = message.content
        if content.contains("Bash") || content.contains("npm") || content.contains("git") {
            // 简单的命令提取逻辑
            let lines = content.components(separatedBy: "\n")
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("$") || trimmed.hasPrefix(">") {
                    return String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
                }
                if trimmed.contains("npm ") || trimmed.contains("git ") || trimmed.contains("bash") {
                    return trimmed
                }
            }
        }
        return nil
    }
}

// MARK: - Command Preview

/// 命令预览框
struct CommandPreview: View {
    let command: String

    var body: some View {
        VStack(alignment: .leading, spacing: CCSpacing.xs) {
            HStack {
                Text("命令")
                    .font(.ccCaption)
                    .foregroundColor(CCColor.textTertiary)
                Spacer()
                Button(action: {
                    UIPasteboard.general.string = command
                    CCHaptic.light()
                }) {
                    Image(systemName: CCIcon.copy)
                        .font(.system(size: 12))
                        .foregroundColor(CCColor.textTertiary)
                }
            }

            Text(command)
                .font(.ccCode)
                .foregroundColor(CCColor.terminalText)
                .padding(CCSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(CCColor.terminalBg)
                .clipShape(RoundedRectangle(cornerRadius: CCRadius.sm))
        }
        .padding(.horizontal, CCSpacing.lg)
    }
}

// MARK: - Selection Sheet

/// 选择对话 Sheet
struct CCSelectionSheet: View {
    let message: CCMessage
    let onSelect: (InteractionOption) -> Void
    let onInput: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var customInput = ""

    var body: some View {
        VStack(spacing: CCSpacing.lg) {
            // 拖动指示器
            Capsule()
                .fill(CCColor.borderDefault)
                .frame(width: 36, height: 5)
                .padding(.top, CCSpacing.sm)

            // 标题
            Text(message.content.isEmpty ? "请选择" : message.content)
                .font(.ccTitle3)
                .foregroundColor(CCColor.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, CCSpacing.lg)

            // 选项列表
            ScrollView {
                VStack(spacing: CCSpacing.sm) {
                    ForEach(message.availableOptions) { option in
                        SelectionOptionRow(option: option) {
                            CCHaptic.light()
                            onSelect(option)
                            dismiss()
                        }
                    }

                    // 自定义输入
                    if message.availableOptions.count > 4 {
                        CustomInputRow(
                            text: $customInput,
                            onSubmit: {
                                if !customInput.isEmpty {
                                    onInput(customInput)
                                    dismiss()
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, CCSpacing.lg)
            }

            Spacer()
        }
        .background(CCColor.bgElevated)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Selection Option Row

/// 选择选项行
struct SelectionOptionRow: View {
    let option: InteractionOption
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: CCSpacing.md) {
                // 快捷键提示
                if let hotkey = option.hotkey {
                    Text("[\(hotkey)]")
                        .font(.ccCodeSmall)
                        .foregroundColor(CCColor.textTertiary)
                        .frame(width: 40)
                }

                // 选项内容
                VStack(alignment: .leading, spacing: CCSpacing.xxs) {
                    Text(option.label)
                        .font(.ccHeadline)
                        .foregroundColor(CCColor.textPrimary)

                    if let description = option.description {
                        Text(description)
                            .font(.ccCaption)
                            .foregroundColor(CCColor.textSecondary)
                    }
                }

                Spacer()

                // 默认标记
                if option.isDefault == true {
                    Text("推荐")
                        .font(.ccCaption)
                        .foregroundColor(.white)
                        .padding(.horizontal, CCSpacing.sm)
                        .padding(.vertical, CCSpacing.xxs)
                        .background(CCColor.accentPrimary)
                        .clipShape(Capsule())
                }
            }
            .padding(CCSpacing.md)
            .background(CCColor.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: CCRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: CCRadius.md)
                    .stroke(option.isDefault == true ? CCColor.accentPrimary : CCColor.borderMuted, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Custom Input Row

/// 自定义输入行
struct CustomInputRow: View {
    @Binding var text: String
    let onSubmit: () -> Void

    var body: some View {
        HStack(spacing: CCSpacing.sm) {
            TextField("输入其他选项...", text: $text)
                .font(.ccBody)
                .padding(.horizontal, CCSpacing.md)
                .padding(.vertical, CCSpacing.sm)
                .background(CCColor.bgTertiary)
                .clipShape(RoundedRectangle(cornerRadius: CCRadius.sm))
                .onSubmit(onSubmit)

            Button(action: onSubmit) {
                Image(systemName: CCIcon.send)
                    .font(.system(size: 24))
                    .foregroundColor(text.isEmpty ? CCColor.textDisabled : CCColor.accentPrimary)
            }
            .disabled(text.isEmpty)
        }
        .padding(.top, CCSpacing.sm)
    }
}

// MARK: - Confirmation Sheet

/// 确认对话 Sheet
struct CCConfirmationSheet: View {
    let title: String
    let message: String
    let confirmTitle: String
    let confirmStyle: CCQuickActionButton.ActionStyle
    let onConfirm: () -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: CCSpacing.xl) {
            // 拖动指示器
            Capsule()
                .fill(CCColor.borderDefault)
                .frame(width: 36, height: 5)
                .padding(.top, CCSpacing.sm)

            // 标题和消息
            VStack(spacing: CCSpacing.md) {
                Text(title)
                    .font(.ccTitle3)
                    .foregroundColor(CCColor.textPrimary)

                if !message.isEmpty {
                    Text(message)
                        .font(.ccBody)
                        .foregroundColor(CCColor.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, CCSpacing.lg)

            Spacer()

            // 按钮
            VStack(spacing: CCSpacing.sm) {
                Button(action: {
                    CCHaptic.medium()
                    onConfirm()
                    dismiss()
                }) {
                    Text(confirmTitle)
                        .font(.ccHeadline)
                        .frame(maxWidth: .infinity)
                        .frame(height: CCSize.buttonHeight)
                        .background(confirmStyle == .reject ? CCColor.accentDanger : CCColor.accentPrimary)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: CCRadius.md))
                }

                Button(action: {
                    CCHaptic.light()
                    onCancel()
                    dismiss()
                }) {
                    Text("取消")
                        .font(.ccHeadline)
                        .frame(maxWidth: .infinity)
                        .frame(height: CCSize.buttonHeight)
                        .background(CCColor.bgTertiary)
                        .foregroundColor(CCColor.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: CCRadius.md))
                }
            }
            .padding(.horizontal, CCSpacing.lg)
            .padding(.bottom, CCSpacing.xl)
        }
        .background(CCColor.bgElevated)
        .presentationDetents([.height(300)])
        .presentationDragIndicator(.hidden)
    }
}
