//
//  ConfigurationImporter.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 10.11.24.
//

import SwiftUI

@available(tvOS, unavailable)
struct ConfigurationImporter: View {
    @Environment(Satellite.self) private var satellite
    
    @State private var pickerPresented = false
    
    var body: some View {
        Menu {
            Button {
                pickerPresented.toggle()
            } label: {
                Label("configuration.import", systemImage: "plus")
            }
            
            Divider()
            
            Link(destination: .init(string: "https://github.com/rasmuslos/SatelliteGuard/blob/main/SECURITY.md")!) {
                Label("security", systemImage: "lock")
            }
            Button {
                satellite.aboutSheetPresented.toggle()
            } label: {
                Label("about", systemImage: "key.viewfinder")
            }
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

#if DEBUG && !os(tvOS)
#Preview {
    ConfigurationImporter()
        .previewEnvironment()
}
#endif
