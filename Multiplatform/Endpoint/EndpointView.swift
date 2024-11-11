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
    
    @ViewBuilder
    private var rows: some View {
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
                #if os(tvOS)
                .focusable()
                #endif
            
            if let listenPort = viewModel.endpoint.listenPort {
                Row("endpoint.listenPort \(listenPort.formatted(.number.grouping(.never)))")
            }
            if let mtu = viewModel.endpoint.mtu {
                Row("endpoint.mtu \(mtu.formatted(.number.grouping(.never)))")
            }
        }
    }
    
    var body: some View {
        Group {
            #if os(tvOS)
            TwoColumn() {
                Image(systemName: viewModel.endpoint.isActive ? isActive ? "diamond.fill" : "diamond.bottomhalf.filled" : "diamond")
                    .symbolEffect(.pulse, isActive: viewModel.pondering || satellite.busy)
                    .foregroundStyle(.secondary)
                    .font(.system(size: 500))
                
                Text("endpoint.connected")
                    .overlay(alignment: .leading) {
                        Image(systemName: "circle.fill")
                            .symbolEffect(.pulse)
                            .font(.system(size: 16))
                            .foregroundStyle(.green)
                            .offset(x: -30)
                    }
                    .opacity(isActive ? 1 : 0)
            } trailing: {
                List {
                    Button {
                        if !viewModel.endpoint.isActive {
                            viewModel.activate()
                        } else if isActive {
                            satellite.land(viewModel.endpoint)
                        } else {
                            satellite.launch(viewModel.endpoint)
                        }
                    } label: {
                        Text(!viewModel.endpoint.isActive ? "endpoint.activate" : isActive ? "disconnect" : "connect")
                    }
                    
                    if viewModel.endpoint.isActive {
                        Button(role: .destructive) {
                            viewModel.deactivate()
                        } label: {
                            Text("endpoint.deactivate")
                        }
                    }
                    
                    rows
                }
                .listStyle(.grouped)
                .scrollClipDisabled()
            }
            #else
            List {
                if viewModel.pondering || satellite.busy {
                    ProgressView()
                } else if !viewModel.endpoint.isActive {
                    Button {
                        viewModel.activate()
                    } label: {
                        Label("endpoint.activate", systemImage: "diamond")
                    }
                } else {
                    Button {
                        if isActive {
                            satellite.land(viewModel.endpoint)
                        } else {
                            satellite.launch(viewModel.endpoint)
                        }
                    } label: {
                        Label(isActive ? "disconnect" : "connect", systemImage: isActive ? "diamond.fill" : "diamond.bottomhalf.filled")
                    }
                }
                
                if isActive {
                    Label("endpoint.connected", systemImage: "circle.fill")
                        .foregroundStyle(.green)
                }
                
                rows
            }
            .sheet(isPresented: $viewModel.editSheetPresented) {
                EndpointEditView(endpoint: viewModel.endpoint)
            }
            .toolbar {
                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        viewModel.editSheetPresented.toggle()
                    } label: {
                        Label("endpoint.edit", systemImage: "pencil")
                    }
                    .disabled(isActive)
                }
                
                ToolbarItem(placement: toolbarPlacement) {
                    if viewModel.endpoint.isActive {
                        Button(role: .destructive) {
                            viewModel.deactivate()
                        } label: {
                            Label("endpoint.deactivate", systemImage: "minus.diamond")
                        }
                    }
                }
            }
            #endif
        }
        .navigationTitle(viewModel.endpoint.name)
        .animation(.smooth, value: isActive)
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
