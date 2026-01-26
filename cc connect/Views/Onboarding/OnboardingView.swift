//
//  OnboardingView.swift
//  cc connect
//
//  Design System v3.0 - MUJI 风格引导页
//  极简、大量留白、克制的视觉
//

import SwiftUI

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @State private var copiedCommand: String?

    var body: some View {
        ZStack {
            // 背景
            CCColor.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // 标题 - 极简，无图标
                VStack(spacing: CCSpacing.sm) {
                    Text("CC Connect")
                        .font(.ccTitle2)
                        .foregroundColor(CCColor.textPrimary)

                    Text("Claude Code 移动控制台")
                        .font(.ccCaption)
                        .foregroundColor(CCColor.textTertiary)
                }

                Spacer()
                    .frame(height: CCSpacing.xxxl)

                // 步骤 - 纯文字，大留白
                VStack(alignment: .leading, spacing: CCSpacing.lg) {
                    StepText(
                        number: "1",
                        title: "安装 CLI",
                        command: "npm i -g huashu-cc@latest",
                        isCopied: copiedCommand == "npm i -g huashu-cc@latest"
                    ) {
                        copyCommand("npm i -g huashu-cc@latest")
                    }

                    StepText(
                        number: "2",
                        title: "配置 Hooks",
                        command: "huashu-cc install-hooks",
                        description: "首次安装后只需执行一次",
                        isCopied: copiedCommand == "huashu-cc install-hooks"
                    ) {
                        copyCommand("huashu-cc install-hooks")
                    }

                    StepText(
                        number: "3",
                        title: "启动会话",
                        command: "huashu-cc start",
                        isCopied: copiedCommand == "huashu-cc start"
                    ) {
                        copyCommand("huashu-cc start")
                    }

                    StepText(
                        number: "4",
                        title: "扫码连接",
                        description: nil
                    )
                }
                .padding(.horizontal, CCSpacing.xxl)

                Spacer()

                // 操作按钮
                VStack(spacing: CCSpacing.lg) {
                    CCPrimaryButton(
                        title: "扫码连接",
                        action: { showOnboarding = false },
                        icon: CCIcon.scan
                    )

                    Button(action: { showOnboarding = false }) {
                        Text("跳过")
                            .font(.ccCaption)
                            .foregroundColor(CCColor.textTertiary)
                    }
                }
                .padding(.horizontal, CCSpacing.xxl)
                .padding(.bottom, CCSpacing.xxxl)
            }
        }
    }

    private func copyCommand(_ command: String) {
        UIPasteboard.general.string = command
        CCHaptic.light()
        copiedCommand = command

        // 2秒后重置
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if copiedCommand == command {
                copiedCommand = nil
            }
        }
    }
}

// MARK: - Step Text (MUJI Style)

/// 步骤文字 - 极简设计，无卡片背景
struct StepText: View {
    let number: String
    let title: String
    var command: String? = nil
    var description: String? = nil
    var isCopied: Bool = false
    var onCopy: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: CCSpacing.xs) {
            // 步骤标题
            HStack(spacing: CCSpacing.sm) {
                Text(number)
                    .font(.ccCaption)
                    .foregroundColor(CCColor.textTertiary)

                Text(title)
                    .font(.ccBody)
                    .foregroundColor(CCColor.textPrimary)
            }

            // 命令（如果有）
            if let command = command {
                Button(action: { onCopy?() }) {
                    HStack {
                        Text(command)
                            .font(.ccCode)
                            .foregroundColor(CCColor.textSecondary)

                        Spacer()

                        if isCopied {
                            Text("✓")
                                .font(.ccCaption)
                                .foregroundColor(CCColor.accentSuccess)
                        }
                    }
                }
            }

            // 描述（如果有）
            if let description = description {
                Text(description)
                    .font(.ccCaption)
                    .foregroundColor(CCColor.textTertiary)
            }
        }
    }
}

// MARK: - Legacy StepCard (保持兼容)

struct StepCard: View {
    let number: String
    let title: String
    var command: String? = nil
    var description: String? = nil
    var isCopied: Bool = false
    var onCopy: (() -> Void)? = nil

    var body: some View {
        StepText(
            number: number,
            title: title,
            command: command,
            description: description,
            isCopied: isCopied,
            onCopy: onCopy
        )
    }
}

#Preview {
    OnboardingView(showOnboarding: .constant(true))
}
