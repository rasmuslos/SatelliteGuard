//
//  HomeView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 10.11.24.
//

import SwiftUI
import SwiftData
import SatelliteGuardKit

struct HomeView: View {
    @Query(filter: #Predicate<Endpoint> { $0.active == true }) private var activeEndpoints: [Endpoint]
    @Query(filter: #Predicate<Endpoint> { $0.active == false }) private var inactiveEndpoints: [Endpoint]
    
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
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
        .navigationTitle("home")
        .environment(\.editMode, $editMode)
        .animation(.smooth, value: editMode)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if editMode == .active {
                        editMode = .inactive
                    } else {
                        editMode = .active
                    }
                } label: {
                    Label("home.edit", systemImage: "pencil")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                ConfigurationImporter()
            }
        }
        .task {
            try? await Endpoint.checkActive()
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        HomeView()
            .previewEnvironment()
    }
}
#endif
