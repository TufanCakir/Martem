//
//  MartemTheme.swift
//  Martem
//
//  Created by Tufan Cakir on 21.11.26.
//

import SwiftUI
import UIKit

/// Validated, resolved tokens consumed by SwiftUI, SpriteKit and Metal.
struct ThemeValues: Equatable {
    fileprivate var colors: [String: String]
    fileprivate var numbers: [String: Double]
    fileprivate var fighters: [String: String]
    fileprivate var feedback: [String: String]
    fileprivate var components: [String: String]

    func color(_ key: String) -> Color {
        Color(hex: colors[key] ?? ThemeDefaults.colors[key] ?? "F2F2F2")
    }
    func componentColor(_ key: String, fallback: String) -> Color {
        Color(
            hex: components[key] ?? colors[fallback] ?? ThemeDefaults.colors[
                fallback
            ] ?? "F2F2F2"
        )
    }
    func fighterColor(_ id: String) -> Color {
        Color(hex: fighters[id] ?? "E4E4E4")
    }
    func feedbackColor(_ id: String) -> Color {
        Color(hex: feedback[id] ?? "F2F2F2")
    }
    func number(_ key: String) -> Double {
        numbers[key] ?? ThemeDefaults.numbers[key] ?? 0
    }
    var accent: Color { color("accent") }
    var highlight: Color { color("highlight") }
    var metal: Color { color("metal") }
    var backdrop: Color { color("background") }
    var surface: Color { color("surface") }
    var elevatedSurface: Color { color("elevatedSurface") }
    var border: Color { color("border") }
    var primaryText: Color { color("primaryText") }
    var secondaryText: Color { color("secondaryText") }
    var mutedText: Color { color("mutedText") }
    var success: Color { color("success") }
    var danger: Color { color("danger") }
    var spacing: Double { number("smallSpacing") }
    var padding: Double { number("screenPadding") }
}

private enum ThemeDefaults {
    static let colors = [
        "accent": "E61919", "highlight": "FF7818", "metal": "C4C7CC",
        "background": "100D0E",
        "surface": "191617", "elevatedSurface": "252122", "border": "403A3B",
        "primaryText": "F2F2F2", "secondaryText": "A6A6A6",
        "mutedText": "777777",
        "success": "48C99B", "warning": "FFC247", "danger": "FF3444",
        "healthNormal": "48C99B", "healthCritical": "FF3444",
        "healthDamage": "FF7818",
        "flow": "33CCFF", "timer": "FFD044", "experience": "B49AFF",
        "loading": "E61919",
    ]
    static let numbers: [String: Double] = [
        "extraSmallSpacing": 4, "smallSpacing": 8, "mediumSpacing": 12,
        "largeSpacing": 16,
        "screenPadding": 22, "sectionSpacing": 24, "cornerRadius": 2,
        "borderWidth": 1,
        "selectedBorderWidth": 2, "minimumTouchTarget": 44, "display": 36,
        "screenTitle": 30,
        "modeTitle": 20, "sectionTitle": 16, "body": 15, "caption": 12,
        "combatFeedback": 24,
        "combatValue": 18, "timerSize": 28, "hitZoneOpacity": 0.45,
        "timingLineWidth": 2,
        "timingGlow": 1, "animationSpeed": 0.12, "brushIntensity": 0.35,
        "sweepIntensity": 0.25,
        "lightningIntensity": 0.08, "vignetteIntensity": 0.45,
        "brightness": 0.8,
        "damageDuration": 0.18, "pressDuration": 0.12,
    ]
    static let fighters = [
        "blue": "33CCFF", "orange": "FF780D", "red": "FF3444",
        "purple": "B49AFF",
        "green": "48C99B", "yellow": "FFD044", "white": "E4E4E4",
        "cyan": "4DE8E8",
    ]
    static let feedback = [
        "perfect": "FFD044", "great": "48C99B", "good": "33CCFF",
        "hit": "F2F2F2",
        "miss": "FF3444", "counter": "FF7818", "block": "A8C4D1",
        "dodge": "B49AFF",
        "overdrive": "33CCFF", "victory": "FFD044", "defeat": "FF3444",
    ]
    static let modes: [String: [String: String]] = [
        "duel": ["accent": "E61919", "background": "240C0E"],
        "training": ["accent": "48C99B", "background": "0B201A"],
        "pulse": ["accent": "B49AFF", "background": "1C122B"],
        "sudden": ["accent": "FF3444", "background": "300609"],
        "survival": ["accent": "A4C45C", "background": "1A2110"],
        "time_attack": ["accent": "FFD044", "background": "2A200B"],
        "overdrive": ["accent": "33CCFF", "background": "081B2C"],
    ]
}

private struct ThemeOverrides: Decodable {
    var colors: [String: String] = [:]
    var numbers: [String: Double] = [:]
    var components: [String: String] = [:]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicKey.self)
        for key in container.allKeys {
            if key.stringValue == "components" {
                components =
                    (try? container.decode([String: String].self, forKey: key))
                    ?? [:]
                continue
            }
            let name =
                [
                    "blue": "accent", "orange": "highlight", "steel": "metal",
                    "spacing": "smallSpacing", "padding": "screenPadding",
                ][key.stringValue] ?? key.stringValue
            if let value = try? container.decode(String.self, forKey: key) {
                colors[name] = value
            } else if let value = try? container.decode(
                Double.self,
                forKey: key
            ) {
                numbers[name] = value
            }
        }
    }
}

private struct DynamicKey: CodingKey {
    var stringValue: String
    init?(stringValue: String) { self.stringValue = stringValue }
    var intValue: Int? { nil }
    init?(intValue: Int) { return nil }
}

struct ThemeCatalog: Decodable {
    private var resolvedBase: ThemeValues
    private var modeValues: [String: ThemeValues]
    static let fallback: ThemeCatalog = {
        let base = ThemeValues(
            colors: ThemeDefaults.colors,
            numbers: ThemeDefaults.numbers,
            fighters: ThemeDefaults.fighters,
            feedback: ThemeDefaults.feedback,
            components: [:]
        )
        var modes: [String: ThemeValues] = [:]
        for (id, colors) in ThemeDefaults.modes {
            var value = base
            value.colors.merge(colors) { _, new in new }
            if id == "training" { value.numbers["lightningIntensity"] = 0 }
            if id == "overdrive" { value.numbers["lightningIntensity"] = 0.18 }
            modes[id] = value
        }
        return ThemeCatalog(resolvedBase: base, modeValues: modes)
    }()

    private init(resolvedBase: ThemeValues, modeValues: [String: ThemeValues]) {
        self.resolvedBase = resolvedBase
        self.modeValues = modeValues
    }

    init(from decoder: Decoder) throws {
        let root = try decoder.container(keyedBy: DynamicKey.self)
        func overrides(_ key: String) -> ThemeOverrides? {
            guard let key = DynamicKey(stringValue: key) else { return nil }
            return try? root.decode(ThemeOverrides.self, forKey: key)
        }
        func strings(_ key: String) -> [String: String] {
            guard let key = DynamicKey(stringValue: key) else { return [:] }
            return (try? root.decode([String: String].self, forKey: key)) ?? [:]
        }
        func validHex(_ value: String) -> Bool {
            value.count == 6
                && value.unicodeScalars.allSatisfy {
                    CharacterSet(charactersIn: "0123456789abcdefABCDEF")
                        .contains($0)
                }
        }
        func apply(_ values: ThemeOverrides?, to theme: inout ThemeValues) {
            guard let values else { return }
            for (key, value) in values.components where validHex(value) {
                theme.components[key] = value
            }
            for (key, value) in values.colors
            where ThemeDefaults.colors[key] != nil && validHex(value) {
                theme.colors[key] = value
            }
            for (key, value) in values.numbers
            where ThemeDefaults.numbers[key] != nil && value.isFinite {
                let limit: ClosedRange<Double>
                switch key {
                case "hitZoneOpacity", "brushIntensity", "sweepIntensity",
                    "lightningIntensity", "vignetteIntensity", "brightness":
                    limit = 0...1
                case "animationSpeed", "damageDuration", "pressDuration":
                    limit = 0...3
                case "minimumTouchTarget": limit = 44...100
                case "display", "screenTitle", "modeTitle", "sectionTitle",
                    "body", "caption", "combatFeedback", "combatValue",
                    "timerSize":
                    limit = 8...72
                default: limit = 0...60
                }
                if limit.contains(value) { theme.numbers[key] = value }
            }
        }

        var base = ThemeCatalog.fallback.resolvedBase
        apply(overrides("base"), to: &base)
        for section in ["typography", "layout", "effects", "shader"] {
            apply(overrides(section), to: &base)
        }
        for (key, value) in strings("fighterColors")
        where ThemeDefaults.fighters[key] != nil && validHex(value) {
            base.fighters[key] = value
        }
        for (key, value) in strings("combatFeedbackColors")
        where ThemeDefaults.feedback[key] != nil && validHex(value) {
            base.feedback[key] = value
        }
        for (key, value) in strings("components") where validHex(value) {
            base.components[key] = value
        }

        let supplied =
            DynamicKey(stringValue: "modes").flatMap {
                try? root.decode([String: ThemeOverrides].self, forKey: $0)
            } ?? [:]
        var result: [String: ThemeValues] = [:]
        for (id, defaults) in ThemeDefaults.modes {
            var value = base
            value.colors.merge(defaults) { _, new in new }
            if id == "training" { value.numbers["lightningIntensity"] = 0 }
            if id == "overdrive" { value.numbers["lightningIntensity"] = 0.18 }
            apply(supplied[id], to: &value)
            result[id] = value
        }
        resolvedBase = base
        modeValues = result
    }

    static func bundled() -> ThemeCatalog {
        guard
            let url = Bundle.main.url(
                forResource: "Theme",
                withExtension: "json"
            ),
            let data = try? Data(contentsOf: url),
            let theme = try? JSONDecoder().decode(Self.self, from: data)
        else { return .fallback }
        return theme
    }
    var valid: Bool { true }
    func values(for mode: String?) -> ThemeValues {
        mode.flatMap { modeValues[$0] } ?? resolvedBase
    }
}

private struct ContentVersionKey: EnvironmentKey { static let defaultValue = 1 }
private struct MartemThemeKey: EnvironmentKey {
    static let defaultValue = ThemeCatalog.fallback.values(for: nil)
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
    init(hex: String) {
        let number = UInt32(hex, radix: 16) ?? 0xF2F2F2
        self.init(
            red: Double((number >> 16) & 255) / 255,
            green: Double((number >> 8) & 255) / 255,
            blue: Double(number & 255) / 255
        )
    }
}
