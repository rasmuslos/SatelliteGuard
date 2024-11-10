//
//  MultiplatformApp.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 10.11.24.
//

import SwiftUI
import SwiftData
import SatelliteGuardKit

@main
struct MultiplatformApp: App {
    @State private var satellite = Satellite()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(satellite)
                .modelContainer(PersistenceManager.shared.modelContainer)
        }
    }
}
