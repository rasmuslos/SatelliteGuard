//
//  Endpoint+Connection.swift
//  SatelliteGuardKit
//
//  Created by Rasmus Krämer on 11.11.24.
//

import Foundation
import Network
import NetworkExtension
import SGPersistence

internal extension Endpoint {
    var connection: NETunnelProviderSession? {
        get async {
            await manager?.connection as? NETunnelProviderSession
        }
    }
}

public extension Endpoint {
    var status: NEVPNStatus {
        get async {
            await connection?.status ?? .invalid
        }
    }
    
    func connect() async throws {
        try await connection?.startVPNTunnel(options: [:])
    }
    func disconnect() async {
        await connection?.stopVPNTunnel()
    }
}
