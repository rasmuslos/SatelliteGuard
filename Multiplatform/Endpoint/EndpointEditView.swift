//
//  EditEndpointView.swift
//  SatelliteGuard
//
//  Created by Rasmus Krämer on 11.11.24.
//

import Foundation
import SwiftUI
import SatelliteGuardKit

struct EndpointEditView: View {
    @Environment(\.dismiss) private var dismiss
    
    let endpoint: Endpoint
    
    @State private var privateKeyMalformed = false
    
    private var privateKey: Binding<String> {
        .init(get: { endpoint.privateKey.base64EncodedString() }, set: {
            guard let data = Data(base64Encoded: $0), data.count == 32 else {
                privateKeyMalformed = true
                return
            }
            
            privateKeyMalformed = false
            endpoint.privateKey = data
        })
    }
    
    private var isValid: Bool {
        !privateKeyMalformed
    }
    
    var body: some View {
        @Bindable var endpoint = endpoint
        
        NavigationStack {
            List {
                Section {
                    TextField("endpoint.edit.name", text: $endpoint.name)
                    TextField("endpoint.edit.privateKey", text: privateKey)
                } footer: {
                    if privateKeyMalformed {
                        Text("endpoint.edit.key.malformed")
                            .foregroundStyle(.red)
                    }
                }
                
                Section {
                    Toggle("endpoint.edit.disconnectsOnSleep", isOn: $endpoint.disconnectsOnSleep)
                    
                    Toggle("endpoint.edit.excludeAPN", isOn: $endpoint.excludeAPN)
                    Toggle("endpoint.edit.enforceRoutes", isOn: $endpoint.enforceRoutes)
                    Toggle("endpoint.edit.includeAllNetworks", isOn: $endpoint.includeAllNetworks)
                    Toggle("endpoint.edit.excludeCellularServices", isOn: $endpoint.excludeCellularServices)
                    Toggle("endpoint.edit.allowAccessToLocalNetwork", isOn: $endpoint.allowAccessToLocalNetwork)
                    Toggle("endpoint.edit.excludeDeviceCommunication", isOn: $endpoint.excludeDeviceCommunication)
                }
                
                Section {} header: {
                    Text("endpoint.edit.active")
                } footer: {
                    VStack(alignment: .leading) {
                        ForEach(endpoint.active) {
                            Text($0.uuidString)
                        }
                    }
                }
            }
            .navigationTitle("endpoint.edit")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        endpoint.modelContext?.rollback()
                        dismiss()
                    } label: {
                        Text("endpoint.edit.cancel")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        try? endpoint.modelContext?.save()
                        dismiss()
                    } label: {
                        Text("endpoint.edit.save")
                    }
                    .disabled(!isValid)
                }
            }
        }
        .onAppear {
            try? PersistenceManager.shared.modelContainer.mainContext.save()
            PersistenceManager.shared.modelContainer.mainContext.autosaveEnabled = false
        }
        .onDisappear {
            PersistenceManager.shared.modelContainer.mainContext.autosaveEnabled = true
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
