//
//  ThemePreview.swift
//  Martem
//
//  Created by Tufan Cakir on 21.11.26.
//

#if DEBUG
    import SwiftUI
    import SpriteKit

    struct ThemePreview: View {
        @State private var selection = "base"
        private let catalog = ThemeCatalog.bundled()
        private let modes = [
            "base", "duel", "training", "pulse", "sudden", "survival",
            "time_attack", "overdrive",
        ]

        var body: some View {
            let theme = catalog.values(
                for: selection == "base" ? nil : selection
            )
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Picker("Theme", selection: $selection) {
                        ForEach(modes, id: \.self) { mode in
                            Text(mode.uppercased()).tag(mode)
                        }
                    }.pickerStyle(.menu)
                    ScreenHeader(
                        title: "MARTEM",
                        subtitle: selection.uppercased()
                    )
                    MartemPanel {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CRIMSON  /  STEEL  /  FIRE").foregroundStyle(
                                theme.primaryText
                            )
                            HStack {
                                Button("START") {}.buttonStyle(
                                    MartemButtonStyle(primary: true)
                                )
                                Button("ZURÜCK") {}.buttonStyle(
                                    MartemButtonStyle()
                                )
                            }
                            HStack {
                                Button("AUSGEWÄHLT") {}.buttonStyle(
                                    MartemButtonStyle(selected: true)
                                )
                                Button("GESPERRT") {}.buttonStyle(
                                    MartemButtonStyle()
                                ).disabled(true)
                            }
                        }
                    }
                    HealthBar(
                        name: "VORIX",
                        current: 65,
                        maximum: 100,
                        enemy: false
                    )
                    ProgressView(value: 0.75).tint(theme.color("flow"))
                    Text("ZEIT  42").font(
                        .system(
                            size: theme.number("timerSize"),
                            weight: .bold,
                            design: .monospaced
                        )
                    ).foregroundStyle(theme.color("timer"))
                    HStack {
                        Text("PERFECT").foregroundStyle(
                            theme.feedbackColor("perfect")
                        )
                        Text("GOOD").foregroundStyle(
                            theme.feedbackColor("good")
                        )
                        Text("MISS").foregroundStyle(
                            theme.feedbackColor("miss")
                        )
                    }.font(.headline.bold())
                    let fighter = Fighter(
                        id: "preview",
                        name: "VORIX",
                        title: "",
                        color: "blue",
                        image: "",
                        imageURL: nil,
                        power: 20,
                        guardValue: 100
                    )
                    FighterPortrait(fighter: fighter, size: 80)
                    Text("SHADER").font(.caption.bold())
                    BattleShaderBackground(arena: selection).frame(height: 100)
                        .clipped()
                    Text("TIMING TRACK / PULSE").font(.caption.bold())
                    HStack {
                        SpriteView(
                            scene: scene(theme, mechanic: .marker),
                            options: [.allowsTransparency]
                        )
                        SpriteView(
                            scene: scene(theme, mechanic: .pulse),
                            options: [.allowsTransparency]
                        )
                    }.frame(height: 100)
                    HStack(spacing: 4) {
                        ForEach(
                            [
                                "accent", "highlight", "metal", "background",
                                "surface", "border", "success", "danger",
                            ],
                            id: \.self
                        ) { color in
                            VStack {
                                Rectangle().fill(theme.color(color)).frame(
                                    height: 30
                                )
                                Text(color).font(.system(size: 7)).lineLimit(1)
                                    .minimumScaleFactor(0.5)
                            }
                        }
                    }
                }.padding().background(theme.backdrop).foregroundStyle(
                    theme.primaryText
                )
            }
            .environment(\.martemTheme, theme)
            .background { BattleShaderBackground(arena: selection) }
            .preferredColorScheme(.dark)
        }

        private func scene(_ theme: ThemeValues, mechanic: TimingMechanic)
            -> BattleScene
        {
            BattleScene(
                size: CGSize(width: 400, height: 120),
                speed: 1,
                mechanic: mechanic,
                visualTheme: theme
            )
        }
    }

    #Preview("MARTEM Theme") {
        ThemePreview()
    }
#endif
