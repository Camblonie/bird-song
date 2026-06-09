//
//  BirdClassifier.swift
//  Bird Song
//
//  Wraps BirdNET CoreML inference and returns all species above a confidence
//  threshold. Uses a mock implementation until the real .mlmodel is added.
//
//  To swap in the real model:
//    1. Add BirdNET.mlmodel to the Xcode project.
//    2. Set USE_REAL_MODEL = true below.
//    3. Uncomment the CoreML inference block in classifyBuffer(_:).
//

import AVFoundation
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
    /// Toggle — set true once BirdNET.mlmodel is added to the project
    private static let USE_REAL_MODEL = false

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
        if Self.USE_REAL_MODEL {
            runCoreMLInference(buffer)
        } else {
            runMockInference()
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

    // MARK: - CoreML Inference (inactive until model is added)

    /// Real BirdNET CoreML inference path — activate by setting USE_REAL_MODEL = true.
    private func runCoreMLInference(_ buffer: AVAudioPCMBuffer) {
        // TODO: Implement after BirdNET.mlmodel is added to the project.
        // Steps:
        //   1. Convert buffer to spectrogram MLMultiArray (BirdNET expects a mel spectrogram).
        //   2. Run BirdNETInput through the generated model class.
        //   3. Parse output dictionary: label -> confidence Double.
        //   4. Filter to BirdCatalog.labelSet, threshold, sort, call applyResults(_:).
        print("[BirdClassifier] CoreML path not yet implemented — add BirdNET.mlmodel first.")
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
