//
//  NETunnelProviderManager+Configuration.swift
//  SatelliteGuardKit
//
//  Created by Rasmus Krämer on 10.11.24.
//

import Foundation
import Network
import NetworkExtension

public extension NETunnelProviderManager {
    func identified(by: UUID) -> Bool {
        guard let protocolConfiguration = protocolConfiguration as? NETunnelProviderProtocol,
              protocolConfiguration.providerBundleIdentifier == Bundle.main.bundleIdentifier else {
            return false
        }
        
        return protocolConfiguration.id == by
    }
}
