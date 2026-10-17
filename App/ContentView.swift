import SwiftUI
import SwiftData

enum PieceSortOption: String, CaseIterable, Identifiable {
    case titleAsc = "Título (A-Z)"
    case titleDesc = "Título (Z-A)"
    case composerAsc = "Compositor (A-Z)"
    case difficultyAsc = "Dificultad (menor a mayor)"
    case difficultyDesc = "Dificultad (mayor a menor)"
    case dateLearnedDesc = "Fecha de añadido (más reciente)"
    
    var id: String { rawValue }
    
    var systemImage: String {
        switch self {
        case .titleAsc: return "arrow.up"
        case .titleDesc: return "arrow.down"
        case .composerAsc: return "person"
        case .difficultyAsc: return "star"
        case .difficultyDesc: return "star.fill"
        case .dateLearnedDesc: return "calendar"
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var pieces: [RepertoirePiece]
    @Query(sort: \PieceFolder.createdAt, order: .forward) private var folders: [PieceFolder]
    @State private var searchText = ""
    @State private var sortOption: PieceSortOption = .titleAsc
    @State private var isShowingAddSheet = false
    @State private var isShowingDiscoverSheet = false
    @State private var isShowingHelpSheet = false
    @State private var isShowingFolderSheet = false
    @State private var selectedFolder: PieceFolder? = nil
    @State private var selectedPiece: RepertoirePiece?
    
    var filteredPieces: [RepertoirePiece] {
        let filtered = pieces.filter { piece in
            if let selectedFolder = selectedFolder {
                if piece.folder?.id != selectedFolder.id {
                    return false
                }
            }

            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            if query.isEmpty { return true }
            
            let words = query.split(separator: " ").map(String.init).filter { !$0.isEmpty }
            let fields: [String] = [
                piece.title,
                piece.composer,
                piece.key,
                piece.studyNotes ?? "",
                piece.eraRaw,
                piece.statusRaw
            ]
            
            // Coincidencia con frase completa o con cualquier palabra en cualquiera de los campos
            let matchesFull = fields.contains { $0.localizedCaseInsensitiveContains(query) }
            let matchesAnyWord = words.contains { word in
                fields.contains { $0.localizedCaseInsensitiveContains(word) }
            }
            return matchesFull || matchesAnyWord
        }
        
        return filtered.sorted { p1, p2 in
            switch sortOption {
            case .titleAsc:
                return p1.title.localizedCaseInsensitiveCompare(p2.title) == .orderedAscending
            case .titleDesc:
                return p1.title.localizedCaseInsensitiveCompare(p2.title) == .orderedDescending
            case .composerAsc:
                return p1.composer.localizedCaseInsensitiveCompare(p2.composer) == .orderedAscending
            case .difficultyAsc:
                if p1.difficulty == p2.difficulty {
                    return p1.title.localizedCaseInsensitiveCompare(p2.title) == .orderedAscending
                }
                return p1.difficulty < p2.difficulty
            case .difficultyDesc:
                if p1.difficulty == p2.difficulty {
                    return p1.title.localizedCaseInsensitiveCompare(p2.title) == .orderedAscending
                }
                return p1.difficulty > p2.difficulty
            case .dateLearnedDesc:
                return p1.dateLearned > p2.dateLearned
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedPiece) {
                // Sección de Carpetas Personalizadas
                Section {
                    Button {
                        selectedFolder = nil
                    } label: {
                        ZStack(alignment: .leading) {
                            Color.black.opacity(0.001)
                                .frame(maxWidth: .infinity)
                                .contentShape(Rectangle())

                            HStack(spacing: 10) {
                                Image(systemName: "tray.full")
                                    .foregroundStyle(selectedFolder == nil ? Color.accentColor : Color.secondary)
                                Text("Todas las obras")
                                    .fontWeight(selectedFolder == nil ? .semibold : .regular)
                                    .foregroundStyle(selectedFolder == nil ? Color.accentColor : Color.primary)
                                Spacer()
                                Text("\(pieces.count)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if selectedFolder == nil {
                                    Image(systemName: "checkmark")
                                        .font(.caption.bold())
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .dropDestination(for: String.self) { items, _ in
                        if let uuidString = items.first,
                           let uuid = UUID(uuidString: uuidString),
                           let draggedPiece = pieces.first(where: { $0.id == uuid }) {
                            draggedPiece.folder = nil
                            try? modelContext.save()
                            return true
                        }
                        return false
                    }

                    ForEach(folders) { folder in
                        Button {
                            if selectedFolder?.id == folder.id {
                                selectedFolder = nil
                            } else {
                                selectedFolder = folder
                            }
                        } label: {
                            ZStack(alignment: .leading) {
                                Color.black.opacity(0.001)
                                    .frame(maxWidth: .infinity)
                                    .contentShape(Rectangle())

                                HStack(spacing: 10) {
                                    Image(systemName: "folder.fill")
                                        .foregroundStyle(Color(hex: folder.colorHex))
                                    Text(folder.name)
                                        .fontWeight(selectedFolder?.id == folder.id ? .semibold : .regular)
                                        .foregroundStyle(selectedFolder?.id == folder.id ? Color.accentColor : Color.primary)
                                    Spacer()
                                    Text("\(folder.pieces?.count ?? 0)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    if selectedFolder?.id == folder.id {
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        .dropDestination(for: String.self) { items, _ in
                            if let uuidString = items.first,
                               let uuid = UUID(uuidString: uuidString),
                               let draggedPiece = pieces.first(where: { $0.id == uuid }) {
                                draggedPiece.folder = folder // Asigna la obra a la carpeta destino
                                try? modelContext.save()
                                return true
                            }
                            return false
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                if selectedFolder?.id == folder.id {
                                    selectedFolder = nil
                                }
                                modelContext.delete(folder)
                            } label: {
                                Label("Eliminar", systemImage: "trash")
                            }
                        }
                    }

                    if folders.isEmpty {
                        Button(action: { isShowingFolderSheet = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "folder.badge.plus")
                                    .foregroundStyle(.secondary)
                                Text("Crear carpeta...")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    HStack {
                        Text("Mis Carpetas")
                        Spacer()
                        Button(action: { isShowingFolderSheet = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                Text("Nueva")
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Sección del Listado de Obras
                Section(header: Text(selectedFolder != nil ? "Obras en \(selectedFolder!.name)" : "Repertorio")) {
                    if filteredPieces.isEmpty {
                        Text(selectedFolder != nil ? "No hay obras en esta carpeta." : "No hay obras en el repertorio.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(filteredPieces) { piece in
                            NavigationLink(value: piece) {
                                HStack(alignment: .center, spacing: 8) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack(spacing: 6) {
                                            Text(piece.title)
                                                .font(.headline)
                                                .lineLimit(1)
                                            if !piece.key.isEmpty {
                                                Text("(\(piece.key))")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        Text(piece.composer)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }

                                    Spacer()

                                    HStack(spacing: 6) {
                                        if let folder = piece.folder, selectedFolder == nil {
                                            Image(systemName: "folder.fill")
                                                .font(.caption)
                                                .foregroundStyle(Color(hex: folder.colorHex))
                                        }

                                        Text(String(repeating: "★", count: piece.difficulty))
                                            .font(.caption2)
                                            .foregroundStyle(.orange)
                                    }
                                }
                            }
                            .draggable(piece.id.uuidString)
                        }
                        .onDelete(perform: deleteItems)
                    }
                }
            }
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Buscar en mi repertorio..."
            )
            .navigationTitle("OpusMarina")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        // 1. Añadir obra
                        Button(action: { isShowingAddSheet = true }) {
                            Image(systemName: "plus")
                        }

                        // 2. Catálogo online
                        Button(action: { isShowingDiscoverSheet = true }) {
                            Image(systemName: "globe")
                        }

                        // 3. Ordenación
                        Menu {
                            Picker("Ordenar por", selection: $sortOption) {
                                ForEach(PieceSortOption.allCases) { option in
                                    Label(option.rawValue, systemImage: option.systemImage)
                                        .tag(option)
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                        }

                        // 4. Ayuda
                        Button(action: { isShowingHelpSheet = true }) {
                            Image(systemName: "questionmark.circle")
                        }
                    }
                }
            }
        } detail: {
            if let selectedPiece = selectedPiece {
                PieceDetailView(piece: selectedPiece)
            } else {
                ContentUnavailableView(
                    "Selecciona una obra",
                    systemImage: "music.note",
                    description: Text("Elige una pieza del listado para ver sus detalles.")
                )
            }
        }
        .sheet(isPresented: $isShowingAddSheet) {
            AddPieceView(initialFolder: selectedFolder)
        }
        .sheet(isPresented: $isShowingDiscoverSheet) {
            DiscoverPiecesView()
        }
        .sheet(isPresented: $isShowingHelpSheet) {
            MaestroHelpSheet()
        }
        .sheet(isPresented: $isShowingFolderSheet) {
            FolderManagerSheet()
        }
        .onAppear {
            ensureUniquePieceIDs()
        }
    }
    
    private func ensureUniquePieceIDs() {
        var seenIDs = Set<UUID>()
        var hasDuplicates = false
        for piece in pieces {
            if !seenIDs.insert(piece.id).inserted {
                hasDuplicates = true
                break
            }
        }
        
        guard hasDuplicates else { return }
        
        for piece in pieces {
            piece.id = UUID()
        }
        try? modelContext.save()
    }
    
    private func deleteItems(offsets: IndexSet) {
        for index in offsets {
            let piece = filteredPieces[index]
            modelContext.delete(piece)
        }
        selectedPiece = nil
    }
}

struct PieceDetailView: View {
    @Bindable var piece: RepertoirePiece
    @Query(sort: \PieceFolder.createdAt, order: .forward) private var folders: [PieceFolder]
    
    @State private var isShowingSafari = false
    @State private var isShowingPDF = false
    @State private var isImportingPDF = false
    @State private var isShowingPracticeMode = false
    @State private var safariURL: URL?
    
    var pdfURL: URL? {
        guard let fileName = piece.pdfFileName else { return nil }
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls.first?.appendingPathComponent(fileName)
    }
    
    var body: some View {
        List {
            Section("Detalles") {
                LabeledContent("Compositor", value: piece.composer)
                if !piece.key.isEmpty {
                    LabeledContent("Tonalidad", value: piece.key)
                }
                LabeledContent("Época", value: piece.era.rawValue)
                LabeledContent("Estado", value: piece.status.rawValue)
                LabeledContent("Dificultad", value: String(repeating: "★", count: piece.difficulty))

                Picker("Carpeta", selection: $piece.folder) {
                    Text("Ninguna").tag(nil as PieceFolder?)
                    ForEach(folders) { folder in
                        HStack(spacing: 8) {
                            Image(systemName: "folder.fill")
                                .foregroundStyle(Color(hex: folder.colorHex))
                            Text(folder.name)
                        }
                        .tag(folder as PieceFolder?)
                    }
                }
            }
            
            Section("Práctica") {
                LabeledContent("Tiempo Total", value: piece.totalPracticeTime.formattedPracticeTime)
                
                Button(action: { isShowingPracticeMode = true }) {
                    Label("Iniciar Práctica", systemImage: "metronome")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor)
                        .cornerRadius(10)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            
            Section("Partitura") {
                if let url = pdfURL, FileManager.default.fileExists(atPath: url.path) {
                    Button(action: { isShowingPDF = true }) {
                        Label("Ver Partitura (PDF)", systemImage: "doc.richtext")
                            .font(.headline)
                    }
                    
                    Button(role: .destructive, action: {
                        try? FileManager.default.removeItem(at: url)
                        piece.pdfFileName = nil
                    }) {
                        Label("Eliminar PDF", systemImage: "trash")
                    }
                } else {
                    Button(action: { isImportingPDF = true }) {
                        Label("Adjuntar PDF...", systemImage: "plus.doc")
                    }
                }
            }
            
            if let notes = piece.studyNotes, !notes.isEmpty {
                Section("Notas de estudio") {
                    Text(notes)
                }
            }
            
            if let url = piece.webLink {
                Section("Enlaces") {
                    Button(action: {
                        safariURL = url
                        isShowingSafari = true
                    }) {
                        Label("Abrir enlace web", systemImage: "safari")
                    }
                }
            }

            // ── Recordings ────────────────────────────────────────────
            RecordingsView(piece: piece)
        }
        .navigationTitle(piece.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingSafari, content: {
            if let url = safariURL {
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        })
        .sheet(isPresented: $isShowingPDF, content: {
            if let url = pdfURL {
                ScoreViewerSheet(fileURL: url)
            }
        })
        .sheet(isPresented: $isShowingPracticeMode, content: {
            PracticeModeView(piece: piece)
        })
        .fileImporter(
            isPresented: $isImportingPDF,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            do {
                guard let selectedFile = try result.get().first else { return }
                
                if selectedFile.startAccessingSecurityScopedResource() {
                    defer { selectedFile.stopAccessingSecurityScopedResource() }
                    
                    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                    let fileName = UUID().uuidString + "-" + selectedFile.lastPathComponent
                    let destinationURL = documentsDirectory.appendingPathComponent(fileName)
                    
                    try FileManager.default.copyItem(at: selectedFile, to: destinationURL)
                    
                    if let oldFile = piece.pdfFileName {
                        let oldURL = documentsDirectory.appendingPathComponent(oldFile)
                        try? FileManager.default.removeItem(at: oldURL)
                    }
                    
                    piece.pdfFileName = fileName
                }
            } catch {
                print("Error importing PDF: \(error)")
            }
        }
    }
}

struct AddPieceView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \PieceFolder.createdAt, order: .forward) private var folders: [PieceFolder]
    
    var initialFolder: PieceFolder? = nil
    
    @State private var title = ""
    @State private var composer = ""
    @State private var key = ""
    @State private var era: MusicEra = .romantic
    @State private var status: LearningStatus = .toLearn
    @State private var difficulty = 3
    @State private var studyNotes = ""
    @State private var webLinkString = ""
    @State private var selectedFolder: PieceFolder?
    
    init(initialFolder: PieceFolder? = nil) {
        self.initialFolder = initialFolder
        _selectedFolder = State(initialValue: initialFolder)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Información principal") {
                    TextField("Título", text: $title)
                    TextField("Compositor", text: $composer)
                    TextField("Tonalidad (ej. Do menor / C minor)", text: $key)
                }
                
                Section("Clasificación") {
                    Picker("Carpeta", selection: $selectedFolder) {
                        Text("Ninguna").tag(nil as PieceFolder?)
                        ForEach(folders) { folder in
                            HStack(spacing: 8) {
                                Image(systemName: "folder.fill")
                                    .foregroundStyle(Color(hex: folder.colorHex))
                                Text(folder.name)
                            }
                            .tag(folder as PieceFolder?)
                        }
                    }
                    Picker("Época musical", selection: $era) {
                        ForEach(MusicEra.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Picker("Estado", selection: $status) {
                        ForEach(LearningStatus.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Stepper("Dificultad: \(difficulty) estrellas", value: $difficulty, in: 1...5)
                }
                
                Section("Detalles adicionales") {
                    TextField("Notas de estudio", text: $studyNotes, axis: .vertical)
                        .lineLimit(3...6)
                    TextField("Enlace web (URL)", text: $webLinkString)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("Nueva Obra")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        let url = URL(string: webLinkString)
                        let newPiece = RepertoirePiece(
                            title: title,
                            composer: composer,
                            key: key,
                            era: era,
                            status: status,
                            difficulty: difficulty,
                            studyNotes: studyNotes.isEmpty ? nil : studyNotes,
                            webLink: url,
                            folder: selectedFolder
                        )
                        modelContext.insert(newPiece)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || composer.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [RepertoirePiece.self, PieceFolder.self], inMemory: true)
}
