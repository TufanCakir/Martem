//
//  FighterImage.swift
//  Martem
//
//  Created by Tufan Cakir on 21.11.26.
//

import SwiftUI

struct FighterImage: View {
    @Environment(\.contentVersion) private var contentVersion
    let fighter: Fighter
    var skin: Skin? = nil

    var body: some View {
        if let url = remoteURL.flatMap({
            CatalogLoader.versioned($0, version: contentVersion)
        }) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .success(let image):
                    image.resizable().scaledToFit()
                case .failure:
                    fallback
                @unknown default:
                    fallback
                }
            }
        } else {
            fallback
        }
    }

    private var remoteURL: URL? {
        guard let imageURL = skin?.imageURL ?? fighter.imageURL else {
            return nil
        }
        if imageURL.scheme?.lowercased() == "https" { return imageURL }
        guard imageURL.scheme == nil,
            let base = RemoteConfig.load()?.assetsBaseURL,
            base.scheme?.lowercased() == "https"
        else { return nil }
        return URL(string: imageURL.relativeString, relativeTo: base)?
            .absoluteURL
    }

    private var fallback: some View {
        Image(systemName: "person.crop.square.badge.exclamationmark")
            .resizable()
            .scaledToFit()
            .padding(12)
            .foregroundStyle(.secondary)
            .accessibilityLabel("Bild für \(fighter.name) nicht verfügbar")
    }
}
