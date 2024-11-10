//
//  EndpointViewModel.swift
//  SatelliteGuard
//
//  Created by Rasmus Krämer on 11.11.24.
//

import Foundation
import Network
import NetworkExtension
import SwiftUI
import SwiftData
import SatelliteGuardKit

@Observable
class EndpointViewModel {
    let endpoint: Endpoint
    
    @MainActor var activating: Bool
    
    @MainActor var notifyError: Bool
    @MainActor var notifySuccess: Bool
    
    @MainActor
    init(endpoint: Endpoint) {
        self.endpoint = endpoint
        
        activating = false
        
        notifyError = false
        notifySuccess = false
    }
    
    func activate() {
        Task {
            await MainActor.withAnimation {
                self.activating = true
            }
            
            do {
                try await endpoint.notifySystem()
                
                await MainActor.withAnimation {
                    self.notifySuccess.toggle()
                }
            } catch {
                await MainActor.withAnimation {
                    self.notifyError.toggle()
                }
            }
            
            await MainActor.withAnimation {
                self.activating = false
            }
        }
    }
}
