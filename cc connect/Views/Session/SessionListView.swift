//
//  SessionListView.swift
//  cc connect
//
//  Design System v4.0 - Glassmorphism 玻璃拟态会话列表页
//

import SwiftUI
import SwiftData

struct SessionListView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Session.lastActivity, order: .reverse)
    private var sessions: [Session]

    @State private var showScanView = false
    @State private var selectedSession: Session?
    @State private var sessionToDelete: Session?
    @State private var showDeleteConfirmation = false

    /// 活跃连接（当前正在连接或状态为活跃）
    private var activeSessions: [Session] {
        sessions.filter { $0.isActive || $0.status.isActiveStatus }
    }

    /// 已断开的会话
    private var disconnectedSessions: [Session] {
        sessions.filter { !$0.isActive && !$0.status.isActiveStatus }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // 深邃背景
                CCColor.bgPrimary.ignoresSafeArea()

                // 背景装饰 - 渐变光晕
                GeometryReader { geo in
                    Circle()
                        .fill(CCColor.accentPrimary.opacity(0.08))
                        .frame(width: geo.size.width * 0.8)
                        .blur(radius: 80)
                        .offset(x: -geo.size.width * 0.3, y: -geo.size.height * 0.2)

                    Circle()
                        .fill(CCColor.accentClaude.opacity(0.05))
                        .frame(width: geo.size.width * 0.6)
                        .blur(radius: 60)
                        .offset(x: geo.size.width * 0.5, y: geo.size.height * 0.6)
                }
                .ignoresSafeArea()

                if sessions.isEmpty {
                    EmptyStateView(onScan: { showScanView = true })
                } else {
                    sessionList
                }
            }
            .navigationTitle("Peanut")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(CCColor.bgPrimary.opacity(0.8), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: CCIcon.settings)
                            .foregroundColor(CCColor.textPrimary)
                            .frame(width: 36, height: 36)
                            .glassBackground(cornerRadius: CCRadius.sm)
                    }
                }
            }
            .sheet(isPresented: $showScanView) {
                ScanView(onPaired: { session in
                    showScanView = false
                    selectedSession = session
                })
            }
            .navigationDestination(item: $selectedSession) { session in
                SessionDetailView(session: session)
            }
            .alert("删除会话", isPresented: $showDeleteConfirmation) {
                Button("取消", role: .cancel) {
                    sessionToDelete = nil
                }
                Button("删除", role: .destructive) {
                    if let session = sessionToDelete {
                        deleteSession(session)
                    }
                    sessionToDelete = nil
                }
            } message: {
                Text("确定要删除这个会话吗？所有聊天记录将被清除。")
            }
        }
    }

    // MARK: - Session List

    private var sessionList: some View {
        ScrollView {
            LazyVStack(spacing: CCSpacing.md) {
                // 顶部扫码按钮 - 首屏最重要的操作入口
                ScanButton(action: { showScanView = true })
                    .padding(.bottom, CCSpacing.md)

                // 活跃连接区
                if !activeSessions.isEmpty {
                    SectionHeaderView(
                        title: "活跃连接",
                        icon: CCIcon.active
                    )

                    ForEach(activeSessions) { session in
                        CCSessionCard(session: session) {
                            selectedSession = session
                        }
                    }
                }

                // 已断开的会话
                if !disconnectedSessions.isEmpty {
                    SectionHeaderView(
                        title: "已断开",
                        icon: CCIcon.history
                    )
                    .padding(.top, activeSessions.isEmpty ? 0 : CCSpacing.md)

                    ForEach(disconnectedSessions) { session in
                        CCSessionCard(session: session) {
                            selectedSession = session
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                sessionToDelete = session
                                showDeleteConfirmation = true
                            } label: {
                                Label("删除会话", systemImage: CCIcon.delete)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                sessionToDelete = session
                                showDeleteConfirmation = true
                            } label: {
                                Label("删除", systemImage: CCIcon.delete)
                            }
                        }
                    }
                }
            }
            .padding(CCSpacing.lg)
        }
    }

    private func deleteSession(_ session: Session) {
        CCHaptic.medium()
        modelContext.delete(session)
        try? modelContext.save()
    }
}

// MARK: - Empty State View

/// 空状态 - 玻璃拟态风格
struct EmptyStateView: View {
    let onScan: () -> Void
    @State private var isVisible = false

    var body: some View {
        VStack(spacing: CCSpacing.xxxl) {
            Spacer()

            // Logo + 文字
            VStack(spacing: CCSpacing.lg) {
                // 发光图标
                ZStack {
                    Circle()
                        .fill(CCColor.accentClaude.opacity(0.15))
                        .frame(width: 80, height: 80)
                        .blur(radius: 20)

                    Image(systemName: "sparkles")
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [CCColor.accentClaude, CCColor.accentPrimary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(spacing: CCSpacing.sm) {
                    Text("尚无连接")
                        .font(.ccHeadline)
                        .foregroundColor(CCColor.textPrimary)

                    Text("扫码连接你的 Mac")
                        .font(.ccBody)
                        .foregroundColor(CCColor.textSecondary)
                }
            }

            // 按钮
            CCPrimaryButton(
                title: "扫码连接",
                action: onScan,
                icon: CCIcon.scan
            )
            .padding(.horizontal, CCSpacing.xxxl)

            Spacer()
        }
        .padding(CCSpacing.xl)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Section Header

/// 区域头部 - 玻璃拟态：带图标
struct SectionHeaderView: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: CCSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(CCColor.textTertiary)

            Text(title)
                .font(.ccCaption)
                .foregroundColor(CCColor.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, CCSpacing.xs)
        .padding(.vertical, CCSpacing.xs)
    }
}

// MARK: - Session Card

/// 会话卡片 - 玻璃拟态：发光状态指示 + 玻璃背景
struct CCSessionCard: View {
    let session: Session
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            CCHaptic.light()
            onTap()
        }) {
            HStack(spacing: CCSpacing.md) {
                // 左侧发光状态指示线
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [
                                CCColor.statusColor(for: session.status),
                                CCColor.statusColor(for: session.status).opacity(0.5)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 3)
                    .shadow(color: CCColor.statusGlowColor(for: session.status), radius: 6, x: 0, y: 0)

                // 内容
                VStack(alignment: .leading, spacing: CCSpacing.xs) {
                    // 名称
                    Text(session.name)
                        .font(.ccHeadline)
                        .foregroundColor(CCColor.textPrimary)

                    // 最近消息预览
                    if let preview = session.lastMessagePreview {
                        Text(preview)
                            .font(.ccCaption)
                            .foregroundColor(CCColor.textSecondary)
                            .lineLimit(1)
                    }

                    // 状态 + 时间
                    HStack(spacing: CCSpacing.xs) {
                        Text(session.status.displayText)
                            .foregroundColor(CCColor.statusColor(for: session.status))
                        Text("·")
                            .foregroundColor(CCColor.textTertiary)
                        Text(session.lastActivity.timeAgo)
                            .foregroundColor(CCColor.textTertiary)
                    }
                    .font(.ccCaption)
                }

                Spacer()

                // 需要输入时显示脉冲圆点
                if session.status == .waiting {
                    CCStatusIndicator(status: .waiting, size: 10)
                }

                // 箭头
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(CCColor.textTertiary)
            }
            .padding(.vertical, CCSpacing.md)
            .padding(.horizontal, CCSpacing.lg)
            .glassBackground(cornerRadius: CCRadius.lg)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.15)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Scan Button (顶部主按钮)

/// 扫码按钮 - 玻璃拟态：发光边框 + 渐变高光
struct ScanButton: View {
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            CCHaptic.medium()
            action()
        }) {
            HStack(spacing: CCSpacing.md) {
                // 发光图标
                ZStack {
                    Circle()
                        .fill(CCColor.accentPrimary.opacity(0.2))
                        .frame(width: 36, height: 36)

                    Image(systemName: CCIcon.scan)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(CCColor.accentPrimary)
                }

                Text("扫码连接")
                    .font(.ccHeadline)
                    .foregroundColor(CCColor.textPrimary)

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(CCColor.textTertiary)
            }
            .padding(.horizontal, CCSpacing.lg)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .glassCard(cornerRadius: CCRadius.lg)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.15)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

#Preview {
    SessionListView()
}
