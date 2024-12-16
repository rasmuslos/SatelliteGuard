//
//  Untitled.swift
//  SatelliteGuardKit
//
//  Created by Rasmus Krämer on 16.12.24.
//

import Foundation
import RFNotifications
import Network
import NetworkExtension

#if canImport(UIKit)
import UIKit
#endif

public extension RFNotification.Notification {
    static var vpnStatusUpdate: Notification<(UUID, NEVPNStatus, Date?)> { .init("io.rfk.SatelliteGuardKit.vpnStatusUpdate") }
}
