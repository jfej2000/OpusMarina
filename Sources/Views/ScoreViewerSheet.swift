import SwiftUI

struct ScoreViewerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let fileURL: URL
    
    var body: some View {
        NavigationStack {
            PDFKitView(url: fileURL)
                .navigationTitle(fileURL.lastPathComponent)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cerrar") { dismiss() }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        ShareLink(item: fileURL) {
                            Label("Compartir", systemImage: "square.and.arrow.up")
                        }
                    }
                }
        }
    }
}
