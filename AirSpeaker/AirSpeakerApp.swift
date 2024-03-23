//
//  AirSpeakerApp.swift
//  AirSpeaker
//
//  Created by Vina Melody on 25/2/24.
//

import SwiftUI

@main
struct AirSpeakerApp: App {

    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    
    var body: some Scene {
        WindowGroup {
            EmptyView()
                .persistentSystemOverlays(.hidden)
                .task {
                    await openImmersiveSpace(id: "ImmersiveSpace")
                }
        }
        .windowStyle(.volumetric)

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }
    }
}
