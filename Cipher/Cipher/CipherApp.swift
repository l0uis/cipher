//
//  CipherApp.swift
//  Cipher
//
//  Created by Louis Currie on 09.02.26.
//

import SwiftUI
import SwiftData

@main
struct CipherApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            PatternScan.self,
            AnalysisResult.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(sharedModelContainer)
    }
}
