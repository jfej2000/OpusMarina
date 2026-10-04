import Foundation
import AVFoundation
import Observation

@Observable
class MetronomeService {
    var bpm: Double = 100 {
        didSet {
            if isPlaying {
                stop()
                start()
            }
        }
    }
    var timeSignature: Int = 4
    var isPlaying = false
    var currentBeat = 0
    
    private var timer: Timer?
    private var engine = AVAudioEngine()
    private var highPlayer = AVAudioPlayerNode()
    private var lowPlayer = AVAudioPlayerNode()
    private var clickBufferHigh: AVAudioPCMBuffer?
    private var clickBufferLow: AVAudioPCMBuffer?
    
    init() {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        clickBufferHigh = generateClick(format: format, frequency: 880)
        clickBufferLow = generateClick(format: format, frequency: 440)
        
        engine.attach(highPlayer)
        engine.attach(lowPlayer)
        engine.connect(highPlayer, to: engine.mainMixerNode, format: format)
        engine.connect(lowPlayer, to: engine.mainMixerNode, format: format)
        
        try? engine.start()
    }
    
    private func generateClick(format: AVAudioFormat, frequency: Float) -> AVAudioPCMBuffer {
        let sampleRate = Float(format.sampleRate)
        let length = AVAudioFrameCount(sampleRate * 0.05)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: length)!
        buffer.frameLength = length
        
        let channels = buffer.floatChannelData!
        for i in 0..<Int(length) {
            let phase = Float(i) / sampleRate * frequency * 2.0 * .pi
            let envelope = exp(-Float(i) / (sampleRate * 0.015))
            channels[0][i] = sin(phase) * envelope
        }
        return buffer
    }
    
    func start() {
        guard !isPlaying else { return }
        isPlaying = true
        currentBeat = 0
        
        if !engine.isRunning {
            try? engine.start()
        }
        
        let interval = 60.0 / bpm
        playClick()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.playClick()
        }
    }
    
    func stop() {
        isPlaying = false
        timer?.invalidate()
        timer = nil
    }
    
    private func playClick() {
        if currentBeat == 0 {
            highPlayer.stop()
            if let buffer = clickBufferHigh {
                highPlayer.scheduleBuffer(buffer, at: nil)
            }
            highPlayer.play()
        } else {
            lowPlayer.stop()
            if let buffer = clickBufferLow {
                lowPlayer.scheduleBuffer(buffer, at: nil)
            }
            lowPlayer.play()
        }
        currentBeat = (currentBeat + 1) % timeSignature
    }
}
