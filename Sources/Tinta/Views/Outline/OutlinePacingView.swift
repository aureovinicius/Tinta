import SwiftUI

public struct OutlinePacingView: View {
    @EnvironmentObject private var store: BookStore

    public init() {}

    public var body: some View {
        let book = store.currentBook
        let chapters = book.activeChapters

        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header & Book Summary Metrics
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Escaleta Estrutural & Ritmo do Livro")
                                .font(.title2.bold())
                            Text("\(book.title) — \(book.subtitle)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            store.presentNewPartSheet()
                        } label: {
                            Label("Novo Ato...", systemImage: "folder.badge.plus")
                        }
                        .buttonStyle(.bordered)

                        Button {
                            _ = store.addChapter()
                        } label: {
                            Label("Novo Capítulo", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    // Metric Cards Row
                    HStack(spacing: 14) {
                        metricCard(
                            title: "Total de Palavras",
                            value: "\(book.totalWordCount)",
                            subtitle: "Meta: \(book.targetWordCount) (\(Int(book.bookProgressRatio * 100))%)",
                            icon: "text.word.spacing",
                            color: .orange
                        )
                        metricCard(
                            title: "Páginas Estimadas",
                            value: "~\(book.estimatedPagesCount)",
                            subtitle: "\(book.estimatedReadingMinutes) min de leitura",
                            icon: "book.pages",
                            color: .blue
                        )
                        let avgWords = chapters.isEmpty ? 0 : (book.totalWordCount / chapters.count)
                        metricCard(
                            title: "Média por Capítulo",
                            value: "\(avgWords) pal.",
                            subtitle: "\(chapters.count) capítulos ativos",
                            icon: "chart.bar.xaxis",
                            color: .teal
                        )
                        let finalizedCount = chapters.filter { $0.status == .final }.count
                        metricCard(
                            title: "Capítulos Finalizados",
                            value: "\(finalizedCount) / \(chapters.count)",
                            subtitle: "\(book.parts.count) atos estruturados",
                            icon: "checkmark.seal.fill",
                            color: .green
                        )
                    }
                }

                // Visual Narrative Pacing Bar Chart
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Gráfico de Ritmo e Extensão dos Capítulos", systemImage: "waveform.path.ecg")
                            .font(.headline)
                        Spacer()
                        Text("Altura da barra = contagem de palavras • Linha tracejada = meta do capítulo")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if chapters.isEmpty {
                        Text("Adicione capítulos para visualizar o gráfico de ritmo.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding()
                    } else {
                        let maxWords = max(300, chapters.map { max($0.wordCount, $0.targetWordCount) }.max() ?? 500)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .bottom, spacing: 16) {
                                ForEach(Array(chapters.enumerated()), id: \.element.id) { index, chap in
                                    let ratio = CGFloat(chap.wordCount) / CGFloat(maxWords)
                                    let targetRatio = CGFloat(chap.targetWordCount) / CGFloat(maxWords)
                                    Button {
                                        store.selection = .chapter(chap.id)
                                        store.viewMode = .editor
                                    } label: {
                                        VStack(spacing: 6) {
                                            Text("\(chap.wordCount)")
                                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                                .foregroundStyle(.secondary)

                                            ZStack(alignment: .bottom) {
                                                RoundedRectangle(cornerRadius: 6)
                                                    .fill(Color.primary.opacity(0.06))
                                                    .frame(width: 44, height: 130)

                                                RoundedRectangle(cornerRadius: 6)
                                                    .fill(chap.status.badgeColor.gradient)
                                                    .frame(width: 44, height: max(8, 130 * min(1.0, ratio)))

                                                // Target line marker
                                                Rectangle()
                                                    .fill(Color.primary.opacity(0.45))
                                                    .frame(width: 48, height: 1.5)
                                                    .offset(y: -130 * min(1.0, targetRatio))
                                            }

                                            Text("C\(index + 1)")
                                                .font(.caption.bold())
                                            Text(chap.title)
                                                .font(.system(size: 10))
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                                .frame(width: 72)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .help("\(chap.title) — \(chap.wordCount) / \(chap.targetWordCount) palavras (\(chap.status.rawValue))")
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 4)
                        }
                    }
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(store.theme.cardBackgroundColor)
                )

                // Structured Escaleta Table grouped by Act / Part
                VStack(alignment: .leading, spacing: 14) {
                    Label("Tabela da Escaleta por Ato e Capítulo", systemImage: "tablecells")
                        .font(.headline)

                    ForEach(book.sortedParts) { part in
                        partSectionView(part: part, chapters: book.chapters(in: part.id))
                    }

                    let unassigned = book.chapters(in: nil)
                    if !unassigned.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Capítulos Sem Ato Definido")
                                .font(.subheadline.bold())
                                .foregroundStyle(.secondary)
                            ForEach(unassigned) { chap in
                                outlineRowView(for: chap)
                            }
                        }
                        .padding(14)
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
    }

    // MARK: - Subviews

    private func metricCard(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.title2.bold().monospacedDigit())
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private func partSectionView(part: BookPart, chapters: [ChapterItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "folder.fill")
                    .foregroundStyle(store.theme.accentColor)
                TextField("Título do Ato", text: Binding(
                    get: { part.title },
                    set: { val in
                        var copy = part
                        copy.title = val
                        store.updatePart(copy)
                    }
                ))
                .textFieldStyle(.roundedBorder)
                .font(.headline)
                .frame(maxWidth: 240)

                TextField("Subtítulo do Ato...", text: Binding(
                    get: { part.subtitle },
                    set: { val in
                        var copy = part
                        copy.subtitle = val
                        store.updatePart(copy)
                    }
                ))
                .textFieldStyle(.roundedBorder)
                .font(.subheadline)
                .frame(maxWidth: 260)

                Button {
                    store.presentEditPartSheet(id: part.id)
                } label: {
                    Label("Editar Ato", systemImage: "pencil")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)

                Spacer()

                let partWords = chapters.reduce(0) { $0 + $1.wordCount }
                Text("\(chapters.count) cap. • \(partWords) palavras")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)

                Button {
                    _ = store.addChapter(in: part.id)
                } label: {
                    Label("Capítulo", systemImage: "plus")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }
            .padding(.bottom, 4)

            if chapters.isEmpty {
                Text("Nenhum capítulo neste ato.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 6)
            } else {
                ForEach(chapters) { chap in
                    outlineRowView(for: chap)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private func outlineRowView(for chapter: ChapterItem) -> some View {
        let globalIndex = (store.currentBook.activeChapters.firstIndex(where: { $0.id == chapter.id }) ?? 0) + 1
        return HStack(spacing: 12) {
            Toggle("", isOn: Binding(
                get: { chapter.includeInCompile },
                set: { val in
                    var copy = chapter
                    copy.includeInCompile = val
                    store.updateChapter(copy)
                }
            ))
            .labelsHidden()
            .help("Incluir este capítulo na compilação do livro")

            Circle()
                .fill(chapter.colorLabel.color)
                .frame(width: 9, height: 9)

            Text(String(format: "#%02d", globalIndex))
                .font(.caption.monospacedDigit().bold())
                .foregroundStyle(.secondary)
                .frame(width: 30, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(chapter.title)
                    .font(.subheadline.weight(.semibold))
                if !chapter.synopsis.isEmpty {
                    Text(chapter.synopsis)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(minWidth: 180, maxWidth: .infinity, alignment: .leading)

            // POV badge
            if let povId = chapter.povCharacterId,
               let pov = store.currentBook.characters.first(where: { $0.id == povId }) {
                Label(pov.name, systemImage: "person.fill")
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.12))
                    .foregroundStyle(.orange)
                    .clipShape(Capsule())
            }

            // Status picker
            Picker("", selection: Binding(
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
            .labelsHidden()
            .frame(width: 115)

            // Word count & progress
            VStack(alignment: .trailing, spacing: 3) {
                Text("\(chapter.wordCount) / \(chapter.targetWordCount) pal.")
                    .font(.caption2.monospacedDigit())
                ProgressView(value: chapter.progressRatio)
                    .frame(width: 75)
                    .tint(chapter.status.badgeColor)
            }
            .frame(width: 95)

            // Reorder & Open
            HStack(spacing: 4) {
                Button {
                    store.moveChapter(chapter.id, direction: -1)
                } label: {
                    Image(systemName: "chevron.up")
                }
                .buttonStyle(.borderless)

                Button {
                    store.moveChapter(chapter.id, direction: 1)
                } label: {
                    Image(systemName: "chevron.down")
                }
                .buttonStyle(.borderless)

                Button {
                    store.selection = .chapter(chapter.id)
                    store.viewMode = .editor
                } label: {
                    Text("Abrir")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.primary.opacity(0.03))
        )
    }
}
