import SpriteKit
import SwiftUI

private enum ArcadeStyle {
    static let blue = Color(red: 0.20, green: 0.80, blue: 1)
    static let orange = Color(red: 1, green: 0.47, blue: 0.05)
    static let steel = Color(red: 0.66, green: 0.77, blue: 0.82)
}

struct GameView: View {
    @State private var model = GameModel()

    var body: some View {
        ZStack {
            ArcadeBackground(
                arena: model.screen == .battle ? model.mode?.id : nil
            )
            switch model.screen {
            case .start: StartScreen { model.screen = .modes }
            case .modes: ModeScreen(model: model)
            case .roster: RosterScreen(model: model)
            case .battle: BattleScreen(model: model)
            case .result: VictoryView(model: model)
            case .error:
                Text("SPIELDATEN KONNTEN NICHT GELADEN WERDEN")
                    .font(.headline).foregroundStyle(.white).padding()
            }
        }
        .preferredColorScheme(.dark)
        .task { model.load() }
    }
}

private struct ArcadeBackground: View {
    let arena: String?
    private var arenaColor: Color {
        switch arena {
        case "duel": Color(red: 0.20, green: 0.08, blue: 0.05)
        case "training": Color(red: 0.10, green: 0.06, blue: 0.21)
        default: Color(red: 0.04, green: 0.09, blue: 0.16)
        }
    }
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.black, arenaColor, .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            if let arena {
                BattleShaderBackground(arena: arena)
            }
            GeometryReader { proxy in
                Path { path in
                    path.move(to: CGPoint(x: proxy.size.width * 0.8, y: 0))
                    path.addLines([
                        CGPoint(
                            x: proxy.size.width * 0.54,
                            y: proxy.size.height * 0.28
                        ),
                        CGPoint(
                            x: proxy.size.width * 0.69,
                            y: proxy.size.height * 0.29
                        ),
                        CGPoint(
                            x: proxy.size.width * 0.25,
                            y: proxy.size.height * 0.75
                        ),
                    ])
                }.stroke(ArcadeStyle.blue.opacity(0.16), lineWidth: 2).blur(
                    radius: 2
                )
            }
        }.ignoresSafeArea()
    }
}

private struct ScreenHeader: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(subtitle).font(
                .system(size: 10, weight: .bold, design: .monospaced)
            ).tracking(3).foregroundStyle(ArcadeStyle.blue)
            Text(title).font(
                .system(size: 31, weight: .black, design: .rounded)
            ).italic().foregroundStyle(.white)
            Rectangle().fill(
                LinearGradient(
                    colors: [ArcadeStyle.blue, .white.opacity(0.5), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            ).frame(height: 2)
        }
    }
}

private struct StartScreen: View {
    let start: () -> Void
    var body: some View {
        VStack(spacing: 0) {

            Spacer()

            Text("MARTEM").font(
                .system(size: 58, weight: .black, design: .rounded)
            ).italic()
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, ArcadeStyle.steel, .white],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: ArcadeStyle.blue, radius: 14)
                .minimumScaleFactor(0.5).lineLimit(1)

            Spacer()

            Button(action: start) {
                Text("▶  TAP TO START").font(.system(size: 20, weight: .black))
                    .italic().foregroundStyle(ArcadeStyle.orange)
                    .frame(maxWidth: .infinity).padding()
                    .background(.white.opacity(0.06))
                    .overlay(Rectangle().stroke(ArcadeStyle.steel.opacity(0.4)))
            }

            Spacer()

                .frame(height: 50)
        }.padding(.horizontal, 30)
    }
}

private struct ModeScreen: View {
    let model: GameModel
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ScreenHeader(
                title: "MODUS WÄHLEN",
                subtitle: "MARTEM  /  BATTLE SYSTEM"
            )
            Text("MODUS WÄHLEN").font(.caption.bold()).tracking(2)
                .foregroundStyle(ArcadeStyle.steel)
            VStack(spacing: 0) {
                ForEach(model.catalog?.modes ?? []) { mode in
                    Button {
                        model.selectMode(mode)
                    } label: {
                        HStack {
                            Text(model.selectedModeID == mode.id ? "▶" : "■")
                                .foregroundStyle(
                                    model.selectedModeID == mode.id
                                        ? ArcadeStyle.orange : ArcadeStyle.blue
                                )
                            Text(mode.name).foregroundStyle(
                                model.selectedModeID == mode.id
                                    ? ArcadeStyle.orange : .white
                            )
                            Spacer()
                        }.font(.system(size: 20, weight: .black)).italic()
                            .padding(.vertical, 14)
                            .overlay(alignment: .bottom) {
                                Rectangle().fill(.white.opacity(0.25)).frame(
                                    height: 1
                                )
                            }
                    }
                }
            }
            if let mode = model.mode {
                VStack(alignment: .leading, spacing: 10) {
                    Text(mode.name).font(.headline).foregroundStyle(
                        ArcadeStyle.blue
                    )
                    Text(mode.description).font(.subheadline).foregroundStyle(
                        .white.opacity(0.8)
                    )
                    Text("ARENA  /  \(mode.arena)").font(.caption.bold())
                        .foregroundStyle(ArcadeStyle.orange)
                }.frame(maxWidth: .infinity, alignment: .leading).padding()
                    .background(.white.opacity(0.08))
            }
            Spacer()
            Text("1× AUSWÄHLEN  /  2× BESTÄTIGEN").font(.caption2.bold())
                .tracking(1).foregroundStyle(.gray)
            Button("‹  ZURÜCK") { model.screen = .start }.foregroundStyle(
                .white
            )
        }.padding(24)
    }
}

private struct RosterScreen: View {
    let model: GameModel
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ScreenHeader(
                title: "CHOOSE YOUR FIGHTER",
                subtitle: model.mode?.name ?? ""
            )
            Text("WÄHLE DEINEN KÄMPFER").font(.caption.bold()).tracking(2)
                .foregroundStyle(ArcadeStyle.steel)
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(model.catalog?.fighters ?? []) { fighter in
                    Button {
                        model.selectFighter(fighter)
                    } label: {
                        VStack(spacing: 8) {
                            FighterPortrait(fighter: fighter, size: 70)
                            Text(fighter.name).font(
                                .system(size: 18, weight: .black)
                            ).italic()
                            Text(fighter.title).font(
                                .system(size: 9, weight: .bold)
                            ).tracking(1)
                        }.foregroundStyle(
                            model.selectedFighterID == fighter.id
                                ? ArcadeStyle.orange : .white
                        )
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(.white.opacity(0.06))
                        .overlay(
                            Rectangle().stroke(
                                model.selectedFighterID == fighter.id
                                    ? ArcadeStyle.orange
                                    : ArcadeStyle.blue.opacity(0.4),
                                lineWidth: model.selectedFighterID == fighter.id
                                    ? 2 : 1
                            )
                        )
                    }
                }
            }
            if let fighter = model.player {
                Text("POWER  \(fighter.power)     HP  \(fighter.guardValue)")
                    .font(.caption.bold().monospaced()).foregroundStyle(
                        ArcadeStyle.blue
                    )
            }
            Spacer()
            Text("ERNEUT TIPPEN, UM ZU KÄMPFEN").font(.caption2.bold())
                .tracking(1).foregroundStyle(.gray)
            Button("‹  ZURÜCK") { model.screen = .modes }.foregroundStyle(
                .white
            )
        }.padding(24)
    }
}

private struct FighterPortrait: View {
    let fighter: Fighter
    let size: CGFloat
    var tint: Color {
        switch fighter.color {
        case "orange": ArcadeStyle.orange
        case "purple": .purple
        case "cyan": .cyan
        default: ArcadeStyle.blue
        }
    }
    var body: some View {
        ZStack {
            Circle().fill(tint.opacity(0.15))
            Circle().stroke(tint.opacity(0.7), lineWidth: 2)
            Image(fighter.image)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .padding(size * 0.08)
                .clipShape(Circle())
        }.frame(width: size, height: size).shadow(
            color: tint.opacity(0.4),
            radius: 10
        )
    }
}

private struct HealthBar: View {
    let name: String
    let current: Int
    let maximum: Int
    let enemy: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(name)
                Spacer()
                Text("\(current) / \(maximum)")
            }.font(.system(size: 12, weight: .black, design: .monospaced))
            GeometryReader { proxy in
                ZStack(alignment: enemy ? .trailing : .leading) {
                    Rectangle().fill(.black.opacity(0.8))
                    Rectangle().fill(
                        LinearGradient(
                            colors: [ArcadeStyle.orange, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: proxy.size.width * CGFloat(max(0, current))
                            / CGFloat(max(1, maximum))
                    )
                }.overlay(Rectangle().stroke(ArcadeStyle.steel, lineWidth: 2))
            }.frame(height: 15)
        }
    }
}

private struct BattleScreen: View {
    let model: GameModel
    var body: some View {
        if let player = model.player, let enemy = model.enemy,
            let mode = model.mode, let scene = model.scene
        {
            GeometryReader { geometry in
                VStack(spacing: 8) {
                    HStack {
                        Button("‹ MENÜ") { model.leaveBattle() }.font(
                            .caption.bold()
                        )
                        Spacer()
                        Text("STAGE \(model.round) / \(mode.rounds)").font(
                            .caption.bold().monospaced()
                        ).foregroundStyle(ArcadeStyle.blue)
                    }
                    HealthBar(
                        name: enemy.name,
                        current: model.enemyHP,
                        maximum: enemy.guardValue,
                        enemy: true
                    )
                    Spacer(minLength: 0)
                    FighterPortrait(
                        fighter: enemy,
                        size: min(geometry.size.height * 0.15, 115)
                    )
                    Text(enemy.title).font(.caption2.bold()).tracking(2)
                        .foregroundStyle(ArcadeStyle.steel)
                    Spacer(minLength: 0)
                    Text(mode.arena).font(
                        .system(size: 10, weight: .black, design: .monospaced)
                    ).tracking(3).foregroundStyle(ArcadeStyle.blue)
                    Text(model.feedback).font(.system(size: 22, weight: .black))
                        .italic().foregroundStyle(ArcadeStyle.orange)
                    SpriteView(scene: scene, options: [.allowsTransparency])
                        .id(ObjectIdentifier(scene))
                        .frame(height: 90).allowsHitTesting(false)
                    Button(action: model.attack) {
                        Text("STRIKE").font(.system(size: 24, weight: .black))
                            .italic().tracking(3)
                            .foregroundStyle(.black).frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(
                                LinearGradient(
                                    colors: [.white, ArcadeStyle.blue],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay(Rectangle().stroke(.white, lineWidth: 2))
                            .shadow(
                                color: ArcadeStyle.blue.opacity(0.5),
                                radius: 10
                            )
                    }
                    Text("TIPPE IN DER LEUCHTENDEN ZONE").font(
                        .system(size: 9, weight: .bold)
                    ).tracking(1).foregroundStyle(.gray)
                    Spacer(minLength: 0)
                    FighterPortrait(
                        fighter: player,
                        size: min(geometry.size.height * 0.15, 115)
                    )
                    Text(player.title).font(.caption2.bold()).tracking(2)
                        .foregroundStyle(ArcadeStyle.steel)
                    Spacer(minLength: 0)
                    HealthBar(
                        name: player.name,
                        current: model.playerHP,
                        maximum: player.guardValue,
                        enemy: false
                    )
                }.padding(.horizontal, 22).padding(.vertical, 8)
            }
        }
    }
}

#Preview {
    GameView()
}
