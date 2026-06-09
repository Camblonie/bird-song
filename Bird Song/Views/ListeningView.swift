//
//  ListeningView.swift
//  Bird Song
//
//  Main listening screen: mic toggle, animated waveform, and scrollable
//  per-bird detection cards. Each card has its own "Log This" button.
//

import SwiftUI
import SwiftData

struct ListeningView: View {

    // MARK: - Environment & Dependencies

    @Environment(\.modelContext) private var modelContext
    @StateObject private var audioManager = AudioSessionManager()
    @StateObject private var classifier = BirdClassifier()

    // MARK: - State

    /// Tracks which bird IDs have already been logged in the current session
    @State private var loggedBirdIDs: Set<String> = []
    /// Animated waveform bar heights
    @State private var waveHeights: [CGFloat] = Array(repeating: 4, count: 20)
    @State private var waveTimer: Timer?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(.systemBackground), Color.green.opacity(0.08)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    // Mic button + waveform
                    micSection

                    Spacer()

                    // Detection cards
                    detectionSection
                        .padding(.bottom, 20)
                }
            }
            .navigationTitle("Bird Song")
            .navigationBarTitleDisplayMode(.large)
        }
        .onChange(of: audioManager.isListening) { _, listening in
            if listening {
                startWaveAnimation()
                // Wire audio buffers to classifier
                audioManager.onBuffer = { [weak classifier] buffer in
                    classifier?.classifyBuffer(buffer)
                }
            } else {
                stopWaveAnimation()
                audioManager.onBuffer = nil
            }
        }
    }

    // MARK: - Subviews

    /// Mic toggle button with animated waveform underneath
    private var micSection: some View {
        VStack(spacing: 24) {
            // Animated waveform bars (only visible while listening)
            if audioManager.isListening {
                HStack(spacing: 4) {
                    ForEach(0..<waveHeights.count, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.green)
                            .frame(width: 4, height: waveHeights[i])
                            .animation(.easeInOut(duration: 0.2), value: waveHeights[i])
                    }
                }
                .frame(height: 40)
                .transition(.opacity.combined(with: .scale))
            } else {
                Text("Tap the mic to start listening")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Mic button
            Button {
                if audioManager.isListening {
                    audioManager.stopListening()
                    loggedBirdIDs.removeAll()
                } else {
                    audioManager.startListening()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(audioManager.isListening ? Color.red : Color.green)
                        .frame(width: 100, height: 100)
                        .shadow(color: (audioManager.isListening ? Color.red : Color.green).opacity(0.4),
                                radius: 12, x: 0, y: 4)

                    Image(systemName: audioManager.isListening ? "stop.fill" : "mic.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.white)
                }
            }
            .accessibilityLabel(audioManager.isListening ? "Stop listening" : "Start listening")

            if audioManager.isListening {
                Text("Listening…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: audioManager.isListening)
    }

    /// Scrollable list of detected bird cards, or placeholder
    @ViewBuilder
    private var detectionSection: some View {
        if classifier.activeDetections.isEmpty {
            if audioManager.isListening {
                // Listening but no birds yet
                VStack(spacing: 8) {
                    Image(systemName: "waveform.and.mic")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("Listening for birds…")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            }
            // Silent when not listening — mic button area is the CTA
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text(classifier.activeDetections.count == 1 ? "1 Bird Detected" : "\(classifier.activeDetections.count) Birds Detected")
                    .font(.headline)
                    .padding(.horizontal)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(classifier.activeDetections) { detection in
                            BirdDetectionCard(
                                detection: detection,
                                isLogged: loggedBirdIDs.contains(detection.bird.id),
                                onLog: { logSighting(detection) }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(duration: 0.4), value: classifier.activeDetections.count)
        }
    }

    // MARK: - Actions

    /// Save a detection to SwiftData and mark its card as logged.
    private func logSighting(_ detection: DetectedBird) {
        let sighting = BirdSighting(
            birdName: detection.bird.commonName,
            scientificName: detection.bird.scientificName,
            confidence: detection.confidence,
            imageName: detection.bird.imageName,
            birdNETLabel: detection.bird.birdNETLabel
        )
        modelContext.insert(sighting)
        loggedBirdIDs.insert(detection.bird.id)
    }

    // MARK: - Waveform Animation

    private func startWaveAnimation() {
        waveTimer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { _ in
            waveHeights = waveHeights.map { _ in CGFloat.random(in: 4...36) }
        }
    }

    private func stopWaveAnimation() {
        waveTimer?.invalidate()
        waveTimer = nil
        waveHeights = Array(repeating: 4, count: 20)
    }
}

// MARK: - BirdDetectionCard

/// Card shown for a single detected bird with photo, info, and per-card Log This button.
private struct BirdDetectionCard: View {

    let detection: DetectedBird
    let isLogged: Bool
    let onLog: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Bird photo
            BirdThumbnail(imageName: detection.bird.imageName)

            // Name + confidence
            VStack(alignment: .leading, spacing: 4) {
                Text(detection.bird.commonName)
                    .font(.headline)
                    .lineLimit(1)

                Text(detection.bird.scientificName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .italic()
                    .lineLimit(1)

                // Confidence bar
                confidenceBar

                Text("\(Int(detection.confidence * 100))% confidence")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Log This button
            Button(action: onLog) {
                Label(isLogged ? "Logged" : "Log This",
                      systemImage: isLogged ? "checkmark.circle.fill" : "plus.circle")
                    .font(.caption.bold())
                    .foregroundStyle(isLogged ? .green : .white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isLogged ? Color.green.opacity(0.15) : Color.green)
                    )
            }
            .disabled(isLogged)
            .accessibilityLabel(isLogged ? "Already logged" : "Log \(detection.bird.commonName)")
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        )
    }

    /// Green confidence bar scaled 0–100%
    private var confidenceBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.green.opacity(0.15))
                    .frame(height: 5)
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.green)
                    .frame(width: geo.size.width * detection.confidence, height: 5)
            }
        }
        .frame(height: 5)
    }
}

// MARK: - BirdThumbnail

/// Displays a bundled bird photo; falls back to a feather SF Symbol placeholder.
struct BirdThumbnail: View {
    let imageName: String
    var size: CGFloat = 68

    var body: some View {
        Group {
            if let uiImage = UIImage(named: imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                // Placeholder until real photos are added
                ZStack {
                    Color.green.opacity(0.15)
                    Image(systemName: "bird")
                        .font(.system(size: size * 0.4))
                        .foregroundStyle(Color.green)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    ListeningView()
        .modelContainer(for: BirdSighting.self, inMemory: true)
}
