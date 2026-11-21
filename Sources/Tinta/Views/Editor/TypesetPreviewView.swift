import AppKit
import SwiftUI

public struct SingleChapterTypesetView: View {
    @EnvironmentObject private var store: BookStore
    public let chapter: ChapterItem
    public let chapterNumber: Int

    public init(chapter: ChapterItem, chapterNumber: Int) {
        self.chapter = chapter
        self.chapterNumber = chapterNumber
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                // Editorial Chapter Header
                VStack(spacing: 8) {
                    Text("CAPÍTULO \(chapterNumber)")
                        .font(.system(size: 11, weight: .semibold, design: .serif))
                        .tracking(3)
                        .foregroundStyle(store.theme.accentColor)

                    Text(chapter.title)
                        .font(Font(store.fontStyle.nsFont(size: store.fontSize * 1.65, weight: .bold)))
                        .foregroundStyle(store.theme.textColor)
                        .multilineTextAlignment(.center)

                    if !chapter.subtitle.isEmpty {
                        Text(chapter.subtitle)
                            .font(Font(store.fontStyle.nsFont(size: store.fontSize * 0.95, italic: true)))
                            .foregroundStyle(store.theme.textColor.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }

                    Text("❦")
                        .font(.system(size: 18))
                        .foregroundStyle(store.theme.accentColor.opacity(0.75))
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 16)
                .overlay(alignment: .bottom) {
                    Divider().opacity(0.35)
                }

                // Rendered Markdown Blocks
                LiteraryMarkdownBlocksView(
                    markdown: BookExporter.stripLeadingDuplicateHeading(from: chapter.content, title: chapter.title),
                    theme: store.theme,
                    fontStyle: store.fontStyle,
                    fontSize: store.fontSize,
                    lineSpacing: store.lineSpacing
                )
            }
            .padding(.horizontal, 42)
            .padding(.vertical, 44)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .background(store.theme.backgroundColor)
    }
}

public struct FullBookReaderView: View {
    @EnvironmentObject private var store: BookStore
    @ViewState private var selectedChapterScrollTarget: UUID? = nil

    public init() {}

    public var body: some View {
        let book = store.currentBook
        let chapters = book.activeChapters.filter { $0.includeInCompile }

        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 48) {
                    // Book Title Page Card
                    VStack(spacing: 16) {
                        Text(book.genre.uppercased())
                            .font(.system(size: 11, weight: .semibold, design: .serif))
                            .tracking(3.5)
                            .foregroundStyle(store.theme.accentColor)

                        Text(book.title)
                            .font(Font(store.fontStyle.nsFont(size: 36, weight: .bold)))
                            .foregroundStyle(store.theme.textColor)
                            .multilineTextAlignment(.center)

                        if !book.subtitle.isEmpty {
                            Text(book.subtitle)
                                .font(Font(store.fontStyle.nsFont(size: 19, italic: true)))
                                .foregroundStyle(store.theme.textColor.opacity(0.75))
                                .multilineTextAlignment(.center)
                        }

                        Text("❦")
                            .font(.system(size: 24))
                            .foregroundStyle(store.theme.accentColor)
                            .padding(.vertical, 10)

                        Text(book.author.uppercased())
                            .font(.system(size: 13, weight: .medium, design: .serif))
                            .tracking(2.5)
                            .foregroundStyle(store.theme.textColor.opacity(0.85))

                        HStack(spacing: 18) {
                            Label("\(book.totalWordCount) palavras", systemImage: "text.word.spacing")
                            Label("~\(book.estimatedPagesCount) págs.", systemImage: "book.pages")
                            Label("\(book.estimatedReadingMinutes) min leitura", systemImage: "clock")
                        }
                        .font(.caption)
                        .foregroundStyle(store.theme.textColor.opacity(0.55))
                        .padding(.top, 12)
                    }
                    .padding(.vertical, 56)
                    .padding(.horizontal, 40)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(store.theme.textColor.opacity(0.03))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(store.theme.accentColor.opacity(0.18), lineWidth: 1)
                            )
                    )

                    // Epigraph
                    if !book.epigraph.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        VStack(alignment: .trailing, spacing: 10) {
                            Text("“\(book.epigraph)”")
                                .font(Font(store.fontStyle.nsFont(size: store.fontSize * 1.05, italic: true)))
                                .foregroundStyle(store.theme.textColor.opacity(0.85))
                                .multilineTextAlignment(.trailing)

                            if !book.epigraphAuthor.isEmpty {
                                Text("— \(book.epigraphAuthor)")
                                    .font(Font(store.fontStyle.nsFont(size: store.fontSize * 0.88)))
                                    .foregroundStyle(store.theme.accentColor)
                            }
                        }
                        .frame(maxWidth: 460, alignment: .trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.horizontal, 24)
                    }

                    // Interactive Table of Contents
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("SUMÁRIO")
                                .font(.system(size: 12, weight: .bold, design: .serif))
                                .tracking(2.5)
                                .foregroundStyle(store.theme.accentColor)
                            Spacer()
                            Text("\(chapters.count) capítulos compiláveis")
                                .font(.caption)
                                .foregroundStyle(store.theme.textColor.opacity(0.55))
                        }

                        Divider().opacity(0.3)

                        ForEach(Array(chapters.enumerated()), id: \.element.id) { index, chap in
                            Button {
                                withAnimation(.easeInOut(duration: 0.35)) {
                                    proxy.scrollTo(chap.id, anchor: .top)
                                }
                            } label: {
                                HStack(alignment: .firstTextBaseline, spacing: 12) {
                                    Text(String(format: "%02d", index + 1))
                                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(store.theme.accentColor)

                                    Text(chap.title)
                                        .font(Font(store.fontStyle.nsFont(size: 15, weight: .bold)))
                                        .foregroundStyle(store.theme.textColor)

                                    if !chap.subtitle.isEmpty {
                                        Text("— \(chap.subtitle)")
                                            .font(Font(store.fontStyle.nsFont(size: 14, italic: true)))
                                            .foregroundStyle(store.theme.textColor.opacity(0.65))
                                            .lineLimit(1)
                                    }

                                    Spacer()

                                    Text("\(chap.wordCount) pal.")
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(store.theme.textColor.opacity(0.5))
                                }
                                .padding(.vertical, 4)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(28)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(store.theme.textColor.opacity(0.035))
                    )

                    // Chapters in Order
                    ForEach(Array(chapters.enumerated()), id: \.element.id) { index, chapter in
                        VStack(alignment: .leading, spacing: 26) {
                            // Part Divider if first chapter of a part
                            if let partId = chapter.partId,
                               (index == 0 || chapters[index - 1].partId != partId),
                               let part = book.parts.first(where: { $0.id == partId }) {
                                VStack(spacing: 8) {
                                    Divider().background(store.theme.accentColor)
                                    Text(part.title.uppercased())
                                        .font(.system(size: 14, weight: .bold, design: .serif))
                                        .tracking(2.5)
                                        .foregroundStyle(store.theme.accentColor)
                                        .padding(.top, 14)
                                    if !part.subtitle.isEmpty {
                                        Text(part.subtitle)
                                            .font(Font(store.fontStyle.nsFont(size: 15, italic: true)))
                                            .foregroundStyle(store.theme.textColor.opacity(0.75))
                                    }
                                    Divider().padding(.top, 14)
                                }
                                .padding(.vertical, 20)
                            }

                            // Chapter Header
                            VStack(spacing: 8) {
                                Text("CAPÍTULO \(index + 1)")
                                    .font(.system(size: 11, weight: .semibold, design: .serif))
                                    .tracking(3)
                                    .foregroundStyle(store.theme.accentColor)

                                Text(chapter.title)
                                    .font(Font(store.fontStyle.nsFont(size: store.fontSize * 1.7, weight: .bold)))
                                    .foregroundStyle(store.theme.textColor)
                                    .multilineTextAlignment(.center)

                                if !chapter.subtitle.isEmpty {
                                    Text(chapter.subtitle)
                                        .font(Font(store.fontStyle.nsFont(size: store.fontSize, italic: true)))
                                        .foregroundStyle(store.theme.textColor.opacity(0.7))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 12)

                            LiteraryMarkdownBlocksView(
                                markdown: BookExporter.stripLeadingDuplicateHeading(from: chapter.content, title: chapter.title),
                                theme: store.theme,
                                fontStyle: store.fontStyle,
                                fontSize: store.fontSize,
                                lineSpacing: store.lineSpacing
                            )

                            HStack {
                                Spacer()
                                Button {
                                    store.selection = .chapter(chapter.id)
                                    store.viewMode = .editor
                                } label: {
                                    Label("Editar Capítulo \(index + 1)", systemImage: "pencil")
                                        .font(.caption)
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding(.top, 8)

                            Divider().padding(.top, 24).opacity(0.35)
                        }
                        .id(chapter.id)
                    }
                }
                .padding(.horizontal, 48)
                .padding(.vertical, 48)
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
            }
            .background(store.theme.backgroundColor)
        }
    }
}

// MARK: - Literary Markdown Block Renderer

public struct LiteraryMarkdownBlocksView: View {
    public let markdown: String
    public let theme: EditorTheme
    public let fontStyle: EditorFontStyle
    public let fontSize: CGFloat
    public let lineSpacing: CGFloat

    fileprivate enum Block {
        case heading(level: Int, text: String)
        case paragraph(text: String, isFirstParagraph: Bool, isDialogue: Bool)
        case bulletItem(text: String)
        case numberedItem(number: String, text: String)
        case table(headers: [String], rows: [[String]])
        case blockquote(text: String)
        case sceneBreak
    }

    private static let numberedListRegex = try! NSRegularExpression(pattern: "^(\\d+\\.)\\s+(.*)$")

    private var parsedBlocks: [Block] {
        let lines = markdown.components(separatedBy: .newlines)
        var result: [Block] = []
        var isFirstBody = true
        var idx = 0

        while idx < lines.count {
            let trimmed = lines[idx].trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                idx += 1
                continue
            }
            if trimmed.hasPrefix("%%") && trimmed.hasSuffix("%%") {
                idx += 1
                continue
            }

            // Scene break / horizontal rule
            if trimmed == "* * *" || trimmed == "***" || trimmed == "---" {
                result.append(.sceneBreak)
                isFirstBody = false
                idx += 1
                continue
            }

            // Headings
            if trimmed.hasPrefix("### ") {
                result.append(.heading(level: 3, text: String(trimmed.dropFirst(4))))
                idx += 1
                continue
            } else if trimmed.hasPrefix("## ") {
                result.append(.heading(level: 2, text: String(trimmed.dropFirst(3))))
                idx += 1
                continue
            } else if trimmed.hasPrefix("# ") {
                result.append(.heading(level: 1, text: String(trimmed.dropFirst(2))))
                idx += 1
                continue
            }

            // Markdown Tables (| ... |)
            if trimmed.hasPrefix("|") && trimmed.hasSuffix("|") {
                var tableLines: [String] = []
                while idx < lines.count {
                    let tLine = lines[idx].trimmingCharacters(in: .whitespaces)
                    if tLine.hasPrefix("|") && tLine.hasSuffix("|") {
                        tableLines.append(tLine)
                        idx += 1
                    } else {
                        break
                    }
                }
                if let parsedTable = Self.parseMarkdownTable(tableLines) {
                    result.append(parsedTable)
                    isFirstBody = false
                }
                continue
            }

            // Bullet list item (* or -)
            if trimmed.hasPrefix("* ") || trimmed.hasPrefix("- ") || trimmed.hasPrefix("• ") {
                let itemText = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                result.append(.bulletItem(text: itemText))
                isFirstBody = false
                idx += 1
                continue
            }

            // Numbered list item (1. , 2. , etc.)
            let nsTrimmed = trimmed as NSString
            if let match = Self.numberedListRegex.firstMatch(in: trimmed, range: NSRange(location: 0, length: nsTrimmed.length)),
               match.numberOfRanges == 3 {
                let numStr = nsTrimmed.substring(with: match.range(at: 1))
                let itemText = nsTrimmed.substring(with: match.range(at: 2))
                result.append(.numberedItem(number: numStr, text: itemText))
                isFirstBody = false
                idx += 1
                continue
            }

            // Blockquote
            if trimmed.hasPrefix("> ") || trimmed == ">" {
                let q = trimmed.hasPrefix("> ") ? String(trimmed.dropFirst(2)) : ""
                result.append(.blockquote(text: q))
                idx += 1
                continue
            }

            // Standard or dialogue paragraph
            let isDialogue = trimmed.hasPrefix("—") || trimmed.hasPrefix("–") || trimmed.hasPrefix("--")
            let normalized = trimmed.hasPrefix("-- ")
                ? "— " + String(trimmed.dropFirst(3))
                : trimmed
            result.append(.paragraph(text: normalized, isFirstParagraph: isFirstBody && !isDialogue, isDialogue: isDialogue))
            isFirstBody = false
            idx += 1
        }
        return result
    }

    private static func parseMarkdownTable(_ lines: [String]) -> Block? {
        guard !lines.isEmpty else { return nil }
        func splitCells(_ line: String) -> [String] {
            var inner = line
            if inner.hasPrefix("|") { inner.removeFirst() }
            if inner.hasSuffix("|") { inner.removeLast() }
            return inner.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
        }

        let headerCells = splitCells(lines[0])
        var bodyRows: [[String]] = []
        for (i, line) in lines.enumerated() where i > 0 {
            let cells = splitCells(line)
            // Skip separator row like | :--- | :--- |
            let isSeparator = cells.allSatisfy { cell in
                !cell.isEmpty && cell.allSatisfy { $0 == "-" || $0 == ":" || $0 == " " }
            }
            if !isSeparator {
                bodyRows.append(cells)
            }
        }
        return .table(headers: headerCells, rows: bodyRows)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: fontSize * 0.62) {
            ForEach(Array(parsedBlocks.enumerated()), id: \.offset) { _, block in
                switch block {
                case .heading(let level, let text):
                    let scale: CGFloat = level == 1 ? 1.45 : (level == 2 ? 1.25 : 1.1)
                    Text(styledInlineAttributedString(for: text, baseSize: fontSize * scale, defaultBold: true))
                        .foregroundStyle(theme.accentColor)
                        .padding(.top, 10)

                case .sceneBreak:
                    HStack(spacing: 12) {
                        Rectangle()
                            .fill(theme.accentColor.opacity(0.25))
                            .frame(height: 1)
                        Text("⁂")
                            .font(.system(size: fontSize * 1.1))
                            .foregroundStyle(theme.accentColor)
                        Rectangle()
                            .fill(theme.accentColor.opacity(0.25))
                            .frame(height: 1)
                    }
                    .padding(.vertical, 10)

                case .blockquote(let text):
                    HStack(spacing: 14) {
                        Rectangle()
                            .fill(theme.accentColor)
                            .frame(width: 3)
                        Text(styledInlineAttributedString(for: text, baseSize: fontSize * 0.96, defaultItalic: true))
                            .foregroundStyle(theme.textColor.opacity(0.88))
                            .lineSpacing(lineSpacing)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(theme.textColor.opacity(0.035))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                case .bulletItem(let text):
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("•")
                            .font(Font(fontStyle.nsFont(size: fontSize, weight: .bold)))
                            .foregroundStyle(theme.accentColor)
                        Text(styledInlineAttributedString(for: text, baseSize: fontSize))
                            .foregroundStyle(theme.textColor)
                            .lineSpacing(lineSpacing * 0.85)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.leading, 12)

                case .numberedItem(let number, let text):
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(number)
                            .font(Font(fontStyle.nsFont(size: fontSize * 0.95, weight: .bold)))
                            .foregroundStyle(theme.accentColor)
                            .frame(minWidth: 26, alignment: .trailing)
                        Text(styledInlineAttributedString(for: text, baseSize: fontSize))
                            .foregroundStyle(theme.textColor)
                            .lineSpacing(lineSpacing * 0.85)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.leading, 6)

                case .table(let headers, let rows):
                    markdownTableView(headers: headers, rows: rows)

                case .paragraph(let text, let isFirst, _):
                    if isFirst, let firstChar = text.first, firstChar.isLetter {
                        let remainder = String(text.dropFirst())
                        HStack(alignment: .top, spacing: 8) {
                            Text(String(firstChar))
                                .font(Font(fontStyle.nsFont(size: fontSize * 2.8, weight: .bold)))
                                .foregroundStyle(theme.accentColor)
                                .padding(.top, -6)
                            Text(styledInlineAttributedString(for: remainder, baseSize: fontSize))
                                .foregroundStyle(theme.textColor)
                                .lineSpacing(lineSpacing)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    } else {
                        Text(styledInlineAttributedString(for: text, baseSize: fontSize, leadingIndent: "    "))
                            .foregroundStyle(theme.textColor)
                            .lineSpacing(lineSpacing)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func markdownTableView(headers: [String], rows: [[String]]) -> some View {
        VStack(spacing: 0) {
            // Header Row
            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(headers.enumerated()), id: \.offset) { _, headerText in
                    Text(styledInlineAttributedString(for: headerText, baseSize: fontSize * 0.88, defaultBold: true))
                        .foregroundStyle(theme.accentColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                }
            }
            .background(theme.accentColor.opacity(0.12))

            Divider()

            // Body Rows
            ForEach(Array(rows.enumerated()), id: \.offset) { rowIdx, row in
                HStack(alignment: .top, spacing: 0) {
                    ForEach(0..<headers.count, id: \.self) { colIdx in
                        let cellText = colIdx < row.count ? row[colIdx] : ""
                        Text(styledInlineAttributedString(for: cellText, baseSize: fontSize * 0.86))
                            .foregroundStyle(theme.textColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                    }
                }
                .background(rowIdx.isMultiple(of: 2) ? Color.clear : theme.textColor.opacity(0.03))
                if rowIdx < rows.count - 1 {
                    Divider().opacity(0.35)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(theme.textColor.opacity(0.16), lineWidth: 1)
        )
        .padding(.vertical, 6)
    }

    private func cleanWikiLinks(in input: String) -> String {
        input.replacingOccurrences(of: "[[", with: "").replacingOccurrences(of: "]]", with: "")
    }

    /// Parses inline Markdown (**bold**, *italic*, ***bold-italic***, `code`) and explicitly binds the matching NSFont face (e.g. Georgia-Bold) to every run.
    private func styledInlineAttributedString(
        for raw: String,
        baseSize: CGFloat,
        defaultBold: Bool = false,
        defaultItalic: Bool = false,
        leadingIndent: String = ""
    ) -> AttributedString {
        let cleaned = cleanWikiLinks(in: raw)
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)

        var parsed = (try? AttributedString(markdown: cleaned, options: options)) ?? AttributedString(cleaned)

        for run in parsed.runs {
            let intent = run.inlinePresentationIntent ?? []
            let isBold = defaultBold || intent.contains(.stronglyEmphasized)
            let isItalic = defaultItalic || intent.contains(.emphasized)
            let isCode = intent.contains(.code)

            if isCode {
                let monoFont = NSFont.monospacedSystemFont(ofSize: baseSize * 0.9, weight: isBold ? .bold : .regular)
                parsed[run.range].font = Font(monoFont)
            } else {
                let runNSFont = fontStyle.nsFont(
                    size: baseSize,
                    weight: isBold ? .bold : .regular,
                    italic: isItalic
                )
                parsed[run.range].font = Font(runNSFont)
            }
        }

        if !leadingIndent.isEmpty {
            var prefix = AttributedString(leadingIndent)
            prefix.font = Font(fontStyle.nsFont(size: baseSize))
            return prefix + parsed
        }
        return parsed
    }
}
