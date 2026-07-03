//
//  LittleGalileoApp.swift
//  LittleGalileo
//
//  Created by 钱前 on 2026/7/4.
//

import SwiftUI

@main
struct LittleGalileoApp: App {
    @StateObject private var catalog = StarCatalog()
    @StateObject private var location = LocationManager()
    @StateObject private var collection = CollectionStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(catalog)
                .environmentObject(location)
                .environmentObject(collection)
                .preferredColorScheme(.dark)
        }
    }
}
