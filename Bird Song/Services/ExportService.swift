//
//  ExportService.swift
//  Bird Song
//
//  Encodes BirdSighting records to pretty-printed JSON and presents
//  UIActivityViewController so the user can save, share, or AirDrop the file.
//

import UIKit
import SwiftData

/// Handles JSON export of the user's bird sighting history.
enum ExportService {

    /// Encode sightings to JSON and present the system share sheet.
    /// - Parameters:
    ///   - sightings: All BirdSighting records to export.
    ///   - presentingViewController: The view controller to present from.
    static func exportJSON(
        sightings: [BirdSighting],
        from presentingViewController: UIViewController
    ) {
        let exports = sightings.map { s in
            BirdSightingExport(
                id: s.id,
                timestamp: s.timestamp,
                birdName: s.birdName,
                scientificName: s.scientificName,
                confidence: s.confidence,
                imageName: s.imageName,
                birdNETLabel: s.birdNETLabel
            )
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(exports) else { return }

        // Write to a temp file so share sheet shows a proper filename
        let fileName = "BirdSightings-\(Date().exportFilenamePart).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: url)
        } catch {
            print("[ExportService] Failed to write temp file: \(error)")
            return
        }

        let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        presentingViewController.present(activity, animated: true)
    }
}
