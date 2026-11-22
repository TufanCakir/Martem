//
//  MusicPlayer.swift
//  Martem
//
//  Created by Tufan Cakir on 21.11.26.
//

import AVFoundation
import Foundation

@MainActor
final class MusicPlayer {
    private var playingVersion: Int?
    private var player: AVPlayer?
    private var endObserver: NSObjectProtocol?
    private var urls: [URL] = []
    private var currentIndex = 0
    private var enabled =
        UserDefaults.standard.object(forKey: "musicEnabled") as? Bool ?? true
    private var volume =
        UserDefaults.standard.object(forKey: "musicVolume") as? Double ?? 0.7

    func updateSettings(enabled: Bool, volume: Double) {
        self.enabled = enabled
        self.volume = min(max(volume, 0), 1)
        player?.volume = enabled ? Float(self.volume) : 0
    }

    func playBattle(_ filenames: [String], version: Int) {
        if player != nil, playingVersion == version {
            return
        }

        stop()

        guard let base = RemoteConfig.load()?.musicBaseURL,
            base.scheme?.lowercased() == "https"
        else { return }

        urls = filenames.compactMap { filename in
            guard !filename.isEmpty,
                let url = URL(
                    string: filename,
                    relativeTo: base
                )?.absoluteURL,
                url.scheme?.lowercased() == "https"
            else { return nil }

            return CatalogLoader.versioned(url, version: version)
        }

        guard !urls.isEmpty else { return }

        playingVersion = version
        currentIndex = 0

        player = AVPlayer()
        player?.volume = enabled ? Float(volume) : 0

        playCurrent()
    }

    private func playCurrent() {
        guard let player, urls.indices.contains(currentIndex) else { return }
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        let item = AVPlayerItem(url: urls[currentIndex])
        endObserver = NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification,
            object: item,
            queue: .main
        ) { [weak self, weak item] _ in
            Task { @MainActor [weak self, weak item] in
                guard let self, let item, self.player?.currentItem === item,
                    !self.urls.isEmpty
                else { return }
                self.currentIndex = (self.currentIndex + 1) % self.urls.count
                self.playCurrent()
            }
        }
        player.replaceCurrentItem(with: item)
        player.play()
    }

    func stop() {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        endObserver = nil
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        urls = []
        playingVersion = nil
    }
}
