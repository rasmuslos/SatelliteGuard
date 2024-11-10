//
//  MainActor+Animation.swift
//  SatelliteGuard
//
//  Created by Rasmus Krämer on 10.11.24.
//

import Foundation
import SwiftUI

internal extension MainActor {
    static func withAnimation<T>(_ animation: Animation? = nil, _ body: @MainActor @escaping () -> T) async {
        let _ = await MainActor.run {
            SwiftUI.withAnimation(animation) {
                body()
            }
        }
    }
}
