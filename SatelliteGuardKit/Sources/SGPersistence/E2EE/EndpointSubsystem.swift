//
//  EndpointManager.swift
//  SatelliteGuardKit
//
//  Created by Rasmus Krämer on 30.11.24.
//

import Foundation
import SwiftData
@preconcurrency import Combine

extension PersistenceManager {
    public final actor EndpointSubsystem: ModelActor {
        private var endpoints: [Endpoint]
        private(set) var activeEndpointIDs: Set<UUID> {
            didSet {
                self.activeEndpointIDsDidChangeSubject.send(activeEndpointIDs)
                
                Task {
                    await PersistenceManager.shared.keyValue.set(.activeEndpoints(for: PersistenceManager.shared.keyHolder.deviceID), Array(self.activeEndpointIDs))
                }
            }
        }
        
        public nonisolated let modelContainer: ModelContainer
        public nonisolated let modelExecutor: any ModelExecutor
        
        private nonisolated let endpointsDidChangeSubject: CurrentValueSubject<[Endpoint], Never>
        private nonisolated let activeEndpointIDsDidChangeSubject: CurrentValueSubject<Set<UUID>, Never>
        
        private nonisolated(unsafe) var cancellable: AnyCancellable?
        
        init(modelContainer: SwiftData.ModelContainer) {
            endpoints = []
            activeEndpointIDs = .init()
            
            endpointsDidChangeSubject = .init(endpoints)
            activeEndpointIDsDidChangeSubject = .init(activeEndpointIDs)
            
            let modelContext = ModelContext(modelContainer)
            self.modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
            self.modelContainer = modelContainer
            
            cancellable = nil
            
            Task {
                // This is here to run slightly after the init of `PersistenceManager`
                createObservers()
                
                await self.updateActiveEndpointIDs()
            }
        }
    }
}

public extension PersistenceManager.EndpointSubsystem {
    var all: [Endpoint] {
        endpoints
    }
    
    nonisolated var activeEndpointIDsDidChange: AnyPublisher<Set<UUID>, Never> {
        activeEndpointIDsDidChangeSubject.eraseToAnyPublisher()
    }
    nonisolated var endpointsDidChange: AnyPublisher<[Endpoint], Never> {
        endpointsDidChangeSubject.eraseToAnyPublisher()
    }
    
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
    
    func store(_ endpoint: Endpoint) {
        let encryptedEndpoint = EncryptedEndpoint(endpoint)
        
        modelContext.insert(encryptedEndpoint)
        
        do {
            try modelContext.save()
        } catch {
            Task {
                PersistenceManager.shared.keyHolder.failedToEstablishAuthorization()
            }
        }
    }
}

private extension PersistenceManager.EndpointSubsystem {
    func updateEndpoints() {
        do {
            let encryptedEndpoints = try modelContext.fetch(FetchDescriptor<EncryptedEndpoint>())
            
            endpoints = encryptedEndpoints.map(\.decrypted)
            endpointsDidChangeSubject.value = endpoints
        } catch {
            Task {
                PersistenceManager.shared.keyHolder.failedToEstablishAuthorization()
            }
        }
    }
    func updateActiveEndpointIDs() {
        Task {
            self.activeEndpointIDs = .init(await PersistenceManager.shared.keyValue[.activeEndpoints(for: PersistenceManager.shared.keyHolder.deviceID)] ?? [])
        }
    }
    
    nonisolated func createObservers() {
        cancellable = PersistenceManager.shared.keyHolder.authorizationDidChange.sink { [weak self] in
            guard $0 == .authorized else {
                return
            }
            
            Task { [weak self] in
                await self?.updateEndpoints()
                await self?.updateActiveEndpointIDs()
            }
        }
    }
}
