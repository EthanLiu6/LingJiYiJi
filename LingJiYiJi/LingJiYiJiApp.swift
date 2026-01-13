//
//  LingJiYiJiApp.swift
//  LingJiYiJi
//
//  Created by Ethan.Liu on 2026/1/13.
//

import SwiftUI
import SwiftData

@main
struct LingJiYiJiApp: App {
    let container: ModelContainer
    
    init() {
        NotificationManager.shared.requestAuthorization()
        
        do {
            let schema = Schema([
                Inspiration.self,
                Category.self,
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
