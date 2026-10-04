import SwiftUI

struct MaestroCharacterView: View {
    @State private var isConducting = false
    
    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            
            ZStack {
                // Cabello
                Path { path in
                    path.move(to: CGPoint(x: w * 0.3, y: h * 0.2))
                    path.addQuadCurve(to: CGPoint(x: w * 0.15, y: h * 0.65), control: CGPoint(x: w * 0.1, y: h * 0.4))
                    path.addQuadCurve(to: CGPoint(x: w * 0.3, y: h * 0.75), control: CGPoint(x: w * 0.2, y: h * 0.75))
                    path.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.8), control: CGPoint(x: w * 0.4, y: h * 0.7))
                    path.addQuadCurve(to: CGPoint(x: w * 0.7, y: h * 0.75), control: CGPoint(x: w * 0.6, y: h * 0.7))
                    path.addQuadCurve(to: CGPoint(x: w * 0.85, y: h * 0.65), control: CGPoint(x: w * 0.8, y: h * 0.75))
                    path.addQuadCurve(to: CGPoint(x: w * 0.7, y: h * 0.2), control: CGPoint(x: w * 0.9, y: h * 0.4))
                    path.addQuadCurve(to: CGPoint(x: w * 0.3, y: h * 0.2), control: CGPoint(x: w * 0.5, y: h * 0.05))
                }
                .fill(Color(white: 0.15))
                
                // Rostro
                Ellipse()
                    .fill(Color(red: 0.98, green: 0.85, blue: 0.75))
                    .frame(width: w * 0.55, height: h * 0.6)
                    .position(x: w * 0.5, y: h * 0.45)
                
                // Ojos
                Circle().fill(.black).frame(width: w * 0.06).position(x: w * 0.38, y: h * 0.42)
                Circle().fill(.black).frame(width: w * 0.06).position(x: w * 0.62, y: h * 0.42)
                
                // Gafas (borde)
                Circle().stroke(Color.gray, lineWidth: 2).frame(width: w * 0.18).position(x: w * 0.38, y: h * 0.42)
                Circle().stroke(Color.gray, lineWidth: 2).frame(width: w * 0.18).position(x: w * 0.62, y: h * 0.42)
                Path { path in
                    path.move(to: CGPoint(x: w * 0.47, y: h * 0.42))
                    path.addLine(to: CGPoint(x: w * 0.53, y: h * 0.42))
                }.stroke(Color.gray, lineWidth: 2)
                
                // Perilla
                Path { path in
                    path.move(to: CGPoint(x: w * 0.43, y: h * 0.65))
                    path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.75))
                    path.addLine(to: CGPoint(x: w * 0.57, y: h * 0.65))
                    path.closeSubpath()
                }.fill(Color(white: 0.15))
                
                // Cuerpo (Frac)
                Path { path in
                    path.move(to: CGPoint(x: w * 0.15, y: h))
                    path.addLine(to: CGPoint(x: w * 0.35, y: h * 0.75))
                    path.addLine(to: CGPoint(x: w * 0.65, y: h * 0.75))
                    path.addLine(to: CGPoint(x: w * 0.85, y: h))
                    path.closeSubpath()
                }.fill(Color.black)
                
                // Camisa blanca interior
                Path { path in
                    path.move(to: CGPoint(x: w * 0.35, y: h * 0.75))
                    path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.95))
                    path.addLine(to: CGPoint(x: w * 0.65, y: h * 0.75))
                    path.closeSubpath()
                }.fill(Color.white)
                
                // Pajarita (roja oscura)
                Path { path in
                    path.move(to: CGPoint(x: w * 0.5, y: h * 0.78))
                    path.addLine(to: CGPoint(x: w * 0.42, y: h * 0.74))
                    path.addLine(to: CGPoint(x: w * 0.42, y: h * 0.82))
                    path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.78))
                    path.addLine(to: CGPoint(x: w * 0.58, y: h * 0.74))
                    path.addLine(to: CGPoint(x: w * 0.58, y: h * 0.82))
                    path.closeSubpath()
                }.fill(Color.red)
                
                // Brazo conduciendo
                ZStack {
                    // Manga
                    Path { path in
                        path.move(to: CGPoint(x: w * 0.75, y: h * 0.9))
                        path.addQuadCurve(to: CGPoint(x: w * 0.9, y: h * 0.65), control: CGPoint(x: w * 0.95, y: h * 0.85))
                    }
                    .stroke(Color.black, style: StrokeStyle(lineWidth: w * 0.1, lineCap: .round))
                    
                    // Mano
                    Circle()
                        .fill(Color(red: 0.98, green: 0.85, blue: 0.75))
                        .frame(width: w * 0.12)
                        .position(x: w * 0.9, y: h * 0.65)
                    
                    // Batuta
                    Path { path in
                        path.move(to: CGPoint(x: w * 0.9, y: h * 0.65))
                        path.addLine(to: CGPoint(x: w * 0.7, y: h * 0.3))
                    }
                    .stroke(Color(white: 0.9), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                }
                .rotationEffect(.degrees(isConducting ? 15 : -15), anchor: UnitPoint(x: 0.75, y: 0.9))
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                isConducting = true
            }
        }
    }
}
