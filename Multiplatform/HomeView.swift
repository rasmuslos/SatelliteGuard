//
//  HomeView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 10.11.24.
//

import SwiftUI
import SwiftData
import SatelliteGuardKit

@available(macOS, unavailable)
struct HomeView: View {
    @Environment(Satellite.self) private var satellite
    
    var body: some View {
        Group {
            if satellite.endpoints.isEmpty {
                #if os(tvOS)
                VStack(alignment: .leading, spacing: 12) {
                    Text("home.empty")
                        .font(.title3)
                    Text("home.empty.description")
                        .foregroundStyle(.secondary)
                }
                #else
                ContentUnavailableView("home.empty", systemImage: "network", description: Text("home.empty.description"))
                #endif
            } else {
                List {
                    ForEach(satellite.endpoints) {
                        EndpointCell(endpoint: $0)
                    }
                }
                #if os(tvOS)
                .listStyle(.grouped)
                .scrollClipDisabled()
                #else
                .listStyle(.insetGrouped)
                #endif
            }
        }
        #if os(tvOS)
        .padding(.leading, ContentView.gap)
        #else
        .navigationTitle("home")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if satellite.pondering {
                    ProgressView()
                } else {
                    Menu {
                        ConfigurationImportMenu()
                    } label: {
                        Label("configuration.import", systemImage: "plus")
                    }
                }
            }
        }
        #endif
    }
}

#if DEBUG && !os(macOS)
#Preview {
    NavigationStack {
        HomeView()
            .previewEnvironment()
    }
}
#endif
