//
//  MenuBarMenu.swift
//  SatelliteGuard
//
//  Created by Rasmus Krämer on 28.11.24.
//

import Foundation
import SwiftUI
import SwiftData
import SatelliteGuardKit

#if os(macOS)
import ServiceManagement
#endif

@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
struct DesktopMenu: View {
    @Environment(Satellite.self) private var satellite
    @Environment(\.openWindow) private var openWindow
    
    let endpoints: [Endpoint] = []
    
    private var activeEndpoints: [Endpoint] {
        endpoints.filter { satellite.activeEndpointIDs.contains($0.id) }
    }
    private var inactiveEndpoints: [Endpoint] {
        endpoints.filter { !satellite.activeEndpointIDs.contains($0.id) }
    }
    
    private var isActive: Bool {
        if case .connected = satellite.dominantStatus {
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
                    
                    StatusLabel(status: nil)
                        .labelStyle(.titleOnly)
                        .bold()
                        .font(.caption2)
                }
                
                Spacer(minLength: 12)
                
                Menu {
                    ConfigurationImporter.Inner()
                    
                    Divider()
                    
                    #if os(macOS)
                    Toggle("launch.login", isOn: .init(get: { SMAppService.mainApp.status == .enabled }, set: satellite.updateServiceRegistration))
                    #endif
                    
                    Button("quit") {
                        exit(0)
                    }
                    .keyboardShortcut("q", modifiers: .command)
                } label: {
                    Image("satellite.guard")
                        .symbolEffect(.pulse, isActive: isActive)
                        .symbolEffect(.wiggle, value: satellite.notifyError)
                        .symbolEffect(.variableColor, isActive: satellite.pondering)
                        .foregroundStyle(satellite.dominantStatus == .disconnected ? .secondary : isActive ? .green : Color.blue)
                }
                .menuStyle(.button)
                .buttonStyle(.plain)
            }
            .animation(.smooth, value: satellite.status)
            
            Divider()
                .padding(.bottom, -4)
            
            if endpoints.isEmpty {
                Button {
                    openWindow(id: "import-configuration")
                    satellite.importPickerVisible.toggle()
                } label: {
                    HStack(spacing: 0) {
                        Text("home.empty")
                            .foregroundStyle(.secondary)
                        
                        Spacer(minLength: 12)
                        
                        Image(systemName: "plus")
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
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
    @Environment(\.openWindow) private var openWindow
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
            if satellite.connectedIDs.contains(endpoint.id) {
                satellite.land(endpoint)
            } else if satellite.activeEndpointIDs.contains(endpoint.id) {
                satellite.launch(endpoint)
            } else {
                satellite.activate(endpoint)
            }
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(!satellite.activeEndpointIDs.contains(endpoint.id) ? .gray : satellite.connectedIDs.contains(endpoint.id) ? .green : .accentColor)
                    .overlay {
                        Image(systemName: !satellite.activeEndpointIDs.contains(endpoint.id) ? "diamond" : satellite.connectedIDs.contains(endpoint.id) ? "diamond.fill" : "diamond.bottomhalf.filled")
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
            Button {
                openWindow(value: endpoint.id)
            } label: {
                Text("endpoint.info")
            }
            
            Divider()
            
            EndpointPrimaryButton(endpoint)
            
            if satellite.activeEndpointIDs.contains(endpoint.id) {
                EndpointDeactivateButton(endpoint)
            } else {
                Button(role: .destructive) {
                    
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
    DesktopMenu()
        .previewEnvironment()
}
#endif
