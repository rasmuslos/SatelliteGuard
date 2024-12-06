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
    
    @Query private var endpoints: [Endpoint]
    @State private var editMode: EditMode = .inactive
    
    private var activeEndpoints: [Endpoint] {
        endpoints.filter(\.isActive)
    }
    private var inactiveEndpoints: [Endpoint] {
        endpoints.filter { !$0.isActive }
    }
    
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
                    if !activeEndpoints.isEmpty {
                        Section("home.active") {
                            ForEach(activeEndpoints) {
                                EndpointCell(endpoint: $0)
                            }
                        }
                    }
                    
                    if !inactiveEndpoints.isEmpty {
                        Section("home.inactive") {
                            ForEach(inactiveEndpoints) {
                                EndpointCell(endpoint: $0)
                            }
                            .onDelete {
                                for index in $0 {
                                    try? inactiveEndpoints[index].remove()
                                }
                            }
                        }
                    }
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
