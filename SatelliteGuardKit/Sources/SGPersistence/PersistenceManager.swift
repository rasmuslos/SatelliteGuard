//
//  PersistenceManager.swift
//  SatelliteGuardKit
//
//  Created by Rasmus Krämer on 01.12.24.
//

import Foundation
import SwiftData

public final class PersistenceManager {
    private let schema: Schema
    private let modelConfiguration: ModelConfiguration
    
    public let modelContainer: ModelContainer
    
    private(set) public var keyValue: KeyValueSubsystem
    private(set) public var keyHolder: KeyHolderSubsystem
    private(set) public var endpoint: EndpointSubsystem
    
    private init() {
        schema = .init([
            KeyHolder.self,
            KeyValueEntity.self,
            EncryptedEndpoint.self,
        ], version: .init(2, 0, 0))
        
        modelConfiguration = .init("SatelliteGuard",
                                   schema: schema,
                                   isStoredInMemoryOnly: false,
                                   allowsSave: true,
                                   groupContainer: .identifier("group.io.rfk.SatelliteGuard"),
                                   cloudKitDatabase: .private("iCloud.SatelliteGuard"))
        
        modelContainer = try! ModelContainer(for: schema, configurations: [modelConfiguration])
        
        // MARK: RESET
        
        // try! ModelContext(modelContainer).delete(model: KeyHolder.self)
        
        keyValue = .init(modelContainer: modelContainer)
        keyHolder = .init(modelContainer: modelContainer)
        endpoint = .init(modelContainer: modelContainer)
    }
}

public extension PersistenceManager {
    nonisolated(unsafe) static let shared = PersistenceManager()
}
