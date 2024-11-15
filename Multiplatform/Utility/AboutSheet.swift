//
//  SettingsView.swift
//  SatelliteGuard
//
//  Created by Rasmus Krämer on 13.11.24.
//

import Foundation
import SwiftUI
import SatelliteGuardKit

struct AboutSheet: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("about.wireGuard \(WireGuardConnection.wireGuardVersion)")
                    
                    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                       let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                        Text("about.satelliteGuard \(version) \(build)")
                    }
                }
                
                Section {
                    Link(destination: .init(string: "https://github.com/rasmuslos/ShelfPlayer")!) {
                        Label("about.gitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                }
            }
            .navigationTitle("about.title")
            #if !os(tvOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
}

#Preview {
    AboutSheet()
}
