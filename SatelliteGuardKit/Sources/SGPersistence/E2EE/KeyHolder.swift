//
//  Keyholder.swift
//  SatelliteGuardKit
//
//  Created by Rasmus Krämer on 30.11.24.
//

import Foundation
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
        publicKey = Self.publicSecKeyData
        
        activeEndpointIDs = []
    }
}

private extension KeyHolder {
    static var privateKey: SecKey {
        let attributes: NSDictionary = [
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits: 256,
            kSecAttrTokenID: kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs: [
                kSecAttrIsPermanent: true,
                kSecAttrApplicationTag: "io.rfk.SatelliteGuard.keyHolder.privateKey",
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

extension KeyHolder {
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
