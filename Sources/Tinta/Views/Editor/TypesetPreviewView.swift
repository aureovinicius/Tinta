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
                        .font(.custom(store.fontStyle.fontName, size: store.fontSize * 1.65).bold())
                        .foregroundStyle(store.theme.textColor)
                        .multilineTextAlignment(.center)

                    if !chapter.subtitle.isEmpty {
                        Text(chapter.subtitle)
                            .font(.custom(store.fontStyle.fontName, size: store.fontSize * 0.95).italic())
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
            .frame(maxWidth: 680)
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
                            .font(.custom(store.fontStyle.fontName, size: 36).bold())
                            .foregroundStyle(store.theme.textColor)
                            .multilineTextAlignment(.center)

                        if !book.subtitle.isEmpty {
                            Text(book.subtitle)
                                .font(.custom(store.fontStyle.fontName, size: 19).italic())
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
                                .font(.custom(store.fontStyle.fontName, size: store.fontSize * 1.05).italic())
                                .foregroundStyle(store.theme.textColor.opacity(0.85))
                                .multilineTextAlignment(.trailing)

                            if !book.epigraphAuthor.isEmpty {
                                Text("— \(book.epigraphAuthor)")
                                    .font(.custom(store.fontStyle.fontName, size: store.fontSize * 0.88))
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
                                        .font(.custom(store.fontStyle.fontName, size: 15).weight(.semibold))
                                        .foregroundStyle(store.theme.textColor)

                                    if !chap.subtitle.isEmpty {
                                        Text("— \(chap.subtitle)")
                                            .font(.custom(store.fontStyle.fontName, size: 14).italic())
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
                                            .font(.custom(store.fontStyle.fontName, size: 15).italic())
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
                                    .font(.custom(store.fontStyle.fontName, size: store.fontSize * 1.7).bold())
                                    .foregroundStyle(store.theme.textColor)
                                    .multilineTextAlignment(.center)

                                if !chapter.subtitle.isEmpty {
                                    Text(chapter.subtitle)
                                        .font(.custom(store.fontStyle.fontName, size: store.fontSize).italic())
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
                .frame(maxWidth: 740)
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

    fileprivate enum Block: Identifiable {
        case heading(level: Int, text: String)
        case paragraph(text: String, isFirstParagraph: Bool, isDialogue: Bool)
        case blockquote(text: String)
        case sceneBreak

        var id: UUID { UUID() }
    }

    private var parsedBlocks: [Block] {
        let lines = markdown.components(separatedBy: .newlines)
        var result: [Block] = []
        var isFirstBody = true

        for raw in lines {
            let trimmed = raw.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            if trimmed.hasPrefix("%%") && trimmed.hasSuffix("%%") { continue }

            if trimmed == "* * *" || trimmed == "***" || trimmed == "---" {
                result.append(.sceneBreak)
                isFirstBody = false
                continue
            }
            if trimmed.hasPrefix("### ") {
                result.append(.heading(level: 3, text: String(trimmed.dropFirst(4))))
                continue
            } else if trimmed.hasPrefix("## ") {
                result.append(.heading(level: 2, text: String(trimmed.dropFirst(3))))
                continue
            } else if trimmed.hasPrefix("# ") {
                result.append(.heading(level: 1, text: String(trimmed.dropFirst(2))))
                continue
            }
            if trimmed.hasPrefix("> ") || trimmed == ">" {
                let q = trimmed.hasPrefix("> ") ? String(trimmed.dropFirst(2)) : ""
                result.append(.blockquote(text: q))
                continue
            }

            let isDialogue = trimmed.hasPrefix("—") || trimmed.hasPrefix("–") || trimmed.hasPrefix("--")
            let normalized = trimmed.hasPrefix("-- ")
                ? "— " + String(trimmed.dropFirst(3))
                : trimmed
            result.append(.paragraph(text: normalized, isFirstParagraph: isFirstBody && !isDialogue, isDialogue: isDialogue))
            isFirstBody = false
        }
        return result
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: fontSize * 0.65) {
            ForEach(Array(parsedBlocks.enumerated()), id: \.offset) { _, block in
                switch block {
                case .heading(let level, let text):
                    let scale: CGFloat = level == 1 ? 1.45 : (level == 2 ? 1.25 : 1.1)
                    Text(cleanWikiLinks(in: text))
                        .font(.custom(fontStyle.fontName, size: fontSize * scale).bold())
                        .foregroundStyle(theme.accentColor)
                        .padding(.top, 10)

                case .sceneBreak:
                    Text("⁂")
                        .font(.system(size: fontSize * 1.25))
                        .foregroundStyle(theme.accentColor)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 12)

                case .blockquote(let text):
                    HStack(spacing: 14) {
                        Rectangle()
                            .fill(theme.accentColor)
                            .frame(width: 3)
                        Text(styledInlineAttributedString(for: text))
                            .font(.custom(fontStyle.fontName, size: fontSize * 0.96).italic())
                            .foregroundStyle(theme.textColor.opacity(0.86))
                            .lineSpacing(lineSpacing)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(theme.textColor.opacity(0.035))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                case .paragraph(let text, let isFirst, let isDialogue):
                    if isFirst, let firstChar = text.first {
                        let remainder = String(text.dropFirst())
                        HStack(alignment: .top, spacing: 8) {
                            Text(String(firstChar))
                                .font(.custom(fontStyle.fontName, size: fontSize * 2.8).bold())
                                .foregroundStyle(theme.accentColor)
                                .padding(.top, -6)
                            Text(styledInlineAttributedString(for: remainder))
                                .font(.custom(fontStyle.fontName, size: fontSize))
                                .foregroundStyle(theme.textColor)
                                .lineSpacing(lineSpacing)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    } else {
                        Text(styledInlineAttributedString(for: (isDialogue ? "    " : "      ") + text))
                            .font(.custom(fontStyle.fontName, size: fontSize))
                            .foregroundStyle(isDialogue ? Color(nsColor: theme.dialogueNSColor) : theme.textColor)
                            .lineSpacing(lineSpacing)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private func cleanWikiLinks(in input: String) -> String {
        input.replacingOccurrences(of: "[[", with: "").replacingOccurrences(of: "]]", with: "")
    }

    private func styledInlineAttributedString(for raw: String) -> AttributedString {
        let cleaned = cleanWikiLinks(in: raw)
        if let attr = try? AttributedString(markdown: cleaned) {
            return attr
        }
        return AttributedString(cleaned)
    }
}
