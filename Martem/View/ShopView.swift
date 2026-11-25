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
            let catalog = try? JSONDecoder().decode(Self.self, from: data)
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("MARTEM SHOP").font(.title2.bold()).italic()
                Spacer(minLength: 8)
                Label(
                    "\(model.progress?.credits ?? 0)",
                    systemImage: model.symbols.symbol(for: "credits")
                )
                .font(.subheadline.bold().monospacedDigit())
                .foregroundStyle(theme.highlight)
                .accessibilityLabel("\(model.progress?.credits ?? 0) credits")
            }
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(categories) { category in
                        Button {
                            selectedCategory = category.id
                        } label: {
                            Label(
                                categoryTitle(category),
                                systemImage: model.symbols.symbol(
                                    for: category.symbol
                                )
                            )
                            .font(.caption.bold())
                            .padding(.horizontal, 12)
                            .frame(minHeight: 44)
                            .foregroundStyle(
                                selectedCategory == category.id
                                    ? theme.highlight : theme.metal
                            )
                            .overlay(
                                Rectangle().stroke(
                                    selectedCategory == category.id
                                        ? theme.highlight : theme.border
                                )
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(
                            selectedCategory == category.id ? .isSelected : []
                        )
                    }
                }
            }
            .scrollIndicators(.hidden)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    if !message.isEmpty {
                        Text(message).font(.caption).foregroundStyle(
                            theme.accent
                        )
                    }
                    if selectedCategory == "skins" {
                        skinSection
                    } else if selectedCategory == "credits" {
                        creditSection
                    }
                    if !model.store.message.isEmpty {
                        Text(model.store.message).font(.caption)
                            .foregroundStyle(theme.accent)
                    }
                }
            }
            HStack {
                Button("‹ BACK") { model.screen = .modes }
                    .foregroundStyle(theme.highlight)
                Spacer()
                Button("RESTORE PURCHASES") {
                    Task { await model.store.restore() }
                }
                .foregroundStyle(theme.metal)
            }
            .font(.caption.bold())
            .buttonStyle(.plain)
            .frame(minHeight: 44)
        }
        .padding(12)
    }

    private func categoryTitle(_ category: ShopCategory) -> String {
        switch category.id {
        case "skins": "SKINS"
        case "credits": "CREDITS"
        default: category.title
        }
    }

    private var skinSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Cosmetic only. No stat changes.")
                .font(.caption).foregroundStyle(.secondary)
            if let progress = model.progress {
                ForEach(model.catalog?.fighters ?? []) { fighter in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            FighterImage(fighter: fighter).frame(
                                width: 40,
                                height: 40
                            )
                            VStack(alignment: .leading, spacing: 2) {
                                Text(fighter.name).font(.subheadline.bold())
                                    .italic()
                                Text("\(progress.wins(for: fighter.id)) WINS")
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(theme.accent)
                            }
                            Spacer(minLength: 0)
                        }
                        ForEach(
                            progress.catalog.skins.filter {
                                $0.fighterID == fighter.id
                            }
                        ) { skin in
                            Divider()
                            HStack(spacing: 6) {
                                FighterImage(fighter: fighter, skin: skin)
                                    .frame(width: 36, height: 36)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(skin.name).font(.caption.bold())
                                    if skin.masteryWins > 0 {
                                        Text("\(skin.masteryWins) mastery wins")
                                            .font(.caption2).foregroundStyle(
                                                .secondary
                                            )
                                    }
                                }
                                Spacer(minLength: 2)
                                if progress.ownsSkin(skin) {
                                    if progress.selectedSkin(for: fighter.id)?
                                        .id == skin.id
                                    {
                                        Text("EQUIPPED").font(.caption2.bold())
                                            .foregroundStyle(theme.success)
                                    } else {
                                        Button("EQUIP") { progress.equip(skin) }
                                            .disabled(
                                                !progress.ownsFighter(
                                                    fighter.id
                                                )
                                            )
                                    }
                                } else {
                                    ViewThatFits(in: .horizontal) {
                                        HStack(spacing: 4) {
                                            skinPurchaseButtons(skin)
                                        }
                                        VStack(alignment: .trailing, spacing: 4)
                                        { skinPurchaseButtons(skin) }
                                    }
                                }
                            }
                            .font(.caption2.bold())
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    .padding(8)
                    .background(theme.surface)
                    .overlay(
                        Rectangle().stroke(
                            theme.border,
                            lineWidth: theme.number("borderWidth")
                        )
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func skinPurchaseButtons(_ skin: Skin) -> some View {
        Button("\(skin.price) CR") {
            if let progress = model.progress {
                message =
                    progress.buySkin(skin)
                    ? "Skin unlocked."
                    : "Not enough credits or fighter locked."
            }
        }
        if let product = productForSkin(skin.id) {
            Button(product.displayPrice) {
                Task { await model.store.purchase(product) }
            }
        } else {
            Text("Price unavailable").font(.caption2).foregroundStyle(
                .secondary
            )
        }
    }

    private var creditSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Credits can be purchased multiple times.")
                .font(.caption).foregroundStyle(.secondary)
            let products = model.store.products.filter {
                model.store.item(for: $0.id)?.kind == .credits
            }.sorted {
                (model.store.item(for: $0.id)?.credits ?? 0)
                    < (model.store.item(for: $1.id)?.credits ?? 0)
            }
            if products.isEmpty {
                Text("Credit packs are currently unavailable.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            ForEach(products, id: \.id) { product in
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(product.displayName).font(.subheadline.bold())
                        Text(product.description).font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 4)
                    Button(product.displayPrice) {
                        Task { await model.store.purchase(product) }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .font(.caption.bold())
                }
                .padding(8)
                .background(theme.surface)
                .overlay(
                    Rectangle().stroke(
                        theme.border,
                        lineWidth: theme.number("borderWidth")
                    )
                )
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
