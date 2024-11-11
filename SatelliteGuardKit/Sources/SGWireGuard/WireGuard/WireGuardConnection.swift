//
//  WireguardConnection.swift
//  SatelliteGuardKit
//
//  Created by Rasmus Krämer on 11.11.24.
//

import Foundation
import Network
import NetworkExtension
import SGPersistence
import WireGuardKit
import OSLog

public class WireGuardConnection {
    let provider: NEPacketTunnelProvider
    let endpoint: SGPersistence.Endpoint
    
    let adapter: WireGuardAdapter
    
    static let logger = Logger(subsystem: "WireGuard", category: "Tunnel")
    
    public init(provider: NEPacketTunnelProvider, endpoint: SGPersistence.Endpoint) {
        self.provider = provider
        self.endpoint = endpoint
        
        adapter = .init(with: provider, logHandler: Self.log)
    }
}

public extension WireGuardConnection {
    func activate() async throws {
        try await withCheckedThrowingContinuation { continuation in
            adapter.start(tunnelConfiguration: endpoint.configuration) {
                guard let error = $0 else {
                    continuation.resume()
                    return
                }
                
                print(error)
                continuation.resume(throwing: ActivationError.generic)
            }
        }
    }
    func deactivate() async {
        await withCheckedContinuation { continuation in
            adapter.stop() {
                guard let error = $0 else {
                    continuation.resume()
                    return
                }
                
                print(error)
                continuation.resume()
            }
        }
    }
    
    enum ActivationError: Error {
        case generic
    }
}

private extension WireGuardConnection {
    static func log(_ level: WireGuardLogLevel, message: String) {
        switch level {
        case .verbose:
            logger.debug("\(message)")
        case .error:
            logger.fault("\(message)")
        }
    }
}
