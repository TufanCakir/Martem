//
//  SettingsView.swift
//  Martem
//
//  Created by Tufan Cakir on 21.11.26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.martemTheme) private var theme
    @AppStorage("musicEnabled") private var musicEnabled = true
    @AppStorage("musicVolume") private var musicVolume = 0.7
    let model: GameModel

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            ?? "–"
    }
    private var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "–"
    }
    private var privacyURL: URL? {
        guard let url = RemoteConfig.load()?.privacyPolicyURL,
            url.scheme?.lowercased() == "https"
        else { return nil }
        return url
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("EINSTELLUNGEN").font(.largeTitle.bold()).italic()
                VStack(alignment: .leading, spacing: 16) {
                    Text("AUDIO").font(.headline).foregroundStyle(theme.accent)
                    Toggle("Musik", isOn: $musicEnabled)
                        .tint(theme.highlight)
                    HStack {
                        Image(systemName: "speaker.fill")
                        Slider(value: $musicVolume, in: 0...1)
                            .tint(theme.accent)
                            .disabled(!musicEnabled)
                            .accessibilityLabel("Musiklautstärke")
                        Image(systemName: "speaker.wave.3.fill")
                        Text(
                            musicVolume,
                            format: .percent.precision(.fractionLength(0))
                        )
                        .font(.caption.monospacedDigit())
                    }
                }
                .padding().background(.white.opacity(0.07))

                VStack(alignment: .leading, spacing: 12) {
                    Text("INFORMATIONEN").font(.headline).foregroundStyle(
                        theme.accent
                    )
                    LabeledContent("Version", value: version)
                    LabeledContent("Build", value: build)
                    LabeledContent(
                        "Inhaltsversion",
                        value: String(model.contentVersion)
                    )
                    Text(
                        "© \(Calendar.current.component(.year, from: .now)) Tufan Cakir"
                    )
                    .font(.caption).foregroundStyle(.secondary)
                }
                .padding().background(.white.opacity(0.07))

                VStack(alignment: .leading, spacing: 12) {
                    Text("DATENSCHUTZ").font(.headline).foregroundStyle(
                        theme.accent
                    )
                    if let privacyURL {
                        Link(
                            "Nutzungsbedingungen von MARTEM",
                            destination: privacyURL
                        )
                    } else {
                        Text(
                            "Die Datenschutzerklärung von MARTEM ist noch nicht hinterlegt."
                        )
                        .font(.caption).foregroundStyle(.secondary)
                    }
                    if let eulaURL = URL(
                        string:
                            "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
                    ) {
                        Link("Apple Standard-EULA", destination: eulaURL)
                    }
                    if let appleURL = URL(
                        string:
                            "https://www.apple.com/legal/privacy/data/de/app-store/"
                    ) {
                        Link(
                            "Apple: App Store & Datenschutz",
                            destination: appleURL
                        )
                    }
                }
                .padding().background(.white.opacity(0.07))

                Button("‹  ZURÜCK") { model.screen = .modes }
                    .font(.headline).foregroundStyle(theme.highlight)
            }
            .padding(theme.padding)
        }
        .onChange(of: musicEnabled) { _, _ in applyAudioSettings() }
        .onChange(of: musicVolume) { _, _ in applyAudioSettings() }
        .onAppear { applyAudioSettings() }
    }

    private func applyAudioSettings() {
        model.musicPlayer.updateSettings(
            enabled: musicEnabled,
            volume: musicVolume
        )
    }
}
