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
    @MainActor var aboutSheetPresented: Bool
    
    @MainActor private(set) var importing: Bool
    @MainActor private(set) var transmitting: Int
    
    @MainActor private(set) var notifyError: Bool
    @MainActor private(set) var notifySuccess: Bool
    
    @ObservationIgnored private var tokens: [Any]!
    private static let logger = Logger(subsystem: "Core", category: "Satellite")
    
    @MainActor
    init() {
        status = [:]
        
        editingEndpoint = nil
        aboutSheetPresented = false
        
        importing = false
        transmitting = 0
        
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
            case .connected(let since):
                3
            }
        }
    }
}

extension Satellite {
    @MainActor
    var pondering: Bool {
        transmitting > 0 || !status.filter { $1 == .establishing || $1 == .disconnecting }.isEmpty
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
                } catch {
                    print(error)
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
    func launch(_ endpoint: Endpoint, _ status: Binding<Bool>? = nil, _ notifySuccess: Binding<Bool>? = nil, _ notifyError: Binding<Bool>? = nil) {
        Task {
            await MainActor.withAnimation {
                self.transmitting += 1
                status?.wrappedValue = true
            }
            
            do {
                for connectedId in await self.connectedIDs {
                    if let current = Endpoint.identified(by: connectedId) {
                        await current.disconnect()
                    }
                }
                
                try await endpoint.connect()
                
                await MainActor.withAnimation {
                    self.status[endpoint.id] = .establishing
                    
                    self.notifySuccess.toggle()
                    notifySuccess?.wrappedValue.toggle()
                }
            } catch {
                await MainActor.withAnimation {
                    self.notifyError.toggle()
                    notifyError?.wrappedValue.toggle()
                    
                    self.transmitting -= 1
                }
            }
            
            await MainActor.withAnimation {
                self.transmitting -= 1
                status?.wrappedValue = false
            }
        }
    }
    func land(_ endpoint: Endpoint?, _ status: Binding<Bool>? = nil, _ notifySuccess: Binding<Bool>? = nil, _ notifyError: Binding<Bool>? = nil) {
        Task {
            await MainActor.withAnimation {
                self.transmitting += 1
                status?.wrappedValue = true
            }
            
            if let endpoint {
                await endpoint.disconnect()
                await MainActor.withAnimation {
                    self.status[endpoint.id] = .disconnecting
                }
            } else {
                for connectedId in await self.connectedIDs {
                    if let current = Endpoint.identified(by: connectedId) {
                        await current.disconnect()
                        await MainActor.withAnimation {
                            self.status[current.id] = .disconnecting
                        }
                    }
                }
            }
            
            await MainActor.withAnimation {
                self.notifySuccess.toggle()
                notifySuccess?.wrappedValue.toggle()
                
                self.transmitting -= 1
                status?.wrappedValue = false
            }
        }
    }
    
    func activate(_ endpoint: Endpoint, _ status: Binding<Bool>? = nil, _ notifySuccess: Binding<Bool>? = nil, _ notifyError: Binding<Bool>? = nil) {
        Task {
            await MainActor.withAnimation {
                self.transmitting += 1
                status?.wrappedValue = true
            }
            
            do {
                try await endpoint.notifySystem()
                
                await MainActor.withAnimation {
                    self.notifySuccess.toggle()
                    notifySuccess?.wrappedValue.toggle()
                }
            } catch {
                await MainActor.withAnimation {
                    self.notifyError.toggle()
                    notifyError?.wrappedValue.toggle()
                    
                    self.transmitting -= 1
                }
            }
            
            await MainActor.withAnimation {
                self.notifySuccess.toggle()
                notifySuccess?.wrappedValue.toggle()
                
                self.transmitting -= 1
                status?.wrappedValue = false
            }
        }
    }
    func deactivate(_ endpoint: Endpoint, _ status: Binding<Bool>? = nil, _ notifySuccess: Binding<Bool>? = nil, _ notifyError: Binding<Bool>? = nil) {
        Task {
            await MainActor.withAnimation {
                self.transmitting += 1
                status?.wrappedValue = true
            }
            
            do {
                try await endpoint.deactivate()
                
                await MainActor.withAnimation {
                    self.notifySuccess.toggle()
                    notifySuccess?.wrappedValue.toggle()
                }
            } catch {
                await MainActor.withAnimation {
                    self.notifyError.toggle()
                    notifyError?.wrappedValue.toggle()
                    
                    self.transmitting -= 1
                }
            }
            
            await MainActor.withAnimation {
                self.notifySuccess.toggle()
                notifySuccess?.wrappedValue.toggle()
                
                self.transmitting -= 1
                status?.wrappedValue = false
            }
        }
    }
    
    enum SatelliteError: Error {
        case permissionDenied
        case invalidConfiguration
    }
}

private extension Satellite {
    func setupObservers() -> [Any] {
        var tokens = [WireGuardMonitor.shared.statusPublisher.sink { [weak self] (id, status, connectedSince) in
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
                self?.status[id] = parsed
            }
        }]
        #if !os(macOS)
        tokens += [NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification).sink { [weak self] _ in
            Task {
                guard let endpoints = await Endpoint.all else {
                    return
                }
                
                for endpoint in endpoints {
                    let status: VPNStatus
                    
                    switch await endpoint.status {
                    case .connected:
                        status = .connected(since: .now)
                    case .connecting:
                        status = .establishing
                    default:
                        status = .disconnected
                    }
                    
                    await MainActor.withAnimation {
                        self?.status[endpoint.id] = status
                    }
                }
            }
        }]
        #endif
        
        return tokens
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
