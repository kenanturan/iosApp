//
//  languageAppApp.swift
//  languageApp
//
//  Created by testing on 22.04.2025.
//

import SwiftUI

@main
struct languageAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, CoreDataManager.shared.context)
        }
    }
}
