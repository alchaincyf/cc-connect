//
//  StartupOptionsView.swift
//  cc connect
//
//  Design System v3.0 - 扫码成功后的启动选项
//  提供启动 Claude Code 的选项
//

import SwiftUI

/// 扫码成功后的启动选项视图
struct StartupOptionsView: View {
    let session: Session
    let onStartClaude: () -> Void
    let onStartWithFlags: () -> Void
    let onWait: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // 成功提示
            VStack(spacing: CCSpacing.md) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 48))
                    .foregroundColor(CCColor.accentSuccess)

                Text("连接成功")
                    .font(.ccTitle2)
                    .foregroundColor(CCColor.textPrimary)

                Text("已连接到 \(session.deviceName ?? "Mac")")
                    .font(.ccCaption)
                    .foregroundColor(CCColor.textTertiary)
            }

            Spacer()
                .frame(height: CCSpacing.xxxl)

            // 启动选项
            VStack(spacing: CCSpacing.lg) {
                // 主选项：启动 Claude Code
                Button(action: onStartClaude) {
                    VStack(spacing: CCSpacing.sm) {
                        Text("启动 Claude Code")
                            .font(.ccBody)
                            .foregroundColor(CCColor.bgPrimary)

                        Text("发送 'claude' 命令")
                            .font(.ccCaption)
                            .foregroundColor(CCColor.bgPrimary.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: CCSize.buttonHeightLarge)
                    .background(CCColor.accentPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: CCRadius.lg))
                }

                // 次要选项：高级模式
                Button(action: onStartWithFlags) {
                    HStack {
                        VStack(alignment: .leading, spacing: CCSpacing.xxs) {
                            Text("跳过权限确认")
                                .font(.ccSubheadline)
                                .foregroundColor(CCColor.textPrimary)

                            Text("claude --dangerously-skip-permissions")
                                .font(.ccCodeSmall)
                                .foregroundColor(CCColor.textTertiary)
                        }

                        Spacer()

                        Image(systemName: "bolt.fill")
                            .font(.system(size: 16))
                            .foregroundColor(CCColor.accentWarning)
                    }
                    .padding(CCSpacing.lg)
                    .background(CCColor.bgSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: CCRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: CCRadius.md)
                            .stroke(CCColor.borderMuted, lineWidth: 1)
                    )
                }

                // 等待选项
                Button(action: onWait) {
                    Text("稍后再说")
                        .font(.ccCaption)
                        .foregroundColor(CCColor.textTertiary)
                }
                .padding(.top, CCSpacing.sm)
            }
            .padding(.horizontal, CCSpacing.xxl)

            Spacer()
        }
        .background(CCColor.bgPrimary.ignoresSafeArea())
    }
}

#Preview {
    StartupOptionsView(
        session: Session(name: "测试", status: .idle, lastActivity: Date()),
        onStartClaude: {},
        onStartWithFlags: {},
        onWait: {}
    )
}
