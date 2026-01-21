//
//  SessionListView.swift
//  cc connect
//
//  Design System v2.0 - 会话列表页
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
            .navigationTitle("CC Connect")
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

                // 新建连接按钮
                AddNewButton(action: { showScanView = true })
                    .padding(.top, CCSpacing.sm)
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

struct EmptyStateView: View {
    let onScan: () -> Void

    var body: some View {
        VStack(spacing: CCSpacing.xxl) {
            Spacer()

            // 图标
            Image(systemName: CCIcon.empty)
                .font(.system(size: 60))
                .foregroundColor(CCColor.textTertiary)

            // 文字
            VStack(spacing: CCSpacing.md) {
                Text("还没有连接")
                    .font(.ccTitle2)
                    .foregroundColor(CCColor.textPrimary)

                Text("连接你的 Mac，随时随地\n控制 Claude Code")
                    .font(.ccBody)
                    .foregroundColor(CCColor.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // 按钮
            CCPrimaryButton(
                title: "扫码连接",
                action: onScan,
                icon: CCIcon.scan
            )
            .padding(.horizontal, CCSpacing.xxxxl)

            Spacer()
        }
        .padding(CCSpacing.lg)
    }
}

// MARK: - Section Header

struct SectionHeaderView: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: CCSpacing.xs) {
            Image(systemName: icon)
                .font(.caption)
            Text(title)
                .font(.ccCaption)
        }
        .foregroundColor(CCColor.textSecondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, CCSpacing.xs)
    }
}

// MARK: - Session Card

struct CCSessionCard: View {
    let session: Session
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            CCHaptic.light()
            onTap()
        }) {
            VStack(alignment: .leading, spacing: CCSpacing.sm) {
                // 头部：状态 + 名称 + 徽章
                HStack(spacing: CCSpacing.sm) {
                    CCStatusIndicator(status: session.status)

                    Text(session.name)
                        .font(.ccHeadline)
                        .foregroundColor(CCColor.textPrimary)

                    Spacer()

                    // 需要输入徽章
                    if session.status == .waiting {
                        Text("需要输入")
                            .font(.ccCaption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, CCSpacing.sm)
                            .padding(.vertical, CCSpacing.xxs)
                            .background(CCColor.accentWarning)
                            .clipShape(Capsule())
                    }
                }

                // 元信息
                HStack(spacing: CCSpacing.xs) {
                    Text(session.status.displayText)
                        .font(.ccFootnote)
                        .foregroundColor(CCColor.textSecondary)
                    Text("·")
                        .foregroundColor(CCColor.textTertiary)
                    Text(session.lastActivity.timeAgo)
                        .font(.ccFootnote)
                        .foregroundColor(CCColor.textTertiary)
                }

                // 最后消息预览
                if let lastMessage = session.messages.last {
                    Text("> \(lastMessage.content)")
                        .font(.ccCodeSmall)
                        .foregroundColor(CCColor.textTertiary)
                        .lineLimit(1)
                }
            }
            .padding(CCSpacing.lg)
            .background(CCColor.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: CCRadius.md))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add New Button

struct AddNewButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: {
            CCHaptic.light()
            action()
        }) {
            HStack(spacing: CCSpacing.sm) {
                Image(systemName: CCIcon.add)
                Text("扫码新建连接")
            }
            .font(.ccHeadline)
            .foregroundColor(CCColor.accentPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: CCSize.buttonHeight)
            .background(CCColor.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: CCRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: CCRadius.md)
                    .stroke(CCColor.borderDefault, lineWidth: 1)
            )
        }
    }
}

#Preview {
    SessionListView()
}
