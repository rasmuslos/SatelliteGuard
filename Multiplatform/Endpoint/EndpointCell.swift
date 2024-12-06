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
    
    private var icon: String {
        if !endpoint.isActive {
            "diamond"
        } else if satellite.connectedIDs.contains(endpoint.id) {
            "diamond.fill"
        } else {
            "diamond.bottomhalf.filled"
        }
    }
    
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
        satellite.connectedIDs.contains(endpoint.id)
    }
    
    @MainActor
    private var toggle: Binding<Bool> {
        .init() { isActive } set: { $0 ? satellite.launch(endpoint) : satellite.land(endpoint) }
    }
    
    var body: some View {
        NavigationLink(destination: EndpointView(endpoint)) {
            HStack(spacing: 0) {
                #if os(tvOS)
                label
                
                if isActive {
                    Spacer(minLength: 12)
                    Image(systemName: "circle.fill")
                        .foregroundStyle(.green)
                }
                #else
                Image(systemName: icon)
                    .padding(.trailing, 16)
                
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
            .padding(12)
        }
        .listRowInsets(.init(top: 0, leading: 4, bottom: 0, trailing: 12))
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
