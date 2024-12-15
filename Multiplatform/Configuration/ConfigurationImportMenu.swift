//
//  ConfigurationImporter.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 10.11.24.
//

import SwiftUI
import SatelliteGuardKit

@available(tvOS, unavailable)
struct ConfigurationImportMenu: View {
    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    #endif

    @Environment(Satellite.self) private var satellite
    
    var body: some View {
        Button {
            #if os(macOS)
            openWindow(id: "import-configuration")
            #endif
            satellite.importPickerVisible.toggle()
        } label: {
            Label("configuration.import", systemImage: "plus")
        }
        .keyboardShortcut("i", modifiers: .command)
        .disabled(satellite.importing)
        
        #if !os(macOS)
        Divider()
        #endif
        
        Link(destination: .init(string: "https://github.com/rasmuslos/SatelliteGuard/blob/main/SECURITY.md")!) {
            Label("security", systemImage: "lock")
        }
        
        Button(role: .destructive) {
            Task {
                try! await PersistenceManager.shared.reset()
            }
        } label: {
            Label("reset", systemImage: "square.stack.3d.up.trianglebadge.exclamationmark.fill")
        }
    }
}

@available(tvOS, unavailable)
extension ConfigurationImportMenu {
    struct ImporterModifier: ViewModifier {
        @Environment(Satellite.self) private var satellite
        
        func body(content: Content) -> some View {
            @Bindable var satellite = satellite
            
            content
                .fileImporter(isPresented: $satellite.importPickerVisible,
                              allowedContentTypes: [.init(exportedAs: "com.wireguard.config.quick")],
                              allowsMultipleSelection: true,
                              onCompletion: satellite.handleFileSelection)
        }
    }
}

