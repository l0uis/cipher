//
//  CipherApp.swift
//  Cipher
//
//  Created by Louis Currie on 09.02.26.
//

import SwiftUI
import SwiftData
import UIKit

@main
struct CipherApp: App {
    @State private var showLaunch = true

    init() {
        // Custom navigation title fonts
        let largeTitleFont = UIFont(name: "SortsMillGoudy-Regular", size: 34) ?? .systemFont(ofSize: 34)
        let inlineTitleFont = UIFont(name: "SortsMillGoudy-Regular", size: 17) ?? .systemFont(ofSize: 17)
        let bodyFont = UIFont(name: "REM", size: 15) ?? .systemFont(ofSize: 15)

        UINavigationBar.appearance().largeTitleTextAttributes = [
            .font: largeTitleFont,
            .foregroundColor: UIColor(named: "CipherPrimaryText") ?? .label
        ]
        UINavigationBar.appearance().titleTextAttributes = [
            .font: inlineTitleFont,
            .foregroundColor: UIColor(named: "CipherPrimaryText") ?? .label
        ]

        // List/table background
        UITableView.appearance().backgroundColor = UIColor(named: "CipherBackground")

        // Bar button items use REM
        UIBarButtonItem.appearance().setTitleTextAttributes([.font: bodyFont], for: .normal)
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            PatternScan.self,
            AnalysisResult.self,
        ])

        // Use App Group container if available, fall back to default
        let hasAppGroup = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppConstants.appGroupIdentifier
        ) != nil

        let modelConfiguration: ModelConfiguration
        if hasAppGroup {
            modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                groupContainer: .identifier(AppConstants.appGroupIdentifier)
            )
        } else {
            modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        }

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ZStack {
                HomeView()
                    .tint(CipherStyle.Colors.primaryText)

                if showLaunch {
                    LaunchScreenView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .task {
                await ImageStorageService.shared.migrateIfNeeded()
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        showLaunch = false
                    }
                }
            }
        }
        .modelContainer(sharedModelContainer)
        .handlesExternalEvents(matching: ["cipher"])
    }
}
