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
        VStack(spacing: 12) {
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
                
                Image("satellite.guard")
                    .foregroundStyle(.secondary)
                    .symbolEffect(.pulse, isActive: satellite.pondering)
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
        .padding(16)
        .frame(width: 300)
    }
}

private struct StatusSection: View {
    @Environment(Satellite.self) private var satellite
    
    let title: LocalizedStringKey
    let endpoints: [Endpoint]
    
    @State private var hovered = false
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(title)
                    .bold()
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            
            ForEach(endpoints) { endpoint in
                HStack(spacing: 8) {
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
                            .fill(satellite.connectedID == endpoint.id ? .green : .gray.opacity(0.4))
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
                .padding(-4)
                .onHover {
                    hovered = $0
                }
                .animation(.smooth, value: hovered)
            }
        }
    }
}

/*
 if endpoints.isEmpty {
     Text("home.empty")
         .foregroundStyle(.secondary)
     
     ConfigurationImporter.Inner()
     exitButton
 } else {
     if !activeEndpoints.isEmpty {
         Section("home.active") {
             ForEach(Array(activeEndpoints.enumerated()), id: \.element) {
                 MenuCell(endpoint: $1, index: $0)
             }
         }
     }
     if !inactiveEndpoints.isEmpty {
         Section("home.inactive") {
             ForEach(Array(inactiveEndpoints.enumerated()), id: \.element) {
                 MenuCell(endpoint: $1, index: $0)
             }
         }
     }
     
     if menuExpanded {
         Section("more") {
             ConfigurationImporter.Inner()
             exitButton
         }
     } else {
         Button {
             withAnimation {
                 menuExpanded.toggle()
             }
         } label: {
             Text("more")
         }
     }
 }
 
private struct MenuCell: View {
    @Environment(Satellite.self) private var satellite
    
    let endpoint: Endpoint
    let index: Int
    
    var body: some View {
        Menu {
            EndpointPrimaryButton(endpoint)
            
            if endpoint.isActive {
                EndpointDeactivateButton(endpoint)
                    .foregroundStyle(.secondary)
            } else {
                Button {
                    try? endpoint.remove()
                } label: {
                    Text("endpoint.remove")
                }
            }
        } label: {
            HStack(spacing: 8) {
                if satellite.connectedID == endpoint.id {
                    Circle()
                        .fill(.green)
                }
                
                Text(endpoint.name)
            }
        }
    }
}
*/

#if DEBUG
#Preview {
    StatusMenu()
        .previewEnvironment()
}
#endif
