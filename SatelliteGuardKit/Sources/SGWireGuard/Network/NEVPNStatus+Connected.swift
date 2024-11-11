//
//  NEVPNStatus+Connected.swift
//  SatelliteGuardKit
//
//  Created by Rasmus Krämer on 11.11.24.
//

import NetworkExtension

public extension NEVPNStatus {
    var isConnected: Bool {
        switch self {
        case .connecting, .connected, .reasserting:
            true
        case .invalid, .disconnected, .disconnecting:
            false
        default:
            false
        }
    }
}
