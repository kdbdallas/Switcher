//
//  MediaScanner.swift
//  Switcher
//

import Foundation
import UniformTypeIdentifiers

enum MediaScanner {
    static func scan(folder: URL) -> (images: [URL], videos: [URL]) {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return ([], [])
        }

        var images: [URL] = []
        var videos: [URL] = []

        for url in contents {
            guard let type = UTType(filenameExtension: url.pathExtension) else { continue }
            if type.conforms(to: .image) {
                images.append(url)
            } else if type.conforms(to: .movie) {
                videos.append(url)
            }
        }

        return (images, videos)
    }
}
