//
//  Satellite.swift
//  SatelliteGuard
//
//  Created by Rasmus Krämer on 10.11.24.
//

import Foundation
import Network
import SwiftUI
import WireGuardKit
import SatelliteGuardKit

@Observable
internal class Satellite {
    @MainActor private(set) var importing: Bool
    
    @MainActor
    init() {
        importing = false
    }
    
    func handleFileSelection(_ result: Result<[URL], any Error>) {
        Task {
            await MainActor.withAnimation {
                self.importing = true
            }
            
            for url in try result.get() {
                do {
                    guard url.startAccessingSecurityScopedResource() else {
                        throw SatelliteError.permissionDenied
                    }
                    
                    print(url.lastPathComponent)
                    
                    try await importConfiguration(url)
                    url.stopAccessingSecurityScopedResource()
                } catch {
                    print(error)
                }
            }
            
            await MainActor.withAnimation {
                self.importing = false
            }
        }
    }
}

private extension Satellite {
    func importConfiguration(_ configurationURL: URL) async throws {
        let (data, _) = try await URLSession.shared.data(from: configurationURL)
        
        guard let contents = String(data: data, encoding: .utf8) else {
            throw SatelliteError.invalidConfiguration
        }
        
        let lines = contents.split(separator: "\n")
        
        var url: URL? = nil
        
        var routes: [IPAddressRange]? = nil
        var addresses: [IPAddressRange]? = nil
        
        var publicKey: Data? = nil
        var privateKey: Data? = nil
        var preSharedKey: Data? = nil
        
        var dns: [IPAddress]? = nil
        var listenPort: UInt16? = nil
        
        var mtu: UInt16? = nil
        var persistentKeepAlive: UInt16? = nil
        
        for line in lines {
            let stripped = line.components(separatedBy: .whitespacesAndNewlines).joined()
            let parts = stripped.split(separator: "=", maxSplits: 1)
            
            guard parts.count == 2 else {
                continue
            }
            
            let key = parts[0]
            let value = String(parts[1])
            
            switch key {
            case "Endpoint":
                url = .init(string: "wg://\(value)")
                
            case "AllowedIPs":
                routes = value.split(separator: ",").compactMap { IPAddressRange(from: String($0)) }
            case "Address":
                addresses = value.split(separator: ",").compactMap { IPAddressRange(from: String($0)) }
                
            case "PublicKey":
                publicKey = BaseKey(base64Key: value)?.rawValue
            case "PresharedKey":
                preSharedKey = BaseKey(base64Key: value)?.rawValue
            case "PrivateKey":
                privateKey = BaseKey(base64Key: value)?.rawValue
                
            case "DNS":
                dns = value.split(separator: ",").compactMap { parse(ipAddress: String($0)) }
            case "ListenPort":
                listenPort = UInt16(value)
                
            case "MTU":
                mtu = UInt16(value)
            case "PersistentKeepAlive":
                persistentKeepAlive = UInt16(value)
                
            default:
                continue
            }
        }
        
        guard let url, let routes, let addresses, let publicKey, let privateKey else {
            throw SatelliteError.invalidConfiguration
        }
        
        var name = configurationURL.lastPathComponent
        
        if name.hasSuffix(".conf") {
            name = name.replacingOccurrences(of: ".conf", with: "")
        }
        
        try await MainActor.run { [name, preSharedKey, dns, listenPort, mtu, persistentKeepAlive] in
            let context = PersistenceManager.shared.modelContainer.mainContext
            let endpoint = Endpoint(name: name,
                                    url: url,
                                    routes: routes,
                                    addresses: addresses,
                                    publicKey: publicKey,
                                    privateKey: privateKey,
                                    preSharedKey: preSharedKey,
                                    dns: dns,
                                    listenPort: listenPort,
                                    mtu: mtu,
                                    persistentKeepAlive: persistentKeepAlive)
            
            context.insert(endpoint)
            try context.save()
        }
    }
    
    enum SatelliteError: Error {
        case permissionDenied
        case invalidConfiguration
    }
}

#if DEBUG
extension Satellite {
    @MainActor
    static var fixture: Satellite {
        .init()
    }
}

extension View {
    @ViewBuilder
    func satellite() -> some View {
        environment(Satellite.fixture)
    }
}
#endif
