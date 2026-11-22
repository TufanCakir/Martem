//
//  MartemTheme.swift
//  Martem
//
//  Created by Tufan Cakir on 21.11.26.
//

import SwiftUI

struct ThemeValues: Codable {
    let blue: String
    let orange: String
    let steel: String
    let background: String
    let spacing: Double
    let padding: Double

    var accent: Color { Color(hex: blue) }
    var highlight: Color { Color(hex: orange) }
    var metal: Color { Color(hex: steel) }
    var backdrop: Color { Color(hex: background) }
}

struct ThemeCatalog: Codable {
    let base: ThemeValues
    let modes: [String: ThemeValues]

    static let fallback = ThemeCatalog(
        base: ThemeValues(
            blue: "33CCFF",
            orange: "FF780D",
            steel: "A8C4D1",
            background: "0A1729",
            spacing: 8,
            padding: 22
        ),
        modes: [:]
    )

    static func bundled() -> ThemeCatalog {
        guard
            let url = Bundle.main.url(
                forResource: "Theme",
                withExtension: "json"
            ),
            let data = try? Data(contentsOf: url),
            let theme = try? JSONDecoder().decode(Self.self, from: data),
            theme.valid
        else { return .fallback }
        return theme
    }

    var valid: Bool {
        ([base] + Array(modes.values)).allSatisfy {
            [$0.blue, $0.orange, $0.steel, $0.background].allSatisfy {
                $0.count == 6 && UInt32($0, radix: 16) != nil
            } && (0...40).contains($0.spacing) && (0...50).contains($0.padding)
        }
    }

    func values(for mode: String?) -> ThemeValues {
        mode.flatMap { modes[$0] } ?? base
    }
}

private struct ContentVersionKey: EnvironmentKey {
    static let defaultValue = 1
}

private struct MartemThemeKey: EnvironmentKey {
    static let defaultValue = ThemeCatalog.fallback.base
}

extension EnvironmentValues {
    var contentVersion: Int {
        get { self[ContentVersionKey.self] }
        set { self[ContentVersionKey.self] = newValue }
    }
    var martemTheme: ThemeValues {
        get { self[MartemThemeKey.self] }
        set { self[MartemThemeKey.self] = newValue }
    }
}

extension Color {
    fileprivate init(hex: String) {
        let number = UInt32(hex, radix: 16) ?? 0
        self.init(
            red: Double((number >> 16) & 255) / 255,
            green: Double((number >> 8) & 255) / 255,
            blue: Double(number & 255) / 255
        )
    }
}
