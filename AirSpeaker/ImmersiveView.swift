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
    @State var isPlaying: Bool = false

    var body: some View {
        RealityView { content, attachments in
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

                    if let attachment = attachments.entity(for: "speaker_controls") {
                        attachment.position = [0, 0.3, 0]
                        speaker.addChild(attachment, preservingWorldTransform: true)
                    }

                    animation = speaker.availableAnimations[0]
                    audioController = speaker.prepareAudio(audioResource)
                    audioController?.gain = volume

                    animate()
                    content.add(table)
                }
            }
            catch {
                print("Error loading the model")
            }
        } update: { content, attachments in
            animate()
        } attachments: {
            Attachment(id: "speaker_controls") {
                HStack {
                    Toggle(isOn: $isPlaying) {
                        Label("Play", systemImage: isPlaying ? "pause.fill" : "play.fill")
                            .font(.largeTitle)
                            .padding()
                    }
                    .toggleStyle(.button)
                    .buttonStyle(.bordered)
                    .tint(.green)
                    .labelStyle(.iconOnly)
                    .padding()
                    .glassBackgroundEffect(in: Circle())

                    Slider(value: $volume, in: (-60.0)...(0.0))
                        .tint(.green)
                        .frame(maxWidth: 200)
                        .onChange(of: volume) { _, newValue in
                            let vol = Audio.Decibel(floatLiteral: newValue)
                            if let audioController, audioController.isPlaying {
                                audioController.fade(to: vol, duration: 0)
                            }
                        }
                }

            }
        }
        .gesture(dragGesture)
    }

    private var dragGesture: some Gesture {
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

    private func animate() {
        guard let speaker, let animation, let audioController else { return }

        if isPlaying {
            speaker.playAnimation(animation.repeat())
            audioController.play()
        } else {
            speaker.stopAllAnimations()
            audioController.stop()
        }
    }
}

#Preview {
    ImmersiveView()
        .previewLayout(.sizeThatFits)
}
