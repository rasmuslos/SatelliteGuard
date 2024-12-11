//
//  SplitScreenView.swift
//  SatelliteGuard
//
//  Created by Rasmus Krämer on 11.12.24.
//

import SwiftUI

@available(iOS, unavailable)
@available(macOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
struct SplitScreenView<Content: View>: View {
    @Environment(Satellite.self) private var satellite
    
    @ViewBuilder var content: Content
    
    @State private var navigationContext: NavigationContextPreferenceKey.NavigationContext = .unknown
    
    static var gap: CGFloat {
        80
    }
    
    private var image: String {
        switch navigationContext {
        case .unknown, .home:
            "satellite.guard"
        case .endpoint(let endpoint):
            if satellite.connectedIDs.contains(endpoint.id) {
                "diamond.fill"
            } else if satellite.activeEndpointIDs.contains(endpoint.id) {
                "diamond.bottomhalf.filled"
            } else {
                "diamond"
            }
        }
    }
    private var dominantStatus: Satellite.VPNStatus {
        if case .endpoint(let endpoint) = navigationContext {
            satellite.status[endpoint.id] ?? .disconnected
        } else {
            satellite.dominantStatus
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = max(0, geometry.size.width / 2) - 40
            
            ZStack(alignment: .topLeading) {
                HStack(spacing: 0) {
                    VStack(spacing: 40) {
                        Spacer(minLength: 0)
                        
                        ZStack {
                            Group {
                                Image("satellite.guard")
                                
                                Image("diamond")
                                Image("diamond.fill")
                                Image("diamond.bottomhalf.filled")
                            }
                            .hidden()
                            
                            Image(image)
                                .foregroundStyle(.secondary)
                                .symbolEffect(.wiggle, value: satellite.notifyError)
                                .symbolEffect(.variableColor.iterative.dimInactiveLayers.reversing, value: satellite.pondering)
                                .contentTransition(.symbolEffect(.replace.byLayer.offUp))
                                .animation(.smooth, value: image)
                        }
                        .font(.system(size: 500))
                        
                        StatusLabel(status: dominantStatus, color: true, indicator: true)
                            .labelStyle(.titleOnly)
                            .opacity(dominantStatus == .disconnected ? 0 : 1)
                            .animation(.smooth, value: dominantStatus)
                        
                        Spacer(minLength: 0)
                    }
                    .frame(width: width)
                    
                    Spacer(minLength: geometry.safeAreaInsets.leading)
                    
                    content
                        .frame(width: width + Self.gap)
                        .offset(x: -Self.gap)
                }
            }
        }
        .onPreferenceChange(NavigationContextPreferenceKey.self) {
            navigationContext = $0
        }
    }
}
