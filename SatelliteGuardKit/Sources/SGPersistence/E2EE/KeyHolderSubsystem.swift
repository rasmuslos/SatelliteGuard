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
    public final actor KeyHolderSubsystem: ObservableObject {
        private nonisolated(unsafe) var _deviceID: UUID?
        private(set) nonisolated(unsafe) var secret: SymmetricKey?
        
        private var keyHolders: [KeyHolder]
        
        private nonisolated let authorizationDidChangeSubject: CurrentValueSubject<AuthorizationStatus, Never>
        private let context: ModelContext
        
        private nonisolated(unsafe) var cancellable: AnyCancellable?
        
        public static let logger = Logger(subsystem: "SatelliteGuardKit", category: "KeyHolder")
        
        init(container: ModelContainer) {
            _deviceID = nil
            secret = nil
            
            context = ModelContext(container)
            authorizationDidChangeSubject = .init(.establishing)
            
            do {
                keyHolders = try context.fetch(FetchDescriptor<KeyHolder>())
            } catch {
                keyHolders = []
                authorizationDidChangeSubject.send(.establishingFailed)
            }
            
            cancellable = nil
            createObservers()
            
            Task {
                await self.logInit()
                await self.updateKeyHolders()
            }
            
            // MARK: RESET

            print(SecItemDelete([
              kSecClass: kSecClassKey,
              kSecAttrSynchronizable: kSecAttrSynchronizableAny
            ] as CFDictionary))
        }
        
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
    
    nonisolated var authorizationDidChange: AnyPublisher<AuthorizationStatus, Never> {
        authorizationDidChangeSubject.eraseToAnyPublisher()
    }
    
    func createKeyHolder() {
        guard current == nil else {
            return
        }
        
        guard !keyHolders.contains(where: { $0.id == deviceID }) else {
            return
        }
        
        let keyHolder = KeyHolder()
        
        context.insert(keyHolder)
        
        do {
            try context.save()
        } catch {
            authorizationDidChangeSubject.send(.establishingFailed)
            return
        }
        
        updateKeyHolders()
    }
    
    func createSecret() {
        guard keyHolders.count == 1 && secret == nil else {
            return
        }
        
        secret = SymmetricKey(size: .bits256)
        
        do {
            try current.store(secret: secret!)
            try context.save()
        } catch {
            authorizationDidChangeSubject.send(.establishingFailed)
            return
        }
        
        Task {
            await PersistenceManager.shared.keyValue.set(.secretCreated, .now)
            await PersistenceManager.shared.keyValue.set(.secretCreator, deviceID)
        }
        
        updateAuthorization()
    }
    
    func reset() {
        do {
            try context.delete(model: KeyHolder.self)
            try context.save()
        } catch {
            authorizationDidChangeSubject.send(.establishingFailed)
            return
        }
        
        updateKeyHolders()
    }
}

private extension PersistenceManager.KeyHolderSubsystem {
    var current: KeyHolder! {
        keyHolders.first { $0.id == deviceID }
    }
    
    func updateKeyHolders() {
        self.keyHolders = try! context.fetch(FetchDescriptor<KeyHolder>())
        
        if let current, let sharedKey = current.sharedKey {
            print(current.key)
        }
        
        updateAuthorization()
    }
    
    func updateAuthorization() {
        guard authorizationDidChangeSubject.value != .establishingFailed else {
            return
        }
        
        if current == nil {
            authorizationDidChangeSubject.send(.none)
        } else if secret != nil {
            authorizationDidChangeSubject.send(.authorized)
        } else if keyHolders.count == 1 {
            authorizationDidChangeSubject.send(.missingSecretCreateStrategy)
        } else {
            authorizationDidChangeSubject.send(.missingSecretRequestStrategy)
        }
        
        Self.logger.info("Authorization status: \(self.authorizationDidChangeSubject.value.debugDescription)")
    }
}

private extension PersistenceManager.KeyHolderSubsystem {
    nonisolated func createObservers() {
        cancellable = NotificationCenter.default.publisher(for: ModelContext.didSave).sink { [weak self] _ in
            Task { [weak self] in
                await self?.updateKeyHolders()
            }
        }
    }
    
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
