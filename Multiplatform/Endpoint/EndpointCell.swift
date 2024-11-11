//
//  EndpointCell.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 10.11.24.
//

import SwiftUI
import SwiftData
import SatelliteGuardKit

struct EndpointCell: View {
    @Environment(Satellite.self) private var satellite
    
    let endpoint: Endpoint
    
    @State private var pondering = false
    
    @ViewBuilder
    private var label: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(endpoint.name)
            Text(endpoint.peers.map { $0.endpoint }.joined(separator: ", "))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
    
    @MainActor
    private var toggle: Binding<Bool> {
        .init() { satellite.connectedID == endpoint.id } set: { $0 ? satellite.launch(endpoint) : satellite.land(endpoint) }
    }
    
    var body: some View {
        NavigationLink(destination: EndpointView(endpoint: endpoint)) {
            if endpoint.isActive {
                Toggle(isOn: toggle) {
                    label
                }
                .toggleStyle(.switch)
            } else {
                label
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        List {
            EndpointCell(endpoint: .fixture)
        }
    }
}
#endif
