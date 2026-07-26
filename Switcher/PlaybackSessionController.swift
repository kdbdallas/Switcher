//
//  PlaybackSessionController.swift
//  Switcher
//

import AppKit

/// Hardware media-key codes delivered via NSEvent's `.systemDefined` type, subtype 8
/// (NX_SUBTYPE_AUX_CONTROL_BUTTONS). Not part of any public AppKit API.
private enum MediaKeyCode: Int32 {
    case playPause = 16   // NX_KEYTYPE_PLAY
    case next = 17        // NX_KEYTYPE_NEXT
    case previous = 18    // NX_KEYTYPE_PREVIOUS
    case fastForward = 19 // NX_KEYTYPE_FAST
    case rewind = 20      // NX_KEYTYPE_REWIND
}

private let fastForwardRate: Float = 4
private let rewindRate: Float = -4

/// Coordinates one full-screen `PlaybackWindowController` per screen as a single session.
/// Cursor visibility, presentation options, and keyboard shortcuts (Escape to quit, Right
/// Arrow to skip a video, media keys to play/pause/scrub) are applied once for the whole
/// session rather than per window — `NSCursor.hide()`/`unhide()` in particular is a
/// balanced stack, so it must not be called once per screen.
final class PlaybackSessionController {
    private let controllers: [PlaybackWindowController]
    private let onFinish: () -> Void
    private var escapeMonitor: Any?

    init(controllers: [PlaybackWindowController], onFinish: @escaping () -> Void) {
        self.controllers = controllers
        self.onFinish = onFinish
    }

    func show() {
        NSApp.presentationOptions = [.hideDock, .hideMenuBar]
        controllers.forEach { $0.show() }
        NSApp.activate()
        NSCursor.hide()

        escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .systemDefined]) { [weak self] event in
            guard let self else { return event }

            if event.type == .systemDefined {
                return self.handleMediaKey(event)
            }

            if event.keyCode == 53 { // Escape
                self.finish()
                return nil
            }
            if event.keyCode == 124 { // Right Arrow
                for controller in self.controllers where isVideoMode(controller.viewModel.mode) {
                    controller.viewModel.skipToNextVideo()
                }
                return nil
            }
            return event
        }
    }

    /// Applies a hardware media key (play/pause, fast-forward, rewind) to every screen
    /// currently showing video, so the keyboard's media keys control all of them together
    /// instead of whichever single video the system would otherwise pick. Fast-forward and
    /// rewind hold a scrub rate for as long as the key is down rather than issuing repeated
    /// seeks, which under two simultaneous videos could stall one of them mid-seek while
    /// the other kept advancing.
    private func handleMediaKey(_ event: NSEvent) -> NSEvent? {
        guard event.subtype.rawValue == 8, let code = MediaKeyCode(rawValue: Int32((event.data1 & 0xFFFF0000) >> 16)) else {
            return event
        }
        let isKeyDown = ((event.data1 & 0xFF00) >> 8) == 0xA

        let videoViewModels = controllers.map(\.viewModel).filter { isVideoMode($0.mode) }
        guard !videoViewModels.isEmpty else { return event }

        switch code {
        case .playPause:
            if isKeyDown {
                videoViewModels.forEach { $0.togglePlayPause() }
            }
        case .fastForward, .next:
            videoViewModels.forEach { $0.setPlaybackRate(isKeyDown ? fastForwardRate : 1) }
        case .rewind, .previous:
            videoViewModels.forEach { $0.setPlaybackRate(isKeyDown ? rewindRate : 1) }
        }
        return nil
    }

    private func finish() {
        if let escapeMonitor {
            NSEvent.removeMonitor(escapeMonitor)
            self.escapeMonitor = nil
        }
        controllers.forEach { $0.stop() }
        NSCursor.unhide()
        NSApp.presentationOptions = []
        onFinish()
    }
}

private func isVideoMode(_ mode: PlaybackViewModel.Mode) -> Bool {
    if case .video = mode { return true }
    return false
}
