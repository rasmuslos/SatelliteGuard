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
    
    @Attribute(.allowsCloudEncryption)
    private(set) var id: UUID!
    
    @Attribute(.allowsCloudEncryption)
    private(set) var added: Date!
    @Attribute(.allowsCloudEncryption)
    private(set) var operatingSystem: OperatingSystem!
    
    @Attribute(.allowsCloudEncryption)
    var sharedKey: Data?
    @Attribute(.allowsCloudEncryption)
    private(set) var publicKey: Data!
    
    @Attribute(.allowsCloudEncryption)
    var activeEndpointIDs: [UUID]!
    
    init() {
        id = PersistenceManager.shared.keyHolder.deviceID
        
        added = .now
        operatingSystem = .current
        
        sharedKey = nil
        publicKey = PersistenceManager.KeyHolderSubsystem.publicSecKeyData
        
        activeEndpointIDs = []
    }
}

extension KeyHolder {
    func store(secret: SymmetricKey) {
        let algorithm: SecKeyAlgorithm = .eciesEncryptionCofactorVariableIVX963SHA256AESGCM
        
        guard SecKeyIsAlgorithmSupported(publicSecKey, .encrypt, algorithm) else {
            fatalError("Unsupported encryption algorithm")
        }
        
        var error: Unmanaged<CFError>?
        
        return secret.withUnsafeBytes {
            let data = Data(Array($0))
            
            guard let cipher = SecKeyCreateEncryptedData(publicSecKey, algorithm, data as CFData, &error) as Data? else {
                fatalError("Couldn't encrypt data: \(error!.takeRetainedValue().localizedDescription)")
            }
            
            self.sharedKey = cipher
        }
    }
    
    var publicSecKey: SecKey {
        let options: [String: Any] = [kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
                                      kSecAttrKeyClass as String: kSecAttrKeyClassPublic]
        
        var error: Unmanaged<CFError>?
        
        guard let key = SecKeyCreateWithData(publicKey as CFData, options as CFDictionary, &error) else {
            fatalError("Couldn't create public key: \(error!.takeRetainedValue().localizedDescription)")
        }
        
        return key
    }
    
    enum OperatingSystem: Int, Codable {
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
