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
    var id: UUID {
        return providerConfiguration!["id"] as! UUID
    }
}
