//
//  ConnectedLabel.swift
//  SatelliteGuard
//
//  Created by Rasmus Krämer on 15.11.24.
//

import Foundation
import SwiftUI

struct ConnectedLabel: View {
    @Environment(Satellite.self) private var satellite
    
    var indicator: Bool = false
    
    var body: some View {
        Group {
            if let connectedSince = satellite.connectedSince {
                Text("connected.since")
                + Text(verbatim: " ")
                + Text(connectedSince, style: .relative)
            } else {
                Text("connected")
            }
        }
        .compositingGroup()
        .overlay(alignment: .leading) {
            if indicator {
                Image(systemName: "circle.fill")
                    .symbolEffect(.pulse)
                    .font(.system(size: 16))
                    .foregroundStyle(.green)
                    .offset(x: -30)
            }
        }
    }
}
