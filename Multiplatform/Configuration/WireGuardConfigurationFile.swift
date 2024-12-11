//
//  WireGuardConfigurationFile.swift
//  SatelliteGuard
//
//  Created by Rasmus Krämer on 30.11.24.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct WireGuardConfigurationFile: FileDocument {
    let fileName: String?
    let contents: String
    
    static var readableContentTypes: [UTType] {[
        .init(exportedAs: "com.wireguard.config.quick"),
    ]}
    
    init(configuration: ReadConfiguration) throws {
        guard let contents = configuration.file.regularFileContents, let data = String(data: contents, encoding: .utf8) else {
            throw ConfigurationFileError.empty
        }
        
        fileName = configuration.file.filename?.replacing(".conf", with: "")
        self.contents = data
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        throw ConfigurationFileError.unsupported
    }
    
    enum ConfigurationFileError: Error {
        case empty
        case unsupported
    }
}
