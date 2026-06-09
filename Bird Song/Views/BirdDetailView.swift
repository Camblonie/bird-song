//
//  BirdDetailView.swift
//  Bird Song
//
//  Full-screen detail card for a logged BirdSighting.
//

import SwiftUI

struct BirdDetailView: View {

    let sighting: BirdSighting

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {

                    // Hero bird photo
                    heroBirdPhoto

                    // Details card
                    detailCard
                        .padding()
                }
            }
            .navigationTitle(sighting.birdName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Subviews

    private var heroBirdPhoto: some View {
        Group {
            if let uiImage = UIImage(named: sighting.imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 280)
                    .clipped()
            } else {
                // Placeholder until real photos are added
                ZStack {
                    Color.green.opacity(0.15)
                    VStack(spacing: 8) {
                        Image(systemName: "bird")
                            .font(.system(size: 72))
                            .foregroundStyle(Color.green)
                        Text(sighting.birdName)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 280)
            }
        }
    }

    private var detailCard: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Names
            VStack(alignment: .leading, spacing: 4) {
                Text(sighting.birdName)
                    .font(.title2.bold())
                Text(sighting.scientificName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .italic()
            }

            Divider()

            // Confidence
            VStack(alignment: .leading, spacing: 6) {
                Label("Confidence", systemImage: "chart.bar.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.green.opacity(0.15))
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.green)
                                .frame(width: geo.size.width * sighting.confidence, height: 8)
                        }
                    }
                    .frame(height: 8)

                    Text("\(Int(sighting.confidence * 100))%")
                        .font(.subheadline.bold())
                        .foregroundStyle(.green)
                        .frame(width: 40, alignment: .trailing)
                }
            }

            Divider()

            // Date & Time
            VStack(alignment: .leading, spacing: 6) {
                Label("Date & Time Logged", systemImage: "calendar")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                HStack(spacing: 16) {
                    Label(sighting.timestamp.shortDateString, systemImage: "calendar")
                        .font(.subheadline)
                    Label(sighting.timestamp.shortTimeString, systemImage: "clock")
                        .font(.subheadline)
                }
            }

            Divider()

            // BirdNET technical label
            VStack(alignment: .leading, spacing: 4) {
                Label("Model Label", systemImage: "cpu")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text(sighting.birdNETLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}
