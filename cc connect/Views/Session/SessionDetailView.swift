//
//  SessionDetailView.swift
//  cc connect
//
//  Design System v4.0 - Glassmorphism 玻璃拟态会话详情页
//  玻璃消息展示 + 思考状态指示器 + 权限请求 Sheet
//

import SwiftUI
import SwiftData

struct SessionDetailView: View {
    @Bindable var session: Session
    @StateObject private var wsManager = WebSocketManager()

    @State private var inputText = ""
    @State private var showPermissionSheet = false
    @State private var showSelectionSheet = false
    @State private var pendingPermission: CCMessage?
    @State private var pendingSelection: CCMessage?
    @State private var scrollTrigger = false  // 触发滚动到底部
    @State private var hasConnected = false   // 防止重复连接

    @FocusState private var isInputFocused: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            // 深邃背景
            CCColor.bgPrimary.ignoresSafeArea()

            // 背景装饰光晕
            GeometryReader { geo in
                Circle()
                    .fill(CCColor.accentClaude.opacity(0.05))
                    .frame(width: geo.size.width * 0.5)
                    .blur(radius: 60)
                    .offset(x: geo.size.width * 0.6, y: geo.size.height * 0.1)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // 消息列表
                CCMessageList(
                    messages: wsManager.messages,
                    onTap: dismissKeyboard,
                    scrollToBottomTrigger: scrollTrigger,
                    initialMessageCount: wsManager.initialMessageCount
                )

                // 思考状态指示器 - 仅当思考但没有具体状态文字时显示
                if wsManager.isThinking && wsManager.statusBarText == nil {
                    CCThinkingIndicator()
                        .padding(.horizontal, CCSpacing.xl)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                // 交互区域（简单问题/确认）- 不包括权限请求和选择对话
                if let interaction = wsManager.currentInteraction,
                   interaction.type != .permissionRequest,
                   interaction.type != .selectionDialog {
                    CCInteractionBar(
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
                CCChatInputBar(
                    text: $inputText,
                    isFocused: $isInputFocused,
                    onSend: sendMessage,
                    onInterrupt: { wsManager.sendInterrupt() }
                )
            }
            .animation(.easeInOut(duration: 0.2), value: wsManager.isThinking)

            // 状态栏浮层
            if let statusText = wsManager.statusBarText {
                CCStatusOverlay(text: statusText)
                    .padding(.bottom, CCSize.inputBarHeight + CCSpacing.sm)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.2), value: wsManager.statusBarText)
            }
        }
        .navigationTitle(session.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(CCColor.bgPrimary, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                CCConnectionBadge(state: wsManager.connectionState)
            }
        }
        .onAppear {
            connectWebSocket()
        }
        .onDisappear {
            print("🔴 SessionDetailView 消失，断开连接")
            wsManager.disconnect()
            hasConnected = false
        }
        .onChange(of: isInputFocused) { _, isFocused in
            // 键盘弹出时滚动到底部
            if isFocused {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    scrollTrigger.toggle()
                }
            }
        }
        .onChange(of: wsManager.currentInteraction) { _, newValue in
            guard let interaction = newValue else { return }

            // 权限请求使用 Sheet 弹出
            if interaction.type == .permissionRequest {
                pendingPermission = interaction
                showPermissionSheet = true
            }
            // 选择对话使用 Sheet 弹出
            else if interaction.type == .selectionDialog {
                pendingSelection = interaction
                showSelectionSheet = true
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
        .sheet(isPresented: $showSelectionSheet) {
            if let selection = pendingSelection {
                CCSelectionSheet(
                    message: selection,
                    onSelect: { option in
                        wsManager.respondToInteraction(option: option)
                        pendingSelection = nil
                    },
                    onInput: { text in
                        wsManager.sendInput(text)
                        pendingSelection = nil
                    }
                )
            }
        }
    }

    // MARK: - Actions

    private func dismissKeyboard() {
        isInputFocused = false
    }

    private func connectWebSocket() {
        // 防止重复连接
        guard !hasConnected else {
            print("⚠️ 已连接，跳过重复连接")
            return
        }
        guard let secret = session.secret else {
            print("⚠️ 无 secret，无法连接")
            return
        }

        hasConnected = true
        print("🔵 SessionDetailView 连接 WebSocket: \(session.id)")

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

// MARK: - Preview

#Preview {
    NavigationStack {
        SessionDetailView(session: Session(
            name: "测试会话",
            status: .running,
            lastActivity: Date()
        ))
    }
}
