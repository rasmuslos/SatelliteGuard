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
    let endpoint: Endpoint
    
    @ViewBuilder
    private var label: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(endpoint.name)
            Text(endpoint.friendlyURL)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
    
    var body: some View {
        NavigationLink(destination: EndpointView(endpoint: endpoint)) {
            if endpoint.active {
                Toggle(isOn: .constant(false)) {
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
