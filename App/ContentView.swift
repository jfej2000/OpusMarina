import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var pieces: [RepertoirePiece]
    
    @State private var selectedEra: MusicEra? = nil
    @State private var selectedStatus: LearningStatus? = nil
    @State private var isShowingAddSheet = false
    @State private var isShowingDiscoverSheet = false
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
    let piece: RepertoirePiece
    
    var body: some View {
        List {
            Section("Detalles") {
                LabeledContent("Compositor", value: piece.composer)
                LabeledContent("Época", value: piece.era.rawValue)
                LabeledContent("Estado", value: piece.status.rawValue)
                LabeledContent("Dificultad", value: String(repeating: "★", count: piece.difficulty))
            }
            
            if let notes = piece.studyNotes, !notes.isEmpty {
                Section("Notas de estudio") {
                    Text(notes)
                }
            }
            
            if let url = piece.webLink {
                Section("Enlaces") {
                    Link("Abrir partitura/vídeo", destination: url)
                }
            }
        }
        .navigationTitle(piece.title)
        .navigationBarTitleDisplayMode(.inline)
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
