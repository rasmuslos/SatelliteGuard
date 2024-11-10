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
                }
            }
        }
        .navigationTitle("home")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ConfigurationImporter()
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        HomeView()
            .satellite()
    }
}
#endif
