import SwiftUI

// MARK: - Character Profile Editor

public struct CharacterEditorView: View {
    @EnvironmentObject private var store: BookStore
    public let characterId: UUID

    public init(characterId: UUID) {
        self.characterId = characterId
    }

    private var character: CharacterProfile? {
        store.currentBook.characters.first(where: { $0.id == characterId })
    }

    private var chaptersFeaturingCharacter: [ChapterItem] {
        guard let char = character else { return [] }
        return store.currentBook.activeChapters.filter { chap in
            chap.povCharacterId == char.id ||
            chap.content.localizedCaseInsensitiveContains(char.name)
        }
    }

    public var body: some View {
        if let char = character {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    // Header Banner
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(char.role.color.opacity(0.18))
                                .frame(width: 56, height: 56)
                            Text(String(char.name.prefix(1)).uppercased())
                                .font(.system(size: 24, weight: .bold, design: .serif))
                                .foregroundStyle(char.role.color)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            TextField("Nome do Personagem", text: Binding(
                                get: { char.name },
                                set: { val in
                                    var copy = char
                                    copy.name = val
                                    store.updateCharacter(copy)
                                }
                            ))
                            .textFieldStyle(.plain)
                            .font(.system(size: 24, weight: .bold, design: .serif))

                            HStack(spacing: 12) {
                                Picker("Papel", selection: Binding(
                                    get: { char.role },
                                    set: { val in
                                        var copy = char
                                        copy.role = val
                                        store.updateCharacter(copy)
                                    }
                                )) {
                                    ForEach(CharacterRole.allCases) { r in
                                        Text(r.rawValue).tag(r)
                                    }
                                }
                                .frame(width: 175)

                                TextField("Idade (ex: 34 anos)", text: Binding(
                                    get: { char.age },
                                    set: { val in
                                        var copy = char
                                        copy.age = val
                                        store.updateCharacter(copy)
                                    }
                                ))
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 140)

                                TextField("Arquétipo (ex: A Arquivista Relutante)", text: Binding(
                                    get: { char.archetype },
                                    set: { val in
                                        var copy = char
                                        copy.archetype = val
                                        store.updateCharacter(copy)
                                    }
                                ))
                                .textFieldStyle(.roundedBorder)
                            }
                        }

                        Spacer()

                        Button(role: .destructive) {
                            store.deleteCharacter(char.id)
                        } label: {
                            Label("Excluir", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(store.theme.cardBackgroundColor)
                    )

                    // Character Psychological & Narrative Fields
                    HStack(alignment: .top, spacing: 18) {
                        VStack(alignment: .leading, spacing: 16) {
                            bibleFieldBox(
                                title: "Resumo & Essência",
                                icon: "sparkles",
                                text: Binding(
                                    get: { char.summary },
                                    set: { val in
                                        var copy = char
                                        copy.summary = val
                                        store.updateCharacter(copy)
                                    }
                                ),
                                height: 85
                            )

                            bibleFieldBox(
                                title: "Descrição Física & Maneirismos",
                                icon: "person.text.rectangle",
                                text: Binding(
                                    get: { char.physicalDescription },
                                    set: { val in
                                        var copy = char
                                        copy.physicalDescription = val
                                        store.updateCharacter(copy)
                                    }
                                ),
                                height: 105
                            )

                            bibleFieldBox(
                                title: "Arco Narrativo & Transformação",
                                icon: "point.topleft.down.curvedto.point.bottomright.up",
                                text: Binding(
                                    get: { char.arcNotes },
                                    set: { val in
                                        var copy = char
                                        copy.arcNotes = val
                                        store.updateCharacter(copy)
                                    }
                                ),
                                height: 110
                            )
                        }

                        VStack(alignment: .leading, spacing: 16) {
                            bibleFieldBox(
                                title: "Desejo & Motivação Externa",
                                icon: "flame",
                                text: Binding(
                                    get: { char.motivation },
                                    set: { val in
                                        var copy = char
                                        copy.motivation = val
                                        store.updateCharacter(copy)
                                    }
                                ),
                                height: 95
                            )

                            bibleFieldBox(
                                title: "Medo, Ferida & Conflito Interno",
                                icon: "bolt.heart",
                                text: Binding(
                                    get: { char.internalConflict },
                                    set: { val in
                                        var copy = char
                                        copy.internalConflict = val
                                        store.updateCharacter(copy)
                                    }
                                ),
                                height: 95
                            )

                            // Appearances in Manuscript
                            VStack(alignment: .leading, spacing: 10) {
                                Label("Capítulos com \(char.name) (\(chaptersFeaturingCharacter.count))", systemImage: "book.pages")
                                    .font(.subheadline.bold())

                                if chaptersFeaturingCharacter.isEmpty {
                                    Text("Mencione [[\(char.name)]] em um capítulo ou defina como POV para rastrear aparições automaticamente.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    ForEach(chaptersFeaturingCharacter) { chap in
                                        Button {
                                            store.selection = .chapter(chap.id)
                                            store.viewMode = .editor
                                        } label: {
                                            HStack {
                                                Image(systemName: chap.povCharacterId == char.id ? "eye.fill" : "doc.text")
                                                    .foregroundStyle(chap.povCharacterId == char.id ? .orange : .secondary)
                                                Text(chap.title)
                                                    .font(.caption.weight(.semibold))
                                                Spacer()
                                                if chap.povCharacterId == char.id {
                                                    Text("POV")
                                                        .font(.system(size: 9, weight: .bold))
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(Color.orange.opacity(0.15))
                                                        .foregroundStyle(.orange)
                                                        .clipShape(Capsule())
                                                }
                                                Text("\(chap.wordCount) pal.")
                                                    .font(.caption2.monospacedDigit())
                                                    .foregroundStyle(.secondary)
                                            }
                                            .padding(8)
                                            .background(Color.primary.opacity(0.04))
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(store.theme.cardBackgroundColor)
                            )
                        }
                    }
                }
                .padding(24)
            }
            .background(store.theme.backgroundColor)
        } else {
            ContentUnavailableView("Personagem não encontrado", systemImage: "person.slash")
        }
    }
}

// MARK: - Location Profile Editor

public struct LocationEditorView: View {
    @EnvironmentObject private var store: BookStore
    public let locationId: UUID

    public init(locationId: UUID) {
        self.locationId = locationId
    }

    private var location: LocationProfile? {
        store.currentBook.locations.first(where: { $0.id == locationId })
    }

    private var chaptersAtLocation: [ChapterItem] {
        guard let loc = location else { return [] }
        return store.currentBook.activeChapters.filter { chap in
            chap.locationId == loc.id ||
            chap.content.localizedCaseInsensitiveContains(loc.name)
        }
    }

    public var body: some View {
        if let loc = location {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.teal.opacity(0.16))
                                .frame(width: 54, height: 54)
                            Image(systemName: "map.fill")
                                .font(.title2)
                                .foregroundStyle(.teal)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            TextField("Nome do Local ou Cenário", text: Binding(
                                get: { loc.name },
                                set: { val in
                                    var copy = loc
                                    copy.name = val
                                    store.updateLocation(copy)
                                }
                            ))
                            .textFieldStyle(.plain)
                            .font(.system(size: 24, weight: .bold, design: .serif))

                            TextField("Região / Localização (ex: Promontório Norte da Ilha)", text: Binding(
                                get: { loc.region },
                                set: { val in
                                    var copy = loc
                                    copy.region = val
                                    store.updateLocation(copy)
                                }
                            ))
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 420)
                        }

                        Spacer()

                        Button(role: .destructive) {
                            store.deleteLocation(loc.id)
                        } label: {
                            Label("Excluir", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(store.theme.cardBackgroundColor)
                    )

                    HStack(alignment: .top, spacing: 18) {
                        VStack(alignment: .leading, spacing: 16) {
                            bibleFieldBox(
                                title: "Atmosfera & Clima Emocional",
                                icon: "cloud.fog.fill",
                                text: Binding(
                                    get: { loc.atmosphere },
                                    set: { val in
                                        var copy = loc
                                        copy.atmosphere = val
                                        store.updateLocation(copy)
                                    }
                                ),
                                height: 90
                            )

                            bibleFieldBox(
                                title: "Detalhes Sensoriais (Sons, Cheiros, Luz, Texturas)",
                                icon: "hand.Wave.fill",
                                text: Binding(
                                    get: { loc.sensoryDetails },
                                    set: { val in
                                        var copy = loc
                                        copy.sensoryDetails = val
                                        store.updateLocation(copy)
                                    }
                                ),
                                height: 110
                            )
                        }

                        VStack(alignment: .leading, spacing: 16) {
                            bibleFieldBox(
                                title: "Arquitetura, Geografia & História do Lugar",
                                icon: "building.columns",
                                text: Binding(
                                    get: { loc.description },
                                    set: { val in
                                        var copy = loc
                                        copy.description = val
                                        store.updateLocation(copy)
                                    }
                                ),
                                height: 100
                            )

                            bibleFieldBox(
                                title: "Segredos & Notas de Cena",
                                icon: "key.fill",
                                text: Binding(
                                    get: { loc.notes },
                                    set: { val in
                                        var copy = loc
                                        copy.notes = val
                                        store.updateLocation(copy)
                                    }
                                ),
                                height: 90
                            )
                        }
                    }

                    // Chapters in this setting
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Capítulos Ambientados em \(loc.name) (\(chaptersAtLocation.count))", systemImage: "mappin.and.ellipse")
                            .font(.subheadline.bold())

                        if chaptersAtLocation.isEmpty {
                            Text("Vincule este local no inspetor do capítulo ou mencione [[\(loc.name)]] no texto.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            HStack(spacing: 10) {
                                ForEach(chaptersAtLocation) { chap in
                                    Button {
                                        store.selection = .chapter(chap.id)
                                        store.viewMode = .editor
                                    } label: {
                                        Label(chap.title, systemImage: "doc.text")
                                            .font(.caption)
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(store.theme.cardBackgroundColor)
                    )
                }
                .padding(24)
            }
            .background(store.theme.backgroundColor)
        } else {
            ContentUnavailableView("Cenário não encontrado", systemImage: "map")
        }
    }
}

// MARK: - Research Note Markdown Editor

public struct ResearchNoteEditorView: View {
    @EnvironmentObject private var store: BookStore
    public let noteId: UUID

    public init(noteId: UUID) {
        self.noteId = noteId
    }

    private var note: ResearchNote? {
        store.currentBook.researchNotes.first(where: { $0.id == noteId })
    }

    public var body: some View {
        if let note = note {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "books.vertical.fill")
                        .foregroundStyle(store.theme.accentColor)

                    TextField("Título da Nota de Pesquisa", text: Binding(
                        get: { note.title },
                        set: { val in
                            var copy = note
                            copy.title = val
                            store.updateResearchNote(copy)
                        }
                    ))
                    .textFieldStyle(.plain)
                    .font(.headline)

                    TextField("Categoria", text: Binding(
                        get: { note.category },
                        set: { val in
                            var copy = note
                            copy.category = val
                            store.updateResearchNote(copy)
                        }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 180)

                    Spacer()

                    Text("\(TextAnalytics.countWords(in: note.content)) palavras")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)

                    Button(role: .destructive) {
                        store.deleteResearchNote(note.id)
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .help("Excluir nota de pesquisa")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.bar)

                Divider()

                MarkdownTextEditor(
                    text: Binding(
                        get: { note.content },
                        set: { val in
                            var copy = note
                            copy.content = val
                            store.updateResearchNote(copy)
                        }
                    ),
                    theme: store.theme,
                    fontStyle: store.fontStyle,
                    fontSize: store.fontSize,
                    lineSpacing: store.lineSpacing,
                    columnWidth: store.editorColumnWidth,
                    typewriterScrolling: false,
                    focusMode: .off,
                    commandPublisher: store.editorCommandSubject
                )
            }
        } else {
            ContentUnavailableView("Nota não encontrada", systemImage: "doc.questionmark")
        }
    }
}

// MARK: - Trash Bin View

public struct TrashBinView: View {
    @EnvironmentObject private var store: BookStore

    public init() {}

    public var body: some View {
        let trashed = store.currentBook.trashedChapters
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Lixeira do Manuscrito (\(trashed.count))", systemImage: "trash")
                    .font(.title2.bold())
                Spacer()
            }

            if trashed.isEmpty {
                ContentUnavailableView(
                    "A Lixeira Está Vazia",
                    systemImage: "trash.slash",
                    description: Text("Capítulos removidos ficam guardados aqui até que você decida restaurá-los ou excluí-los em definitivo.")
                )
            } else {
                List(trashed) { chap in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(chap.title)
                                .font(.headline)
                            Text("\(chap.wordCount) palavras • \(chap.synopsis)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Button("Restaurar") {
                            store.restoreChapter(chap.id)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)

                        Button("Excluir Definitivamente", role: .destructive) {
                            store.permanentlyDeleteChapter(chap.id)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(store.theme.backgroundColor)
    }
}

// MARK: - Shared Helper Box

@ViewBuilder
fileprivate func bibleFieldBox(title: String, icon: String, text: Binding<String>, height: CGFloat) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        Label(title, systemImage: icon)
            .font(.subheadline.bold())
            .foregroundStyle(.primary)

        TextEditor(text: text)
            .font(.system(size: 13.5))
            .scrollContentBackground(.hidden)
            .frame(height: height)
            .padding(8)
            .background(Color.primary.opacity(0.035))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    .padding(14)
    .background(
        RoundedRectangle(cornerRadius: 10)
            .fill(Color(nsColor: .controlBackgroundColor))
    )
}
