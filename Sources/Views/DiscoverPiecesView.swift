import SwiftUI
import SwiftData

struct DiscoverPiecesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var service = OpenOpusService()
    @State private var searchText = ""
    @State private var addedPieceIDs: Set<String> = []
    
    var body: some View {
        NavigationStack {
            List {
                if service.isSearching {
                    HStack {
                        Spacer()
                        ProgressView("Buscando en Open Opus...")
                        Spacer()
                    }
                    .padding()
                } else if let error = service.errorMessage {
                    Text(error).foregroundStyle(.red)
                } else if service.searchResults.isEmpty && !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                    Text("No se encontraron resultados.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(service.searchResults) { result in
                        if let work = result.work, let composer = result.composer {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(work.title).font(.headline)
                                Text(composer.complete_name).font(.subheadline)
                                
                                HStack {
                                    Text(OpenOpusService.mapEpochToMusicEra(epoch: composer.epoch).rawValue)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.accentColor.opacity(0.2))
                                        .cornerRadius(8)
                                    
                                    Spacer()
                                    
                                    if let imslpURL = URL(string: "https://imslp.org/wiki/Special:Search?search=\(composer.name)+\(work.title)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") {
                                        Link("IMSLP", destination: imslpURL)
                                            .font(.caption)
                                            .buttonStyle(.bordered)
                                    }
                                    
                                    Button(action: {
                                        addPiece(work: work, composer: composer)
                                        addedPieceIDs.insert(result.id)
                                    }) {
                                        if addedPieceIDs.contains(result.id) {
                                            Label("Añadida", systemImage: "checkmark.circle.fill")
                                                .foregroundStyle(.green)
                                        } else {
                                            Label("Añadir", systemImage: "plus.circle")
                                        }
                                    }
                                    .disabled(addedPieceIDs.contains(result.id))
                                    .buttonStyle(.borderedProminent)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Descubrir Obras")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Buscar compositor o título...")
            .onChange(of: searchText) { _, newValue in
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    if searchText == newValue {
                        await service.search(query: newValue)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }
    
    private func addPiece(work: OpenOpusWork, composer: OpenOpusComposer) {
        let era = OpenOpusService.mapEpochToMusicEra(epoch: composer.epoch)
        let imslpLink = URL(string: "https://imslp.org/wiki/Special:Search?search=\(composer.name)+\(work.title)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")
        let newPiece = RepertoirePiece(
            title: work.title,
            composer: composer.complete_name,
            era: era,
            status: .toLearn,
            difficulty: 3,
            studyNotes: nil,
            webLink: imslpLink
        )
        modelContext.insert(newPiece)
    }
}

#Preview {
    DiscoverPiecesView()
}
