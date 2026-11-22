//
//  GameView.swift
//  Martem
//
//  Created by Tufan Cakir on 21.11.26.
//

import SpriteKit
import SwiftUI

struct GameView: View {
    @State private var model = GameModel()
    @State private var connection = ConnectionMonitor()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            ArcadeBackground(
                arena: model.screen == .battle ? model.mode?.id : nil
            )
            switch model.screen {
            case .loading:
                LoadingView(
                    progress: model.loadingProgress,
                    message: model.loadingMessage
                )
            case .offline:
                OfflineView(message: model.loadingMessage) {
                    Task { await prepare() }
                }
            case .start: StartScreen { model.screen = .modes }
            case .modes: ModeScreen(model: model)
            case .roster: RosterScreen(model: model)
            case .shop: ShopView(model: model)
            case .settings: SettingsView(model: model)
            case .battle: BattleScreen(model: model)
            case .result: VictoryView(model: model)
            case .error:
                Text("SPIELDATEN KONNTEN NICHT GELADEN WERDEN")
                    .font(.headline).foregroundStyle(.white).padding()
            }
            if !connection.connected && model.screen != .loading
                && model.screen != .offline
            {
                OfflineView(
                    message:
                        "Internetverbindung unterbrochen. Der Kampf ist pausiert."
                ) { Task { await prepare() } }
            }
        }
        .environment(\.contentVersion, model.contentVersion)
        .environment(
            \.martemTheme,
            model.theme.values(
                for: model.screen == .battle ? model.mode?.id : nil
            )
        )
        .preferredColorScheme(.dark)
        .task { await prepare() }
        .onChange(of: model.screen) { _, _ in updateMusic() }
        .onChange(of: scenePhase) { _, _ in updateMusic() }
        .onChange(of: connection.connected) { _, connected in
            if model.screen == .battle { model.scene?.isPaused = !connected }
            updateMusic()
        }
    }

    private func prepare() async {
        model.scene?.isPaused = true
        await model.load()
        if let progress = model.progress {
            await model.store.start(progress: progress)
        }
        updateMusic()
    }

    private func updateMusic() {
        guard scenePhase == .active,
            connection.connected,
            model.screen != .loading,
            model.screen != .offline,
            model.screen != .error
        else {
            model.musicPlayer.stop()
            return
        }

        model.musicPlayer.playBattle(
            model.music.battle,
            version: model.contentVersion
        )
    }
}

private struct ArcadeBackground: View {
    @Environment(\.martemTheme) private var theme
    let arena: String?
    private var arenaColor: Color { theme.backdrop }
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
                }.stroke(theme.accent.opacity(0.16), lineWidth: 2).blur(
                    radius: 2
                )
            }
        }.ignoresSafeArea()
    }
}

private struct ScreenHeader: View {
    @Environment(\.martemTheme) private var theme
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(subtitle).font(
                .system(size: 10, weight: .bold, design: .monospaced)
            ).tracking(3).foregroundStyle(theme.accent)
            Text(title).font(
                .system(size: 31, weight: .black, design: .rounded)
            ).italic().foregroundStyle(.white)
            Rectangle().fill(
                LinearGradient(
                    colors: [theme.accent, .white.opacity(0.5), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            ).frame(height: 2)
        }
    }
}

private struct StartScreen: View {
    @Environment(\.martemTheme) private var theme
    let start: () -> Void
    var body: some View {
        VStack(spacing: 0) {

            Spacer()

            Text("MARTEM").font(
                .system(size: 58, weight: .black, design: .rounded)
            ).italic()
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, theme.metal, .white],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: theme.accent, radius: 14)
                .minimumScaleFactor(0.5).lineLimit(1)

            Spacer()

            Button(action: start) {
                Text("▶  TAP TO START").font(.system(size: 20, weight: .black))
                    .italic().foregroundStyle(theme.highlight)
                    .frame(maxWidth: .infinity).padding()
                    .background(.white.opacity(0.06))
                    .overlay(Rectangle().stroke(theme.metal.opacity(0.4)))
            }

            Spacer().frame(height: 30)
            Text(
                "© \(Calendar.current.component(.year, from: .now)) Tufan Cakir"
            )
            .font(.caption2).foregroundStyle(.secondary)
            Text(
                "Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–") · Build \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "–")"
            )
            .font(.caption2.monospaced()).foregroundStyle(.secondary)
            .padding(.top, 4)
            Spacer().frame(height: 16)
        }.padding(.horizontal, 30)
    }
}

private struct ModeScreen: View {
    @Environment(\.martemTheme) private var theme
    let model: GameModel
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ScreenHeader(
                title: "MODUS WÄHLEN",
                subtitle: "MARTEM  /  BATTLE SYSTEM"
            )
            Text("MODUS WÄHLEN").font(.caption.bold()).tracking(2)
                .foregroundStyle(theme.metal)
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(model.catalog?.modes ?? []) { mode in
                        Button {
                            model.selectMode(mode)
                        } label: {
                            HStack {
                                Text(
                                    model.selectedModeID == mode.id ? "▶" : "■"
                                )
                                .foregroundStyle(
                                    model.selectedModeID == mode.id
                                        ? theme.highlight : theme.accent
                                )
                                Text(mode.name).foregroundStyle(
                                    model.selectedModeID == mode.id
                                        ? theme.highlight : .white
                                )
                                Spacer()
                            }.font(.system(size: 20, weight: .black)).italic()
                                .padding(.vertical, 14)
                                .overlay(alignment: .bottom) {
                                    Rectangle().fill(.white.opacity(0.25))
                                        .frame(
                                            height: 1
                                        )
                                }
                        }
                    }
                }
            }
            if let mode = model.mode {
                VStack(alignment: .leading, spacing: 10) {
                    Text(mode.name).font(.headline).foregroundStyle(
                        theme.accent
                    )
                    Text(mode.description).font(.subheadline).foregroundStyle(
                        .white.opacity(0.8)
                    )
                    Text("ARENA  /  \(mode.arena)").font(.caption.bold())
                        .foregroundStyle(theme.highlight)
                }.frame(maxWidth: .infinity, alignment: .leading).padding()
                    .background(.white.opacity(0.08))
            }
            Spacer()
            Button {
                model.screen = .shop
            } label: {
                Label(
                    "SHOP  •  \(model.progress?.credits ?? 0) CREDITS",
                    systemImage: model.symbols.symbol(for: "credits")
                )
                .font(.headline.italic()).foregroundStyle(theme.highlight)
            }
            Button {
                model.screen = .settings
            } label: {
                Label("EINSTELLUNGEN", systemImage: "gearshape.fill")
                    .font(.headline.italic()).foregroundStyle(theme.metal)
            }
            Text("1× AUSWÄHLEN  /  2× BESTÄTIGEN").font(.caption2.bold())
                .tracking(1).foregroundStyle(.gray)
            Button("‹  ZURÜCK") { model.screen = .start }.foregroundStyle(
                .white
            )
        }.padding(theme.padding)
    }
}

private struct RosterScreen: View {
    @Environment(\.martemTheme) private var theme
    let model: GameModel
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ScreenHeader(
                title: "CHOOSE YOUR FIGHTER",
                subtitle: model.mode?.name ?? ""
            )
            Text("WÄHLE DEINEN KÄMPFER").font(.caption.bold()).tracking(2)
                .foregroundStyle(theme.metal)
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(model.catalog?.fighters ?? []) { fighter in
                    Button {
                        model.selectFighter(fighter)
                    } label: {
                        VStack(spacing: 8) {
                            FighterPortrait(
                                fighter: fighter,
                                size: 70,
                                skin: model.progress?.selectedSkin(
                                    for: fighter.id
                                )
                            )
                            if model.progress?.ownsFighter(fighter.id) != true {
                                Label("GESPERRT", systemImage: "lock.fill")
                                    .font(.caption2)
                            }
                            Text(fighter.name).font(
                                .system(size: 18, weight: .black)
                            ).italic()
                            Text(fighter.title).font(
                                .system(size: 9, weight: .bold)
                            ).tracking(1)
                        }.foregroundStyle(
                            model.selectedFighterID == fighter.id
                                ? theme.highlight : .white
                        )
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(.white.opacity(0.06))
                        .overlay(
                            Rectangle().stroke(
                                model.selectedFighterID == fighter.id
                                    ? theme.highlight
                                    : theme.accent.opacity(0.4),
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
                        theme.accent
                    )
            }
            Spacer()
            Text("ERNEUT TIPPEN, UM ZU KÄMPFEN").font(.caption2.bold())
                .tracking(1).foregroundStyle(.gray)
            Button("‹  ZURÜCK") { model.screen = .modes }.foregroundStyle(
                .white
            )
        }.padding(theme.padding)
    }
}

private struct FighterPortrait: View {
    @Environment(\.martemTheme) private var theme
    let fighter: Fighter
    let size: CGFloat
    var skin: Skin? = nil
    var tint: Color {
        switch fighter.color {
        case "orange": theme.highlight
        case "purple": .purple
        case "cyan": .cyan
        default: theme.accent
        }
    }
    var body: some View {
        ZStack {
            Circle().fill(tint.opacity(0.15))
            Circle().stroke(tint.opacity(0.7), lineWidth: 2)
            FighterImage(fighter: fighter, skin: skin)
                .padding(size * 0.08)
                .clipShape(Circle())
            if let skinSymbol = skin?.symbol, skin?.imageURL == nil,
                skinSymbol != "person.fill"
            {
                Image(systemName: skinSymbol)
                    .font(.system(size: size * 0.22, weight: .bold))
                    .foregroundStyle(.orange)
                    .shadow(color: .black, radius: 3)
                    .offset(x: size * 0.32, y: size * 0.30)
            }
        }.frame(width: size, height: size).shadow(
            color: tint.opacity(0.4),
            radius: 10
        )
    }
}

private struct HealthBar: View {
    @Environment(\.martemTheme) private var theme
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
                            colors: [theme.highlight, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: proxy.size.width * CGFloat(max(0, current))
                            / CGFloat(max(1, maximum))
                    )
                }.overlay(Rectangle().stroke(theme.metal, lineWidth: 2))
            }.frame(height: 15)
        }
    }
}

private struct BattleScreen: View {
    @Environment(\.martemTheme) private var theme
    let model: GameModel
    var body: some View {
        if let player = model.player, let enemy = model.enemy,
            let mode = model.mode, let scene = model.scene
        {
            GeometryReader { geometry in
                VStack(spacing: theme.spacing) {
                    HStack {
                        Button("‹ MENÜ") { model.leaveBattle() }.font(
                            .caption.bold()
                        )
                        Spacer()
                        Text("STAGE \(model.round) / \(mode.rounds)").font(
                            .caption.bold().monospaced()
                        ).foregroundStyle(theme.accent)
                    }
                    HealthBar(
                        name: enemy.name,
                        current: model.enemyHP,
                        maximum: model.enemyMaxHP,
                        enemy: true
                    )
                    Spacer(minLength: 0)
                    FighterPortrait(
                        fighter: enemy,
                        size: min(geometry.size.height * 0.15, 115)
                    )
                    Text(enemy.title).font(.caption2.bold()).tracking(2)
                        .foregroundStyle(theme.metal)
                    Spacer(minLength: 0)
                    Text(mode.arena).font(
                        .system(size: 10, weight: .black, design: .monospaced)
                    ).tracking(3).foregroundStyle(theme.accent)
                    Text(model.feedback).font(.system(size: 22, weight: .black))
                        .italic().foregroundStyle(theme.highlight)
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
                                    colors: [.white, theme.accent],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay(Rectangle().stroke(.white, lineWidth: 2))
                            .shadow(
                                color: theme.accent.opacity(0.5),
                                radius: 10
                            )
                    }
                    Text(
                        model.isTutorial
                            ? "ÜBUNG: TRIFF DIE ORANGE ZONE – OHNE SCHADEN"
                            : (mode.mechanic == .pulse
                                ? "TIPPE, WENN SICH DIE RINGE TREFFEN"
                                : "TIPPE IN DER LEUCHTENDEN ZONE")
                    ).font(
                        .system(size: 9, weight: .bold)
                    ).tracking(1).foregroundStyle(.gray)
                    Spacer(minLength: 0)
                    FighterPortrait(
                        fighter: player,
                        size: min(geometry.size.height * 0.15, 115),
                        skin: model.progress?.selectedSkin(
                            for: player.id
                        )
                    )
                    Text(player.title).font(.caption2.bold()).tracking(2)
                        .foregroundStyle(theme.metal)
                    Spacer(minLength: 0)
                    HealthBar(
                        name: player.name,
                        current: model.playerHP,
                        maximum: player.guardValue,
                        enemy: false
                    )
                }.padding(.horizontal, theme.padding).padding(
                    .vertical,
                    theme.spacing
                )
            }
        }
    }
}

#Preview {
    GameView()
}
