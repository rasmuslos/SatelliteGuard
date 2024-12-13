//
//  ContentView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 10.11.24.
//

import SwiftUI
import SwiftData
import SatelliteGuardKit

@available(macOS, unavailable)
struct ContentView: View {
    @Environment(Satellite.self) private var satellite
    
    @ViewBuilder
    private var mainContent: some View {
        NavigationStack {
            HomeView()
        }
    }
    
    var body: some View {
        @Bindable var satellite = satellite
        
        KeyHolderAuthorizationView {
            #if os(tvOS)
            SplitScreenView {
                mainContent
            }
            #else
            mainContent
                .modifier(ConfigurationImporter.ImporterModifier())
                .sheet(item: $satellite.editingEndpoint) {
                    EndpointEditView($0)
                }
            #endif
        }
    }
}

#if DEBUG && !os(macOS)
#Preview {
    ContentView()
        .previewEnvironment()
}
#endif
