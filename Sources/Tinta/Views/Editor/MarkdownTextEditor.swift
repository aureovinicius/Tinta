import AppKit
import Combine
import SwiftUI

public struct MarkdownTextEditor: NSViewRepresentable {
    @Binding public var text: String
    public var theme: EditorTheme
    public var fontStyle: EditorFontStyle
    public var fontSize: CGFloat
    public var lineSpacing: CGFloat
    public var columnWidth: CGFloat
    public var typewriterScrolling: Bool
    public var focusMode: FocusHighlightMode
    public var commandPublisher: PassthroughSubject<BookStore.EditorFormatCommand, Never>
    public var onSplitAtCursor: ((Int) -> Void)?

    public init(
        text: Binding<String>,
        theme: EditorTheme,
        fontStyle: EditorFontStyle,
        fontSize: CGFloat,
        lineSpacing: CGFloat,
        columnWidth: CGFloat,
        typewriterScrolling: Bool,
        focusMode: FocusHighlightMode,
        commandPublisher: PassthroughSubject<BookStore.EditorFormatCommand, Never>,
        onSplitAtCursor: ((Int) -> Void)? = nil
    ) {
        self._text = text
        self.theme = theme
        self.fontStyle = fontStyle
        self.fontSize = fontSize
        self.lineSpacing = lineSpacing
        self.columnWidth = columnWidth
        self.typewriterScrolling = typewriterScrolling
        self.focusMode = focusMode
        self.commandPublisher = commandPublisher
        self.onSplitAtCursor = onSplitAtCursor
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = true
        scrollView.backgroundColor = theme.backgroundNSColor

        let textView = LiteraryNSTextView()
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = true
        textView.isContinuousSpellCheckingEnabled = true
        textView.drawsBackground = true
        textView.backgroundColor = theme.backgroundNSColor
        textView.insertionPointColor = theme.accentNSColor

        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]

        textView.textContainer?.containerSize = NSSize(width: columnWidth, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.lineFragmentPadding = 12

        textView.delegate = context.coordinator
        scrollView.documentView = textView

        context.coordinator.textView = textView
        context.coordinator.scrollView = scrollView
        context.coordinator.subscribeToCommands(commandPublisher)

        textView.string = text
        context.coordinator.updateInsets(for: scrollView.bounds.size)
        context.coordinator.applySyntaxHighlighting()

        return scrollView
    }

    public func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self
        guard let textView = context.coordinator.textView else { return }

        scrollView.backgroundColor = theme.backgroundNSColor
        textView.backgroundColor = theme.backgroundNSColor
        textView.insertionPointColor = theme.accentNSColor

        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            context.coordinator.isProgrammaticUpdate = true
            textView.string = text
            textView.selectedRanges = selectedRanges
            context.coordinator.isProgrammaticUpdate = false
        }

        context.coordinator.updateInsets(for: scrollView.bounds.size)
        context.coordinator.applySyntaxHighlighting()
    }

    // MARK: - Custom NSTextView Subclass for Layout & Shortcuts

    public final class LiteraryNSTextView: NSTextView {
        public var onResizeCallback: ((NSSize) -> Void)?

        public override func setFrameSize(_ newSize: NSSize) {
            super.setFrameSize(newSize)
            onResizeCallback?(newSize)
        }
    }

    // MARK: - Coordinator

    @MainActor
    public final class Coordinator: NSObject, NSTextViewDelegate {
        public var parent: MarkdownTextEditor
        public weak var textView: LiteraryNSTextView?
        public weak var scrollView: NSScrollView?
        public var isProgrammaticUpdate = false
        private var cancellable: AnyCancellable?

        private static let heading1Regex = try! NSRegularExpression(pattern: "^#\\s+.*$", options: [.anchorsMatchLines])
        private static let heading2Regex = try! NSRegularExpression(pattern: "^##\\s+.*$", options: [.anchorsMatchLines])
        private static let heading3Regex = try! NSRegularExpression(pattern: "^###\\s+.*$", options: [.anchorsMatchLines])
        private static let blockquoteRegex = try! NSRegularExpression(pattern: "^>\\s*.*$", options: [.anchorsMatchLines])
        private static let dialogueRegex = try! NSRegularExpression(pattern: "^(—|–|--)\\s*.*$", options: [.anchorsMatchLines])
        private static let boldRegex = try! NSRegularExpression(pattern: "\\*\\*(.+?)\\*\\*", options: [])
        private static let italicRegex = try! NSRegularExpression(pattern: "(?<!\\*)\\*(?!\\*)(.+?)(?<!\\*)\\*(?!\\*)", options: [])
        private static let wikilinkRegex = try! NSRegularExpression(pattern: "\\[\\[([^\\]]+)\\]\\]", options: [])
        private static let commentRegex = try! NSRegularExpression(pattern: "%%.*?%%", options: [.dotMatchesLineSeparators])
        private static let sceneBreakRegex = try! NSRegularExpression(pattern: "^(\\* \\* \\*|\\*\\*\\*|---)$", options: [.anchorsMatchLines])

        public init(_ parent: MarkdownTextEditor) {
            self.parent = parent
            super.init()
        }

        public func subscribeToCommands(_ publisher: PassthroughSubject<BookStore.EditorFormatCommand, Never>) {
            cancellable = publisher.sink { [weak self] command in
                self?.handleCommand(command)
            }
        }

        public func updateInsets(for containerSize: NSSize) {
            guard let textView = textView else { return }
            let horizontalInset = max(36.0, (containerSize.width - parent.columnWidth) / 2.0)
            let verticalInset = parent.typewriterScrolling ? max(160.0, containerSize.height * 0.38) : 44.0
            textView.textContainerInset = NSSize(width: horizontalInset, height: verticalInset)
            textView.onResizeCallback = { [weak self] newSize in
                guard let self = self else { return }
                let hInset = max(36.0, (newSize.width - self.parent.columnWidth) / 2.0)
                let vInset = self.parent.typewriterScrolling ? max(160.0, (self.scrollView?.bounds.height ?? 500) * 0.38) : 44.0
                if abs(textView.textContainerInset.width - hInset) > 2 {
                    textView.textContainerInset = NSSize(width: hInset, height: vInset)
                }
            }
        }

        public func textDidChange(_ notification: Notification) {
            guard !isProgrammaticUpdate, let textView = textView else { return }

            // Replace leading "-- " with literary em-dash "— "
            autoReplaceLiteraryDashIfNeeded(in: textView)

            parent.text = textView.string
            applySyntaxHighlighting()
            if parent.typewriterScrolling {
                centerCursorVertically()
            }
        }

        public func textViewDidChangeSelection(_ notification: Notification) {
            guard !isProgrammaticUpdate else { return }
            if parent.focusMode != .off {
                applySyntaxHighlighting()
            }
            if parent.typewriterScrolling {
                centerCursorVertically()
            }
        }

        private func autoReplaceLiteraryDashIfNeeded(in textView: NSTextView) {
            let cursor = textView.selectedRange().location
            guard cursor >= 3 else { return }
            let nsString = textView.string as NSString
            let checkRange = NSRange(location: cursor - 3, length: 3)
            guard NSMaxRange(checkRange) <= nsString.length else { return }
            if nsString.substring(with: checkRange) == "-- " {
                isProgrammaticUpdate = true
                textView.replaceCharacters(in: checkRange, with: "— ")
                textView.setSelectedRange(NSRange(location: cursor - 1, length: 0))
                isProgrammaticUpdate = false
            }
        }

        public func centerCursorVertically() {
            guard let textView = textView,
                  let scrollView = scrollView,
                  let layoutManager = textView.layoutManager,
                  let textContainer = textView.textContainer else { return }

            let selectedRange = textView.selectedRange()
            let glyphRange = layoutManager.glyphRange(forCharacterRange: selectedRange, actualCharacterRange: nil)
            var rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
            if rect.height == 0 {
                rect.size.height = parent.fontSize * 1.5
            }
            rect.origin.x += textView.textContainerOrigin.x
            rect.origin.y += textView.textContainerOrigin.y

            let visibleHeight = scrollView.contentView.bounds.height
            let targetY = max(0, rect.midY - (visibleHeight / 2.0))
            scrollView.contentView.scroll(to: NSPoint(x: 0, y: targetY))
            scrollView.reflectScrolledClipView(scrollView.contentView)
        }

        public func applySyntaxHighlighting() {
            guard let textView = textView,
                  let storage = textView.textStorage else { return }

            let fullText = textView.string
            let nsString = fullText as NSString
            let fullRange = NSRange(location: 0, length: nsString.length)
            guard fullRange.length > 0 else { return }

            let baseFont = parent.fontStyle.nsFont(size: parent.fontSize)
            let boldFont = parent.fontStyle.nsFont(size: parent.fontSize, weight: .bold)
            let italicFont = parent.fontStyle.nsFont(size: parent.fontSize, italic: true)
            let h1Font = parent.fontStyle.nsFont(size: parent.fontSize * 1.65, weight: .bold)
            let h2Font = parent.fontStyle.nsFont(size: parent.fontSize * 1.35, weight: .bold)
            let h3Font = parent.fontStyle.nsFont(size: parent.fontSize * 1.15, weight: .bold)

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = parent.lineSpacing
            paragraphStyle.paragraphSpacing = parent.fontSize * 0.45

            let isFocusEnabled = parent.focusMode != .off
            let defaultTextColor = isFocusEnabled ? parent.theme.mutedNSColor : parent.theme.textNSColor

            storage.beginEditing()

            storage.setAttributes([
                .font: baseFont,
                .foregroundColor: defaultTextColor,
                .paragraphStyle: paragraphStyle
            ], range: fullRange)

            // Blockquotes (> ...)
            Self.blockquoteRegex.enumerateMatches(in: fullText, options: [], range: fullRange) { match, _, _ in
                guard let range = match?.range else { return }
                storage.addAttribute(.font, value: italicFont, range: range)
                if !isFocusEnabled {
                    storage.addAttribute(.foregroundColor, value: parent.theme.accentNSColor, range: range)
                }
            }

            // Bold (**...**)
            Self.boldRegex.enumerateMatches(in: fullText, options: [], range: fullRange) { match, _, _ in
                guard let range = match?.range else { return }
                storage.addAttribute(.font, value: boldFont, range: range)
            }

            // Italic (*...*)
            Self.italicRegex.enumerateMatches(in: fullText, options: [], range: fullRange) { match, _, _ in
                guard let range = match?.range else { return }
                storage.addAttribute(.font, value: italicFont, range: range)
            }

            // WikiLinks ([[...]])
            Self.wikilinkRegex.enumerateMatches(in: fullText, options: [], range: fullRange) { match, _, _ in
                guard let range = match?.range else { return }
                if !isFocusEnabled {
                    storage.addAttribute(.foregroundColor, value: parent.theme.accentNSColor, range: range)
                    storage.addAttribute(.backgroundColor, value: parent.theme.accentNSColor.withAlphaComponent(0.10), range: range)
                }
            }

            // Comments (%% ... %%)
            Self.commentRegex.enumerateMatches(in: fullText, options: [], range: fullRange) { match, _, _ in
                guard let range = match?.range else { return }
                storage.addAttribute(.font, value: italicFont, range: range)
                storage.addAttribute(.foregroundColor, value: parent.theme.mutedNSColor, range: range)
            }

            // Scene breaks (* * *)
            Self.sceneBreakRegex.enumerateMatches(in: fullText, options: [], range: fullRange) { match, _, _ in
                guard let range = match?.range else { return }
                let centered = NSMutableParagraphStyle()
                centered.alignment = .center
                centered.lineSpacing = parent.lineSpacing
                centered.paragraphSpacing = parent.fontSize * 0.6
                storage.addAttributes([
                    .paragraphStyle: centered,
                    .foregroundColor: parent.theme.accentNSColor,
                    .font: boldFont
                ], range: range)
            }

            // Headings (#, ##, ###)
            Self.heading3Regex.enumerateMatches(in: fullText, options: [], range: fullRange) { match, _, _ in
                guard let range = match?.range else { return }
                storage.addAttribute(.font, value: h3Font, range: range)
                if !isFocusEnabled {
                    storage.addAttribute(.foregroundColor, value: parent.theme.accentNSColor, range: range)
                }
            }
            Self.heading2Regex.enumerateMatches(in: fullText, options: [], range: fullRange) { match, _, _ in
                guard let range = match?.range else { return }
                storage.addAttribute(.font, value: h2Font, range: range)
                if !isFocusEnabled {
                    storage.addAttribute(.foregroundColor, value: parent.theme.accentNSColor, range: range)
                }
            }
            Self.heading1Regex.enumerateMatches(in: fullText, options: [], range: fullRange) { match, _, _ in
                guard let range = match?.range else { return }
                storage.addAttribute(.font, value: h1Font, range: range)
                if !isFocusEnabled {
                    storage.addAttribute(.foregroundColor, value: parent.theme.accentNSColor, range: range)
                }
            }

            // Focus mode active range illumination
            if isFocusEnabled {
                let cursorLocation = min(textView.selectedRange().location, nsString.length)
                let safeProbeRange = NSRange(location: min(cursorLocation, max(0, nsString.length - 1)), length: 0)
                let activeRange: NSRange
                switch parent.focusMode {
                case .paragraph:
                    activeRange = nsString.paragraphRange(for: safeProbeRange)
                case .sentence:
                    var sentenceMatchRange = nsString.paragraphRange(for: safeProbeRange)
                    fullText.enumerateSubstrings(in: fullText.startIndex..<fullText.endIndex, options: [.bySentences, .localized]) { _, subRange, _, stop in
                        let nsSub = NSRange(subRange, in: fullText)
                        if NSLocationInRange(cursorLocation, nsSub) || NSMaxRange(nsSub) == cursorLocation {
                            sentenceMatchRange = nsSub
                            stop = true
                        }
                    }
                    activeRange = sentenceMatchRange
                case .off:
                    activeRange = fullRange
                }
                if activeRange.location != NSNotFound && NSMaxRange(activeRange) <= nsString.length {
                    storage.addAttribute(.foregroundColor, value: parent.theme.textNSColor, range: activeRange)
                }
            }

            storage.endEditing()
            textView.typingAttributes = [
                .font: baseFont,
                .foregroundColor: parent.theme.textNSColor,
                .paragraphStyle: paragraphStyle
            ]
        }

        // MARK: - Formatting Commands Execution

        private func handleCommand(_ command: BookStore.EditorFormatCommand) {
            guard let textView = textView else { return }
            let range = textView.selectedRange()
            let nsString = textView.string as NSString
            let selectedText = range.length > 0 ? nsString.substring(with: range) : ""

            switch command {
            case .bold:
                let replacement = selectedText.isEmpty ? "**texto em negrito**" : "**\(selectedText)**"
                insertReplacement(replacement, in: textView, range: range)
            case .italic:
                let replacement = selectedText.isEmpty ? "*texto em itálico*" : "*\(selectedText)*"
                insertReplacement(replacement, in: textView, range: range)
            case .heading(let level):
                let prefix = String(repeating: "#", count: max(1, min(3, level))) + " "
                let paraRange = nsString.paragraphRange(for: range)
                let currentPara = nsString.substring(with: paraRange)
                let stripped = currentPara.replacingOccurrences(of: "^#{1,3}\\s+", with: "", options: .regularExpression)
                insertReplacement(prefix + stripped, in: textView, range: paraRange)
            case .dialogueDash:
                let paraRange = nsString.paragraphRange(for: range)
                let currentPara = nsString.substring(with: paraRange)
                if currentPara.hasPrefix("— ") {
                    let stripped = String(currentPara.dropFirst(2))
                    insertReplacement(stripped, in: textView, range: paraRange)
                } else {
                    insertReplacement("— " + currentPara, in: textView, range: paraRange)
                }
            case .blockquote:
                let paraRange = nsString.paragraphRange(for: range)
                let currentPara = nsString.substring(with: paraRange)
                insertReplacement("> " + currentPara, in: textView, range: paraRange)
            case .sceneBreak:
                insertReplacement("\n\n* * *\n\n", in: textView, range: range)
            case .wikilink:
                let replacement = selectedText.isEmpty ? "[[Personagem ou Local]]" : "[[\(selectedText)]]"
                insertReplacement(replacement, in: textView, range: range)
            case .comment:
                let replacement = selectedText.isEmpty ? "%% Nota de revisão %%" : "%% \(selectedText) %%"
                insertReplacement(replacement, in: textView, range: range)
            case .splitChapterAtCursor:
                parent.onSplitAtCursor?(range.location)
            }
        }

        private func insertReplacement(_ replacement: String, in textView: NSTextView, range: NSRange) {
            if textView.shouldChangeText(in: range, replacementString: replacement) {
                textView.replaceCharacters(in: range, with: replacement)
                textView.didChangeText()
            }
        }
    }
}
