import SwiftUI
import SwiftData

// MARK: - Main recordings section view

struct RecordingsView: View {
    @Bindable var piece: RepertoirePiece
    @Environment(\.modelContext) private var modelContext

    @State private var recorder = AudioRecorderService()
    @State private var activeRecordingFileName: String?
    @State private var currentlyPlayingID: UUID?
    @State private var showPermissionAlert = false

    private var recordings: [AudioRecording] {
        (piece.recordings ?? []).sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        Section {
            // ── Record button ──────────────────────────────────────────
            RecordButton(
                isRecording: recorder.isRecording,
                duration: recorder.recordingDuration,
                audioLevel: recorder.audioLevel
            ) {
                Task { await toggleRecording() }
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))

            // ── Recordings list ────────────────────────────────────────
            if recordings.isEmpty && !recorder.isRecording {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "waveform.and.mic")
                            .font(.title2)
                            .foregroundStyle(.tertiary)
                        Text("Sin grabaciones aún")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
            } else {
                ForEach(recordings) { recording in
                    RecordingRow(
                        recording: recording,
                        isPlaying: currentlyPlayingID == recording.id && recorder.isPlaying
                    ) {
                        // Play / Pause
                        if currentlyPlayingID == recording.id {
                            recorder.stopPlayback()
                            currentlyPlayingID = nil
                        } else {
                            recorder.stopPlayback()
                            currentlyPlayingID = recording.id
                            recorder.play(recording: recording)
                        }
                    }
                }
                .onDelete { indexSet in
                    deleteRecordings(at: indexSet)
                }
            }
        } header: {
            Label("Ensayos y Grabaciones", systemImage: "waveform.and.mic")
        }
        .alert("Micrófono no disponible", isPresented: $showPermissionAlert) {
            Button("Abrir Ajustes") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("OpusMarina necesita acceso al micrófono. Actívalo en Ajustes > Privacidad > Micrófono.")
        }
    }

    // MARK: - Actions

    private func toggleRecording() async {
        if recorder.isRecording {
            let duration = recorder.stopRecording()
            if let fileName = activeRecordingFileName {
                let newRecording = AudioRecording(fileName: fileName, duration: duration)
                modelContext.insert(newRecording)
                if piece.recordings == nil { piece.recordings = [] }
                piece.recordings?.append(newRecording)
                activeRecordingFileName = nil
            }
        } else {
            recorder.stopPlayback()
            currentlyPlayingID = nil
            if let fileName = await recorder.startRecording() {
                activeRecordingFileName = fileName
            } else {
                showPermissionAlert = true
            }
        }
    }

    private func deleteRecordings(at offsets: IndexSet) {
        for index in offsets {
            let recording = recordings[index]
            recorder.deleteFile(for: recording)
            modelContext.delete(recording)
        }
    }
}

// MARK: - Record Button

private struct RecordButton: View {
    let isRecording: Bool
    let duration: TimeInterval
    let audioLevel: Float
    let action: () -> Void

    // Normalise dBFS (-60…0) → 0…1
    private var levelNorm: Double {
        Double(max(0, min(1, (audioLevel + 60) / 60)))
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isRecording ? Color.red.opacity(0.15) : Color.accentColor.opacity(0.12))
                        .frame(width: 52, height: 52)
                    Circle()
                        .fill(isRecording ? Color.red : Color.accentColor)
                        .frame(
                            width: isRecording ? 20 + levelNorm * 10 : 22,
                            height: isRecording ? 20 + levelNorm * 10 : 22
                        )
                        .animation(.easeInOut(duration: 0.1), value: levelNorm)
                    if isRecording {
                        Circle()
                            .stroke(Color.red.opacity(0.5), lineWidth: 2)
                            .frame(width: 42, height: 42)
                            .scaleEffect(1 + levelNorm * 0.3)
                            .opacity(1 - levelNorm * 0.3)
                            .animation(.easeOut(duration: 0.1), value: levelNorm)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(isRecording ? "Detener grabación" : "Iniciar grabación")
                        .font(.headline)
                        .foregroundStyle(isRecording ? .red : .primary)
                    if isRecording {
                        Text(formatDuration(duration))
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.red.opacity(0.8))
                    } else {
                        Text("Grabar esta sesión de práctica")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isRecording ? Color.red.opacity(0.07) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isRecording ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1.5)
                    )
            )
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }

    private func formatDuration(_ t: TimeInterval) -> String {
        let total = Int(t)
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Recording Row

private struct RecordingRow: View {
    let recording: AudioRecording
    let isPlaying: Bool
    let onPlayPause: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Play / Pause button
            Button(action: onPlayPause) {
                ZStack {
                    Circle()
                        .fill(isPlaying ? Color.accentColor : Color(.systemGray5))
                        .frame(width: 38, height: 38)
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isPlaying ? .white : .primary)
                        .offset(x: isPlaying ? 0 : 1)
                }
            }
            .buttonStyle(.plain)

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(recording.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline).fontWeight(.medium)
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(recording.formattedDuration)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }

            Spacer()

            if isPlaying {
                WaveformAnimationView()
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Animated waveform indicator

private struct WaveformAnimationView: View {
    @State private var animating = false
    private let barCount = 4
    private let barHeights: [CGFloat] = [8, 14, 10, 16]

    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            ForEach(0..<barCount, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.accentColor)
                    .frame(width: 3, height: animating ? barHeights[i] : 4)
                    .animation(
                        .easeInOut(duration: 0.4)
                            .repeatForever()
                            .delay(Double(i) * 0.1),
                        value: animating
                    )
            }
        }
        .frame(height: 20)
        .onAppear { animating = true }
        .onDisappear { animating = false }
    }
}
