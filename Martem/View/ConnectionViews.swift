//
//  ConnectionViews.swift
//  Martem
//
//  Created by Tufan Cakir on 21.11.26.
//

import SwiftUI

struct LoadingView: View {
    let progress: Double
    let message: String
    var body: some View {
        VStack(spacing: 20) {
            Text("MARTEM").font(.largeTitle.bold()).italic()
            ProgressView(value: progress).tint(.cyan)
            Text(message).font(.caption.bold()).tracking(1)
            Text("\(Int(progress * 100)) %").font(.caption.monospaced())
        }.padding(32).frame(maxWidth: 420)
    }
}

struct OfflineView: View {
    let message: String
    let retry: () -> Void
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "wifi.slash").font(.system(size: 50))
                    .foregroundStyle(.cyan)
                Text("VERBINDUNG FEHLT").font(.title.bold()).italic()
                Text(message).multilineTextAlignment(.center).foregroundStyle(
                    .secondary
                )
                Button("ERNEUT VERSUCHEN", action: retry).buttonStyle(
                    .borderedProminent
                )
            }.padding(30)
        }
    }
}
