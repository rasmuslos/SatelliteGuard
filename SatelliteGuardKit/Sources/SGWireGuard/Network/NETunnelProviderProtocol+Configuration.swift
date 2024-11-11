//
//  NETunnelProviderProtocol+ProtocolConfiguration.swift
//  SatelliteGuardKit
//
//  Created by Rasmus Krämer on 10.11.24.
//

import Foundation
import Network
import NetworkExtension

public extension NETunnelProviderProtocol {
    var id: UUID? {
        guard let uuid = providerConfiguration?["id"] as? String else {
            return nil
        }
        
        return .init(uuidString: uuid)
    }
}
