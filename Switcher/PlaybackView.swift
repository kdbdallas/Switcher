//
//  PlaybackView.swift
//  Switcher
//

import SwiftUI
import AVFoundation

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

    func makeNSView(context: Context) -> PlayerLayerView {
        let view = PlayerLayerView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspect
        return view
    }

    func updateNSView(_ nsView: PlayerLayerView, context: Context) {
        nsView.playerLayer.player = player
    }
}

/// Hosts a bare `AVPlayerLayer` instead of AVKit's `AVPlayerView`. `AVPlayerView`
/// auto-registers with the system's Now Playing / media-key routing regardless of its
/// `updatesNowPlayingInfoCenter` flag (that only controls displayed metadata, not command
/// routing) — with two screens each playing an independent video, that leaves one of them
/// stuck responding to AVKit's own hold-to-seek gesture (which pauses during the hold and
/// resumes on release) instead of `PlaybackSessionController`'s media-key handling. A plain
/// `AVPlayerLayer` has no such integration.
private final class PlayerLayerView: NSView {
    let playerLayer = AVPlayerLayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func makeBackingLayer() -> CALayer {
        playerLayer
    }
}
