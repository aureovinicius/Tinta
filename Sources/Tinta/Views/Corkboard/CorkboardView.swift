import SwiftUI

public struct CorkboardView: View {
    @EnvironmentObject private var store: BookStore
    public var filterPartId: UUID? = nil

    @ViewState private var selectedPartFilter: UUID? = nil
    @ViewState private var selectedStatusFilter: ChapterStatus? = nil

    public init(filterPartId: UUID? = nil) {
        self.filterPartId = filterPartId
    }

    private var filteredChapters: [ChapterItem] {
        let effectivePartId = filterPartId ?? selectedPartFilter
        return store.currentBook.activeChapters.filter { chap in
            let matchesPart = (effectivePartId == nil) || (chap.partId == effectivePartId)
            let matchesStatus = (selectedStatusFilter == nil) || (chap.status == selectedStatusFilter)
            return matchesPart && matchesStatus
        }
    }

    private let columns = [
        GridItem(.adaptive(minimum: 280, maximum: 340), spacing: 18)
    ]

    public var body: some View {
        VStack(spacing: 0) {
            corkboardToolbar
            Divider()

            ScrollView {
                if filteredChapters.isEmpty {
                    ContentUnavailableView(
                        "Nenhuma Ficha Encontrada",
                        systemImage: "rectangle.grid.2x2",
                        description: Text("Adicione um novo capítulo ou ajuste os filtros do quadro de fichas.")
                    )
                    .padding(.top, 80)
                } else {
                    LazyVGrid(columns: columns, spacing: 18) {
                        ForEach(Array(filteredChapters.enumerated()), id: \.element.id) { _, chapter in
                            let globalNumber = (store.currentBook.activeChapters.firstIndex(where: { $0.id == chapter.id }) ?? 0) + 1
                            CorkboardCardView(chapter: chapter, chapterNumber: globalNumber)
                        }
                    }
                    .padding(24)
                }
            }
            .background(store.theme.backgroundColor)
        }
    }

    private var corkboardToolbar: some View {
        HStack(spacing: 14) {
            Label("Quadro de Fichas (Corkboard)", systemImage: "square.grid.2x2.fill")
                .font(.headline)

            if filterPartId == nil {
                Picker("Ato / Parte", selection: $selectedPartFilter) {
                    Text("Todos os Atos").tag(UUID?.none)
                    ForEach(store.currentBook.sortedParts) { part in
                        Text(part.title).tag(UUID?.some(part.id))
                    }
                }
                .frame(maxWidth: 220)
            } else if let pId = filterPartId,
                      let part = store.currentBook.parts.first(where: { $0.id == pId }) {
                Text(part.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(store.theme.accentColor)
            }

            Picker("Status", selection: $selectedStatusFilter) {
                Text("Todos os Status").tag(ChapterStatus?.none)
                ForEach(ChapterStatus.allCases) { st in
                    Text(st.rawValue).tag(ChapterStatus?.some(st))
                }
            }
            .frame(maxWidth: 180)

            Spacer()

            Text("\(filteredChapters.count) capítulos • \(filteredChapters.reduce(0) { $0 + $1.wordCount }) palavras")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                let created = store.addChapter(in: filterPartId ?? selectedPartFilter)
                store.selection = .chapter(created.id)
                store.viewMode = .corkboard
            } label: {
                Label("Nova Ficha", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(.bar)
    }
}

public struct CorkboardCardView: View {
    @EnvironmentObject private var store: BookStore
    public let chapter: ChapterItem
    public let chapterNumber: Int

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Top Color Label & Number Bar
            HStack(spacing: 8) {
                Circle()
                    .fill(chapter.colorLabel.color)
                    .frame(width: 10, height: 10)

                Text("CAPÍTULO \(chapterNumber)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(.secondary)

                Spacer()

                // Reorder Arrows
                HStack(spacing: 2) {
                    Button {
                        store.moveChapter(chapter.id, direction: -1)
                    } label: {
                        Image(systemName: "arrow.up.backward")
                            .font(.caption2)
                    }
                    .buttonStyle(.borderless)
                    .help("Mover capítulo para antes")

                    Button {
                        store.moveChapter(chapter.id, direction: 1)
                    } label: {
                        Image(systemName: "arrow.down.forward")
                            .font(.caption2)
                    }
                    .buttonStyle(.borderless)
                    .help("Mover capítulo para depois")
                }

                // Status Pill
                HStack(spacing: 4) {
                    Image(systemName: chapter.status.iconName)
                    Text(chapter.status.rawValue)
                }
                .font(.system(size: 10, weight: .semibold))
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(chapter.status.badgeColor.opacity(0.14))
                .foregroundStyle(chapter.status.badgeColor)
                .clipShape(Capsule())
            }

            // Chapter Title & Subtitle
            TextField("Título do Capítulo", text: Binding(
                get: { chapter.title },
                set: { val in
                    var copy = chapter
                    copy.title = val
                    store.updateChapter(copy)
                }
            ))
            .textFieldStyle(.plain)
            .font(.system(size: 15, weight: .bold, design: .serif))

            TextField("Subtítulo ou gancho da cena...", text: Binding(
                get: { chapter.subtitle },
                set: { val in
                    var copy = chapter
                    copy.subtitle = val
                    store.updateChapter(copy)
                }
            ))
            .textFieldStyle(.plain)
            .font(.system(size: 12, design: .serif).italic())
            .foregroundStyle(.secondary)

            Divider().opacity(0.4)

            // Editable Synopsis Box
            VStack(alignment: .leading, spacing: 4) {
                Text("SINOPSE DA CENA / CAPÍTULO")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)

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
                .frame(height: 82)
                .padding(6)
                .background(Color.primary.opacity(0.035))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            // Metadata Badges (POV & Location)
            HStack(spacing: 8) {
                if let povId = chapter.povCharacterId,
                   let pov = store.currentBook.characters.first(where: { $0.id == povId }) {
                    Label(pov.name, systemImage: "person.fill")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.12))
                        .foregroundStyle(.orange)
                        .clipShape(Capsule())
                }

                if let locId = chapter.locationId,
                   let loc = store.currentBook.locations.first(where: { $0.id == locId }) {
                    Label(loc.name, systemImage: "mappin.and.ellipse")
                        .font(.caption2)
                        .lineLimit(1)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.teal.opacity(0.12))
                        .foregroundStyle(.teal)
                        .clipShape(Capsule())
                }

                Spacer()
            }

            Divider().opacity(0.4)

            // Footer: Word Count Progress & Open Button
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(chapter.wordCount) / \(chapter.targetWordCount) palavras")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                    ProgressView(value: chapter.progressRatio)
                        .frame(width: 90)
                        .tint(chapter.colorLabel == .none ? store.theme.accentColor : chapter.colorLabel.color)
                }

                Spacer()

                Button {
                    store.selection = .chapter(chapter.id)
                    store.viewMode = .editor
                } label: {
                    Label("Escrever", systemImage: "pencil.line")
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(store.theme.cardBackgroundColor)
                .shadow(color: .black.opacity(store.isNightMode ? 0.35 : 0.07), radius: 5, x: 0, y: 2)
        )
        .overlay(alignment: .top) {
            UnevenRoundedRectangle(topLeadingRadius: 12, topTrailingRadius: 12)
                .fill(chapter.colorLabel.color)
                .frame(height: 5)
        }
    }
}
