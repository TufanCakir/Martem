//
//  CachedRemoteImage.swift
//  Martem
//
//  Created by Tufan Cakir on 21.11.26.
//

import SwiftUI
import UIKit

@MainActor
final class ImageCache {
    static let shared = ImageCache()
    private let images = NSCache<NSURL, UIImage>()
    private let cache = URLCache(
        memoryCapacity: 20_000_000,
        diskCapacity: 100_000_000
    )
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = cache
        return URLSession(configuration: configuration)
    }()

    func image(for url: URL) async throws -> UIImage {
        if let image = images.object(forKey: url as NSURL) { return image }
        let request = URLRequest(
            url: url,
            cachePolicy: .returnCacheDataElseLoad,
            timeoutInterval: 15
        )
        if let cached = cache.cachedResponse(for: request),
            let image = UIImage(data: cached.data)
        {
            images.setObject(image, forKey: url as NSURL)
            return image
        }
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse,
            (200..<300).contains(http.statusCode),
            data.count <= 15_000_000, let image = UIImage(data: data)
        else {
            throw URLError(.cannotDecodeContentData)
        }
        cache.storeCachedResponse(
            CachedURLResponse(response: response, data: data),
            for: request
        )
        images.setObject(image, forKey: url as NSURL)
        return image
    }
}

struct CachedRemoteImage<Placeholder: View>: View {
    let url: URL
    @ViewBuilder let placeholder: () -> Placeholder
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image).resizable().scaledToFit()
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            image = nil
            image = try? await ImageCache.shared.image(for: url)
        }
    }
}
