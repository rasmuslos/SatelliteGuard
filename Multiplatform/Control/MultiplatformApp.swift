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
    
    init() {
        WireGuardMonitor.shared.ping()
        
        Task {
            await Endpoint.checkActive()
        }
        
        #if DEBUG && os(tvOS)
        Task.detached {
            if await Endpoint.all?.isEmpty ?? true {
                await MainActor.run {
                    PersistenceManager.shared.modelContainer.mainContext.insert(Endpoint.fixture)
                }
            }
        }
        #endif
    }
    
    var body: some Scene {
        #if os(macOS)
        MenuBarExtra {
            StatusMenu()
                .environment(satellite)
                .modelContainer(PersistenceManager.shared.modelContainer)
        } label: {
            switch satellite.status {
            case .connected:
                Label("home", systemImage: "diamond.fill")
            case .establishing:
                Label("home", systemImage: "diamond.bottomhalf.filled")
            default:
                Label("home", image: "satellite.guard")
            }
        }
        .menuBarExtraStyle(.window)
        #else
        WindowGroup {
            ContentView()
                .sensoryFeedback(.error, trigger: satellite.notifyError)
                .sensoryFeedback(.success, trigger: satellite.notifySuccess)
                .environment(satellite)
                .modelContainer(PersistenceManager.shared.modelContainer)
        }
        #endif
    }
}
