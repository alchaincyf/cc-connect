//
//  SettingsView.swift
//  cc connect
//
//  Created by alchain on 2026/1/21.
//

import SwiftUI

struct SettingsView: View {
    @State private var notifyOnComplete = true
    @State private var notifyOnInput = true
    @State private var notifyOnError = true

    var body: some View {
        List {
            // Notification Settings
            Section {
                Toggle("任务完成通知", isOn: $notifyOnComplete)
                Toggle("需要输入通知", isOn: $notifyOnInput)
                Toggle("错误通知", isOn: $notifyOnError)
            } header: {
                Text("通知设置")
            }

            // Connection Management
            Section {
                NavigationLink {
                    ConnectedDevicesView()
                } label: {
                    HStack {
                        Text("已连接设备")
                        Spacer()
                        Text("1")
                            .foregroundColor(.ccTextTertiary)
                    }
                }
            } header: {
                Text("连接管理")
            }

            // About
            Section {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.ccTextTertiary)
                }

                NavigationLink {
                    HelpView()
                } label: {
                    Text("帮助文档")
                }

                Link(destination: URL(string: "mailto:feedback@cc-connect.app")!) {
                    Text("反馈问题")
                }

                NavigationLink {
                    PrivacyPolicyView()
                } label: {
                    Text("隐私政策")
                }
            } header: {
                Text("关于")
            }

            // Debug (only in development)
            #if DEBUG
            Section {
                Button("重置引导") {
                    UserDefaults.standard.removeObject(forKey: "hasLaunched")
                }
                .foregroundColor(.ccError)
            } header: {
                Text("调试")
            }
            #endif
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Connected Devices View
struct ConnectedDevicesView: View {
    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: CCSpacing.xs) {
                        Text("MacBook Pro")
                            .font(.ccHeadline)
                        Text("已连接")
                            .font(.ccFootnote)
                            .foregroundColor(.ccSuccess)
                    }
                    Spacer()
                    Image(systemName: "laptopcomputer")
                        .foregroundColor(.ccTextSecondary)
                }
            }
        }
        .navigationTitle("已连接设备")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Help View
struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CCSpacing.xxl) {
                HelpSection(
                    title: "如何连接？",
                    content: """
                    1. 在 Mac 终端安装 CLI：
                       brew install cc-connect
                    2. 运行命令：cc start
                    3. 打开 App 扫描终端上显示的二维码
                    """
                )

                HelpSection(
                    title: "连接断开怎么办？",
                    content: """
                    请确保：
                    • Mac 上的 cc-cli 正在运行
                    • 手机网络连接正常
                    • 如仍无法连接，尝试重新扫码
                    """
                )

                HelpSection(
                    title: "如何发送输入？",
                    content: """
                    当 Claude Code 需要输入时：
                    • 使用快捷按钮（是/否/继续）
                    • 或输入自定义文本后点击发送
                    """
                )
            }
            .padding(CCSpacing.lg)
        }
        .navigationTitle("帮助文档")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HelpSection: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: CCSpacing.md) {
            Text(title)
                .font(.ccHeadline)
                .foregroundColor(.ccTextPrimary)

            Text(content)
                .font(.ccBody)
                .foregroundColor(.ccTextSecondary)
        }
    }
}

// MARK: - Privacy Policy View
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CCSpacing.lg) {
                Text("""
                CC Connect 隐私政策

                最后更新：2026年1月

                1. 数据收集
                我们收集的数据仅用于提供服务功能：
                • 设备推送 Token（用于发送通知）
                • 会话连接信息（用于消息转发）

                2. 数据存储
                • 消息内容仅在传输时经过我们的服务器，不会持久存储
                • 会话信息在设备本地存储

                3. 数据安全
                • 所有通信使用 HTTPS/WSS 加密传输
                • 我们不会将您的数据出售给第三方

                4. 联系我们
                如有疑问，请联系：privacy@cc-connect.app
                """)
                .font(.ccBody)
                .foregroundColor(.ccTextSecondary)
            }
            .padding(CCSpacing.lg)
        }
        .navigationTitle("隐私政策")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
