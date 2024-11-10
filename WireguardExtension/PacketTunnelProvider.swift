//
//  PacketTunnelProvider.swift
//  WireguardExtension
//
//  Created by Rasmus Krämer on 10.11.24.
//

import NetworkExtension

class PacketTunnelProvider: NEPacketTunnelProvider {
    override func startTunnel(options: [String : NSObject]?) async throws {
    }
    
    override func stopTunnel(with reason: NEProviderStopReason) async {
    }
    
    override func handleAppMessage(_ messageData: Data) async -> Data? {
        nil
    }
    
    override func sleep() async {
    }
    
    override func wake() {
    }
}
