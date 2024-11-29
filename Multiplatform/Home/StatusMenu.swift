//
//  MenuBarMenu.swift
//  SatelliteGuard
//
//  Created by Rasmus Krämer on 28.11.24.
//

import Foundation
import SwiftUI
import SwiftData
import ServiceManagement
import SatelliteGuardKit

@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
struct StatusMenu: View {
    @Environment(Satellite.self) private var satellite
    
    @Query private var endpoints: [Endpoint]
    @State private var menuExpanded: Bool = false
    
    private var activeEndpoints: [Endpoint] {
        endpoints.filter(\.isActive)
    }
    private var inactiveEndpoints: [Endpoint] {
        endpoints.filter { !$0.isActive }
    }
    
    private var isActive: Bool {
        if let status = satellite.status, case Satellite.VPNStatus.connected = status {
            true
        } else {
            false
        }
    }
    
    var body: some View {
        @Bindable var satellite = satellite
        
        VStack(spacing: 8) {
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("home")
                        .font(.headline)
                    
                    StatusLabel()
                        .labelStyle(.titleOnly)
                        .bold()
                        .font(.caption2)
                }
                
                Spacer(minLength: 12)
                
                Menu {
                    ConfigurationImporter.Inner()
                    
                    Divider()
                    
                    Button("quit") {
                        exit(0)
                    }
                    .keyboardShortcut("q", modifiers: .command)
                } label: {
                    Image("satellite.guard")
                        .symbolEffect(.variableColor, isActive: satellite.pondering)
                        .symbolEffect(.pulse, isActive: isActive)
                        .foregroundStyle(satellite.status == .disconnected ? .secondary : isActive ? .green : Color.blue)
                }
                .menuStyle(.button)
                .buttonStyle(.plain)
            }
            .animation(.smooth, value: satellite.status)
            
            Divider()
                .padding(.bottom, -4)
            
            if endpoints.isEmpty {
                HStack {
                    Text("home.empty")
                    Spacer()
                }
            }
            
            if !activeEndpoints.isEmpty {
                StatusSection(title: "home.active", enableShortcuts: true, endpoints: activeEndpoints)
            }
            if !inactiveEndpoints.isEmpty {
                StatusSection(title: "home.inactive", enableShortcuts: false, endpoints: inactiveEndpoints)
            }
        }
        .foregroundStyle(.primary)
        .padding(12)
        .frame(width: 300)
    }
}

@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
private struct StatusSection: View {
    let title: LocalizedStringKey
    let enableShortcuts: Bool
    let endpoints: [Endpoint]
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(title)
                    .bold()
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            
            ForEach(Array(endpoints.enumerated()), id: \.element) {
                StatusMenuCell(endpoint: $1, index: enableShortcuts ? $0 : nil)
            }
        }
    }
}

@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
private struct StatusMenuCell: View {
    @Environment(Satellite.self) private var satellite
    
    let endpoint: Endpoint
    let index: Int?
    
    @State private var hovered = false
    
    private var shortcut: Character? {
        switch index {
        case 0:
            "1"
        case 1:
            "2"
        case 2:
            "3"
        case 3:
            "4"
        case 4:
            "5"
        case 5:
            "6"
        case 6:
            "7"
        case 7:
            "8"
        case 8:
            "9"
        case 9:
            "0"
        default:
            nil
        }
    }
    
    var body: some View {
        Button {
            if !endpoint.isActive {
                satellite.activate(endpoint)
            } else if satellite.connectedID == endpoint.id {
                satellite.land(endpoint)
            } else {
                satellite.launch(endpoint)
            }
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(!endpoint.isActive ? .gray : satellite.connectedID == endpoint.id ? .green : .accentColor)
                    .overlay {
                        Image(systemName: !endpoint.isActive ? "diamond" : satellite.connectedID == endpoint.id ? "diamond.fill" : "diamond.bottomhalf.filled")
                            .font(.system(size: 12))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 24, height: 24)
                
                Text(endpoint.name)
                
                Spacer()
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .modify {
            if let shortcut {
                $0
                    .keyboardShortcut(.init(unicodeScalarLiteral: shortcut), modifiers: [])
            } else {
                $0
            }
        }
        .contextMenu {
            EndpointPrimaryButton(endpoint)
            
            if endpoint.isActive {
                EndpointDeactivateButton(endpoint)
            } else {
                Button(role: .destructive) {
                    try? endpoint.remove()
                } label: {
                    Text("endpoint.remove")
                }
            }
        }
        .disabled(satellite.pondering)
        .padding(4)
        .background(hovered ? Color.gray.opacity(0.2) : .clear, in: RoundedRectangle(cornerRadius: 8))
        .padding(-4)
        .onHover {
            hovered = $0
        }
        .animation(.smooth, value: hovered)
    }
}

#if DEBUG && os(macOS)
#Preview {
    StatusMenu()
        .previewEnvironment()
}
#endif
