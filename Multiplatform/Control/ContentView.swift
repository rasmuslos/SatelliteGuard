//
//  ContentView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 10.11.24.
//

import SwiftUI
import SwiftData
import SatelliteGuardKit

@available(macOS, unavailable)
struct ContentView: View {
    @Environment(Satellite.self) private var satellite
    
    static let gap: CGFloat = 80
    
    #if os(tvOS)
    @State private var navigationContext: NavigationContextPreferenceKey.NavigationContext = .unknown
    
    private var isConnected: Bool {
        if case .endpoint(let endpoint) = navigationContext {
            return satellite.connectedID == endpoint.id
        }
        
        return satellite.connectedID != nil
    }
    
    private var image: String {
        switch navigationContext {
        case .unknown, .home:
            "satellite.guard"
        case .endpoint(let endpoint):
            if !endpoint.isActive {
                "diamond"
            } else if satellite.connectedID == endpoint.id {
                "diamond.fill"
            } else {
                "diamond.bottomhalf.filled"
            }
        }
    }
    #endif
    
    @ViewBuilder
    private var mainContent: some View {
        NavigationStack {
            HomeView()
        }
    }
    
    var body: some View {
        @Bindable var satellite = satellite
        
        Group {
            #if os(tvOS)
            GeometryReader { geometry in
                let width = max(0, geometry.size.width / 2) - 40
                
                ZStack(alignment: .topLeading) {
                    #if DEBUG
                    HStack(spacing: geometry.safeAreaInsets.leading) {
                        Rectangle()
                            .fill(.red)
                        Rectangle()
                            .fill(.blue)
                    }
                    .frame(width: geometry.size.width)
                    #endif
                    
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
                            
                            StatusLabel(color: true, indicator: true)
                                .opacity(isConnected ? 1 : 0)
                                .animation(.smooth, value: isConnected)
                            
                            Spacer(minLength: 0)
                        }
                        .frame(width: width)
                        
                        Spacer(minLength: geometry.safeAreaInsets.leading)
                        
                        mainContent
                            .frame(width: width + Self.gap)
                            .offset(x: -Self.gap)
                    }
                }
            }
            .onPreferenceChange(NavigationContextPreferenceKey.self) {
                navigationContext = $0
            }
            #else
            mainContent
                .sheet(item: $satellite.editingEndpoint) {
                    EndpointEditView($0)
                }
            #endif
        }
    }
}

#if DEBUG && !os(macOS)
#Preview {
    ContentView()
        .previewEnvironment()
}
#endif
