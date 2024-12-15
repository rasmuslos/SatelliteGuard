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
        
        private var stash: RFNotification.MarkerStash
        
        init(modelContainer: SwiftData.ModelContainer) {
            endpoints = []
            activeEndpointIDs = .init()
            
            let modelContext = ModelContext(modelContainer)
            self.modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
            self.modelContainer = modelContainer
            
            stash = .init()
            
            Task {
                await createObservers()
            }
        }
        
        func update() throws {
            try updateEndpoints()
            updateActiveEndpointIDs()
        }
        
        func updateEndpoints() throws {
            guard PersistenceManager.shared.keyHolder.secret != nil else {
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
}

private extension PersistenceManager.EndpointSubsystem {
    func updateActiveEndpointIDs() {
        Task {
            self.activeEndpointIDs = .init(await PersistenceManager.shared.keyValue[.activeEndpoints(for: PersistenceManager.shared.keyHolder.deviceID)] ?? [])
        }
    }
    
    func createObservers() {
        RFNotification[.authorizationChanged].subscribe(queue: .current) {
            guard $0 == .authorized else {
                return
            }
            
            Task {
                do {
                    try await self.updateEndpoints()
                } catch {
                    PersistenceManager.shared.keyHolder.authenticationFailed()
                }
            }
        }.store(in: &stash)
    }
}
