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
    var endpoint: Endpoint
    
    @MainActor var pondering: Bool
    
    @MainActor var notifyError: Bool
    @MainActor var notifySuccess: Bool
    
    @MainActor
    init(endpoint: Endpoint) {
        self.endpoint = endpoint
        
        pondering = false
        
        notifyError = false
        notifySuccess = false
    }
    
    // May I present: Thread Safe, Concurrent Swift 6 code
    // If any goofballs comments, that i could mark this view model
    // as @MainActor: No, it would defeat the entire point. Then the
    // main actor would be blocked waiting for said async (long) operation
    // this here spawns a new task somewhere and blocks nothing
    
    func activate() {
        Task {
            await MainActor.withAnimation {
                self.pondering = true
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
                self.pondering = false
            }
        }
    }
    
    func deactivate() {
        Task {
            await MainActor.withAnimation {
                self.pondering = true
            }
            
            do {
                try await endpoint.deactivate()
                
                await MainActor.withAnimation {
                    self.notifySuccess.toggle()
                }
            } catch {
                await MainActor.withAnimation {
                    self.notifyError.toggle()
                }
            }
            
            await MainActor.withAnimation {
                self.pondering = false
            }
        }
    }
}
