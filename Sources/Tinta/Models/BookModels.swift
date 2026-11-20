import Foundation
import SwiftUI

/// Typealias for SwiftUI's State property wrapper struct to avoid CommandLineTools macro lookup on macOS 27 SDK.
public typealias ViewState<Value> = SwiftUI.State<Value>

// MARK: - Enums & Metadata Types

public enum ChapterStatus: String, Codable, CaseIterable, Identifiable {
    case idea = "Ideia"
    case draft = "Rascunho"
    case inProgress = "Em Escrita"
    case revision = "Em Revisão"
    case final = "Finalizado"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .idea: return "lightbulb"
        case .draft: return "doc.text"
        case .inProgress: return "pencil.line"
        case .revision: return "magnifyingglass.circle"
        case .final: return "checkmark.seal.fill"
        }
    }

    public var badgeColor: Color {
        switch self {
        case .idea: return .purple
        case .draft: return .secondary
        case .inProgress: return .orange
        case .revision: return .blue
        case .final: return .green
        }
    }
}

public enum ChapterColorLabel: String, Codable, CaseIterable, Identifiable {
    case none = "Nenhum"
    case amber = "Âmbar"
    case crimson = "Carmim"
    case emerald = "Esmeralda"
    case sapphire = "Safira"
    case amethyst = "Ametista"
    case slate = "Ardósia"

    public var id: String { rawValue }

    public var color: Color {
        switch self {
        case .none: return .gray.opacity(0.35)
        case .amber: return Color(red: 0.88, green: 0.58, blue: 0.16)
        case .crimson: return Color(red: 0.80, green: 0.24, blue: 0.28)
        case .emerald: return Color(red: 0.18, green: 0.64, blue: 0.44)
        case .sapphire: return Color(red: 0.20, green: 0.48, blue: 0.82)
        case .amethyst: return Color(red: 0.56, green: 0.34, blue: 0.78)
        case .slate: return Color(red: 0.42, green: 0.49, blue: 0.56)
        }
    }
}

public enum CharacterRole: String, Codable, CaseIterable, Identifiable {
    case protagonist = "Protagonista"
    case antagonist = "Antagonista"
    case deuteragonist = "Deuteragonista"
    case mentor = "Mentor"
    case supporting = "Coadjuvante"
    case other = "Outro"

    public var id: String { rawValue }

    public var color: Color {
        switch self {
        case .protagonist: return .orange
        case .antagonist: return .red
        case .deuteragonist: return .blue
        case .mentor: return .purple
        case .supporting: return .teal
        case .other: return .secondary
        }
    }
}

public enum WorkspaceViewMode: String, CaseIterable, Identifiable {
    case editor = "Editor"
    case splitPreview = "Editor + Prova"
    case corkboard = "Fichas"
    case outline = "Escaleta"
    case bookReader = "Livro"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .editor: return "doc.plaintext"
        case .splitPreview: return "rectangle.split.2x1"
        case .corkboard: return "square.grid.2x2"
        case .outline: return "list.bullet.rectangle"
        case .bookReader: return "book.pages"
        }
    }

    public var tooltip: String {
        switch self {
        case .editor: return "Editor Markdown focado (⌘1)"
        case .splitPreview: return "Editor com Prova Tipográfica ao lado (⌘2)"
        case .corkboard: return "Quadro de Fichas dos capítulos (⌘3)"
        case .outline: return "Escaleta estrutural e gráfico de ritmo (⌘4)"
        case .bookReader: return "Modo Leitura do livro completo (⌘5)"
        }
    }
}

public enum EditorTheme: String, Codable, CaseIterable, Identifiable {
    case parchment = "Pólen Literário"
    case daylight = "Tinta Clara"
    case sepia = "Sépia Clássico"
    case midnight = "Meia-Noite"
    case amberNight = "Noturno Âmbar"
    case obsidian = "Obsidiana OLED"

    public var id: String { rawValue }

    public var isDark: Bool {
        switch self {
        case .parchment, .daylight, .sepia:
            return false
        case .midnight, .amberNight, .obsidian:
            return true
        }
    }

    public static var dayThemes: [EditorTheme] {
        [.parchment, .daylight, .sepia]
    }

    public static var nightThemes: [EditorTheme] {
        [.midnight, .amberNight, .obsidian]
    }

    public var iconName: String {
        switch self {
        case .parchment: return "book.pages"
        case .daylight: return "sun.max.fill"
        case .sepia: return "cup.and.saucer.fill"
        case .midnight: return "moon.stars.fill"
        case .amberNight: return "flame.fill"
        case .obsidian: return "sparkles"
        }
    }

    public var backgroundNSColor: NSColor {
        switch self {
        case .parchment: return NSColor(calibratedRed: 0.980, green: 0.968, blue: 0.935, alpha: 1.0)
        case .daylight: return NSColor(calibratedRed: 0.992, green: 0.992, blue: 0.995, alpha: 1.0)
        case .sepia: return NSColor(calibratedRed: 0.945, green: 0.914, blue: 0.855, alpha: 1.0)
        case .midnight: return NSColor(calibratedRed: 0.105, green: 0.115, blue: 0.138, alpha: 1.0)
        case .amberNight: return NSColor(calibratedRed: 0.098, green: 0.082, blue: 0.070, alpha: 1.0)
        case .obsidian: return NSColor(calibratedRed: 0.058, green: 0.062, blue: 0.072, alpha: 1.0)
        }
    }

    public var cardBackgroundNSColor: NSColor {
        switch self {
        case .parchment: return NSColor(calibratedRed: 0.952, green: 0.936, blue: 0.892, alpha: 1.0)
        case .daylight: return NSColor(calibratedRed: 0.960, green: 0.965, blue: 0.975, alpha: 1.0)
        case .sepia: return NSColor(calibratedRed: 0.912, green: 0.875, blue: 0.805, alpha: 1.0)
        case .midnight: return NSColor(calibratedRed: 0.148, green: 0.162, blue: 0.192, alpha: 1.0)
        case .amberNight: return NSColor(calibratedRed: 0.142, green: 0.118, blue: 0.100, alpha: 1.0)
        case .obsidian: return NSColor(calibratedRed: 0.105, green: 0.112, blue: 0.128, alpha: 1.0)
        }
    }

    public var textNSColor: NSColor {
        switch self {
        case .parchment: return NSColor(calibratedRed: 0.16, green: 0.14, blue: 0.12, alpha: 1.0)
        case .daylight: return NSColor(calibratedRed: 0.12, green: 0.13, blue: 0.15, alpha: 1.0)
        case .sepia: return NSColor(calibratedRed: 0.22, green: 0.17, blue: 0.12, alpha: 1.0)
        case .midnight: return NSColor(calibratedRed: 0.89, green: 0.88, blue: 0.85, alpha: 1.0)
        case .amberNight: return NSColor(calibratedRed: 0.92, green: 0.84, blue: 0.71, alpha: 1.0)
        case .obsidian: return NSColor(calibratedRed: 0.91, green: 0.92, blue: 0.94, alpha: 1.0)
        }
    }

    public var accentNSColor: NSColor {
        switch self {
        case .parchment: return NSColor(calibratedRed: 0.65, green: 0.28, blue: 0.14, alpha: 1.0)
        case .daylight: return NSColor(calibratedRed: 0.16, green: 0.40, blue: 0.68, alpha: 1.0)
        case .sepia: return NSColor(calibratedRed: 0.58, green: 0.26, blue: 0.12, alpha: 1.0)
        case .midnight: return NSColor(calibratedRed: 0.88, green: 0.62, blue: 0.34, alpha: 1.0)
        case .amberNight: return NSColor(calibratedRed: 0.90, green: 0.54, blue: 0.25, alpha: 1.0)
        case .obsidian: return NSColor(calibratedRed: 0.38, green: 0.78, blue: 0.68, alpha: 1.0)
        }
    }

    public var dialogueNSColor: NSColor {
        switch self {
        case .parchment: return NSColor(calibratedRed: 0.20, green: 0.34, blue: 0.28, alpha: 1.0)
        case .daylight: return NSColor(calibratedRed: 0.15, green: 0.38, blue: 0.36, alpha: 1.0)
        case .sepia: return NSColor(calibratedRed: 0.24, green: 0.36, blue: 0.26, alpha: 1.0)
        case .midnight: return NSColor(calibratedRed: 0.58, green: 0.78, blue: 0.68, alpha: 1.0)
        case .amberNight: return NSColor(calibratedRed: 0.82, green: 0.72, blue: 0.52, alpha: 1.0)
        case .obsidian: return NSColor(calibratedRed: 0.56, green: 0.84, blue: 0.78, alpha: 1.0)
        }
    }

    public var mutedNSColor: NSColor {
        switch self {
        case .parchment, .daylight, .sepia:
            return textNSColor.withAlphaComponent(0.32)
        case .midnight, .amberNight, .obsidian:
            return textNSColor.withAlphaComponent(0.28)
        }
    }

    public var backgroundColor: Color { Color(nsColor: backgroundNSColor) }
    public var cardBackgroundColor: Color { Color(nsColor: cardBackgroundNSColor) }
    public var textColor: Color { Color(nsColor: textNSColor) }
    public var accentColor: Color { Color(nsColor: accentNSColor) }
}

public enum EditorFontStyle: String, Codable, CaseIterable, Identifiable {
    case serif = "Georgia Literária"
    case palatino = "Palatino Clássica"
    case sans = "Avenir Moderna"
    case mono = "Menlo Máquina"

    public var id: String { rawValue }

    public var fontName: String {
        switch self {
        case .serif: return "Georgia"
        case .palatino: return "Palatino"
        case .sans: return "Avenir Next"
        case .mono: return "Menlo"
        }
    }

    public func nsFont(size: CGFloat, weight: NSFont.Weight = .regular, italic: Bool = false) -> NSFont {
        let base = NSFont(name: fontName, size: size) ?? NSFont.systemFont(ofSize: size, weight: weight)
        var traits: NSFontTraitMask = []
        if weight == .bold || weight == .semibold || weight == .heavy {
            traits.insert(.boldFontMask)
        }
        if italic {
            traits.insert(.italicFontMask)
        }
        if traits.isEmpty {
            return base
        }
        return NSFontManager.shared.convert(base, toHaveTrait: traits)
    }
}

public enum FocusHighlightMode: String, Codable, CaseIterable, Identifiable {
    case off = "Desativado"
    case sentence = "Frase Atual"
    case paragraph = "Parágrafo Atual"

    public var id: String { rawValue }
}

public enum BinderSelection: Hashable {
    case manuscriptOverview
    case partOverview(UUID)
    case chapter(UUID)
    case character(UUID)
    case location(UUID)
    case researchNote(UUID)
    case trash
}

// MARK: - Core Book Entities

public struct BookPart: Codable, Identifiable, Hashable {
    public var id: UUID
    public var title: String
    public var subtitle: String
    public var synopsis: String
    public var order: Int

    public init(
        id: UUID = UUID(),
        title: String,
        subtitle: String = "",
        synopsis: String = "",
        order: Int = 0
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.synopsis = synopsis
        self.order = order
    }
}

public struct ChapterSnapshot: Codable, Identifiable, Hashable {
    public var id: UUID
    public var label: String
    public var createdAt: Date
    public var content: String
    public var wordCount: Int

    public init(
        id: UUID = UUID(),
        label: String,
        createdAt: Date = Date(),
        content: String,
        wordCount: Int
    ) {
        self.id = id
        self.label = label
        self.createdAt = createdAt
        self.content = content
        self.wordCount = wordCount
    }
}

public struct ChapterItem: Codable, Identifiable, Hashable {
    public var id: UUID
    public var partId: UUID?
    public var order: Int
    public var title: String
    public var subtitle: String
    public var synopsis: String
    public var notes: String
    public var content: String
    public var status: ChapterStatus
    public var colorLabel: ChapterColorLabel
    public var povCharacterId: UUID?
    public var locationId: UUID?
    public var targetWordCount: Int
    public var includeInCompile: Bool
    public var isTrashed: Bool
    public var tags: [String]
    public var snapshots: [ChapterSnapshot]
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        partId: UUID? = nil,
        order: Int = 0,
        title: String,
        subtitle: String = "",
        synopsis: String = "",
        notes: String = "",
        content: String = "",
        status: ChapterStatus = .draft,
        colorLabel: ChapterColorLabel = .none,
        povCharacterId: UUID? = nil,
        locationId: UUID? = nil,
        targetWordCount: Int = 2500,
        includeInCompile: Bool = true,
        isTrashed: Bool = false,
        tags: [String] = [],
        snapshots: [ChapterSnapshot] = [],
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.partId = partId
        self.order = order
        self.title = title
        self.subtitle = subtitle
        self.synopsis = synopsis
        self.notes = notes
        self.content = content
        self.status = status
        self.colorLabel = colorLabel
        self.povCharacterId = povCharacterId
        self.locationId = locationId
        self.targetWordCount = targetWordCount
        self.includeInCompile = includeInCompile
        self.isTrashed = isTrashed
        self.tags = tags
        self.snapshots = snapshots
        self.updatedAt = updatedAt
    }

    public var wordCount: Int {
        TextAnalytics.countWords(in: content)
    }

    public var characterCount: Int {
        content.count
    }

    public var progressRatio: Double {
        guard targetWordCount > 0 else { return 0 }
        return min(1.0, Double(wordCount) / Double(targetWordCount))
    }
}

public struct CharacterProfile: Codable, Identifiable, Hashable {
    public var id: UUID
    public var name: String
    public var role: CharacterRole
    public var age: String
    public var archetype: String
    public var summary: String
    public var physicalDescription: String
    public var motivation: String
    public var internalConflict: String
    public var arcNotes: String

    public init(
        id: UUID = UUID(),
        name: String,
        role: CharacterRole = .protagonist,
        age: String = "",
        archetype: String = "",
        summary: String = "",
        physicalDescription: String = "",
        motivation: String = "",
        internalConflict: String = "",
        arcNotes: String = ""
    ) {
        self.id = id
        self.name = name
        self.role = role
        self.age = age
        self.archetype = archetype
        self.summary = summary
        self.physicalDescription = physicalDescription
        self.motivation = motivation
        self.internalConflict = internalConflict
        self.arcNotes = arcNotes
    }
}

public struct LocationProfile: Codable, Identifiable, Hashable {
    public var id: UUID
    public var name: String
    public var region: String
    public var atmosphere: String
    public var sensoryDetails: String
    public var description: String
    public var notes: String

    public init(
        id: UUID = UUID(),
        name: String,
        region: String = "",
        atmosphere: String = "",
        sensoryDetails: String = "",
        description: String = "",
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.region = region
        self.atmosphere = atmosphere
        self.sensoryDetails = sensoryDetails
        self.description = description
        self.notes = notes
    }
}

public struct ResearchNote: Codable, Identifiable, Hashable {
    public var id: UUID
    public var title: String
    public var category: String
    public var content: String
    public var tags: [String]
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        category: String = "Mundo & Lore",
        content: String = "",
        tags: [String] = [],
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.content = content
        self.tags = tags
        self.updatedAt = updatedAt
    }
}

public struct DailyWritingEntry: Codable, Identifiable, Hashable {
    public var id: String { dateString }
    public var dateString: String
    public var wordsWritten: Int
    public var minutesActive: Int

    public init(dateString: String, wordsWritten: Int, minutesActive: Int = 0) {
        self.dateString = dateString
        self.wordsWritten = wordsWritten
        self.minutesActive = minutesActive
    }
}

public struct BookProject: Codable, Identifiable, Hashable {
    public var id: UUID
    public var title: String
    public var subtitle: String
    public var author: String
    public var genre: String
    public var epigraph: String
    public var epigraphAuthor: String
    public var synopsis: String
    public var targetWordCount: Int
    public var dailyWordGoal: Int
    public var createdAt: Date
    public var updatedAt: Date
    public var parts: [BookPart]
    public var chapters: [ChapterItem]
    public var characters: [CharacterProfile]
    public var locations: [LocationProfile]
    public var researchNotes: [ResearchNote]
    public var writingLog: [DailyWritingEntry]

    public init(
        id: UUID = UUID(),
        title: String,
        subtitle: String = "",
        author: String = "Autor",
        genre: String = "Ficção Literária",
        epigraph: String = "",
        epigraphAuthor: String = "",
        synopsis: String = "",
        targetWordCount: Int = 60000,
        dailyWordGoal: Int = 1000,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        parts: [BookPart] = [],
        chapters: [ChapterItem] = [],
        characters: [CharacterProfile] = [],
        locations: [LocationProfile] = [],
        researchNotes: [ResearchNote] = [],
        writingLog: [DailyWritingEntry] = []
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.author = author
        self.genre = genre
        self.epigraph = epigraph
        self.epigraphAuthor = epigraphAuthor
        self.synopsis = synopsis
        self.targetWordCount = targetWordCount
        self.dailyWordGoal = dailyWordGoal
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.parts = parts
        self.chapters = chapters
        self.characters = characters
        self.locations = locations
        self.researchNotes = researchNotes
        self.writingLog = writingLog
    }

    public var activeChapters: [ChapterItem] {
        chapters
            .filter { !$0.isTrashed }
            .sorted { $0.order < $1.order }
    }

    public var trashedChapters: [ChapterItem] {
        chapters
            .filter { $0.isTrashed }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    public var sortedParts: [BookPart] {
        parts.sorted { $0.order < $1.order }
    }

    public func chapters(in partId: UUID?) -> [ChapterItem] {
        activeChapters.filter { $0.partId == partId }
    }

    public var totalWordCount: Int {
        activeChapters
            .filter { $0.includeInCompile }
            .reduce(0) { $0 + $1.wordCount }
    }

    public var totalCharacterCount: Int {
        activeChapters
            .filter { $0.includeInCompile }
            .reduce(0) { $0 + $1.characterCount }
    }

    public var bookProgressRatio: Double {
        guard targetWordCount > 0 else { return 0 }
        return min(1.0, Double(totalWordCount) / Double(targetWordCount))
    }

    public var estimatedPagesCount: Int {
        max(1, Int(ceil(Double(totalWordCount) / 250.0)))
    }

    public var estimatedReadingMinutes: Int {
        max(1, Int(ceil(Double(totalWordCount) / 220.0)))
    }
}
