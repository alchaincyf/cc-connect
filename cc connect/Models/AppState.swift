//
//  AppState.swift
//  cc connect
//
//  Created by alchain on 2026/1/21.
//

import Foundation
import SwiftUI

// MARK: - App State
@Observable
final class AppState {
    // MARK: - Singleton
    static let shared = AppState()

    // MARK: - State
    var isFirstLaunch: Bool {
        get { !UserDefaults.standard.bool(forKey: "hasLaunched") }
        set { UserDefaults.standard.set(!newValue, forKey: "hasLaunched") }
    }

    var currentSessionId: String?
    var isConnecting: Bool = false
    var connectionError: String?

    // MARK: - Navigation
    var showOnboarding: Bool = true
    var selectedTab: Tab = .sessions

    enum Tab {
        case sessions
        case settings
    }

    // MARK: - Notifications
    var notificationEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "notificationEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "notificationEnabled") }
    }

    var notifyOnComplete: Bool {
        get { UserDefaults.standard.object(forKey: "notifyOnComplete") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "notifyOnComplete") }
    }

    var notifyOnInput: Bool {
        get { UserDefaults.standard.object(forKey: "notifyOnInput") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "notifyOnInput") }
    }

    var notifyOnError: Bool {
        get { UserDefaults.standard.object(forKey: "notifyOnError") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "notifyOnError") }
    }

    // MARK: - Init
    private init() {
        showOnboarding = isFirstLaunch
    }

    // MARK: - Methods
    func completeOnboarding() {
        isFirstLaunch = false
        showOnboarding = false
    }

    func reset() {
        UserDefaults.standard.removeObject(forKey: "hasLaunched")
        showOnboarding = true
    }
}

// MARK: - Session Store
@Observable
final class SessionStore {
    // MARK: - State
    var sessions: [Session] = []
    var currentSession: Session?

    // Mock data for development
    func loadMockData() {
        let session1 = Session(
            name: "项目重构任务",
            status: .running,
            lastActivity: Date(),
            isConnected: true,
            deviceName: "MacBook Pro"
        )
        session1.messages = [
            Message(type: .claude, content: "Analyzing codebase..."),
            Message(type: .claude, content: "Found 15 files to process"),
            Message(type: .claude, content: "Processing src/components...")
        ]

        let session2 = Session(
            name: "API开发",
            status: .waiting,
            lastActivity: Date().addingTimeInterval(-60),
            isConnected: true,
            deviceName: "MacBook Pro"
        )
        session2.messages = [
            Message(type: .claude, content: "Creating API endpoint"),
            Message(type: .system, content: "确认创建以下文件？\n• src/api/user.ts\n• src/types/user.ts")
        ]

        let session3 = Session(
            name: "Bug修复",
            status: .idle,
            lastActivity: Date().addingTimeInterval(-3600),
            isConnected: true,
            deviceName: "MacBook Pro"
        )
        session3.messages = [
            Message(type: .claude, content: "Task completed"),
            Message(type: .claude, content: "Fixed 3 bugs"),
            Message(type: .system, content: "All tests passing ✓")
        ]

        sessions = [session1, session2, session3]
    }
}
