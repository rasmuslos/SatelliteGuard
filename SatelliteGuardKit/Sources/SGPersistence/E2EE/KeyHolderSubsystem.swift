//
//  KeyHolderManager.swift
//  SatelliteGuardKit
//
//  Created by Rasmus Krämer on 01.12.24.
//

import Foundation
import SwiftData
import OSLog
@preconcurrency import Combine
import CryptoKit

extension PersistenceManager {
    public final actor KeyHolderSubsystem: ModelActor {
        private var keyHolders: [KeyHolder]
        
        private nonisolated(unsafe) var _deviceID: UUID?
        private(set) nonisolated(unsafe) var secret: SymmetricKey?
        
        public nonisolated let modelContainer: ModelContainer
        public nonisolated let modelExecutor: any ModelExecutor
        
        private nonisolated let authorizationDidChangeSubject: CurrentValueSubject<AuthorizationStatus, Never>
        private nonisolated let unauthorizedKeyHolderIDsDidChangeSubject: CurrentValueSubject<[UnauthorizedKeyHolder], Never>
        
        public static let logger = Logger(subsystem: "SatelliteGuardKit", category: "KeyHolder")
        
        init(modelContainer: ModelContainer) {
            _deviceID = nil
            secret = nil
            
            let modelContext = ModelContext(modelContainer)
            self.modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
            self.modelContainer = modelContainer
            
            authorizationDidChangeSubject = .init(.establishing)
            unauthorizedKeyHolderIDsDidChangeSubject = .init([])
            
            do {
                keyHolders = try modelContext.fetch(FetchDescriptor<KeyHolder>())
            } catch {
                keyHolders = []
                authorizationDidChangeSubject.value = .establishingFailed
            }
            
            Task {
                await self.logInit()
                await self.updateKeyHolders()
            }
            
            // MARK: RESET

            // print(SecItemDelete([
            //   kSecClass: kSecClassKey,
            //   kSecAttrSynchronizable: kSecAttrSynchronizableAny
            // ] as CFDictionary))
        }
        
        nonisolated func failedToEstablishAuthorization() {
            authorizationDidChangeSubject.value = .establishingFailed
        }
        
        public typealias UnauthorizedKeyHolder = (id: UUID, added: Date, operatingSystem: OperatingSystem, publicKeyVerifier: [String])
        
        public enum AuthorizationStatus: CustomDebugStringConvertible {
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
        
        public enum OperatingSystem: Int, Codable {
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
        
        if let deviceID = UserDefaults.standard.string(forKey: "deviceID") {
            _deviceID = UUID(uuidString: deviceID)!
        } else {
            _deviceID = .init()
            UserDefaults.standard.set(_deviceID?.uuidString, forKey: "deviceID")
        }
        
        return _deviceID!
    }
    
    nonisolated var emojiCode: [String] {
        EmojiConverter.convert([UInt8](KeyHolder.publicSecKeyData))
    }
    
    nonisolated var authorizationDidChange: AnyPublisher<AuthorizationStatus, Never> {
        authorizationDidChangeSubject.eraseToAnyPublisher()
    }
    nonisolated var unauthorizedKeyHolderIDsDidChange: AnyPublisher<[UnauthorizedKeyHolder], Never> {
        unauthorizedKeyHolderIDsDidChangeSubject.eraseToAnyPublisher()
    }
    
    func updateKeyHolders() {
        do {
            self.keyHolders = try modelContext.fetch(FetchDescriptor<KeyHolder>())
        } catch {
            failedToEstablishAuthorization()
            return
        }
        
        let unauthorized = keyHolders.filter { $0.sharedKey == nil }
        unauthorizedKeyHolderIDsDidChangeSubject.value = unauthorized.map {
            ($0.id, $0.added, $0.operatingSystem, EmojiConverter.convert([UInt8]($0.publicKey)))
        }
        
        if let current {
            secret = current.secret
        }
        
        updateAuthorization()
    }
    
    func createKeyHolder() {
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
            
            updateKeyHolders()
        } catch {
            failedToEstablishAuthorization()
        }
    }
    
    func createSecret() {
        guard keyHolders.count == 1 && secret == nil else {
            return
        }
        
        secret = SymmetricKey(size: .bits256)
        
        do {
            current.sharedKey = encryptSecret(current.publicSecKey)
            try modelContext.save()
        } catch {
            failedToEstablishAuthorization()
            return
        }
        
        Task {
            await PersistenceManager.shared.keyValue.set(.secretCreated, .now)
            await PersistenceManager.shared.keyValue.set(.secretCreator, deviceID)
        }
        
        updateAuthorization()
    }
    
    func reset() {
        SecItemDelete([
           kSecClass: kSecClassKey,
           kSecAttrSynchronizable: kSecAttrSynchronizableAny
         ] as CFDictionary)
        
        do {
            try modelContext.delete(model: KeyHolder.self)
            try modelContext.save()
            
            updateKeyHolders()
        } catch {
            failedToEstablishAuthorization()
        }
    }
    
    func deny(_ deviceID: UUID) {
        do {
            guard let keyHolder = keyHolders.first(where: { $0.id == deviceID }) else {
                fatalError("Device ID not found")
            }
            
            modelContext.delete(keyHolder)
            try modelContext.save()
            
            updateKeyHolders()
        } catch {
            failedToEstablishAuthorization()
        }
    }
    func trust(_ deviceID: UUID) {
        guard let keyHolder = keyHolders.first(where: { $0.id == deviceID }) else {
            fatalError("Device ID not found")
        }
        
        keyHolder.sharedKey = encryptSecret(keyHolder.publicSecKey)
        
        do {
            try modelContext.save()
        } catch {
            failedToEstablishAuthorization()
        }
    }
}

private extension PersistenceManager.KeyHolderSubsystem {
    var current: KeyHolder! {
        keyHolders.first { $0.id == deviceID }
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
    
    func updateAuthorization() {
        guard authorizationDidChangeSubject.value != .establishingFailed else {
            return
        }
        
        if current == nil {
            authorizationDidChangeSubject.value = .none
        } else if secret != nil {
            authorizationDidChangeSubject.value = .authorized
        } else if keyHolders.count == 1 {
            authorizationDidChangeSubject.value = .missingSecretCreateStrategy
        } else {
            authorizationDidChangeSubject.value = .missingSecretRequestStrategy
        }
        
        Self.logger.info("Authorization status: \(self.authorizationDidChangeSubject.value.debugDescription)")
    }
}

private extension PersistenceManager.KeyHolderSubsystem {
    func logInit() {
        Self.logger.info("KeyHolderSubsystem initialized (keyHolders: \(self.keyHolders.count), deviceID: \(self.deviceID))")
        
        Task {
            if let secretCreated = await PersistenceManager.shared.keyValue[.secretCreated],
               let secretCreator = await PersistenceManager.shared.keyValue[.secretCreator] {
                Self.logger.info("Secret created: \(secretCreated), creator: \(secretCreator)")
            }
        }
    }
}
