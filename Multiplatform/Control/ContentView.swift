//
//  ContentView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 10.11.24.
//

import SwiftUI
import SwiftData
import SatelliteGuardKit

struct ContentView: View {
    @Environment(Satellite.self) private var satellite
    
    static let gap: CGFloat = 60
    
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
            "network.badge.shield.half.filled"
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
                let width = max(0, geometry.size.width / 2)
                
                HStack(spacing: 0) {
                    VStack {
                        Spacer()
                        
                        Image(systemName: image)
                            .foregroundStyle(.secondary)
                            .font(.system(size: 500))
                            .contentTransition(.symbolEffect(.replace.upUp))
                            .animation(.smooth, value: image)
                        
                        ConnectedLabel(indicator: true)
                            .opacity(isConnected ? 1 : 0)
                            .animation(.smooth, value: isConnected)
                        
                        Spacer()
                    }
                    .frame(width: width - Self.gap)
                    .ignoresSafeArea()
                    
                    mainContent
                        .frame(width: width + Self.gap)
                }
            }
            .onPreferenceChange(NavigationContextPreferenceKey.self) {
                navigationContext = $0
            }
            #else
            mainContent
                .sheet(item: $satellite.editingEndpoint) {
                    EndpointEditView(endpoint: $0)
                }
            #endif
        }
        .sheet(isPresented: $satellite.aboutSheetPresented) {
            AboutSheet()
        }
    }
}

#if DEBUG
#Preview {
    ContentView()
        .previewEnvironment()
}
#endif
