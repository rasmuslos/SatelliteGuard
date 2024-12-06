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

@available(tvOS, unavailable)
extension ConfigurationImporter {
    struct ImportButton: View {
        @Environment(Satellite.self) private var satellite
        
        let configuration: FileDocumentConfiguration<WireGuardConfigurationFile>
        
        @State private var importFired = 0
        
        var body: some View {
            Group {
                switch importFired {
                case 0:
                    Button("configuration.import") {
                        satellite.handleFileImport(configuration.document.contents, name: configuration.document.fileName ?? "Unknown")
                    }
                    .disabled(importFired != 0)
                case 1:
                    ProgressView()
                default:
                    Text("import.success")
                }
            }
            .onChange(of: satellite.importing) {
                importFired += 1
            }
        }
    }
}

#if DEBUG && !os(tvOS)
#Preview {
    ConfigurationImporter()
        .previewEnvironment()
}
#endif
