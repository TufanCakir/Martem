import SwiftUI

struct BattleShaderBackground: View {
    let arena: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var arenaIndex: Float {
        switch arena {
        case "duel": 1
        case "training": 2
        default: 0
        }
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { timeline in
            GeometryReader { geometry in
                let time = reduceMotion ? 0 : Float(timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 100))
                Rectangle()
                    .fill(ShaderLibrary.battleMetal(
                        .float2(geometry.size),
                        .float(time),
                        .float(arenaIndex)
                    ))
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}