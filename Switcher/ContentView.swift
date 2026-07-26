//
//  ContentView.swift
//  Switcher
//
//  Created by Dallas Brown on 7/5/26.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @State private var folderURL: URL?
    @State private var interval: Double = 3.0
    @State private var playbackSession: PlaybackSessionController?
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            Text("Switcher")
                .font(.largeTitle)
                .bold()

            VStack(spacing: 8) {
                Button("Choose Folder…", action: chooseFolder)

                Text(folderURL?.path ?? "No folder selected")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Stepper(value: $interval, in: 0.5...30, step: 0.5) {
                Text("Interval: \(interval, specifier: "%.1f")s")
            }
            .frame(width: 220)

            Button("Run", action: startPlayback)
                .disabled(folderURL == nil)

            if let errorMessage {
                Text(errorMessage)
                    .font(.callout)
                    .foregroundStyle(.red)
            }
        }
        .padding(40)
        .frame(width: 380)
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Choose a folder of photos or videos"

        errorMessage = nil
        if panel.runModal() == .OK, let url = panel.url {
            folderURL?.stopAccessingSecurityScopedResource()
            _ = url.startAccessingSecurityScopedResource()
            folderURL = url
        }
    }

    private func startPlayback() {
        guard let folderURL else { return }

        let (images, videos) = MediaScanner.scan(folder: folderURL)
        guard !images.isEmpty || !videos.isEmpty else {
            errorMessage = "No photos or videos found in that folder."
            return
        }
        errorMessage = nil

        // One independent slideshow per connected screen; only the main screen's video
        // (if any) plays audio so two video slideshows don't talk over each other.
        let mainScreen = NSScreen.main
        let windowControllers = NSScreen.screens.compactMap { screen -> PlaybackWindowController? in
            guard let viewModel = PlaybackViewModel(images: images, videos: videos, mutesAudio: screen != mainScreen) else {
                return nil
            }
            return PlaybackWindowController(viewModel: viewModel, interval: interval, screen: screen)
        }
        guard !windowControllers.isEmpty else { return }

        let session = PlaybackSessionController(controllers: windowControllers) {
            playbackSession = nil
        }
        playbackSession = session
        session.show()
    }
}

#Preview {
    ContentView()
}
