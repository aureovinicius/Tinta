import Foundation
import Testing
@testable import Tinta

struct TintaTests {
    @Test("Análise literária de palavras, diálogo e eco lexical")
    func testTextAnalyticsCountsAndDialogueRatio() {
        let sample = """
        # Capítulo Um

        O vento soprava forte sobre o farol antigo da ilha. O farol brilhava na neblina espessa.

        — Você trouxe o mapa do farol? — perguntou Helena.
        — Trouxe o caderno inteiro — respondeu Mateus.
        """

        let stats = TextAnalytics.analyze(sample)
        #expect(stats.wordCount > 25)
        #expect(stats.paragraphCount == 4)
        #expect(abs(stats.dialogueLineRatio - 0.5) < 0.01)

        let repeatedFarol = stats.topRepeatedWords.first(where: { $0.word == "farol" })
        #expect(repeatedFarol != nil)
        #expect(repeatedFarol?.count == 3)

        let headings = TextAnalytics.extractOutlineHeadings(from: sample)
        #expect(headings.count == 1)
        #expect(headings.first?.title == "Capítulo Um")
    }

    @Test("Conversão de Markdown literário para HTML tipográfico")
    func testMarkdownToLiteraryHTMLConversion() {
        let md = """
        Primeiro parágrafo narrativo com **negrito** e [[Helena Viana]].

        — Uma linha de diálogo literário.

        * * *

        > Uma epígrafe citada.
        """

        let html = TextAnalytics.markdownToLiteraryHTML(md, dropCapFirstParagraph: true)
        #expect(html.contains("class=\"first-paragraph\""))
        #expect(html.contains("<strong>negrito</strong>"))
        #expect(html.contains("class=\"wikilink\">Helena Viana</span>"))
        #expect(html.contains("class=\"dialogue\""))
        #expect(html.contains("class=\"scene-break\""))
        #expect(html.contains("<blockquote>"))
    }

    @Test("Operações do BookStore, divisão de capítulos e instantâneos")
    @MainActor
    func testBookStoreOperationsAndSnapshots() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("TintaTests_\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let store = BookStore(customStorageDirectory: tempDir)
        #expect(!store.books.isEmpty)

        let initialCount = store.currentBook.activeChapters.count
        let newChap = store.addChapter(title: "Capítulo de Teste")
        #expect(store.currentBook.activeChapters.count == initialCount + 1)

        // Update content and take a snapshot
        store.updateChapterContent(id: newChap.id, newContent: "# Capítulo de Teste\n\nPrimeiro texto original.")
        store.createSnapshot(for: newChap.id, label: "Versão 1")

        // Modify content and restore snapshot
        store.updateChapterContent(id: newChap.id, newContent: "# Capítulo de Teste\n\nTexto alterado depois.")
        let snap = try #require(store.currentBook.chapters.first(where: { $0.id == newChap.id })?.snapshots.first)
        store.restoreSnapshot(snap, for: newChap.id)

        let restoredContent = store.currentBook.chapters.first(where: { $0.id == newChap.id })?.content
        #expect(restoredContent == "# Capítulo de Teste\n\nPrimeiro texto original.")

        // Split chapter test
        let fullText = "Primeira parte do capítulo.\n\nSegunda parte do capítulo."
        store.updateChapterContent(id: newChap.id, newContent: fullText)
        store.splitChapter(id: newChap.id, atUTF16Offset: 28)
        #expect(store.currentBook.activeChapters.count == initialCount + 2)

        // Trash and restore
        store.trashChapter(newChap.id)
        #expect(store.currentBook.trashedChapters.count == 1)
        store.restoreChapter(newChap.id)
        #expect(store.currentBook.trashedChapters.count == 0)
    }

    @Test("Compilação e exportação completa do livro")
    func testBookExporterCompilationAndFolderExport() throws {
        let book = SampleBookFactory.makeSampleBook()
        let compiledMD = BookExporter.compileMarkdown(book: book)
        #expect(compiledMD.contains("title: \"As Cartas do Farol de Vidro\""))
        #expect(compiledMD.contains("## Sumário"))
        #expect(compiledMD.contains("O Cheiro de Sal e Nanquim"))

        let compiledHTML = BookExporter.compileHTML(book: book)
        #expect(compiledHTML.contains("<!DOCTYPE html>"))
        #expect(compiledHTML.contains("As Cartas do Farol de Vidro"))

        let tempExportDir = FileManager.default.temporaryDirectory.appendingPathComponent("TintaExport_\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempExportDir) }

        try BookExporter.exportStructuredFolder(book: book, to: tempExportDir)
        let fullBookPath = tempExportDir.appendingPathComponent("00_Livro_Completo.md").path
        #expect(FileManager.default.fileExists(atPath: fullBookPath))
    }
}
