import SwiftUI

public struct MainWorkspaceView: View {
    @EnvironmentObject private var store: BookStore
    @ViewState private var columnVisibility: NavigationSplitViewVisibility = .all

    public init() {}

    public var body: some View {
        ZStack(alignment: .bottom) {
            if store.isZenMode {
                zenModeWorkspace
            } else {
                NavigationSplitView(columnVisibility: $columnVisibility) {
                    SidebarBinderView()
                } detail: {
                    HStack(spacing: 0) {
                        centerDetailWorkspace
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                        if store.showInspector {
                            Divider()
                            InspectorSidebarView()
                                .transition(.move(edge: .trailing))
                        }
                    }
                }
                .toolbar {
                    workspaceToolbar
                }
            }

            // Floating Toast Banner
            if let toast = store.statusBannerMessage {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(toast)
                        .font(.caption.weight(.medium))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 3)
                .padding(.bottom, 38)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .preferredColorScheme(store.theme.isDark ? .dark : .light)
        .sheet(isPresented: $store.showBookSettingsSheet) {
            BookSettingsSheet()
                .environmentObject(store)
        }
        .sheet(isPresented: $store.showNewBookSheet) {
            NewBookSheet()
                .environmentObject(store)
        }
        .sheet(isPresented: $store.showExportSheet) {
            ExportBookSheet()
                .environmentObject(store)
        }
        .sheet(isPresented: $store.showQuickOpenSheet) {
            QuickOpenSheet()
                .environmentObject(store)
        }
        .sheet(isPresented: $store.showPartEditorSheet) {
            PartEditorSheet()
                .environmentObject(store)
        }
    }

    // MARK: - Center Detail Workspace

    @ViewBuilder
    private var centerDetailWorkspace: some View {
        switch store.selection {
        case .character(let charId):
            CharacterEditorView(characterId: charId)

        case .location(let locId):
            LocationEditorView(locationId: locId)

        case .researchNote(let noteId):
            ResearchNoteEditorView(noteId: noteId)

        case .trash:
            TrashBinView()

        case .partOverview(let partId):
            CorkboardView(filterPartId: partId)

        case .manuscriptOverview:
            switch store.viewMode {
            case .corkboard:
                CorkboardView()
            case .bookReader:
                FullBookReaderView()
            default:
                OutlinePacingView()
            }

        case .chapter(let chapterId):
            switch store.viewMode {
            case .editor, .splitPreview:
                ChapterEditorContainerView(chapterId: chapterId)
            case .corkboard:
                CorkboardView()
            case .outline:
                OutlinePacingView()
            case .bookReader:
                FullBookReaderView()
            }

        case .none:
            if let first = store.currentBook.activeChapters.first {
                ChapterEditorContainerView(chapterId: first.id)
            } else {
                OutlinePacingView()
            }
        }
    }

    // MARK: - Distraction-Free Zen Mode Workspace

    @ViewBuilder
    private var zenModeWorkspace: some View {
        if let chapterId = store.selectedChapterId ?? store.currentBook.activeChapters.first?.id {
            ChapterEditorContainerView(chapterId: chapterId)
        } else {
            OutlinePacingView()
        }
    }

    // MARK: - Window Toolbar

    @ToolbarContentBuilder
    private var workspaceToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            Button {
                store.showQuickOpenSheet = true
            } label: {
                Label("Busca Rápida", systemImage: "magnifyingglass")
            }
            .help("Busca Rápida no Livro (⌘K)")

            Button {
                let chap = store.addChapter()
                store.selection = .chapter(chap.id)
                store.viewMode = .editor
            } label: {
                Label("Novo Capítulo", systemImage: "plus.rectangle.on.folder")
            }
            .help("Criar Novo Capítulo (⌘N)")
        }

        ToolbarItem(placement: .principal) {
            Picker("Modo de Visualização", selection: $store.viewMode) {
                ForEach(WorkspaceViewMode.allCases) { mode in
                    Label(mode.rawValue, systemImage: mode.iconName)
                        .tag(mode)
                        .help(mode.tooltip)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 460)
        }

        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                store.toggleNightMode()
            } label: {
                Label(
                    store.isNightMode ? "Modo Diurno" : "Modo Noturno",
                    systemImage: store.isNightMode ? "moon.stars.fill" : "moon"
                )
                .foregroundStyle(store.isNightMode ? .yellow : .primary)
            }
            .help(store.isNightMode ? "Alternar para Modo Diurno (⌃⌘N)" : "Alternar para Modo Noturno (⌃⌘N)")

            Menu {
                Section("Modo Noturno") {
                    ForEach(EditorTheme.nightThemes) { nightTheme in
                        Button {
                            store.theme = nightTheme
                        } label: {
                            HStack {
                                Label(nightTheme.rawValue, systemImage: nightTheme.iconName)
                                if store.theme == nightTheme {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
                Section("Modo Diurno") {
                    ForEach(EditorTheme.dayThemes) { dayTheme in
                        Button {
                            store.theme = dayTheme
                        } label: {
                            HStack {
                                Label(dayTheme.rawValue, systemImage: dayTheme.iconName)
                                if store.theme == dayTheme {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            } label: {
                Label(store.theme.rawValue, systemImage: "paintpalette")
            }
            .help("Escolher paleta de tema (Diurno / Noturno)")

            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    store.isZenMode.toggle()
                }
            } label: {
                Label("Modo Zen", systemImage: "sparkles.rectangle.stack")
            }
            .help("Modo Zen Sem Distrações (⇧⌘F)")

            Button {
                store.showExportSheet = true
            } label: {
                Label("Compilar Livro", systemImage: "book.and.wrench")
            }
            .help("Compilar e Exportar Livro (⇧⌘E)")

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    store.showInspector.toggle()
                }
            } label: {
                Label("Inspetor", systemImage: "sidebar.right")
            }
            .help("Mostrar/Ocultar Inspetor Lateral (⌥⌘I)")
        }
    }
}
