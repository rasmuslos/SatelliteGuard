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
    
    private var isLoading: Bool {
        #if os(macOS)
        false
        #else
        satellite.pondering
        #endif
    }
    private var isActive: Bool {
        satellite.connectedIDs.contains(endpoint.id)
    }
    
    private var label: LocalizedStringKey {
        if isActive {
            "disconnect"
        } else if satellite.activeEndpointIDs.contains(endpoint.id) {
            "connect"
        } else {
            "endpoint.activate"
        }
    }
    private var icon: String {
        if isActive {
            "diamond.fill"
        } else if satellite.activeEndpointIDs.contains(endpoint.id) {
            "diamond.bottomhalf.filled"
        } else {
            "diamond"
        }
    }
    
    var body: some View {
        if isLoading {
            ProgressView()
        } else {
            Button {
                if isActive {
                    satellite.land(endpoint)
                } else if satellite.activeEndpointIDs.contains(endpoint.id) {
                    satellite.activate(endpoint)
                } else {
                    satellite.launch(endpoint)
                }
            } label: {
                Label(label, systemImage: icon)
                    #if os(tvOS)
                    .labelStyle(.titleOnly)
                    #endif
            }
            .disabled(satellite.pondering)
        }
    }
}
