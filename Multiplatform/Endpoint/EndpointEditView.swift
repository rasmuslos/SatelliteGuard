//
//  EditEndpointView.swift
//  SatelliteGuard
//
//  Created by Rasmus Krämer on 11.11.24.
//

import Foundation
import SwiftUI
import SatelliteGuardKit

@available(tvOS, unavailable)
struct EndpointEditView: View {
    @Environment(Satellite.self) private var satellite
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel: EndpointEditViewModel
    
    init(_ endpoint: Endpoint) {
        _viewModel = .init(initialValue: .init(endpoint: endpoint))
    }
    
    var body: some View {
        Text(verbatim: "abc")
    }
}

#if DEBUG
#Preview {
    Text(verbatim: ":)")
        .sheet(isPresented: .constant(true)) {
            EndpointEditView(.fixture)
        }
        .previewEnvironment()
}
#endif
