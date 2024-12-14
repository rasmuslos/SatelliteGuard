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
    
    @ViewBuilder private var resetButton: some View {
        Button(role: .destructive) {
            reset()
        } label: {
            Label("reset", systemImage: "exclamationmark.triangle.fill")
                #if os(macOS)
                .labelStyle(.titleOnly)
                #endif
        }
    }
    
    var body: some View {
        switch satellite.authorizationStatus {
        case .none:
            ContentUnavailableView("keyHolder.create.title", systemImage: "inset.filled.center.rectangle.badge.plus", description: Text("keyHolder.create.description"))
            
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
            
            resetButton
        case .missingSecretCreateStrategy, .missingSecretRequestStrategy:
            ContentUnavailableView("keyHolder.authorize.title", systemImage: "person.bust", description: Text(satellite.authorizationStatus == .missingSecretCreateStrategy ? "keyHolder.init.description" : "keyHolder.authorize.description \(PersistenceManager.shared.keyHolder.emojiCode.joined(separator: ""))"))
            
            if loading {
                ProgressView()
            } else {
                if satellite.authorizationStatus == .missingSecretCreateStrategy {
                    Button {
                        createSecret()
                    } label: {
                        Label("keyHolder.init.action", systemImage: "key.2.on.ring")
                            #if os(macOS)
                            .labelStyle(.titleOnly)
                            #endif
                    }
                } else {
                    resetButton
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

#if DEBUG
#Preview {
    KeyHolderAuthorizationView {
        Text(verbatim: "abc")
    }
    .previewEnvironment()
}
#endif
