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
    public final actor EndpointSubsystem: ObservableObject {
        private var endpoints: [Endpoint]
        private(set) var activeEndpointIDs: Set<UUID> {
            didSet {
                self.activeEndpointIDsDidChangeSubject.send(activeEndpointIDs)
                
                Task {
                    await PersistenceManager.shared.keyValue.set(.activeEndpoints(for: PersistenceManager.shared.keyHolder.deviceID), Array(self.activeEndpointIDs))
                }
            }
        }
        
        private nonisolated let activeEndpointIDsDidChangeSubject: CurrentValueSubject<Set<UUID>, Never>
        private let context: ModelContext
        
        init(container: ModelContainer) {
            endpoints = []
            activeEndpointIDs = .init()
            
            context = ModelContext(container)
            activeEndpointIDsDidChangeSubject = .init(activeEndpointIDs)
            
            Task {
                await self.updateActiveEndpointIDs()
            }
        }
    }
}

public extension PersistenceManager.EndpointSubsystem {
    var all: [Endpoint] {
        endpoints
    }
    
    var activeEndpointIDsDidChange: AnyPublisher<Set<UUID>, Never> {
        activeEndpointIDsDidChangeSubject.eraseToAnyPublisher()
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
}

private extension PersistenceManager.EndpointSubsystem {
    func updateActiveEndpointIDs() {
        Task {
            self.activeEndpointIDs = .init(await PersistenceManager.shared.keyValue[.activeEndpoints(for: PersistenceManager.shared.keyHolder.deviceID)] ?? [])
        }
    }
}
