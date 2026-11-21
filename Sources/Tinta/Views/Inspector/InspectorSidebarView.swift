import SwiftUI

public struct InspectorSidebarView: View {
    @EnvironmentObject private var store: BookStore

    public enum InspectorTab: String, CaseIterable, Identifiable {
        case metadata = "Ficha"
        case analytics = "Estilo"
        case snapshots = "Versões & Metas"

        public var id: String { rawValue }

        public var icon: String {
            switch self {
            case .metadata: return "doc.badge.gearshape"
            case .analytics: return "chart.bar.doc.horizontal"
            case .snapshots: return "clock.arrow.circlepath"
            }
        }
    }

    @ViewState private var selectedTab: InspectorTab = .metadata
    @ViewState private var newSnapshotLabel: String = ""

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Inspector Tab Picker
            Picker("Inspetor", selection: $selectedTab) {
                ForEach(InspectorTab.allCases) { tab in
                    Label(tab.rawValue, systemImage: tab.icon)
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(10)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch selectedTab {
                    case .metadata:
                        metadataTabContent
                    case .analytics:
                        analyticsTabContent
                    case .snapshots:
                        snapshotsAndGoalsTabContent
                    }
                }
                .padding(14)
            }
        }
        .frame(minWidth: 270, idealWidth: 295, maxWidth: 340)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Tab 1: Chapter Metadata, Synopsis & Notes

    @ViewBuilder
    private var metadataTabContent: some View {
        if let chapter = store.selectedChapter {
            // Color Label Swatches
            inspectorSection(title: "Etiqueta de Cor & Status") {
                HStack(spacing: 8) {
                    ForEach(ChapterColorLabel.allCases) { label in
                        Button {
                            var copy = chapter
                            copy.colorLabel = label
                            store.updateChapter(copy)
                        } label: {
                            Circle()
                                .fill(label.color)
                                .frame(width: 18, height: 18)
                                .overlay {
                                    if chapter.colorLabel == label {
                                        Circle()
                                            .strokeBorder(Color.primary, lineWidth: 2)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                        .help(label.rawValue)
                    }
                }
                .padding(.vertical, 2)

                Picker("Status", selection: Binding(
                    get: { chapter.status },
                    set: { val in
                        var copy = chapter
                        copy.status = val
                        store.updateChapter(copy)
                    }
                )) {
                    ForEach(ChapterStatus.allCases) { st in
                        Text(st.rawValue).tag(st)
                    }
                }

                HStack(spacing: 6) {
                    Picker("Ato / Parte", selection: Binding(
                        get: { chapter.partId },
                        set: { val in
                            var copy = chapter
                            copy.partId = val
                            store.updateChapter(copy)
                        }
                    )) {
                        Text("Sem Ato").tag(UUID?.none)
                        ForEach(store.currentBook.sortedParts) { part in
                            Text(part.title).tag(UUID?.some(part.id))
                        }
                    }

                    if let partId = chapter.partId {
                        Button {
                            store.presentEditPartSheet(id: partId)
                        } label: {
                            Image(systemName: "pencil")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .help("Renomear ou editar este Ato")
                    }

                    Button {
                        store.presentNewPartSheet()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("Criar Novo Ato")
                }

                Toggle("Incluir na Compilação do Livro", isOn: Binding(
                    get: { chapter.includeInCompile },
                    set: { val in
                        var copy = chapter
                        copy.includeInCompile = val
                        store.updateChapter(copy)
                    }
                ))
                .font(.caption)
            }

            // Narrative Context (POV & Location)
            inspectorSection(title: "Contexto Narrativo") {
                Picker("Ponto de Vista (POV)", selection: Binding(
                    get: { chapter.povCharacterId },
                    set: { val in
                        var copy = chapter
                        copy.povCharacterId = val
                        store.updateChapter(copy)
                    }
                )) {
                    Text("Narrador Geral / Sem POV").tag(UUID?.none)
                    ForEach(store.currentBook.characters) { char in
                        Text(char.name).tag(UUID?.some(char.id))
                    }
                }

                Picker("Cenário Principal", selection: Binding(
                    get: { chapter.locationId },
                    set: { val in
                        var copy = chapter
                        copy.locationId = val
                        store.updateChapter(copy)
                    }
                )) {
                    Text("Não Definido").tag(UUID?.none)
                    ForEach(store.currentBook.locations) { loc in
                        Text(loc.name).tag(UUID?.some(loc.id))
                    }
                }

                HStack {
                    Text("Meta de Palavras:")
                        .font(.caption)
                    Spacer()
                    TextField("Meta", value: Binding(
                        get: { chapter.targetWordCount },
                        set: { val in
                            var copy = chapter
                            copy.targetWordCount = max(50, val)
                            store.updateChapter(copy)
                        }
                    ), format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                }
            }

            // Synopsis
            inspectorSection(title: "Sinopse do Capítulo") {
                TextEditor(text: Binding(
                    get: { chapter.synopsis },
                    set: { val in
                        var copy = chapter
                        copy.synopsis = val
                        store.updateChapter(copy)
                    }
                ))
                .font(.system(size: 12.5))
                .scrollContentBackground(.hidden)
                .frame(height: 95)
                .padding(6)
                .background(Color.primary.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            // Author Notes
            inspectorSection(title: "Notas de Revisão do Autor") {
                TextEditor(text: Binding(
                    get: { chapter.notes },
                    set: { val in
                        var copy = chapter
                        copy.notes = val
                        store.updateChapter(copy)
                    }
                ))
                .font(.system(size: 12.5))
                .scrollContentBackground(.hidden)
                .frame(height: 110)
                .padding(6)
                .background(Color.primary.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        } else {
            bookOverviewInspectorCard
        }
    }

    // MARK: - Tab 2: Style Analytics & Repeated Words Detector

    @ViewBuilder
    private var analyticsTabContent: some View {
        if let chapter = store.selectedChapter {
            let stats = TextAnalytics.analyze(chapter.content)
            let headings = TextAnalytics.extractOutlineHeadings(from: chapter.content)

            inspectorSection(title: "Métricas Estilísticas") {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    statTile(label: "Palavras", value: "\(stats.wordCount)")
                    statTile(label: "Páginas Est.", value: "~\(stats.estimatedPages)")
                    statTile(label: "Parágrafos", value: "\(stats.paragraphCount)")
                    statTile(label: "Frases", value: "\(stats.sentenceCount)")
                    statTile(label: "Palavras/Frase", value: String(format: "%.1f", stats.averageWordsPerSentence))
                    statTile(label: "% de Diálogo", value: "\(Int(stats.dialogueLineRatio * 100))%")
                    statTile(label: "Tempo Leitura", value: "\(stats.readingTimeMinutes) min")
                    statTile(label: "Narração Voz", value: "\(stats.speakingTimeMinutes) min")
                }
            }

            inspectorSection(title: "Eco Lexical (Palavras Mais Repetidas)") {
                if stats.topRepeatedWords.isEmpty {
                    Text("Nenhuma repetição excessiva detectada neste trecho.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(stats.topRepeatedWords, id: \.word) { item in
                            HStack {
                                Text(item.word)
                                    .font(.caption.weight(.medium))
                                Spacer()
                                Text("\(item.count)×")
                                    .font(.caption2.monospacedDigit().bold())
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 2)
                                    .background(store.theme.accentColor.opacity(0.15))
                                    .foregroundStyle(store.theme.accentColor)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }

            inspectorSection(title: "Subseções Markdown do Capítulo") {
                if headings.isEmpty {
                    Text("Use #, ## ou ### para organizar cenas internas.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(headings.enumerated()), id: \.offset) { _, h in
                            HStack(spacing: 6) {
                                Text(String(repeating: "#", count: h.level))
                                    .font(.caption2.monospaced().bold())
                                    .foregroundStyle(store.theme.accentColor)
                                Text(h.title)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                            .padding(.leading, CGFloat((h.level - 1) * 8))
                        }
                    }
                }
            }
        } else {
            bookOverviewInspectorCard
        }
    }

    // MARK: - Tab 3: Writing Goals & Chapter Snapshots

    @ViewBuilder
    private var snapshotsAndGoalsTabContent: some View {
        let book = store.currentBook

        inspectorSection(title: "Metas de Escrita do Livro") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Progresso do Livro")
                        .font(.caption.weight(.medium))
                    Spacer()
                    Text("\(book.totalWordCount) / \(book.targetWordCount) pal.")
                        .font(.caption.monospacedDigit())
                }
                ProgressView(value: book.bookProgressRatio)
                    .tint(store.theme.accentColor)

                Divider().padding(.vertical, 4)

                HStack {
                    Text("Meta Diária")
                        .font(.caption.weight(.medium))
                    Spacer()
                    Text("\(store.todayWordsWritten) / \(book.dailyWordGoal) pal.")
                        .font(.caption.monospacedDigit())
                }
                let dailyRatio = book.dailyWordGoal > 0 ? min(1.0, Double(store.todayWordsWritten) / Double(book.dailyWordGoal)) : 0
                ProgressView(value: dailyRatio)
                    .tint(.green)
            }
        }

        if let chapter = store.selectedChapter {
            inspectorSection(title: "Instantâneos do Capítulo (\(chapter.snapshots.count))") {
                HStack(spacing: 6) {
                    TextField("Etiqueta da versão...", text: $newSnapshotLabel)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)

                    Button {
                        store.createSnapshot(for: chapter.id, label: newSnapshotLabel)
                        newSnapshotLabel = ""
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .help("Salvar versão atual do capítulo")
                }

                if chapter.snapshots.isEmpty {
                    Text("Crie um instantâneo antes de reescrever cenas importantes para poder restaurar a qualquer momento.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(chapter.snapshots) { snap in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(snap.label)
                                        .font(.caption.weight(.semibold))
                                        .lineLimit(1)
                                    Spacer()
                                    Text("\(snap.wordCount) pal.")
                                        .font(.caption2.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }
                                Text(snap.createdAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)

                                HStack {
                                    Spacer()
                                    Button("Restaurar Versão") {
                                        store.restoreSnapshot(snap, for: chapter.id)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.mini)
                                }
                            }
                            .padding(8)
                            .background(Color.primary.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    // MARK: - Helpers

    private var bookOverviewInspectorCard: some View {
        let book = store.currentBook
        return inspectorSection(title: "Resumo do Projeto") {
            Text(book.title)
                .font(.headline)
            if !book.subtitle.isEmpty {
                Text(book.subtitle)
                    .font(.caption.italic())
                    .foregroundStyle(.secondary)
            }
            Divider()
            Text(book.synopsis)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func inspectorSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(1.1)
                .foregroundStyle(.secondary)
            content()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(store.theme.cardBackgroundColor)
        )
    }

    private func statTile(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded).monospacedDigit())
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.035))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
