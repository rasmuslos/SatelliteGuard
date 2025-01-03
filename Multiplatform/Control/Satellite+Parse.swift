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
    nonisolated func importConfiguration(_ configurationURL: URL) async throws {
        let (data, _) = try await URLSession.shared.data(from: configurationURL)
        
        guard let contents = String(data: data, encoding: .utf8) else {
            throw SatelliteError.invalidConfiguration
        }
        
        return try await importConfiguration(contents, name: configurationURL.lastPathComponent)
    }
    nonisolated func importConfiguration(_ contents: String, name: String) async throws {
        let lines = contents.split(separator: "\n")
        var name = name
        
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
        
        if name.hasSuffix(".conf") {
            name = name.replacingOccurrences(of: ".conf", with: "")
        }
        
        guard interfaceCache.isValid && peerCache.reduce(true, { $0 && $1.isValid }) else {
            throw SatelliteError.invalidConfiguration
        }
        
        let peers = peerCache.map { Peer(publicKey: $0.publicKey,
                                         preSharedKey: $0.preSharedKey,
                                         endpoint: $0.endpoint,
                                         routes: $0.routes,
                                         persistentKeepAlive: $0.persistentKeepAlive) }
        
        let endpoint = SatelliteGuardKit.Endpoint(id: .init(),
                                                  name: name,
                                                  privateKey: interfaceCache.privateKey,
                                                  addresses: interfaceCache.addresses,
                                                  mtu: interfaceCache.mtu,
                                                  listenPort: interfaceCache.listenPort,
                                                  peers: peers,
                                                  dns: interfaceCache.dns,
                                                  
                                                  disconnectsOnSleep: false,
                                                  excludeAPN: true,
                                                  excludeCellularServices: true,
                                                  allowAccessToLocalNetwork: true,
                                                  excludeDeviceCommunication: true,
                                                  enforceRoutes: false,
                                                  includeAllNetworks: false)
        
        do {
            try await PersistenceManager.shared.endpoint.store(endpoint)
        } catch {
            await MainActor.run {
                notifyError.toggle()
            }
        }
    }
}

private protocol ParseCache {
    var isValid: Bool { get }
}
private final class InterfaceCache: ParseCache {
    var addresses: [IPAddressRange]!
    var privateKey: Data!
    
    var dns: [IPAddress]?
    var listenPort: UInt16?
    
    var mtu: UInt16?
    
    var isValid: Bool {
        addresses != nil && privateKey != nil
    }
}
private final class PeerCache: ParseCache {
    var publicKey: Data!
    var preSharedKey: Data?
    
    var endpoint: String!
    
    var routes: [IPAddressRange]!
    
    var persistentKeepAlive: UInt16?
    
    var isValid: Bool {
        publicKey != nil && endpoint != nil && routes != nil
    }
}
