//
//  KeyValueManager.swift
//  SatelliteGuardKit
//
//  Created by Rasmus Krämer on 30.11.24.
//

import Foundation
import SwiftData

extension PersistenceManager {
    public final actor KeyValueSubsystem {
        private let context: ModelContext
        
        init(container: ModelContainer) {
            context = ModelContext(container)
        }
        
        public func set<Value>(_ key: Key<Value>, _ value: Value?) {
            self[key] = value
        }
        
        // TODO: BROKEN
        public subscript<Value: DataRepresentable>(_ key: Key<Value>) -> Value? {
            get {
                guard let entities = try? context.fetch(FetchDescriptor<KeyValueEntity>()) else {
                    return nil
                }
                
                // let entities: [KeyValueEntity] = []
                
                guard let entity = entities.first else {
                    return nil
                }
                
                return Value(data: entity.value)
            }
            set {
                if let newValue {
                    let entity = KeyValueEntity(key: key.identifier, value: newValue.data)
                    
                    context.insert(entity)
                    try? context.save()
                } else {
                    try? context.delete(model: KeyValueEntity.self)
                    try? context.save()
                }
            }
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
    static var vaultSetup: Key<Date> { .init("vaultSetup") }
    static var vaultInitialDeviceID: Key<UUID> { .init("vaultInitialDeviceID") }
}
