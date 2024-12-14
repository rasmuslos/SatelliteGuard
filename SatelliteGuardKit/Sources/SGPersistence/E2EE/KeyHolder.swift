//
//  Keyholder.swift
//  SatelliteGuardKit
//
//  Created by Rasmus Krämer on 30.11.24.
//

import Foundation
import CryptoKit
import SwiftData

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@Model
final class KeyHolder {
    #Index<KeyHolder>([\.id])
    // #Unique<KeyHolder>([\.id])
    
    @Attribute(.allowsCloudEncryption)
    private(set) var id: UUID!
    
    @Attribute(.allowsCloudEncryption)
    private(set) var added: Date!
    @Attribute(.allowsCloudEncryption)
    private(set) var operatingSystem: PersistenceManager.KeyHolderSubsystem.OperatingSystem!
    
    @Attribute(.allowsCloudEncryption)
    var sharedKey: Data?
    @Attribute(.allowsCloudEncryption)
    private(set) var publicKey: Data!
    
    init() {
        id = PersistenceManager.shared.keyHolder.deviceID
        
        added = .now
        operatingSystem = .current
        
        sharedKey = nil
        publicKey = Self.publicSecKeyData
    }
}

extension KeyHolder {
    var publicSecKey: SecKey {
        let options: [String: Any] = [kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
                                      kSecAttrKeyClass as String: kSecAttrKeyClassPublic]
        
        var error: Unmanaged<CFError>?
        
        guard let key = SecKeyCreateWithData(publicKey as CFData, options as CFDictionary, &error) else {
            fatalError("Couldn't create public key: \(error!.takeRetainedValue().localizedDescription)")
        }
        
        return key
    }
    
    var secret: SymmetricKey? {
        guard let sharedKey else {
            return nil
        }
        
        guard SecKeyIsAlgorithmSupported(Self.privateKey, .decrypt, Self.algorithm) else {
            fatalError("Unsupported decryption algorithm")
        }
        
        var error: Unmanaged<CFError>?
        
        guard let key = SecKeyCreateDecryptedData(Self.privateKey, Self.algorithm, sharedKey as CFData, &error) as Data? else {
            fatalError("Could not decrypt data")
        }
        
        return SymmetricKey(data: key)
    }
}

// MARK: Device keys

extension KeyHolder {
    static let tag = "io.rfk.SatelliteGuard.keyHolder.privateKey"
    static let algorithm: SecKeyAlgorithm = .eciesEncryptionStandardVariableIVX963SHA512AESGCM
    
    static var privateKey: SecKey {
        let query: NSDictionary = [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: tag,
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            
            kSecReturnRef: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecSuccess {
            return item as! SecKey
        }
        
        let attributes: NSDictionary = [
            kSecAttrTokenID: kSecAttrTokenIDSecureEnclave,
            kSecAttrKeySizeInBits: 256,
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            
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
