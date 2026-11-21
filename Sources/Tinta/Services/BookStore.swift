import AppKit
import Combine
import Foundation
import SwiftUI

@MainActor
public final class BookStore: ObservableObject {
    // MARK: - Library & Active Selection
    @Published public var books: [BookProject] = []
    @Published public var currentBookId: UUID = UUID()
    @Published public var selection: BinderSelection? = nil
    @Published public var viewMode: WorkspaceViewMode = .editor
    @Published public var binderSearchText: String = ""

    // MARK: - Layout & Modes
    @Published public var showInspector: Bool = true
    @Published public var isZenMode: Bool = false
    @Published public var showBookSettingsSheet: Bool = false
    @Published public var showExportSheet: Bool = false
    @Published public var showQuickOpenSheet: Bool = false
    @Published public var showNewBookSheet: Bool = false
    @Published public var showPartEditorSheet: Bool = false
    @Published public var editingPartId: UUID? = nil
    @Published public var statusBannerMessage: String? = nil

    // MARK: - Editor Typography & Appearance Preferences
    @Published public var theme: EditorTheme = .parchment {
        didSet {
            if theme.isDark {
                preferredNightTheme = theme
            } else {
                preferredDayTheme = theme
            }
            UserDefaults.standard.set(theme.rawValue, forKey: "Tinta.activeTheme")
            UserDefaults.standard.set(preferredDayTheme.rawValue, forKey: "Tinta.preferredDayTheme")
            UserDefaults.standard.set(preferredNightTheme.rawValue, forKey: "Tinta.preferredNightTheme")
            applyWindowAppearance()
        }
    }
    @Published public var preferredDayTheme: EditorTheme = .parchment
    @Published public var preferredNightTheme: EditorTheme = .midnight
    @Published public var fontStyle: EditorFontStyle = .serif
    @Published public var fontSize: CGFloat = 17.0
    @Published public var lineSpacing: CGFloat = 7.0
    @Published public var editorColumnWidth: CGFloat = 680.0
    @Published public var typewriterScrolling: Bool = false
    @Published public var focusMode: FocusHighlightMode = .off

    public var isNightMode: Bool {
        theme.isDark
    }

    // MARK: - Writing Sprint / Pomodoro Timer
    @Published public var isSprintActive: Bool = false
    @Published public var sprintSecondsRemaining: Int = 25 * 60
    @Published public var sprintDurationMinutes: Int = 25
    @Published public var sprintBaselineWords: Int = 0

    // MARK: - Editor Action Commands (forwarded to active NSTextView)
    public let editorCommandSubject = PassthroughSubject<EditorFormatCommand, Never>()

    private var sprintTimer: Timer?
    private let storageDirectoryURL: URL
    private var isLoaded = false
    private var initialBookWordCountOnLaunch: Int = 0

    public enum EditorFormatCommand {
        case bold
        case italic
        case heading(Int)
        case dialogueDash
        case blockquote
        case sceneBreak
        case wikilink
        case comment
        case splitChapterAtCursor
    }

    public init(customStorageDirectory: URL? = nil) {
        if let custom = customStorageDirectory {
            self.storageDirectoryURL = custom
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            self.storageDirectoryURL = appSupport.appendingPathComponent("Tinta", isDirectory: true)
        }
        if let savedDay = UserDefaults.standard.string(forKey: "Tinta.preferredDayTheme"),
           let dayTheme = EditorTheme(rawValue: savedDay), !dayTheme.isDark {
            self.preferredDayTheme = dayTheme
        }
        if let savedNight = UserDefaults.standard.string(forKey: "Tinta.preferredNightTheme"),
           let nightTheme = EditorTheme(rawValue: savedNight), nightTheme.isDark {
            self.preferredNightTheme = nightTheme
        }
        if let savedActive = UserDefaults.standard.string(forKey: "Tinta.activeTheme"),
           let activeTheme = EditorTheme(rawValue: savedActive) {
            self.theme = activeTheme
        }
        loadLibrary()
        applyWindowAppearance()
    }

    // MARK: - Computed Properties for Active Book

    public var currentBookIndex: Int? {
        books.firstIndex(where: { $0.id == currentBookId })
    }

    public var currentBook: BookProject {
        get {
            if let idx = currentBookIndex {
                return books[idx]
            }
            return books.first ?? SampleBookFactory.makeSampleBook()
        }
        set {
            if let idx = currentBookIndex {
                var updated = newValue
                updated.updatedAt = Date()
                books[idx] = updated
                updateDailyWritingLogIfNeeded(for: updated)
                saveLibrary()
            }
        }
    }

    public var selectedChapterId: UUID? {
        if case .chapter(let id) = selection {
            return id
        }
        return nil
    }

    public var selectedChapter: ChapterItem? {
        guard let id = selectedChapterId else { return nil }
        return currentBook.chapters.first(where: { $0.id == id })
    }

    public var todayWordsWritten: Int {
        let key = Self.dateString(for: Date())
        return currentBook.writingLog.first(where: { $0.dateString == key })?.wordsWritten ?? 0
    }

    public var sprintWordsWritten: Int {
        max(0, currentBook.totalWordCount - sprintBaselineWords)
    }

    // MARK: - Persistence

    public func loadLibrary() {
        let fm = FileManager.default
        try? fm.createDirectory(at: storageDirectoryURL, withIntermediateDirectories: true)
        let libraryFile = storageDirectoryURL.appendingPathComponent("library.tinta.json")

        if fm.fileExists(atPath: libraryFile.path),
           let data = try? Data(contentsOf: libraryFile) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            if let loaded = try? decoder.decode([BookProject].self, from: data), !loaded.isEmpty {
                self.books = loaded
                self.currentBookId = loaded[0].id
                if let firstChapter = loaded[0].activeChapters.first {
                    self.selection = .chapter(firstChapter.id)
                } else {
                    self.selection = .manuscriptOverview
                }
                self.initialBookWordCountOnLaunch = loaded[0].totalWordCount
                self.isLoaded = true
                return
            }
        }

        // First launch: create sample book
        let sample = SampleBookFactory.makeSampleBook()
        self.books = [sample]
        self.currentBookId = sample.id
        if let firstChap = sample.activeChapters.first {
            self.selection = .chapter(firstChap.id)
        } else {
            self.selection = .manuscriptOverview
        }
        self.initialBookWordCountOnLaunch = sample.totalWordCount
        self.isLoaded = true
        saveLibrary()
    }

    public func saveLibrary() {
        guard isLoaded else { return }
        let libraryFile = storageDirectoryURL.appendingPathComponent("library.tinta.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(books) {
            try? data.write(to: libraryFile, options: .atomic)
        }
    }

    private func updateDailyWritingLogIfNeeded(for book: BookProject) {
        guard let bIdx = books.firstIndex(where: { $0.id == book.id }) else { return }
        let key = Self.dateString(for: Date())
        let delta = max(0, book.totalWordCount - initialBookWordCountOnLaunch)
        if let logIdx = books[bIdx].writingLog.firstIndex(where: { $0.dateString == key }) {
            let currentLogged = books[bIdx].writingLog[logIdx].wordsWritten
            if delta > 0 {
                books[bIdx].writingLog[logIdx].wordsWritten = max(currentLogged, delta)
            }
        } else {
            books[bIdx].writingLog.append(DailyWritingEntry(dateString: key, wordsWritten: max(10, delta), minutesActive: 1))
        }
    }

    // MARK: - Book Management

    public func selectBook(_ id: UUID) {
        guard books.contains(where: { $0.id == id }) else { return }
        currentBookId = id
        initialBookWordCountOnLaunch = currentBook.totalWordCount
        if let firstChap = currentBook.activeChapters.first {
            selection = .chapter(firstChap.id)
        } else {
            selection = .manuscriptOverview
        }
    }

    public func createNewBook(title: String, subtitle: String, author: String, genre: String, targetWords: Int, dailyGoal: Int) {
        let part1 = BookPart(title: "Ato I — Início", subtitle: "Apresentação do mundo", order: 0)
        let firstChapter = ChapterItem(
            partId: part1.id,
            order: 0,
            title: "Capítulo 1",
            subtitle: "",
            synopsis: "Cena de abertura do livro.",
            content: "# Capítulo 1\n\nComece a escrever sua história aqui...\n",
            status: .inProgress,
            colorLabel: .amber,
            targetWordCount: 2500
        )
        let newBook = BookProject(
            title: title.isEmpty ? "Novo Livro Sem Título" : title,
            subtitle: subtitle,
            author: author.isEmpty ? "Autor" : author,
            genre: genre.isEmpty ? "Romance" : genre,
            targetWordCount: max(1000, targetWords),
            dailyWordGoal: max(100, dailyGoal),
            parts: [part1],
            chapters: [firstChapter]
        )
        books.append(newBook)
        currentBookId = newBook.id
        selection = .chapter(firstChapter.id)
        initialBookWordCountOnLaunch = newBook.totalWordCount
        saveLibrary()
        showToast("Livro “\(newBook.title)” criado")
    }

    public func deleteBook(_ id: UUID) {
        guard books.count > 1 else {
            showToast("Mantenha ao menos um livro na biblioteca")
            return
        }
        books.removeAll { $0.id == id }
        if currentBookId == id, let first = books.first {
            selectBook(first.id)
        }
        saveLibrary()
    }

    // MARK: - Parts (Acts) Operations

    public func presentNewPartSheet() {
        editingPartId = nil
        showPartEditorSheet = true
    }

    public func presentEditPartSheet(id: UUID) {
        editingPartId = id
        showPartEditorSheet = true
    }

    @discardableResult
    public func addPart(title: String = "Novo Ato / Parte", subtitle: String = "", synopsis: String = "") -> BookPart {
        var book = currentBook
        let nextOrder = (book.parts.map(\.order).max() ?? -1) + 1
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = trimmedTitle.isEmpty ? "Ato \(book.parts.count + 1)" : trimmedTitle
        let newPart = BookPart(title: finalTitle, subtitle: subtitle, synopsis: synopsis, order: nextOrder)
        book.parts.append(newPart)
        currentBook = book
        selection = .partOverview(newPart.id)
        showToast("Ato criado: \(finalTitle)")
        return newPart
    }

    public func updatePart(_ part: BookPart) {
        var book = currentBook
        if let idx = book.parts.firstIndex(where: { $0.id == part.id }) {
            book.parts[idx] = part
            currentBook = book
            showToast("Ato atualizado: \(part.title)")
        }
    }

    public func movePart(_ id: UUID, direction: Int) {
        var book = currentBook
        let sorted = book.sortedParts
        guard let currentIdx = sorted.firstIndex(where: { $0.id == id }) else { return }
        let targetIdx = currentIdx + direction
        guard targetIdx >= 0 && targetIdx < sorted.count else { return }

        let currentPart = sorted[currentIdx]
        let neighborPart = sorted[targetIdx]

        if let p1 = book.parts.firstIndex(where: { $0.id == currentPart.id }),
           let p2 = book.parts.firstIndex(where: { $0.id == neighborPart.id }) {
            let tempOrder = book.parts[p1].order
            book.parts[p1].order = book.parts[p2].order
            book.parts[p2].order = tempOrder
            currentBook = book
        }
    }

    public func deletePart(_ partId: UUID) {
        var book = currentBook
        let fallbackPartId = book.sortedParts.first(where: { $0.id != partId })?.id
        for idx in book.chapters.indices where book.chapters[idx].partId == partId {
            book.chapters[idx].partId = fallbackPartId
        }
        book.parts.removeAll { $0.id == partId }
        currentBook = book
        selection = .manuscriptOverview
    }

    // MARK: - Chapter Operations

    @discardableResult
    public func addChapter(in partId: UUID? = nil, title: String = "Novo Capítulo") -> ChapterItem {
        var book = currentBook
        let targetPartId = partId ?? selectedChapter?.partId ?? book.sortedParts.first?.id
        let nextOrder = (book.chapters.map(\.order).max() ?? -1) + 1
        let chapterNumber = book.activeChapters.count + 1
        let finalTitle = title == "Novo Capítulo" ? "Capítulo \(chapterNumber)" : title
        let newChapter = ChapterItem(
            partId: targetPartId,
            order: nextOrder,
            title: finalTitle,
            subtitle: "",
            synopsis: "",
            content: "# \(finalTitle)\n\n",
            status: .draft,
            colorLabel: .none,
            targetWordCount: 2500
        )
        book.chapters.append(newChapter)
        currentBook = book
        selection = .chapter(newChapter.id)
        showToast("Criado: \(finalTitle)")
        return newChapter
    }

    public func updateChapter(_ updated: ChapterItem) {
        var book = currentBook
        if let idx = book.chapters.firstIndex(where: { $0.id == updated.id }) {
            var copy = updated
            copy.updatedAt = Date()
            book.chapters[idx] = copy
            currentBook = book
        }
    }

    public func updateChapterContent(id: UUID, newContent: String) {
        var book = currentBook
        if let idx = book.chapters.firstIndex(where: { $0.id == id }) {
            guard book.chapters[idx].content != newContent else { return }
            book.chapters[idx].content = newContent
            book.chapters[idx].updatedAt = Date()
            currentBook = book
        }
    }

    public func duplicateChapter(_ id: UUID) {
        var book = currentBook
        guard let original = book.chapters.first(where: { $0.id == id }) else { return }
        var copy = original
        copy.id = UUID()
        copy.title = "\(original.title) (Cópia)"
        copy.order = original.order + 1
        copy.updatedAt = Date()

        for idx in book.chapters.indices where book.chapters[idx].order > original.order {
            book.chapters[idx].order += 1
        }
        book.chapters.append(copy)
        currentBook = book
        selection = .chapter(copy.id)
        showToast("Capítulo duplicado")
    }

    public func moveChapter(_ id: UUID, direction: Int) {
        var book = currentBook
        let active = book.activeChapters
        guard let currentIdx = active.firstIndex(where: { $0.id == id }) else { return }
        let targetIdx = currentIdx + direction
        guard targetIdx >= 0 && targetIdx < active.count else { return }

        let currentChap = active[currentIdx]
        let neighborChap = active[targetIdx]

        if let c1 = book.chapters.firstIndex(where: { $0.id == currentChap.id }),
           let c2 = book.chapters.firstIndex(where: { $0.id == neighborChap.id }) {
            let tempOrder = book.chapters[c1].order
            book.chapters[c1].order = book.chapters[c2].order
            book.chapters[c2].order = tempOrder
            currentBook = book
        }
    }

    public func splitChapter(id: UUID, atUTF16Offset offset: Int) {
        var book = currentBook
        guard let idx = book.chapters.firstIndex(where: { $0.id == id }) else { return }
        let original = book.chapters[idx]
        let nsText = original.content as NSString
        guard offset > 0 && offset < nsText.length else {
            showToast("Posicione o cursor no meio do texto para dividir o capítulo")
            return
        }

        let firstHalf = nsText.substring(to: offset).trimmingCharacters(in: .whitespacesAndNewlines)
        let secondHalf = nsText.substring(from: offset).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !secondHalf.isEmpty else { return }

        book.chapters[idx].content = firstHalf
        book.chapters[idx].updatedAt = Date()

        let newTitle = "\(original.title) (Parte 2)"
        for i in book.chapters.indices where book.chapters[i].order > original.order {
            book.chapters[i].order += 1
        }

        let splitChap = ChapterItem(
            partId: original.partId,
            order: original.order + 1,
            title: newTitle,
            subtitle: original.subtitle,
            synopsis: "Continuação dividida de \(original.title)",
            content: secondHalf.hasPrefix("#") ? secondHalf : "# \(newTitle)\n\n\(secondHalf)",
            status: original.status,
            colorLabel: original.colorLabel,
            povCharacterId: original.povCharacterId,
            locationId: original.locationId,
            targetWordCount: original.targetWordCount
        )
        book.chapters.append(splitChap)
        currentBook = book
        selection = .chapter(splitChap.id)
        showToast("Capítulo dividido em dois")
    }

    public func trashChapter(_ id: UUID) {
        var book = currentBook
        if let idx = book.chapters.firstIndex(where: { $0.id == id }) {
            book.chapters[idx].isTrashed = true
            book.chapters[idx].updatedAt = Date()
            currentBook = book
            if let next = book.activeChapters.first {
                selection = .chapter(next.id)
            } else {
                selection = .manuscriptOverview
            }
            showToast("Capítulo movido para a Lixeira")
        }
    }

    public func restoreChapter(_ id: UUID) {
        var book = currentBook
        if let idx = book.chapters.firstIndex(where: { $0.id == id }) {
            book.chapters[idx].isTrashed = false
            book.chapters[idx].updatedAt = Date()
            currentBook = book
            selection = .chapter(id)
            showToast("Capítulo restaurado")
        }
    }

    public func permanentlyDeleteChapter(_ id: UUID) {
        var book = currentBook
        book.chapters.removeAll { $0.id == id }
        currentBook = book
    }

    // MARK: - Snapshots (Version Control for Writers)

    public func createSnapshot(for chapterId: UUID, label: String = "") {
        var book = currentBook
        guard let idx = book.chapters.firstIndex(where: { $0.id == chapterId }) else { return }
        let chap = book.chapters[idx]
        let finalLabel = label.trimmingCharacters(in: .whitespaces).isEmpty
            ? "Instantâneo (\(chap.wordCount) palavras)"
            : label
        let snap = ChapterSnapshot(
            label: finalLabel,
            content: chap.content,
            wordCount: chap.wordCount
        )
        book.chapters[idx].snapshots.insert(snap, at: 0)
        currentBook = book
        showToast("Instantâneo salvo")
    }

    public func restoreSnapshot(_ snapshot: ChapterSnapshot, for chapterId: UUID) {
        var book = currentBook
        guard let idx = book.chapters.firstIndex(where: { $0.id == chapterId }) else { return }
        // Save automatic backup before restoring
        let current = book.chapters[idx]
        let backup = ChapterSnapshot(
            label: "Antes de restaurar (\(current.wordCount) pal.)",
            content: current.content,
            wordCount: current.wordCount
        )
        book.chapters[idx].snapshots.insert(backup, at: 0)
        book.chapters[idx].content = snapshot.content
        book.chapters[idx].updatedAt = Date()
        currentBook = book
        showToast("Versão restaurada com backup automático")
    }

    // MARK: - Story Bible Operations (Characters, Locations, Research)

    public func addCharacter() {
        var book = currentBook
        let char = CharacterProfile(
            name: "Novo Personagem",
            role: .supporting,
            age: "",
            archetype: "",
            summary: "Breve descrição do papel na história."
        )
        book.characters.append(char)
        currentBook = book
        selection = .character(char.id)
    }

    public func updateCharacter(_ character: CharacterProfile) {
        var book = currentBook
        if let idx = book.characters.firstIndex(where: { $0.id == character.id }) {
            book.characters[idx] = character
            currentBook = book
        }
    }

    public func deleteCharacter(_ id: UUID) {
        var book = currentBook
        book.characters.removeAll { $0.id == id }
        for idx in book.chapters.indices where book.chapters[idx].povCharacterId == id {
            book.chapters[idx].povCharacterId = nil
        }
        currentBook = book
        selection = .manuscriptOverview
    }

    public func addLocation() {
        var book = currentBook
        let loc = LocationProfile(
            name: "Novo Cenário",
            region: "",
            atmosphere: "",
            sensoryDetails: ""
        )
        book.locations.append(loc)
        currentBook = book
        selection = .location(loc.id)
    }

    public func updateLocation(_ location: LocationProfile) {
        var book = currentBook
        if let idx = book.locations.firstIndex(where: { $0.id == location.id }) {
            book.locations[idx] = location
            currentBook = book
        }
    }

    public func deleteLocation(_ id: UUID) {
        var book = currentBook
        book.locations.removeAll { $0.id == id }
        for idx in book.chapters.indices where book.chapters[idx].locationId == id {
            book.chapters[idx].locationId = nil
        }
        currentBook = book
        selection = .manuscriptOverview
    }

    public func addResearchNote() {
        var book = currentBook
        let note = ResearchNote(
            title: "Nova Nota de Pesquisa",
            category: "Pesquisa & Mundo",
            content: "# Nova Nota de Pesquisa\n\nAnote referências, regras do mundo, cronologia ou fragmentos de ideias aqui.\n"
        )
        book.researchNotes.append(note)
        currentBook = book
        selection = .researchNote(note.id)
    }

    public func updateResearchNote(_ note: ResearchNote) {
        var book = currentBook
        if let idx = book.researchNotes.firstIndex(where: { $0.id == note.id }) {
            var copy = note
            copy.updatedAt = Date()
            book.researchNotes[idx] = copy
            currentBook = book
        }
    }

    public func deleteResearchNote(_ id: UUID) {
        var book = currentBook
        book.researchNotes.removeAll { $0.id == id }
        currentBook = book
        selection = .manuscriptOverview
    }

    // MARK: - Import Markdown File as Chapter

    public func importMarkdownFilePanel() {
        let panel = NSOpenPanel()
        panel.title = "Importar Arquivo Markdown como Capítulo"
        panel.allowedContentTypes = [.plainText]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false

        if panel.runModal() == .OK {
            for url in panel.urls {
                if let text = try? String(contentsOf: url, encoding: .utf8) {
                    let baseName = url.deletingPathExtension().lastPathComponent
                    var chap = addChapter(title: baseName)
                    chap.content = text
                    updateChapter(chap)
                }
            }
            showToast("Arquivo(s) Markdown importado(s)")
        }
    }

    // MARK: - Writing Sprint Timer

    public func toggleSprint() {
        if isSprintActive {
            stopSprint()
        } else {
            startSprint()
        }
    }

    public func startSprint() {
        sprintTimer?.invalidate()
        sprintBaselineWords = currentBook.totalWordCount
        sprintSecondsRemaining = sprintDurationMinutes * 60
        isSprintActive = true
        showToast("Sprint de escrita iniciado (\(sprintDurationMinutes) min)")

        sprintTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, self.isSprintActive else { return }
                if self.sprintSecondsRemaining > 0 {
                    self.sprintSecondsRemaining -= 1
                } else {
                    self.stopSprint(completed: true)
                }
            }
        }
    }

    public func stopSprint(completed: Bool = false) {
        sprintTimer?.invalidate()
        sprintTimer = nil
        isSprintActive = false
        if completed {
            NSSound.beep()
            showToast("Sprint concluído! +\(sprintWordsWritten) palavras escritas.")
        }
    }

    // MARK: - Night Mode & Appearance Management

    public func toggleNightMode() {
        withAnimation(.easeInOut(duration: 0.25)) {
            if theme.isDark {
                theme = preferredDayTheme
                showToast("Modo Diurno ativado (\(theme.rawValue))")
            } else {
                theme = preferredNightTheme
                showToast("Modo Noturno ativado (\(theme.rawValue))")
            }
        }
    }

    public func applyWindowAppearance() {
        let targetAppearance = NSAppearance(named: theme.isDark ? .darkAqua : .aqua)
        NSApplication.shared.appearance = targetAppearance
    }

    // MARK: - Helpers

    public func showToast(_ message: String) {
        statusBannerMessage = message
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_600_000_000)
            if self.statusBannerMessage == message {
                withAnimation {
                    self.statusBannerMessage = nil
                }
            }
        }
    }

    nonisolated public static func dateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
