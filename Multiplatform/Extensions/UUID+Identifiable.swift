//
//  UUID+Identifiable.swift
//  SatelliteGuard
//
//  Created by Rasmus Krämer on 11.11.24.
//

import Foundation

extension UUID: @retroactive Identifiable {
    public var id: Self {
        self
    }
}
