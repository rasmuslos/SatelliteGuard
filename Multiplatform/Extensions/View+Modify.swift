//
//  View+Modify.swift
//  SatelliteGuard
//
//  Created by Rasmus Krämer on 28.11.24.
//

import Foundation
import SwiftUI

internal extension View {
    func modify<T: View>(@ViewBuilder _ modifier: (Self) -> T) -> some View {
        return modifier(self)
    }
}
