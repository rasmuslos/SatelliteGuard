//
//  UnauthorizedKeyHolderRow.swift
//  SatelliteGuard
//
//  Created by Rasmus Krämer on 14.12.24.
//

import SwiftUI
import SatelliteGuardKit

struct KeyHolderUnauthorizedRow: View {
    let keyHolder: PersistenceManager.KeyHolderSubsystem.UnauthorizedKeyHolder
    
    @State private var hovered = false
    @State private var alertPresented = false
    
    @ViewBuilder
    private var buttons: some View {
        Button("keyHolder.trust.action") {
            Task {
                await PersistenceManager.shared.keyHolder.trust(keyHolder.id)
            }
            
            alertPresented = false
        }
        .keyboardShortcut(.defaultAction)
        
        Button("keyHolder.trust.deny", role: .destructive) {
            Task {
                await PersistenceManager.shared.keyHolder.deny(keyHolder.id)
            }
            
            alertPresented = false
        }
    }
    
    var body: some View {
        Button {
            alertPresented.toggle()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: keyHolder.operatingSystem.icon)
                    .font(.largeTitle)
                    .foregroundStyle(hovered ? Color.accentColor : .primary)
                
                VStack(alignment: .leading, spacing: 2) {
                        Text("keyHolder.created")
                        + Text(verbatim: " ")
                        + Text(keyHolder.added, style: .date)
                    
                    Text(keyHolder.id.uuidString)
                        .font(.caption2)
                        .fontDesign(.monospaced)
                        .foregroundStyle(.secondary)
                        .contentTransition(.opacity)
                }
                
                Spacer()
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Text(keyHolder.publicKeyVerifier.joined(separator: ""))
            
            Divider()
            
            buttons
        }
        .animation(.smooth, value: hovered)
        .alert("keyHolder.trust.title", isPresented: $alertPresented) {
            buttons
            
            Button("cancel", role: .cancel) {
                alertPresented = false
            }
        } message: {
            Text("keyHolder.trust.message \(keyHolder.publicKeyVerifier.joined(separator: ""))")
        }
        .onHover {
            hovered = $0
        }
    }
}

private extension PersistenceManager.KeyHolderSubsystem.OperatingSystem {
    var icon: String {
        switch self {
        case .iOS:
            "iphone"
        case .tvOS:
            "appletv"
        case .macOS:
            "macstudio"
        }
    }
}
