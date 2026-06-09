//
//  Bird_SongApp.swift
//  Bird Song
//
//  App entry point. Configures the SwiftData ModelContainer for BirdSighting
//  and presents the root tab view.
//

import SwiftUI
import SwiftData

@main
struct Bird_SongApp: App {

    /// Persistent SwiftData store for BirdSighting records.
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([BirdSighting.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("[Bird_SongApp] Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}
