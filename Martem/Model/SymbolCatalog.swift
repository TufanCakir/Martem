//
//  SymbolCatalog.swift
//  Martem
//
//  Created by Tufan Cakir on 21.11.26.
//

import Foundation
import UIKit

struct SymbolCatalog: Decodable {
    let symbols: [String: String]

    private static let defaults: [String: String] = [
        "credits": "star.circle.fill",
        "eventPoints": "sparkles",
        "precisionMedal": "medal.fill",
        "skins": "person.fill",
        "shop": "bag.fill",
    ]

    static func load() -> SymbolCatalog {
        guard
            let url = Bundle.main.url(
                forResource: "Symbols",
                withExtension: "json"
            ),
            let data = try? Data(contentsOf: url),
            let catalog = try? JSONDecoder().decode(
                SymbolCatalog.self,
                from: data
            )
        else {
            return SymbolCatalog(symbols: defaults)
        }
        return catalog
    }

    func symbol(for key: String) -> String {
        let fallback = Self.defaults[key] ?? "questionmark.circle"
        guard let symbol = symbols[key], UIImage(systemName: symbol) != nil
        else {
            return UIImage(systemName: fallback) != nil
                ? fallback : "questionmark.circle"
        }
        return symbol
    }
}
