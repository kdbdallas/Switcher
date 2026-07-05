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

final class PlaybackWindowController: NSWindowController {
    private let viewModel: PlaybackViewModel
    private let interval: TimeInterval
    private let onFinish: () -> Void
    private var escapeMonitor: Any?

    init(viewModel: PlaybackViewModel, interval: TimeInterval, screen: NSScreen, onFinish: @escaping () -> Void) {
        self.viewModel = viewModel
        self.interval = interval
        self.onFinish = onFinish

        let window = FullScreenWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
            screen: screen
        )
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
        guard let window else { return }
        NSApp.presentationOptions = [.hideDock, .hideMenuBar]
        window.makeKeyAndOrderFront(nil)
        NSApp.activate()
        NSCursor.hide()
        viewModel.start(interval: interval)

        escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            if event.keyCode == 53 { // Escape
                self.finish()
                return nil
            }
            return event
        }
    }

    private func finish() {
        if let escapeMonitor {
            NSEvent.removeMonitor(escapeMonitor)
            self.escapeMonitor = nil
        }
        viewModel.stop()
        NSCursor.unhide()
        NSApp.presentationOptions = []
        window?.close()
        onFinish()
    }
}
