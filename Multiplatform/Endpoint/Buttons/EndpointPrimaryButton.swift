//
//  ActivateEndpointButton.swift
//  SatelliteGuard
//
//  Created by Rasmus Krämer on 13.11.24.
//

import Foundation
import SwiftUI
import SatelliteGuardKit

struct EndpointPrimaryButton: View {
    @Environment(Satellite.self) private var satellite
    
    let endpoint: Endpoint
    
    init(_ endpoint: Endpoint) {
        self.endpoint = endpoint
    }
    
    private var isActive: Bool {
        satellite.connectedIDs.contains(endpoint.id)
    }
    
    private var label: LocalizedStringKey {
        if !endpoint.isActive {
            "endpoint.activate"
        } else if isActive {
            "disconnect"
        } else {
            "connect"
        }
    }
    private var icon: String {
        if !endpoint.isActive {
            "diamond"
        } else if isActive {
            "diamond.fill"
        } else {
            "diamond.bottomhalf.filled"
        }
    }
    
    var body: some View {
        if satellite.pondering {
            ProgressView()
        } else {
            Button {
                if !endpoint.isActive {
                    satellite.activate(endpoint)
                } else if isActive {
                    satellite.land(endpoint)
                } else {
                    satellite.launch(endpoint)
                }
            } label: {
                Label(label, systemImage: icon)
                    #if os(tvOS)
                    .labelStyle(.titleOnly)
                    #endif
            }
        }
    }
}
