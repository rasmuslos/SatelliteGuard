//
//  ConnectedLabel.swift
//  SatelliteGuard
//
//  Created by Rasmus Krämer on 15.11.24.
//

import Foundation
import SwiftUI

struct StatusLabel: View {
    @Environment(Satellite.self) private var satellite
    
    var color = false
    var indicator = false
    
    private var isActive: Bool {
        if let status = satellite.status, case Satellite.VPNStatus.connected = status {
            true
        } else {
            false
        }
    }
    
    var body: some View {
        if satellite.status != .disconnected {
            Label {
                switch satellite.status {
                case .connected(let since):
                    Text("connected.since")
                    + Text(verbatim: " ")
                    + Text(since, style: .relative)
                case .establishing:
                    Text("connecting")
                case .disconnecting:
                    Text("disconnecting")
                default:
                    EmptyView()
                }
            } icon: {
                Image(systemName: "circle")
                    .symbolEffect(.pulse, isActive: isActive)
                    .symbolVariant(satellite.status == .disconnecting ? .none : .fill)
                    .foregroundStyle(isActive ? .green : .blue)
            }
            .modify {
                if color {
                    $0.foregroundStyle(satellite.status == .establishing ? .blue : .green)
                } else {
                    $0
                }
            }
            .animation(.smooth, value: satellite.status)
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
}
