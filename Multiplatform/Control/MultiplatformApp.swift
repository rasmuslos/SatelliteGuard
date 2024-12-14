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
    #if os(macOS)
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    #endif
    @State private var satellite = Satellite()
    
    init() {
        WireGuardMonitor.shared.ping()
        
        Task.detached {
            try await Task.sleep(for: .seconds(1))
            await PersistenceManager.shared.keyHolder.updateKeyHolders()
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
            MenuBarItem()
                .environment(satellite)
                .modelContainer(PersistenceManager.shared.modelContainer)
        } label: {
            MenuBarItem.LabelIcon(satellite: satellite)
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

#if os(macOS)
class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        true
    }
    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        print(filenames)
    }
}
#endif
