//
//  IPAddress+Parse.swift
//  SatelliteGuard
//
//  Created by Rasmus Krämer on 10.11.24.
//

import Foundation
import Network

public func parse(ipAddress address: Data) -> IPAddress? {
    IPv4Address(address) ?? IPv6Address(address)
}
public func parse(ipAddress address: String) -> IPAddress? {
    IPv4Address(address) ?? IPv6Address(address)
}

