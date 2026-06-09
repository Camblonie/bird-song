//
//  AudioSessionManager.swift
//  Bird Song
//
//  Manages AVAudioEngine microphone capture and produces 3-second PCM buffers
//  for downstream bird classification.
//

import AVFoundation
import Combine

/// Manages the audio session and microphone capture pipeline.
/// Emits `audioBuffer` events on a background queue every ~3 seconds.
final class AudioSessionManager: ObservableObject {

    // MARK: - Published State

    /// Whether the mic is currently recording
    @Published private(set) var isListening: Bool = false

    // MARK: - Internal

    private let engine = AVAudioEngine()
    private let bufferSize: AVAudioFrameCount = 144_000  // 3 sec × 48 000 Hz
    private var accumulatedFrames: AVAudioFrameCount = 0
    private var accumulatedBuffer: AVAudioPCMBuffer?

    /// Callback fired with each 3-second PCM buffer (48 kHz, mono Float32)
    var onBuffer: ((AVAudioPCMBuffer) -> Void)?

    // MARK: - Public API

    /// Request microphone permission then start the engine.
    func startListening() {
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            guard granted else { return }
            DispatchQueue.main.async {
                self?.startEngine()
            }
        }
    }

    /// Stop mic capture and tear down the engine.
    func stopListening() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isListening = false
        accumulatedFrames = 0
        accumulatedBuffer = nil
    }

    // MARK: - Private

    private func startEngine() {
        do {
            // Configure audio session for measurement (quiet, minimal processing)
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setPreferredSampleRate(48_000)
            try session.setActive(true)

            let inputNode = engine.inputNode
            // Use native hardware format to avoid resampler overhead
            let inputFormat = inputNode.inputFormat(forBus: 0)

            // Install a tap that feeds small chunks into our accumulator
            inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
                self?.accumulate(buffer: buffer)
            }

            try engine.start()
            isListening = true
        } catch {
            print("[AudioSessionManager] Failed to start: \(error)")
        }
    }

    /// Accumulate incoming PCM frames into a running 3-second buffer.
    private func accumulate(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        let frameCount = buffer.frameLength

        // Lazily create the accumulator buffer using the tap's format
        if accumulatedBuffer == nil {
            accumulatedBuffer = AVAudioPCMBuffer(
                pcmFormat: buffer.format,
                frameCapacity: bufferSize
            )
        }
        guard let acc = accumulatedBuffer,
              let accData = acc.floatChannelData else { return }

        let channels = min(Int(buffer.format.channelCount), 1) // mono
        for ch in 0..<channels {
            let src = channelData[ch]
            let dst = accData[ch].advanced(by: Int(accumulatedFrames))
            let remaining = Int(bufferSize) - Int(accumulatedFrames)
            let toCopy = min(Int(frameCount), remaining)
            dst.update(from: src, count: toCopy)
        }

        accumulatedFrames += min(frameCount, AVAudioFrameCount(Int(bufferSize) - Int(accumulatedFrames)))

        // When we have a full 3-second window, fire the callback and reset
        if accumulatedFrames >= bufferSize {
            acc.frameLength = bufferSize
            onBuffer?(acc)
            accumulatedFrames = 0
            accumulatedBuffer = nil
        }
    }
}
