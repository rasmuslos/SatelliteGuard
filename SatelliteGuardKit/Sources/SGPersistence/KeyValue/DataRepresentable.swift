//
//  DataRepresentable.swift
//  SatelliteGuardKit
//
//  Created by Rasmus Krämer on 05.12.24.
//

import Foundation

extension Date: PersistenceManager.KeyValueSubsystem.DataRepresentable {
    public var data: Data {
        try! JSONEncoder().encode(self)
    }
    public init?(data: Data) {
        guard let date = try? JSONDecoder().decode(Date.self, from: data) else {
            return nil
        }
        
        self.init(timeIntervalSince1970: date.timeIntervalSince1970)
    }
}

extension UUID: PersistenceManager.KeyValueSubsystem.DataRepresentable {
    public var data: Data {
        uuidString.data(using: .utf8)!
    }
    public init?(data: Data) {
        guard let uuidString = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        self.init(uuidString: uuidString)
    }
}

extension String: PersistenceManager.KeyValueSubsystem.DataRepresentable {
    public var data: Data {
        data(using: .utf8)!
    }
    public init?(data: Data) {
        self.init(data: data, encoding: .utf8)
    }
}

extension Array: PersistenceManager.KeyValueSubsystem.DataRepresentable where Element: PersistenceManager.KeyValueSubsystem.DataRepresentable & Codable {
    public var data: Data {
        try! JSONEncoder().encode(self)
    }
    public init?(data: Data) {
        guard let array = try? JSONDecoder().decode([Element].self, from: data) else {
            return nil
        }
        
        self.init(array)
    }
}

