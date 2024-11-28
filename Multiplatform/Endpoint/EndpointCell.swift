//
//  EndpointCell.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 10.11.24.
//

import SwiftUI
import SwiftData
import SatelliteGuardKit

@available(macOS, unavailable)
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
    private var isActive: Bool {
        satellite.connectedID == endpoint.id
    }
    
    @MainActor
    private var toggle: Binding<Bool> {
        .init() { isActive } set: { $0 ? satellite.launch(endpoint) : satellite.land(endpoint) }
    }
    
    var body: some View {
        NavigationLink(destination: EndpointView(endpoint)) {
            #if os(tvOS)
            HStack(spacing: 0) {
                label
                
                if isActive {
                    Spacer(minLength: 12)
                    Image(systemName: "circle.fill")
                        .foregroundStyle(.green)
                }
            }
            #else
            if endpoint.isActive {
                Toggle(isOn: toggle) {
                    label
                }
                .toggleStyle(.switch)
            } else {
                label
            }
            #endif
        }
        #if !os(tvOS)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if endpoint.isActive {
                EndpointDeactivateButton(endpoint)
            }
        }
        #endif
        .contextMenu {
            EndpointPrimaryButton(endpoint)
            EndpointDeactivateButton(endpoint)
            
            #if !os(tvOS)
            EndpointEditButton(endpoint)
            #endif
        }
    }
}

#if DEBUG && !os(macOS)
#Preview {
    NavigationStack {
        List {
            EndpointCell(endpoint: .fixture)
        }
    }
    .previewEnvironment()
}
#endif
