import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query private var pieces: [RepertoirePiece]
    @Environment(\.dismiss) private var dismiss
    
    var totalPracticeTime: TimeInterval {
        pieces.reduce(0) { $0 + $1.totalPracticeTime }
    }
    
    var learnedPiecesCount: Int {
        pieces.filter { $0.status == .learned || $0.status == .toReview }.count
    }
    
    var eraDistribution: [EraStat] {
        var counts: [MusicEra: Int] = [:]
        for piece in pieces {
            counts[piece.era, default: 0] += 1
        }
        return counts.map { EraStat(era: $0.key.rawValue, count: $0.value) }.sorted(by: { $0.count > $1.count })
    }
    
    var statusDistribution: [StatusStat] {
        var counts: [LearningStatus: Int] = [:]
        for piece in pieces {
            counts[piece.status, default: 0] += 1
        }
        return counts.map { StatusStat(status: $0.key.rawValue, count: $0.value) }.sorted(by: { $0.count > $1.count })
    }
    
    var topComposers: [ComposerStat] {
        var counts: [String: Int] = [:]
        for piece in pieces {
            let name = piece.composer.trimmingCharacters(in: .whitespacesAndNewlines)
            counts[name, default: 0] += 1
        }
        return counts.map { ComposerStat(name: $0.key, count: $0.value) }.sorted(by: { $0.count > $1.count }).prefix(5).map { $0 }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Tarjetas de Resumen
                    HStack(spacing: 16) {
                        StatCard(title: "Obras", value: "\(pieces.count)", systemImage: "music.note.list")
                        StatCard(title: "Aprendidas", value: "\(learnedPiecesCount)", systemImage: "star.fill")
                        StatCard(title: "Tiempo Total", value: totalPracticeTime.formattedPracticeTime, systemImage: "clock.fill")
                    }
                    .padding(.horizontal)
                    
                    if pieces.isEmpty {
                        ContentUnavailableView("Sin Datos", systemImage: "chart.bar.xaxis", description: Text("Añade obras a tu repertorio para ver estadísticas."))
                    } else {
                        // Gráfico de Épocas
                        VStack(alignment: .leading) {
                            Text("Distribución por Época")
                                .font(.headline)
                            Chart(eraDistribution) { stat in
                                SectorMark(
                                    angle: .value("Cantidad", stat.count),
                                    innerRadius: .ratio(0.5),
                                    angularInset: 1.5
                                )
                                .cornerRadius(4)
                                .foregroundStyle(by: .value("Época", stat.era))
                                .annotation(position: .overlay) {
                                    Text("\(stat.count)")
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(height: 250)
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        // Gráfico de Estado de Estudio
                        VStack(alignment: .leading) {
                            Text("Progreso de Estudio")
                                .font(.headline)
                            Chart(statusDistribution) { stat in
                                BarMark(
                                    x: .value("Estado", stat.status),
                                    y: .value("Cantidad", stat.count)
                                )
                                .foregroundStyle(by: .value("Estado", stat.status))
                            }
                            .frame(height: 200)
                            .chartLegend(.hidden)
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        // Compositores Principales
                        VStack(alignment: .leading) {
                            Text("Top Compositores")
                                .font(.headline)
                            Chart(topComposers) { stat in
                                BarMark(
                                    x: .value("Cantidad", stat.count),
                                    y: .value("Compositor", stat.name)
                                )
                                .foregroundStyle(Color.accentColor)
                            }
                            .frame(height: 200)
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Estadísticas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let systemImage: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundColor(.accentColor)
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
}

struct EraStat: Identifiable {
    let id = UUID()
    let era: String
    let count: Int
}

struct StatusStat: Identifiable {
    let id = UUID()
    let status: String
    let count: Int
}

struct ComposerStat: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
}
