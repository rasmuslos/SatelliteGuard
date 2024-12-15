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
import Combine
import RFNotifications
import SatelliteGuardKit

#if os(macOS)
import ServiceManagement
#endif

@Observable @MainActor
final class Satellite: Sendable {
    private(set) var endpoints: [Endpoint]
    private(set) var activeEndpointIDs: Set<UUID>
    private(set) var endpointStatus: [UUID: VPNStatus]
    
    private(set) var unauthorizedKeyHolderIDs: [PersistenceManager.KeyHolderSubsystem.UnauthorizedKeyHolder]
    
    var editingEndpoint: Endpoint?
    var importPickerVisible: Bool
    
    private(set) var importing: Bool
    private(set) var transmitting: Int
    
    private(set) var authorizationStatus: PersistenceManager.KeyHolderSubsystem.AuthorizationStatus
    
    var notifyError: Bool
    var notifySuccess: Bool
    
    @ObservationIgnored private var stash = RFNotification.MarkerStash()
    @ObservationIgnored private nonisolated let logger = Logger(subsystem: "io.rfk.SatelliteGuard", category: "Satellite")
    
    init() {
        endpoints = []
        activeEndpointIDs = []
        endpointStatus = [:]
        
        unauthorizedKeyHolderIDs = []
        
        editingEndpoint = nil
        importPickerVisible = false
        
        importing = false
        transmitting = 0
        
        authorizationStatus = .establishing
        
        notifyError = false
        notifySuccess = false
        
        createObservers()
        
        // CloudKit takes some time to synchronise
        Task.detached(priority: .high) {
            try await Task.sleep(for: .seconds(1))
            await PersistenceManager.shared.update()
        }
    }
    
    enum VPNStatus: Sendable, Equatable, Hashable {
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
    
    enum SatelliteError: Sendable, Error {
        case permissionDenied
        case invalidConfiguration
    }
}

extension Satellite {
    var pondering: Bool {
        importing || transmitting > 0 || !endpointStatus.filter { $1 == .establishing || $1 == .disconnecting }.isEmpty
    }
    
    var dominantStatus: VPNStatus {
        Dictionary(endpointStatus.map { ($1, [$0]) }, uniquingKeysWith: +).keys.reduce(.disconnected) { $0.priority < $1.priority ? $1 : $0 }
    }
    
    var connectedIDs: [UUID] {
        endpointStatus.filter { (_, status) in
            if case .connected = status {
                true
            } else {
                false
            }
        }.map(\.key)
    }
    
    nonisolated func handleFileSelection(_ result: Result<[URL], any Error>) {
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
                    
                    logger.info("Successfully imported configuration")
                    
                    await MainActor.run {
                        self.notifySuccess.toggle()
                    }
                } catch {
                    logger.error("Failed to import configuration: \(error)")
                    
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
    nonisolated func handleFileImport(_ contents: String, name: String) {
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
    nonisolated func updateServiceRegistration(_ register: Bool) {
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
                
                logger.info("Service \(register ? "registered" : "unregistered")")
            } catch {
                logger.error("Failed to update service registration: \(error)")
                
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
    nonisolated func launch(_ endpoint: Endpoint) {
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
                logger.info("Connected to \(endpoint.id)")
                
                await MainActor.withAnimation {
                    self.endpointStatus[endpoint.id] = .establishing
                    self.notifySuccess.toggle()
                }
            } catch {
                logger.error("Failed to connect to \(endpoint.id): \(error)")
                
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
    nonisolated func land(_ endpoint: Endpoint?) {
        Task {
            await MainActor.withAnimation {
                self.transmitting += 1
            }
            
            if let endpoint {
                await endpoint.disconnect()
                await MainActor.withAnimation {
                    self.endpointStatus[endpoint.id] = .disconnecting
                }
            } else {
                for connectedID in await self.connectedIDs {
                    if let current = await PersistenceManager.shared.endpoint[connectedID] {
                        await current.disconnect()
                        await MainActor.withAnimation {
                            self.endpointStatus[current.id] = .disconnecting
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
    
    nonisolated func activate(_ endpoint: Endpoint) {
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
                logger.error("Failed to active to \(endpoint.id): \(error)")
                
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
    nonisolated func deactivate(_ endpoint: Endpoint) {
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
                logger.error("Failed to deactivate to \(endpoint.id): \(error)")
                
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
    func createObservers() {
        /*
        cancellables += [WireGuardMonitor.shared.statusPublisher.sink { [weak self] (id, status, connectedSince) in
            self?.parseStatus(status, for: id, connectedSince: connectedSince)
        }]
         */
        
        RFNotification[.authorizationChanged].subscribe { [weak self] in
            guard let self else {
                return
            }
            
            let current = self.authorizationStatus
            
            self.logger.info("Updating authorization status to \($0.debugDescription) (current: \(current.debugDescription))")
            
            guard current != .establishingFailed else {
                return
            }
            
            self.authorizationStatus = $0
        }.store(in: &stash)
        
        RFNotification[.unauthorizedKeyHoldersChanged].subscribe { [weak self] in
            self?.unauthorizedKeyHolderIDs = $0
        }.store(in: &stash)
        
        RFNotification[.endpointsChanged].subscribe { [weak self] in
            self?.endpoints = $0
        }.store(in: &stash)
        
        RFNotification[.activeEndpointIDsChanged].subscribe { [weak self] in
            self?.activeEndpointIDs = $0
        }.store(in: &stash)
        
        #if canImport(UIKit)
        RFNotification[.didBecomeActive].subscribe {
            Task {
                await PersistenceManager.shared.keyHolder.updateKeyHolders()
            }
        }.store(in: &stash)
        #endif
    }
    
    nonisolated func parseStatus(_ status: NEVPNStatus, for endpointID: UUID, connectedSince: Date?) {
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
            
            if self.endpointStatus[endpointID]?.priority != parsed.priority {
                self.endpointStatus[endpointID] = parsed
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
