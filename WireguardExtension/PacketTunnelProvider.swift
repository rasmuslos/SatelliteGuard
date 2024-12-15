//
//  PacketTunnelProvider.swift
//  WireguardExtension
//
//  Created by Rasmus Krämer on 10.11.24.
//

import Foundation
import Network
import NetworkExtension
import SatelliteGuardKit

class PacketTunnelProvider: NEPacketTunnelProvider {
    private var connection: WireGuardConnection!
    
    override func startTunnel(options: [String : NSObject]?) async throws {
        guard let protocolConfiguration = protocolConfiguration as? NETunnelProviderProtocol, let id = protocolConfiguration.id, let endpoint = await PersistenceManager.shared.endpoint[id] else {
                  throw TunnelError.invalidEndpoint
        }
        
        connection = .init(provider: self, endpoint: endpoint)
        
        self.protocolConfiguration.passwordReference
        
        try await connection.activate()
    }
    
    override func stopTunnel(with reason: NEProviderStopReason) async {
        await connection.deactivate()
        
        #if os(macOS)
        exit(0)
        #endif
    }
    
    override func handleAppMessage(_ messageData: Data) async -> Data? {
        return messageData
    }
    
    override func sleep() async {
    }
    
    override func wake() {
    }
    
    enum TunnelError: Error {
        case invalidEndpoint
    }
}
