//
//  PlaybackViewModel.swift
//  Switcher
//

import AppKit
import AVFoundation
import Observation

@Observable
final class PlaybackViewModel {
    enum Mode {
        case photos([URL])
        case video([URL])
    }

    var currentImage: NSImage?
    var player: AVPlayer?

    let mode: Mode

    private var timer: Timer?
    private var lastImageIndex: Int?
    private var endObserver: NSObjectProtocol?

    init?(images: [URL], videos: [URL]) {
        if !images.isEmpty {
            mode = .photos(images)
        } else if !videos.isEmpty {
            mode = .video(videos)
        } else {
            return nil
        }
    }

    func start(interval: TimeInterval) {
        switch mode {
        case .photos(let urls):
            showRandomImage(from: urls)
            timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                self?.showRandomImage(from: urls)
            }
        case .video(let urls):
            playRandomVideo(from: urls)
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
        player?.pause()
        player = nil
    }

    private func showRandomImage(from urls: [URL]) {
        guard !urls.isEmpty else { return }
        var index = Int.random(in: 0..<urls.count)
        if urls.count > 1 {
            while index == lastImageIndex {
                index = Int.random(in: 0..<urls.count)
            }
        }
        lastImageIndex = index
        currentImage = NSImage(contentsOf: urls[index])
    }

    private func playRandomVideo(from urls: [URL]) {
        guard let url = urls.randomElement() else { return }
        let item = AVPlayerItem(url: url)

        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.playRandomVideo(from: urls)
        }

        if let player {
            player.replaceCurrentItem(with: item)
        } else {
            player = AVPlayer(playerItem: item)
        }
        player?.play()
    }
}
