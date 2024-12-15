//
//  RFNotification+Entries.swift
//  SatelliteGuardKit
//
//  Created by Rasmus Krämer on 15.12.24.
//

import Foundation
import RFNotifications

#if canImport(UIKit)
import UIKit
#endif

public extension RFNotification.Notification {
    static var endpointsChanged: Notification<[Endpoint]> { .init("io.rfk.SatelliteGuardKit.endpointsChanged") }
    static var activeEndpointIDsChanged: Notification<Set<UUID>> { .init("io.rfk.SatelliteGuardKit.activeEndpointIDsChanged") }
    
    static var authorizationChanged: Notification<PersistenceManager.KeyHolderSubsystem.AuthorizationStatus> { .init("io.rfk.SatelliteGuardKit.authorizationChanged") }
    static var unauthorizedKeyHoldersChanged: Notification<[PersistenceManager.KeyHolderSubsystem.UnauthorizedKeyHolder]> { .init("io.rfk.SatelliteGuardKit.unauthorizedKeyHoldersChanged") }
    
    #if canImport(UIKit)
    static var didBecomeActive: Notification<RFNotificationEmptyPayload> { .init(UIApplication.didBecomeActiveNotification) }
    #endif
}
