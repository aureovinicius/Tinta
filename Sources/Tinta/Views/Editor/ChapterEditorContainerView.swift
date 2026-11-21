import SwiftUI

public struct ChapterEditorContainerView: View {
    @EnvironmentObject private var store: BookStore
    public let chapterId: UUID

    @ViewState private var showTypographyPopover: Bool = false
    @ViewState private var showWikiLinkInsertMenu: Bool = false

    public init(chapterId: UUID) {
        self.chapterId = chapterId
    }

    private var chapter: ChapterItem? {
        store.currentBook.chapters.first(where: { $0.id == chapterId })
    }

    private var chapterNumber: Int {
        if let idx = store.currentBook.activeChapters.firstIndex(where: { $0.id == chapterId }) {
            return idx + 1
        }
        return 1
    }

    public var body: some View {
        if let chapter = chapter {
            VStack(spacing: 0) {
                if !store.isZenMode {
                    editorHeaderToolbar(for: chapter)
                    Divider()
                }

                // Editor or Split Editor + Typeset Proof
                if store.viewMode == .splitPreview {
                    HSplitView {
                        markdownEditorBody(for: chapter)
                            .frame(minWidth: 340, maxWidth: .infinity, maxHeight: .infinity)

                        SingleChapterTypesetView(chapter: chapter, chapterNumber: chapterNumber)
                            .frame(minWidth: 320, maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else {
                    markdownEditorBody(for: chapter)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                Divider()
                editorBottomStatusBar(for: chapter)
            }
            .background(store.theme.backgroundColor)
        } else {
            ContentUnavailableView(
                "Nenhum Capítulo Selecionado",
                systemImage: "book.closed",
                description: Text("Selecione um capítulo no fichário à esquerda ou crie um novo capítulo.")
            )
        }
    }

    // MARK: - Top Formatting & Metadata Bar

    @ViewBuilder
    private func editorHeaderToolbar(for chapter: ChapterItem) -> some View {
        VStack(spacing: 8) {
            // Row 1: Chapter breadcrumb, Title inline editor, Status & POV badges
            HStack(spacing: 12) {
                Circle()
                    .fill(chapter.colorLabel.color)
                    .frame(width: 10, height: 10)

                Text("CAP. \(chapterNumber)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)

                TextField("Título do Capítulo", text: Binding(
                    get: { chapter.title },
                    set: { newTitle in
                        var updated = chapter
                        updated.title = newTitle
                        store.updateChapter(updated)
                    }
                ))
                .textFieldStyle(.plain)
                .font(.system(size: 15, weight: .semibold))
                .frame(maxWidth: 280)

                // Act / Part Interactive Menu Pill
                Menu {
                    Section("Mover Capítulo para Ato") {
                        Button("Sem Ato") {
                            var updated = chapter
                            updated.partId = nil
                            store.updateChapter(updated)
                        }
                        ForEach(store.currentBook.sortedParts) { p in
                            Button {
                                var updated = chapter
                                updated.partId = p.id
                                store.updateChapter(updated)
                            } label: {
                                HStack {
                                    Text(p.title)
                                    if chapter.partId == p.id {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                    Divider()
                    if let currentPartId = chapter.partId {
                        Button {
                            store.presentEditPartSheet(id: currentPartId)
                        } label: {
                            Label("Renomear / Editar Este Ato...", systemImage: "pencil")
                        }
                    }
                    Button {
                        store.presentNewPartSheet()
                    } label: {
                        Label("Novo Ato / Parte...", systemImage: "folder.badge.plus")
                    }
                } label: {
                    let partTitle = store.currentBook.parts.first(where: { $0.id == chapter.partId })?.title ?? "Sem Ato"
                    HStack(spacing: 4) {
                        Image(systemName: "folder")
                        Text(partTitle)
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(Capsule())
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .help("Trocar, renomear ou criar Ato / Parte")

                Spacer()

                // POV Picker Pill
                Menu {
                    Button("Sem Ponto de Vista (POV)") {
                        var updated = chapter
                        updated.povCharacterId = nil
                        store.updateChapter(updated)
                    }
                    Divider()
                    ForEach(store.currentBook.characters) { character in
                        Button {
                            var updated = chapter
                            updated.povCharacterId = character.id
                            store.updateChapter(updated)
                        } label: {
                            Label(character.name, systemImage: "person.fill")
                        }
                    }
                } label: {
                    let povName = store.currentBook.characters.first(where: { $0.id == chapter.povCharacterId })?.name ?? "POV"
                    Label(povName, systemImage: "person.crop.circle")
                        .font(.caption)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()

                // Status Picker Pill
                Menu {
                    ForEach(ChapterStatus.allCases) { st in
                        Button {
                            var updated = chapter
                            updated.status = st
                            store.updateChapter(updated)
                        } label: {
                            Label(st.rawValue, systemImage: st.iconName)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: chapter.status.iconName)
                        Text(chapter.status.rawValue)
                    }
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(chapter.status.badgeColor.opacity(0.15))
                    .foregroundStyle(chapter.status.badgeColor)
                    .clipShape(Capsule())
                }
                .menuStyle(.borderlessButton)
                .fixedSize()

                Button {
                    store.createSnapshot(for: chapter.id)
                } label: {
                    Label("Instantâneo", systemImage: "camera.aperture")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Salvar um instantâneo (snapshot) do capítulo atual antes de grandes edições")
            }

            // Row 2: Literary Markdown Formatting Bar
            HStack(spacing: 4) {
                Group {
                    formatButton(label: "H1", icon: nil, tooltip: "Título Nível 1") {
                        store.editorCommandSubject.send(.heading(1))
                    }
                    formatButton(label: "H2", icon: nil, tooltip: "Subtítulo Nível 2") {
                        store.editorCommandSubject.send(.heading(2))
                    }
                    formatButton(label: "H3", icon: nil, tooltip: "Seção Nível 3") {
                        store.editorCommandSubject.send(.heading(3))
                    }

                    Divider().frame(height: 16).padding(.horizontal, 4)

                    formatButton(label: nil, icon: "bold", tooltip: "Negrito (**texto**)") {
                        store.editorCommandSubject.send(.bold)
                    }
                    formatButton(label: nil, icon: "italic", tooltip: "Itálico (*texto*)") {
                        store.editorCommandSubject.send(.italic)
                    }
                    formatButton(label: "— Diálogo", icon: "text.bubble", tooltip: "Inserir Travessão Literário de Diálogo (—)") {
                        store.editorCommandSubject.send(.dialogueDash)
                    }
                    formatButton(label: nil, icon: "text.quote", tooltip: "Citação / Epígrafe (> )") {
                        store.editorCommandSubject.send(.blockquote)
                    }
                    formatButton(label: "⁂ Cena", icon: nil, tooltip: "Inserir Quebra de Cena (* * *)") {
                        store.editorCommandSubject.send(.sceneBreak)
                    }
                }

                // WikiLink insertion menu for Characters & Locations
                Menu {
                    Button("Inserir [[Link Livre]]") {
                        store.editorCommandSubject.send(.wikilink)
                    }
                    if !store.currentBook.characters.isEmpty {
                        Divider()
                        Text("Personagens")
                        ForEach(store.currentBook.characters) { char in
                            Button("[[ \(char.name) ]]") {
                                insertEntityWikiLink(name: char.name, into: chapter)
                            }
                        }
                    }
                    if !store.currentBook.locations.isEmpty {
                        Divider()
                        Text("Locais & Cenários")
                        ForEach(store.currentBook.locations) { loc in
                            Button("[[ \(loc.name) ]]") {
                                insertEntityWikiLink(name: loc.name, into: chapter)
                            }
                        }
                    }
                } label: {
                    Label("[[Elenco]]", systemImage: "link")
                        .font(.caption)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .padding(.horizontal, 4)

                formatButton(label: nil, icon: "note.text", tooltip: "Comentário de Revisão Oculto (%% nota %%)") {
                    store.editorCommandSubject.send(.comment)
                }

                formatButton(label: "Dividir", icon: "scissors", tooltip: "Dividir Capítulo na Posição do Cursor") {
                    store.editorCommandSubject.send(.splitChapterAtCursor)
                }

                Spacer()

                // Typewriter Scrolling Toggle
                Toggle(isOn: $store.typewriterScrolling) {
                    Image(systemName: "align.vertical.center")
                }
                .toggleStyle(.button)
                .controlSize(.small)
                .help("Modo Máquina de Escrever (mantém a linha ativa centralizada)")

                // Focus Mode Picker
                Menu {
                    ForEach(FocusHighlightMode.allCases) { mode in
                        Button {
                            store.focusMode = mode
                        } label: {
                            HStack {
                                Text(mode.rawValue)
                                if store.focusMode == mode {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Label(
                        store.focusMode == .off ? "Foco" : store.focusMode.rawValue,
                        systemImage: store.focusMode == .off ? "eye" : "eye.circle.fill"
                    )
                    .font(.caption)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()

                // Typography & Theme Popover button
                Button {
                    showTypographyPopover.toggle()
                } label: {
                    Label("Tipografia", systemImage: "textformat.size")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .popover(isPresented: $showTypographyPopover, arrowEdge: .bottom) {
                    typographySettingsPopover
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }

    // MARK: - Main Editor Area

    @ViewBuilder
    private func markdownEditorBody(for chapter: ChapterItem) -> some View {
        MarkdownTextEditor(
            text: Binding(
                get: { chapter.content },
                set: { newValue in
                    store.updateChapterContent(id: chapter.id, newContent: newValue)
                }
            ),
            theme: store.theme,
            fontStyle: store.fontStyle,
            fontSize: store.fontSize,
            lineSpacing: store.lineSpacing,
            columnWidth: store.editorColumnWidth,
            typewriterScrolling: store.typewriterScrolling,
            focusMode: store.focusMode,
            commandPublisher: store.editorCommandSubject,
            onSplitAtCursor: { utf16Offset in
                store.splitChapter(id: chapter.id, atUTF16Offset: utf16Offset)
            }
        )
    }

    // MARK: - Bottom Status Bar

    @ViewBuilder
    private func editorBottomStatusBar(for chapter: ChapterItem) -> some View {
        let stats = TextAnalytics.analyze(chapter.content)
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                Text("\(stats.wordCount) palavras")
                    .font(.caption.monospacedDigit().weight(.semibold))
                Text("/ meta \(chapter.targetWordCount)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)

                ProgressView(value: chapter.progressRatio)
                    .frame(width: 64)
                    .tint(chapter.progressRatio >= 1.0 ? .green : store.theme.accentColor)
            }

            Divider().frame(height: 12)

            Text("\(stats.characterCount) caracteres")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)

            Text("~\(stats.estimatedPages) pág.")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)

            Text("\(stats.readingTimeMinutes) min leitura")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)

            Text("Diálogo: \(Int(stats.dialogueLineRatio * 100))%")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)

            Spacer()

            // Writing Sprint Widget in Status Bar
            if store.isSprintActive {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text(formatSeconds(store.sprintSecondsRemaining))
                        .font(.caption.monospacedDigit().bold())
                    Text("(+\(store.sprintWordsWritten) pal.)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.green)
                    Button("Parar") {
                        store.stopSprint()
                    }
                    .buttonStyle(.borderless)
                    .font(.caption2)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.orange.opacity(0.15))
                .clipShape(Capsule())
            } else {
                Button {
                    store.startSprint()
                } label: {
                    Label("Sprint 25m", systemImage: "timer")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }

            Divider().frame(height: 12)

            // Quick Night Mode Toggle in Bottom Status Bar
            Button {
                store.toggleNightMode()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: store.isNightMode ? "moon.stars.fill" : "sun.max")
                        .foregroundStyle(store.isNightMode ? .yellow : .secondary)
                    Text(store.theme.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .help("Alternar entre Modo Diurno e Modo Noturno (⌃⌘N)")

            if store.isZenMode {
                Button {
                    withAnimation {
                        store.isZenMode = false
                    }
                } label: {
                    Label("Sair do Modo Zen", systemImage: "arrow.down.right.and.arrow.up.left")
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.mini)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(.bar)
    }

    // MARK: - Typography Popover

    private var typographySettingsPopover: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Aparência & Tipografia")
                    .font(.headline)
                Spacer()
                Button {
                    store.toggleNightMode()
                } label: {
                    Label(
                        store.isNightMode ? "Noturno Ativo" : "Ativar Noturno",
                        systemImage: store.isNightMode ? "moon.stars.fill" : "moon"
                    )
                    .font(.caption.weight(.medium))
                }
                .buttonStyle(.borderedProminent)
                .tint(store.isNightMode ? .indigo : .secondary)
                .controlSize(.small)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("MODO NOTURNO")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    ForEach(EditorTheme.nightThemes) { th in
                        themeSwatchButton(for: th)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("MODO DIURNO")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    ForEach(EditorTheme.dayThemes) { th in
                        themeSwatchButton(for: th)
                    }
                }
            }

            Divider()

            Picker("Fonte", selection: $store.fontStyle) {
                ForEach(EditorFontStyle.allCases) { font in
                    Text(font.rawValue).tag(font)
                }
            }

            HStack {
                Text("Tamanho: \(Int(store.fontSize)) pt")
                    .font(.caption)
                    .frame(width: 110, alignment: .leading)
                Slider(value: $store.fontSize, in: 13...26, step: 1)
            }

            HStack {
                Text("Entrelinha: \(Int(store.lineSpacing)) pt")
                    .font(.caption)
                    .frame(width: 110, alignment: .leading)
                Slider(value: $store.lineSpacing, in: 2...16, step: 1)
            }

            HStack {
                Text("Largura: \(Int(store.editorColumnWidth)) px")
                    .font(.caption)
                    .frame(width: 110, alignment: .leading)
                Slider(value: $store.editorColumnWidth, in: 520...960, step: 20)
            }
        }
        .padding(16)
        .frame(width: 340)
    }

    private func themeSwatchButton(for th: EditorTheme) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                store.theme = th
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(th.backgroundColor)
                        .frame(height: 32)
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .strokeBorder(
                                    store.theme == th ? th.accentColor : Color.primary.opacity(0.18),
                                    lineWidth: store.theme == th ? 2.5 : 1
                                )
                        )
                    HStack(spacing: 4) {
                        Image(systemName: th.iconName)
                            .font(.caption2)
                            .foregroundStyle(th.accentColor)
                        Text("Aa")
                            .font(.system(size: 12, weight: .bold, design: .serif))
                            .foregroundStyle(th.textColor)
                    }
                }
                Text(th.rawValue)
                    .font(.system(size: 10, weight: store.theme == th ? .bold : .regular))
                    .foregroundStyle(store.theme == th ? .primary : .secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func formatButton(label: String?, icon: String?, tooltip: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 3) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                if let label = label {
                    Text(label)
                        .font(.caption.weight(.semibold))
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
        }
        .buttonStyle(.borderless)
        .help(tooltip)
    }

    private func insertEntityWikiLink(name: String, into chapter: ChapterItem) {
        var updated = chapter
        updated.content += " [[\(name)]]"
        store.updateChapter(updated)
    }

    private func formatSeconds(_ totalSeconds: Int) -> String {
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
