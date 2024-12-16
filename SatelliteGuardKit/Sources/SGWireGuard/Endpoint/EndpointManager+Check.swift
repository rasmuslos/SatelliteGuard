//
//  EndpointManager+Check.swift
//  SatelliteGuardKit
//
//  Created by Rasmus Krämer on 16.12.24.
//

import Foundation
import SGPersistence
import Network
@preconcurrency import NetworkExtension

extension PersistenceManager.EndpointSubsystem {
    public func checkActive() async {
        let managers = (try? await NETunnelProviderManager.loadAllFromPreferences()) ?? []
        
        let activeIDs = managers.compactMap(\.id)
        let endpointIDs = endpoints.map(\.id)
        
        let outdated = managers.filter {
            guard let id = $0.id else {
                return true
            }
            
            return !endpointIDs.contains(id)
        }
        
        for manager in outdated {
            try? await manager.removeFromPreferences()
        }
        
        let active = endpoints.filter { activeIDs.contains($0.id) }
        
        var invalidInactive = [Endpoint]()
        var invalidActive = [Endpoint]()
        
        for endpoint in active {
            if self[endpoint.id] && !active.contains(endpoint) {
                invalidInactive.append(endpoint)
            }
            if !self[endpoint.id] && active.contains(endpoint) {
                invalidActive.append(endpoint)
            }
        }
        
        for endpoint in invalidInactive {
            try? await endpoint.deactivate()
        }
        for endpoint in invalidActive {
            try? await endpoint.reassert()
        }
    }
}
