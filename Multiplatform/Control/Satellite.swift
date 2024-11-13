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

@Observable
final class Satellite {
    @MainActor private var orbitingID: UUID?
    @MainActor private(set) var status: NEVPNStatus
    @MainActor private(set) var connectedSince: Date?
    
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
        orbitingID = nil
        status = .invalid
        
        editingEndpoint = nil
        aboutSheetPresented = false
        
        importing = false
        transmitting = 0
        
        notifyError = false
        notifySuccess = false
        
        tokens = setupObservers()
    }
}

extension Satellite {
    @MainActor
    var connectedLabel: String {
        if let connectedSince {
            let friendlyDate = connectedSince.formatted(date: .abbreviated, time: .shortened)
            
            return .init(localized: "connected.since \(friendlyDate)")
        }
        
        return .init(localized: "connected")
    }
    
    @MainActor
    var pondering: Bool {
        transmitting > 0
    }
    
    @MainActor
    var connectedID: UUID? {
        status.isConnected ? orbitingID : nil
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
}

extension Satellite {
    func launch(_ endpoint: Endpoint, _ status: Binding<Bool>? = nil, _ notifySuccess: Binding<Bool>? = nil, _ notifyError: Binding<Bool>? = nil) {
        Task {
            await MainActor.withAnimation {
                self.transmitting += 1
                status?.wrappedValue = true
            }
            
            do {
                if let orbitingID = await orbitingID, await connectedID != orbitingID.id, let current = Endpoint.identified(by: orbitingID) {
                    await current.disconnect()
                }
                
                try await endpoint.connect()
                
                await MainActor.withAnimation {
                    self.orbitingID = endpoint.id
                    
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
    func land(_ endpoint: Endpoint, _ status: Binding<Bool>? = nil, _ notifySuccess: Binding<Bool>? = nil, _ notifyError: Binding<Bool>? = nil) {
        Task {
            await MainActor.withAnimation {
                self.transmitting += 1
                status?.wrappedValue = true
            }
            
            await endpoint.disconnect()
            await MainActor.withAnimation {
                self.orbitingID = nil
                
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
                    self.orbitingID = endpoint.id
                    
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
                try await endpoint.notifySystem()
                
                await MainActor.withAnimation {
                    self.orbitingID = endpoint.id
                    
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
        [WireGuardMonitor.shared.statusPublisher.sink { (id, status, connectedSince) in
            Task { @MainActor in
                guard status.isConnected && self.orbitingID == id else {
                    return
                }
                
                self.orbitingID = id
                self.status = status
                self.connectedSince = connectedSince
            }
        }]
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
