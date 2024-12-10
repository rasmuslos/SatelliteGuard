//
//  EditEndpointView.swift
//  SatelliteGuard
//
//  Created by Rasmus Krämer on 11.11.24.
//

import Foundation
import SwiftUI
import SatelliteGuardKit

@available(tvOS, unavailable)
struct EndpointEditView: View {
    @Environment(Satellite.self) private var satellite
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel: EndpointEditViewModel
    
    init(_ endpoint: Endpoint) {
        _viewModel = .init(initialValue: .init(endpoint: endpoint))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("endpoint.edit.name", text: .constant(""))
                }
                
                Group {
                    Section {
                        TextField("endpoint.edit.privateKey", text: viewModel.privateKey)
                        Group {
                            TextField("endpoint.edit.listenPort", text: viewModel.listenPort)
                            TextField("endpoint.edit.mtu", text: viewModel.mtu)
                        }
                        #if !os(macOS)
                        .keyboardType(.numberPad)
                        #endif
                    } footer: {
                        VStack {
                            if viewModel.privateKeyMalformed {
                                Text("endpoint.edit.key.malformed")
                            }
                            if viewModel.listenPortMalformed {
                                Text("endpoint.edit.listenPort.malformed")
                            }
                            if viewModel.mtuMalformed {
                                Text("endpoint.edit.mtu.malformed")
                            }
                        }
                        .foregroundStyle(.red)
                    }
                }
                .autocorrectionDisabled()
                #if !os(macOS)
                .textInputAutocapitalization(.never)
                #endif
                
                Section {
                } footer: {
                    Text("endpoint.edit.appleTVDisclaimer")
                }
                
                Section {} header: {
                    Text("endpoint.edit.active")
                } footer: {
                    VStack(alignment: .leading) {
                    }
                }
            }
            .navigationTitle("endpoint.edit")
            #if os(iOS)
            .interactiveDismissDisabled()
            .navigationBarTitleDisplayMode(.inline)
            #elseif os(macOS)
            .navigationSubtitle(viewModel.endpoint.name)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        satellite.editingEndpoint = nil
                    } label: {
                        Text("endpoint.edit.cancel")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        Button {
                            viewModel.save()
                        } label: {
                            Text("endpoint.edit.save")
                        }
                        .disabled(!viewModel.isValid)
                    }
                }
            }
        }
        .onAppear {
            viewModel.dismissAction = {    
                satellite.editingEndpoint = nil
            }
        }
    }
}

#if DEBUG
#Preview {
    Text(verbatim: ":)")
        .sheet(isPresented: .constant(true)) {
            EndpointEditView(.fixture)
        }
        .previewEnvironment()
}
#endif
