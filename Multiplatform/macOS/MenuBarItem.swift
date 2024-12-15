//
//  MenuBarItem.swift
//  SatelliteGuard
//
//  Created by Rasmus Krämer on 11.12.24.
//

import SwiftUI
import SatelliteGuardKit

#if os(macOS)
import ServiceManagement
#endif

@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
struct MenuBarItem: View {
    @Environment(Satellite.self) private var satellite
    
    private var isActive: Bool {
        if case .connected = satellite.dominantStatus {
            true
        } else {
            false
        }
    }
    
    var body: some View {
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
                    ConfigurationImportMenu()
                    
                    Divider()
                    
                    #if os(macOS)
                    Toggle("launch.login", isOn: .init(get: { SMAppService.mainApp.status == .enabled }, set: {
                        satellite.updateServiceRegistration($0)
                    }))
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
            .animation(.smooth, value: satellite.endpointStatus)
            
            Divider()
                .padding(.bottom, -4)
            
            KeyHolderAuthorizationView {
                DesktopMenu()
            }
        }
        .foregroundStyle(.primary)
        .padding(12)
        .frame(width: 300)
        .task {
            await PersistenceManager.shared.keyHolder.updateKeyHolders()
        }
    }
}

@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
extension MenuBarItem {
    struct LabelIcon: View {
        let satellite: Satellite
        
        var body: some View {
            switch satellite.dominantStatus {
            case .connected:
                Label("home", systemImage: "diamond.fill")
            case .establishing:
                Label("home", systemImage: "diamond.bottomhalf.filled")
            case .disconnecting:
                Label("home", systemImage: "diamond")
            default:
                Label("home", image: "satellite.guard")
            }
        }
    }
}
