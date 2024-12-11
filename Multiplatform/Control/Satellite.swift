//
//  Satellite.swift
//  SatelliteGuard
//
//  Created by Rasmus Krämer on 10.11.24.
//

import Foundation
import Network
import NetworkExtension
import SwiftUI
import OSLog
import SatelliteGuardKit

#if os(macOS)
import ServiceManagement
#endif

@Observable
final class Satellite {
    @MainActor private(set) var status: [UUID: VPNStatus]
    
    @MainActor var editingEndpoint: Endpoint?
    @MainActor var importPickerVisible: Bool
    
    @MainActor private(set) var activeEndpointIDs: [UUID]
    
    @MainActor private(set) var importing: Bool
    @MainActor private(set) var transmitting: Int
    
    @MainActor private(set) var authorized: Bool
    @MainActor private(set) var didJoinVault: Bool
    
    @MainActor private(set) var notifyError: Bool
    @MainActor private(set) var notifySuccess: Bool
    
    @ObservationIgnored private var tokens: [Any]!
    
    private static let logger = Logger(subsystem: "Satellite", category: "SatelliteGuard")
    
    @MainActor
    init() {
        status = [:]
        
        editingEndpoint = nil
        importPickerVisible = false
        
        importing = false
        transmitting = 0
        
        authorized = false
        didJoinVault = PersistenceManager.shared.keyHolder.authorized
        
        activeEndpointIDs = []
        
        notifyError = false
        notifySuccess = false
        
        tokens = setupObservers()
    }
    
    enum VPNStatus: Equatable, Hashable {
        case disconnecting
        case disconnected
        case establishing
        case connected(since: Date)
        
        var priority: Int {
            switch self {
            case .disconnecting:
                1
            case .disconnected:
                0
            case .establishing:
                2
            case .connected:
                3
            }
        }
    }
    
    enum SatelliteError: Error {
        case permissionDenied
        case invalidConfiguration
    }
}

extension Satellite {
    @MainActor
    var pondering: Bool {
        importing || transmitting > 0 || !status.filter { $1 == .establishing || $1 == .disconnecting }.isEmpty
    }
    
    @MainActor
    var dominantStatus: VPNStatus {
        Dictionary(status.map { ($1, [$0]) }, uniquingKeysWith: +).keys.reduce(.disconnected) { $0.priority < $1.priority ? $1 : $0 }
    }
    
    @MainActor
    var connectedIDs: [UUID] {
        status.filter { (_, status) in
            if case .connected = status {
                true
            } else {
                false
            }
        }.map(\.key)
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
                    
                    try await importConfiguration(url)
                    url.stopAccessingSecurityScopedResource()
                    
                    await MainActor.run {
                        self.notifySuccess.toggle()
                    }
                } catch {
                    await MainActor.run {
                        self.notifyError.toggle()
                    }
                }
            }
            
            await MainActor.withAnimation {
                self.importing = false
            }
        }
    }
    func handleFileImport(_ contents: String, name: String) {
        Task {
            guard !(await self.importing) else {
                return
            }
            
            await MainActor.withAnimation {
                self.importing = true
            }
            
            do {
                try await importConfiguration(contents, name: name)
                
                await MainActor.run {
                    self.notifySuccess.toggle()
                }
            } catch {
                await MainActor.run {
                    self.notifyError.toggle()
                }
            }
            
            await MainActor.withAnimation {
                self.importing = false
            }
        }
    }
    
    #if os(macOS)
    func updateServiceRegistration(_ register: Bool) {
        Task {
            await MainActor.withAnimation {
                self.transmitting += 1
            }
            
            do {
                if register {
                    try SMAppService.mainApp.register()
                } else {
                    try await SMAppService.mainApp.unregister()
                }
            } catch {
                await MainActor.run {
                    self.notifyError.toggle()
                }
            }
            
            await MainActor.withAnimation {
                self.transmitting -= 1
            }
        }
    }
    #endif
}

extension Satellite {
    func launch(_ endpoint: Endpoint) {
        Task {
            await MainActor.withAnimation {
                self.transmitting += 1
            }
            
            do {
                for connectedID in await self.connectedIDs {
                    if let current = await PersistenceManager.shared.endpoint[connectedID] {
                        await current.disconnect()
                    }
                }
                
                try await endpoint.connect()
                
                await MainActor.withAnimation {
                    self.status[endpoint.id] = .establishing
                    self.notifySuccess.toggle()
                }
            } catch {
                await MainActor.withAnimation {
                    self.transmitting -= 1
                    self.notifyError.toggle()
                }
            }
            
            await MainActor.withAnimation {
                self.transmitting -= 1
            }
        }
    }
    func land(_ endpoint: Endpoint?) {
        Task {
            await MainActor.withAnimation {
                self.transmitting += 1
            }
            
            if let endpoint {
                await endpoint.disconnect()
                await MainActor.withAnimation {
                    self.status[endpoint.id] = .disconnecting
                }
            } else {
                for connectedID in await self.connectedIDs {
                    if let current = await PersistenceManager.shared.endpoint[connectedID] {
                        await current.disconnect()
                        await MainActor.withAnimation {
                            self.status[current.id] = .disconnecting
                        }
                    }
                }
            }
            
            await MainActor.withAnimation {
                self.transmitting -= 1
                self.notifySuccess.toggle()
            }
        }
    }
    
    func activate(_ endpoint: Endpoint) {
        Task {
            await MainActor.withAnimation {
                self.transmitting += 1
            }
            
            do {
                try await endpoint.reassert()
                
                await MainActor.withAnimation {
                    self.notifySuccess.toggle()
                }
            } catch {
                await MainActor.withAnimation {
                    self.transmitting -= 1
                    self.notifyError.toggle()
                }
            }
            
            await MainActor.withAnimation {
                self.transmitting -= 1
                self.notifySuccess.toggle()
            }
        }
    }
    func deactivate(_ endpoint: Endpoint) {
        Task {
            await MainActor.withAnimation {
                self.transmitting += 1
            }
            
            do {
                try await endpoint.deactivate()
                
                await MainActor.withAnimation {
                    self.notifySuccess.toggle()
                }
            } catch {
                await MainActor.withAnimation {
                    self.transmitting -= 1
                    self.notifyError.toggle()
                }
            }
            
            await MainActor.withAnimation {
                self.transmitting -= 1
                self.notifySuccess.toggle()
            }
        }
    }
}

private extension Satellite {
    func setupObservers() -> [Any] {
        var tokens = [WireGuardMonitor.shared.statusPublisher.sink { [weak self] (id, status, connectedSince) in
            self?.parseStatus(status, for: id, connectedSince: connectedSince)
        }, PersistenceManager.shared.keyHolder.activationDidChange.sink { [weak self] _ in
            Task {
                let activeIDs = await PersistenceManager.shared.keyHolder.activeIDs
                
                await MainActor.withAnimation {
                    self?.activeEndpointIDs = activeIDs
                }
            }
        }, PersistenceManager.shared.keyHolder.authorizationDidChange.sink { [weak self] authorized in
            Task {
                let didJoinVault = await PersistenceManager.shared.keyHolder.didJoinVault
                
                await MainActor.withAnimation {
                    self?.authorized = PersistenceManager.shared.keyHolder.authorized
                    self?.didJoinVault = didJoinVault
                }
            }
        }]
        #if !os(macOS)
        tokens += [NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification).sink { [weak self] _ in
            Task {
                for endpoint in await PersistenceManager.shared.endpoint.all {
                    await self?.parseStatus(endpoint.status, for: endpoint.id, connectedSince: .now)
                }
            }
        }]
        #endif
        
        return tokens
    }
    
    func parseStatus(_ status: NEVPNStatus, for endpointID: UUID, connectedSince: Date?) {
        let parsed: VPNStatus
        
        switch status {
        case .connected:
            parsed = .connected(since: connectedSince ?? .now)
        case .connecting, .reasserting:
            parsed = .establishing
        case .disconnecting:
            parsed = .disconnecting
        default:
            parsed = .disconnected
        }
        
        Task { @MainActor in
            if self.editingEndpoint?.id == endpointID && parsed != .disconnected {
                self.editingEndpoint = nil
            }
            
            if self.status[endpointID]?.priority != parsed.priority {
                self.status[endpointID] = parsed
            }
        }
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
    func previewEnvironment() -> some View {
        environment(Satellite.fixture)
    }
}
#endif
