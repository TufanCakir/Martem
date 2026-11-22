//
//  ProgressManager.swift
//  Martem
//
//  Created by Tufan Cakir on 21.11.26.
//

import Foundation
import Observation

struct Skin: Codable, Identifiable {
    let id: String
    let fighterID: String
    let name: String
    let price: Int
    let symbol: String
    let imageURL: URL?
    let masteryWins: Int
}

struct RewardRules: Codable {
    let loss: Int
    let duelWin: Int
    let arcadeStage: Int
    let noMiss: Int
}

struct RewardCatalog: Codable {
    let fighterPrices: [String: Int]
    let skins: [Skin]
    let rewards: RewardRules

    static func load() throws -> RewardCatalog {
        guard
            let url = Bundle.main.url(
                forResource: "Rewards",
                withExtension: "json"
            )
        else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try decode(Data(contentsOf: url))
    }

    static func decode(_ data: Data) throws -> RewardCatalog {
        let result = try JSONDecoder().decode(Self.self, from: data)
        guard result.fighterPrices.values.allSatisfy({ $0 >= 0 }),
            result.skins.allSatisfy({ $0.price >= 0 && $0.masteryWins >= 0 }),
            [
                result.rewards.loss, result.rewards.duelWin,
                result.rewards.arcadeStage, result.rewards.noMiss,
            ].allSatisfy({ $0 >= 0 })
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return result
    }
}

private struct SavedProgress: Codable {
    var credits = 0
    var fighters: Set<String> = []
    var skins: Set<String> = []
    var selectedSkins: [String: String] = [:]
    var wins: [String: Int] = [:]
    var processedTransactions: Set<String>? = nil
}

@MainActor @Observable
final class ProgressManager {
    private let key = "martem.progress.v1"
    private var state: SavedProgress
    var catalog: RewardCatalog
    var storeFighters: Set<String> = []
    var storeSkins: Set<String> = []

    init(catalog: RewardCatalog) {
        self.catalog = catalog
        if let data = UserDefaults.standard.data(forKey: key),
            let saved = try? JSONDecoder().decode(
                SavedProgress.self,
                from: data
            )
        {
            var migrated = saved
            for (oldID, newID) in [("raiden", "vorix"), ("akira", "braxo")] {
                if let count = migrated.wins.removeValue(forKey: oldID) {
                    migrated.wins[newID, default: 0] += count
                }
                if migrated.fighters.remove(oldID) != nil {
                    migrated.fighters.insert(newID)
                }
                for suffix in ["default", oldID == "raiden" ? "storm" : "iron"]
                {
                    let oldSkin = "\(oldID)_\(suffix)"
                    let newSkin = "\(newID)_\(suffix)"
                    if migrated.skins.remove(oldSkin) != nil {
                        migrated.skins.insert(newSkin)
                    }
                    if migrated.selectedSkins[oldID] == oldSkin {
                        migrated.selectedSkins[newID] = newSkin
                    }
                }
                migrated.selectedSkins.removeValue(forKey: oldID)
            }
            state = migrated
            if let data = try? JSONEncoder().encode(migrated) {
                UserDefaults.standard.set(data, forKey: key)
            }
        } else {
            state = SavedProgress()
        }
    }

    var credits: Int { state.credits }
    var totalWins: Int { state.wins.values.reduce(0, +) }
    var fighterUnlockWins: Int { 10 }
    func wins(for fighterID: String) -> Int {
        state.wins[fighterID, default: 0]
    }
    func ownsFighter(_ id: String) -> Bool {
        guard let price = catalog.fighterPrices[id] else { return false }
        return price == 0 || state.fighters.contains(id)
            || totalWins >= fighterUnlockWins
    }
    func ownsSkin(_ skin: Skin) -> Bool {
        skin.price == 0 || state.skins.contains(skin.id)
            || storeSkins.contains(skin.id)
            || (skin.masteryWins > 0
                && wins(for: skin.fighterID) >= skin.masteryWins)
    }
    func selectedSkin(for fighterID: String) -> Skin? {
        let skins = catalog.skins.filter { $0.fighterID == fighterID }
        if let id = state.selectedSkins[fighterID],
            let skin = skins.first(where: { $0.id == id }), ownsSkin(skin)
        {
            return skin
        }
        return skins.first { $0.price == 0 }
    }
    @discardableResult func buySkin(_ skin: Skin) -> Bool {
        guard ownsFighter(skin.fighterID), !ownsSkin(skin), skin.price > 0,
            state.credits >= skin.price
        else { return false }
        state.credits -= skin.price
        state.skins.insert(skin.id)
        save()
        return true
    }
    func equip(_ skin: Skin) {
        guard ownsFighter(skin.fighterID), ownsSkin(skin) else { return }
        state.selectedSkins[skin.fighterID] = skin.id
        save()
    }
    func award(_ amount: Int) {
        guard amount > 0 else { return }
        state.credits += amount
        save()
    }
    func grantPurchasedCredits(_ amount: Int, transactionID: String) {
        guard amount > 0,
            !(state.processedTransactions ?? []).contains(transactionID)
        else { return }
        state.credits += amount
        var ids = state.processedTransactions ?? []
        ids.insert(transactionID)
        state.processedTransactions = ids
        save()
    }
    func recordWin(fighterID: String) {
        state.wins[fighterID, default: 0] += 1
        save()
    }
    private func save() {
        guard let data = try? JSONEncoder().encode(state) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
