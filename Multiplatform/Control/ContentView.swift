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
    
    private var image: String {
        if satellite.connectedID != nil {
            return "diamond.fill"
        }
        
        return "diamond"
    }
    
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
            GeometryReader { proxy in
                let width = max(0, proxy.size.width / 2 - 40)
                
                HStack(spacing: 80) {
                    VStack {
                        Spacer()
                        
                        Image(systemName: image)
                            .foregroundStyle(.secondary)
                            .font(.system(size: 500))
                            
                        ConnectedLabel()
                            .opacity(satellite.connectedID == nil ? 0 : 1)
                        
                        Spacer()
                    }
                    .frame(width: width)
                    .ignoresSafeArea()
                    
                    mainContent
                        .frame(width: width)
                }
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
