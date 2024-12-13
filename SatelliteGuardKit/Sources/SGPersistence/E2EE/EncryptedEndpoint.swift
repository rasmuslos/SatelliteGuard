//
//  EncryptedEndpoint.swift
//  SatelliteGuardKit
//
//  Created by Rasmus Krämer on 30.11.24.
//

import Foundation
import SwiftData
import CryptoKit

@Model
final class EncryptedEndpoint {
    @Attribute(.allowsCloudEncryption)
    private(set) var id: UUID!
    @Attribute(.allowsCloudEncryption)
    private(set) var name: String!
    
    @Attribute(.allowsCloudEncryption)
    private(set) var contents: Data!
    
    @Attribute(.allowsCloudEncryption)
    private(set) var deviceID: UUID!
    
    init(_ endpoint: Endpoint) {
        id = endpoint.id
        name = endpoint.name
        
        contents = encrypt(endpoint)
        
        deviceID = PersistenceManager.shared.keyHolder.deviceID
    }
    
    var decrypted: Endpoint {
        do {
            let box = try ChaChaPoly.SealedBox(combined: contents)
            let contents = try ChaChaPoly.open(box, using: PersistenceManager.shared.keyHolder.secret!)
            
            return try JSONDecoder().decode(Endpoint.self, from: contents)
        } catch {
            fatalError("Could not decrypt \(id!) (\(name!)): \(error.localizedDescription)")
        }
    }
}

// This function has been autocompleted in a single keystroke... Insane
private func encrypt(_ endpoint: Endpoint) -> Data {
    do {
        let contents = try JSONEncoder().encode(endpoint)
        let box = try ChaChaPoly.seal(contents, using: PersistenceManager.shared.keyHolder.secret!)
        
        return box.combined
    } catch {
        fatalError("Could not encrypt \(endpoint): \(error.localizedDescription)")
    }
}
