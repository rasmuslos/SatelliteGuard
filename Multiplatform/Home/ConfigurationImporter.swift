//
//  ConfigurationImporter.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 10.11.24.
//

import SwiftUI

struct ConfigurationImporter: View {
    @Environment(Satellite.self) private var satellite
    
    @State private var pickerPresented = false
    
    var body: some View {
        Button {
            pickerPresented.toggle()
        } label: {
            if satellite.importing {
                ProgressView()
            } else {
                Label("configuration.import", systemImage: "plus")
            }
        }
        .disabled(satellite.importing)
        .fileImporter(isPresented: $pickerPresented, allowedContentTypes: [.init(exportedAs: "com.wireguard.config.quick")], allowsMultipleSelection: true, onCompletion: satellite.handleFileSelection)
    }
}

#Preview {
    ConfigurationImporter()
        .satellite()
}
