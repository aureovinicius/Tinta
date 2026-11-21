import Foundation

public struct RepeatedWordItem: Equatable, Identifiable {
    public var id: String { word }
    public let word: String
    public let count: Int
}

public struct ChapterStatistics: Equatable {
    public let wordCount: Int
    public let characterCount: Int
    public let characterCountNoSpaces: Int
    public let paragraphCount: Int
    public let sentenceCount: Int
    public let averageWordsPerSentence: Double
    public let dialogueLineRatio: Double
    public let readingTimeMinutes: Int
    public let speakingTimeMinutes: Int
    public let estimatedPages: Int
    public let topRepeatedWords: [RepeatedWordItem]
}

public enum TextAnalytics {
    private static let portugueseStopWords: Set<String> = [
        "a", "ao", "aos", "aquela", "aquelas", "aquele", "aqueles", "aquilo", "as", "até",
        "com", "como", "da", "das", "de", "dela", "delas", "dele", "deles", "depois",
        "do", "dos", "e", "ela", "elas", "ele", "eles", "em", "entre", "era", "eram",
        "essa", "essas", "esse", "esses", "esta", "está", "estão", "estas", "este", "estes",
        "eu", "foi", "foram", "há", "isso", "isto", "já", "lhe", "lhes", "mais", "mas",
        "me", "mesmo", "meu", "meus", "minha", "minhas", "muito", "na", "não", "nas",
        "nem", "no", "nos", "nós", "nossa", "nossas", "nosso", "nossos", "num", "numa",
        "o", "os", "ou", "para", "pela", "pelas", "pelo", "pelos", "por", "qual", "quando",
        "que", "quem", "se", "sem", "ser", "seu", "seus", "só", "sua", "suas", "também",
        "te", "tem", "têm", "tinha", "todo", "todos", "tu", "tua", "tuas", "tudo", "um",
        "uma", "umas", "uns", "você", "vocês", "sobre", "ainda", "onde", "então", "apenas"
    ]

    public static func countWords(in text: String) -> Int {
        guard !text.isEmpty else { return 0 }
        var count = 0
        text.enumerateSubstrings(in: text.startIndex..<text.endIndex, options: [.byWords, .localized]) { _, _, _, _ in
            count += 1
        }
        return count
    }

    public static func analyze(_ text: String) -> ChapterStatistics {
        let words = extractWords(from: text)
        let wordCount = words.count
        let charCount = text.count
        let charNoSpaces = text.unicodeScalars.filter { !CharacterSet.whitespacesAndNewlines.contains($0) }.count

        let nonEmptyLines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let paragraphCount = nonEmptyLines.count

        var sentenceCount = 0
        text.enumerateSubstrings(in: text.startIndex..<text.endIndex, options: [.bySentences, .localized]) { sub, _, _, _ in
            if let sub = sub, !sub.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                sentenceCount += 1
            }
        }
        let safeSentences = max(1, sentenceCount)
        let avgSentence = wordCount > 0 ? Double(wordCount) / Double(safeSentences) : 0.0

        let dialogueLines = nonEmptyLines.filter { line in
            line.hasPrefix("—") || line.hasPrefix("--") || line.hasPrefix("–") || line.hasPrefix("\"") || line.hasPrefix("“")
        }.count
        let dialogueRatio = nonEmptyLines.isEmpty ? 0.0 : Double(dialogueLines) / Double(nonEmptyLines.count)

        let readingMinutes = max(1, Int(ceil(Double(wordCount) / 220.0)))
        let speakingMinutes = max(1, Int(ceil(Double(wordCount) / 140.0)))
        let estimatedPages = max(1, Int(ceil(Double(wordCount) / 250.0)))

        var frequencies: [String: Int] = [:]
        for w in words {
            let lower = w.lowercased()
            guard lower.count >= 4, !portugueseStopWords.contains(lower) else { continue }
            frequencies[lower, default: 0] += 1
        }

        let topRepeated = frequencies
            .filter { $0.value >= 2 }
            .sorted {
                if $0.value == $1.value { return $0.key < $1.key }
                return $0.value > $1.value
            }
            .prefix(8)
            .map { RepeatedWordItem(word: $0.key, count: $0.value) }

        return ChapterStatistics(
            wordCount: wordCount,
            characterCount: charCount,
            characterCountNoSpaces: charNoSpaces,
            paragraphCount: paragraphCount,
            sentenceCount: sentenceCount,
            averageWordsPerSentence: avgSentence,
            dialogueLineRatio: dialogueRatio,
            readingTimeMinutes: wordCount == 0 ? 0 : readingMinutes,
            speakingTimeMinutes: wordCount == 0 ? 0 : speakingMinutes,
            estimatedPages: wordCount == 0 ? 0 : estimatedPages,
            topRepeatedWords: topRepeated
        )
    }

    public static func extractWords(from text: String) -> [String] {
        var result: [String] = []
        text.enumerateSubstrings(in: text.startIndex..<text.endIndex, options: [.byWords, .localized]) { substring, _, _, _ in
            if let word = substring, !word.isEmpty {
                result.append(word)
            }
        }
        return result
    }

    public static func extractOutlineHeadings(from markdown: String) -> [(level: Int, title: String, lineIndex: Int)] {
        let lines = markdown.components(separatedBy: .newlines)
        var headings: [(level: Int, title: String, lineIndex: Int)] = []
        for (idx, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("### ") {
                headings.append((3, String(trimmed.dropFirst(4)), idx))
            } else if trimmed.hasPrefix("## ") {
                headings.append((2, String(trimmed.dropFirst(3)), idx))
            } else if trimmed.hasPrefix("# ") {
                headings.append((1, String(trimmed.dropFirst(2)), idx))
            }
        }
        return headings
    }

    private static let numberedListLineRegex = try! NSRegularExpression(pattern: "^(\\d+)\\.\\s+(.*)$")

    /// Converts Markdown text into literary HTML/XHTML paragraphs, lists, and tables for Preview, HTML, PDF, and EPUB export
    public static func markdownToLiteraryHTML(_ markdown: String, dropCapFirstParagraph: Bool = true) -> String {
        let lines = markdown.components(separatedBy: .newlines)
        var htmlParts: [String] = []
        var isFirstBodyParagraph = dropCapFirstParagraph
        var inBlockquote = false
        var inUl = false
        var inOl = false

        func closeOpenContainers() {
            if inBlockquote {
                htmlParts.append("</blockquote>")
                inBlockquote = false
            }
            if inUl {
                htmlParts.append("</ul>")
                inUl = false
            }
            if inOl {
                htmlParts.append("</ol>")
                inOl = false
            }
        }

        var idx = 0
        while idx < lines.count {
            let trimmed = lines[idx].trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                closeOpenContainers()
                idx += 1
                continue
            }

            // Ignore editor comments %% ... %%
            if trimmed.hasPrefix("%%") && trimmed.hasSuffix("%%") {
                idx += 1
                continue
            }

            if trimmed == "* * *" || trimmed == "***" || trimmed == "---" {
                closeOpenContainers()
                htmlParts.append("<div class=\"scene-break\">⁂</div>")
                isFirstBodyParagraph = false
                idx += 1
                continue
            }

            if trimmed.hasPrefix("### ") {
                closeOpenContainers()
                let content = formatInlineMarkdown(String(trimmed.dropFirst(4)))
                htmlParts.append("<h3>\(content)</h3>")
                idx += 1
                continue
            } else if trimmed.hasPrefix("## ") {
                closeOpenContainers()
                let content = formatInlineMarkdown(String(trimmed.dropFirst(3)))
                htmlParts.append("<h2>\(content)</h2>")
                idx += 1
                continue
            } else if trimmed.hasPrefix("# ") {
                closeOpenContainers()
                let content = formatInlineMarkdown(String(trimmed.dropFirst(2)))
                htmlParts.append("<h1>\(content)</h1>")
                idx += 1
                continue
            }

            // Markdown Tables
            if trimmed.hasPrefix("|") && trimmed.hasSuffix("|") {
                closeOpenContainers()
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
                htmlParts.append(renderTableHTML(from: tableLines))
                isFirstBodyParagraph = false
                continue
            }

            // Bullet list (* or - or •)
            if trimmed.hasPrefix("* ") || trimmed.hasPrefix("- ") || trimmed.hasPrefix("• ") {
                if inBlockquote { htmlParts.append("</blockquote>"); inBlockquote = false }
                if inOl { htmlParts.append("</ol>"); inOl = false }
                if !inUl {
                    htmlParts.append("<ul>")
                    inUl = true
                }
                let itemContent = formatInlineMarkdown(String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces))
                htmlParts.append("<li>\(itemContent)</li>")
                isFirstBodyParagraph = false
                idx += 1
                continue
            }

            // Numbered list (1. , 2. , etc.)
            let nsTrimmed = trimmed as NSString
            if let match = numberedListLineRegex.firstMatch(in: trimmed, range: NSRange(location: 0, length: nsTrimmed.length)),
               match.numberOfRanges == 3 {
                if inBlockquote { htmlParts.append("</blockquote>"); inBlockquote = false }
                if inUl { htmlParts.append("</ul>"); inUl = false }
                if !inOl {
                    htmlParts.append("<ol>")
                    inOl = true
                }
                let itemContent = formatInlineMarkdown(nsTrimmed.substring(with: match.range(at: 2)))
                htmlParts.append("<li>\(itemContent)</li>")
                isFirstBodyParagraph = false
                idx += 1
                continue
            }

            if trimmed.hasPrefix("> ") || trimmed == ">" {
                if inUl { htmlParts.append("</ul>"); inUl = false }
                if inOl { htmlParts.append("</ol>"); inOl = false }
                if !inBlockquote {
                    htmlParts.append("<blockquote>")
                    inBlockquote = true
                }
                let quoteText = trimmed.hasPrefix("> ") ? String(trimmed.dropFirst(2)) : ""
                htmlParts.append("<p>\(formatInlineMarkdown(quoteText))</p>")
                idx += 1
                continue
            }

            closeOpenContainers()

            let formatted = formatInlineMarkdown(trimmed)
            let isDialogue = trimmed.hasPrefix("—") || trimmed.hasPrefix("–") || trimmed.hasPrefix("--")
            if isFirstBodyParagraph && !isDialogue {
                htmlParts.append("<p class=\"first-paragraph\">\(formatted)</p>")
                isFirstBodyParagraph = false
            } else if isDialogue {
                htmlParts.append("<p class=\"dialogue\">\(formatted)</p>")
                isFirstBodyParagraph = false
            } else {
                htmlParts.append("<p>\(formatted)</p>")
            }
            idx += 1
        }

        closeOpenContainers()
        return htmlParts.joined(separator: "\n")
    }

    private static func renderTableHTML(from lines: [String]) -> String {
        guard !lines.isEmpty else { return "" }
        func splitCells(_ line: String) -> [String] {
            var inner = line
            if inner.hasPrefix("|") { inner.removeFirst() }
            if inner.hasSuffix("|") { inner.removeLast() }
            return inner.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
        }
        let headerCells = splitCells(lines[0])
        var html: [String] = ["<table class=\"md-table\">", "<thead><tr>"]
        for cell in headerCells {
            html.append("<th>\(formatInlineMarkdown(cell))</th>")
        }
        html.append("</tr></thead>")
        html.append("<tbody>")
        for (i, line) in lines.enumerated() where i > 0 {
            let cells = splitCells(line)
            let isSeparator = cells.allSatisfy { c in !c.isEmpty && c.allSatisfy { $0 == "-" || $0 == ":" || $0 == " " } }
            if isSeparator { continue }
            html.append("<tr>")
            for colIdx in 0..<headerCells.count {
                let cellText = colIdx < cells.count ? cells[colIdx] : ""
                html.append("<td>\(formatInlineMarkdown(cellText))</td>")
            }
            html.append("</tr>")
        }
        html.append("</tbody></table>")
        return html.joined(separator: "\n")
    }

    public static func formatInlineMarkdown(_ text: String) -> String {
        var escaped = text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")

        // Convert double hyphen at start or inline to literary em-dash
        if escaped.hasPrefix("-- ") {
            escaped = "— " + String(escaped.dropFirst(3))
        } else if escaped.hasPrefix("--") {
            escaped = "—" + String(escaped.dropFirst(2))
        }

        // Bold+Italic ***text***
        escaped = applyRegex(escaped, pattern: "\\*\\*\\*(?=\\S)(.+?)(?<=\\S)\\*\\*\\*", template: "<strong><em>$1</em></strong>")
        // Bold **text**
        escaped = applyRegex(escaped, pattern: "\\*\\*(?=\\S)(.+?)(?<=\\S)\\*\\*", template: "<strong>$1</strong>")
        // Italic *text* or _text_
        escaped = applyRegex(escaped, pattern: "(?<!\\*)\\*(?![\\*\\s])(.+?)(?<![\\*\\s])\\*(?!\\*)", template: "<em>$1</em>")
        escaped = applyRegex(escaped, pattern: "(?<!_)_(?![_\\s])(.+?)(?<![_\\s])_(?!_)", template: "<em>$1</em>")
        //Inline code `code`
        escaped = applyRegex(escaped, pattern: "`([^`]+)`", template: "<code>$1</code>")
        // WikiLinks [[Entity]]
        escaped = applyRegex(escaped, pattern: "\\[\\[([^\\]]+)\\]\\]", template: "<span class=\"wikilink\">$1</span>")

        return escaped
    }

    private static func applyRegex(_ input: String, pattern: String, template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return input
        }
        let range = NSRange(input.startIndex..<input.endIndex, in: input)
        return regex.stringByReplacingMatches(in: input, options: [], range: range, withTemplate: template)
    }
}
