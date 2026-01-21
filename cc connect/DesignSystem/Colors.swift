//
//  Colors.swift
//  cc connect
//
//  Design System v2.0 - 色彩系统
//  基于 GitHub Dark 风格，专为开发者工具设计
//

import SwiftUI
import UIKit

// MARK: - Design Tokens

/// CC Connect 设计系统色彩
enum CCColor {

    // MARK: - Background Colors

    /// 主背景色 - 页面背景
    /// Dark: #0D1117, Light: #FFFFFF
    static let bgPrimary = Color.adaptive(dark: "0D1117", light: "FFFFFF")

    /// 次级背景色 - 卡片背景
    /// Dark: #161B22, Light: #F6F8FA
    static let bgSecondary = Color.adaptive(dark: "161B22", light: "F6F8FA")

    /// 三级背景色 - 输入框、次级容器
    /// Dark: #21262D, Light: #F0F3F6
    static let bgTertiary = Color.adaptive(dark: "21262D", light: "F0F3F6")

    /// 浮层背景色 - 弹窗、Sheet
    /// Dark: #30363D, Light: #FFFFFF
    static let bgElevated = Color.adaptive(dark: "30363D", light: "FFFFFF")

    // MARK: - Border Colors

    /// 默认边框
    /// Dark: #30363D, Light: #D1D9E0
    static let borderDefault = Color.adaptive(dark: "30363D", light: "D1D9E0")

    /// 弱化边框
    /// Dark: #21262D, Light: #E6EBF1
    static let borderMuted = Color.adaptive(dark: "21262D", light: "E6EBF1")

    // MARK: - Text Colors

    /// 主要文字
    /// Dark: #E6EDF3, Light: #1F2328
    static let textPrimary = Color.adaptive(dark: "E6EDF3", light: "1F2328")

    /// 次要文字
    /// Dark: #8B949E, Light: #656D76
    static let textSecondary = Color.adaptive(dark: "8B949E", light: "656D76")

    /// 辅助文字
    /// Dark: #6E7681, Light: #8C959F
    static let textTertiary = Color.adaptive(dark: "6E7681", light: "8C959F")

    /// 禁用文字
    /// Dark: #484F58, Light: #AFB8C1
    static let textDisabled = Color.adaptive(dark: "484F58", light: "AFB8C1")

    /// 链接文字
    /// Dark: #58A6FF, Light: #0969DA
    static let textLink = Color.adaptive(dark: "58A6FF", light: "0969DA")

    // MARK: - Accent Colors (固定色值)

    /// Claude 品牌色 - 琥珀金
    static let accentClaude = Color(hex: "CA8A04")

    /// 主强调色 - 亮蓝
    static let accentPrimary = Color(hex: "58A6FF")

    /// 成功色 - GitHub Green
    static let accentSuccess = Color(hex: "238636")

    /// 警告色 - 温暖橙
    static let accentWarning = Color(hex: "DB6D28")

    /// 危险色 - 红色
    static let accentDanger = Color(hex: "DA3633")

    /// 信息色 - 亮蓝
    static let accentInfo = Color(hex: "58A6FF")

    // MARK: - Terminal Colors (固定色值)

    /// 终端背景
    static let terminalBg = Color(hex: "0D1117")

    /// 终端默认文字
    static let terminalText = Color(hex: "C9D1D9")

    /// 终端注释/行号
    static let terminalComment = Color(hex: "8B949E")

    /// 终端关键字
    static let terminalKeyword = Color(hex: "FF7B72")

    /// 终端字符串
    static let terminalString = Color(hex: "A5D6FF")

    /// 终端数字
    static let terminalNumber = Color(hex: "79C0FF")

    /// 终端函数名
    static let terminalFunction = Color(hex: "D2A8FF")

    /// 终端变量
    static let terminalVariable = Color(hex: "FFA657")

    /// 终端类型
    static let terminalType = Color(hex: "7EE787")

    // MARK: - Semantic Colors

    /// 成功背景（15%透明度）
    static let successBg = Color(hex: "238636").opacity(0.15)

    /// 警告背景（15%透明度）
    static let warningBg = Color(hex: "DB6D28").opacity(0.15)

    /// 错误背景（15%透明度）
    static let dangerBg = Color(hex: "DA3633").opacity(0.15)

    /// 信息背景（15%透明度）
    static let infoBg = Color(hex: "58A6FF").opacity(0.15)

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
