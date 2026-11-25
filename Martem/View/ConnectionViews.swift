//
//  ConnectionViews.swift
//  Martem
//
//  Created by Tufan Cakir on 21.11.26.
//

import SwiftUI

struct LoadingView: View {

    @Environment(\.martemTheme) private var theme

    let progress: Double
    let message: String
    let bytes: Int

    var body: some View {
        VStack(spacing: 20) {

            Text("MARTEM")
                .font(.largeTitle.bold())
                .italic()

            ProgressView(value: progress)
                .tint(theme.color("loading"))

            Text(message)
                .font(.caption.bold())
                .tracking(1)

            Text(
                "\(Int(progress * 100))% · \(ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)) PROCESSED"
            )
            .font(.caption.monospaced())
        }
        .padding(32)
        .frame(maxWidth: 420)
    }
}

struct OfflineView: View {

    @Environment(\.martemTheme) private var theme

    let message: String
    let retry: () -> Void

    var body: some View {
        ZStack {

            theme.backdrop
                .ignoresSafeArea()

            VStack(spacing: 20) {

                Image(systemName: "wifi.slash")
                    .font(.system(size: 50))
                    .foregroundStyle(theme.accent)

                Text("NO CONNECTION")
                    .font(.title.bold())
                    .italic()

                Text(message)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                Button("RETRY", action: retry)
                    .buttonStyle(.borderedProminent)
            }
            .padding(30)
        }
    }
}
