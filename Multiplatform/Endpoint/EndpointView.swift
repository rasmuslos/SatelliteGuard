//
//  EndpointView.swift
//  SatelliteGuard
//
//  Created by Rasmus Krämer on 10.11.24.
//

import Foundation
import Network
import SwiftUI
import SatelliteGuardKit

struct EndpointView: View {
    let endpoint: Endpoint
    
    var body: some View {
        List {
            if endpoint.active {
                Button {
                    
                } label: {
                    Label("endpoint.activate", systemImage: "lock.document.fill")
                }
            } else {
                Button {
                    
                } label: {
                    Label("connect", systemImage: "network")
                }
            }
            
            Section {
                Row(endpoint.friendlyURL)
                
                if let listenPort = endpoint.listenPort {
                    Row("endpoint.listenPort \(listenPort.formatted(.number.grouping(.never)))")
                }
                if let mtu = endpoint.mtu {
                    Row("endpoint.mtu \(mtu.formatted(.number.grouping(.never)))")
                }
                if let persistentKeepAlive = endpoint.persistentKeepAlive {
                    Row("endpoint.persistentKeepAlive \(persistentKeepAlive.formatted(.number.grouping(.never)))")
                }
            }
            
            Section("endpoint.keys") {
                Group {
                    Row(endpoint.privateKey.base64EncodedString())
                    Row(endpoint.publicKey.base64EncodedString())
                    
                    if let preSharedKey = endpoint.preSharedKey {
                        Row(preSharedKey.base64EncodedString())
                    }
                }
                .privacySensitive()
            }
            
            if let dns = endpoint.dns {
                Section("endpoint.dns") {
                    ForEach(dns, id: \.rawValue) { server in
                        Row("\(server)")
                    }
                }
            }
            
            Section("endpoint.routes") {
                ForEach(endpoint.routes) { range in
                    Row(range.stringRepresentation)
                }
            }
            
            Section("endpoint.addresses") {
                ForEach(endpoint.addresses) { range in
                    Row(range.stringRepresentation)
                }
            }
        }
        .navigationTitle(endpoint.name)
    }
}

private struct Row: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        Text(text)
            .fontDesign(.monospaced)
    }
}

#Preview {
    NavigationStack {
        EndpointView(endpoint: .fixture)
    }
}
