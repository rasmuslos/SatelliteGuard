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
    #Index<EncryptedEndpoint>([\.id])
    // #Unique<EncryptedEndpoint>([\.id])
    
    @Attribute(.allowsCloudEncryption)
    private(set) var id: UUID!
    @Attribute(.allowsCloudEncryption)
    private(set) var name: String!
    
    @Attribute(.allowsCloudEncryption)
    private(set) var contents: Data!
    
    @Attribute(.allowsCloudEncryption)
    private(set) var deviceID: UUID!
    
    init(_ endpoint: Endpoint) throws {
        id = endpoint.id
        name = endpoint.name
        
        contents = try encrypt(endpoint)
        
        deviceID = PersistenceManager.shared.keyHolder.deviceID
    }
    
    var decrypted: Endpoint? {
        guard let secret = PersistenceManager.shared.keyHolder.secret else {
            return nil
        }
        
        do {
            let box = try ChaChaPoly.SealedBox(combined: contents)
            let contents = try ChaChaPoly.open(box, using: secret)
            
            return try JSONDecoder().decode(Endpoint.self, from: contents)
        } catch {
            return nil
        }
    }
}

// This function has been autocompleted in a single keystroke... Insane
private func encrypt(_ endpoint: Endpoint) throws -> Data {
    do {
        let contents = try JSONEncoder().encode(endpoint)
        let box = try ChaChaPoly.seal(contents, using: PersistenceManager.shared.keyHolder.secret!)
        
        return box.combined
    } catch {
        throw PersistenceManager.PersistenceError.cryptographicOperationFailed
    }
}
