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
    
    let endpoints: [Endpoint] = []
    
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
        Group {
            if endpoints.isEmpty {
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
                    
                }
                #if os(tvOS)
                .listStyle(.grouped)
                .scrollClipDisabled()
                #else
                .listStyle(.insetGrouped)
                .environment(\.editMode, $editMode)
                #endif
            }
        }
        #if os(tvOS)
        .padding(.leading, ContentView.gap)
        #else
        .navigationTitle("home")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    if editMode == .active {
                        editMode = .inactive
                    } else {
                        editMode = .active
                    }
                } label: {
                    Label("home.edit", systemImage: "pencil")
                }
                
                if satellite.pondering {
                    ProgressView()
                } else {
                    ConfigurationImporter()
                }
            }
        }
        #endif
        .animation(.smooth, value: editMode)
        .task {
            await Endpoint.checkActive()
        }
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
