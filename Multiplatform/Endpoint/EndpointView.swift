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
    
    private var toolbarPlacement: ToolbarItemPlacement {
        #if os(tvOS)
        .topBarTrailing
        #else
        .secondaryAction
        #endif
    }
    private var isActive: Bool {
        satellite.connectedID == viewModel.endpoint.id
    }
    
    var body: some View {
        List {
            if viewModel.pondering || satellite.busy {
                ProgressView()
            } else if !viewModel.endpoint.isActive {
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
                    Row(string: range.stringRepresentation)
                }
            }
            
            if let dns = viewModel.endpoint.dns {
                Section("endpoint.dns") {
                    ForEach(dns, id: \.rawValue) { server in
                        Row(string: "\(server)")
                    }
                }
            }
            
            ForEach(viewModel.endpoint.peers) { peer in
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
                Row(string: viewModel.endpoint.privateKey.base64EncodedString())
                    .privacySensitive()
                
                if let listenPort = viewModel.endpoint.listenPort {
                    Row("endpoint.listenPort \(listenPort.formatted(.number.grouping(.never)))")
                }
                if let mtu = viewModel.endpoint.mtu {
                    Row("endpoint.mtu \(mtu.formatted(.number.grouping(.never)))")
                }
            }
        }
        .animation(.smooth, value: isActive)
        .navigationTitle(viewModel.endpoint.name)
        .sheet(isPresented: $viewModel.editSheetPresented) {
            EndpointEditView(endpoint: viewModel.endpoint)
        }
        .toolbar {
            #if !os(tvOS)
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    viewModel.editSheetPresented.toggle()
                } label: {
                    Label("endpoint.edit", systemImage: "pencil")
                }
                .disabled(isActive)
            }
            #endif
            
            ToolbarItem(placement: toolbarPlacement) {
                if viewModel.endpoint.isActive {
                    Button(role: .destructive) {
                        viewModel.deactivate()
                    } label: {
                        Label("endpoint.deactivate", systemImage: "minus.diamond")
                            #if os(tvOS)
                            .labelStyle(.titleOnly)
                            #endif
                    }
                }
            }
        }
        .sensoryFeedback(.error, trigger: viewModel.notifyError)
        .sensoryFeedback(.success, trigger: viewModel.notifySuccess)
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
        EndpointView(endpoint: .fixture)
    }
    .previewEnvironment()
}
#endif
