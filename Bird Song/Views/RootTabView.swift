//
//  RootTabView.swift
//  Bird Song
//
//  Root tab bar: Listen | History
//

import SwiftUI
import SwiftData

struct RootTabView: View {
    var body: some View {
        TabView {
            ListeningView()
                .tabItem {
                    Label("Listen", systemImage: "mic.fill")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "list.bullet")
                }
        }
        .tint(.green) // accent color throughout tabs
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: BirdSighting.self, inMemory: true)
}
