//
//  EndpointEditButton.swift
//  SatelliteGuard
//
//  Created by Rasmus Krämer on 13.11.24.
//

import Foundation
import SwiftUI
import SatelliteGuardKit

@available(tvOS, unavailable)
struct EndpointEditButton: View {
    @Environment(Satellite.self) private var satellite
    
    let endpoint: Endpoint
    
    init(_ endpoint: Endpoint) {
        self.endpoint = endpoint
    }
    
    private var isActive: Bool {
        satellite.connectedIDs.contains(endpoint.id)
    }
    
    var body: some View {
        Button {
            satellite.editingEndpoint = endpoint
        } label: {
            Label("endpoint.edit", systemImage: "pencil")
        }
        .disabled(isActive)
        .foregroundColor(isActive ? .secondary : .primary)
    }
}
