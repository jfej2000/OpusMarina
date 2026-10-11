import SwiftUI

struct MaestroHelpSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Header con El Maestro
                    HStack(spacing: 20) {
                        MaestroCharacterView()
                            .frame(width: 80, height: 100)
                            .padding(6)
                            .background(
                                Circle()
                                    .fill(Color.accentColor.opacity(0.12))
                            )
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("¡Hola, Marina!")
                                .font(.title2.bold())
                            Text("Soy tu Maestro musical. Aquí tienes la guía completa para sacar el máximo partido a tu estudio al piano con OpusMarina.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .padding(.horizontal)

                    // MARK: - Secciones de Ayuda
                    VStack(spacing: 16) {
                        HelpSectionCard(
                            icon: "music.note.list",
                            iconColor: .blue,
                            title: "🎼 Repertorio y Estados de Estudio",
                            description: "Organiza tus obras musicales con precisión:",
                            items: [
                                ("Por aprender", "Obras seleccionadas que planeas iniciar próximamente."),
                                ("En estudio", "Obras en las que trabajas activamente en el teclado."),
                                ("Aprendidas", "Piezas dominadas listas para interpretar en público o audición."),
                                ("Para repasar", "Obras aprendidas que necesitan mantenimiento técnico periódico."),
                                ("Épocas & Tonalidad", "Filtra por Barroco, Clasicismo, Romanticismo... y registra la tonalidad (ej. Do menor).")
                            ]
                        )

                        HelpSectionCard(
                            icon: "magnifyingglass",
                            iconColor: .purple,
                            title: "🔍 Catálogo Online (Open Opus e IMSLP)",
                            description: "Explora la biblioteca de música clásica universal:",
                            items: [
                                ("Búsqueda integrada", "Encuentra piezas por compositor o título desde la base de datos Open Opus."),
                                ("Añadir en 1 toque", "Importa la pieza con su época y metadatos con un solo botón."),
                                ("Acceso a IMSLP", "Enlace directo para descargar gratis la partitura en la biblioteca Petrucci.")
                            ]
                        )

                        HelpSectionCard(
                            icon: "metronome",
                            iconColor: .orange,
                            title: "⏱️ Modo Práctica y Metrónomo",
                            description: "Tu asistente de ritmo y registro de dedicación:",
                            items: [
                                ("Metrónomo flexible", "Ajusta de 40 a 240 BPM con precisión, controles + / - y pulsación háptica/visual."),
                                ("Compases clásicos", "Configura métricas de 2/4, 3/4, 4/4 o 6/8 con acento en el primer tiempo."),
                                ("Tiempo de estudio", "Inicia la sesión; el tiempo se sumará automáticamente al historial de la obra al finalizar.")
                            ]
                        )

                        HelpSectionCard(
                            icon: "doc.richtext",
                            iconColor: .red,
                            title: "📄 Partituras y Enlaces de Referencia",
                            description: "Ten siempre tus partituras sobre el atril digital:",
                            items: [
                                ("Importar PDF", "Adjunta partituras desde iCloud Drive o la app Archivos de tu iPad."),
                                ("Visor en atril", "Lee la partitura a pantalla completa sin distracciones mientras practicas."),
                                ("Enlaces web", "Guarda enlaces directos a grabaciones de referencia en YouTube o Spotify.")
                            ]
                        )

                        HelpSectionCard(
                            icon: "waveform.and.mic",
                            iconColor: .teal,
                            title: "🎙️ Grabadora de Ensayos",
                            description: "Escúchate y evalúa tu progreso al piano:",
                            items: [
                                ("Grabación de tomas", "Registra sesiones con el micrófono en alta fidelidad (.m4a)."),
                                ("Medidor de nivel", "Animación en tiempo real para asegurar un volumen óptimo sin distorsión."),
                                ("Historial de tomas", "Reproduce grabaciones anteriores por fecha y hora para analizar tu evolución.")
                            ]
                        )

                        HelpSectionCard(
                            icon: "chart.bar.xaxis",
                            iconColor: .green,
                            title: "📊 Estadísticas y Progreso",
                            description: "Visualiza tu crecimiento artístico:",
                            items: [
                                ("Tiempo acumulado", "Horas y minutos totales dedicados al piano."),
                                ("Distribución por época", "Gráfico circular de tu repertorio entre estilos históricos."),
                                ("Top Compositores", "Descubre a qué autores dedicas más tiempo de ensayo.")
                            ]
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Centro de Ayuda")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .help("Cerrar centro de ayuda")
                }
            }
        }
    }
}

// MARK: - Tarjeta de Sección de Ayuda
private struct HelpSectionCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let items: [(title: String, detail: String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3.bold())
                    .foregroundStyle(iconColor)
                    .frame(width: 32, height: 32)
                    .background(iconColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text(title)
                    .font(.headline)
            }

            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.title) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundStyle(iconColor)
                            .bold()
                        Text("**\(item.title):** \(item.detail)")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                }
            }
            .padding(.leading, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}
