//
//  BirdSighting.swift
//  Bird Song
//
//  SwiftData model representing a single logged bird sighting.
//

import Foundation
import SwiftData

/// A single confirmed bird sighting saved by the user.
@Model
final class BirdSighting {
    /// Unique identifier for the sighting
    var id: UUID
    /// Date and time the sighting was logged
    var timestamp: Date
    /// Common English name (e.g. "American Robin")
    var birdName: String
    /// Scientific name (e.g. "Turdus migratorius")
    var scientificName: String
    /// Confidence score from 0.0 to 1.0
    var confidence: Double
    /// Asset image name for the bundled bird photo
    var imageName: String
    /// BirdNET model label string used for identification
    var birdNETLabel: String

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        birdName: String,
        scientificName: String,
        confidence: Double,
        imageName: String,
        birdNETLabel: String
    ) {
        self.id = id
        self.timestamp = timestamp
        self.birdName = birdName
        self.scientificName = scientificName
        self.confidence = confidence
        self.imageName = imageName
        self.birdNETLabel = birdNETLabel
    }
}

/// Codable DTO used for JSON export — mirrors BirdSighting fields.
struct BirdSightingExport: Codable {
    let id: UUID
    let timestamp: Date
    let birdName: String
    let scientificName: String
    let confidence: Double
    let imageName: String
    let birdNETLabel: String
}
