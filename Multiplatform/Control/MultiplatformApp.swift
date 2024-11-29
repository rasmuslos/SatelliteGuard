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
    
    private var inserted: Binding<Bool> {
        .init() { true } set: {
            if !$0 {
                exit(0)
            }
        }
    }
    
    var body: some Scene {
        #if os(macOS)
        MenuBarExtra(isInserted: inserted) {
            StatusMenu()
                .environment(satellite)
                .modelContainer(PersistenceManager.shared.modelContainer)
        } label: {
            switch satellite.dominantStatus {
            case .connected:
                Label("home", systemImage: "diamond.fill")
            case .establishing:
                Label("home", systemImage: "diamond.bottomhalf.filled")
            case .disconnecting:
                Label("home", systemImage: "diamond")
            default:
                Label("home", image: "satellite.guard")
            }
        }
        .menuBarExtraStyle(.window)
        
        WindowGroup("Endpoint", for: Endpoint.ID.self) { $endpointID in
            if let endpointID, let endpoint = Endpoint.identified(by: endpointID) {
                Group {
                    if endpointID == satellite.editingEndpoint?.id {
                        EndpointEditView(endpoint)
                            .padding(20)
                    } else {
                        EndpointView(endpoint)
                    }
                }
                .environment(satellite)
                .modelContainer(PersistenceManager.shared.modelContainer)
            }
        }
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
