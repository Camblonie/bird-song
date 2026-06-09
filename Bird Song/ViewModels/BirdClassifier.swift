//
//  BirdClassifier.swift
//  Bird Song
//
//  Wraps BirdNET CoreML inference and returns all species above a confidence
//  threshold. Uses a mock implementation until the real .mlmodel is added.
//
//  To swap in the real model:
//    1. Run scripts/convert_birdnet_to_coreml.py to produce BirdNET.mlpackage
//       and BirdNET_Labels.json.
//    2. Drag both files into Xcode (add to Bird Song target).
//    3. Set USE_REAL_MODEL = true below.
//

import AVFoundation
import Accelerate
import CoreML
import Combine

/// A single classification result from the BirdNET model.
struct DetectedBird: Identifiable, Equatable {
    let id: UUID = UUID()
    let bird: Bird
    let confidence: Double
    /// Timestamp of detection — used for debounce expiry
    let detectedAt: Date = Date()

    static func == (lhs: DetectedBird, rhs: DetectedBird) -> Bool {
        lhs.bird.id == rhs.bird.id
    }
}

/// Runs inference on 3-second audio buffers and publishes detected birds.
final class BirdClassifier: ObservableObject {

    // MARK: - Configuration

    /// Minimum confidence to surface a detection (0–1)
    static let confidenceThreshold: Double = 0.70
    /// How many seconds a card remains visible after the last detection
    static let debounceSeconds: Double = 5.0

    /// Inference mode selection:
    ///   .mock   — random birds, no audio analysis (default)
    ///   .api    — BirdNET-Analyzer REST server (set serverURL in BirdNETAPIService)
    ///   .coreML — on-device CoreML model (requires BirdNET.mlpackage in bundle)
    enum InferenceMode { case mock, api, coreML }
    private static let inferenceMode: InferenceMode = .api

    // MARK: - Published State

    /// Currently active detections, updated on the main thread
    @Published private(set) var activeDetections: [DetectedBird] = []

    // MARK: - Private

    private var debounceTimers: [String: Timer] = [:]
    /// Holds the last detections so the mock can cycle through species
    private var mockCycleIndex: Int = 0

    // MARK: - Public API

    /// Process one 3-second PCM buffer and update activeDetections.
    func classifyBuffer(_ buffer: AVAudioPCMBuffer) {
        switch Self.inferenceMode {
        case .mock:   runMockInference()
        case .api:    runAPIInference(buffer)
        case .coreML: runCoreMLInference(buffer)
        }
    }

    /// Remove a specific detection immediately (e.g. after user logs it).
    func dismiss(_ detection: DetectedBird) {
        DispatchQueue.main.async { [weak self] in
            self?.activeDetections.removeAll { $0.id == detection.id }
            self?.debounceTimers[detection.bird.id]?.invalidate()
            self?.debounceTimers.removeValue(forKey: detection.bird.id)
        }
    }

    // MARK: - Mock Inference

    /// Cycles through catalog species in small groups to simulate multi-bird detection.
    private func runMockInference() {
        let catalog = BirdCatalog.all
        guard !catalog.isEmpty else { return }

        // Cycle through pairs of birds to demonstrate multi-bird display
        let count = catalog.count
        let idx1 = mockCycleIndex % count
        let idx2 = (mockCycleIndex + 1) % count
        mockCycleIndex = (mockCycleIndex + 2) % count

        let fakeResults: [(bird: Bird, confidence: Double)] = [
            (catalog[idx1], Double.random(in: 0.72...0.98)),
            (catalog[idx2], Double.random(in: 0.71...0.95)),
        ]
        applyResults(fakeResults)
    }

    // MARK: - API Inference

    /// Send buffer to the BirdNET-Analyzer REST server and apply results.
    private func runAPIInference(_ buffer: AVAudioPCMBuffer) {
        BirdNETAPIService.analyze(buffer: buffer) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let apiResults):
                // Convert BirdNETResult labels → (Bird, confidence) pairs
                // BirdNET label format: "Turdus migratorius_American Robin"
                // BirdCatalog.birdNETLabel format: "American Robin_Turdus migratorius"
                // We match by checking if the catalog label's words appear in the server label.
                let matched: [(bird: Bird, confidence: Double)] = apiResults.compactMap { r in
                    guard r.confidence >= Self.confidenceThreshold else { return nil }
                    guard let bird = BirdCatalog.bird(forAPILabel: r.label) else { return nil }
                    return (bird: bird, confidence: r.confidence)
                }
                self.applyResults(matched)

            case .failure(let error):
                print("[BirdClassifier] API error: \(error.localizedDescription)")
                // Fall back to mock so the UI stays active during development
                self.runMockInference()
            }
        }
    }

    // MARK: - CoreML Inference

    /// Lazy-loaded BirdNET model — nil until BirdNET.mlpackage is added to the bundle.
    private lazy var birdNETModel: MLModel? = {
        guard let url = Bundle.main.url(forResource: "BirdNET", withExtension: "mlmodelc")
                     ?? Bundle.main.url(forResource: "BirdNET", withExtension: "mlpackage") else {
            print("[BirdClassifier] BirdNET.mlpackage not found in bundle.")
            return nil
        }
        return try? MLModel(contentsOf: url)
    }()

    /// Lazy-loaded species labels from BirdNET_Labels.json bundled with the app.
    private lazy var birdNETLabels: [String] = {
        guard let url = Bundle.main.url(forResource: "BirdNET_Labels", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let labels = try? JSONDecoder().decode([String].self, from: data) else {
            print("[BirdClassifier] BirdNET_Labels.json not found in bundle.")
            return []
        }
        return labels
    }()

    // MARK: BirdNET spectrogram constants (V2.4)
    private let sampleRate: Double  = 48_000
    private let nFFT: Int           = 1024
    private let hopSize: Int        = 280
    private let nMelBins: Int       = 96
    private let specWidth: Int      = 511   // time frames in the model input
    // Channel 0: low-frequency band 0–3 kHz
    private let fminLow: Double     = 0.0
    private let fmaxLow: Double     = 3_000.0
    // Channel 1: high-frequency band 500 Hz–15 kHz
    private let fminHigh: Double    = 500.0
    private let fmaxHigh: Double    = 15_000.0

    /// Full BirdNET CoreML inference path.
    private func runCoreMLInference(_ buffer: AVAudioPCMBuffer) {
        guard let model = birdNETModel, !birdNETLabels.isEmpty else {
            print("[BirdClassifier] Model or labels not loaded — falling back to mock.")
            runMockInference()
            return
        }
        guard let channelData = buffer.floatChannelData else { return }

        // Extract mono Float32 samples, normalized to [-1, 1]
        let frameCount = Int(buffer.frameLength)
        var samples = Array(UnsafeBufferPointer(start: channelData[0], count: frameCount))
        normalizeAudio(&samples)

        // Build two-channel mel spectrogram: shape [1, 2, 96, 511]
        guard let inputArray = buildSpectrogram(samples: samples) else {
            print("[BirdClassifier] Failed to build spectrogram.")
            return
        }

        // Run inference
        do {
            let input  = try MLDictionaryFeatureProvider(dictionary: ["input": inputArray])
            let output = try model.prediction(from: input)

            // Parse output — CoreML classifier models expose classLabel_probs
            var results: [(bird: Bird, confidence: Double)] = []

            if let probs = output.featureValue(for: "classLabel_probs")?.dictionaryValue as? [String: Double] {
                // Filter to catalog species only and apply threshold
                let labelSet = BirdCatalog.labelSet
                for (label, confidence) in probs {
                    guard confidence >= Self.confidenceThreshold,
                          labelSet.contains(label),
                          let bird = BirdCatalog.bird(forLabel: label) else { continue }
                    results.append((bird: bird, confidence: confidence))
                }
            }

            results.sort { $0.confidence > $1.confidence }
            applyResults(results)

        } catch {
            print("[BirdClassifier] Inference error: \(error)")
        }
    }

    // MARK: - Mel Spectrogram Builder

    /// Normalise audio samples to [-1, 1] in-place.
    private func normalizeAudio(_ samples: inout [Float]) {
        var maxVal: Float = 0
        vDSP_maxmgv(samples, 1, &maxVal, vDSP_Length(samples.count))
        guard maxVal > 0 else { return }
        var scale = 1.0 / maxVal
        vDSP_vsmul(samples, 1, &scale, &samples, 1, vDSP_Length(samples.count))
    }

    /// Build the two-channel mel spectrogram MLMultiArray expected by BirdNET V2.4.
    /// Returns shape [1, 2, nMelBins, specWidth] = [1, 2, 96, 511].
    private func buildSpectrogram(samples: [Float]) -> MLMultiArray? {
        let shape: [NSNumber] = [1, 2, NSNumber(value: nMelBins), NSNumber(value: specWidth)]
        guard let array = try? MLMultiArray(shape: shape, dataType: .float32) else { return nil }

        // Channel 0 — low band (0–3 kHz)
        let ch0 = melSpectrogram(samples: samples, fmin: fminLow, fmax: fmaxLow)
        // Channel 1 — high band (500 Hz–15 kHz)
        let ch1 = melSpectrogram(samples: samples, fmin: fminHigh, fmax: fmaxHigh)

        // Write both channels into the MLMultiArray [1, 2, 96, 511]
        for (chIdx, spec) in [ch0, ch1].enumerated() {
            for mel in 0..<nMelBins {
                for t in 0..<specWidth {
                    let idx = chIdx * nMelBins * specWidth + mel * specWidth + t
                    let val: Float = (t < spec.count && mel < spec[0].count) ? spec[t][mel] : 0
                    array[idx] = NSNumber(value: val)
                }
            }
        }
        return array
    }

    /// Compute a mel spectrogram for a given frequency band.
    /// Returns a [timeFrames × nMelBins] matrix.
    private func melSpectrogram(samples: [Float], fmin: Double, fmax: Double) -> [[Float]] {
        let frameCount = samples.count
        let n          = nFFT
        let hop        = hopSize
        let numFrames  = max(0, (frameCount - n) / hop + 1)

        // Pre-build Hann window
        var window = [Float](repeating: 0, count: n)
        vDSP_hann_window(&window, vDSP_Length(n), Int32(vDSP_HANN_NORM))

        // Build mel filterbank
        let filterbank = melFilterbank(nFFT: n, nMels: nMelBins, sampleRate: sampleRate, fmin: fmin, fmax: fmax)

        // FFT setup (size n, half-complex output n/2+1)
        let log2n = vDSP_Length(log2(Float(n)))
        guard let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else { return [] }
        defer { vDSP_destroy_fftsetup(fftSetup) }

        var spectrogram = [[Float]]()
        spectrogram.reserveCapacity(numFrames)

        var realPart = [Float](repeating: 0, count: n / 2)
        var imagPart = [Float](repeating: 0, count: n / 2)

        for frameIdx in 0..<numFrames {
            let start = frameIdx * hop

            // Windowed frame
            var frame = [Float](repeating: 0, count: n)
            let available = min(n, frameCount - start)
            frame.withUnsafeMutableBufferPointer { fBuf in
                samples.withUnsafeBufferPointer { sBuf in
                    cblas_scopy(Int32(available), sBuf.baseAddress! + start, 1, fBuf.baseAddress!, 1)
                }
            }
            vDSP_vmul(frame, 1, window, 1, &frame, 1, vDSP_Length(n))

            // FFT
            var splitComplex = DSPSplitComplex(realp: &realPart, imagp: &imagPart)
            frame.withUnsafeBytes { rawBytes in
                let floatPtr = rawBytes.bindMemory(to: DSPComplex.self)
                vDSP_ctoz(floatPtr.baseAddress!, 2, &splitComplex, 1, vDSP_Length(n / 2))
            }
            vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2n, FFTDirection(FFT_FORWARD))

            // Power spectrum |FFT|^2 — shape [n/2 + 1]
            var power = [Float](repeating: 0, count: n / 2 + 1)
            power[0]       = realPart[0] * realPart[0]                 // DC
            power[n / 2]   = imagPart[0] * imagPart[0]                 // Nyquist
            for k in 1..<(n / 2) {
                power[k] = realPart[k] * realPart[k] + imagPart[k] * imagPart[k]
            }

            // Apply mel filterbank → [nMelBins] energy values
            var melEnergies = [Float](repeating: 0, count: nMelBins)
            for m in 0..<nMelBins {
                var energy: Float = 0
                vDSP_dotpr(power, 1, filterbank[m], 1, &energy, vDSP_Length(n / 2 + 1))
                // Non-linear magnitude scaling (BirdNET: log1p-like)
                melEnergies[m] = log(max(energy, 1e-10))
            }

            spectrogram.append(melEnergies)
        }

        // Pad or trim to exactly specWidth frames
        var result = [[Float]](repeating: [Float](repeating: 0, count: nMelBins), count: specWidth)
        let copyCount = min(spectrogram.count, specWidth)
        for i in 0..<copyCount { result[i] = spectrogram[i] }

        return result
    }

    /// Build a triangular mel filterbank.
    /// Returns a [nMels × (nFFT/2 + 1)] matrix of filter weights.
    private func melFilterbank(nFFT: Int, nMels: Int, sampleRate: Double, fmin: Double, fmax: Double) -> [[Float]] {
        func hzToMel(_ hz: Double) -> Double { 2595.0 * log10(1.0 + hz / 700.0) }
        func melToHz(_ mel: Double) -> Double { 700.0 * (pow(10.0, mel / 2595.0) - 1.0) }

        let melMin = hzToMel(fmin)
        let melMax = hzToMel(fmax)

        // nMels + 2 evenly-spaced mel points
        let melPoints = (0...(nMels + 1)).map { i -> Double in
            melMin + Double(i) * (melMax - melMin) / Double(nMels + 1)
        }
        // Convert to Hz, then to FFT bin indices
        let hzPoints = melPoints.map { melToHz($0) }
        let bins = hzPoints.map { Int(floor($0 / sampleRate * Double(nFFT + 1))) }

        var filterbank = [[Float]](repeating: [Float](repeating: 0, count: nFFT / 2 + 1), count: nMels)

        for m in 0..<nMels {
            let lo  = bins[m]
            let ctr = bins[m + 1]
            let hi  = bins[m + 2]
            for k in lo..<ctr {
                guard k < nFFT / 2 + 1 else { break }
                filterbank[m][k] = Float(Double(k - lo) / Double(max(ctr - lo, 1)))
            }
            for k in ctr..<hi {
                guard k < nFFT / 2 + 1 else { break }
                filterbank[m][k] = Float(Double(hi - k) / Double(max(hi - ctr, 1)))
            }
        }
        return filterbank
    }

    // MARK: - Detection Lifecycle

    /// Merge new results into activeDetections, resetting debounce timers.
    private func applyResults(_ results: [(bird: Bird, confidence: Double)]) {
        let qualified = results.filter { $0.confidence >= Self.confidenceThreshold }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            for result in qualified {
                // Reset debounce timer for this species
                self.debounceTimers[result.bird.id]?.invalidate()
                let timer = Timer.scheduledTimer(
                    withTimeInterval: Self.debounceSeconds,
                    repeats: false
                ) { [weak self] _ in
                    self?.expireDetection(birdID: result.bird.id)
                }
                self.debounceTimers[result.bird.id] = timer

                // Update or insert detection
                if let idx = self.activeDetections.firstIndex(where: { $0.bird.id == result.bird.id }) {
                    self.activeDetections[idx] = DetectedBird(bird: result.bird, confidence: result.confidence)
                } else {
                    self.activeDetections.append(DetectedBird(bird: result.bird, confidence: result.confidence))
                }
            }
        }
    }

    /// Called when a debounce timer fires — removes the card for that species.
    private func expireDetection(birdID: String) {
        DispatchQueue.main.async { [weak self] in
            self?.activeDetections.removeAll { $0.bird.id == birdID }
            self?.debounceTimers.removeValue(forKey: birdID)
        }
    }
}
