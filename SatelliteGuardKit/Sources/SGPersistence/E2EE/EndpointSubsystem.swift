//
//  EndpointManager.swift
//  SatelliteGuardKit
//
//  Created by Rasmus Krämer on 30.11.24.
//

import Foundation
import SwiftData
import RFNotifications

extension PersistenceManager {
    public final actor EndpointSubsystem: ModelActor, Sendable {
        private(set) public var endpoints: [Endpoint] {
            didSet {
                RFNotification[.endpointsChanged].send(endpoints)
            }
        }
        private(set) public var activeEndpointIDs: Set<UUID> {
            didSet {
                RFNotification[.activeEndpointIDsChanged].send(activeEndpointIDs)
                
                Task {
                    await PersistenceManager.shared.keyValue.set(.activeEndpoints(for: PersistenceManager.shared.keyHolder.deviceID), self.activeEndpointIDs)
                }
            }
        }
        
        public nonisolated let modelContainer: ModelContainer
        public nonisolated let modelExecutor: any ModelExecutor
        
        init(modelContainer: SwiftData.ModelContainer) {
            endpoints = []
            activeEndpointIDs = .init()
            
            let modelContext = ModelContext(modelContainer)
            self.modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
            self.modelContainer = modelContainer
        }
        
        func update() throws {
            try updateEndpoints()
            updateActiveEndpointIDs()
        }
        
        func updateEndpoints() throws {
            guard PersistenceManager.shared.keyHolder.secret != nil else {
                print("a")
                
                self.endpoints = []
                return
            }
            
            let encryptedEndpoints = try modelContext.fetch(FetchDescriptor<EncryptedEndpoint>())
            
            let endpoints = encryptedEndpoints.map(\.decrypted)
            let valid = endpoints.compactMap { $0 }
            
            if endpoints.count != valid.count {
                self.endpoints = []
                throw PersistenceError.cryptographicOperationFailed
            } else {
                self.endpoints = valid
            }
        }
        
        func reset() throws {
            try modelContext.delete(model: EncryptedEndpoint.self)
            try modelContext.save()
            
            activeEndpointIDs = []
            
            try updateEndpoints()
        }
    }
}

public extension PersistenceManager.EndpointSubsystem {
    subscript(id: UUID) -> Endpoint? {
        endpoints.first(where: { $0.id == id })
    }
    subscript(id: UUID) -> Bool {
        activeEndpointIDs.contains(id)
    }
    
    func activate(_ id: UUID) {
        activeEndpointIDs.insert(id)
    }
    func deactivate(_ id: UUID) {
        activeEndpointIDs.remove(id)
    }
    
    func store(_ endpoint: Endpoint) throws {
        let encryptedEndpoint = try EncryptedEndpoint(endpoint)
        
        modelContext.insert(encryptedEndpoint)
        try modelContext.save()
        
        try updateEndpoints()
    }
    func delete(_ endpointID: UUID) throws {
        let descriptor = FetchDescriptor<EncryptedEndpoint>(predicate: #Predicate {
            $0.id == endpointID
        })
        let endpoint = try modelContext.fetch(descriptor).first
        
        guard let endpoint else {
            throw PersistenceManager.PersistenceError.endpointNotFound
        }
        
        modelContext.delete(endpoint)
        try modelContext.save()
        
        self.endpoints.removeAll { $0.id == endpointID }
    }
}

private extension PersistenceManager.EndpointSubsystem {
    func updateActiveEndpointIDs() {
        Task {
            self.activeEndpointIDs = .init(await PersistenceManager.shared.keyValue[.activeEndpoints(for: PersistenceManager.shared.keyHolder.deviceID)] ?? [])
        }
    }
}
