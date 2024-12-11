//
//  VaultView.swift
//  SatelliteGuard
//
//  Created by Rasmus Krämer on 11.12.24.
//

import SwiftUI
import SatelliteGuardKit

struct VaultView<Content: View>: View {
    @Environment(Satellite.self) private var satellite
    
    @ViewBuilder var content: Content
    
    var body: some View {
        if satellite.authorized {
            content
        } else if satellite.didJoinVault {
            ContentUnavailableView {
                Text("vault.authorize.title")
                    .bold()
            } description: {
                Text("vault.authorize.description")
            }
        } else {
            ContentUnavailableView {
                Text("vault.join.title")
                    .bold()
            } description: {
                Text("vault.join.description")
            }
            
            Button {
                Task {
                    await PersistenceManager.shared.keyHolder.joinVault()
                }
            } label: {
                Label("vault.join.action", systemImage: "plus")
                #if os(macOS)
                    .labelStyle(.titleOnly)
                #endif
            }
        }
    }
}
