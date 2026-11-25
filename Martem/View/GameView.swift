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
                    message: model.loadingMessage,
                    bytes: model.loadedBytes
                )
            case .offline:
                OfflineView(message: model.loadingMessage) {
                    Task { await prepare() }
                }
            case .start:
                StartScreen(config: model.startView) { model.screen = .modes }
            case .modes: ModeScreen(model: model)
            case .roster: RosterScreen(model: model)
            case .shop: ShopView(model: model)
            case .settings: SettingsView(model: model)
            case .battle: BattleScreen(model: model)
            case .result: VictoryView(model: model)
            case .error:
                Text("FAILED TO LOAD GAME DATA")
                    .font(.headline).foregroundStyle(.white).padding()
            }
            if !connection.connected && model.screen != .loading
                && model.screen != .offline
            {
                OfflineView(
                    message:
                        "Internet connection lost. The battle is paused."
                ) { Task { await prepare() } }
            }
        }
        .environment(\.contentVersion, model.contentVersion)
        .environment(
            \.martemTheme,
            model.theme.values(
                for: (model.screen == .battle || model.screen == .result)
                    ? model.mode?.id : nil
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
    let arena: String?
    var body: some View {
        ZStack {
            Color.black
            if let arena {
                BattleShaderBackground(arena: arena)
            }
        }
        .ignoresSafeArea()
    }
}
struct ScreenHeader: View {
    @Environment(\.martemTheme) private var theme
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: theme.number("extraSmallSpacing"))
        {
            Text(subtitle).font(
                .system(size: 10, weight: .bold, design: .monospaced)
            ).tracking(3).foregroundStyle(theme.accent)
            Text(title).font(
                .system(
                    size: theme.number("screenTitle"),
                    weight: .black,
                    design: .rounded
                )
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
    @Environment(\.contentVersion) private var contentVersion
    let config: StartViewCatalog
    let start: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            if let base = RemoteConfig.load()?.assetsBaseURL,
                let url = URL(string: config.logo, relativeTo: base)?
                    .absoluteURL,
                url.scheme?.lowercased() == "https",
                let versioned = CatalogLoader.versioned(
                    url,
                    version: contentVersion
                )
            {
                CachedRemoteImage(url: versioned) {
                    fallbackLogo
                }
                .frame(height: 150)
            } else {
                fallbackLogo
            }
            Text(config.subtitle)
                .font(.caption2.bold())
                .tracking(1)
                .multilineTextAlignment(.center)
                .foregroundStyle(theme.accent)
                .padding(.top, 12)
            Spacer()
            Text("PRESS TO START")
                .font(.system(size: 20, weight: .black))
                .italic()
                .tracking(2)
                .foregroundStyle(theme.highlight)
            Spacer().frame(height: 30)
            Text(
                "© \(Calendar.current.component(.year, from: .now)) Tufan Cakir"
            )
            .font(.caption2)
            .foregroundStyle(.secondary)
            Text(
                "Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–") · Build \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "–")"
            )
            .font(.caption2.monospaced())
            .foregroundStyle(.secondary)
            .padding(.top, 4)
            Spacer().frame(height: 16)
        }
        .padding(.horizontal, 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture(perform: start)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            start()
        }
    }
    private var fallbackLogo: some View {
        Text("MARTEM")
            .font(.system(size: 48, weight: .black))
            .italic()
            .foregroundStyle(theme.metal)
    }
}

private struct ModeScreen: View {

    @Environment(\.martemTheme) private var theme

    let model: GameModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            ScreenHeader(
                title: "SELECT MODE",
                subtitle: "MARTEM / BATTLE SYSTEM"
            )

            VStack(spacing: 0) {
                ForEach(model.catalog?.modes ?? []) { mode in

                    let selected = model.selectedModeID == mode.id

                    Button {
                        model.selectMode(mode)
                    } label: {
                        HStack(spacing: 10) {

                            Text(selected ? "▶" : "■")
                                .font(.system(size: 12))
                                .foregroundStyle(
                                    selected
                                        ? theme.highlight
                                        : theme.accent
                                )

                            Text(mode.name)
                                .font(.system(size: 20, weight: .black))
                                .italic()
                                .foregroundStyle(
                                    selected
                                        ? theme.highlight
                                        : .white
                                )

                            Spacer(minLength: 0)
                        }
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(theme.border)
                                .frame(height: 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(
                        selected ? .isSelected : []
                    )
                }
            }

            if let mode = model.mode {
                VStack(alignment: .leading, spacing: 6) {

                    Text(mode.name)
                        .font(.subheadline.bold())
                        .foregroundStyle(theme.accent)

                    Text(mode.description)
                        .font(.caption)
                        .foregroundStyle(theme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("ARENA / \(mode.arena)")
                        .font(.caption2.bold())
                        .foregroundStyle(theme.highlight)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(theme.surface)
            }

            Spacer(minLength: 0)

            footer
        }
        .padding()
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 8) {

            Text("TAP TO SELECT / TAP AGAIN TO CONFIRM")
                .font(.caption2.bold())
                .tracking(1)
                .foregroundStyle(theme.secondaryText)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)

            Divider()

            HStack(spacing: 12) {

                Button {
                    model.screen = .shop
                } label: {
                    Label(
                        "SHOP · \(model.progress?.credits ?? 0)",
                        systemImage: model.symbols.symbol(
                            for: "credits"
                        )
                    )
                    .foregroundStyle(theme.highlight)
                    .frame(minHeight: 44)
                }

                Spacer(minLength: 0)

                Button {
                    model.screen = .settings
                } label: {
                    Label(
                        "SETTINGS",
                        systemImage: "gearshape.fill"
                    )
                    .foregroundStyle(theme.metal)
                    .frame(minHeight: 44)
                }
            }
            .font(.subheadline.bold().italic())
            .buttonStyle(.plain)

            Button("‹ BACK") {
                model.screen = .start
            }
            .font(.caption.bold())
            .foregroundStyle(.white)
            .frame(minHeight: 44)
            .buttonStyle(.plain)
        }
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
            Text("SELECT YOUR FIGHTER").font(.caption.bold()).tracking(2)
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
                                Label("LOCKED", systemImage: "lock.fill")
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
                        .frame(maxWidth: .infinity).padding(
                            .vertical,
                            theme.number("largeSpacing")
                        )
                        .accessibilityAddTraits(
                            model.selectedFighterID == fighter.id
                                ? .isSelected : []
                        )
                        .background(theme.surface)
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
            Text("TAP AGAIN TO FIGHT").font(.caption2.bold())
                .tracking(1).foregroundStyle(.gray)
            Button("‹  BACK") { model.screen = .modes }.foregroundStyle(
                .white
            )
        }.padding(theme.padding)
    }
}
struct FighterPortrait: View {
    @Environment(\.martemTheme) private var theme
    let fighter: Fighter
    let size: CGFloat
    var skin: Skin? = nil
    var tint: Color {
        theme.fighterColor(fighter.color)
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
                    .foregroundStyle(theme.fighterColor(fighter.color))
                    .shadow(color: .black, radius: 3)
                    .offset(x: size * 0.32, y: size * 0.30)
            }
        }.frame(width: size, height: size).shadow(
            color: tint.opacity(0.4),
            radius: 10
        )
    }
}
struct HealthBar: View {
    @Environment(\.martemTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
                            colors: [
                                theme.color(
                                    current * 4 <= maximum
                                        ? "healthCritical" : "healthNormal"
                                ), theme.color("healthDamage"),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: proxy.size.width * CGFloat(max(0, current))
                            / CGFloat(max(1, maximum))
                    )
                }.overlay(
                    Rectangle().stroke(
                        theme.metal,
                        lineWidth: theme.number("borderWidth")
                    )
                )
                .animation(
                    reduceMotion
                        ? nil
                        : .easeOut(duration: theme.number("damageDuration")),
                    value: current
                )
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
                        Button("‹ MENU") { model.leaveBattle() }.font(
                            .caption.bold()
                        )
                        Spacer()
                        Text(
                            BattleModeRules.isSurvival(mode.id)
                                ? "WAVE \(model.round)"
                                : "STAGE \(model.round) / \(mode.rounds)"
                        ).font(
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
                    if BattleModeRules.isTimeAttack(mode.id) {
                        Text("TIME  \(Int(model.timeRemaining.rounded(.up))) s")
                            .font(
                                .system(
                                    size: theme.number("timerSize"),
                                    weight: .bold,
                                    design: .monospaced
                                )
                            ).monospacedDigit().foregroundStyle(
                                theme.color("timer")
                            )
                    }
                    if BattleModeRules.isOverdrive(mode.id) {
                        Text("FLOW  \(model.flow)%").font(
                            .headline.monospacedDigit()
                        )
                        ProgressView(value: Double(model.flow), total: 100)
                            .tint(theme.color("flow"))
                    }
                    Text(model.feedback).font(
                        .system(
                            size: theme.number("combatFeedback"),
                            weight: .black
                        )
                    )
                    .italic().foregroundStyle(
                        theme.feedbackColor(model.feedbackKind)
                    )
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
                            ? "PRACTICE: HIT THE ORANGE ZONE – NO DAMAGE"
                            : (mode.mechanic == .pulse
                                ? "TAP WHEN THE RINGS ALIGN"
                                : "TAP WHEN THE MARKER REACHES THE GLOWING ZONE")
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
