//
//  Spacing.swift
//  cc connect
//
//  Design System v4.0 - Glassmorphism 玻璃拟态间距系统
//  更大的留白，更多呼吸感
//

import SwiftUI

// MARK: - Spacing Tokens

/// CC Connect 设计系统间距
enum CCSpacing {

    // MARK: - Base Scale (4pt Grid)

    /// 0pt - 无间距
    static let space0: CGFloat = 0

    /// 4pt - 最小间距，图标与文字
    static let space1: CGFloat = 4

    /// 8pt - 紧凑间距，行内元素
    static let space2: CGFloat = 8

    /// 12pt - 默认间距，列表项内
    static let space3: CGFloat = 12

    /// 16pt - 标准间距，卡片内边距
    static let space4: CGFloat = 16

    /// 20pt - 较大间距
    static let space5: CGFloat = 20

    /// 24pt - 区块间距
    static let space6: CGFloat = 24

    /// 32pt - 大区块间距
    static let space8: CGFloat = 32

    /// 40pt - 页面边距
    static let space10: CGFloat = 40

    /// 48pt - 特大间距
    static let space12: CGFloat = 48

    // MARK: - Semantic Aliases (MUJI 风格 - 更大留白)

    /// 4pt - 超小间距
    static let xxs: CGFloat = 4

    /// 8pt - 极小间距
    static let xs: CGFloat = space2

    /// 12pt - 小间距
    static let sm: CGFloat = space3

    /// 16pt - 中等间距
    static let md: CGFloat = space4

    /// 24pt - 大间距（增加留白）
    static let lg: CGFloat = space6

    /// 32pt - 超大间距
    static let xl: CGFloat = space8

    /// 40pt - 巨大间距
    static let xxl: CGFloat = space10

    /// 56pt - 极大间距（大幅增加）
    static let xxxl: CGFloat = 56

    /// 72pt - 最大间距（大幅增加）
    static let xxxxl: CGFloat = 72

    // MARK: - Component Specific (组件专用)

    /// 按钮内边距 - 水平
    static let buttonPaddingH: CGFloat = space3  // 12pt

    /// 按钮内边距 - 垂直
    static let buttonPaddingV: CGFloat = space2  // 8pt

    /// 卡片内边距
    static let cardPadding: CGFloat = space4  // 16pt

    /// 卡片间距
    static let cardSpacing: CGFloat = space3  // 12pt

    /// 列表项间距
    static let listItemSpacing: CGFloat = space2  // 8pt

    /// 区块间距
    static let sectionSpacing: CGFloat = space6  // 24pt

    /// 页面边距
    static let pagePadding: CGFloat = space4  // 16pt

    /// 输入框内边距
    static let inputPadding: CGFloat = 14  // 特殊值
}

// MARK: - Corner Radius Tokens

/// CC Connect 设计系统圆角
enum CCRadius {

    /// 0pt - 无圆角
    static let none: CGFloat = 0

    /// 4pt - 小圆角，标签
    static let xs: CGFloat = 4

    /// 8pt - 中圆角，按钮、输入框
    static let sm: CGFloat = 8

    /// 12pt - 大圆角，卡片
    static let md: CGFloat = 12

    /// 16pt - 特大圆角，弹窗
    static let lg: CGFloat = 16

    /// 20pt - 超大圆角
    static let xl: CGFloat = 20

    /// 9999pt - 全圆，徽章、头像
    static let full: CGFloat = 9999
}

// MARK: - Size Tokens

/// CC Connect 设计系统尺寸
enum CCSize {

    // MARK: - Touch Targets (触控区域)

    /// 最小触控区域 - 44pt
    static let minTouchTarget: CGFloat = 44

    /// 按钮高度 - 标准
    static let buttonHeight: CGFloat = 50

    /// 按钮高度 - 紧凑
    static let buttonHeightCompact: CGFloat = 44

    /// 按钮高度 - 大
    static let buttonHeightLarge: CGFloat = 56

    /// 快捷操作按钮最小宽度
    static let quickActionMinWidth: CGFloat = 80

    // MARK: - Status Indicators

    /// 状态圆点 - 小
    static let statusDotSmall: CGFloat = 8

    /// 状态圆点 - 标准
    static let statusDot: CGFloat = 10

    /// 状态脉冲环
    static let statusPulseRing: CGFloat = 16

    // MARK: - Icons

    /// 图标 - 超小
    static let iconXS: CGFloat = 12

    /// 图标 - 小
    static let iconSM: CGFloat = 16

    /// 图标 - 中
    static let iconMD: CGFloat = 20

    /// 图标 - 大
    static let iconLG: CGFloat = 24

    /// 图标 - 超大
    static let iconXL: CGFloat = 32

    /// 图标 - 巨大
    static let iconXXL: CGFloat = 48

    // MARK: - Input

    /// 输入框最小高度
    static let inputMinHeight: CGFloat = 44

    /// 输入栏高度（含内边距）
    static let inputBarHeight: CGFloat = 56

    /// 发送按钮大小
    static let sendButtonSize: CGFloat = 32

    /// 中断按钮大小
    static let interruptButtonSize: CGFloat = 28
}

// MARK: - Layout Helpers

extension View {
    /// 应用卡片内边距
    func ccCardPadding() -> some View {
        self.padding(CCSpacing.cardPadding)
    }

    /// 应用页面边距
    func ccPagePadding() -> some View {
        self.padding(.horizontal, CCSpacing.pagePadding)
    }

    /// 应用标准圆角
    func ccCornerRadius(_ radius: CGFloat = CCRadius.md) -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: radius))
    }
}
