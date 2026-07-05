//
//  PlaybackView.swift
//  Switcher
//

import SwiftUI
import AVKit

struct PlaybackView: View {
    let viewModel: PlaybackViewModel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch viewModel.mode {
            case .photos:
                if let image = viewModel.currentImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            case .video:
                if let player = viewModel.player {
                    VideoPlayerView(player: player)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct VideoPlayerView: NSViewRepresentable {
    let player: AVPlayer

    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.player = player
        view.controlsStyle = .none
        view.videoGravity = .resizeAspect
        return view
    }

    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        nsView.player = player
    }
}
