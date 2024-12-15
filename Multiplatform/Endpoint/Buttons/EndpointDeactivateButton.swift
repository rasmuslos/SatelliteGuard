//
//  EndpointDeactivateButton.swift
//  SatelliteGuard
//
//  Created by Rasmus Krämer on 13.11.24.
//

import Foundation
import SwiftUI
import SatelliteGuardKit

struct EndpointDeactivateButton: View {
    @Environment(Satellite.self) private var satellite
    
    let endpoint: Endpoint
    
    init(_ endpoint: Endpoint) {
        self.endpoint = endpoint
    }
    
    private var isBlocked: Bool {
        satellite.connectedIDs.contains(endpoint.id) || satellite.pondering
    }
    
    var body: some View {
        if satellite.activeEndpointIDs.contains(endpoint.id) {
            Button(role: .destructive) {
                satellite.deactivate(endpoint)
            } label: {
                Label("endpoint.deactivate", systemImage: "minus.diamond")
                    #if os(tvOS)
                    .labelStyle(.titleOnly)
                    #endif
            }
            .foregroundStyle(isBlocked ? .secondary : .primary)
            .disabled(isBlocked)
        }
    }
}
