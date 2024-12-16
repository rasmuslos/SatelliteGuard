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
    
    public let modelContainer: ModelContainer
    
    public let keyValue: KeyValueSubsystem
    public let keyHolder: KeyHolderSubsystem
    public let endpoint: EndpointSubsystem
    
    #if os(macOS)
    public nonisolated(unsafe) let defaults = UserDefaults(suiteName: "N8AA4S3S96.io.rfk.SatelliteGuard")!
    #else
    public nonisolated(unsafe) let defaults = UserDefaults(suiteName: "group.io.rfk.SatelliteGuard")!
    #endif
    
    private init() {
        logger = .init(subsystem: "io.rfk.SatelliteGuardKit", category: "PersistenceManager")
        
        let schema = Schema([
            KeyHolder.self,
            KeyValueEntity.self,
            EncryptedEndpoint.self,
        ], version: .init(2, 0, 0))
        
        #if os(macOS)
        let identifier: ModelConfiguration.GroupContainer = .identifier("N8AA4S3S96.io.rfk.SatelliteGuard")
        #else
        let identifier: ModelConfiguration.GroupContainer = .identifier("group.io.rfk.SatelliteGuard")
        #endif
        
        let modelConfiguration = ModelConfiguration("SatelliteGuard",
                                                    schema: schema,
                                                    isStoredInMemoryOnly: false,
                                                    allowsSave: true,
                                                    groupContainer: identifier,
                                                    cloudKitDatabase: .private("iCloud.SatelliteGuard"))
        
        modelContainer = try! ModelContainer(for: schema, configurations: [modelConfiguration])
        
        keyValue = .init(modelContainer: modelContainer)
        keyHolder = .init(modelContainer: modelContainer)
        endpoint = .init(modelContainer: modelContainer)
        
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
        await PersistenceManager.shared.keyHolder.updateKeyHolders()
        
        do {
            try await self.endpoint.update()
        } catch {
            self.keyHolder.authenticationFailed()
        }
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
        case endpointNotFound
        case cryptographicOperationFailed
    }
}

public extension PersistenceManager {
    static let shared = PersistenceManager()
}
