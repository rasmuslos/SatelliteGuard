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
    @State private var viewModel: EndpointViewModel
    
    init(endpoint: Endpoint) {
        _viewModel = .init(initialValue: .init(endpoint: endpoint))
    }
    
    private var isActive: Bool {
        satellite.connectedID == viewModel.endpoint.id
    }
    
    var body: some View {
        List {
            if viewModel.pondering || satellite.busy {
                ProgressView()
            } else if !viewModel.endpoint.active {
                Button {
                    viewModel.activate()
                } label: {
                    Label("endpoint.activate", systemImage: "plus.diamond")
                }
            } else {
                Button {
                    if isActive {
                        satellite.land(viewModel.endpoint)
                    } else {
                        satellite.launch(viewModel.endpoint)
                    }
                } label: {
                    Label(isActive ? "disconnect" : "connect", systemImage: "diamond")
                        .symbolVariant(isActive ? .fill : .none)
                }
            }
            
            if isActive {
                Label("endpoint.connected", systemImage: "circle.fill")
                    .foregroundStyle(.green)
            }
            
            Section("endpoint.addresses") {
                ForEach(viewModel.endpoint.addresses) { range in
                    Row(range.stringRepresentation)
                }
            }
            
            if let dns = viewModel.endpoint.dns {
                Section("endpoint.dns") {
                    ForEach(dns, id: \.rawValue) { server in
                        Row("\(server)")
                    }
                }
            }
            
            ForEach(viewModel.endpoint.peers) { peer in
                Section("endpoint.peer") {
                    Row(peer.endpoint)
                    Row(peer.routes.map(\.stringRepresentation).joined(separator: ", "))
                    
                    Group {
                        Row(peer.publicKey.base64EncodedString())
                        
                        if let preSharedKey = peer.preSharedKey {
                            Row(preSharedKey.base64EncodedString())
                        }
                    }
                    .privacySensitive()
                    
                    if let persistentKeepAlive = peer.persistentKeepAlive {
                        Row("endpoint.mtu \(persistentKeepAlive.formatted(.number.grouping(.never)))")
                    }
                }
            }
            
            Section("endpoint.interface") {
                Row(viewModel.endpoint.privateKey.base64EncodedString())
                    .privacySensitive()
                
                if let listenPort = viewModel.endpoint.listenPort {
                    Row("endpoint.listenPort \(listenPort.formatted(.number.grouping(.never)))")
                }
                if let mtu = viewModel.endpoint.mtu {
                    Row("endpoint.mtu \(mtu.formatted(.number.grouping(.never)))")
                }
            }
            
            Section("endpoint.settings") {
                Button {
                    
                } label: {
                    Label("endpoint.edit", systemImage: "pencil")
                }
                .disabled(isActive)
            }
        }
        .animation(.smooth, value: isActive)
        .navigationTitle(viewModel.endpoint.name)
        .toolbar {
            ToolbarItem(placement: .secondaryAction) {
                if viewModel.endpoint.active {
                    Button(role: .destructive) {
                        viewModel.deactivate()
                    } label: {
                        Label("endpoint.deactivate", systemImage: "minus.diamond")
                    }
                }
            }
        }
        .sensoryFeedback(.error, trigger: viewModel.notifyError)
        .sensoryFeedback(.success, trigger: viewModel.notifySuccess)
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

#if DEBUG
#Preview {
    NavigationStack {
        EndpointView(endpoint: .fixture)
    }
}
#endif
