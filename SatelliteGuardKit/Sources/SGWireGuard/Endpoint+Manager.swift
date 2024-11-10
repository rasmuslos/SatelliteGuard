//
//  Endpoint+Register.swift
//  SatelliteGuardKit
//
//  Created by Rasmus Krämer on 10.11.24.
//

import Foundation
import SwiftData
import Network
import NetworkExtension
import SGPersistence

private extension Endpoint {
    func updateManager(_ manager: NETunnelProviderManager) async throws {
        let encoder = JSONEncoder()
        let encoded = try encoder.encode(self)
        let endpoint = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
        
        let providerProtocol = NETunnelProviderProtocol()
        
        providerProtocol.providerBundleIdentifier = Bundle.main.bundleIdentifier
        providerProtocol.providerConfiguration = endpoint
        
        providerProtocol.serverAddress = friendlyURL
        providerProtocol.disconnectOnSleep = disconnectsOnSleep
        
        providerProtocol.excludeAPNs = excludeAPN
        providerProtocol.enforceRoutes = enforceRoutes
        providerProtocol.includeAllNetworks = includeAllNetworks
        providerProtocol.excludeLocalNetworks = allowAccessToLocalNetwork
        providerProtocol.excludeCellularServices = excludeCellularServices
        providerProtocol.excludeDeviceCommunication = excludeDeviceCommunication
        
        manager.protocolConfiguration = providerProtocol
        
        try await manager.saveToPreferences()
    }
    
    var manager: NETunnelProviderManager? {
        get async {
            guard let managers = try? await NETunnelProviderManager.loadAllFromPreferences() else {
                return nil
            }
            
            let manager: NETunnelProviderManager
            
            if let existing = managers.first(where: { $0.identified(by: id) }) {
                if !active {
                    Self.logger.fault("Manager found even though endpoint is not active")
                }
                
                manager = existing
            } else if active {
                manager = .init()
                
                do {
                    try await updateManager(manager)
                } catch {
                    Self.logger.fault("Failed to update newly created manager")
                    print(error)
                    return nil
                }
            } else {
                return nil
            }
            
            manager.isEnabled = active
            
            return manager
        }
    }
}

public extension Endpoint {
    func notifySystem() async throws {
        active = true
        
        guard let manager = await manager else {
            Self.logger.fault("Could not create manager for \(self.id) while updating")
            throw EndpointError.managerMissing
        }
        
        try await updateManager(manager)
    }
}
