//
//  EndpointManager.swift
//  SatelliteGuardKit
//
//  Created by Rasmus Krämer on 30.11.24.
//

import Foundation
import SwiftData
import CryptoKit

extension PersistenceManager {
    public final actor EndpointSubsystem: ObservableObject {
        private let context: ModelContext
        
        private var endpoints: [EncryptedEndpoint]
        
        init(container: ModelContainer) {
            context = ModelContext(container)
            endpoints = try! context.fetch(FetchDescriptor<EncryptedEndpoint>())
        }
    }
}

public extension PersistenceManager.EndpointSubsystem {
    var all: [Endpoint] {
        []
    }
    
    subscript (id: UUID) -> Endpoint? {
        guard let endpoint = endpoints.first(where: { $0.id == id }) else {
            return nil
        }
        
        return decrypt(endpoint.contents)
    }
    
    func store(endpoint: Endpoint) async throws {
        
    }
}

private extension PersistenceManager.EndpointSubsystem {
    func decrypt(_ data: Data) -> Endpoint {
        do {
            let box = try ChaChaPoly.SealedBox(combined: data)
            let contents = try ChaChaPoly.open(box, using: PersistenceManager.shared.keyHolder.secret!)
            
            return try JSONDecoder().decode(Endpoint.self, from: contents)
        } catch {
            fatalError("Could not decrypt \(data): \(error.localizedDescription)")
        }
    }
}
