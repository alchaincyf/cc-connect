//
//  CCConnectApp.swift
//  cc connect
//
//  Created by alchain on 2026/1/21.
//

import SwiftUI
import SwiftData

@main
struct CCConnectApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(AppState.shared)
        }
        .modelContainer(for: [Session.self, Message.self])
    }
}

// MARK: - Root View
struct RootView: View {
    @Environment(AppState.self) private var appState
    @State private var isReady = false

    var body: some View {
        ZStack {
            if isReady {
                Group {
                    if appState.showOnboarding {
                        OnboardingView(showOnboarding: Binding(
                            get: { appState.showOnboarding },
                            set: { appState.showOnboarding = $0 }
                        ))
                    } else {
                        SessionListView()
                    }
                }
                .transition(.opacity)
            } else {
                LaunchScreenView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isReady)
        .onAppear {
            // 短暂延迟后显示主界面，让 SwiftData 初始化完成
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isReady = true
            }
        }
    }
}

// MARK: - Launch Screen
struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            Color.ccBackground
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 48))
                    .foregroundColor(.ccPrimary)

                Text("Peanut")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.ccTextPrimary)
            }
        }
    }
}

#Preview {
    RootView()
        .environment(AppState.shared)
}
