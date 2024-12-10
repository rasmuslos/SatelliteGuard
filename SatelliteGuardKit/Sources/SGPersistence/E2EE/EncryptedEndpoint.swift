//
//  EncryptedEndpoint.swift
//  SatelliteGuardKit
//
//  Created by Rasmus Krämer on 30.11.24.
//

import Foundation
import SwiftData

@Model
final class EncryptedEndpoint {
    @Attribute(.allowsCloudEncryption)
    private(set) var id: UUID!
    @Attribute(.allowsCloudEncryption)
    private(set) var name: String!
    
    @Attribute(.allowsCloudEncryption)
    private(set) var contents: Data!
    
    @Attribute(.allowsCloudEncryption)
    private(set) var deviceID: String!
    
    init(id: UUID, name: String, contents: Data, deviceID: String) {
        self.id = id
        self.name = name
        self.contents = contents
        self.deviceID = deviceID
    }
}
