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
    @State var isDragging = false
    @State var dragStartPosition: SIMD3<Float> = .zero
    @State var animation: AnimationResource? = nil
    @State var audioController: AudioPlaybackController?
    @State var volume: Double = -30.0

    var body: some View {
        RealityView { content in
            do {
                speaker = try await ModelEntity(named: "jbl_charge")
                let environment = try await EnvironmentResource(named: "studio")
                let audioResource = try AudioFileResource.load(named: "calming.wav", in: nil, configuration: .init(loadingStrategy: .preload, shouldLoop: true))

                if let speaker {
                    let table = {
                        let anchor = AnchorEntity(.plane(.horizontal, classification: .table, minimumBounds: [0.5, 0.5]))
                        anchor.addChild(speaker, preservingWorldTransform: true)
                        return anchor
                    }()

                    speaker.scale = [0.00075, 0.00075, 0.00075]

                    speaker.components.set(ImageBasedLightComponent(source: .single(environment)))
                    speaker.components.set(ImageBasedLightReceiverComponent(imageBasedLight: speaker))

                    let speakerBounds = speaker.model!.mesh.bounds.extents
                    speaker.components.set(CollisionComponent(shapes: [.generateBox(size: speakerBounds)]))
                    speaker.components.set(InputTargetComponent())
                    speaker.components.set(GroundingShadowComponent(castsShadow: true))

                    animation = speaker.availableAnimations[0]
                    audioController = speaker.prepareAudio(audioResource)
                    audioController?.gain = volume

                    if let animation {
                        speaker.playAnimation(animation.repeat())
                    }
                    audioController?.play()

                    content.add(table)
                }
            }
            catch {
                print("Error loading the model")
            }
        }
        .gesture(dragGesture)
    }

    var dragGesture: some Gesture {
        DragGesture()
            .targetedToAnyEntity()
            .onChanged { value in
                let entity = value.entity

                if !isDragging {
                    isDragging = true
                    dragStartPosition = entity.position(relativeTo: nil)
                }

                let translation3D = value.convert(value.gestureValue.translation3D, from: .local, to: .scene)
                let offset = SIMD3<Float>(x: Float(translation3D.x),
                                          y: Float(translation3D.y),
                                          z: Float(translation3D.z))

                entity.setPosition(dragStartPosition + offset, relativeTo: nil)
            }
            .onEnded {_ in 
                isDragging = false
                dragStartPosition = .zero
            }
    }
}

#Preview {
    ImmersiveView()
        .previewLayout(.sizeThatFits)
}
