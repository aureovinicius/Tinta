import AppKit
import SwiftUI

public final class TintaAppDelegate: NSObject, NSApplicationDelegate {
    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
        if NSApplication.shared.applicationIconImage == nil || Bundle.main.bundleIdentifier == nil {
            NSApplication.shared.applicationIconImage = Self.makeLiteraryAppIcon()
        }
    }

    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    public static func makeLiteraryAppIcon(size: CGFloat = 512) -> NSImage {
        let img = NSImage(size: NSSize(width: size, height: size))
        img.lockFocus()

        let rect = NSRect(x: size * 0.06, y: size * 0.06, width: size * 0.88, height: size * 0.88)
        let path = NSBezierPath(roundedRect: rect, xRadius: size * 0.2, yRadius: size * 0.2)

        // Warm deep ink & parchment gradient
        let gradient = NSGradient(colors: [
            NSColor(calibratedRed: 0.16, green: 0.13, blue: 0.11, alpha: 1.0),
            NSColor(calibratedRed: 0.34, green: 0.18, blue: 0.12, alpha: 1.0)
        ])
        gradient?.draw(in: path, angle: -45)

        // Gold border accent
        NSColor(calibratedRed: 0.88, green: 0.68, blue: 0.42, alpha: 0.85).setStroke()
        path.lineWidth = size * 0.018
        path.stroke()

        // Draw fountain pen nib / literary monogram "T"
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont(name: "Palatino-Bold", size: size * 0.48) ?? NSFont.boldSystemFont(ofSize: size * 0.48),
            .foregroundColor: NSColor(calibratedRed: 0.97, green: 0.94, blue: 0.86, alpha: 1.0),
            .paragraphStyle: paragraph
        ]
        let str = NSAttributedString(string: "T", attributes: attrs)
        let textRect = NSRect(x: 0, y: size * 0.18, width: size, height: size * 0.62)
        str.draw(in: textRect)

        img.unlockFocus()
        return img
    }
}

@main
public struct TintaApp: App {
    @NSApplicationDelegateAdaptor(TintaAppDelegate.self) private var appDelegate
    @StateObject private var store = BookStore()

    public init() {}

    public var body: some Scene {
        WindowGroup("Tinta — Estúdio Literário Markdown") {
            MainWorkspaceView()
                .environmentObject(store)
                .frame(minWidth: 980, minHeight: 640)
        }
        .defaultSize(width: 1340, height: 840)
        .commands {
            tintaMenuCommands
        }
    }

    @CommandsBuilder
    private var tintaMenuCommands: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Novo Capítulo") {
                let chap = store.addChapter()
                store.selection = .chapter(chap.id)
                store.viewMode = .editor
            }
            .keyboardShortcut("n", modifiers: [.command])

            Button("Novo Ato / Parte") {
                store.addPart(title: "Ato \(store.currentBook.parts.count + 1)")
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])

            Button("Criar Novo Livro...") {
                store.showNewBookSheet = true
            }
            .keyboardShortcut("n", modifiers: [.command, .option])

            Divider()

            Button("Busca Rápida no Livro...") {
                store.showQuickOpenSheet = true
            }
            .keyboardShortcut("k", modifiers: [.command])

            Button("Importar Arquivo Markdown (.md)...") {
                store.importMarkdownFilePanel()
            }
            .keyboardShortcut("o", modifiers: [.command, .shift])

            Divider()

            Button("Ficha Editorial & Epígrafe do Livro...") {
                store.showBookSettingsSheet = true
            }

            Button("Compilar e Exportar Livro...") {
                store.showExportSheet = true
            }
            .keyboardShortcut("e", modifiers: [.command, .shift])
        }

        CommandMenu("Manuscrito") {
            Button("Salvar Instantâneo do Capítulo Atual") {
                if let id = store.selectedChapterId {
                    store.createSnapshot(for: id)
                }
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])

            Button("Dividir Capítulo na Posição do Cursor") {
                store.editorCommandSubject.send(.splitChapterAtCursor)
            }
            .keyboardShortcut("d", modifiers: [.command, .shift])

            Button("Duplicar Capítulo Atual") {
                if let id = store.selectedChapterId {
                    store.duplicateChapter(id)
                }
            }

            Divider()

            Button("Novo Personagem") {
                store.addCharacter()
            }

            Button("Novo Cenário / Local") {
                store.addLocation()
            }

            Button("Nova Nota de Pesquisa") {
                store.addResearchNote()
            }

            Divider()

            Button(store.isSprintActive ? "Encerrar Sprint de Escrita" : "Iniciar Sprint de Escrita (25 min)") {
                store.toggleSprint()
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])
        }

        CommandMenu("Formatação") {
            Button("Negrito (**)") {
                store.editorCommandSubject.send(.bold)
            }
            .keyboardShortcut("b", modifiers: [.command])

            Button("Itálico (*)") {
                store.editorCommandSubject.send(.italic)
            }
            .keyboardShortcut("i", modifiers: [.command])

            Divider()

            Button("Título 1 (#)") {
                store.editorCommandSubject.send(.heading(1))
            }
            .keyboardShortcut("1", modifiers: [.command, .control])

            Button("Subtítulo 2 (##)") {
                store.editorCommandSubject.send(.heading(2))
            }
            .keyboardShortcut("2", modifiers: [.command, .control])

            Button("Seção 3 (###)") {
                store.editorCommandSubject.send(.heading(3))
            }
            .keyboardShortcut("3", modifiers: [.command, .control])

            Divider()

            Button("Travessão de Diálogo Literário (—)") {
                store.editorCommandSubject.send(.dialogueDash)
            }
            .keyboardShortcut("d", modifiers: [.command])

            Button("Bloco de Citação (>)") {
                store.editorCommandSubject.send(.blockquote)
            }
            .keyboardShortcut("q", modifiers: [.command, .shift])

            Button("Quebra de Cena (* * *)") {
                store.editorCommandSubject.send(.sceneBreak)
            }

            Button("Inserir Link da Bíblia [[...]]") {
                store.editorCommandSubject.send(.wikilink)
            }
            .keyboardShortcut("l", modifiers: [.command, .shift])

            Button("Inserir Comentário de Revisão (%%)") {
                store.editorCommandSubject.send(.comment)
            }
        }

        CommandMenu("Visualização") {
            Button("Modo Editor") {
                store.viewMode = .editor
            }
            .keyboardShortcut("1", modifiers: [.command])

            Button("Modo Editor + Prova Tipográfica") {
                store.viewMode = .splitPreview
            }
            .keyboardShortcut("2", modifiers: [.command])

            Button("Modo Quadro de Fichas (Corkboard)") {
                store.viewMode = .corkboard
            }
            .keyboardShortcut("3", modifiers: [.command])

            Button("Modo Escaleta & Ritmo") {
                store.viewMode = .outline
            }
            .keyboardShortcut("4", modifiers: [.command])

            Button("Modo Leitura do Livro") {
                store.viewMode = .bookReader
            }
            .keyboardShortcut("5", modifiers: [.command])

            Divider()

            Button(store.isZenMode ? "Sair do Modo Zen" : "Entrar no Modo Zen Sem Distrações") {
                withAnimation {
                    store.isZenMode.toggle()
                }
            }
            .keyboardShortcut("f", modifiers: [.command, .shift])

            Button(store.typewriterScrolling ? "Desativar Rolagem Máquina de Escrever" : "Ativar Rolagem Máquina de Escrever") {
                store.typewriterScrolling.toggle()
            }
            .keyboardShortcut("t", modifiers: [.command, .option])

            Button(store.showInspector ? "Ocultar Inspetor" : "Mostrar Inspetor") {
                withAnimation {
                    store.showInspector.toggle()
                }
            }
            .keyboardShortcut("i", modifiers: [.command, .option])

            Divider()

            Button(store.isNightMode ? "Desativar Modo Noturno (Voltar ao Diurno)" : "Ativar Modo Noturno") {
                store.toggleNightMode()
            }
            .keyboardShortcut("n", modifiers: [.command, .control])

            Menu("Tema de Papel & Modo Noturno") {
                Section("Modo Noturno") {
                    ForEach(EditorTheme.nightThemes) { th in
                        Button(th.rawValue) {
                            store.theme = th
                        }
                    }
                }
                Section("Modo Diurno") {
                    ForEach(EditorTheme.dayThemes) { th in
                        Button(th.rawValue) {
                            store.theme = th
                        }
                    }
                }
            }

            Menu("Modo de Foco") {
                ForEach(FocusHighlightMode.allCases) { fm in
                    Button(fm.rawValue) {
                        store.focusMode = fm
                    }
                }
            }

            Divider()

            Button("Aumentar Fonte") {
                store.fontSize = min(28, store.fontSize + 1)
            }
            .keyboardShortcut("+", modifiers: [.command])

            Button("Diminuir Fonte") {
                store.fontSize = max(12, store.fontSize - 1)
            }
            .keyboardShortcut("-", modifiers: [.command])
        }
    }
}
