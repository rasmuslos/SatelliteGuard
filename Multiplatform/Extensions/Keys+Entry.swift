//
//  Keys+Entry.swift
//  SatelliteGuard
//
//  Created by Rasmus Krämer on 17.11.24.
//

import SwiftUI
import SatelliteGuardKit

struct NavigationContextPreferenceKey: PreferenceKey {
    static var defaultValue: NavigationContext = .unknown
    
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = nextValue()
    }
    
    enum NavigationContext: Equatable {
        case unknown
        case home
        case endpoint(_ endpoint: Endpoint)
    }
}
