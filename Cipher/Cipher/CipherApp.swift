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
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

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
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        showLaunch = false
                    }
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
