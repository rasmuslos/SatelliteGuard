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
    
    var body: some View {
        @Bindable var satellite = satellite
        
        VStack(spacing: 8) {
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("home")
                        .font(.headline)
                    
                    if satellite.connectedID != nil {
                        ConnectedLabel()
                            .bold()
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
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
                        .foregroundStyle(.secondary)
                        .symbolEffect(.pulse, isActive: satellite.pondering)
                }
                .menuStyle(.button)
                .buttonStyle(.plain)
            }
            .animation(.smooth, value: satellite.connectedID)
            
            Divider()
                .padding(.bottom, -4)
            
            if endpoints.isEmpty {
                HStack {
                    Text("home.empty")
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                }
            }
            
            if !activeEndpoints.isEmpty {
                StatusSection(title: "home.active", endpoints: activeEndpoints)
            }
            if !inactiveEndpoints.isEmpty {
                StatusSection(title: "home.inactive", endpoints: inactiveEndpoints)
            }
        }
        .foregroundStyle(.primary)
        .padding(12)
        .frame(width: 300)
    }
}

private struct StatusSection: View {
    let title: LocalizedStringKey
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
            
            ForEach(endpoints) {
                StatusMenuCell(endpoint: $0)
            }
        }
    }
}

private struct StatusMenuCell: View {
    @Environment(Satellite.self) private var satellite
    
    let endpoint: Endpoint
    
    @State private var hovered = false
    
    var body: some View {
        HStack(spacing: 6) {
            Button {
                if !endpoint.isActive {
                    satellite.activate(endpoint)
                } else if satellite.connectedID == endpoint.id {
                    satellite.land(endpoint)
                } else {
                    satellite.launch(endpoint)
                }
            } label: {
                Circle()
                    .fill(satellite.connectedID == endpoint.id ? .green : .accentColor)
                    .overlay {
                        Image(systemName: !endpoint.isActive ? "diamond" : satellite.connectedID == endpoint.id ? "diamond.fill" : "diamond.bottomhalf.filled")
                            .font(.system(size: 12))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .disabled(satellite.pondering)
            
            Text(endpoint.name)
            
            Spacer()
        }
        .padding(4)
        .background(hovered ? Color.gray.opacity(0.2) : .clear, in: RoundedRectangle(cornerRadius: 8))
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
        .padding(-4)
        .onHover {
            hovered = $0
        }
        .animation(.smooth, value: hovered)
    }
}

#Preview {
    StatusMenu()
}

#if DEBUG
#Preview {
    StatusMenu()
        .previewEnvironment()
}
#endif
