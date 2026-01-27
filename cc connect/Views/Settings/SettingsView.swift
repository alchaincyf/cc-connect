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
                    Text("1.3.0")
                        .foregroundColor(.ccTextTertiary)
                }

                NavigationLink {
                    HelpView()
                } label: {
                    Text("帮助文档")
                }

                Link(destination: URL(string: "mailto:alchaincyf@gmail.com")!) {
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
                       npm install -g peanut-cc@latest
                    2. 安装 Hooks 配置（首次必须）：
                       peanut install-hooks
                    3. 启动会话：peanut start
                    4. 打开 App 扫描终端上显示的二维码
                    """
                )

                HelpSection(
                    title: "连接断开怎么办？",
                    content: """
                    请确保：
                    • Mac 上的 peanut 正在运行
                    • 手机网络连接正常
                    • 如仍无法连接，尝试重新扫码

                    常见问题：
                    • 端口被占用：kill -9 $(lsof -t -i:19789)
                    • Hooks 未配置：peanut install-hooks
                    """
                )

                HelpSection(
                    title: "如何发送输入？",
                    content: """
                    当 Claude Code 需要输入时：
                    • 使用快捷按钮（允许/拒绝/始终允许）
                    • 或输入自定义文本后点击发送
                    • 点击中断按钮可发送 Ctrl+C 中断当前任务
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
                Peanut 隐私政策

                最后更新：2026年1月

                1. 数据收集
                我们收集的数据仅用于提供服务功能：
                • 设备推送 Token（用于发送通知）
                • 会话连接信息（用于消息转发）

                2. 数据存储
                • 消息内容仅在传输时经过中继服务器，不会持久存储
                • 会话信息在设备本地存储（SwiftData）
                • 中继服务器不记录任何消息内容

                3. 数据安全
                • 所有通信使用 HTTPS/WSS 加密传输
                • 中继服务器基于 Cloudflare Workers，符合行业安全标准
                • 我们不会将您的数据出售给第三方

                4. 开源
                • CLI 工具和中继服务器代码完全开源
                • 您可以自行部署私有中继服务器

                5. 联系我们
                如有疑问，请联系：alchaincyf@gmail.com
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
