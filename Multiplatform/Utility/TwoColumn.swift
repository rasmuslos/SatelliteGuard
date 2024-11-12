//
//  TwoColumn.swift
//  SatelliteGuard
//
//  Created by Rasmus Krämer on 11.11.24.
//

import Foundation
import SwiftUI

@available(iOS, unavailable)
@available(macOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
struct TwoColumn<LeadingContent: View, TrailingContent: View>: View {
    @ViewBuilder let leading: () -> LeadingContent
    @ViewBuilder let trailing: () -> TrailingContent
    
    var body: some View {
        GeometryReader { proxy in
            let width = max(0, proxy.size.width / 2 - 40)
            
            HStack(spacing: 80) {
                VStack {
                    Spacer()
                    
                    leading()
                    
                    Spacer()
                }
                .frame(width: width)
                .ignoresSafeArea()
                
                trailing()
                    .frame(width: width)
            }
        }
    }
}
