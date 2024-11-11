//
//  Satellite+Parse.swift
//  SatelliteGuard
//
//  Created by Rasmus Krämer on 11.11.24.
//

// This is here so that the WireGuard namespace does not collide ("Endpoint")

import Foundation
import Network
import WireGuardKit
import SatelliteGuardKit

internal extension Satellite {
    /// Parses a WireGuard config file and stores the contents inside the database
    func importConfiguration(_ configurationURL: URL) async throws {
        let (data, _) = try await URLSession.shared.data(from: configurationURL)
        
        guard let contents = String(data: data, encoding: .utf8) else {
            throw SatelliteError.invalidConfiguration
        }
        
        let lines = contents.split(separator: "\n")
        
        var peerCache = [PeerCache]()
        let interfaceCache = InterfaceCache()
        
        for line in lines {
            switch line {
            case "[Peer]":
                peerCache.append(.init())
            default:
                let stripped = line.components(separatedBy: .whitespacesAndNewlines).joined()
                let parts = stripped.split(separator: "=", maxSplits: 1)
                
                guard parts.count == 2 else {
                    continue
                }
                
                let key = parts[0]
                let value = String(parts[1])
                
                switch key {
                    // MARK: [Interface]
                case "Address":
                    interfaceCache.addresses = value.split(separator: ",").compactMap { IPAddressRange(from: String($0)) }
                    
                case "PrivateKey":
                    interfaceCache.privateKey = BaseKey(base64Key: value)?.rawValue
                    
                case "DNS":
                    interfaceCache.dns = value.split(separator: ",").compactMap { parse(ipAddress: String($0)) }
                case "ListenPort":
                    interfaceCache.listenPort = UInt16(value)
                    
                case "MTU":
                    interfaceCache.mtu = UInt16(value)
                    
                    // MARK: [Peer]
                case "Endpoint":
                    peerCache.last?.endpoint = value
                case "AllowedIPs":
                    peerCache.last?.routes = value.split(separator: ",").compactMap { IPAddressRange(from: String($0)) }
                    
                case "PublicKey":
                    peerCache.last?.publicKey = BaseKey(base64Key: value)?.rawValue
                case "PresharedKey":
                    peerCache.last?.preSharedKey = BaseKey(base64Key: value)?.rawValue
                    
                case "PersistentKeepAlive":
                    peerCache.last?.persistentKeepAlive = UInt16(value)
                    
                default:
                    continue
                }
            }
        }
        
        var name = configurationURL.lastPathComponent
        
        if name.hasSuffix(".conf") {
            name = name.replacingOccurrences(of: ".conf", with: "")
        }
        
        guard interfaceCache.isValid && peerCache.reduce(true, { $0 && $1.isValid }) else {
            throw SatelliteError.invalidConfiguration
        }
        
        try await MainActor.run { [name, peerCache] in
            let context = PersistenceManager.shared.modelContainer.mainContext
            
            let peers = peerCache.map { Peer(publicKey: $0.publicKey,
                                             preSharedKey: $0.preSharedKey,
                                             endpoint: $0.endpoint,
                                             routes: $0.routes,
                                             persistentKeepAlive: $0.persistentKeepAlive) }
            
            let endpoint = Endpoint(name: name,
                                    peers: peers,
                                    addresses: interfaceCache.addresses,
                                    privateKey: interfaceCache.privateKey,
                                    dns: interfaceCache.dns,
                                    listenPort: interfaceCache.listenPort,
                                    mtu: interfaceCache.mtu)
            
            context.insert(endpoint)
            try context.save()
        }
    }
}

private protocol ParseCache {
    var isValid: Bool { get }
}
private class InterfaceCache: ParseCache {
    var addresses: [IPAddressRange]!
    var privateKey: Data!
    
    var dns: [IPAddress]?
    var listenPort: UInt16?
    
    var mtu: UInt16?
    
    var isValid: Bool {
        addresses != nil && privateKey != nil
    }
}
private class PeerCache: ParseCache {
    var publicKey: Data!
    var preSharedKey: Data?
    
    var endpoint: String!
    
    var routes: [IPAddressRange]!
    
    var persistentKeepAlive: UInt16?
    
    var isValid: Bool {
        publicKey != nil && endpoint != nil && routes != nil
    }
}
