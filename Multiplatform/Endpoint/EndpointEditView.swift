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
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel: EndpointEditViewModel
    
    init(endpoint: Endpoint) {
        _viewModel = .init(initialValue: .init(endpoint: endpoint))
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("endpoint.edit.name", text: $viewModel.endpoint.name)
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
                    Toggle("endpoint.edit.disconnectsOnSleep", isOn: $viewModel.endpoint.disconnectsOnSleep)
                    
                    Toggle("endpoint.edit.excludeAPN", isOn: $viewModel.endpoint.excludeAPN)
                    Toggle("endpoint.edit.enforceRoutes", isOn: $viewModel.endpoint.enforceRoutes)
                    Toggle("endpoint.edit.includeAllNetworks", isOn: $viewModel.endpoint.includeAllNetworks)
                    Toggle("endpoint.edit.excludeCellularServices", isOn: $viewModel.endpoint.excludeCellularServices)
                    Toggle("endpoint.edit.allowAccessToLocalNetwork", isOn: $viewModel.endpoint.allowAccessToLocalNetwork)
                    Toggle("endpoint.edit.excludeDeviceCommunication", isOn: $viewModel.endpoint.excludeDeviceCommunication)
                } footer: {
                    Text("endpoint.edit.appleTVDisclaimer")
                }
                
                Section {} header: {
                    Text("endpoint.edit.active")
                } footer: {
                    VStack(alignment: .leading) {
                        ForEach(viewModel.endpoint.active) {
                            Text($0.uuidString)
                        }
                    }
                }
            }
            .navigationTitle("endpoint.edit")
            .interactiveDismissDisabled()
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("endpoint.edit.cancel")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
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
            #endif
        }
        .onAppear {
            viewModel.dismissAction = dismiss
        }
    }
}

#if DEBUG
#Preview {
    Text(verbatim: ":)")
        .sheet(isPresented: .constant(true)) {
            EndpointEditView(endpoint: .fixture)
        }
        .previewEnvironment()
}
#endif
