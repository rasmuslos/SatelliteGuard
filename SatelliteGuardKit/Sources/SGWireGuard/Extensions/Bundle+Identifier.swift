//
//  Bundle+identifier.swift
//  SatelliteGuard
//
//  Created by Rasmus Krämer on 11.11.24.
//

import Foundation

extension Bundle {
    var networkExtensionIdentifier: String? {
        bundleIdentifier?.appending(".WireGuardExtension")
    }
}
