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
    func updateManager(_  manager: NETunnelProviderManager) async throws {
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
        
        manager.protocolConfiguration = providerProtocol
        
        manager.localizedDescription = name
        manager.isEnabled = isActive
        
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
                if !isActive {
                    Self.logger.fault("Manager found even though endpoint is not active")
                }
                
                manager = existing
            } else if isActive {
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
            
            return manager
        }
    }
}

public extension Endpoint {
    func notifySystem() async throws {
        active.append(PersistenceManager.shared.uuid)
        try modelContext?.save()
        
        guard let manager = await manager else {
            Self.logger.fault("Could not create manager for \(self.id) while updating")
            throw EndpointError.managerMissing
        }
        
        try await updateManager(manager)
    }
    
    func deactivate() async throws {
        active.removeAll { $0 == PersistenceManager.shared.uuid }
        try modelContext?.save()
        
        try await manager?.removeFromPreferences()
    }
    
    static func checkActive() async throws {
        let managers = (try? await NETunnelProviderManager.loadAllFromPreferences()) ?? []
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        let endpoints = try context.fetch(FetchDescriptor<Endpoint>())
        
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
        let invalidInactive = endpoints.filter { $0.isActive && !active.contains($0) }
        let invalidActive = endpoints.filter { !$0.isActive && active.contains($0) }
        
        for endpoint in invalidInactive {
            try? await endpoint.deactivate()
        }
        for endpoint in invalidActive {
            try? await endpoint.notifySystem()
        }
        
        try context.save()
    }
}