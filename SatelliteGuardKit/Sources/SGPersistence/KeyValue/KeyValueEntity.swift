//
//  KeyValueEntity.swift
//  SatelliteGuardKit
//
//  Created by Rasmus Krämer on 30.11.24.
//

import Foundation
import SwiftData

@Model
final class KeyValueEntity {
    #Index<KeyValueEntity>([\.key])
    
    @Attribute(.allowsCloudEncryption)
    private(set) var key: String!
    
    @Attribute(.allowsCloudEncryption)
    var value: Data!
    
    init(key: String, value: Data) {
        self.key = key
        self.value = value
    }
}
