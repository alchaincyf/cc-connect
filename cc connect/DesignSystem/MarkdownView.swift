//
//  MarkdownView.swift
//  cc connect
//
//  Markdown 渲染组件 - 支持常见 Markdown 格式
//

import SwiftUI

// MARK: - Markdown Text View

/// 简单的 Markdown 文本渲染
/// 支持：粗体、斜体、行内代码、链接
struct CCMarkdownText: View {
    let content: String
    var font: Font = .ccBody
    var color: Color = CCColor.textPrimary

    var body: some View {
        if let attributed = try? AttributedString(markdown: content, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            Text(attributed)
                .font(font)
                .foregroundColor(color)
                .tint(CCColor.accentPrimary)
        } else {
            Text(content)
                .font(font)
                .foregroundColor(color)
        }
    }
}

// MARK: - Full Markdown View

/// 完整的 Markdown 渲染视图
/// 支持：标题、段落、代码块、列表、引用等
struct CCMarkdownView: View {
    let content: String
    var textColor: Color = CCColor.textPrimary

    private var blocks: [MarkdownBlock] {
        parseMarkdown(content)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: CCSpacing.sm) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                renderBlock(block)
            }
        }
    }

    @ViewBuilder
    private func renderBlock(_ block: MarkdownBlock) -> some View {
        switch block {
        case .heading(let level, let text):
            renderHeading(level: level, text: text)
        case .paragraph(let text):
            CCMarkdownText(content: text, color: textColor)
                .textSelection(.enabled)
                .lineSpacing(4)
        case .codeBlock(let language, let code):
            renderCodeBlock(language: language, code: code)
        case .bulletList(let items):
            renderBulletList(items)
        case .numberedList(let items):
            renderNumberedList(items)
        case .blockquote(let text):
            renderBlockquote(text)
        case .horizontalRule:
            Divider()
                .padding(.vertical, CCSpacing.sm)
        }
    }

    @ViewBuilder
    private func renderHeading(level: Int, text: String) -> some View {
        let font: Font = switch level {
        case 1: .ccTitle1
        case 2: .ccTitle2
        case 3: .ccTitle3
        default: .ccHeadline
        }

        Text(text)
            .font(font)
            .fontWeight(.semibold)
            .foregroundColor(textColor)
            .padding(.top, level == 1 ? CCSpacing.md : CCSpacing.sm)
    }

    @ViewBuilder
    private func renderCodeBlock(language: String?, code: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let lang = language, !lang.isEmpty {
                Text(lang)
                    .font(.ccCodeSmall)
                    .foregroundColor(CCColor.textTertiary)
                    .padding(.horizontal, CCSpacing.sm)
                    .padding(.vertical, CCSpacing.xs)
                    .background(CCColor.bgTertiary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.ccCode)
                    .foregroundColor(CCColor.terminalText)
                    .textSelection(.enabled)
                    .padding(CCSpacing.sm)
            }
            .background(CCColor.terminalBg)
        }
        .clipShape(RoundedRectangle(cornerRadius: CCRadius.sm))
        .overlay(
            RoundedRectangle(cornerRadius: CCRadius.sm)
                .stroke(CCColor.borderMuted, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func renderBulletList(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: CCSpacing.xs) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: CCSpacing.sm) {
                    Text("•")
                        .font(.ccBody)
                        .foregroundColor(CCColor.textTertiary)
                    CCMarkdownText(content: item, color: textColor)
                        .textSelection(.enabled)
                }
            }
        }
    }

    @ViewBuilder
    private func renderNumberedList(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: CCSpacing.xs) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: CCSpacing.sm) {
                    Text("\(index + 1).")
                        .font(.ccBody)
                        .foregroundColor(CCColor.textTertiary)
                        .frame(minWidth: 20, alignment: .trailing)
                    CCMarkdownText(content: item, color: textColor)
                        .textSelection(.enabled)
                }
            }
        }
    }

    @ViewBuilder
    private func renderBlockquote(_ text: String) -> some View {
        HStack(spacing: CCSpacing.sm) {
            Rectangle()
                .fill(CCColor.borderDefault)
                .frame(width: 3)

            CCMarkdownText(content: text, color: CCColor.textSecondary)
                .textSelection(.enabled)
                .italic()
        }
        .padding(.vertical, CCSpacing.xs)
    }
}

// MARK: - Markdown Parser

private enum MarkdownBlock {
    case heading(level: Int, text: String)
    case paragraph(text: String)
    case codeBlock(language: String?, code: String)
    case bulletList(items: [String])
    case numberedList(items: [String])
    case blockquote(text: String)
    case horizontalRule
}

private func parseMarkdown(_ content: String) -> [MarkdownBlock] {
    var blocks: [MarkdownBlock] = []
    let lines = content.components(separatedBy: "\n")
    var i = 0

    while i < lines.count {
        let line = lines[i]
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        // 空行跳过
        if trimmed.isEmpty {
            i += 1
            continue
        }

        // 代码块 ```
        if trimmed.hasPrefix("```") {
            let language = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
            var codeLines: [String] = []
            i += 1
            while i < lines.count && !lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                codeLines.append(lines[i])
                i += 1
            }
            blocks.append(.codeBlock(language: language.isEmpty ? nil : language, code: codeLines.joined(separator: "\n")))
            i += 1
            continue
        }

        // 标题 # ## ###
        if let match = trimmed.firstMatch(of: /^(#{1,6})\s+(.+)$/) {
            let level = match.1.count
            let text = String(match.2)
            blocks.append(.heading(level: level, text: text))
            i += 1
            continue
        }

        // 水平线 --- or ***
        if trimmed.allSatisfy({ $0 == "-" || $0 == "*" || $0 == " " }) && trimmed.filter({ $0 == "-" || $0 == "*" }).count >= 3 {
            blocks.append(.horizontalRule)
            i += 1
            continue
        }

        // 无序列表 - or *
        if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
            var items: [String] = []
            while i < lines.count {
                let l = lines[i].trimmingCharacters(in: .whitespaces)
                if l.hasPrefix("- ") {
                    items.append(String(l.dropFirst(2)))
                } else if l.hasPrefix("* ") {
                    items.append(String(l.dropFirst(2)))
                } else if l.isEmpty {
                    i += 1
                    continue
                } else {
                    break
                }
                i += 1
            }
            if !items.isEmpty {
                blocks.append(.bulletList(items: items))
            }
            continue
        }

        // 有序列表 1. 2. 3.
        if let _ = trimmed.firstMatch(of: /^\d+\.\s+/) {
            var items: [String] = []
            while i < lines.count {
                let l = lines[i].trimmingCharacters(in: .whitespaces)
                if let match = l.firstMatch(of: /^\d+\.\s+(.+)$/) {
                    items.append(String(match.1))
                } else if l.isEmpty {
                    i += 1
                    continue
                } else {
                    break
                }
                i += 1
            }
            if !items.isEmpty {
                blocks.append(.numberedList(items: items))
            }
            continue
        }

        // 引用 >
        if trimmed.hasPrefix("> ") {
            var quoteLines: [String] = []
            while i < lines.count {
                let l = lines[i].trimmingCharacters(in: .whitespaces)
                if l.hasPrefix("> ") {
                    quoteLines.append(String(l.dropFirst(2)))
                } else if l.hasPrefix(">") {
                    quoteLines.append(String(l.dropFirst(1)))
                } else if l.isEmpty {
                    break
                } else {
                    break
                }
                i += 1
            }
            blocks.append(.blockquote(text: quoteLines.joined(separator: "\n")))
            continue
        }

        // 普通段落 - 收集连续的非空行
        var paragraphLines: [String] = []
        while i < lines.count {
            let l = lines[i]
            let t = l.trimmingCharacters(in: .whitespaces)
            if t.isEmpty || t.hasPrefix("#") || t.hasPrefix("```") || t.hasPrefix("- ") || t.hasPrefix("* ") || t.hasPrefix("> ") || t.firstMatch(of: /^\d+\.\s+/) != nil {
                break
            }
            paragraphLines.append(l)
            i += 1
        }
        if !paragraphLines.isEmpty {
            blocks.append(.paragraph(text: paragraphLines.joined(separator: "\n")))
        }
    }

    return blocks
}

// MARK: - Preview

#Preview {
    ScrollView {
        CCMarkdownView(content: """
        # 标题一

        这是一个**粗体**和*斜体*以及`代码`的示例。

        ## 标题二

        - 列表项 1
        - 列表项 2
        - 列表项 3

        1. 有序列表 1
        2. 有序列表 2

        ```swift
        func hello() {
            print("Hello, World!")
        }
        ```

        > 这是一段引用文本

        ---

        普通段落文本。
        """)
        .padding()
    }
    .background(CCColor.bgPrimary)
}
