//
//  Peer.swift
//  SatelliteGuardKit
//
//  Created by Rasmus Krämer on 11.11.24.
//

import Foundation
import Network
import WireGuardKit

public class Peer: Codable {
    public let publicKey: Data
    public let preSharedKey: Data?
    
    public let endpoint: String
    
    private let _routes: [String]
    
    public let persistentKeepAlive: UInt16?
    
    public init(publicKey: Data, preSharedKey: Data?, endpoint: String, routes: [IPAddressRange], persistentKeepAlive: UInt16?) {
        self.publicKey = publicKey
        self.preSharedKey = preSharedKey
        self.endpoint = endpoint
        self._routes = routes.map(\.stringRepresentation)
        self.persistentKeepAlive = persistentKeepAlive
    }
}

extension Peer: Identifiable {
    public var id: String {
        endpoint
    }
    
    public var configuration: PeerConfiguration {
        var peerConfiguration = PeerConfiguration(publicKey: .init(rawValue: publicKey)!)
        
        if let preSharedKey = preSharedKey {
            peerConfiguration.preSharedKey = .init(rawValue: preSharedKey)
        }
        
        peerConfiguration.allowedIPs = routes
        peerConfiguration.endpoint = .init(from: endpoint)
        peerConfiguration.persistentKeepAlive = persistentKeepAlive
        
        return peerConfiguration
    }
}

public extension Peer {
    var routes: [IPAddressRange] {
        _routes.compactMap { IPAddressRange(from: $0) }
    }
}
