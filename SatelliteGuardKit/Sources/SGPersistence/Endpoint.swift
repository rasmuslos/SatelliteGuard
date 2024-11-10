//
//  Endpoint.swift
//  SatelliteGuardKit
//
//  Created by Rasmus Krämer on 10.11.24.
//

import Foundation
import SwiftData
import Network
import WireGuardKit

@Model
public class Endpoint: Codable {
    // Technically unique, but not marked or enforced as such due to CloudKit restrictions
    private(set) public var id = UUID()
    
    @Attribute(.allowsCloudEncryption) private(set) public var name: String
    @Attribute(.allowsCloudEncryption) private(set) public var active: Bool
    
    @Attribute(.allowsCloudEncryption) private(set) public var url: URL
    
    @Attribute(.allowsCloudEncryption) private(set) var _routes: [String]
    @Attribute(.allowsCloudEncryption) private(set) var _addresses: [String]
    
    @Attribute(.allowsCloudEncryption) private(set) public var publicKey: Data
    @Attribute(.allowsCloudEncryption) private(set) public var privateKey: Data
    @Attribute(.allowsCloudEncryption) private(set) public var preSharedKey: Data?
    
    @Attribute(.allowsCloudEncryption) private(set) var _dns: [Data]?
    @Attribute(.allowsCloudEncryption) private(set) public var listenPort: UInt16?
    
    @Attribute(.allowsCloudEncryption) private(set) public var mtu: UInt16?
    @Attribute(.allowsCloudEncryption) private(set) public var persistentKeepAlive: UInt16?
    
    public init(name: String, url: URL, routes: [IPAddressRange], addresses: [IPAddressRange], publicKey: Data, privateKey: Data, preSharedKey: Data? = nil, dns: [IPAddress]? = nil, listenPort: UInt16? = nil, mtu: UInt16? = nil, persistentKeepAlive: UInt16? = nil) {
        self.name = name
        active = false
        
        self.url = url
        _routes = routes.map(\.stringRepresentation)
        _addresses = addresses.map(\.stringRepresentation)
        self.publicKey = publicKey
        self.privateKey = privateKey
        self.preSharedKey = preSharedKey
        _dns = dns?.map(\.rawValue)
        self.listenPort = listenPort
        self.mtu = mtu
        self.persistentKeepAlive = persistentKeepAlive
    }
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: ._id)
        
        name = try container.decode(String.self, forKey: ._name)
        active = try container.decode(Bool.self, forKey: ._active)
        
        url = try container.decode(URL.self, forKey: ._url)
        
        _routes = try container.decode([String].self, forKey: .__routes)
        _addresses = try container.decode([String].self, forKey: .__addresses)
        
        publicKey = try container.decode(Data.self, forKey: ._publicKey)
        privateKey = try container.decode(Data.self, forKey: ._privateKey)
        preSharedKey = try container.decode(Data?.self, forKey: ._preSharedKey)
        
        _dns = try container.decode([Data]?.self, forKey: .__dns)
        listenPort = try container.decodeIfPresent(UInt16.self, forKey: ._listenPort)
        
        mtu = try container.decodeIfPresent(UInt16.self, forKey: ._mtu)
        persistentKeepAlive = try container.decodeIfPresent(UInt16.self, forKey: ._persistentKeepAlive)
    }
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: ._id)
        
        try container.encode(name, forKey: ._name)
        try container.encode(active, forKey: ._active)
        
        try container.encode(url.absoluteString, forKey: ._url)
        
        try container.encode(_routes, forKey: .__routes)
        try container.encode(_addresses, forKey: .__addresses)
        
        try container.encode(publicKey, forKey: ._publicKey)
        try container.encode(privateKey, forKey: ._privateKey)
        try container.encode(preSharedKey, forKey: ._preSharedKey)
        
        try container.encode(_dns, forKey: .__dns)
        try container.encodeIfPresent(listenPort, forKey: ._listenPort)
        
        try container.encodeIfPresent(mtu, forKey: ._mtu)
        try container.encodeIfPresent(persistentKeepAlive, forKey: ._persistentKeepAlive)
    }
    
    enum CodingKeys: CodingKey {
        case _id
        case _name
        case _active
        case _url
        case __routes
        case __addresses
        case _publicKey
        case _privateKey
        case _preSharedKey
        case __dns
        case _listenPort
        case _mtu
        case _persistentKeepAlive
        case _$backingData
        case _$observationRegistrar
    }
}

public extension Endpoint {
    var routes: [IPAddressRange] {
        _routes.compactMap { IPAddressRange(from: $0) }
    }
    var addresses: [IPAddressRange] {
        _addresses.compactMap { IPAddressRange(from: $0) }
    }
    
    var dns: [IPAddress]? {
        _dns?.compactMap { parse(ipAddress: $0) }
    }
    
    var friendlyURL: String {
        let host = url.host() ?? "?"
        let port = url.port?.description ?? "?"
        
        return "\(host):\(port)"
    }
}

extension Endpoint: Hashable {}
extension Endpoint: Equatable {}
extension Endpoint: Identifiable {}

#if DEBUG
public extension Endpoint {
    nonisolated(unsafe) static let fixture = Endpoint(name: "Vault 7",
                                                      url: .init(string: "wg://cia.gov:12345")!,
                                                      routes: [.init(from: "0.0.0.0/0")!],
                                                      addresses: [.init(from: "192.0.0.1/24")!],
                                                      publicKey: .init(count: 32),
                                                      privateKey: .init(count: 32),
                                                      preSharedKey: .init(count: 32),
                                                      dns: [IPv4Address("1.1.1.1")!],
                                                      listenPort: .max,
                                                      mtu: 1024,
                                                      persistentKeepAlive: 30)
}
#endif
