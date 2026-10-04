import SwiftUI

struct PracticeModeView: View {
    @Bindable var piece: RepertoirePiece
    @State private var metronome = MetronomeService()
    @State private var sessionSeconds: TimeInterval = 0
    @State private var isSessionActive = false
    @State private var timer: Timer?
    @State private var showingPDF = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                VStack {
                    Text(timeString(from: sessionSeconds))
                        .font(.system(size: 64, weight: .bold, design: .monospaced))
                    
                    HStack(spacing: 20) {
                        Button(action: toggleSession) {
                            Image(systemName: isSessionActive ? "pause.circle.fill" : "play.circle.fill")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundColor(isSessionActive ? .orange : .green)
                        }
                        
                        Button(action: endSession) {
                            Image(systemName: "stop.circle.fill")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(20)
                
                Circle()
                    .fill(metronome.currentBeat == 0 ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .scaleEffect(metronome.isPlaying ? 1.2 : 1.0)
                    .animation(.spring(response: 0.1, dampingFraction: 0.5), value: metronome.currentBeat)
                
                VStack(spacing: 15) {
                    Text("\(Int(metronome.bpm)) BPM")
                        .font(.title2.bold())
                    
                    Slider(value: $metronome.bpm, in: 40...240, step: 1)
                        .padding(.horizontal)
                    
                    HStack(spacing: 30) {
                        Button(action: { metronome.bpm = max(40, metronome.bpm - 1) }) {
                            Image(systemName: "minus.circle")
                                .font(.title)
                        }
                        
                        Button(action: {
                            if metronome.isPlaying {
                                metronome.stop()
                            } else {
                                metronome.start()
                            }
                        }) {
                            Image(systemName: metronome.isPlaying ? "metronome.fill" : "metronome")
                                .font(.system(size: 40))
                                .foregroundColor(metronome.isPlaying ? .accentColor : .primary)
                        }
                        
                        Button(action: { metronome.bpm = min(240, metronome.bpm + 1) }) {
                            Image(systemName: "plus.circle")
                                .font(.title)
                        }
                    }
                    
                    Picker("Compás", selection: $metronome.timeSignature) {
                        Text("2/4").tag(2)
                        Text("3/4").tag(3)
                        Text("4/4").tag(4)
                        Text("6/8").tag(6)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                }
                
                Spacer()
                
                if piece.pdfFileName != nil {
                    Button(action: { showingPDF.toggle() }) {
                        Label(showingPDF ? "Ocultar Partitura" : "Ver Partitura", systemImage: "doc.text")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
            .navigationTitle("Modo Práctica")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingPDF) {
                if let fileName = piece.pdfFileName,
                   let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName) {
                    ScoreViewerSheet(fileURL: url)
                }
            }
            .onDisappear {
                metronome.stop()
                if isSessionActive {
                    endSession()
                }
            }
        }
    }
    
    private func toggleSession() {
        isSessionActive.toggle()
        if isSessionActive {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                sessionSeconds += 1
            }
            if !metronome.isPlaying { metronome.start() }
        } else {
            timer?.invalidate()
            timer = nil
            metronome.stop()
        }
    }
    
    private func endSession() {
        isSessionActive = false
        timer?.invalidate()
        timer = nil
        metronome.stop()
        
        if sessionSeconds > 0 {
            piece.totalPracticeTime += sessionSeconds
            sessionSeconds = 0
        }
    }
    
    private func timeString(from seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
