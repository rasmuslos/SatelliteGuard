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
import RFNotifications
import SGPersistence

public class WireGuardMonitor {
    let logger = Logger(subsystem: "WireGuard", category: "Monitor")
    private var token: AnyCancellable
    
    private init() {
        token = NotificationCenter.default.publisher(for: .NEVPNStatusDidChange).sink { notification in
            guard let object = notification.object as? NETunnelProviderSession,
                  let manager = object.manager as? NETunnelProviderManager,
                  let id = manager.id else {
                return
            }
            
            RFNotification[.vpnStatusUpdate].send((id, manager.connection.status, manager.connection.connectedDate))
        }
    }
}

public extension WireGuardMonitor {
    nonisolated(unsafe) static let shared = WireGuardMonitor()
    
    static let VPNStatusChanged = NSNotification.Name("VPNStatusChanged")
    
    func ping() {
        logger.info("Pong 🏓")
    }
}
