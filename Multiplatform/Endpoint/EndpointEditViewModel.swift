//
//  EndpointEditViewModel.swift
//  SatelliteGuard
//
//  Created by Rasmus Krämer on 12.11.24.
//

import Foundation
import Network
import NetworkExtension
import SwiftUI
import SwiftData
import SatelliteGuardKit

@Observable
final class EndpointEditViewModel {
    var endpoint: Endpoint
    
    @MainActor private(set) var privateKeyMalformed: Bool
    @MainActor private(set) var listenPortMalformed: Bool
    @MainActor private(set) var mtuMalformed: Bool
    
    @MainActor private(set) var isSaving: Bool
    @MainActor var dismissAction: (() -> Void)!
    
    @MainActor private(set) var notifyError: Bool
    @MainActor private(set) var notifySuccess: Bool
    
    @MainActor
    init(endpoint: Endpoint) {
        self.endpoint = endpoint
        
        privateKeyMalformed = false
        listenPortMalformed = false
        mtuMalformed = false
        
        isSaving = false
        
        notifyError = false
        notifySuccess = false
        
        saveMainModelContext()
        PersistenceManager.shared.modelContainer.mainContext.autosaveEnabled = false
    }
    deinit {
        Task { @MainActor in
            PersistenceManager.shared.modelContainer.mainContext.autosaveEnabled = true
        }
    }
    
    @MainActor
    private func saveMainModelContext() {
        do {
            try PersistenceManager.shared.modelContainer.mainContext.save()
        } catch {
            Task {
                try await Task.sleep(nanoseconds: NSEC_PER_SEC / 2)
                await MainActor.run {
                    notifyError.toggle()
                }
            }
        }
    }
}

extension EndpointEditViewModel {
    func save() {
        Task {
            await MainActor.run {
                isSaving = true
            }
            
            await saveMainModelContext()
            try await endpoint.notifySystem()
            await dismissAction()
            
            await MainActor.run {
                isSaving = false
            }
        }
    }
    func dismiss() {
        endpoint.modelContext?.rollback()
    }
    
    @MainActor
    var privateKey: Binding<String> {
        .init() { self.endpoint.privateKey.base64EncodedString() } set: {
            guard let data = Data(base64Encoded: $0), data.count == 32 else {
                self.privateKeyMalformed = true
                return
            }
            
            self.privateKeyMalformed = false
            self.endpoint.privateKey = data
        }
    }
    @MainActor
    var listenPort: Binding<String> {
        .init() {
            if let listenPort = self.endpoint.listenPort {
                return String(listenPort)
            } else {
                return ""
            }
        } set: {
            if $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                self.endpoint.listenPort = nil
                self.listenPortMalformed = false
                
                return
            }
            
            guard let unsignedInteger = UInt16($0) else {
                self.listenPortMalformed = true
                return
            }
            
            self.listenPortMalformed = false
            self.endpoint.listenPort = unsignedInteger
        }
    }
    @MainActor
    var mtu: Binding<String> {
        .init() {
            if let mtu = self.endpoint.mtu {
                return String(mtu)
            } else {
                return ""
            }
        } set: {
            if $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                self.endpoint.mtu = nil
                self.mtuMalformed = false
                
                return
            }
            
            guard let unsignedInteger = UInt16($0) else {
                self.mtuMalformed = true
                return
            }
            
            self.mtuMalformed = false
            self.endpoint.mtu = unsignedInteger
        }
    }
    
    @MainActor
    var isValid: Bool {
        !privateKeyMalformed || !listenPortMalformed || !mtuMalformed
    }
}
