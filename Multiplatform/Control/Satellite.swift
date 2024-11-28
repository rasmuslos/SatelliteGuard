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
    @MainActor private(set) var status: VPNStatus?
    
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
        status = nil
        
        editingEndpoint = nil
        aboutSheetPresented = false
        
        importing = false
        transmitting = 0
        
        notifyError = false
        notifySuccess = false
        
        tokens = setupObservers()
    }
    
    enum VPNStatus: Equatable {
        case disconnected
        case establishing
        case connected(since: Date)
    }
}

extension Satellite {
    @MainActor
    var pondering: Bool {
        transmitting > 0 || status == .establishing
    }
    
    @MainActor
    var connectedID: UUID? {
        if let status, case VPNStatus.connected = status {
            orbitingID
        } else {
            nil
        }
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
    func land(_ endpoint: Endpoint?, _ status: Binding<Bool>? = nil, _ notifySuccess: Binding<Bool>? = nil, _ notifyError: Binding<Bool>? = nil) {
        Task {
            await MainActor.withAnimation {
                self.transmitting += 1
                status?.wrappedValue = true
            }
            
            if let endpoint {
                await endpoint.disconnect()
            } else if let orbitingID = await self.orbitingID, let endpoint = Endpoint.identified(by: orbitingID) {
                await endpoint.disconnect()
            }
            
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
            Task { @MainActor in
                print(id, status.rawValue, connectedSince, await self?.orbitingID)
                
                guard status.isConnected && self?.orbitingID == id else {
                    return
                }
                
                self?.orbitingID = id
                switch status {
                case .connected:
                    self?.status = .connected(since: connectedSince ?? .now)
                case .connecting:
                    self?.status = .establishing
                default:
                    self?.status = .disconnected
                }
            }
        }]
        #if !os(macOS)
        tokens += [NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification).sink { _ in
            Task {
                guard let endpoints = await Endpoint.all else {
                    return
                }
                
                let orbitingID = await self.orbitingID
                
                for endpoint in endpoints {
                    let status = await endpoint.status
                    
                    if status.isConnected {
                        await MainActor.withAnimation {
                            self.orbitingID = endpoint.id
                            
                            switch status {
                            case .connected:
                                self.status = .connected(since: .now)
                            case .connecting:
                                self.status = .establishing
                            default:
                                self.status = .disconnected
                            }
                        }
                    } else if !status.isConnected && orbitingID == endpoint.id {
                        await MainActor.withAnimation {
                            self.orbitingID = nil
                            self.status = nil
                        }
                    } else {
                        continue
                    }
                    
                    break
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
