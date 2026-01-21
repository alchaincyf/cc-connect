//
//  Typography.swift
//  cc connect
//
//  Design System v2.0 - 字体系统
//  基于 iOS Human Interface Guidelines，支持 Dynamic Type
//

import SwiftUI

// MARK: - Design Tokens

/// CC Connect 设计系统字体
enum CCFont {

    // MARK: - Interface Fonts (界面字体)

    /// 大标题 - 34pt Bold
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .default)

    /// 一级标题 - 28pt Bold
    static let title1 = Font.system(size: 28, weight: .bold, design: .default)

    /// 二级标题 - 22pt Bold
    static let title2 = Font.system(size: 22, weight: .bold, design: .default)

    /// 三级标题 - 20pt Semibold
    static let title3 = Font.system(size: 20, weight: .semibold, design: .default)

    /// 标题行 - 17pt Semibold (列表标题、按钮)
    static let headline = Font.system(size: 17, weight: .semibold, design: .default)

    /// 正文 - 17pt Regular
    static let body = Font.system(size: 17, weight: .regular, design: .default)

    /// 标注 - 16pt Regular
    static let callout = Font.system(size: 16, weight: .regular, design: .default)

    /// 副标题 - 15pt Regular
    static let subheadline = Font.system(size: 15, weight: .regular, design: .default)

    /// 脚注 - 13pt Regular
    static let footnote = Font.system(size: 13, weight: .regular, design: .default)

    /// 小标签 - 12pt Regular
    static let caption1 = Font.system(size: 12, weight: .regular, design: .default)

    /// 最小文字 - 11pt Regular
    static let caption2 = Font.system(size: 11, weight: .regular, design: .default)

    // MARK: - Code Fonts (代码字体)

    /// 大号代码 - 15pt Monospaced
    static let codeLarge = Font.system(size: 15, weight: .regular, design: .monospaced)

    /// 中号代码 - 14pt Monospaced (代码块主要字体)
    static let codeMedium = Font.system(size: 14, weight: .regular, design: .monospaced)

    /// 小号代码 - 13pt Monospaced
    static let codeSmall = Font.system(size: 13, weight: .regular, design: .monospaced)

    /// 超小号代码 - 12pt Monospaced (行号、注释)
    static let codeXSmall = Font.system(size: 12, weight: .regular, design: .monospaced)

    /// 代码粗体 - 14pt Semibold Monospaced (关键字、函数名)
    static let codeBold = Font.system(size: 14, weight: .semibold, design: .monospaced)

    // MARK: - Special Fonts (特殊字体)

    /// 圆角数字 - 17pt Medium Rounded (数字徽章)
    static let numberBadge = Font.system(size: 17, weight: .medium, design: .rounded)

    /// 快捷键提示 - 12pt Medium Monospaced
    static let hotkey = Font.system(size: 12, weight: .medium, design: .monospaced)
}

// MARK: - Font Extension (方便使用)

extension Font {
    // MARK: - Interface Fonts

    /// 大标题 - 34pt Bold
    static let ccLargeTitle = CCFont.largeTitle

    /// 一级标题 - 28pt Bold
    static let ccTitle1 = CCFont.title1

    /// 二级标题 - 22pt Bold
    static let ccTitle2 = CCFont.title2

    /// 三级标题 - 20pt Semibold
    static let ccTitle3 = CCFont.title3

    /// 标题行 - 17pt Semibold
    static let ccHeadline = CCFont.headline

    /// 正文 - 17pt Regular
    static let ccBody = CCFont.body

    /// 标注 - 16pt Regular
    static let ccCallout = CCFont.callout

    /// 副标题 - 15pt Regular
    static let ccSubheadline = CCFont.subheadline

    /// 脚注 - 13pt Regular
    static let ccFootnote = CCFont.footnote

    /// 小标签 - 12pt Regular
    static let ccCaption = CCFont.caption1

    /// 最小文字 - 11pt Regular
    static let ccCaption2 = CCFont.caption2

    // MARK: - Code Fonts

    /// 大号代码 - 15pt Monospaced
    static let ccCodeLarge = CCFont.codeLarge

    /// 中号代码 - 14pt Monospaced
    static let ccCode = CCFont.codeMedium

    /// 小号代码 - 13pt Monospaced
    static let ccCodeSmall = CCFont.codeSmall

    /// 超小号代码 - 12pt Monospaced
    static let ccCodeXSmall = CCFont.codeXSmall

    /// 代码粗体 - 14pt Semibold Monospaced
    static let ccCodeBold = CCFont.codeBold

    // MARK: - Legacy (兼容旧代码)

    static let ccTerminal = CCFont.codeMedium
    static let ccTerminalLarge = CCFont.codeLarge
}

// MARK: - Text Style Modifiers

extension View {
    /// 应用主标题样式
    func ccTitleStyle() -> some View {
        self
            .font(.ccTitle2)
            .foregroundColor(CCColor.textPrimary)
    }

    /// 应用正文样式
    func ccBodyStyle() -> some View {
        self
            .font(.ccBody)
            .foregroundColor(CCColor.textPrimary)
    }

    /// 应用次要文字样式
    func ccSecondaryStyle() -> some View {
        self
            .font(.ccSubheadline)
            .foregroundColor(CCColor.textSecondary)
    }

    /// 应用代码样式
    func ccCodeStyle() -> some View {
        self
            .font(.ccCode)
            .foregroundColor(CCColor.terminalText)
    }

    /// 应用标签样式
    func ccCaptionStyle() -> some View {
        self
            .font(.ccCaption)
            .foregroundColor(CCColor.textTertiary)
    }
}

// MARK: - Line Height

/// 行高配置
enum CCLineHeight {
    static let largeTitle: CGFloat = 41
    static let title1: CGFloat = 34
    static let title2: CGFloat = 28
    static let title3: CGFloat = 25
    static let headline: CGFloat = 22
    static let body: CGFloat = 22
    static let callout: CGFloat = 21
    static let subheadline: CGFloat = 20
    static let footnote: CGFloat = 18
    static let caption1: CGFloat = 16
    static let caption2: CGFloat = 13

    static let codeLarge: CGFloat = 20
    static let codeMedium: CGFloat = 19
    static let codeSmall: CGFloat = 18
    static let codeXSmall: CGFloat = 16
}
