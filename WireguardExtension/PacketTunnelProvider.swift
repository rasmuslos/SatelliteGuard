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
    private lazy var connection: WireGuardConnection! = {
        guard let protocolConfiguration = protocolConfiguration as? NETunnelProviderProtocol,
              let id = protocolConfiguration.id,
              let endpoint = Endpoint.identified(by: id) else {
            return nil
        }
        
        return .init(provider: self, endpoint: endpoint)
    }()
    
    override func startTunnel(options: [String : NSObject]?) async throws {
        try await connection.activate()
    }
    
    override func stopTunnel(with reason: NEProviderStopReason) async {
        await connection.deactivate()
    }
    
    override func handleAppMessage(_ messageData: Data) async -> Data? {
        return messageData
    }
    
    override func sleep() async {
    }
    
    override func wake() {
    }
}
