//
//  PlaybackWindowController.swift
//  Switcher
//

import AppKit
import SwiftUI

/// Borderless window that can still become key so it receives the Escape key press.
private final class FullScreenWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// Displays one slideshow full-screen on a single screen. Owns only its own window and
/// view model; app-wide concerns shared across screens (cursor visibility, presentation
/// options, key handling) are coordinated by `PlaybackSessionController`.
final class PlaybackWindowController: NSWindowController {
    let viewModel: PlaybackViewModel
    private let interval: TimeInterval

    init(viewModel: PlaybackViewModel, interval: TimeInterval, screen: NSScreen) {
        self.viewModel = viewModel
        self.interval = interval

        // Deliberately not passing `screen:` here: on a multi-screen setup where a
        // secondary screen has a negative origin and a different backingScaleFactor than
        // the main screen, NSWindow's screen-aware initializer miscomputes the origin
        // (scaling it by the secondary screen's backing scale), placing the window in the
        // wrong spot. Creating the window screen-agnostic and positioning it explicitly
        // with setFrame avoids that.
        let window = FullScreenWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.setFrame(screen.frame, display: true)
        window.level = .screenSaver
        window.backgroundColor = .black
        window.isOpaque = true
        window.hasShadow = false
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: PlaybackView(viewModel: viewModel))

        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        window?.makeKeyAndOrderFront(nil)
        viewModel.start(interval: interval)
    }

    func stop() {
        viewModel.stop()
        window?.close()
    }
}
