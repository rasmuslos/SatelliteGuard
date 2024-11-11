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
    
    private var _uuid: UUID?
    public var uuid: UUID {
        if let _uuid {
            return _uuid
        }
        
        if let uuid = UserDefaults.standard.string(forKey: "uuid") {
            _uuid = UUID(uuidString: uuid)!
        } else {
            _uuid = .init()
            UserDefaults.standard.set(_uuid?.uuidString, forKey: "uuid")
        }
        
        return _uuid!
    }
    
    private init() {
        schema = .init([
            Endpoint.self
        ], version: .init(1, 0, 0))
        
        modelConfiguration = .init("SatelliteGuard", schema: schema, isStoredInMemoryOnly: false, allowsSave: true, groupContainer: .identifier("group.io.rfk.SatelliteGuard"), cloudKitDatabase: .private("iCloud.SatelliteGuard"))
        modelContainer = try! ModelContainer(for: schema, configurations: [modelConfiguration])
    }
    
    nonisolated(unsafe) public static let shared = PersistenceManager()
}
