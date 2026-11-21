import SwiftUI

public struct SidebarBinderView: View {
    @EnvironmentObject private var store: BookStore

    public init() {}

    private var book: BookProject {
        store.currentBook
    }

    private var searchFilter: String {
        store.binderSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Top Book Selector & Progress Card
            bookProjectHeader
            Divider()

            // Search bar inside Binder
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                TextField("Filtrar capítulos, elenco, notas...", text: $store.binderSearchText)
                    .textFieldStyle(.plain)
                    .font(.caption)
                if !store.binderSearchText.isEmpty {
                    Button {
                        store.binderSearchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.primary.opacity(0.04))

            Divider()

            // Main Binder List
            List(selection: $store.selection) {
                // Section 1: Manuscript
                Section {
                    NavigationLink(value: BinderSelection.manuscriptOverview) {
                        HStack {
                            Label("Escaleta Geral do Livro", systemImage: "books.vertical.fill")
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text("\(book.totalWordCount) pal.")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }

                    ForEach(book.sortedParts) { part in
                        let partChapters = filteredChapters(in: part.id)
                        if searchFilter.isEmpty || !partChapters.isEmpty {
                            DisclosureGroup {
                                ForEach(partChapters) { chap in
                                    chapterRow(for: chap)
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "folder.fill")
                                        .foregroundStyle(store.theme.accentColor)
                                    Text(part.title)
                                        .font(.caption.weight(.bold))
                                        .lineLimit(1)
                                    Spacer()
                                    Button {
                                        store.presentEditPartSheet(id: part.id)
                                    } label: {
                                        Image(systemName: "pencil")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Renomear ou editar \(part.title)")

                                    Button {
                                        _ = store.addChapter(in: part.id)
                                    } label: {
                                        Image(systemName: "plus.circle")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Novo capítulo em \(part.title)")
                                }
                                .contextMenu {
                                    Button("Renomear / Editar Ato...") {
                                        store.presentEditPartSheet(id: part.id)
                                    }
                                    Button("Novo Capítulo neste Ato") {
                                        _ = store.addChapter(in: part.id)
                                    }
                                    Button("Ver Fichas deste Ato") {
                                        store.selection = .partOverview(part.id)
                                    }
                                    Divider()
                                    Button("Mover Ato para Cima") {
                                        store.movePart(part.id, direction: -1)
                                    }
                                    Button("Mover Ato para Baixo") {
                                        store.movePart(part.id, direction: 1)
                                    }
                                    Divider()
                                    Button("Remover Ato (manter capítulos)", role: .destructive) {
                                        store.deletePart(part.id)
                                    }
                                }
                            }
                        }
                    }

                    let unassigned = filteredChapters(in: nil)
                    if !unassigned.isEmpty {
                        ForEach(unassigned) { chap in
                            chapterRow(for: chap)
                        }
                    }
                } header: {
                    HStack(spacing: 8) {
                        Text("MANUSCRITO")
                            .font(.system(size: 10, weight: .bold))
                        Spacer()
                        Button {
                            store.presentNewPartSheet()
                        } label: {
                            Image(systemName: "folder.badge.plus")
                        }
                        .buttonStyle(.plain)
                        .help("Novo Ato / Parte (⇧⌘N)")

                        Button {
                            _ = store.addChapter()
                        } label: {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.plain)
                        .help("Adicionar Capítulo (⌘N)")
                    }
                }

                // Section 2: Characters
                Section {
                    ForEach(filteredCharacters) { character in
                        NavigationLink(value: BinderSelection.character(character.id)) {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(character.role.color)
                                    .frame(width: 7, height: 7)
                                Text(character.name)
                                    .font(.caption.weight(.medium))
                                    .lineLimit(1)
                                Spacer()
                                Text(character.role.rawValue)
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .contextMenu {
                            Button("Excluir Personagem", role: .destructive) {
                                store.deleteCharacter(character.id)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("PERSONAGENS (\(book.characters.count))")
                            .font(.system(size: 10, weight: .bold))
                        Spacer()
                        Button {
                            store.addCharacter()
                        } label: {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.plain)
                        .help("Novo Personagem")
                    }
                }

                // Section 3: Locations / Settings
                Section {
                    ForEach(filteredLocations) { location in
                        NavigationLink(value: BinderSelection.location(location.id)) {
                            HStack(spacing: 8) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundStyle(.teal)
                                    .font(.caption)
                                Text(location.name)
                                    .font(.caption.weight(.medium))
                                    .lineLimit(1)
                            }
                        }
                        .contextMenu {
                            Button("Excluir Local", role: .destructive) {
                                store.deleteLocation(location.id)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("LOCAIS & CENÁRIOS (\(book.locations.count))")
                            .font(.system(size: 10, weight: .bold))
                        Spacer()
                        Button {
                            store.addLocation()
                        } label: {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.plain)
                        .help("Novo Cenário")
                    }
                }

                // Section 4: Research & Lore Notes
                Section {
                    ForEach(filteredNotes) { note in
                        NavigationLink(value: BinderSelection.researchNote(note.id)) {
                            HStack(spacing: 8) {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .foregroundStyle(.purple)
                                    .font(.caption)
                                Text(note.title)
                                    .font(.caption.weight(.medium))
                                    .lineLimit(1)
                            }
                        }
                        .contextMenu {
                            Button("Excluir Nota", role: .destructive) {
                                store.deleteResearchNote(note.id)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("NOTAS & PESQUISA (\(book.researchNotes.count))")
                            .font(.system(size: 10, weight: .bold))
                        Spacer()
                        Button {
                            store.addResearchNote()
                        } label: {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.plain)
                        .help("Nova Nota de Pesquisa")
                    }
                }

                // Section 5: Trash
                Section {
                    NavigationLink(value: BinderSelection.trash) {
                        HStack {
                            Label("Lixeira", systemImage: "trash")
                                .font(.caption)
                            Spacer()
                            if !book.trashedChapters.isEmpty {
                                Text("\(book.trashedChapters.count)")
                                    .font(.caption2.monospacedDigit().bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 1)
                                    .background(Color.secondary.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            .listStyle(.sidebar)

            Divider()

            // Bottom Binder Action Footer
            HStack(spacing: 10) {
                Menu {
                    Button {
                        _ = store.addChapter()
                    } label: {
                        Label("Novo Capítulo", systemImage: "doc.badge.plus")
                    }
                    Button {
                        store.presentNewPartSheet()
                    } label: {
                        Label("Novo Ato / Parte...", systemImage: "folder.badge.plus")
                    }
                    Divider()
                    Button {
                        store.addCharacter()
                    } label: {
                        Label("Novo Personagem", systemImage: "person.badge.plus")
                    }
                    Button {
                        store.addLocation()
                    } label: {
                        Label("Novo Local / Cenário", systemImage: "mappin.and.ellipse")
                    }
                    Button {
                        store.addResearchNote()
                    } label: {
                        Label("Nova Nota de Pesquisa", systemImage: "note.text.badge.plus")
                    }
                    Divider()
                    Button {
                        store.importMarkdownFilePanel()
                    } label: {
                        Label("Importar Arquivo .md...", systemImage: "square.and.arrow.down")
                    }
                } label: {
                    Label("Adicionar", systemImage: "plus")
                        .font(.caption.weight(.medium))
                }
                .menuStyle(.borderlessButton)
                .fixedSize()

                Spacer()

                Button {
                    store.showExportSheet = true
                } label: {
                    Label("Compilar", systemImage: "book.and.wrench")
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Compilar e Exportar Livro (.md, .html, .pdf)")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.bar)
        }
        .frame(minWidth: 235, idealWidth: 265, maxWidth: 320)
    }

    // MARK: - Top Book Project Header

    private var bookProjectHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Menu {
                    Section("Livros na Biblioteca") {
                        ForEach(store.books) { b in
                            Button {
                                store.selectBook(b.id)
                            } label: {
                                HStack {
                                    Text(b.title)
                                    if b.id == store.currentBookId {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                    Divider()
                    Button {
                        store.showNewBookSheet = true
                    } label: {
                        Label("Criar Novo Livro...", systemImage: "plus.square.on.square")
                    }
                    Button {
                        store.showBookSettingsSheet = true
                    } label: {
                        Label("Configurações & Epígrafe do Livro...", systemImage: "slider.horizontal.3")
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "book.closed.fill")
                            .foregroundStyle(store.theme.accentColor)
                        Text(book.title)
                            .font(.system(size: 13.5, weight: .bold, design: .serif))
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    store.showBookSettingsSheet = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Metadados e configurações do livro")
            }

            HStack {
                Text(book.author)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(book.totalWordCount) / \(book.targetWordCount) pal. (\(Int(book.bookProgressRatio * 100))%)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: book.bookProgressRatio)
                .tint(store.theme.accentColor)
        }
        .padding(12)
    }

    // MARK: - Chapter Row & Context Menu

    @ViewBuilder
    private func chapterRow(for chapter: ChapterItem) -> some View {
        let globalNum = (book.activeChapters.firstIndex(where: { $0.id == chapter.id }) ?? 0) + 1
        NavigationLink(value: BinderSelection.chapter(chapter.id)) {
            HStack(spacing: 7) {
                Circle()
                    .fill(chapter.colorLabel.color)
                    .frame(width: 7, height: 7)

                Image(systemName: chapter.status.iconName)
                    .font(.system(size: 11))
                    .foregroundStyle(chapter.status.badgeColor)

                VStack(alignment: .leading, spacing: 1) {
                    Text("\(globalNum). \(chapter.title)")
                        .font(.caption.weight(.medium))
                        .lineLimit(1)
                    if !chapter.subtitle.isEmpty {
                        Text(chapter.subtitle)
                            .font(.system(size: 10).italic())
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Text("\(chapter.wordCount)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 1)
        }
        .contextMenu {
            Button("Abrir no Editor") {
                store.selection = .chapter(chapter.id)
                store.viewMode = .editor
            }
            Button("Salvar Instantâneo (Snapshot)") {
                store.createSnapshot(for: chapter.id)
            }
            Button("Duplicar Capítulo") {
                store.duplicateChapter(chapter.id)
            }
            Divider()
            Button("Mover para Cima") {
                store.moveChapter(chapter.id, direction: -1)
            }
            Button("Mover para Baixo") {
                store.moveChapter(chapter.id, direction: 1)
            }
            Divider()
            Menu("Alterar Status") {
                ForEach(ChapterStatus.allCases) { st in
                    Button(st.rawValue) {
                        var copy = chapter
                        copy.status = st
                        store.updateChapter(copy)
                    }
                }
            }
            Menu("Mover para Ato") {
                ForEach(book.sortedParts) { part in
                    Button(part.title) {
                        var copy = chapter
                        copy.partId = part.id
                        store.updateChapter(copy)
                    }
                }
            }
            Divider()
            Button("Mover para a Lixeira", role: .destructive) {
                store.trashChapter(chapter.id)
            }
        }
    }

    // MARK: - Search Filtering Helpers

    private func filteredChapters(in partId: UUID?) -> [ChapterItem] {
        let base = book.chapters(in: partId)
        guard !searchFilter.isEmpty else { return base }
        return base.filter { chap in
            chap.title.localizedCaseInsensitiveContains(searchFilter) ||
            chap.subtitle.localizedCaseInsensitiveContains(searchFilter) ||
            chap.synopsis.localizedCaseInsensitiveContains(searchFilter) ||
            chap.content.localizedCaseInsensitiveContains(searchFilter)
        }
    }

    private var filteredCharacters: [CharacterProfile] {
        guard !searchFilter.isEmpty else { return book.characters }
        return book.characters.filter {
            $0.name.localizedCaseInsensitiveContains(searchFilter) ||
            $0.summary.localizedCaseInsensitiveContains(searchFilter)
        }
    }

    private var filteredLocations: [LocationProfile] {
        guard !searchFilter.isEmpty else { return book.locations }
        return book.locations.filter {
            $0.name.localizedCaseInsensitiveContains(searchFilter) ||
            $0.description.localizedCaseInsensitiveContains(searchFilter)
        }
    }

    private var filteredNotes: [ResearchNote] {
        guard !searchFilter.isEmpty else { return book.researchNotes }
        return book.researchNotes.filter {
            $0.title.localizedCaseInsensitiveContains(searchFilter) ||
            $0.content.localizedCaseInsensitiveContains(searchFilter)
        }
    }
}
