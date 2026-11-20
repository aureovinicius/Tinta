import AppKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - 1. Book Settings & Epigraph Sheet

public struct BookSettingsSheet: View {
    @EnvironmentObject private var store: BookStore
    @Environment(\.dismiss) private var dismiss

    @ViewState private var title: String = ""
    @ViewState private var subtitle: String = ""
    @ViewState private var author: String = ""
    @ViewState private var genre: String = ""
    @ViewState private var epigraph: String = ""
    @ViewState private var epigraphAuthor: String = ""
    @ViewState private var synopsis: String = ""
    @ViewState private var targetWordCount: Int = 60000
    @ViewState private var dailyWordGoal: Int = 1000

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label("Ficha Editorial & Metadados do Livro", systemImage: "book.closed.fill")
                    .font(.title3.bold())
                Spacer()
                Button("Fechar") { dismiss() }
                    .buttonStyle(.borderless)
            }

            Divider()

            Form {
                Section("Identificação da Obra") {
                    TextField("Título do Livro", text: $title)
                    TextField("Subtítulo", text: $subtitle)
                    HStack {
                        TextField("Autor(a)", text: $author)
                        TextField("Gênero Literário", text: $genre)
                    }
                }

                Section("Metas de Escrita") {
                    HStack {
                        TextField("Meta Total (palavras)", value: $targetWordCount, format: .number)
                        TextField("Meta Diária (palavras)", value: $dailyWordGoal, format: .number)
                    }
                }

                Section("Epígrafe da Obra") {
                    TextField("Citação de abertura do livro...", text: $epigraph, axis: .vertical)
                        .lineLimit(2...4)
                    TextField("Autor / Fonte da Epígrafe", text: $epigraphAuthor)
                }

                Section("Sinopse Geral / Quarta Capa") {
                    TextEditor(text: $synopsis)
                        .frame(height: 90)
                }
            }
            .formStyle(.grouped)

            HStack {
                if store.books.count > 1 {
                    Button("Excluir Livro da Biblioteca", role: .destructive) {
                        let id = store.currentBookId
                        dismiss()
                        store.deleteBook(id)
                    }
                }
                Spacer()
                Button("Cancelar") {
                    dismiss()
                }
                Button("Salvar Alterações") {
                    var book = store.currentBook
                    book.title = title
                    book.subtitle = subtitle
                    book.author = author
                    book.genre = genre
                    book.epigraph = epigraph
                    book.epigraphAuthor = epigraphAuthor
                    book.synopsis = synopsis
                    book.targetWordCount = max(500, targetWordCount)
                    book.dailyWordGoal = max(50, dailyWordGoal)
                    store.currentBook = book
                    store.showToast("Metadados do livro atualizados")
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(22)
        .frame(width: 580, height: 590)
        .onAppear {
            let book = store.currentBook
            title = book.title
            subtitle = book.subtitle
            author = book.author
            genre = book.genre
            epigraph = book.epigraph
            epigraphAuthor = book.epigraphAuthor
            synopsis = book.synopsis
            targetWordCount = book.targetWordCount
            dailyWordGoal = book.dailyWordGoal
        }
    }
}

// MARK: - 2. Create New Book Sheet

public struct NewBookSheet: View {
    @EnvironmentObject private var store: BookStore
    @Environment(\.dismiss) private var dismiss

    @ViewState private var title: String = ""
    @ViewState private var subtitle: String = ""
    @ViewState private var author: String = ""
    @ViewState private var genre: String = "Romance"
    @ViewState private var targetWords: Int = 50000
    @ViewState private var dailyGoal: Int = 1000

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("Criar Novo Livro", systemImage: "plus.square.on.square")
                .font(.title3.bold())

            Form {
                TextField("Título do Livro", text: $title)
                TextField("Subtítulo (Opcional)", text: $subtitle)
                TextField("Nome do Autor(a)", text: $author)
                TextField("Gênero Literário", text: $genre)
                TextField("Meta Total de Palavras", value: $targetWords, format: .number)
                TextField("Meta Diária de Palavras", value: $dailyGoal, format: .number)
            }
            .formStyle(.grouped)

            HStack {
                Button("Restaurar Livro de Exemplo") {
                    let sample = SampleBookFactory.makeSampleBook()
                    store.books.append(sample)
                    store.selectBook(sample.id)
                    store.saveLibrary()
                    dismiss()
                }
                Spacer()
                Button("Cancelar") { dismiss() }
                Button("Criar Livro") {
                    store.createNewBook(
                        title: title,
                        subtitle: subtitle,
                        author: author.isEmpty ? store.currentBook.author : author,
                        genre: genre,
                        targetWords: targetWords,
                        dailyGoal: dailyGoal
                    )
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(22)
        .frame(width: 480, height: 420)
    }
}

// MARK: - 3. Compile & Export Book Sheet

public struct ExportBookSheet: View {
    @EnvironmentObject private var store: BookStore
    @Environment(\.dismiss) private var dismiss

    @ViewState private var selectedFormat: ExportFormat = .compiledMarkdown
    @ViewState private var options = ExportOptions()

    public init() {}

    public var body: some View {
        let book = store.currentBook
        let compiledPreview = BookExporter.compileMarkdown(book: book, options: options)

        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Label("Compilar & Exportar Livro", systemImage: "book.and.wrench.fill")
                        .font(.title3.bold())
                    Text("\(book.title) • \(book.activeChapters.filter(\.includeInCompile).count) capítulos selecionados (\(book.totalWordCount) palavras)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Fechar") { dismiss() }
                    .buttonStyle(.borderless)
            }

            Divider()

            HStack(alignment: .top, spacing: 20) {
                // Left Column: Format & Options
                VStack(alignment: .leading, spacing: 14) {
                    Text("Formato de Saída")
                        .font(.subheadline.bold())

                    ForEach(ExportFormat.allCases) { fmt in
                        Button {
                            selectedFormat = fmt
                        } label: {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: selectedFormat == fmt ? "largecircle.fill.circle" : "circle")
                                    .foregroundStyle(selectedFormat == fmt ? Color.accentColor : .secondary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(fmt.rawValue)
                                        .font(.caption.weight(.semibold))
                                    Text(fmt.description)
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedFormat == fmt ? Color.accentColor.opacity(0.1) : Color.primary.opacity(0.03))
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    Divider()

                    Text("Opções Editoriais")
                        .font(.subheadline.bold())

                    Toggle("Incluir Folha de Rosto", isOn: $options.includeTitlePage)
                        .font(.caption)
                    Toggle("Incluir Epígrafe", isOn: $options.includeEpigraph)
                        .font(.caption)
                    Toggle("Gerar Sumário dos Capítulos", isOn: $options.includeTableOfContents)
                        .font(.caption)
                    Toggle("Divisórias de Ato / Parte", isOn: $options.includePartDividers)
                        .font(.caption)
                    Toggle("Subtítulos dos Capítulos", isOn: $options.includeChapterSubtitles)
                        .font(.caption)
                    Toggle("Capitulares (Drop Caps) em HTML/PDF", isOn: $options.dropCaps)
                        .font(.caption)
                    Toggle("Anexar Apêndice da Bíblia da História", isOn: $options.includeStoryBibleAppendix)
                        .font(.caption)
                }
                .frame(width: 280)

                // Right Column: Live Manuscript Preview
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Prévia da Compilação Markdown")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(compiledPreview, forType: .string)
                            store.showToast("Manuscrito compilado copiado para a Área de Transferência")
                        } label: {
                            Label("Copiar Texto Compilado", systemImage: "doc.on.doc")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                    }

                    ScrollView {
                        Text(compiledPreview)
                            .font(.system(size: 12, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(nsColor: .textBackgroundColor))
                    )
                }
            }

            Divider()

            HStack {
                Spacer()
                Button("Cancelar") { dismiss() }
                Button {
                    performExport(book: book)
                } label: {
                    Label("Exportar Agora...", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(22)
        .frame(width: 760, height: 590)
    }

    private func performExport(book: BookProject) {
        let baseFilename = BookExporter.sanitizeFilename(book.title)

        switch selectedFormat {
        case .compiledMarkdown:
            let savePanel = NSSavePanel()
            savePanel.title = "Exportar Manuscrito Markdown"
            savePanel.nameFieldStringValue = "\(baseFilename).md"
            savePanel.canCreateDirectories = true
            if savePanel.runModal() == .OK, let url = savePanel.url {
                let text = BookExporter.compileMarkdown(book: book, options: options)
                try? text.write(to: url, atomically: true, encoding: .utf8)
                store.showToast("Manuscrito salvo em \(url.lastPathComponent)")
                dismiss()
            }

        case .htmlBook:
            let savePanel = NSSavePanel()
            savePanel.title = "Exportar Livro HTML Tipográfico"
            savePanel.nameFieldStringValue = "\(baseFilename).html"
            savePanel.canCreateDirectories = true
            if savePanel.runModal() == .OK, let url = savePanel.url {
                let html = BookExporter.compileHTML(book: book, options: options, theme: store.theme)
                try? html.write(to: url, atomically: true, encoding: .utf8)
                store.showToast("Livro HTML exportado em \(url.lastPathComponent)")
                dismiss()
            }

        case .pdfBook:
            let savePanel = NSSavePanel()
            savePanel.title = "Exportar Livro Diagramado em PDF"
            savePanel.nameFieldStringValue = "\(baseFilename).pdf"
            savePanel.canCreateDirectories = true
            if savePanel.runModal() == .OK, let url = savePanel.url {
                do {
                    try BookExporter.exportPDF(book: book, options: options, to: url)
                    store.showToast("PDF salvo em \(url.lastPathComponent)")
                    dismiss()
                } catch {
                    store.showToast("Erro ao exportar PDF: \(error.localizedDescription)")
                }
            }

        case .markdownFolder:
            let openPanel = NSOpenPanel()
            openPanel.title = "Escolher Pasta de Destino para o Projeto Estruturado"
            openPanel.canChooseFiles = false
            openPanel.canChooseDirectories = true
            openPanel.canCreateDirectories = true
            openPanel.prompt = "Exportar Pasta"
            if openPanel.runModal() == .OK, let parentURL = openPanel.url {
                let targetFolder = parentURL.appendingPathComponent("\(baseFilename)_Tinta", isDirectory: true)
                do {
                    try BookExporter.exportStructuredFolder(book: book, to: targetFolder)
                    store.showToast("Projeto exportado em \(targetFolder.lastPathComponent)")
                    dismiss()
                } catch {
                    store.showToast("Erro: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - 4. Quick Open / Omni-Search Sheet (⌘K)

public struct QuickOpenSheet: View {
    @EnvironmentObject private var store: BookStore
    @Environment(\.dismiss) private var dismiss
    @ViewState private var query: String = ""

    public init() {}

    private struct SearchHit: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let icon: String
        let color: Color
        let selection: BinderSelection
    }

    private var hits: [SearchHit] {
        let book = store.currentBook
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        var all: [SearchHit] = []

        for (idx, chap) in book.activeChapters.enumerated() {
            if trimmed.isEmpty ||
               chap.title.localizedCaseInsensitiveContains(trimmed) ||
               chap.synopsis.localizedCaseInsensitiveContains(trimmed) ||
               chap.content.localizedCaseInsensitiveContains(trimmed) {
                all.append(SearchHit(
                    title: "Cap. \(idx + 1): \(chap.title)",
                    subtitle: "\(chap.wordCount) palavras • \(chap.status.rawValue)",
                    icon: "doc.text.fill",
                    color: chap.status.badgeColor,
                    selection: .chapter(chap.id)
                ))
            }
        }

        for char in book.characters {
            if trimmed.isEmpty ||
               char.name.localizedCaseInsensitiveContains(trimmed) ||
               char.summary.localizedCaseInsensitiveContains(trimmed) {
                all.append(SearchHit(
                    title: char.name,
                    subtitle: "Personagem • \(char.role.rawValue)",
                    icon: "person.fill",
                    color: char.role.color,
                    selection: .character(char.id)
                ))
            }
        }

        for loc in book.locations {
            if trimmed.isEmpty ||
               loc.name.localizedCaseInsensitiveContains(trimmed) ||
               loc.description.localizedCaseInsensitiveContains(trimmed) {
                all.append(SearchHit(
                    title: loc.name,
                    subtitle: "Cenário • \(loc.region)",
                    icon: "mappin.and.ellipse",
                    color: .teal,
                    selection: .location(loc.id)
                ))
            }
        }

        for note in book.researchNotes {
            if trimmed.isEmpty ||
               note.title.localizedCaseInsensitiveContains(trimmed) ||
               note.content.localizedCaseInsensitiveContains(trimmed) {
                all.append(SearchHit(
                    title: note.title,
                    subtitle: "Nota de Pesquisa • \(note.category)",
                    icon: "doc.text.magnifyingglass",
                    color: .purple,
                    selection: .researchNote(note.id)
                ))
            }
        }

        return all
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                TextField("Ir rapidamente para capítulo, personagem, local ou nota...", text: $query)
                    .textFieldStyle(.plain)
                    .font(.title3)
                Button("ESC") { dismiss() }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
            }
            .padding(16)

            Divider()

            List(hits) { hit in
                Button {
                    store.selection = hit.selection
                    if case .chapter = hit.selection,
                       store.viewMode != .editor && store.viewMode != .splitPreview {
                        store.viewMode = .editor
                    }
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: hit.icon)
                            .foregroundStyle(hit.color)
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(hit.title)
                                .font(.subheadline.weight(.semibold))
                            Text(hit.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "return")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 540, height: 390)
    }
}
