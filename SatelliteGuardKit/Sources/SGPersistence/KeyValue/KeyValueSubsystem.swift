//
//  KeyValueManager.swift
//  SatelliteGuardKit
//
//  Created by Rasmus Krämer on 30.11.24.
//

import Foundation
import SwiftData
import OSLog

extension PersistenceManager {
    @ModelActor
    public final actor KeyValueSubsystem: Sendable {
        private let logger = Logger(subsystem: "SatelliteGuardKit", category: "KeyValue")
        
        public func set<Value>(_ key: Key<Value>, _ value: Value?) {
            self[key] = value
        }
        
        public subscript<Value: Codable>(_ key: Key<Value>) -> Value? {
            get {
                let identifier = key.identifier
                
                guard let entity = try? modelContext.fetch(FetchDescriptor<KeyValueEntity>(predicate: #Predicate { $0.key == identifier })).first else {
                    return nil
                }
                
                do {
                    return try JSONDecoder().decode(Value.self, from: entity.value)
                } catch {
                    logger.error("Failed to decode \(Value.self): \(error)")
                    return nil
                }
            }
            set {
                let identifier = key.identifier
                
                if let newValue {
                    do {
                        let data = try JSONEncoder().encode(newValue)
                        
                        if let existing = try? modelContext.fetch(FetchDescriptor<KeyValueEntity>(predicate: #Predicate { $0.key == identifier })).first {
                            existing.value = data
                        } else {
                            let entity = KeyValueEntity(key: key.identifier, value: data)
                            modelContext.insert(entity)
                        }
                        
                        try modelContext.save()
                    } catch {
                        logger.error("Failed to encode \(Value.self) or save: \(error)")
                        return
                    }
                } else {
                    try? modelContext.delete(model: KeyValueEntity.self, where: #Predicate { $0.key == identifier })
                    try? modelContext.save()
                }
            }
        }
        
        func reset() throws {
            try modelContext.delete(model: KeyValueEntity.self)
        }
        
        public struct Key<Value: Codable>: Sendable {
            public typealias Key = PersistenceManager.KeyValueSubsystem.Key
            
            let identifier: String
            
            init(_ identifier: String) {
                self.identifier = identifier
            }
        }
    }
}

public extension PersistenceManager.KeyValueSubsystem.Key {
    static var secretCreated: Key<Date> { .init("secretCreated") }
    static var secretCreator: Key<UUID> { .init("secretCreator") }
    
    static func activeEndpoints(for keyHolder: UUID) -> Key<Set<UUID>> {
        .init("activeEndpoints_\(keyHolder)")
    }
}
