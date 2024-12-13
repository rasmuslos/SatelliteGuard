//
//  KeyHolderAuthorizationView.swift
//  SatelliteGuard
//
//  Created by Rasmus Krämer on 11.12.24.
//

import SwiftUI
import SatelliteGuardKit

struct KeyHolderAuthorizationView<Content: View>: View {
    @Environment(Satellite.self) private var satellite
    
    @ViewBuilder var content: Content
    
    @State private var loading = false
    
    var body: some View {
        switch satellite.authorizationStatus {
        case .none:
            ContentUnavailableView {
                Text("keyHolder.create.title")
                    .bold()
            } description: {
                Text("keyHolder.create.description")
            }
            
            if loading {
                ProgressView()
            } else {
                Button {
                    createKeyHolder()
                } label: {
                    Label("keyHolder.create.action", systemImage: "plus")
                        #if os(macOS)
                        .labelStyle(.titleOnly)
                        #endif
                }
            }
        case .establishing:
            ProgressView()
        case .establishingFailed:
            Image(systemName: "exclamationmark.triangle.fill")
        case .missingSecretCreateStrategy, .missingSecretRequestStrategy:
            ContentUnavailableView {
                Text("keyHolder.authorize.title")
                    .bold()
            } description: {
                Text("keyHolder.authorize.description")
            }
            
            if loading {
                ProgressView()
            } else {
                if satellite.authorizationStatus == .missingSecretCreateStrategy {
                    Button(role: .destructive) {
                        createSecret()
                    } label: {
                        Label("keyHolder.init.action", systemImage: "key.2.on.ring")
                            #if os(macOS)
                            .labelStyle(.titleOnly)
                            #endif
                    }
                } else {
                    Button(role: .destructive) {
                        reset()
                    } label: {
                        Label("keyHolder.reset.action", systemImage: "exclamationmark.triangle.fill")
                            #if os(macOS)
                            .labelStyle(.titleOnly)
                            #endif
                    }
                }
            }
        case .authorized:
            content
        }
    }
    
    private func reset() {
        Task {
            loading = true
            await PersistenceManager.shared.keyHolder.reset()
            loading = false
        }
    }
    private func createKeyHolder() {
        Task {
            loading = true
            await PersistenceManager.shared.keyHolder.createKeyHolder()
            loading = false
        }
    }
    private func createSecret() {
        Task {
            loading = true
            await PersistenceManager.shared.keyHolder.createSecret()
            loading = false
        }
    }
}
