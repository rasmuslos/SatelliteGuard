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
                .labelStyle(.titleOnly)
        }
    }
    @ViewBuilder private var updateButton: some View {
        if loading {
            ProgressView()
        } else {
            Button {
                update()
            } label: {
                Text("update")
            }
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
                }
            }
        case .establishing:
            ProgressView()
            
            updateButton
        case .establishingFailed:
            ContentUnavailableView("keyHolder.fault.title", systemImage: "exclamationmark.triangle.fill", description: Text("keyHolder.fault.description"))
            
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
                    }
                } else {
                    updateButton
                        .buttonStyle(.borderedProminent)
                        .padding(.bottom, 8)
                    
                    resetButton
                        .buttonStyle(.bordered)
                }
            }
        case .authorized:
            content
        }
    }
    
    private func update() {
        Task {
            loading = true
            await PersistenceManager.shared.update()
            loading = false
        }
    }
    
    private func reset() {
        Task {
            loading = true
            try! await PersistenceManager.shared.reset()
            loading = false
        }
    }
    private func createKeyHolder() {
        Task {
            loading = true
            try! await PersistenceManager.shared.keyHolder.createKeyHolder()
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
