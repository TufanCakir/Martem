//
//  ShopView.swift
//  Martem
//
//  Created by Tufan Cakir on 21.11.26.
//

import StoreKit
import SwiftUI

private struct ShopCategory: Decodable, Identifiable {
    let id: String
    let title: String
    let symbol: String
}

private struct ShopCategories: Decodable {
    let categories: [ShopCategory]

    static func load() -> [ShopCategory] {
        guard
            let url = Bundle.main.url(
                forResource: "ShopCategories",
                withExtension: "json"
            ),
            let data = try? Data(contentsOf: url),
            let catalog = try? JSONDecoder().decode(Self.self, from: data),
            !catalog.categories.isEmpty
        else { return [] }
        return catalog.categories
    }
}

struct ShopView: View {
    @Environment(\.martemTheme) private var theme
    let model: GameModel
    @State private var selectedCategory = "skins"
    @State private var message = ""
    private let categories = ShopCategories.load()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("MARTEM SHOP").font(.largeTitle.bold()).italic()
                Label(
                    "\(model.progress?.credits ?? 0) CREDITS",
                    systemImage: model.symbols.symbol(for: "credits")
                )
                .font(.headline.monospaced()).foregroundStyle(theme.highlight)
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(categories) { category in
                            Button {
                                selectedCategory = category.id
                            } label: {
                                Label(
                                    category.title,
                                    systemImage: model.symbols.symbol(
                                        for: category.symbol
                                    )
                                )
                                .foregroundStyle(
                                    selectedCategory == category.id
                                        ? theme.highlight : .white
                                )
                            }.buttonStyle(.bordered)
                        }
                    }
                }
                if !message.isEmpty {
                    Text(message).font(.caption).foregroundStyle(theme.accent)
                }
                if selectedCategory == "skins" {
                    skinSection
                } else if selectedCategory == "credits" {
                    creditSection
                }
                if !model.store.message.isEmpty {
                    Text(model.store.message).font(.caption).foregroundStyle(
                        theme.accent
                    )
                }
                Button("KÄUFE WIEDERHERSTELLEN") {
                    Task { await model.store.restore() }
                }
                .buttonStyle(.bordered)
                .font(.caption.bold())
                Button("‹  ZURÜCK") { model.screen = .modes }.font(.headline)
                    .buttonStyle(.plain)
            }.padding(24)
        }
    }

    private var skinSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Skins sind kosmetisch und verändern keine Kampfwerte.")
                .font(.subheadline).foregroundStyle(.secondary)
            if let progress = model.progress {
                ForEach(model.catalog?.fighters ?? []) { fighter in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            FighterImage(fighter: fighter).frame(
                                width: 56,
                                height: 56
                            )
                            VStack(alignment: .leading) {
                                Text(fighter.name).font(.headline.italic())
                                Text("SIEGE  \(progress.wins(for: fighter.id))")
                                    .font(.caption.monospaced())
                                    .foregroundStyle(theme.accent)
                            }
                        }
                        ForEach(
                            progress.catalog.skins.filter {
                                $0.fighterID == fighter.id
                            }
                        ) { skin in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    FighterImage(fighter: fighter, skin: skin)
                                        .frame(width: 44, height: 44)
                                    VStack(alignment: .leading) {
                                        Text(skin.name).font(
                                            .subheadline.bold()
                                        )
                                        if skin.masteryWins > 0 {
                                            Text(
                                                "\(skin.masteryWins) Siege für Meisterschaft"
                                            )
                                            .font(.caption2).foregroundStyle(
                                                .secondary
                                            )
                                        }
                                    }
                                    Spacer()
                                }
                                if progress.ownsSkin(skin) {
                                    if progress.selectedSkin(for: fighter.id)?
                                        .id == skin.id
                                    {
                                        Text("AKTIV").font(.caption.bold())
                                            .foregroundStyle(.green)
                                    } else {
                                        Button("WÄHLEN") {
                                            progress.equip(skin)
                                        }
                                        .buttonStyle(.bordered).disabled(
                                            !progress.ownsFighter(fighter.id)
                                        )
                                    }
                                } else {
                                    HStack {
                                        Button("\(skin.price) CREDITS") {
                                            message =
                                                progress.buySkin(skin)
                                                ? "Skin freigeschaltet."
                                                : "Nicht genug Credits oder Kämpfer gesperrt."
                                        }.buttonStyle(.bordered)
                                        if let product = productForSkin(skin.id)
                                        {
                                            Button(product.displayPrice) {
                                                Task {
                                                    await model.store.purchase(
                                                        product
                                                    )
                                                }
                                            }.buttonStyle(.bordered)
                                        } else {
                                            Text(
                                                "Echtgeldpreis nicht verfügbar"
                                            ).font(.caption2).foregroundStyle(
                                                .secondary
                                            )
                                        }
                                    }
                                }
                            }
                            Divider()
                        }
                    }.padding().background(.white.opacity(0.07))
                }
            }
        }
    }

    private var creditSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Credits können mehrfach gekauft werden.").font(.subheadline)
                .foregroundStyle(.secondary)
            let products = model.store.products.filter {
                model.store.item(for: $0.id)?.kind == .credits
            }
            .sorted {
                (model.store.item(for: $0.id)?.credits ?? 0)
                    < (model.store.item(for: $1.id)?.credits ?? 0)
            }
            if products.isEmpty {
                Text("Credit-Pakete sind momentan nicht verfügbar.")
                    .foregroundStyle(.secondary)
            }
            ForEach(products, id: \.id) { product in
                HStack {
                    VStack(alignment: .leading) {
                        Text(product.displayName).font(.headline)
                        Text(product.description).font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(product.displayPrice) {
                        Task { await model.store.purchase(product) }
                    }
                    .buttonStyle(.bordered)
                }.padding().background(.white.opacity(0.07))
            }
        }
    }

    private func productForSkin(_ skinID: String) -> Product? {
        model.store.products.first {
            guard let item = model.store.item(for: $0.id) else { return false }
            return item.kind == .skin && item.contentID == skinID
        }
    }
}
