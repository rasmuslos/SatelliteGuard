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
        let providerProtocol = NETunnelProviderProtocol()
        
        providerProtocol.providerBundleIdentifier = Bundle.main.networkExtensionIdentifier
        providerProtocol.providerConfiguration = [
            "id": id.uuidString,
        ]
        
        providerProtocol.username = name
        providerProtocol.serverAddress = peers.map(\.endpoint).joined(separator: ", ")
        providerProtocol.disconnectOnSleep = disconnectsOnSleep
        
        #if !os(tvOS)
        providerProtocol.excludeAPNs = excludeAPN
        providerProtocol.enforceRoutes = enforceRoutes
        providerProtocol.includeAllNetworks = includeAllNetworks
        providerProtocol.excludeLocalNetworks = allowAccessToLocalNetwork
        providerProtocol.excludeCellularServices = excludeCellularServices
        providerProtocol.excludeDeviceCommunication = excludeDeviceCommunication
        #endif
        
        manager.localizedDescription = name
        manager.protocolConfiguration = providerProtocol
        
        try await manager.saveToPreferences()
    }
}

internal extension Endpoint {
    var manager: NETunnelProviderManager? {
        get async {
            guard let managers = try? await NETunnelProviderManager.loadAllFromPreferences() else {
                return nil
            }
            
            let manager: NETunnelProviderManager
            
            if let existing = managers.first(where: { $0.identified(by: id) }) {
                if !(await PersistenceManager.shared.endpoint[id]) {
                    Self.logger.fault("Manager found even though endpoint is not active")
                }
                
                manager = existing
            } else if await PersistenceManager.shared.endpoint[id] {
                manager = .init()
                manager.isEnabled = true
                
                do {
                    try await updateManager(manager)
                } catch {
                    Self.logger.fault("Failed to update newly created manager")
                    print(error)
                    return nil
                }
            } else {
                Self.logger.error("Could not create manager for \(self.id): missing")
                return nil
            }
            
            return manager
        }
    }
}

public extension Endpoint {
    func reassert() async throws {
        do {
            await PersistenceManager.shared.endpoint.activate(id)
            
            guard let manager = await manager else {
                Self.logger.fault("Could not create manager for \(self.id) while updating")
                throw EndpointError.managerMissing
            }
            
            try await updateManager(manager)
        } catch {
            await PersistenceManager.shared.endpoint.deactivate(id)
            throw error
        }
    }
    
    func deactivate() async throws {
        await PersistenceManager.shared.endpoint.deactivate(id)
        
        await disconnect()
        try await manager?.removeFromPreferences()
    }
}
