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
    
    let status: Satellite.VPNStatus?
    
    var color = false
    var indicator = false
    
    private var isActive: Bool {
        if case .connected = satellite.dominantStatus {
            true
        } else {
            false
        }
    }
    
    private var dominantStatus: Satellite.VPNStatus {
        status ?? satellite.dominantStatus
    }
    
    var body: some View {
        if dominantStatus != .disconnected {
            Label {
                switch dominantStatus {
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
                    .symbolVariant(dominantStatus == .disconnecting ? .none : .fill)
                    .foregroundStyle(isActive ? .green : .blue)
            }
            .modify {
                if color {
                    $0.foregroundStyle(dominantStatus == .establishing ? .blue : .green)
                } else {
                    $0
                }
            }
            .animation(.smooth, value: dominantStatus)
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
