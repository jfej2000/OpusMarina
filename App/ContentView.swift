import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var pieces: [RepertoirePiece]
    
    @State private var selectedEra: MusicEra? = nil
    @State private var selectedStatus: LearningStatus? = nil
    @State private var isShowingAddSheet = false
    @State private var isShowingDiscoverSheet = false
    @State private var isShowingStatsSheet = false
    @State private var selectedPiece: RepertoirePiece?
    
    var filteredPieces: [RepertoirePiece] {
        pieces.filter { piece in
            let matchesEra = (selectedEra == nil) || (piece.era == selectedEra)
            let matchesStatus = (selectedStatus == nil) || (piece.status == selectedStatus)
            return matchesEra && matchesStatus
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
                
                Section("Repertorio") {
                    if filteredPieces.isEmpty {
                        Text("No hay obras que coincidan.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(filteredPieces) { piece in
                            NavigationLink(value: piece) {
                                VStack(alignment: .leading) {
                                    Text(piece.title).font(.headline)
                                    Text(piece.composer).font(.subheadline).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                }
            }
            .navigationTitle("OpusMarina")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack {
                        Button(action: { isShowingStatsSheet = true }) {
                            Label("Estadísticas", systemImage: "chart.bar.xaxis")
                        }
                        Button(action: { isShowingDiscoverSheet = true }) {
                            Label("Descubrir", systemImage: "magnifyingglass")
                        }
                        Button(action: { isShowingAddSheet = true }) {
                            Label("Añadir", systemImage: "plus")
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
            AddPieceView()
        }
        .sheet(isPresented: $isShowingDiscoverSheet) {
            DiscoverPiecesView()
        }
        .sheet(isPresented: $isShowingStatsSheet) {
            StatsView()
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
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        let url = URL(string: webLinkString)
                        let newPiece = RepertoirePiece(
                            title: title,
                            composer: composer,
                            era: era,
                            status: status,
                            difficulty: difficulty,
                            studyNotes: studyNotes.isEmpty ? nil : studyNotes,
                            webLink: url
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
        .modelContainer(for: RepertoirePiece.self, inMemory: true)
}
