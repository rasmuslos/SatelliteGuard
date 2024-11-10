//
//  SGPersistence.swift
//  SatelliteGuardKit
//
//  Created by Rasmus Krämer on 10.11.24.
//

import Foundation
import SwiftData

public class PersistenceManager {
    let schema: Schema
    let modelConfiguration: ModelConfiguration
    public let modelContainer: ModelContainer
    
    private init() {
        schema = .init([
            Endpoint.self
        ], version: .init(1, 0, 0))
        
        modelConfiguration = .init("SatelliteGuard", schema: schema, isStoredInMemoryOnly: false, allowsSave: true, groupContainer: .automatic, cloudKitDatabase: .none)
        modelContainer = try! ModelContainer(for: schema, configurations: [modelConfiguration])
    }
    
    nonisolated(unsafe) public static let shared = PersistenceManager()
}
