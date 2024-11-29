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
    
    private var isActive: Bool {
        satellite.connectedIDs.contains(endpoint.id)
    }
    
    var body: some View {
        Button(role: .destructive) {
            satellite.deactivate(endpoint)
        } label: {
            Label("endpoint.deactivate", systemImage: "minus.diamond")
                #if os(tvOS)
                .labelStyle(.titleOnly)
                #endif
        }
        .modify {
            if satellite.connectedIDs.contains(endpoint.id) {
                $0
                    .foregroundStyle(.secondary)
            } else {
                $0
            }
        }
        .disabled(isActive)
    }
}
