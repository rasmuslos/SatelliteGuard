//
//  KeyValueManager.swift
//  SatelliteGuardKit
//
//  Created by Rasmus Krämer on 30.11.24.
//

import Foundation
import SwiftData

extension PersistenceManager {
    @ModelActor
    public final actor KeyValueSubsystem: Sendable {
        public func set<Value>(_ key: Key<Value>, _ value: Value?) {
            self[key] = value
        }
        
        public subscript<Value: DataRepresentable>(_ key: Key<Value>) -> Value? {
            get {
                let identifier = key.identifier
                
                guard let entity = try? modelContext.fetch(FetchDescriptor<KeyValueEntity>(predicate: #Predicate { $0.key == identifier })).first else {
                    return nil
                }
                
                return Value(data: entity.value)
            }
            set {
                let identifier = key.identifier
                
                if let newValue {
                    if let existing = try? modelContext.fetch(FetchDescriptor<KeyValueEntity>(predicate: #Predicate { $0.key == identifier })).first {
                        existing.value = newValue.data
                    } else {
                        let entity = KeyValueEntity(key: key.identifier, value: newValue.data)
                        modelContext.insert(entity)
                    }
                    
                    try? modelContext.save()
                } else {
                    try? modelContext.delete(model: KeyValueEntity.self, where: #Predicate { $0.key == identifier })
                    try? modelContext.save()
                }
            }
        }
        
        func reset() throws {
            try modelContext.delete(model: KeyValueEntity.self)
        }
        
        public protocol DataRepresentable: Sendable {
            init?(data: Data)
            var data: Data { get }
        }
        
        public struct Key<Value: DataRepresentable>: Sendable {
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
