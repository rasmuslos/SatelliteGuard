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
    
    var body: some View {
        Menu {
            Inner()
        } label: {
            if satellite.importing {
                ProgressView()
            } else {
                Label("configuration.import", systemImage: "plus")
            }
        }
    }
}

@available(tvOS, unavailable)
extension ConfigurationImporter {
    struct Inner: View {
        @Environment(Satellite.self) private var satellite
        
        @State private var pickerPresented = false
        
        var body: some View {
            Button {
                pickerPresented.toggle()
            } label: {
                Label("configuration.import", systemImage: "plus")
            }
            .keyboardShortcut("i", modifiers: .command)
            .disabled(satellite.importing)
            .fileImporter(isPresented: $pickerPresented, allowedContentTypes: [.init(exportedAs: "com.wireguard.config.quick")], allowsMultipleSelection: true, onCompletion: satellite.handleFileSelection)
            
            #if !os(macOS)
            Divider()
            #endif
            
            Link(destination: .init(string: "https://github.com/rasmuslos/SatelliteGuard/blob/main/SECURITY.md")!) {
                Label("security", systemImage: "lock")
            }
            
            #if !os(macOS)
            Button {
                satellite.aboutSheetPresented.toggle()
            } label: {
                Label("about", systemImage: "key.viewfinder")
            }
            #endif
        }
    }
}

#if DEBUG && !os(tvOS)
#Preview {
    ConfigurationImporter()
        .previewEnvironment()
}
#endif
