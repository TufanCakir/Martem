//
//  CatalogLoader.swift
//  Martem
//
//  Created by Tufan Cakir on 21.11.26.
//

import Foundation

struct RemoteConfig: Decodable {
    let gameDataURL: URL?
    let themeURL: URL?
    let rewardsURL: URL?
    let musicConfigURL: URL?
    let startViewURL: URL?
    let assetsBaseURL: URL?
    let musicBaseURL: URL?
    let privacyPolicyURL: URL?

    static func load() -> RemoteConfig? {
        guard
            let url = Bundle.main.url(
                forResource: "RemoteConfig",
                withExtension: "json"
            ),
            let data = try? Data(contentsOf: url)
        else { return nil }
        return try? JSONDecoder().decode(Self.self, from: data)
    }
}

struct StartViewCatalog: Codable {
    let logo: String
    let subtitle: String

    static func bundled() -> StartViewCatalog {
        guard
            let url = Bundle.main.url(
                forResource: "StartView",
                withExtension: "json"
            ),
            let data = try? Data(contentsOf: url),
            let value = try? JSONDecoder().decode(Self.self, from: data)
        else {
            return StartViewCatalog(
                logo: "martem_logo.png",
                subtitle: "DON’T JUST FIGHT. MASTER THE ART OF COMBAT."
            )
        }
        return value
    }
}

struct MusicCatalog: Codable {
    let battle: [String]

    init(battle: [String]) {
        self.battle = battle
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let tracks = try? container.decode([String].self, forKey: .battle) {
            battle = tracks
        } else if let track = try? container.decode(
            String.self,
            forKey: .battle
        ) {
            battle = [track]
        } else {
            battle = []
        }
    }

    static func bundled() -> MusicCatalog {
        guard
            let url = Bundle.main.url(
                forResource: "Music",
                withExtension: "json"
            ),
            let data = try? Data(contentsOf: url),
            let catalog = try? JSONDecoder().decode(
                MusicCatalog.self,
                from: data
            )
        else {
            return MusicCatalog(battle: [])
        }
        return catalog
    }
}

enum CatalogLoader {
    static func versioned(_ url: URL, version: Int) -> URL? {
        guard var parts = URLComponents(url: url, resolvingAgainstBaseURL: true)
        else { return nil }
        var query = parts.queryItems ?? []
        query.removeAll { $0.name == "contentVersion" }
        query.append(
            URLQueryItem(name: "contentVersion", value: String(version))
        )
        parts.queryItems = query
        return parts.url
    }

    static func remoteData(_ url: URL?, limit: Int) async throws -> Data {
        guard let url, url.scheme?.lowercased() == "https" else {
            throw URLError(.badURL)
        }
        let request = URLRequest(
            url: url,
            cachePolicy: .useProtocolCachePolicy,
            timeoutInterval: 10
        )
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse,
            (200..<300).contains(response.statusCode),
            data.count <= limit
        else { throw URLError(.badServerResponse) }
        return data
    }

    static func loadRewards() async throws -> RewardCatalog {
        do {
            let data = try await remoteData(
                RemoteConfig.load()?.rewardsURL,
                limit: 200_000
            )
            return try RewardCatalog.decode(data)
        } catch { return try RewardCatalog.load() }
    }

    static func loadMusic() async -> MusicCatalog {
        do {
            let data = try await remoteData(
                RemoteConfig.load()?.musicConfigURL,
                limit: 100_000
            )
            return try JSONDecoder().decode(MusicCatalog.self, from: data)
        } catch { return .bundled() }
    }
    static func loadTheme() async -> ThemeCatalog {
        guard let url = RemoteConfig.load()?.themeURL,
            url.scheme?.lowercased() == "https"
        else { return .bundled() }
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 5
            let (data, response) = try await URLSession.shared.data(
                for: request
            )
            guard let response = response as? HTTPURLResponse,
                (200..<300).contains(response.statusCode), data.count <= 200_000
            else { return .bundled() }
            let theme = try JSONDecoder().decode(ThemeCatalog.self, from: data)
            return theme.valid ? theme : .bundled()
        } catch { return .bundled() }
    }

    static func loadGame() async throws -> GameCatalog {
        if let url = RemoteConfig.load()?.gameDataURL,
            url.scheme?.lowercased() == "https"
        {
            do {
                var request = URLRequest(url: url)
                request.timeoutInterval = 5
                let (data, response) = try await URLSession.shared.data(
                    for: request
                )
                guard let response = response as? HTTPURLResponse,
                    (200..<300).contains(response.statusCode),
                    data.count <= 2_000_000
                else { throw URLError(.badServerResponse) }
                return try GameCatalog.decode(data)
            } catch {
                // Offline, invalid or incompatible content falls back to the bundled catalog.
            }
        }
        return try GameCatalog.load()
    }
}
