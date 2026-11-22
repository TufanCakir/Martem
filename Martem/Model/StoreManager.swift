//
//  StoreManager.swift
//  Martem
//
//  Created by Tufan Cakir on 21.11.26.
//

import Foundation
import Observation
import StoreKit

struct StoreItem: Decodable, Identifiable {
    enum Kind: String, Decodable { case fighter, skin, credits }
    let id: String
    let kind: Kind
    let contentID: String?
    let credits: Int?
}

private struct StoreCatalog: Decodable {
    let products: [StoreItem]
}

@MainActor @Observable
final class StoreManager {
    private(set) var products: [Product] = []
    private(set) var items: [StoreItem] = []
    var message = ""
    private var listener: Task<Void, Never>?
    private weak var progress: ProgressManager?

    func start(progress: ProgressManager) async {
        guard listener == nil else { return }
        self.progress = progress
        do {
            guard
                let url = Bundle.main.url(
                    forResource: "StoreProducts",
                    withExtension: "json"
                )
            else {
                throw CocoaError(.fileNoSuchFile)
            }
            items = try JSONDecoder().decode(
                StoreCatalog.self,
                from: Data(contentsOf: url)
            ).products
            listener = Task { [weak self] in
                for await result in Transaction.updates {
                    await self?.handle(result)
                }
            }
            await refreshEntitlements()
            if !items.isEmpty {
                products = try await Product.products(for: items.map(\.id))
            }
        } catch {
            message = "Shop konnte nicht geladen werden."
        }
    }

    func item(for id: String) -> StoreItem? { items.first { $0.id == id } }

    func isOwned(_ item: StoreItem) -> Bool {
        guard let progress, let id = item.contentID else { return false }
        switch item.kind {
        case .fighter: return progress.ownsFighter(id)
        case .skin:
            guard
                let skin = progress.catalog.skins.first(where: { $0.id == id })
            else { return false }
            return progress.ownsSkin(skin)
        case .credits: return false
        }
    }

    func purchase(_ product: Product) async {
        guard let item = item(for: product.id), !isOwned(item), valid(item)
        else { return }
        guard
            (item.kind == .credits && product.type == .consumable)
                || (item.kind != .credits && product.type == .nonConsumable)
        else {
            message = "Produkttyp passt nicht zur Konfiguration."
            return
        }
        do {
            switch try await product.purchase() {
            case .success(let result): await handle(result)
            case .pending: message = "Kauf wartet auf Bestätigung."
            case .userCancelled: break
            @unknown default: break
            }
        } catch { message = "Kauf fehlgeschlagen." }
    }

    func restore() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            message = "Käufe wurden aktualisiert."
        } catch { message = "Käufe konnten nicht wiederhergestellt werden." }
    }

    private func valid(_ item: StoreItem) -> Bool {
        guard let progress else { return false }
        switch item.kind {
        case .credits: return (item.credits ?? 0) > 0
        case .fighter:
            return item.contentID.map {
                progress.catalog.fighterPrices[$0] != nil
            } ?? false
        case .skin:
            return item.contentID.map { id in
                progress.catalog.skins.contains { $0.id == id }
            } ?? false
        }
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result,
            let item = item(for: transaction.productID), valid(item)
        else { return }
        if transaction.revocationDate != nil {
            await refreshEntitlements()
            await transaction.finish()
            return
        }
        switch item.kind {
        case .credits:
            guard transaction.productType == .consumable,
                let amount = item.credits
            else { return }
            progress?.grantPurchasedCredits(
                amount,
                transactionID: String(transaction.id)
            )
        case .fighter, .skin:
            guard transaction.productType == .nonConsumable else { return }
            await refreshEntitlements()
        }
        await transaction.finish()
    }

    private func refreshEntitlements() async {
        var fighters: Set<String> = []
        var skins: Set<String> = []
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                transaction.revocationDate == nil,
                transaction.productType == .nonConsumable,
                let item = item(for: transaction.productID), valid(item),
                let id = item.contentID
            else { continue }
            if item.kind == .fighter { fighters.insert(id) }
            if item.kind == .skin { skins.insert(id) }
        }
        progress?.storeFighters = fighters
        progress?.storeSkins = skins
    }
}
