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
            #elseif os(iOS)
            mainContent
                .modifier(ConfigurationImportMenu.ImporterModifier())
                .sheet(item: $satellite.editingEndpoint) {
                    Text(verbatim: $0.name)
                }
            #else
            Text(verbatim: "Unsupported Platform")
            #endif
        }
        .sensoryFeedback(.success, trigger: satellite.authorizationStatus)
    }
}

#if DEBUG && !os(macOS)
#Preview {
    ContentView()
        .previewEnvironment()
}
#endif
