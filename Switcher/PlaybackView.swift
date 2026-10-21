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
                    VideoPlayerView(player: player, progress: viewModel.progress)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct VideoPlayerView: NSViewRepresentable {
    let player: AVPlayer
    let progress: Double

    func makeNSView(context: Context) -> PlayerLayerView {
        let view = PlayerLayerView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspect
        return view
    }

    func updateNSView(_ nsView: PlayerLayerView, context: Context) {
        nsView.playerLayer.player = player
        nsView.updateProgress(progress)
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
    private static let barHeight: CGFloat = 5

    let playerLayer = AVPlayerLayer()

    /// Red-bordered track spanning the video's displayed width, pinned to its bottom edge.
    private let progressTrackLayer = CALayer()
    /// Solid red fill, grown from the track's left edge to reflect playback progress.
    private let progressFillLayer = CALayer()
    private var currentProgress: Double = 0

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true

        progressTrackLayer.backgroundColor = .clear
        progressTrackLayer.borderColor = NSColor.systemRed.cgColor
        progressTrackLayer.borderWidth = 1
        progressTrackLayer.isHidden = true
        progressTrackLayer.addSublayer(progressFillLayer)
        progressFillLayer.backgroundColor = NSColor.systemRed.cgColor
        playerLayer.addSublayer(progressTrackLayer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func makeBackingLayer() -> CALayer {
        playerLayer
    }

    /// Called on every playback tick (and on player/frame changes) to keep the progress bar's
    /// fill amount and, since `videoRect` shifts with the view's size and the video's aspect
    /// ratio, its position/size in sync with the currently displayed video frame.
    func updateProgress(_ progress: Double) {
        currentProgress = progress
        layoutProgressBar()
    }

    override func layout() {
        super.layout()
        layoutProgressBar()
    }

    private func layoutProgressBar() {
        // `videoRect` is the letterboxed rect within the layer's bounds that the video
        // actually renders into under `.resizeAspect`; using it (instead of the full view
        // bounds) keeps the bar pinned to the video's own edges, not the screen's.
        let videoRect = playerLayer.videoRect

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }

        guard !videoRect.isEmpty else {
            progressTrackLayer.isHidden = true
            return
        }
        progressTrackLayer.isHidden = false
        progressTrackLayer.frame = CGRect(
            x: videoRect.minX,
            y: videoRect.minY,
            width: videoRect.width,
            height: Self.barHeight
        )
        progressFillLayer.frame = CGRect(
            x: 0,
            y: 0,
            width: progressTrackLayer.bounds.width * CGFloat(min(max(currentProgress, 0), 1)),
            height: progressTrackLayer.bounds.height
        )
    }
}
