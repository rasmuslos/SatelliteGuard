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
    @State private var viewModel: EndpointViewModel
    
    init(endpoint: Endpoint) {
        _viewModel = .init(initialValue: .init(endpoint: endpoint))
    }
    
    var body: some View {
        List {
            if viewModel.activating {
                ProgressView()
            } else if viewModel.endpoint.active {
                Button {
                    
                } label: {
                    Label("connect", systemImage: "network")
                }
            } else {
                Button {
                    viewModel.activate()
                } label: {
                    Label("endpoint.activate", systemImage: "lock.document.fill")
                }
            }
            
            Section {
                Row(viewModel.endpoint.friendlyURL)
                
                if let listenPort = viewModel.endpoint.listenPort {
                    Row("endpoint.listenPort \(listenPort.formatted(.number.grouping(.never)))")
                }
                if let mtu = viewModel.endpoint.mtu {
                    Row("endpoint.mtu \(mtu.formatted(.number.grouping(.never)))")
                }
                if let persistentKeepAlive = viewModel.endpoint.persistentKeepAlive {
                    Row("endpoint.persistentKeepAlive \(persistentKeepAlive.formatted(.number.grouping(.never)))")
                }
            }
            
            Section("endpoint.keys") {
                Group {
                    Row(viewModel.endpoint.privateKey.base64EncodedString())
                    Row(viewModel.endpoint.publicKey.base64EncodedString())
                    
                    if let preSharedKey = viewModel.endpoint.preSharedKey {
                        Row(preSharedKey.base64EncodedString())
                    }
                }
                .privacySensitive()
            }
            
            if let dns = viewModel.endpoint.dns {
                Section("endpoint.dns") {
                    ForEach(dns, id: \.rawValue) { server in
                        Row("\(server)")
                    }
                }
            }
            
            Section("endpoint.routes") {
                ForEach(viewModel.endpoint.routes) { range in
                    Row(range.stringRepresentation)
                }
            }
            
            Section("endpoint.addresses") {
                ForEach(viewModel.endpoint.addresses) { range in
                    Row(range.stringRepresentation)
                }
            }
        }
        .navigationTitle(viewModel.endpoint.name)
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
