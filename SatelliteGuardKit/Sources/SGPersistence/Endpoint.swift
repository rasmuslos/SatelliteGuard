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

@Model
public class Endpoint: Codable {
    // Technically unique, but not marked or enforced as such due to CloudKit restrictions
    private(set) public var id = UUID()
    
    @Attribute(.allowsCloudEncryption) private(set) public var name: String!
    @Attribute(.allowsCloudEncryption) public var active: Bool!
    
    @Attribute(.allowsCloudEncryption) private(set) public var peers: [Peer]!
    @Attribute(.allowsCloudEncryption) private(set) var _addresses: [String]!
    
    @Attribute(.allowsCloudEncryption) private(set) public var privateKey: Data!
    
    @Attribute(.allowsCloudEncryption) private(set) var _dns: [Data]?
    @Attribute(.allowsCloudEncryption) private(set) public var listenPort: UInt16?
    
    @Attribute(.allowsCloudEncryption) private(set) public var mtu: UInt16?
    @Attribute(.allowsCloudEncryption) public var disconnectsOnSleep = true
    
    @Attribute(.allowsCloudEncryption) public var excludeAPN = false
    @Attribute(.allowsCloudEncryption) public var enforceRoutes = false
    @Attribute(.allowsCloudEncryption) public var includeAllNetworks = false
    @Attribute(.allowsCloudEncryption) public var excludeCellularServices = false
    @Attribute(.allowsCloudEncryption) public var allowAccessToLocalNetwork = false
    @Attribute(.allowsCloudEncryption) public var excludeDeviceCommunication = false
    
    public static let logger = Logger(subsystem: "SatelliteGuardKit", category: "Endpoint")
    
    public init(name: String, peers: [Peer], addresses: [IPAddressRange], privateKey: Data, dns: [IPAddress]? = nil, listenPort: UInt16? = nil, mtu: UInt16? = nil) {
        self.name = name
        active = false
        
        self.peers = peers
        _addresses = addresses.map(\.stringRepresentation)
        
        self.privateKey = privateKey
        
        _dns = dns?.map(\.rawValue)
        self.listenPort = listenPort
        
        self.mtu = mtu
    }
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: ._id)
        
        name = try container.decode(String.self, forKey: ._name)
        active = try container.decode(Bool.self, forKey: ._active)
        
        peers = try container.decode([Peer].self, forKey: ._peers)
        _addresses = try container.decode([String].self, forKey: .__addresses)
        
        privateKey = try container.decode(Data.self, forKey: ._privateKey)
        
        _dns = try container.decode([Data]?.self, forKey: .__dns)
        listenPort = try container.decodeIfPresent(UInt16.self, forKey: ._listenPort)
        
        mtu = try container.decodeIfPresent(UInt16.self, forKey: ._mtu)
    }
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: ._id)
        
        try container.encode(name, forKey: ._name)
        try container.encode(active, forKey: ._active)
        
        try container.encode(peers, forKey: ._peers)
        try container.encode(_addresses, forKey: .__addresses)
        
        try container.encode(privateKey, forKey: ._privateKey)
        
        try container.encode(_dns, forKey: .__dns)
        try container.encodeIfPresent(listenPort, forKey: ._listenPort)
        
        try container.encodeIfPresent(mtu, forKey: ._mtu)
    }
    
    enum CodingKeys: CodingKey {
        case _id
        case _name
        case _active
        case _peers
        case __addresses
        case _privateKey
        case __dns
        case _listenPort
        case _mtu
    }
}

public extension Endpoint {
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
    
    @MainActor
    func remove() throws {
        PersistenceManager.shared.modelContainer.mainContext.delete(self)
    }
}

extension Endpoint: Hashable {}
extension Endpoint: Equatable {}
extension Endpoint: Identifiable {}

public extension Endpoint {
    static func identified(by id: UUID) -> Endpoint? {
        let context = ModelContext(PersistenceManager.shared.modelContainer)
        let descriptor = FetchDescriptor<Endpoint>(predicate: #Predicate { $0.id == id })
        
        return try? context.fetch(descriptor).first
    }
}

#if DEBUG
public extension Endpoint {
    nonisolated(unsafe) static let fixture = Endpoint(name: "Vault 7",
                                                      peers: [.init(publicKey: .init(count: 32),
                                                                    preSharedKey: .init(count: 32),
                                                                    endpoint: "gia.gov:12345",
                                                                    routes: [.init(from: "0.0.0.0/0")!],
                                                                    persistentKeepAlive: 40)],
                                                      addresses: [.init(from: "192.0.0.1/24")!],
                                                      privateKey: .init(count: 32),
                                                      dns: [IPv4Address("1.1.1.1")!],
                                                      listenPort: .max,
                                                      mtu: 1024)
}
#endif
