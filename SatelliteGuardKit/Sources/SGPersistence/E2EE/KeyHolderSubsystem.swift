//
//  KeyHolderManager.swift
//  SatelliteGuardKit
//
//  Created by Rasmus Krämer on 01.12.24.
//

import Foundation
import SwiftData
import Combine

extension PersistenceManager {
    public final actor KeyHolderSubsystem: ObservableObject {
        public typealias UpdatePayload = (joined: Bool, activeIDs: [UUID])
        
        private static var _deviceID: UUID?
        private var keyHolders: [KeyHolder] {
            didSet {
                updatePublisher.send((current != nil, activeIDs))
            }
        }
        
        private let updatePublisher: PassthroughSubject<UpdatePayload, Never>
        
        private let context: ModelContext
        
        init() {
            context = ModelContext(shared.modelContainer)
            keyHolders = .init(try! context.fetch(FetchDescriptor<KeyHolder>()))
            
            updatePublisher = .init()
        }
    }
}

public extension PersistenceManager.KeyHolderSubsystem {
    var didUpdate: AnyPublisher<UpdatePayload, Never> {
        updatePublisher.eraseToAnyPublisher()
    }
    
    var isVaultSetup: Bool {
        for keyHolder in self.keyHolders {
            if keyHolder.sharedKey != nil {
                return true
            }
        }
        
        return false
    }
    
    nonisolated var deviceID: UUID {
        if let _deviceID = Self._deviceID {
            return _deviceID
        }
        
        if let deviceID = UserDefaults.standard.string(forKey: "deviceID") {
            Self._deviceID = UUID(uuidString: deviceID)!
        } else {
            Self._deviceID = .init()
            UserDefaults.standard.set(Self._deviceID?.uuidString, forKey: "deviceID")
        }
        
        return Self._deviceID!
    }
    
    var activeIDs: [UUID] {
        keyHolders.first { $0.id == deviceID }?.activeEndpointIDs ?? []
    }
    
    func joinVault() {
        guard !keyHolders.contains(where: { $0.id == deviceID }) else {
            return
        }
        
        if keyHolders.isEmpty {
            Task {
                await PersistenceManager.shared.keyValue.set(.vaultSetup, .now)
                await PersistenceManager.shared.keyValue.set(.vaultInitialDeviceID, deviceID)
            }
        }
        
        context.insert(KeyHolder())
        try! context.save()
    }
    
    func activate(_ id: Endpoint.ID) throws {
        if !current.activeEndpointIDs.contains(id) {
            current.activeEndpointIDs.append(id)
            try context.save()
        }
    }
    func deactivate(_ id: Endpoint.ID) throws {
        current.activeEndpointIDs.removeAll { $0 == id }
        try context.save()
    }
    
    subscript(id: Endpoint.ID) -> Bool {
        current.activeEndpointIDs.contains(id)
    }
}

private extension PersistenceManager.KeyHolderSubsystem {
    var current: KeyHolder! {
        keyHolders.first { $0.id == deviceID }
    }
    
    func updateKeyHolders(_ keyHolders: [KeyHolder]) {
        self.keyHolders = keyHolders
    }
    
    func setupObservers() {
        NotificationCenter.default.addObserver(forName: ModelContext.didSave, object: nil, queue: nil) { _ in
            print("abc")
        }
    }
}
