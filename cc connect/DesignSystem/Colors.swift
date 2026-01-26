//
//  Colors.swift
//  cc connect
//
//  Design System v3.0 - MUJI 风格色彩系统
//  极简、自然、克制的色彩体验
//

import SwiftUI
import UIKit

// MARK: - Design Tokens

/// CC Connect 设计系统色彩 - MUJI 风格
enum CCColor {

    // MARK: - Background Colors (背景色 - 纯净、呼吸感)

    /// 主背景色 - 页面背景
    /// Dark: #121212 (近黑), Light: #FAFAFA (米白)
    static let bgPrimary = Color.adaptive(dark: "121212", light: "FAFAFA")

    /// 次级背景色 - 卡片背景
    /// Dark: #1A1A1A, Light: #FFFFFF
    static let bgSecondary = Color.adaptive(dark: "1A1A1A", light: "FFFFFF")

    /// 三级背景色 - 输入框、次级容器
    /// Dark: #242424, Light: #F5F5F5
    static let bgTertiary = Color.adaptive(dark: "242424", light: "F5F5F5")

    /// 浮层背景色 - 弹窗、Sheet
    /// Dark: #2A2A2A, Light: #FFFFFF
    static let bgElevated = Color.adaptive(dark: "2A2A2A", light: "FFFFFF")

    // MARK: - Border Colors (边框色 - 细腻、低调)

    /// 默认边框
    /// Dark: #333333, Light: #E8E8E8
    static let borderDefault = Color.adaptive(dark: "333333", light: "E8E8E8")

    /// 弱化边框
    /// Dark: #2A2A2A, Light: #EEEEEE
    static let borderMuted = Color.adaptive(dark: "2A2A2A", light: "EEEEEE")

    // MARK: - Text Colors (文字色 - 舒适对比度)

    /// 主要文字
    /// Dark: #E0E0E0, Light: #1A1A1A
    static let textPrimary = Color.adaptive(dark: "E0E0E0", light: "1A1A1A")

    /// 次要文字
    /// Dark: #888888, Light: #666666
    static let textSecondary = Color.adaptive(dark: "888888", light: "666666")

    /// 辅助文字
    /// Dark: #666666, Light: #999999
    static let textTertiary = Color.adaptive(dark: "666666", light: "999999")

    /// 禁用文字
    /// Dark: #4A4A4A, Light: #BBBBBB
    static let textDisabled = Color.adaptive(dark: "4A4A4A", light: "BBBBBB")

    /// 链接文字 - 保持低调的蓝
    /// Dark: #7AA2D4, Light: #5A7DAF
    static let textLink = Color.adaptive(dark: "7AA2D4", light: "5A7DAF")

    // MARK: - Accent Colors (强调色 - 自然、温暖)

    /// Claude 品牌色 - 淡木色/深木色（MUJI 核心色）
    static let accentClaude = Color.adaptive(dark: "D4A574", light: "8B7355")

    /// 主强调色 - 与 Claude 品牌色一致
    static let accentPrimary = Color.adaptive(dark: "D4A574", light: "8B7355")

    /// 成功色 - 柔和绿
    static let accentSuccess = Color.adaptive(dark: "7CAE7A", light: "5D8A5B")

    /// 警告色 - 温暖橙（更柔和）
    static let accentWarning = Color.adaptive(dark: "D4A06A", light: "B8895A")

    /// 危险色 - 柔和红
    static let accentDanger = Color.adaptive(dark: "C27070", light: "A85A5A")

    /// 信息色 - 柔和蓝
    static let accentInfo = Color.adaptive(dark: "7AA2D4", light: "5A7DAF")

    // MARK: - Terminal Colors (终端色 - 柔和、不刺眼)

    /// 终端背景 - 与主背景深色一致
    static let terminalBg = Color(hex: "121212")

    /// 终端默认文字 - 柔和灰白
    static let terminalText = Color(hex: "D0D0D0")

    /// 终端注释/行号
    static let terminalComment = Color(hex: "777777")

    /// 终端关键字 - 柔和红
    static let terminalKeyword = Color(hex: "D4A574")

    /// 终端字符串 - 柔和蓝
    static let terminalString = Color(hex: "9DC3E6")

    /// 终端数字 - 柔和青
    static let terminalNumber = Color(hex: "8FC4BC")

    /// 终端函数名 - 柔和紫
    static let terminalFunction = Color(hex: "C9A8D4")

    /// 终端变量 - 柔和橙
    static let terminalVariable = Color(hex: "D4B896")

    /// 终端类型 - 柔和绿
    static let terminalType = Color(hex: "A8C9A8")

    // MARK: - Semantic Colors (语义色背景 - 极低透明度)

    /// 成功背景（10%透明度 - 更克制）
    static let successBg = Color.adaptive(dark: "7CAE7A", light: "5D8A5B").opacity(0.10)

    /// 警告背景（10%透明度）
    static let warningBg = Color.adaptive(dark: "D4A06A", light: "B8895A").opacity(0.10)

    /// 错误背景（10%透明度）
    static let dangerBg = Color.adaptive(dark: "C27070", light: "A85A5A").opacity(0.10)

    /// 信息背景（10%透明度）
    static let infoBg = Color.adaptive(dark: "7AA2D4", light: "5A7DAF").opacity(0.10)

    // MARK: - Status Colors

    /// 获取状态对应的颜色
    static func statusColor(for status: SessionStatus) -> Color {
        switch status {
        case .running:
            return accentSuccess
        case .waiting:
            return accentWarning
        case .idle:
            return textTertiary
        case .error:
            return accentDanger
        case .disconnected:
            return textDisabled
        }
    }

    /// 获取状态对应的背景色
    static func statusBgColor(for status: SessionStatus) -> Color {
        switch status {
        case .running:
            return accentSuccess.opacity(0.2)
        case .waiting:
            return accentWarning.opacity(0.2)
        case .idle:
            return textTertiary.opacity(0.2)
        case .error:
            return accentDanger.opacity(0.2)
        case .disconnected:
            return textDisabled.opacity(0.2)
        }
    }
}

// MARK: - Legacy Compatibility (过渡期兼容)

extension Color {
    // 旧 API 映射到新系统，方便渐进式迁移
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
    static let ccTerminalGreen = CCColor.terminalType
    static let ccTerminalYellow = CCColor.terminalVariable
    static let ccTerminalRed = CCColor.terminalKeyword
    static let ccTerminalBlue = CCColor.terminalNumber
}

// MARK: - Hex Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
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
