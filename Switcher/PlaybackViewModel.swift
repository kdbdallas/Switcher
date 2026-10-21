//
//  PlaybackViewModel.swift
//  Switcher
//

import AppKit
import AVFoundation
import IOKit.pwr_mgt
import Observation

@Observable
final class PlaybackViewModel {
    enum Mode {
        case photos([URL])
        case video([URL])
    }

    var currentImage: NSImage?
    var player: AVPlayer?

    /// Current video's playback position as a fraction of its duration (0...1). Reset to 0
    /// whenever a new video starts. Unused in `.photos` mode.
    var progress: Double = 0

    let mode: Mode

    private var timer: Timer?
    private var lastImageIndex: Int?
    private var endObserver: NSObjectProtocol?
    private var timeObserverToken: Any?
    private var videoQueue: [URL] = []
    private var lastVideoURL: URL?
    private var sleepAssertionID: IOPMAssertionID = 0
    private var sleepAssertionActive = false
    private let mutesAudio: Bool

    init?(images: [URL], videos: [URL], mutesAudio: Bool) {
        self.mutesAudio = mutesAudio
        if !images.isEmpty {
            mode = .photos(images)
        } else if !videos.isEmpty {
            mode = .video(videos)
        } else {
            return nil
        }
    }

    deinit {
        disableScreenSaver()
    }

    func start(interval: TimeInterval) {
        preventScreenSaver()
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
        if let timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
        player?.pause()
        player = nil
        videoQueue.removeAll()
        lastVideoURL = nil
        progress = 0
        disableScreenSaver()
    }

    /// Prevents the system screen saver and display sleep from activating while media is playing.
    private func preventScreenSaver() {
        guard !sleepAssertionActive else { return }
        let reason = "Switcher is playing back photos or videos" as CFString
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &sleepAssertionID
        )
        sleepAssertionActive = result == kIOReturnSuccess
    }

    /// Restores normal screen saver / display sleep behavior.
    private func disableScreenSaver() {
        guard sleepAssertionActive else { return }
        IOPMAssertionRelease(sleepAssertionID)
        sleepAssertionActive = false
    }

    /// Skips the currently playing video and immediately advances to another random one.
    func skipToNextVideo() {
        guard case .video(let urls) = mode else { return }
        playRandomVideo(from: urls)
    }

    func togglePlayPause() {
        guard let player else { return }
        if player.timeControlStatus == .paused {
            player.play()
        } else {
            player.pause()
        }
    }

    /// Plays the current video at `rate` (> 1 fast-forwards, < 0 reverses, 1 is normal
    /// speed). Used for hardware media keys, which hold this while pressed and restore
    /// normal speed on release. Rate-based scrubbing plays continuously forward/backward
    /// rather than issuing repeated seeks, which under two simultaneous videos can stall
    /// one of them searching for keyframes while the key is held.
    func setPlaybackRate(_ rate: Float) {
        guard let player, let item = player.currentItem else { return }
        if rate < 0, !item.canPlayReverse { return }
        if rate > 1, !item.canPlayFastForward { return }
        player.rate = rate
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

    /// Returns the next video in randomized, non-repeating order. All videos are played once
    /// (in shuffled order) before any video repeats, and a run boundary never immediately
    /// replays the video that just finished.
    private func nextVideoURL(from urls: [URL]) -> URL? {
        guard !urls.isEmpty else { return nil }

        if videoQueue.isEmpty {
            videoQueue = urls.shuffled()
            if urls.count > 1, videoQueue.first == lastVideoURL {
                videoQueue.append(videoQueue.removeFirst())
            }
        }

        let next = videoQueue.removeFirst()
        lastVideoURL = next
        return next
    }

    private func playRandomVideo(from urls: [URL]) {
        guard let url = nextVideoURL(from: urls) else { return }
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

        progress = 0

        if let player {
            player.replaceCurrentItem(with: item)
        } else {
            player = AVPlayer(playerItem: item)
            player?.isMuted = mutesAudio
            addTimeObserver()
        }
        player?.play()
    }

    /// Installed once on the player (which is reused across videos via `replaceCurrentItem`)
    /// to keep `progress` in sync with `currentItem`'s playback position and duration.
    private func addTimeObserver() {
        let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.updateProgress(currentTime: time)
        }
    }

    private func updateProgress(currentTime: CMTime) {
        guard let duration = player?.currentItem?.duration, duration.isNumeric, duration.seconds > 0 else {
            return
        }
        progress = min(max(currentTime.seconds / duration.seconds, 0), 1)
    }
}
