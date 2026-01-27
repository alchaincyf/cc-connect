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
                .preferredColorScheme(.dark)  // 强制深色模式，玻璃拟态效果更佳
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
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // 深邃背景
            CCColor.bgPrimary
                .ignoresSafeArea()

            // 背景光晕
            Circle()
                .fill(CCColor.accentClaude.opacity(0.1))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(y: -50)

            Circle()
                .fill(CCColor.accentPrimary.opacity(0.08))
                .frame(width: 200, height: 200)
                .blur(radius: 60)
                .offset(x: 80, y: 100)

            // Logo
            VStack(spacing: CCSpacing.lg) {
                ZStack {
                    // 发光层
                    Circle()
                        .fill(CCColor.accentClaude.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .blur(radius: 20)
                        .scaleEffect(isAnimating ? 1.2 : 0.8)
                        .opacity(isAnimating ? 0.6 : 0.3)

                    Image(systemName: "sparkles")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [CCColor.accentClaude, CCColor.accentPrimary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Text("Peanut")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [CCColor.textPrimary, CCColor.textSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    RootView()
        .environment(AppState.shared)
}
