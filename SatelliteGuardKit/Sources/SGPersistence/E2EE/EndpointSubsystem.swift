//
//  EndpointManager.swift
//  SatelliteGuardKit
//
//  Created by Rasmus Krämer on 30.11.24.
//

import Foundation
import SwiftData

extension PersistenceManager {
    public final actor EndpointSubsystem: ObservableObject {
        private let context: ModelContext
        
        init() {
            context = ModelContext(shared.modelContainer)
        }
    }
}

public extension PersistenceManager.EndpointSubsystem {
    
}

private extension PersistenceManager.EndpointSubsystem {
    
}
