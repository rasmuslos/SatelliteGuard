//
//  KeyHolderManager.swift
//  SatelliteGuardKit
//
//  Created by Rasmus Krämer on 01.12.24.
//

import Foundation
import SwiftData
@preconcurrency import Combine
import CryptoKit

extension PersistenceManager {
    public final actor KeyHolderSubsystem: ObservableObject {
        public typealias ActivatedChangedPayload = UUID
        
        nonisolated(unsafe) var _deviceID: UUID?
        
        private var keyHolders: [KeyHolder]
        
        private(set) nonisolated(unsafe) var secret: SymmetricKey?
        
        private nonisolated let activationChangedPublisher: PassthroughSubject<ActivatedChangedPayload, Never>
        
        private let context: ModelContext
        
        init(container: ModelContainer) {
            context = ModelContext(container)
            keyHolders = .init(try! context.fetch(FetchDescriptor<KeyHolder>()))
            
            secret = nil
            
            activationChangedPublisher = .init()
        }
    }
}

public extension PersistenceManager.KeyHolderSubsystem {
    nonisolated var activationDidChange: AnyPublisher<ActivatedChangedPayload, Never> {
        activationChangedPublisher.eraseToAnyPublisher()
    }
    
    var isVaultSetup: Bool {
        for keyHolder in self.keyHolders {
            if keyHolder.sharedKey != nil {
                return true
            }
        }
        
        return false
    }
    var authorized: Bool {
        secret != nil
    }
    
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
    
    var activeIDs: [UUID] {
        keyHolders.first { $0.id == deviceID }?.activeEndpointIDs ?? []
    }
    
    func joinVault() {
        guard !keyHolders.contains(where: { $0.id == deviceID }) else {
            return
        }
        
        context.insert(KeyHolder())
        try! context.save()
        
        if keyHolders.isEmpty {
            secret = SymmetricKey(size: .bits256)
            
            current.store(secret: secret!)
            try? context.save()
            
            Task {
                await PersistenceManager.shared.keyValue.set(.vaultSetup, .now)
                await PersistenceManager.shared.keyValue.set(.vaultInitialDeviceID, deviceID)
            }
        }
    }
    
    func activate(_ id: Endpoint.ID) throws {
        if !current.activeEndpointIDs.contains(id) {
            current.activeEndpointIDs.append(id)
            try context.save()
        }
        
        activationChangedPublisher.send(id)
    }
    func deactivate(_ id: Endpoint.ID) throws {
        current.activeEndpointIDs.removeAll { $0 == id }
        try context.save()
        
        activationChangedPublisher.send(id)
    }
    
    subscript(id: Endpoint.ID) -> Bool {
        current.activeEndpointIDs.contains(id)
    }
}

extension PersistenceManager.KeyHolderSubsystem {
    static let tag = "io.rfk.SatelliteGuard.keyHolder.privateKey"
    
    static var privateKey: SecKey {
        let query: [String: Any] = [kSecClass as String: kSecClassKey,
                                       kSecAttrApplicationTag as String: tag,
                                       kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
                                       kSecReturnRef as String: true]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecSuccess {
            return item as! SecKey
        }
        
        let attributes: NSDictionary = [
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits: 256,
            kSecAttrTokenID: kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs: [
                kSecAttrIsPermanent: true,
                kSecAttrApplicationTag: tag,
                kSecAttrAccessControl: SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleAfterFirstUnlock, .privateKeyUsage, nil)!,
            ],
        ]
        
        var error: Unmanaged<CFError>?
        
        guard let privateKey = SecKeyCreateRandomKey(attributes, &error) else {
            fatalError(error!.takeRetainedValue().localizedDescription)
        }
        
        return privateKey
    }
    static var publicSecKey: SecKey {
        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            fatalError("Could not extract public key from private key")
        }
        
        return publicKey
    }
    static var publicSecKeyData: Data {
        var error: Unmanaged<CFError>?
        
        guard let data = SecKeyCopyExternalRepresentation(publicSecKey, &error) as? Data else {
            fatalError(error!.takeRetainedValue().localizedDescription)
        }
        
        return data
    }
}


private extension PersistenceManager.KeyHolderSubsystem {
    var current: KeyHolder! {
        keyHolders.first { $0.id == deviceID }
    }
    
    func updateKeyHolders(_ keyHolders: [KeyHolder]) {
        self.keyHolders = keyHolders
    }
    
    func setupObservers() {
        NotificationCenter.default.addObserver(forName: ModelContext.didSave, object: nil, queue: nil) { _ in
            print("abc")
        }
    }
}
