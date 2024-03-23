//
//  ImmersiveView.swift
//  AirSpeaker
//
//  Created by Vina Melody on 25/2/24.
//

import SwiftUI
import RealityKit

struct ImmersiveView: View {

    @State var speaker: ModelEntity? = nil

    var body: some View {
        RealityView { content in
            do {
                speaker = try await ModelEntity(named: "jbl_charge")

                if let speaker {
                    content.add(speaker)
                }
            }
            catch {
                print("Error loading the model")
            }
        }
    }
}

#Preview {
    ImmersiveView()
        .previewLayout(.sizeThatFits)
}
