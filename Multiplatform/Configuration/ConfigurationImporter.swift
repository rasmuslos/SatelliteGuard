//
//  ConfigurationImporter.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 10.11.24.
//

import SwiftUI
import SatelliteGuardKit

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
                    await PersistenceManager.shared.keyHolder.reset()
                }
            } label: {
                Label("reset", systemImage: "square.stack.3d.up.trianglebadge.exclamationmark.fill")
            }
        }
    }
}

@available(tvOS, unavailable)
extension ConfigurationImporter {
    struct ImportButton: View {
        @Environment(Satellite.self) private var satellite
        
        let configuration: FileDocumentConfiguration<WireGuardConfigurationFile>
        
        var body: some View {
            if satellite.importing {
                ProgressView()
            } else {
                Button("configuration.import") {
                    satellite.handleFileImport(configuration.document.contents, name: configuration.document.fileName ?? "Unknown")
                }
                .disabled(satellite.importing)
            }
        }
    }
}

@available(tvOS, unavailable)
extension ConfigurationImporter {
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

#if DEBUG && !os(tvOS)
#Preview {
    ConfigurationImporter()
        .previewEnvironment()
}
#endif
