//
//  PersistenceManager.swift
//  SatelliteGuardKit
//
//  Created by Rasmus Krämer on 01.12.24.
//

import Foundation
import SwiftData
import OSLog

public final class PersistenceManager: Sendable {
    private let logger: Logger
    private let signPoster: OSSignposter
    
    public let modelContainer: ModelContainer
    
    public let keyValue: KeyValueSubsystem
    public let keyHolder: KeyHolderSubsystem
    public let endpoint: EndpointSubsystem
    
    private init() {
        logger = .init(subsystem: "io.rfk.SatelliteGuardKit", category: "PersistenceManager")
        signPoster = .init(logger: logger)
        
        let signPostID = signPoster.makeSignpostID()
        let signPostState = signPoster.beginInterval("init", id: signPostID)
        
        let schema = Schema([
            KeyHolder.self,
            KeyValueEntity.self,
            EncryptedEndpoint.self,
        ], version: .init(2, 0, 0))
        
        let modelConfiguration = ModelConfiguration("SatelliteGuard",
                                   schema: schema,
                                   isStoredInMemoryOnly: false,
                                   allowsSave: true,
                                   groupContainer: .identifier("group.io.rfk.SatelliteGuard"),
                                   cloudKitDatabase: .private("iCloud.SatelliteGuard"))
        
        modelContainer = try! ModelContainer(for: schema, configurations: [modelConfiguration])
        
        signPoster.emitEvent("Created model container", id: signPostID)
        
        keyValue = .init(modelContainer: modelContainer)
        keyHolder = .init(modelContainer: modelContainer)
        endpoint = .init(modelContainer: modelContainer)
        
        signPoster.endInterval("init", signPostState)
        
        // MARK: RESET
        
        #if RESET
        Task {
            try! await PersistenceManager.shared.reset()
        }
        #endif
        
        Task {
            await self.update()
        }
    }
    
    public func update() async {
        let signPostID = signPoster.makeSignpostID()
        let signPostState = self.signPoster.beginInterval("update", id: signPostID)
        
        await self.keyHolder.updateKeyHolders()
        
        do {
            try await self.endpoint.update()
        } catch {
            self.keyHolder.authenticationFailed()
        }
        
        self.signPoster.endInterval("update", signPostState)
    }
    
    public func reset() async throws {
        SecItemDelete([
           kSecClass: kSecClassKey,
           kSecAttrSynchronizable: kSecAttrSynchronizableAny
         ] as CFDictionary)
        
        try await endpoint.reset()
        try await keyHolder.reset()
        try await keyValue.reset()
    }
    
    public enum PersistenceError: Error {
        case cryptographicOperationFailed
    }
}

public extension PersistenceManager {
    static let shared = PersistenceManager()
}
