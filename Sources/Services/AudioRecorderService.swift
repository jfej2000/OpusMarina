import Foundation
import AVFoundation
import Observation

@Observable
final class AudioRecorderService: NSObject {

    // MARK: - Public state
    var isRecording: Bool = false
    var isPlaying: Bool = false
    var recordingDuration: TimeInterval = 0
    /// Live audio power level in dBFS (0 = max, -160 = silence).
    var audioLevel: Float = -160

    // MARK: - Private
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var durationTimer: Timer?
    private var levelTimer: Timer?

    private let session = AVAudioSession.sharedInstance()

    // MARK: - Recording

    /// Requests microphone permission and starts recording.
    /// - Returns: The file name of the new recording, or nil on failure.
    func startRecording() async -> String? {
        // Request permission (iOS 17+ uses AVAudioApplication)
        let granted: Bool
        if #available(iOS 17.0, *) {
            granted = await AVAudioApplication.requestRecordPermission()
        } else {
            granted = await withCheckedContinuation { continuation in
                session.requestRecordPermission { allowed in
                    continuation.resume(returning: allowed)
                }
            }
        }
        guard granted else { return nil }

        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            print("AudioSession error: \(error)")
            return nil
        }

        let fileName = UUID().uuidString + ".m4a"
        guard let fileURL = documentsURL(for: fileName) else { return nil }

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            isRecording = true
            recordingDuration = 0

            startDurationTimer()
            startLevelTimer()
            return fileName
        } catch {
            print("Could not start recording: \(error)")
            return nil
        }
    }

    /// Stops the active recording and returns the final duration in seconds.
    @discardableResult
    func stopRecording() -> TimeInterval {
        let duration = recordingDuration
        audioRecorder?.stop()
        audioRecorder = nil
        stopTimers()
        isRecording = false
        audioLevel = -160

        try? session.setActive(false)
        return duration
    }

    // MARK: - Playback

    func play(recording: AudioRecording) {
        guard let url = recording.fileURL,
              FileManager.default.fileExists(atPath: url.path) else { return }

        stopPlayback()

        do {
            try session.setCategory(.playback)
            try session.setActive(true)
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            isPlaying = true
        } catch {
            print("Could not play recording: \(error)")
        }
    }

    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
    }

    func togglePlayback(for recording: AudioRecording) {
        if isPlaying {
            stopPlayback()
        } else {
            play(recording: recording)
        }
    }

    // MARK: - File management

    func deleteFile(for recording: AudioRecording) {
        guard let url = recording.fileURL else { return }
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Helpers

    private func documentsURL(for fileName: String) -> URL? {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(fileName)
    }

    private func startDurationTimer() {
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.recordingDuration += 1
        }
    }

    private func startLevelTimer() {
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.audioRecorder?.updateMeters()
            self?.audioLevel = self?.audioRecorder?.averagePower(forChannel: 0) ?? -160
        }
    }

    private func stopTimers() {
        durationTimer?.invalidate()
        durationTimer = nil
        levelTimer?.invalidate()
        levelTimer = nil
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioRecorderService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
    }
}
