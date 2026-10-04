import SwiftUI

struct MaestroGuideView: View {
    @Binding var isEnabled: Bool
    @State private var currentStep = 1
    let totalSteps = 5
    
    let messages = [
        "¡Hola Marina! Soy tu Maestro de música y te guiaré por OpusMarina.",
        "Aquí tienes tus piezas organizadas por épocas (barroca, romántica...) y estado.",
        "Usa la lupa para descubrir obras en el catálogo clásico de Open Opus e IMSLP.",
        "Carga tus PDF y activa mi metrónomo sonoro con cronómetro para estudiar.",
        "¡Y no olvides pasarte por las Estadísticas para observar tus horas y compositores dominados!"
    ]
    
    var body: some View {
        if isEnabled {
            VStack {
                Spacer()
                
                HStack(alignment: .bottom, spacing: 15) {
                    MaestroCharacterView()
                        .frame(width: 100, height: 100)
                        .shadow(radius: 5)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text(messages[currentStep - 1])
                            .font(.body)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        HStack {
                            Text("\(currentStep)/\(totalSteps)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            if currentStep > 1 {
                                Button("Anterior") {
                                    withAnimation { currentStep -= 1 }
                                }
                                .font(.caption.bold())
                                .buttonStyle(.bordered)
                            }
                            
                            if currentStep < totalSteps {
                                Button("Siguiente") {
                                    withAnimation { currentStep += 1 }
                                }
                                .font(.caption.bold())
                                .buttonStyle(.borderedProminent)
                            } else {
                                Button("Cerrar Guía") {
                                    withAnimation(.easeOut) { isEnabled = false }
                                }
                                .font(.caption.bold())
                                .buttonStyle(.borderedProminent)
                                .tint(.green)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.secondarySystemBackground))
                            .shadow(radius: 8)
                    )
                    .overlay(
                        Path { path in
                            path.move(to: CGPoint(x: -15, y: 50))
                            path.addLine(to: CGPoint(x: 0, y: 40))
                            path.addLine(to: CGPoint(x: 0, y: 60))
                            path.closeSubpath()
                        }
                        .fill(Color(UIColor.secondarySystemBackground))
                        , alignment: .leading
                    )
                }
                .padding()
                .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity.combined(with: .scale)))
            }
            .zIndex(100)
        }
    }
}
