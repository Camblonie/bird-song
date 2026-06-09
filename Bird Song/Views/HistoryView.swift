//
//  HistoryView.swift
//  Bird Song
//
//  Shows all logged bird sightings in a list sorted newest-first.
//  Supports swipe-to-delete and JSON export.
//

import SwiftUI
import SwiftData

struct HistoryView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BirdSighting.timestamp, order: .reverse) private var sightings: [BirdSighting]

    // MARK: - State

    @State private var selectedSighting: BirdSighting?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if sightings.isEmpty {
                    emptyState
                } else {
                    sightingList
                }
            }
            .navigationTitle("Sighting History")
            .toolbar {
                if !sightings.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        exportButton
                    }
                }
            }
        }
        .sheet(item: $selectedSighting) { sighting in
            BirdDetailView(sighting: sighting)
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 52))
                .foregroundStyle(.secondary)
            Text("No Sightings Yet")
                .font(.title3.bold())
            Text("Tap the Mic tab and start listening.\nTap \"Log This\" on any detected bird to save it here.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }

    private var sightingList: some View {
        List {
            ForEach(sightings) { sighting in
                Button {
                    selectedSighting = sighting
                } label: {
                    SightingRow(sighting: sighting)
                }
                .listRowBackground(Color(.secondarySystemBackground))
            }
            .onDelete(perform: deleteSightings)
        }
        .listStyle(.insetGrouped)
    }

    private var exportButton: some View {
        Button {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootVC = windowScene.windows.first?.rootViewController else { return }
            ExportService.exportJSON(sightings: sightings, from: rootVC)
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
        .accessibilityLabel("Export sightings as JSON")
    }

    // MARK: - Actions

    private func deleteSightings(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sightings[index])
        }
    }
}

// MARK: - SightingRow

/// Single list row showing thumbnail, bird name, date and confidence.
private struct SightingRow: View {
    let sighting: BirdSighting

    var body: some View {
        HStack(spacing: 12) {
            BirdThumbnail(imageName: sighting.imageName, size: 56)

            VStack(alignment: .leading, spacing: 2) {
                Text(sighting.birdName)
                    .font(.headline)
                Text(sighting.scientificName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .italic()
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(sighting.timestamp.displayString)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Confidence badge
            Text("\(Int(sighting.confidence * 100))%")
                .font(.caption.bold())
                .foregroundStyle(.green)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.12), in: Capsule())
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: BirdSighting.self, inMemory: true)
}
