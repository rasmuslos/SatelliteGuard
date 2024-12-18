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
    @Environment(\.dismissWindow) private var dismissWindow
    #endif
    
    @State private var satellite = Satellite()
    
    init() {
        WireGuardMonitor.shared.ping()
        
        #if DEBUG && os(tvOS)
        Task {
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
        MenuBarExtra(isInserted: .constant(true)) {
            MenuBarItem()
                .environment(satellite)
                .modelContainer(PersistenceManager.shared.modelContainer)
                .onOpenURL { url in
                    Task {
                        try await satellite.importConfiguration(url)
                    }
                }
        } label: {
            MenuBarItem.LabelIcon(satellite: satellite)
        }
        .menuBarExtraStyle(.window)
        
        WindowGroup(for: Endpoint.self) {
            if let endpoint = $0.wrappedValue {
                EndpointView(endpoint)
                    .environment(satellite)
                    .modelContainer(PersistenceManager.shared.modelContainer)
            }
        }
        
        WindowGroup(Text("configuration.import"), id: "import-configuration") {
            VStack {
                Spacer()
                
                Text("configuration.import")
                    .font(.largeTitle)
                
                Spacer()
                
                if satellite.importing || satellite.importPickerVisible {
                    ProgressView()
                } else {
                    Image(systemName: "baseball.diamond.bases")
                        .foregroundStyle(.green)
                        .onAppear {
                            Task {
                                try await Task.sleep(for: .seconds(10))
                                dismissWindow(id: "import-configuration")
                            }
                        }
                }
                
                Spacer()
            }
            .frame(width: 400, height: 150)
            .modifier(ConfigurationImportMenu.ImporterModifier())
            .environment(satellite)
            .modelContainer(PersistenceManager.shared.modelContainer)
        }
        .defaultPosition(.center)
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)
        .windowLevel(.floating)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        #else
        WindowGroup {
            ContentView()
                .sensoryFeedback(.error, trigger: satellite.notifyError)
                .sensoryFeedback(.success, trigger: satellite.notifySuccess)
                .environment(satellite)
                .modelContainer(PersistenceManager.shared.modelContainer)
                .onOpenURL { url in
                    Task {
                        try await satellite.importConfiguration(url)
                    }
                }
        }
        #endif
    }
}
