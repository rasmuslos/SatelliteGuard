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
    
    private var label: LocalizedStringKey {
        if satellite.connectedIDs.contains(endpoint.id) {
            "disconnect"
        } else if satellite.activeEndpointIDs.contains(endpoint.id) {
            "connect"
        } else {
            "endpoint.activate"
        }
    }
    private var icon: String {
        if satellite.connectedIDs.contains(endpoint.id) {
            "diamond.fill"
        } else if satellite.activeEndpointIDs.contains(endpoint.id) {
            "diamond.bottomhalf.filled"
        } else {
            "diamond"
        }
    }
    
    var body: some View {
        if satellite.pondering {
            ProgressView()
        } else {
            Button {
                if satellite.connectedIDs.contains(endpoint.id) {
                    satellite.land(endpoint)
                } else if satellite.activeEndpointIDs.contains(endpoint.id) {
                    satellite.launch(endpoint)
                } else {
                    satellite.activate(endpoint)
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
