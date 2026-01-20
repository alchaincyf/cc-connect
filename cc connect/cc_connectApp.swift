//
//  cc_connectApp.swift
//  cc connect
//
//  Created by alchain on 2026/1/21.
//

import SwiftUI
import CoreData

@main
struct cc_connectApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
