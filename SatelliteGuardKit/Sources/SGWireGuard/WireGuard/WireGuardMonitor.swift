//
//  WireGuardMonitor.swift
//  SatelliteGuardKit
//
//  Created by Rasmus Krämer on 11.11.24.
//

import Foundation
import Network
import NetworkExtension
import OSLog
import Combine
import SGPersistence

public class WireGuardMonitor {
    static let logger = Logger(subsystem: "WireGuard", category: "Monitor")
    
    private var _statusPublisher: PassthroughSubject<(UUID, NEVPNStatus, Date?), Never>
    
    private var tokens: [AnyCancellable]
    
    private init() {
        tokens = []
        
        _statusPublisher = .init()
        
        tokens += [NotificationCenter.default.publisher(for: .NEVPNStatusDidChange).sink { [weak self] notification in
            guard let object = notification.object as? NETunnelProviderSession,
                  let manager = object.manager as? NETunnelProviderManager,
                  let id = manager.id else {
                return
            }
            
            self?._statusPublisher.send((id, manager.connection.status, manager.connection.connectedDate))
        }]
    }
}

public extension WireGuardMonitor {
    nonisolated(unsafe) static let shared = WireGuardMonitor()
    
    var statusPublisher: AnyPublisher<(UUID, NEVPNStatus, Date?), Never> {
        _statusPublisher.eraseToAnyPublisher()
    }
    
    static let VPNStatusChanged = NSNotification.Name("VPNStatusChanged")
    
    func ping() {
        Self.logger.info("Pong 🏓")
    }
}
