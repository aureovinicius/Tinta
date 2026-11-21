import AppKit
import Foundation

public enum ExportFormat: String, CaseIterable, Identifiable {
    case epubBook = "eBook EPUB para Kindle / Apple Books (.epub)"
    case compiledMarkdown = "Manuscrito Markdown Único (.md)"
    case htmlBook = "Livro Tipográfico HTML (.html)"
    case pdfBook = "Livro Diagramado em PDF (.pdf)"
    case markdownFolder = "Pasta Estruturada de Arquivos Markdown"

    public var id: String { rawValue }

    public var description: String {
        switch self {
        case .epubBook:
            return "Gera um eBook padrão EPUB 3 pronto para leitura no Kindle (Send to Kindle / Amazon KDP), Apple Books e Kobo, com sumário interativo e capítulos."
        case .compiledMarkdown:
            return "Gera um único arquivo .md com metadados YAML, folha de rosto, sumário e todos os capítulos marcados para compilação."
        case .htmlBook:
            return "Gera um livro digital em HTML5 com tipografia editorial, capitulares (drop caps), sumário navegável e estilos prontos para impressão."
        case .pdfBook:
            return "Diagrama o livro diretamente em um arquivo PDF paginado com folha de rosto, epígrafe e capítulos formatados."
        case .markdownFolder:
            return "Exporta uma pasta organizada contendo os capítulos individuais em .md, fichas de personagens, locais, notas e backup JSON."
        }
    }

    public var fileExtension: String {
        switch self {
        case .epubBook: return "epub"
        case .compiledMarkdown: return "md"
        case .htmlBook: return "html"
        case .pdfBook: return "pdf"
        case .markdownFolder: return ""
        }
    }
}

public struct ExportOptions {
    public var includeTitlePage: Bool = true
    public var includeEpigraph: Bool = true
    public var includeTableOfContents: Bool = true
    public var includePartDividers: Bool = true
    public var includeChapterSubtitles: Bool = true
    public var includeStoryBibleAppendix: Bool = false
    public var dropCaps: Bool = true

    public init() {}
}

public enum BookExporter {
    /// Compiles the book into a single unified Markdown manuscript
    public static func compileMarkdown(book: BookProject, options: ExportOptions = ExportOptions()) -> String {
        var out: [String] = []

        // YAML Frontmatter
        out.append("---")
        out.append("title: \"\(escapeYAML(book.title))\"")
        if !book.subtitle.isEmpty {
            out.append("subtitle: \"\(escapeYAML(book.subtitle))\"")
        }
        out.append("author: \"\(escapeYAML(book.author))\"")
        out.append("genre: \"\(escapeYAML(book.genre))\"")
        out.append("words: \(book.totalWordCount)")
        out.append("date: \"\(BookStore.dateString(for: Date()))\"")
        out.append("---")
        out.append("")

        if options.includeTitlePage {
            out.append("# \(book.title)")
            if !book.subtitle.isEmpty {
                out.append("### *\(book.subtitle)*")
            }
            out.append("")
            out.append("**Por \(book.author)**")
            out.append("")
            out.append("* * *")
            out.append("")
        }

        if options.includeEpigraph && !book.epigraph.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            out.append("> *\"\(book.epigraph)\"*")
            if !book.epigraphAuthor.isEmpty {
                out.append("> — \(book.epigraphAuthor)")
            }
            out.append("")
            out.append("* * *")
            out.append("")
        }

        let compilableChapters = book.activeChapters.filter { $0.includeInCompile }

        if options.includeTableOfContents {
            out.append("## Sumário")
            out.append("")
            for (idx, chapter) in compilableChapters.enumerated() {
                let romanOrNum = idx + 1
                if !chapter.subtitle.isEmpty && options.includeChapterSubtitles {
                    out.append("\(romanOrNum). **\(chapter.title)** — *\(chapter.subtitle)*")
                } else {
                    out.append("\(romanOrNum). **\(chapter.title)**")
                }
            }
            out.append("")
            out.append("* * *")
            out.append("")
        }

        var currentPartId: UUID? = nil
        for (idx, chapter) in compilableChapters.enumerated() {
            if options.includePartDividers, let pId = chapter.partId, pId != currentPartId {
                currentPartId = pId
                if let part = book.parts.first(where: { $0.id == pId }) {
                    out.append("# \(part.title)")
                    if !part.subtitle.isEmpty {
                        out.append("*\(part.subtitle)*")
                    }
                    out.append("")
                }
            }

            let chapterNum = idx + 1
            let cleanedBody = stripLeadingDuplicateHeading(from: chapter.content, title: chapter.title)

            out.append("## Capítulo \(chapterNum): \(chapter.title)")
            if options.includeChapterSubtitles && !chapter.subtitle.isEmpty {
                out.append("*\(chapter.subtitle)*")
            }
            out.append("")
            out.append(cleanedBody)
            out.append("")
            out.append("* * *")
            out.append("")
        }

        if options.includeStoryBibleAppendix {
            out.append("# Apêndice — Bíblia da História")
            out.append("")
            if !book.characters.isEmpty {
                out.append("## Personagens")
                out.append("")
                for char in book.characters {
                    out.append("### \(char.name) (\(char.role.rawValue))")
                    if !char.summary.isEmpty {
                        out.append(char.summary)
                    }
                    if !char.motivation.isEmpty {
                        out.append("- **Motivação**: \(char.motivation)")
                    }
                    if !char.internalConflict.isEmpty {
                        out.append("- **Conflito Interno**: \(char.internalConflict)")
                    }
                    out.append("")
                }
            }
            if !book.locations.isEmpty {
                out.append("## Locais & Cenários")
                out.append("")
                for loc in book.locations {
                    out.append("### \(loc.name)")
                    if !loc.region.isEmpty {
                        out.append("*\(loc.region)*")
                    }
                    if !loc.description.isEmpty {
                        out.append(loc.description)
                    }
                    out.append("")
                }
            }
        }

        return out.joined(separator: "\n")
    }

    /// Compiles the book into a complete print-styled HTML5 book document
    public static func compileHTML(book: BookProject, options: ExportOptions = ExportOptions(), theme: EditorTheme = .parchment) -> String {
        let compilableChapters = book.activeChapters.filter { $0.includeInCompile }
        let bgHex: String
        let textHex: String
        let accentHex: String
        let cardHex: String

        switch theme {
        case .parchment:
            bgHex = "#FAF7EE"
            textHex = "#26221E"
            accentHex = "#9E4724"
            cardHex = "#F3EFE2"
        case .daylight:
            bgHex = "#FFFFFF"
            textHex = "#1E2024"
            accentHex = "#245FA8"
            cardHex = "#F5F7FA"
        case .sepia:
            bgHex = "#F2E9DA"
            textHex = "#34271C"
            accentHex = "#8C3F1D"
            cardHex = "#E9DEC9"
        case .midnight:
            bgHex = "#1A1D22"
            textHex = "#E4E1DA"
            accentHex = "#E09E56"
            cardHex = "#23272E"
        case .amberNight:
            bgHex = "#181411"
            textHex = "#EAD7B7"
            accentHex = "#E68A40"
            cardHex = "#241E1A"
        case .obsidian:
            bgHex = "#0F1012"
            textHex = "#E8EAEF"
            accentHex = "#60C7AD"
            cardHex = "#1A1C20"
        }

        var bodyHTML: [String] = []

        if options.includeTitlePage {
            bodyHTML.append("""
            <section class="title-page">
                <div class="genre-badge">\(escapeHTML(book.genre))</div>
                <h1 class="book-title">\(escapeHTML(book.title))</h1>
                \(!book.subtitle.isEmpty ? "<h2 class=\"book-subtitle\">\(escapeHTML(book.subtitle))</h2>" : "")
                <div class="title-ornament">❦</div>
                <p class="book-author">\(escapeHTML(book.author))</p>
            </section>
            """)
        }

        if options.includeEpigraph && !book.epigraph.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            bodyHTML.append("""
            <section class="epigraph-page">
                <blockquote class="epigraph">
                    <p>“\(escapeHTML(book.epigraph))”</p>
                    \(!book.epigraphAuthor.isEmpty ? "<footer>— \(escapeHTML(book.epigraphAuthor))</footer>" : "")
                </blockquote>
            </section>
            """)
        }

        if options.includeTableOfContents {
            var tocItems: [String] = []
            for (idx, chapter) in compilableChapters.enumerated() {
                let subtitleSpan = (!chapter.subtitle.isEmpty && options.includeChapterSubtitles)
                    ? " <span class=\"toc-sub\">— \(escapeHTML(chapter.subtitle))</span>"
                    : ""
                tocItems.append("""
                <li>
                    <a href="#chapter-\(idx + 1)">
                        <span class="toc-num">Capítulo \(idx + 1)</span>
                        <span class="toc-title">\(escapeHTML(chapter.title))\(subtitleSpan)</span>
                        <span class="toc-words">\(chapter.wordCount) pal.</span>
                    </a>
                </li>
                """)
            }
            bodyHTML.append("""
            <section class="toc-section">
                <h2>Sumário</h2>
                <ol class="toc-list">
                    \(tocItems.joined(separator: "\n"))
                </ol>
            </section>
            """)
        }

        var currentPartId: UUID? = nil
        for (idx, chapter) in compilableChapters.enumerated() {
            if options.includePartDividers, let pId = chapter.partId, pId != currentPartId {
                currentPartId = pId
                if let part = book.parts.first(where: { $0.id == pId }) {
                    bodyHTML.append("""
                    <section class="part-divider">
                        <div class="part-label">Parte / Ato</div>
                        <h2>\(escapeHTML(part.title))</h2>
                        \(!part.subtitle.isEmpty ? "<p class=\"part-subtitle\">\(escapeHTML(part.subtitle))</p>" : "")
                    </section>
                    """)
                }
            }

            let cleanedBody = stripLeadingDuplicateHeading(from: chapter.content, title: chapter.title)
            let chapterBodyHTML = TextAnalytics.markdownToLiteraryHTML(cleanedBody, dropCapFirstParagraph: options.dropCaps)

            bodyHTML.append("""
            <article class="chapter" id="chapter-\(idx + 1)">
                <header class="chapter-header">
                    <div class="chapter-number">Capítulo \(idx + 1)</div>
                    <h2 class="chapter-title">\(escapeHTML(chapter.title))</h2>
                    \((options.includeChapterSubtitles && !chapter.subtitle.isEmpty) ? "<p class=\"chapter-subtitle\">\(escapeHTML(chapter.subtitle))</p>" : "")
                </header>
                <div class="chapter-content">
                    \(chapterBodyHTML)
                </div>
            </article>
            """)
        }

        return """
        <!DOCTYPE html>
        <html lang="pt-BR">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>\(escapeHTML(book.title)) — \(escapeHTML(book.author))</title>
            <style>
                :root {
                    --bg: \(bgHex);
                    --text: \(textHex);
                    --accent: \(accentHex);
                    --card: \(cardHex);
                }
                * { box-sizing: border-box; }
                body {
                    margin: 0;
                    padding: 48px 24px 96px;
                    background-color: var(--bg);
                    color: var(--text);
                    font-family: "Palatino", "Georgia", "Baskerville", serif;
                    font-size: 18px;
                    line-height: 1.75;
                    -webkit-font-smoothing: antialiased;
                }
                .book-container {
                    max-width: 680px;
                    margin: 0 auto;
                }
                .title-page {
                    text-align: center;
                    padding: 96px 24px 88px;
                    border-bottom: 1px solid rgba(128, 128, 128, 0.22);
                    margin-bottom: 64px;
                    page-break-after: always;
                }
                .genre-badge {
                    text-transform: uppercase;
                    letter-spacing: 0.18em;
                    font-size: 0.72rem;
                    color: var(--accent);
                    margin-bottom: 20px;
                }
                .book-title {
                    font-size: 2.7rem;
                    font-weight: 700;
                    line-height: 1.18;
                    margin: 0 0 14px;
                }
                .book-subtitle {
                    font-size: 1.28rem;
                    font-weight: 400;
                    font-style: italic;
                    opacity: 0.78;
                    margin: 0 0 32px;
                }
                .title-ornament {
                    font-size: 1.6rem;
                    color: var(--accent);
                    margin: 28px 0;
                }
                .book-author {
                    font-size: 1.1rem;
                    letter-spacing: 0.08em;
                    text-transform: uppercase;
                }
                .epigraph-page {
                    padding: 56px 32px;
                    margin-bottom: 64px;
                    border-bottom: 1px solid rgba(128, 128, 128, 0.16);
                    page-break-after: always;
                }
                .epigraph {
                    max-width: 480px;
                    margin: 0 auto;
                    font-style: italic;
                    text-align: right;
                }
                .epigraph footer {
                    margin-top: 12px;
                    font-style: normal;
                    font-size: 0.9rem;
                    color: var(--accent);
                }
                .toc-section {
                    padding: 36px 32px;
                    background: var(--card);
                    border-radius: 10px;
                    margin-bottom: 72px;
                    page-break-after: always;
                }
                .toc-section h2 {
                    margin-top: 0;
                    font-size: 1.4rem;
                    letter-spacing: 0.06em;
                    text-transform: uppercase;
                    color: var(--accent);
                }
                .toc-list {
                    list-style: none;
                    padding: 0;
                    margin: 0;
                }
                .toc-list li {
                    border-bottom: 1px dashed rgba(128, 128, 128, 0.25);
                    padding: 10px 0;
                }
                .toc-list a {
                    color: inherit;
                    text-decoration: none;
                    display: flex;
                    justify-content: space-between;
                    align-items: baseline;
                    gap: 12px;
                }
                .toc-num {
                    font-size: 0.78rem;
                    text-transform: uppercase;
                    letter-spacing: 0.1em;
                    color: var(--accent);
                    min-width: 88px;
                }
                .toc-title { flex: 1; font-weight: 600; }
                .toc-sub { font-weight: 400; font-style: italic; opacity: 0.75; }
                .toc-words { font-size: 0.78rem; opacity: 0.6; }
                .part-divider {
                    text-align: center;
                    padding: 72px 16px;
                    margin: 64px 0;
                    border-top: 2px solid var(--accent);
                    border-bottom: 1px solid rgba(128, 128, 128, 0.25);
                    page-break-before: always;
                }
                .part-label {
                    font-size: 0.75rem;
                    text-transform: uppercase;
                    letter-spacing: 0.2em;
                    color: var(--accent);
                }
                .part-divider h2 {
                    font-size: 2rem;
                    margin: 12px 0 8px;
                }
                .part-subtitle {
                    font-style: italic;
                    opacity: 0.78;
                    margin: 0;
                }
                .chapter {
                    margin-bottom: 88px;
                    page-break-before: always;
                }
                .chapter-header {
                    text-align: center;
                    margin-bottom: 42px;
                }
                .chapter-number {
                    font-size: 0.78rem;
                    text-transform: uppercase;
                    letter-spacing: 0.18em;
                    color: var(--accent);
                    margin-bottom: 8px;
                }
                .chapter-title {
                    font-size: 1.95rem;
                    margin: 0 0 8px;
                }
                .chapter-subtitle {
                    font-style: italic;
                    opacity: 0.72;
                    margin: 0;
                }
                .chapter-content p {
                    margin: 0 0 0.9em;
                    text-align: justify;
                    text-indent: 1.6em;
                    hyphens: auto;
                }
                .chapter-content p.first-paragraph {
                    text-indent: 0;
                }
                .chapter-content p.first-paragraph::first-letter {
                    float: left;
                    font-size: 3.3em;
                    line-height: 0.84;
                    padding-right: 10px;
                    padding-top: 4px;
                    color: var(--accent);
                    font-weight: 700;
                }
                .chapter-content p.dialogue {
                    text-indent: 1.6em;
                }
                .scene-break {
                    text-align: center;
                    color: var(--accent);
                    font-size: 1.25rem;
                    margin: 28px 0;
                    letter-spacing: 0.3em;
                }
                blockquote {
                    margin: 24px 0;
                    padding: 12px 22px;
                    border-left: 3px solid var(--accent);
                    background: var(--card);
                    font-style: italic;
                    border-radius: 0 6px 6px 0;
                }
                blockquote p {
                    text-indent: 0 !important;
                    margin-bottom: 0.4em !important;
                }
                .wikilink {
                    border-bottom: 1px dotted var(--accent);
                }
            </style>
        </head>
        <body>
            <main class="book-container">
                \(bodyHTML.joined(separator: "\n"))
            </main>
        </body>
        </html>
        """
    }

    /// Exports a structured directory containing Markdown chapters, characters, locations, research notes, and project JSON
    public static func exportStructuredFolder(book: BookProject, to directoryURL: URL) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let manuscriptDir = directoryURL.appendingPathComponent("01_Manuscrito", isDirectory: true)
        let charactersDir = directoryURL.appendingPathComponent("02_Personagens", isDirectory: true)
        let locationsDir = directoryURL.appendingPathComponent("03_Locais", isDirectory: true)
        let researchDir = directoryURL.appendingPathComponent("04_Pesquisa", isDirectory: true)

        for dir in [manuscriptDir, charactersDir, locationsDir, researchDir] {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        // Write full compiled manuscript at root
        let compiled = compileMarkdown(book: book)
        try compiled.write(
            to: directoryURL.appendingPathComponent("00_Livro_Completo.md"),
            atomically: true,
            encoding: .utf8
        )

        // Write individual chapters
        for (idx, chapter) in book.activeChapters.enumerated() {
            let safeTitle = sanitizeFilename(chapter.title)
            let filename = String(format: "%02d_%@.md", idx + 1, safeTitle)
            var fileText = """
            ---
            title: "\(escapeYAML(chapter.title))"
            subtitle: "\(escapeYAML(chapter.subtitle))"
            status: "\(chapter.status.rawValue)"
            words: \(chapter.wordCount)
            synopsis: "\(escapeYAML(chapter.synopsis))"
            ---

            \(chapter.content)
            """
            if !chapter.notes.isEmpty {
                fileText += "\n\n<!-- Notas do Autor:\n\(chapter.notes)\n-->\n"
            }
            try fileText.write(
                to: manuscriptDir.appendingPathComponent(filename),
                atomically: true,
                encoding: .utf8
            )
        }

        // Write characters
        for char in book.characters {
            let filename = "\(sanitizeFilename(char.name)).md"
            let text = """
            # \(char.name)
            **Papel**: \(char.role.rawValue) | **Idade**: \(char.age) | **Arquétipo**: \(char.archetype)

            ## Resumo
            \(char.summary)

            ## Descrição Física
            \(char.physicalDescription)

            ## Motivação
            \(char.motivation)

            ## Conflito Interno
            \(char.internalConflict)

            ## Arco Narrativo
            \(char.arcNotes)
            """
            try text.write(to: charactersDir.appendingPathComponent(filename), atomically: true, encoding: .utf8)
        }

        // Write locations
        for loc in book.locations {
            let filename = "\(sanitizeFilename(loc.name)).md"
            let text = """
            # \(loc.name)
            **Região**: \(loc.region)
            **Atmosfera**: \(loc.atmosphere)

            ## Detalhes Sensoriais
            \(loc.sensoryDetails)

            ## Descrição
            \(loc.description)

            ## Notas
            \(loc.notes)
            """
            try text.write(to: locationsDir.appendingPathComponent(filename), atomically: true, encoding: .utf8)
        }

        // Write research notes
        for note in book.researchNotes {
            let filename = "\(sanitizeFilename(note.title)).md"
            try note.content.write(to: researchDir.appendingPathComponent(filename), atomically: true, encoding: .utf8)
        }

        // Write JSON backup
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(book)
        try data.write(to: directoryURL.appendingPathComponent("projeto.tinta.json"))
    }

    /// Generates a paginated PDF file of the compiled book using CoreGraphics / NSAttributedString
    @MainActor
    public static func exportPDF(book: BookProject, options: ExportOptions = ExportOptions(), to fileURL: URL) throws {
        let html = compileHTML(book: book, options: options, theme: .daylight)
        guard let htmlData = html.data(using: .utf8),
              let attrString = NSAttributedString(html: htmlData, documentAttributes: nil) else {
            throw NSError(domain: "TintaExporter", code: 1, userInfo: [NSLocalizedDescriptionKey: "Não foi possível renderizar o documento para PDF."])
        }

        let pageSize = NSSize(width: 595.28, height: 841.89) // A4 points
        let margin: CGFloat = 56.0
        let printableWidth = pageSize.width - (margin * 2)
        let printableHeight = pageSize.height - (margin * 2)

        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: printableWidth, height: printableHeight))
        textView.textStorage?.setAttributedString(attrString)

        let printInfo = NSPrintInfo()
        printInfo.paperSize = pageSize
        printInfo.leftMargin = margin
        printInfo.rightMargin = margin
        printInfo.topMargin = margin
        printInfo.bottomMargin = margin
        printInfo.isHorizontallyCentered = true
        printInfo.isVerticallyCentered = false
        printInfo.jobDisposition = .save
        printInfo.dictionary()[NSPrintInfo.AttributeKey.jobSavingURL] = fileURL

        let printOp = NSPrintOperation(view: textView, printInfo: printInfo)
        printOp.showsPrintPanel = false
        printOp.showsProgressPanel = false
        _ = printOp.run()
    }

    /// Generates a standards-compliant EPUB 3 eBook (.epub) compatible with Amazon Kindle (Send to Kindle / KDP), Apple Books, and Kobo
    public static func exportEPUB(book: BookProject, options: ExportOptions = ExportOptions(), to fileURL: URL) throws {
        let fm = FileManager.default
        let stagingDir = fm.temporaryDirectory.appendingPathComponent("TintaEPUB_\(UUID().uuidString)", isDirectory: true)
        let metaInfDir = stagingDir.appendingPathComponent("META-INF", isDirectory: true)
        let oebpsDir = stagingDir.appendingPathComponent("OEBPS", isDirectory: true)

        defer {
            try? fm.removeItem(at: stagingDir)
        }

        try fm.createDirectory(at: metaInfDir, withIntermediateDirectories: true)
        try fm.createDirectory(at: oebpsDir, withIntermediateDirectories: true)

        // 1. mimetype (must be plain ASCII without trailing newline)
        let mimetypeURL = stagingDir.appendingPathComponent("mimetype")
        try "application/epub+zip".write(to: mimetypeURL, atomically: true, encoding: .ascii)

        // 2. META-INF/container.xml
        let containerXML = """
        <?xml version="1.0" encoding="UTF-8"?>
        <container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
            <rootfiles>
                <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
            </rootfiles>
        </container>
        """
        try containerXML.write(to: metaInfDir.appendingPathComponent("container.xml"), atomically: true, encoding: .utf8)

        // 3. OEBPS/style.css (Kindle & eReader optimized stylesheet)
        let styleCSS = """
        body {
            font-family: Georgia, Palatino, "Bookerly", serif;
            line-height: 1.65;
            margin: 4%;
        }
        h1, h2, h3 {
            font-family: Georgia, Palatino, "Bookerly", serif;
            line-height: 1.25;
            page-break-after: avoid;
        }
        .title-page {
            text-align: center;
            margin-top: 18%;
            page-break-after: always;
        }
        .genre-badge {
            font-size: 0.78em;
            letter-spacing: 0.16em;
            text-transform: uppercase;
            margin-bottom: 1.2em;
        }
        .book-title {
            font-size: 2.2em;
            font-weight: bold;
            margin: 0.2em 0;
        }
        .book-subtitle {
            font-size: 1.15em;
            font-style: italic;
            font-weight: normal;
            margin: 0.4em 0 1.8em;
        }
        .title-ornament {
            font-size: 1.4em;
            margin: 1.2em 0;
        }
        .book-author {
            font-size: 1.05em;
            letter-spacing: 0.08em;
            text-transform: uppercase;
        }
        .epigraph-page {
            margin-top: 15%;
            padding: 0 8%;
            font-style: italic;
            text-align: right;
            page-break-after: always;
        }
        .part-banner {
            text-align: center;
            padding: 1.8em 0;
            margin-bottom: 1.8em;
            border-top: 1px solid #888888;
            border-bottom: 1px solid #888888;
        }
        .part-label {
            font-size: 0.75em;
            text-transform: uppercase;
            letter-spacing: 0.18em;
        }
        .chapter-header {
            text-align: center;
            margin: 1.5em 0 2.2em;
        }
        .chapter-number {
            font-size: 0.78em;
            text-transform: uppercase;
            letter-spacing: 0.16em;
            margin-bottom: 0.4em;
        }
        .chapter-title {
            font-size: 1.65em;
            margin: 0.2em 0;
        }
        .chapter-subtitle {
            font-style: italic;
            font-size: 0.95em;
            margin: 0.3em 0 0;
        }
        p {
            margin: 0 0 0.75em;
            text-align: justify;
            text-indent: 1.4em;
        }
        p.first-paragraph {
            text-indent: 0;
        }
        .drop-cap p.first-paragraph:first-letter {
            font-size: 2.6em;
            font-weight: bold;
            float: left;
            line-height: 0.85;
            padding-right: 0.12em;
        }
        ul, ol {
            margin: 0.8em 0 0.8em 1.6em;
            padding: 0;
        }
        li {
            margin-bottom: 0.4em;
            text-align: left;
        }
        blockquote {
            margin: 1.2em 1.4em;
            padding-left: 0.9em;
            border-left: 2px solid #888888;
            font-style: italic;
        }
        blockquote p {
            text-indent: 0;
        }
        .scene-break {
            text-align: center;
            margin: 1.6em 0;
            font-size: 1.15em;
            letter-spacing: 0.25em;
        }
        table.md-table {
            width: 100%;
            border-collapse: collapse;
            margin: 1.2em 0;
            font-size: 0.88em;
        }
        table.md-table th, table.md-table td {
            border: 1px solid #888888;
            padding: 6px 8px;
            text-align: left;
            vertical-align: top;
        }
        table.md-table th {
            font-weight: bold;
        }
        nav#toc ol {
            list-style-type: decimal;
            padding-left: 1.4em;
        }
        nav#toc li {
            margin-bottom: 0.5em;
        }
        nav#toc a {
            text-decoration: none;
        }
        """
        try styleCSS.write(to: oebpsDir.appendingPathComponent("style.css"), atomically: true, encoding: .utf8)

        func wrapXHTML(title: String, bodyContent: String) -> String {
            return """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE html>
            <html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" xml:lang="pt-BR" lang="pt-BR">
            <head>
                <meta charset="UTF-8" />
                <title>\(escapeHTML(title))</title>
                <link rel="stylesheet" type="text/css" href="style.css" />
            </head>
            <body>
            \(bodyContent)
            </body>
            </html>
            """
        }

        var manifestItems: [(id: String, href: String, mediaType: String, properties: String?)] = [
            ("css", "style.css", "text/css", nil),
            ("ncx", "toc.ncx", "application/x-dtbncx+xml", nil),
            ("nav", "nav.xhtml", "application/xhtml+xml", "nav")
        ]
        var spineItemIds: [String] = []
        var tocEntries: [(id: String, title: String, href: String)] = []

        // 4. Optional Title Page
        if options.includeTitlePage {
            let subtitleHTML = !book.subtitle.isEmpty ? "<h2 class=\"book-subtitle\">\(escapeHTML(book.subtitle))</h2>" : ""
            let titlePageBody = """
            <section class="title-page" epub:type="titlepage">
                <div class="genre-badge">\(escapeHTML(book.genre))</div>
                <h1 class="book-title">\(escapeHTML(book.title))</h1>
                \(subtitleHTML)
                <div class="title-ornament">❦</div>
                <p class="book-author" style="text-indent:0; text-align:center;">\(escapeHTML(book.author))</p>
            </section>
            """
            try wrapXHTML(title: book.title, bodyContent: titlePageBody)
                .write(to: oebpsDir.appendingPathComponent("titlepage.xhtml"), atomically: true, encoding: .utf8)
            manifestItems.append(("titlepage", "titlepage.xhtml", "application/xhtml+xml", nil))
            spineItemIds.append("titlepage")
            tocEntries.append(("titlepage", "Folha de Rosto", "titlepage.xhtml"))
        }

        // 5. Optional Epigraph Page
        if options.includeEpigraph && !book.epigraph.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let authorLine = !book.epigraphAuthor.isEmpty ? "<p style=\"text-indent:0; text-align:right;\">— \(escapeHTML(book.epigraphAuthor))</p>" : ""
            let epigraphBody = """
            <section class="epigraph-page" epub:type="epigraph">
                <p style="text-indent:0; text-align:right;">“\(escapeHTML(book.epigraph))”</p>
                \(authorLine)
            </section>
            """
            try wrapXHTML(title: "Epígrafe", bodyContent: epigraphBody)
                .write(to: oebpsDir.appendingPathComponent("epigraph.xhtml"), atomically: true, encoding: .utf8)
            manifestItems.append(("epigraph", "epigraph.xhtml", "application/xhtml+xml", nil))
            spineItemIds.append("epigraph")
        }

        // Include visible TOC in spine if requested
        if options.includeTableOfContents {
            spineItemIds.append("nav")
        }

        // 6. Chapters
        let compilableChapters = book.activeChapters.filter { $0.includeInCompile }
        var currentPartId: UUID? = nil

        for (idx, chapter) in compilableChapters.enumerated() {
            let chapNum = idx + 1
            let fileId = String(format: "chapter-%02d", chapNum)
            let fileName = "\(fileId).xhtml"

            var partBannerHTML = ""
            if options.includePartDividers, let pId = chapter.partId, pId != currentPartId {
                currentPartId = pId
                if let part = book.parts.first(where: { $0.id == pId }) {
                    let partSub = !part.subtitle.isEmpty ? "<p style=\"text-indent:0; text-align:center; font-style:italic;\">\(escapeHTML(part.subtitle))</p>" : ""
                    partBannerHTML = """
                    <div class="part-banner">
                        <div class="part-label">Parte / Ato</div>
                        <h2>\(escapeHTML(part.title))</h2>
                        \(partSub)
                    </div>
                    """
                }
            }

            let cleanedBody = stripLeadingDuplicateHeading(from: chapter.content, title: chapter.title)
            let bodyHTML = TextAnalytics.markdownToLiteraryHTML(cleanedBody, dropCapFirstParagraph: options.dropCaps)
            let subtitleHTML = (options.includeChapterSubtitles && !chapter.subtitle.isEmpty)
                ? "<p class=\"chapter-subtitle\" style=\"text-indent:0; text-align:center;\">\(escapeHTML(chapter.subtitle))</p>"
                : ""
            let dropCapClass = options.dropCaps ? " class=\"drop-cap\"" : ""

            let chapterXHTMLBody = """
            <article epub:type="chapter"\(dropCapClass)>
                \(partBannerHTML)
                <header class="chapter-header">
                    <div class="chapter-number">Capítulo \(chapNum)</div>
                    <h1 class="chapter-title">\(escapeHTML(chapter.title))</h1>
                    \(subtitleHTML)
                </header>
                <div class="chapter-body">
                    \(bodyHTML)
                </div>
            </article>
            """

            try wrapXHTML(title: "Capítulo \(chapNum): \(chapter.title)", bodyContent: chapterXHTMLBody)
                .write(to: oebpsDir.appendingPathComponent(fileName), atomically: true, encoding: .utf8)

            manifestItems.append((fileId, fileName, "application/xhtml+xml", nil))
            spineItemIds.append(fileId)
            tocEntries.append((fileId, "Capítulo \(chapNum): \(chapter.title)", fileName))
        }

        // 7. Optional Story Bible Appendix
        if options.includeStoryBibleAppendix && (!book.characters.isEmpty || !book.locations.isEmpty) {
            var appendixParts: [String] = ["<section epub:type=\"appendix\">", "<h1>Apêndice — Bíblia da História</h1>"]
            if !book.characters.isEmpty {
                appendixParts.append("<h2>Personagens</h2>")
                for char in book.characters {
                    appendixParts.append("<h3>\(escapeHTML(char.name)) (\(escapeHTML(char.role.rawValue)))</h3>")
                    if !char.summary.isEmpty {
                        appendixParts.append("<p>\(escapeHTML(char.summary))</p>")
                    }
                }
            }
            if !book.locations.isEmpty {
                appendixParts.append("<h2>Locais &amp; Cenários</h2>")
                for loc in book.locations {
                    appendixParts.append("<h3>\(escapeHTML(loc.name))</h3>")
                    if !loc.description.isEmpty {
                        appendixParts.append("<p>\(escapeHTML(loc.description))</p>")
                    }
                }
            }
            appendixParts.append("</section>")

            try wrapXHTML(title: "Apêndice — Bíblia da História", bodyContent: appendixParts.joined(separator: "\n"))
                .write(to: oebpsDir.appendingPathComponent("appendix.xhtml"), atomically: true, encoding: .utf8)
            manifestItems.append(("appendix", "appendix.xhtml", "application/xhtml+xml", nil))
            spineItemIds.append("appendix")
            tocEntries.append(("appendix", "Apêndice — Bíblia da História", "appendix.xhtml"))
        }

        // 8. OEBPS/nav.xhtml (EPUB 3 Navigation Document)
        let navListItems = tocEntries.map { entry in
            "<li><a href=\"\(entry.href)\">\(escapeHTML(entry.title))</a></li>"
        }.joined(separator: "\n                ")

        let firstContentHref = tocEntries.first?.href ?? "nav.xhtml"
        let navXHTML = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE html>
        <html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" xml:lang="pt-BR" lang="pt-BR">
        <head>
            <meta charset="UTF-8" />
            <title>Sumário</title>
            <link rel="stylesheet" type="text/css" href="style.css" />
        </head>
        <body>
            <nav epub:type="toc" id="toc">
                <h1>Sumário</h1>
                <ol>
                \(navListItems)
                </ol>
            </nav>
            <nav epub:type="landmarks" hidden="hidden">
                <h2>Guia</h2>
                <ol>
                    <li><a epub:type="toc" href="nav.xhtml">Sumário</a></li>
                    <li><a epub:type="bodymatter" href="\(firstContentHref)">Início da Leitura</a></li>
                </ol>
            </nav>
        </body>
        </html>
        """
        try navXHTML.write(to: oebpsDir.appendingPathComponent("nav.xhtml"), atomically: true, encoding: .utf8)

        // 9. OEBPS/toc.ncx (Kindle NCX compatibility)
        let navPoints = tocEntries.enumerated().map { idx, entry in
            """
            <navPoint id="navPoint-\(idx + 1)" playOrder="\(idx + 1)">
                <navLabel><text>\(escapeHTML(entry.title))</text></navLabel>
                <content src="\(entry.href)"/>
            </navPoint>
            """
        }.joined(separator: "\n        ")

        let tocNCX = """
        <?xml version="1.0" encoding="UTF-8"?>
        <ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
            <head>
                <meta name="dtb:uid" content="urn:uuid:\(book.id.uuidString)"/>
                <meta name="dtb:depth" content="1"/>
                <meta name="dtb:totalPageCount" content="0"/>
                <meta name="dtb:maxPageNumber" content="0"/>
            </head>
            <docTitle><text>\(escapeHTML(book.title))</text></docTitle>
            <docAuthor><text>\(escapeHTML(book.author))</text></docAuthor>
            <navMap>
                \(navPoints)
            </navMap>
        </ncx>
        """
        try tocNCX.write(to: oebpsDir.appendingPathComponent("toc.ncx"), atomically: true, encoding: .utf8)

        // 10. OEBPS/content.opf
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        let modifiedTimestamp = isoFormatter.string(from: Date())

        let manifestXML = manifestItems.map { item in
            let propAttr = item.properties != nil ? " properties=\"\(item.properties!)\"" : ""
            return "<item id=\"\(item.id)\" href=\"\(item.href)\" media-type=\"\(item.mediaType)\"\(propAttr)/>"
        }.joined(separator: "\n        ")

        let spineXML = spineItemIds.map { id in
            "<itemref idref=\"\(id)\"/>"
        }.joined(separator: "\n        ")

        let contentOPF = """
        <?xml version="1.0" encoding="UTF-8"?>
        <package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="BookId" xml:lang="pt-BR">
            <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
                <dc:identifier id="BookId">urn:uuid:\(book.id.uuidString)</dc:identifier>
                <dc:title>\(escapeHTML(book.title))</dc:title>
                <dc:creator>\(escapeHTML(book.author))</dc:creator>
                <dc:language>pt-BR</dc:language>
                <dc:subject>\(escapeHTML(book.genre))</dc:subject>
                <dc:description>\(escapeHTML(book.synopsis))</dc:description>
                <meta property="dcterms:modified">\(modifiedTimestamp)</meta>
            </metadata>
            <manifest>
                \(manifestXML)
            </manifest>
            <spine toc="ncx">
                \(spineXML)
            </spine>
        </package>
        """
        try contentOPF.write(to: oebpsDir.appendingPathComponent("content.opf"), atomically: true, encoding: .utf8)

        // 11. Package into valid EPUB ZIP archive (/usr/bin/zip)
        if fm.fileExists(atPath: fileURL.path) {
            try fm.removeItem(at: fileURL)
        }

        // Step A: Store mimetype uncompressed (-0 -X) as the first entry
        try runZip(arguments: ["-0", "-X", "-q", fileURL.path, "mimetype"], currentDirectory: stagingDir)
        // Step B: Add META-INF and OEBPS recursively (-r -X -9)
        try runZip(arguments: ["-r", "-X", "-9", "-q", fileURL.path, "META-INF", "OEBPS"], currentDirectory: stagingDir)
    }

    private static func runZip(arguments: [String], currentDirectory: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.arguments = arguments
        process.currentDirectoryURL = currentDirectory

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw NSError(
                domain: "TintaExporter",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: "Falha ao empacotar o arquivo EPUB (código \(process.terminationStatus))."]
            )
        }
    }

    public static func stripLeadingDuplicateHeading(from content: String, title: String) -> String {
        let lines = content.components(separatedBy: .newlines)
        guard let firstNonEmptyIdx = lines.firstIndex(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) else {
            return content
        }
        let firstLine = lines[firstNonEmptyIdx].trimmingCharacters(in: .whitespaces)
        if firstLine.hasPrefix("# ") {
            let headingText = String(firstLine.dropFirst(2)).trimmingCharacters(in: .whitespaces)
            if headingText.caseInsensitiveCompare(title) == .orderedSame {
                let remaining = Array(lines.dropFirst(firstNonEmptyIdx + 1))
                return remaining.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func sanitizeFilename(_ name: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        let cleaned = name.components(separatedBy: invalid).joined(separator: "_")
        let trimmed = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Sem_Titulo" : trimmed.replacingOccurrences(of: " ", with: "_")
    }

    private static func escapeYAML(_ text: String) -> String {
        text.replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\n", with: " ")
    }

    private static func escapeHTML(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
