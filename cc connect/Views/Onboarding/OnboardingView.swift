//
//  OnboardingView.swift
//  cc connect
//
//  Design System v2.0 - 引导页
//  单页完成引导，简洁明了
//

import SwiftUI

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @State private var copiedCommand: String?

    var body: some View {
        ZStack {
            // 背景
            CCColor.bgPrimary.ignoresSafeArea()

            VStack(spacing: CCSpacing.xxl) {
                Spacer()

                // Logo 和标题
                VStack(spacing: CCSpacing.md) {
                    Image(systemName: CCIcon.logo)
                        .font(.system(size: 56))
                        .foregroundColor(CCColor.accentClaude)

                    Text("CC Connect")
                        .font(.ccLargeTitle)
                        .foregroundColor(CCColor.textPrimary)

                    Text("Claude Code 移动控制台")
                        .font(.ccSubheadline)
                        .foregroundColor(CCColor.textSecondary)
                }

                Spacer()

                // 步骤卡片
                VStack(spacing: CCSpacing.md) {
                    StepCard(
                        number: "1",
                        title: "在终端安装 CLI",
                        command: "npm i -g cc-connect",
                        isCopied: copiedCommand == "npm i -g cc-connect"
                    ) {
                        copyCommand("npm i -g cc-connect")
                    }

                    StepCard(
                        number: "2",
                        title: "运行命令",
                        command: "cc start",
                        isCopied: copiedCommand == "cc start"
                    ) {
                        copyCommand("cc start")
                    }

                    StepCard(
                        number: "3",
                        title: "扫描二维码",
                        description: "准备好后点击下方按钮"
                    )
                }
                .padding(.horizontal, CCSpacing.lg)

                Spacer()

                // 操作按钮
                VStack(spacing: CCSpacing.md) {
                    CCPrimaryButton(
                        title: "扫描二维码",
                        action: { showOnboarding = false },
                        icon: CCIcon.scan
                    )

                    CCTextButton(
                        title: "跳过，稍后连接",
                        action: { showOnboarding = false },
                        color: CCColor.textTertiary
                    )
                }
                .padding(.horizontal, CCSpacing.lg)
                .padding(.bottom, CCSpacing.xxl)
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

// MARK: - Step Card

struct StepCard: View {
    let number: String
    let title: String
    var command: String? = nil
    var description: String? = nil
    var isCopied: Bool = false
    var onCopy: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: CCSpacing.md) {
            // 步骤编号
            Text(number)
                .font(.ccHeadline)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(CCColor.accentClaude)
                .clipShape(Circle())

            // 内容
            VStack(alignment: .leading, spacing: CCSpacing.xs) {
                Text(title)
                    .font(.ccHeadline)
                    .foregroundColor(CCColor.textPrimary)

                if let command = command {
                    HStack {
                        Text(command)
                            .font(.ccCode)
                            .foregroundColor(CCColor.terminalText)

                        Spacer()

                        if let onCopy = onCopy {
                            Button(action: onCopy) {
                                HStack(spacing: CCSpacing.xxs) {
                                    Image(systemName: isCopied ? "checkmark" : CCIcon.copy)
                                    Text(isCopied ? "已复制" : "复制")
                                }
                                .font(.ccCaption)
                                .foregroundColor(isCopied ? CCColor.accentSuccess : CCColor.accentPrimary)
                            }
                        }
                    }
                    .padding(CCSpacing.sm)
                    .background(CCColor.terminalBg)
                    .clipShape(RoundedRectangle(cornerRadius: CCRadius.sm))
                }

                if let description = description {
                    Text(description)
                        .font(.ccCaption)
                        .foregroundColor(CCColor.textSecondary)
                }
            }

            Spacer()
        }
        .padding(CCSpacing.md)
        .background(CCColor.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: CCRadius.md))
    }
}

#Preview {
    OnboardingView(showOnboarding: .constant(true))
}
