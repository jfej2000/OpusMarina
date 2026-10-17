import SwiftUI
import SwiftData

struct FolderManagerSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \PieceFolder.createdAt, order: .forward)
    private var existingFolders: [PieceFolder]

    @State private var name: String = ""
    @State private var colorHex: String = PieceFolder.defaultColorHex
    @State private var customColor: Color = Color(hex: PieceFolder.defaultColorHex)

    var body: some View {
        NavigationStack {
            Form {
                Section("Datos de la carpeta") {
                    TextField("Nombre (ej. Recital 2026, Estudios, Conciertos...)", text: $name)
                }

                Section("Color distintivo") {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Colores sugeridos")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 16) {
                            ForEach(PieceFolder.presetColors, id: \.hex) { preset in
                                Button(action: {
                                    colorHex = preset.hex
                                    customColor = preset.color
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(preset.color)
                                            .frame(width: 38, height: 38)
                                        
                                        if colorHex.uppercased() == preset.hex.uppercased() {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 4)

                        Divider()

                        ColorPicker("Color personalizado", selection: $customColor, supportsOpacity: false)
                            .onChange(of: customColor) { _, newColor in
                                colorHex = newColor.toHex()
                            }
                    }
                    .padding(.vertical, 4)
                }

                Section("Vista previa") {
                    HStack(spacing: 14) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Color(hex: colorHex))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(name.trimmingCharacters(in: .whitespaces).isEmpty ? "Nombre de la carpeta" : name)
                                .font(.headline)
                                .foregroundStyle(name.trimmingCharacters(in: .whitespaces).isEmpty ? .secondary : .primary)
                            Text("0 obras")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }

                if !existingFolders.isEmpty {
                    Section("Carpetas existentes") {
                        ForEach(existingFolders) { folder in
                            HStack(spacing: 12) {
                                Image(systemName: "folder.fill")
                                    .foregroundStyle(Color(hex: folder.colorHex))
                                Text(folder.name)
                                    .font(.body)
                                Spacer()
                                Text("\(folder.pieces?.count ?? 0) obras")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onDelete(perform: deleteFolders)
                    }
                }
            }
            .navigationTitle("Nueva Carpeta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !cleanName.isEmpty else { return }
                        let newFolder = PieceFolder(name: cleanName, colorHex: colorHex)
                        modelContext.insert(newFolder)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func deleteFolders(offsets: IndexSet) {
        for index in offsets {
            let folder = existingFolders[index]
            modelContext.delete(folder)
        }
    }
}
