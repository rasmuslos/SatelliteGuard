//
//  IPAddress+Identifiable.swift
//  SatelliteGuard
//
//  Created by Rasmus Krämer on 10.11.24.
//

import Foundation
import Network
import WireGuardKit

extension IPAddressRange: @retroactive Identifiable {
    public var id: String {
        stringRepresentation
    }
}
