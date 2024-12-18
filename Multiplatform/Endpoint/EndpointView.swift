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
    @Environment(Satellite.self) private var satellite
    
    let endpoint: Endpoint
    
    init(_ endpoint: Endpoint) {
        self.endpoint = endpoint
    }
    
    private var isActive: Bool {
        satellite.connectedIDs.contains(endpoint.id)
    }
    
    #if !os(tvOS)
    private var toolbarPlacement: ToolbarItemPlacement {
        #if os(macOS)
        .primaryAction
        #else
        .secondaryAction
        #endif
    }
    #endif
    
    @ViewBuilder
    @available(tvOS, unavailable)
    private var status: some View {
        if let status = satellite.endpointStatus[endpoint.id], status != .disconnected {
            StatusLabel(status: status, color: true)
        } else {
            EndpointEditButton(endpoint)
        }
    }
    
    var body: some View {
        Group {
            List {
                #if !os(macOS)
                if satellite.pondering {
                    ProgressView()
                } else {
                    EndpointPrimaryButton(endpoint)
                }
                
                #if !os(tvOS)
                status
                #endif
                
                EndpointDestructiveButton(endpoint)
                #endif
                
                Section("endpoint.addresses") {
                    ForEach(endpoint.addresses) { range in
                        Row(string: range.stringRepresentation)
                    }
                }
                
                if let dns = endpoint.dns {
                    Section("endpoint.dns") {
                        ForEach(dns, id: \.rawValue) { server in
                            Row(string: "\(server)")
                        }
                    }
                }
                
                ForEach(endpoint.peers) { peer in
                    Section("endpoint.peer") {
                        Row(string: peer.endpoint)
                        Row(string: peer.routes.map(\.stringRepresentation).joined(separator: ", "))
                        
                        Group {
                            Row(string: peer.publicKey.base64EncodedString())
                            
                            if let preSharedKey = peer.preSharedKey {
                                Row(string: preSharedKey.base64EncodedString())
                            }
                        }
                        .privacySensitive()
                        
                        if let persistentKeepAlive = peer.persistentKeepAlive {
                            Row("endpoint.mtu \(persistentKeepAlive.formatted(.number.grouping(.never)))")
                        }
                    }
                }
                
                Section("endpoint.interface") {
                    Row(string: endpoint.privateKey.base64EncodedString())
                        .privacySensitive()
                        #if os(tvOS)
                        .focusable()
                        #endif
                    
                    if let listenPort = endpoint.listenPort {
                        Row("endpoint.listenPort \(listenPort.formatted(.number.grouping(.never)))")
                    }
                    if let mtu = endpoint.mtu {
                        Row("endpoint.mtu \(mtu.formatted(.number.grouping(.never)))")
                    }
                }
            }
            #if os(tvOS)
            .listStyle(.grouped)
            .padding(.leading, ContentView.gap)
            .scrollClipDisabled()
            #else
            .navigationTitle(endpoint.name)
            .toolbar {
                ToolbarItemGroup(placement: toolbarPlacement) {
                    EndpointEditButton(endpoint)
                    
                    
                    #if !os(macOS)
                    Divider()
                    #endif
                    
                    EndpointPrimaryButton(endpoint)
                    EndpointDestructiveButton(endpoint)
                }
            }
            #endif
            #if os(iOS)
            .listStyle(.insetGrouped)
            #elseif os(macOS)
            .listStyle(.inset)
            .navigationSubtitle(endpoint.peers.map { $0.endpoint }.joined(separator: ", "))
            #endif
        }
        .preference(key: NavigationContextPreferenceKey.self, value: .endpoint(endpoint))
        .animation(.smooth, value: isActive)
    }
}

private struct Row: View {
    let text: LocalizedStringKey?
    let string: String?
    
    init(string: String) {
        text = nil
        self.string = string
    }
    init(_ text: LocalizedStringKey) {
        self.text = text
        string = nil
    }
    
    var body: some View {
        Group {
            if let text {
                Text(text)
            } else if let string {
                Text(string)
            }
        }
        .fontDesign(.monospaced)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        EndpointView(.fixture)
    }
    .previewEnvironment()
}
#endif
