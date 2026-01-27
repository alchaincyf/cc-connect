//
//  SessionListView.swift
//  cc connect
//
//  Design System v3.0 - MUJI 风格会话列表页
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

    /// 活跃连接（正在连接或已连接）
    private var activeSessions: [Session] {
        sessions.filter { $0.isActive }
    }

    /// 历史会话（未连接）
    private var historySessions: [Session] {
        sessions.filter { !$0.isActive }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景色
                CCColor.bgPrimary.ignoresSafeArea()

                if sessions.isEmpty {
                    EmptyStateView(onScan: { showScanView = true })
                } else {
                    sessionList
                }
            }
            .navigationTitle("Peanut")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(CCColor.bgPrimary, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: CCIcon.settings)
                            .foregroundColor(CCColor.textPrimary)
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

                // 历史记录区
                if !historySessions.isEmpty {
                    SectionHeaderView(
                        title: "历史记录",
                        icon: CCIcon.history
                    )
                    .padding(.top, activeSessions.isEmpty ? 0 : CCSpacing.md)

                    ForEach(historySessions) { session in
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

/// 空状态 - MUJI 风格：极简文字，大量留白
struct EmptyStateView: View {
    let onScan: () -> Void

    var body: some View {
        VStack(spacing: CCSpacing.xxxl) {
            Spacer()

            // 文字 - 无图标，纯文字
            VStack(spacing: CCSpacing.md) {
                Text("尚无连接")
                    .font(.ccBody)
                    .foregroundColor(CCColor.textPrimary)

                Text("扫码连接你的 Mac")
                    .font(.ccCaption)
                    .foregroundColor(CCColor.textTertiary)
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
    }
}

// MARK: - Section Header

/// 区域头部 - MUJI 风格：极简，无图标
struct SectionHeaderView: View {
    let title: String
    let icon: String  // 保留参数但不使用

    var body: some View {
        Text(title)
            .font(.ccCaption)
            .foregroundColor(CCColor.textTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, CCSpacing.xs)
            .padding(.vertical, CCSpacing.xs)
    }
}

// MARK: - Session Card

/// 会话卡片 - MUJI 风格：极简，大留白
struct CCSessionCard: View {
    let session: Session
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            CCHaptic.light()
            onTap()
        }) {
            HStack(spacing: CCSpacing.md) {
                // 左侧状态指示线
                Rectangle()
                    .fill(CCColor.statusColor(for: session.status))
                    .frame(width: 3)
                    .clipShape(RoundedRectangle(cornerRadius: 1.5))

                // 内容
                VStack(alignment: .leading, spacing: CCSpacing.xs) {
                    // 名称
                    Text(session.name)
                        .font(.ccBody)
                        .foregroundColor(CCColor.textPrimary)

                    // 状态 + 时间
                    Text("\(session.status.displayText) · \(session.lastActivity.timeAgo)")
                        .font(.ccCaption)
                        .foregroundColor(CCColor.textTertiary)
                }

                Spacer()

                // 需要输入时显示小圆点
                if session.status == .waiting {
                    Circle()
                        .fill(CCColor.accentWarning)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.vertical, CCSpacing.md)
            .padding(.horizontal, CCSpacing.lg)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Scan Button (顶部主按钮)

/// 扫码按钮 - MUJI 风格：简洁但明显的主操作入口
struct ScanButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: {
            CCHaptic.medium()
            action()
        }) {
            HStack(spacing: CCSpacing.md) {
                Image(systemName: CCIcon.scan)
                    .font(.system(size: 20))

                Text("扫码连接")
                    .font(.ccHeadline)
            }
            .foregroundColor(CCColor.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: CCSize.buttonHeight)
            .background(CCColor.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: CCRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: CCRadius.md)
                    .stroke(CCColor.borderDefault, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SessionListView()
}
