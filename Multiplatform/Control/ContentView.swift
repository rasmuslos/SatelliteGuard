//
//  ContentView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 10.11.24.
//

import SwiftUI
import SwiftData
import SatelliteGuardKit

struct ContentView: View {
    @Environment(Satellite.self) private var satellite
    
    var body: some View {
        @Bindable var satellite = satellite
        
        NavigationStack {
            HomeView()
        }
        .sheet(item: $satellite.editingEndpoint) {
            EndpointEditView(endpoint: $0)
        }
        .sheet(isPresented: $satellite.aboutSheetPresented) {
            AboutSheet()
        }
    }
}

#Preview {
    ContentView()
        .previewEnvironment()
}
