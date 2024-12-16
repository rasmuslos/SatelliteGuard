//
//  KeyHolderManager.swift
//  SatelliteGuardKit
//
//  Created by Rasmus Krämer on 01.12.24.
//

import Foundation
import OSLog
import SwiftData
import CryptoKit
import RFNotifications

extension PersistenceManager {
    public final actor KeyHolderSubsystem: ModelActor, Sendable {
        private var keyHolders: [KeyHolder]
        
        private nonisolated(unsafe) var _deviceID: UUID?
        private(set) nonisolated(unsafe) var secret: SymmetricKey?
        
        public nonisolated let modelContainer: ModelContainer
        public nonisolated let modelExecutor: any ModelExecutor
        
        private let logger: Logger
        
        init(modelContainer: ModelContainer) {
            logger = Logger(subsystem: "SatelliteGuardKit", category: "KeyHolder")
            
            keyHolders = []
            
            _deviceID = nil
            secret = nil
            
            let modelContext = ModelContext(modelContainer)
            self.modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
            self.modelContainer = modelContainer
            
            logger.info("Initialized KeyHolderSubsystem")
            
            Task {
                await removeDuplicates()
            }
        }
        
        nonisolated func authenticationFailed() {
            RFNotification[.authorizationChanged].send(.establishingFailed)
        }
        
        func reset() throws {
            try modelContext.delete(model: KeyHolder.self)
            try modelContext.save()
            
            updateKeyHolders()
            
            logger.warning("Reseted KeyHolderSubsystem")
        }
        
        public typealias UnauthorizedKeyHolder = (id: UUID, added: Date, operatingSystem: OperatingSystem, publicKeyVerifier: [String])
        
        public enum AuthorizationStatus: Sendable, CustomDebugStringConvertible {
            case establishing
            case establishingFailed
            
            case none
            case authorized
            case missingSecretCreateStrategy
            case missingSecretRequestStrategy
            
            public var debugDescription: String {
                switch self {
                case .establishing:
                    "establishing"
                case .establishingFailed:
                    "establishingFailed"
                case .none:
                    "none"
                case .authorized:
                    "authorized"
                case .missingSecretCreateStrategy:
                    "missingSecretCreateStrategy"
                case .missingSecretRequestStrategy:
                    "missingSecretRequestStrategy"
                }
            }
        }
        
        public enum OperatingSystem: Int, Sendable, Codable {
            case iOS
            case tvOS
            case macOS
            
            static var current: OperatingSystem {
                #if os(iOS)
                .iOS
                #elseif os(tvOS)
                .tvOS
                #elseif os(macOS)
                .macOS
                #endif
            }
        }
    }
}

public extension PersistenceManager.KeyHolderSubsystem {
    nonisolated var deviceID: UUID {
        if let _deviceID = _deviceID {
            return _deviceID
        }
        
        if let deviceID = PersistenceManager.shared.defaults.string(forKey: "deviceID") {
            _deviceID = UUID(uuidString: deviceID)!
        } else {
            _deviceID = .init()
            logger.info( "Generating new device ID: \(self._deviceID!)")
            
            PersistenceManager.shared.defaults.set(_deviceID?.uuidString, forKey: "deviceID")
        }
        
        return _deviceID!
    }
    
    nonisolated var emojiCode: [String] {
        EmojiConverter.convert([UInt8](KeyHolder.publicSecKeyData))
    }
  
    func updateKeyHolders() {
        do {
            self.keyHolders = try modelContext.fetch(FetchDescriptor<KeyHolder>())
        } catch {
            authenticationFailed()
            return
        }
        
        if let current {
            secret = current.secret
        }
        
        let unauthorized = keyHolders.filter { $0.sharedKey == nil }.map {
            ($0.id!, $0.added!, $0.operatingSystem!, EmojiConverter.convert([UInt8]($0.publicKey)))
        }
        
        logger.info("\(self.keyHolders.count) key holders found (unauthorized: \(unauthorized.count))")
        
        Task { [unauthorized] in
            await self.updateAuthorization()
            RFNotification[.unauthorizedKeyHoldersChanged].send(unauthorized)
        }
    }
    
    func createKeyHolder() throws {
        guard current == nil else {
            return
        }
        
        guard !keyHolders.contains(where: { $0.id == deviceID }) else {
            return
        }
        
        let keyHolder = KeyHolder()
        
        modelContext.insert(keyHolder)
        
        do {
            try modelContext.save()
        } catch {
            fatalError("Could not create key holder")
        }
        
        self.updateKeyHolders()
        
        logger.info( "Created key holder \(keyHolder.id)")
    }
    
    func createSecret() {
        guard keyHolders.count == 1 && secret == nil else {
            return
        }
        
        secret = SymmetricKey(size: .bits256)
        current.sharedKey = encryptSecret(current.publicSecKey)
        
        do {
            try modelContext.save()
        } catch {
            authenticationFailed()
            return
        }
        
        Task {
            await PersistenceManager.shared.keyValue.set(.secretCreated, .now)
            await PersistenceManager.shared.keyValue.set(.secretCreator, self.deviceID)
        }
        
        self.updateKeyHolders()
    }
    
    func deny(_ deviceID: UUID) {
        guard let keyHolder = keyHolders.first(where: { $0.id == deviceID }) else {
            fatalError("Device ID not found")
        }
        
        do {
            modelContext.delete(keyHolder)
            try modelContext.save()
        } catch {
            authenticationFailed()
        }
        
        updateKeyHolders()
    }
    func trust(_ deviceID: UUID) {
        guard let keyHolder = keyHolders.first(where: { $0.id == deviceID }) else {
            fatalError("Device ID not found")
        }
        
        keyHolder.sharedKey = encryptSecret(keyHolder.publicSecKey)
        
        do {
            try modelContext.save()
        } catch {
            authenticationFailed()
        }
        
        updateKeyHolders()
    }
}

private extension PersistenceManager.KeyHolderSubsystem {
    var current: KeyHolder! {
        keyHolders.first { $0.id == deviceID }
    }
    
    func removeDuplicates() {
        let duplicates = Dictionary(keyHolders.map { ($0.id, [$0]) }, uniquingKeysWith: { $0 + [$1] }).filter { $0.value.count > 1 } as! [UUID: [KeyHolder]]
        if !duplicates.isEmpty {
            logger.fault( "Found \(duplicates.count) key holders with duplicate IDs: \(duplicates)")
            
            for keyHolders in duplicates.values {
                for keyHolder in keyHolders {
                    modelContext.delete(keyHolder)
                }
            }
            
            do {
                try modelContext.save()
            } catch {
                authenticationFailed()
            }
        }
    }
    
    func encryptSecret(_ publicKey: SecKey) -> Data? {
        guard SecKeyIsAlgorithmSupported(publicKey, .encrypt, KeyHolder.algorithm) else {
            fatalError("Unsupported encryption algorithm")
        }
        
        return secret?.withUnsafeBytes {
            var error: Unmanaged<CFError>?
            let data = Data(Array($0))
            
            guard data.count <= SecKeyGetBlockSize(publicKey) else {
                fatalError("Data too large")
            }
            
            guard let cipher = SecKeyCreateEncryptedData(publicKey, KeyHolder.algorithm, data as CFData, &error) as Data? else {
                fatalError("Couldn't encrypt data: \(error!.takeRetainedValue().localizedDescription)")
            }
            
            return cipher
        }
    }
    
    func updateAuthorization() async {
        if current == nil {
            RFNotification[.authorizationChanged].send(.none)
        } else if secret != nil {
            RFNotification[.authorizationChanged].send(.authorized)
        } else if keyHolders.count == 1 {
            RFNotification[.authorizationChanged].send(.missingSecretCreateStrategy)
        } else {
            RFNotification[.authorizationChanged].send(.missingSecretRequestStrategy)
        }
    }
}
