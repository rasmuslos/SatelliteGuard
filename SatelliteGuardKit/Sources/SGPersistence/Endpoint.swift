//
//  Endpoint.swift
//  SatelliteGuardKit
//
//  Created by Rasmus Krämer on 10.11.24.
//

import Foundation
import SwiftData
import Network
import OSLog
import WireGuardKit

public struct Endpoint {
    public let id: UUID
    public let name: String
    
    public let privateKey: Data
    
    public let mtu: UInt16?
    public let listenPort: UInt16?
    
    public let peers: [Peer]
    
    public let disconnectsOnSleep: Bool
    
    public let excludeAPN: Bool
    public let excludeCellularServices: Bool
    public var allowAccessToLocalNetwork: Bool
    public let excludeDeviceCommunication: Bool
    
    public let enforceRoutes: Bool
    public let includeAllNetworks: Bool
    
    private let _dns: [Data]?
    private let _addresses: [String]
    
    public static let logger = Logger(subsystem: "SatelliteGuardKit", category: "Endpoint")
    
    init(id: UUID,
         name: String,
         privateKey: Data,
         addresses: [IPAddressRange],
         mtu: UInt16?,
         listenPort: UInt16?,
         peers: [Peer],
         dns: [IPAddress]?,
         disconnectsOnSleep: Bool,
         excludeAPN: Bool,
         excludeCellularServices: Bool,
         allowAccessToLocalNetwork: Bool,
         excludeDeviceCommunication: Bool,
         enforceRoutes: Bool,
         includeAllNetworks: Bool) {
        self.id = id
        self.name = name
        
        _addresses = addresses.map(\.stringRepresentation)
        self.privateKey = privateKey
        
        self.mtu = mtu
        self.listenPort = listenPort
        
        self.peers = peers
        _dns = dns?.map(\.rawValue)
        
        self.disconnectsOnSleep = disconnectsOnSleep
        
        self.excludeAPN = excludeAPN
        self.excludeCellularServices = excludeCellularServices
        self.allowAccessToLocalNetwork = allowAccessToLocalNetwork
        self.excludeDeviceCommunication = excludeDeviceCommunication
        
        self.enforceRoutes = enforceRoutes
        self.includeAllNetworks = includeAllNetworks
    }
}

public extension Endpoint {
    var isActive: Bool {
        get async {
            await PersistenceManager.shared.keyHolder[id]
        }
    }
    
    var addresses: [IPAddressRange] {
        _addresses.compactMap { IPAddressRange(from: $0) }
    }
    
    var dns: [IPAddress]? {
        _dns?.compactMap { parse(ipAddress: $0) }
    }
    
    var configuration: TunnelConfiguration {
        .init(name: name, interface: interfaceConfiguration, peers: peers.map(\.configuration))
    }
    var interfaceConfiguration: InterfaceConfiguration {
        var interfaceConfiguration = InterfaceConfiguration(privateKey: .init(rawValue: privateKey)!)
        
        if let dns {
            interfaceConfiguration.dns = dns.map { DNSServer(address: $0) }
        }
        
        interfaceConfiguration.mtu = mtu
        interfaceConfiguration.addresses = addresses
        interfaceConfiguration.listenPort = listenPort
        
        return interfaceConfiguration
    }
    
    enum EndpointError: Error {
        case managerMissing
    }
}

extension Endpoint: Codable {}
extension Endpoint: Hashable {}
extension Endpoint: Equatable {}
extension Endpoint: Identifiable {}

#if DEBUG
public extension Endpoint {
    nonisolated(unsafe) static let fixture = Endpoint(id: UUID(),
                                                      name: "Fixture",
                                                      privateKey: Data(count: 32),
                                                      addresses: [IPAddressRange(from: "192.168.178.1/24")!],
                                                      mtu: 123,
                                                      listenPort: 456,
                                                      peers: [Peer(publicKey: Data(count: 32),
                                                                   preSharedKey: Data(count: 32),
                                                                   endpoint: "cia.gocardless.com",
                                                                   routes: [IPAddressRange(from: "0.0.0.0/0")!],
                                                                   persistentKeepAlive: 789)],
                                                      dns: [IPv4Address("1.2.3.4")!],
                                                      disconnectsOnSleep: true,
                                                      excludeAPN: true,
                                                      excludeCellularServices: true,
                                                      allowAccessToLocalNetwork: true,
                                                      excludeDeviceCommunication: true,
                                                      enforceRoutes: true,
                                                      includeAllNetworks: false)
}
#endif
