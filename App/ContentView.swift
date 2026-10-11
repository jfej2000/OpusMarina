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
    @State private var selectedEra: MusicEra? = nil
    @State private var selectedStatus: LearningStatus? = nil
    @State private var searchText = ""
    @State private var sortOption: PieceSortOption = .titleAsc
    @State private var isShowingAddSheet = false
    @State private var isShowingDiscoverSheet = false
    @State private var isShowingStatsSheet = false
    @State private var isShowingHelpSheet = false
    @State private var selectedPiece: RepertoirePiece?
    
    var filteredPieces: [RepertoirePiece] {
        let filtered = pieces.filter { piece in
            let matchesEra = (selectedEra == nil) || (piece.era == selectedEra)
            let matchesStatus = (selectedStatus == nil) || (piece.status == selectedStatus)
            guard matchesEra && matchesStatus else { return false }
            
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
                Section("Filtros") {
                    Picker("Época", selection: $selectedEra) {
                        Text("Todas").tag(MusicEra?(nil))
                        ForEach(MusicEra.allCases) { era in
                            Text(era.rawValue).tag(MusicEra?(era))
                        }
                    }
                    
                    Picker("Estado", selection: $selectedStatus) {
                        Text("Todos").tag(LearningStatus?(nil))
                        ForEach(LearningStatus.allCases) { status in
                            Text(status.rawValue).tag(LearningStatus?(status))
                        }
                    }
                }
                
                Section("Repertorio (\(filteredPieces.count))") {
                    if filteredPieces.isEmpty {
                        Text("No hay obras que coincidan.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(filteredPieces) { piece in
                            NavigationLink(value: piece) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(piece.title).font(.headline)
                                        if !piece.key.isEmpty {
                                            Text("(\(piece.key))")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    HStack {
                                        Text(piece.composer).font(.subheadline).foregroundStyle(.secondary)
                                        Spacer()
                                        Text(String(repeating: "★", count: piece.difficulty))
                                            .font(.caption2)
                                            .foregroundStyle(.orange)
                                    }
                                }
                            }
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
            .searchSuggestions {
                if searchText.isEmpty {
                    Label("Barroco", systemImage: "music.note").searchCompletion("Barroco")
                    Label("Clasicismo", systemImage: "music.note").searchCompletion("Clasicismo")
                    Label("Romanticismo", systemImage: "music.note").searchCompletion("Romanticismo")
                    Label("En estudio", systemImage: "pencil.and.outline").searchCompletion("En estudio")
                }
            }
            .navigationTitle("OpusMarina")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Picker("Ordenar por", selection: $sortOption) {
                            ForEach(PieceSortOption.allCases) { option in
                                Label(option.rawValue, systemImage: option.systemImage)
                                    .tag(option)
                            }
                        }
                    } label: {
                        Label("Ordenar", systemImage: "arrow.up.arrow.down")
                    }
                    .help("Ordenar repertorio")

                    Button(action: { isShowingDiscoverSheet = true }) {
                        Label("Descubrir online", systemImage: "globe")
                    }
                    .help("Explorar catálogo online (Open Opus / IMSLP)")

                    Button(action: { isShowingStatsSheet = true }) {
                        Label("Estadísticas", systemImage: "chart.bar.xaxis")
                    }
                    .help("Ver estadísticas y progreso")

                    Button(action: { isShowingAddSheet = true }) {
                        Label("Añadir", systemImage: "plus")
                    }
                    .help("Añadir nueva obra")

                    Button(action: { isShowingHelpSheet = true }) {
                        Label("Ayuda", systemImage: "questionmark.circle")
                    }
                    .help("Centro de ayuda y guía")
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
            AddPieceView()
        }
        .sheet(isPresented: $isShowingDiscoverSheet) {
            DiscoverPiecesView()
        }
        .sheet(isPresented: $isShowingStatsSheet) {
            StatsView()
        }
        .sheet(isPresented: $isShowingHelpSheet) {
            MaestroHelpSheet()
        }
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
                .help("Iniciar sesión de práctica y metrónomo")
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            
            Section("Partitura") {
                if let url = pdfURL, FileManager.default.fileExists(atPath: url.path) {
                    Button(action: { isShowingPDF = true }) {
                        Label("Ver Partitura (PDF)", systemImage: "doc.richtext")
                            .font(.headline)
                    }
                    .help("Ver partitura en PDF")
                    
                    Button(role: .destructive, action: {
                        try? FileManager.default.removeItem(at: url)
                        piece.pdfFileName = nil
                    }) {
                        Label("Eliminar PDF", systemImage: "trash")
                    }
                    .help("Eliminar partitura PDF")
                } else {
                    Button(action: { isImportingPDF = true }) {
                        Label("Adjuntar PDF...", systemImage: "plus.doc")
                    }
                    .help("Adjuntar partitura en PDF")
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
                    .help("Abrir enlace web de referencia")
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
    
    @State private var title = ""
    @State private var composer = ""
    @State private var key = ""
    @State private var era: MusicEra = .romantic
    @State private var status: LearningStatus = .toLearn
    @State private var difficulty = 3
    @State private var studyNotes = ""
    @State private var webLinkString = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Información principal") {
                    TextField("Título", text: $title)
                    TextField("Compositor", text: $composer)
                    TextField("Tonalidad (ej. Do menor / C minor)", text: $key)
                }
                
                Section("Clasificación") {
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
                        .help("Cancelar y cerrar")
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
                            webLink: url
                        )
                        modelContext.insert(newPiece)
                        dismiss()
                    }
                    .help("Guardar obra en el repertorio")
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || composer.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: RepertoirePiece.self, inMemory: true)
}
