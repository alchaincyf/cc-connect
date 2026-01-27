//
//  Colors.swift
//  cc connect
//
//  Design System v4.0 - Glassmorphism 玻璃拟态设计
//  科技感、层次感、现代感
//

import SwiftUI
import UIKit

// MARK: - Design Tokens

/// Peanut 设计系统色彩 - Glassmorphism 风格
enum CCColor {

    // MARK: - Background Colors (深色玻璃背景)

    /// 主背景色 - 深邃的科技黑
    /// Dark: #0A0A0F (近纯黑), Light: #F0F2F5 (冷灰白)
    static let bgPrimary = Color.adaptive(dark: "0A0A0F", light: "F0F2F5")

    /// 次级背景色 - 玻璃卡片底色
    /// Dark: #12121A, Light: #FFFFFF
    static let bgSecondary = Color.adaptive(dark: "12121A", light: "FFFFFF")

    /// 三级背景色 - 输入框、次级容器
    /// Dark: #1A1A24, Light: #F5F6F8")
    static let bgTertiary = Color.adaptive(dark: "1A1A24", light: "F5F6F8")

    /// 浮层背景色 - 弹窗、Sheet
    /// Dark: #1E1E28, Light: #FFFFFF
    static let bgElevated = Color.adaptive(dark: "1E1E28", light: "FFFFFF")

    // MARK: - Glass Effect Colors (玻璃效果专用)

    /// 玻璃背景 - 半透明白
    static let glassBg = Color.white.opacity(0.08)

    /// 玻璃背景（浅色模式）
    static let glassBgLight = Color.white.opacity(0.7)

    /// 玻璃边框 - 亮边效果
    static let glassBorder = Color.white.opacity(0.12)

    /// 玻璃高光 - 顶部亮线
    static let glassHighlight = Color.white.opacity(0.15)

    /// 玻璃阴影
    static let glassShadow = Color.black.opacity(0.3)

    // MARK: - Border Colors (边框色 - 微光效果)

    /// 默认边框 - 微弱发光感
    /// Dark: rgba(255,255,255,0.1), Light: #E2E4E8
    static let borderDefault = Color.adaptive(dark: "FFFFFF", light: "E2E4E8").opacity(0.1)

    /// 弱化边框
    static let borderMuted = Color.adaptive(dark: "FFFFFF", light: "EEEEEE").opacity(0.06)

    /// 发光边框 - 用于选中状态
    static let borderGlow = Color.adaptive(dark: "007AFF", light: "007AFF")

    // MARK: - Text Colors (文字色 - 高对比度)

    /// 主要文字 - 纯净白/深黑
    /// Dark: #F8FAFC, Light: #0F172A
    static let textPrimary = Color.adaptive(dark: "F8FAFC", light: "0F172A")

    /// 次要文字
    /// Dark: #94A3B8, Light: #475569
    static let textSecondary = Color.adaptive(dark: "94A3B8", light: "475569")

    /// 辅助文字
    /// Dark: #64748B, Light: #64748B
    static let textTertiary = Color.adaptive(dark: "64748B", light: "64748B")

    /// 禁用文字
    /// Dark: #475569, Light: #CBD5E1
    static let textDisabled = Color.adaptive(dark: "475569", light: "CBD5E1")

    /// 链接文字 - 电光蓝
    static let textLink = Color.adaptive(dark: "60A5FA", light: "2563EB")

    // MARK: - Accent Colors (强调色 - 科技感)

    /// 主强调色 - 电光蓝（Apple 风格）
    static let accentPrimary = Color.adaptive(dark: "007AFF", light: "007AFF")

    /// Claude/AI 品牌色 - 渐变青蓝
    static let accentClaude = Color.adaptive(dark: "00D4AA", light: "00B894")

    /// 成功色 - 霓虹绿
    static let accentSuccess = Color.adaptive(dark: "10B981", light: "059669")

    /// 警告色 - 琥珀橙
    static let accentWarning = Color.adaptive(dark: "F59E0B", light: "D97706")

    /// 危险色 - 玫红
    static let accentDanger = Color.adaptive(dark: "EF4444", light: "DC2626")

    /// 信息色 - 电光蓝
    static let accentInfo = Color.adaptive(dark: "3B82F6", light: "2563EB")

    // MARK: - Glow Colors (发光效果)

    /// 主强调色发光
    static let glowPrimary = Color(hex: "007AFF").opacity(0.4)

    /// Claude 色发光
    static let glowClaude = Color(hex: "00D4AA").opacity(0.4)

    /// 成功色发光
    static let glowSuccess = Color(hex: "10B981").opacity(0.4)

    /// 警告色发光
    static let glowWarning = Color(hex: "F59E0B").opacity(0.4)

    // MARK: - Terminal Colors (终端色 - 高对比度)

    /// 终端背景
    static let terminalBg = Color(hex: "0A0A0F")

    /// 终端默认文字
    static let terminalText = Color(hex: "E2E8F0")

    /// 终端注释/行号
    static let terminalComment = Color(hex: "64748B")

    /// 终端关键字 - 粉紫
    static let terminalKeyword = Color(hex: "F472B6")

    /// 终端字符串 - 青绿
    static let terminalString = Color(hex: "34D399")

    /// 终端数字 - 橙色
    static let terminalNumber = Color(hex: "FB923C")

    /// 终端函数名 - 蓝色
    static let terminalFunction = Color(hex: "60A5FA")

    /// 终端变量 - 紫色
    static let terminalVariable = Color(hex: "A78BFA")

    /// 终端类型 - 黄色
    static let terminalType = Color(hex: "FBBF24")

    // MARK: - Semantic Colors (语义色背景)

    /// 成功背景
    static let successBg = Color(hex: "10B981").opacity(0.15)

    /// 警告背景
    static let warningBg = Color(hex: "F59E0B").opacity(0.15)

    /// 错误背景
    static let dangerBg = Color(hex: "EF4444").opacity(0.15)

    /// 信息背景
    static let infoBg = Color(hex: "3B82F6").opacity(0.15)

    // MARK: - Status Colors

    /// 获取状态对应的颜色
    static func statusColor(for status: SessionStatus) -> Color {
        switch status {
        case .running:
            return accentSuccess
        case .waiting:
            return accentWarning
        case .idle:
            return accentClaude
        case .error:
            return accentDanger
        case .disconnected:
            return textDisabled
        }
    }

    /// 获取状态发光色
    static func statusGlowColor(for status: SessionStatus) -> Color {
        switch status {
        case .running:
            return glowSuccess
        case .waiting:
            return glowWarning
        case .idle:
            return glowClaude
        case .error:
            return Color(hex: "EF4444").opacity(0.4)
        case .disconnected:
            return Color.clear
        }
    }
}

// MARK: - Legacy Compatibility

extension Color {
    static let ccPrimary = CCColor.accentPrimary
    static let ccPrimaryVariant = CCColor.accentPrimary
    static let ccSuccess = CCColor.accentSuccess
    static let ccWarning = CCColor.accentWarning
    static let ccError = CCColor.accentDanger
    static let ccInfo = CCColor.accentInfo

    static let ccBackground = CCColor.bgPrimary
    static let ccSurface = CCColor.bgSecondary
    static let ccSurfaceSecondary = CCColor.bgTertiary
    static let ccBorder = CCColor.borderDefault

    static let ccTextPrimary = CCColor.textPrimary
    static let ccTextSecondary = CCColor.textSecondary
    static let ccTextTertiary = CCColor.textTertiary

    static let ccTerminalBG = CCColor.terminalBg
    static let ccTerminalText = CCColor.terminalText
    static let ccTerminalGreen = CCColor.terminalString
    static let ccTerminalYellow = CCColor.terminalType
    static let ccTerminalRed = CCColor.terminalKeyword
    static let ccTerminalBlue = CCColor.terminalFunction
}

// MARK: - Hex Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            alpha: Double(a) / 255
        )
    }
}

// MARK: - Adaptive Color Helper

extension Color {
    /// 创建自适应颜色（深色/浅色模式）
    static func adaptive(dark: String, light: String) -> Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(hex: dark)
                : UIColor(hex: light)
        })
    }
}

// MARK: - Glass Effect Modifiers

extension View {
    /// 玻璃拟态背景效果
    func glassBackground(
        cornerRadius: CGFloat = CCRadius.lg,
        blur: CGFloat = 20,
        opacity: CGFloat = 0.08,
        showBorder: Bool = false  // 默认不显示边框，更简洁
    ) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .opacity(0.8)
            )
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(opacity))
            )
            .overlay(
                showBorder ?
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(CCColor.glassBorder, lineWidth: 0.5) : nil
            )
    }

    /// 玻璃卡片效果（带阴影，无边框）
    func glassCard(cornerRadius: CGFloat = CCRadius.lg) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
            )
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(CCColor.glassBg)
            )
            .shadow(color: CCColor.glassShadow.opacity(0.3), radius: 12, x: 0, y: 4)
    }

    /// 发光边框效果
    func glowBorder(color: Color, radius: CGFloat = CCRadius.md) -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(color.opacity(0.5), lineWidth: 1)
            )
            .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 0)
    }

    /// 内发光效果
    func innerGlow(color: Color, radius: CGFloat = 10) -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: CCRadius.md)
                    .stroke(color.opacity(0.3), lineWidth: 2)
                    .blur(radius: 4)
            )
    }
}
