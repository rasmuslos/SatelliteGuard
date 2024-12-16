//
//  EndpointDeactivateButton.swift
//  SatelliteGuard
//
//  Created by Rasmus Krämer on 13.11.24.
//

import Foundation
import SwiftUI
import SatelliteGuardKit

struct EndpointDestructiveButton: View {
    @Environment(Satellite.self) private var satellite
    
    let endpoint: Endpoint
    
    init(_ endpoint: Endpoint) {
        self.endpoint = endpoint
    }
    
    private var isBlocked: Bool {
        satellite.connectedIDs.contains(endpoint.id) || satellite.pondering
    }
    
    @ViewBuilder
    private func button<Label: View>(@ViewBuilder _ label: () -> Label, callback: @escaping () -> Void) -> some View {
        Button(role: .destructive) {
            callback()
        } label: {
            label()
                #if os(tvOS) || os(macOS)
                .labelStyle(.titleOnly)
                #endif
        }
        .foregroundStyle(isBlocked ? .secondary : .primary)
        .disabled(isBlocked)
    }
    
    var body: some View {
        if satellite.activeEndpointIDs.contains(endpoint.id) {
            button {
                Label("endpoint.deactivate", systemImage: "minus.diamond")
            } callback: {
                satellite.deactivate(endpoint)
            }
        } else {
            button {
                Label("endpoint.delete", systemImage: "minus.diamond")
            } callback: {
                satellite.delete(endpoint.id)
            }
        }
    }
}
