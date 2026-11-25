//
//  BattleShaderBackground.swift
//  Martem
//
//  Created by Tufan Cakir on 21.11.26.
//

import SwiftUI

struct BattleShaderBackground: View {
    let arena: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.martemTheme) private var theme
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TimelineView(
            .animation(
                minimumInterval: 1.0 / 30.0,
                paused: reduceMotion || scenePhase != .active
            )
        ) { timeline in
            GeometryReader { geometry in
                let time =
                    reduceMotion
                    ? 0
                    : Float(
                        timeline.date.timeIntervalSinceReferenceDate
                            .truncatingRemainder(dividingBy: 100)
                    )
                Rectangle()
                    .fill(
                        ShaderLibrary.battleMetal(
                            .float2(geometry.size),
                            .float(time),
                            .color(theme.backdrop),
                            .color(theme.accent),
                            .color(theme.highlight),
                            .color(theme.metal),
                            .float(Float(theme.number("animationSpeed"))),
                            .float(Float(theme.number("brushIntensity"))),
                            .float(Float(theme.number("sweepIntensity"))),
                            .float(Float(theme.number("lightningIntensity"))),
                            .float(Float(theme.number("vignetteIntensity"))),
                            .float(Float(theme.number("brightness")))
                        )
                    )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
