//
//  GameModel.swift
//  Martem
//
//  Created by Tufan Cakir on 21.11.26.
//

import Foundation
import Observation
import SpriteKit

struct Fighter: Codable, Identifiable {
    let id: String
    let name: String
    let title: String
    let color: String
    let image: String
    let imageURL: URL?
    let power: Int
    let guardValue: Int

    enum CodingKeys: String, CodingKey {
        case id, name, title, color, image, imageURL, power
        case guardValue = "guard"
    }
}

struct BattleMode: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let arena: String
    let speed: Double
    let enemyDamage: Int
    let rounds: Int
    let mechanic: TimingMechanic?
    let suddenDeath: Bool?
    let stageReward: Int?
}

struct GameCatalog: Codable {
    let contentVersion: Int?
    let fighters: [Fighter]
    let modes: [BattleMode]

    static func load() throws -> GameCatalog {
        guard
            let url = Bundle.main.url(
                forResource: "GameData",
                withExtension: "json"
            )
        else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try decode(Data(contentsOf: url))
    }

    static func decode(_ data: Data) throws -> GameCatalog {
        let catalog = try JSONDecoder().decode(GameCatalog.self, from: data)
        guard catalog.fighters.count >= 2, !catalog.modes.isEmpty,
            catalog.fighters.allSatisfy({ $0.guardValue > 0 && $0.power > 0 }),
            catalog.modes.allSatisfy({
                $0.speed > 0 && $0.rounds > 0 && $0.enemyDamage > 0
            })
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return catalog
    }
}

@MainActor @Observable
final class GameModel {
    enum Screen {
        case loading, offline, start, modes, roster, shop, settings, battle,
            result, error
    }
    var screen: Screen = .loading
    var loadingProgress = 0.0
    var loadingMessage = "CONNECTING"
    var contentVersion = 1
    var loadedBytes = 0
    var startView = StartViewCatalog.bundled()
    var catalog: GameCatalog?
    var theme = ThemeCatalog.bundled()
    let symbols = SymbolCatalog.load()
    var progress: ProgressManager?
    let store = StoreManager()
    let musicPlayer = MusicPlayer()
    var music = MusicCatalog.bundled()
    private(set) var earnedCredits = 0
    private var missed = false
    private(set) var isTutorial = false
    private let tutorialKey = "martem.timingTutorialCompleted"
    var selectedModeID: String?
    var selectedFighterID: String?
    var playerHP = 0
    var enemyHP = 0
    var round = 1
    var feedback = "READY?"
    var feedbackKind = "hit"
    var won = false
    var scene: BattleScene?
    private var battleStart: Date?
    private(set) var battleDuration: TimeInterval = 0
    private(set) var damageDealt = 0
    private(set) var damageReceived = 0
    private(set) var timeRemaining = BattleModeRules.initialTime
    private(set) var flow = 0
    private(set) var hits = 0
    private(set) var perfectHits = 0

    var mode: BattleMode? { catalog?.modes.first { $0.id == selectedModeID } }
    var player: Fighter? {
        catalog?.fighters.first { $0.id == selectedFighterID }
    }
    var enemy: Fighter? {
        guard let fighters = catalog?.fighters, let player else { return nil }
        let opponents = fighters.filter { $0.id != player.id }
        guard !opponents.isEmpty else { return nil }
        return opponents[(round - 1) % opponents.count]
    }

    func load() async {
        screen = .loading
        loadingProgress = 0
        loadedBytes = 0
        loadingMessage = "LOADING GAME DATA"
        do {
            guard let config = RemoteConfig.load() else {
                throw URLError(.badURL)
            }
            let gameData = try await CatalogLoader.remoteData(
                config.gameDataURL,
                limit: 2_000_000
            )
            loadedBytes += gameData.count
            let game = try GameCatalog.decode(gameData)
            guard let version = game.contentVersion, version > 0 else {
                throw URLError(.cannotParseResponse)
            }
            loadingProgress = 0.25
            loadingMessage = "LOADING REWARDS"
            let rewardsData = try await CatalogLoader.remoteData(
                config.rewardsURL,
                limit: 200_000
            )
            loadedBytes += rewardsData.count
            let rewards = try RewardCatalog.decode(rewardsData)
            guard
                game.fighters.allSatisfy({ rewards.fighterPrices[$0.id] != nil }
                )
            else { throw URLError(.cannotParseResponse) }
            loadingProgress = 0.5
            loadingMessage = "LOADING THEME"
            let themeData = try await CatalogLoader.remoteData(
                config.themeURL,
                limit: 200_000
            )
            loadedBytes += themeData.count
            let loadedTheme = try JSONDecoder().decode(
                ThemeCatalog.self,
                from: themeData
            )
            guard loadedTheme.valid else {
                throw URLError(.cannotParseResponse)
            }
            loadingProgress = 0.75
            loadingMessage = "LOADING MUSIC CONFIGURATION"
            let musicData = try await CatalogLoader.remoteData(
                config.musicConfigURL,
                limit: 100_000
            )
            loadedBytes += musicData.count
            let loadedMusic = try JSONDecoder().decode(
                MusicCatalog.self,
                from: musicData
            )
            loadingMessage = "LOADING START SCREEN"
            let loadedStart: StartViewCatalog
            if let data = try? await CatalogLoader.remoteData(
                config.startViewURL,
                limit: 100_000
            ),
                let start = try? JSONDecoder().decode(
                    StartViewCatalog.self,
                    from: data
                )
            {
                loadedBytes += data.count
                loadedStart = start
            } else {
                loadedStart = .bundled()
            }
            startView = loadedStart
            catalog = game
            if let progress {
                progress.catalog = rewards
            } else {
                progress = ProgressManager(catalog: rewards)
            }
            contentVersion = version
            theme = loadedTheme
            music = loadedMusic
            loadingProgress = 1
            screen = .start
        } catch {
            loadingMessage =
                "Please check your internet connection and server data."
            screen = .offline
        }
    }

    func selectMode(_ mode: BattleMode) {
        if selectedModeID == mode.id {
            screen = .roster
        } else {
            selectedModeID = mode.id
        }
    }

    func selectFighter(_ fighter: Fighter) {
        guard progress?.ownsFighter(fighter.id) == true else { return }
        if selectedFighterID == fighter.id {
            startBattle()
        } else {
            selectedFighterID = fighter.id
        }
    }

    private var stageRules: StageRules { .forStage(round) }
    var enemyMaxHP: Int { stageRules.enemyHP }
    private var hitWindow: Double {
        mode?.suddenDeath == true
            ? max(0.055, stageRules.goodFraction / 2 - Double(round - 1) * 0.02)
            : stageRules.goodFraction / 2
    }
    private var perfectWindow: Double {
        min(stageRules.perfectFraction / 2, hitWindow * 0.5)
    }

    func startBattle() {
        round = 1
        timeRemaining = BattleModeRules.initialTime
        flow = 0
        earnedCredits = 0
        missed = false
        damageDealt = 0
        damageReceived = 0
        hits = 0
        perfectHits = 0
        battleDuration = 0
        isTutorial = !UserDefaults.standard.bool(forKey: tutorialKey)
        battleStart = isTutorial ? nil : Date()
        startRound()
    }

    private func startRound() {
        guard let player, enemy != nil, let mode else { return }
        if round == 1 || !BattleModeRules.isSurvival(mode.id) {
            playerHP = player.guardValue
        }
        enemyHP = enemyMaxHP
        feedbackKind = "hit"
        feedback = isTutorial ? "PRACTICE: HIT THE ORANGE ZONE" : "HIT THE ZONE"
        let newScene = BattleScene(
            size: CGSize(width: 400, height: 120),
            speed: mode.speed,
            mechanic: isTutorial ? .marker : (mode.mechanic ?? .marker),
            hitWindow: hitWindow,
            perfectWindow: perfectWindow,
            visualTheme: theme.values(for: mode.id)
        )
        newScene.onMiss = { [weak self] in self?.receiveHit() }
        newScene.onTick = { [weak self] delta in self?.tick(delta) }
        scene = newScene
        screen = .battle
    }

    func attack() {
        guard screen == .battle, let scene, player != nil else { return }
        guard let accuracy = scene.strike() else { return }
        if isTutorial {
            if accuracy < perfectWindow {
                UserDefaults.standard.set(true, forKey: tutorialKey)
                isTutorial = false
                scene.isPaused = true
                battleStart = Date()
                startRound()
            } else {
                feedback = "PRACTICE: HIT THE ORANGE ZONE"
            }
            return
        }
        if accuracy < hitWindow {
            let perfect = accuracy < perfectWindow
            let damage =
                mode.map { BattleModeRules.isSuddenDeath($0.id) } == true
                ? enemyHP : (perfect ? 30 : 15)
            if let mode, BattleModeRules.isTimeAttack(mode.id), perfect {
                timeRemaining += BattleModeRules.perfectTimeBonus
            }
            if let mode, BattleModeRules.isOverdrive(mode.id) {
                flow = min(100, flow + (perfect ? 20 : 10))
            }
            damageDealt += min(enemyHP, damage)
            hits += 1
            if perfect { perfectHits += 1 }
            enemyHP = max(0, enemyHP - damage)
            feedbackKind = perfect ? "perfect" : "good"
            feedback =
                perfect ? "PERFECT  •  \(damage)" : "HIT  •  \(damage)"
            if enemyHP == 0 {
                completeRound()
            }
        } else {
            receiveHit()
        }
    }

    private func receiveHit() {
        guard screen == .battle, let mode else { return }
        if isTutorial {
            feedback = "PRACTICE: NO DAMAGE"
            return
        }
        if BattleModeRules.isTraining(mode.id) {
            feedback = "TRAINING: NO DAMAGE"
            return
        }
        missed = true
        if BattleModeRules.isOverdrive(mode.id) { flow = 0 }
        if BattleModeRules.isTimeAttack(mode.id) {
            timeRemaining = max(
                0,
                timeRemaining - BattleModeRules.missTimePenalty
            )
            if timeRemaining == 0 {
                finishBattle(won: false)
                return
            }
        }
        let damage = mode.suddenDeath == true ? playerHP : stageRules.missDamage
        damageReceived += min(playerHP, damage)
        playerHP = max(0, playerHP - damage)
        feedbackKind = "miss"
        feedback = "MISS  •  -\(damage)"
        if playerHP == 0 {
            finishBattle(won: false)
        }
    }

    private func tick(_ delta: TimeInterval) {
        guard screen == .battle, !isTutorial, let mode,
            BattleModeRules.isTimeAttack(mode.id)
        else { return }
        timeRemaining = max(0, timeRemaining - delta)
        if timeRemaining == 0 { finishBattle(won: false) }
    }

    private func completeRound() {
        guard let mode else { return }
        scene?.isPaused = true
        if BattleModeRules.isTraining(mode.id) {
            startRound()
            return
        }
        if let reward = mode.stageReward {
            grant(reward)
        } else if mode.id == "arcade", let rules = progress?.catalog.rewards {
            grant(rules.arcadeStage)
        }
        if round < mode.rounds {
            round += 1
            startRound()
        } else {
            finishBattle(won: true)
        }
    }

    private func finishBattle(won: Bool) {
        scene?.isPaused = true
        guard screen == .battle else { return }
        self.won = won
        if let mode, mode.id != "training",
            let rules = progress?.catalog.rewards
        {
            if won {
                if mode.id == "duel" { grant(rules.duelWin) }
                if !missed { grant(rules.noMiss) }
                if let player { progress?.recordWin(fighterID: player.id) }
            } else {
                grant(rules.loss)
            }
        }
        battleDuration = max(
            0,
            battleStart.map { Date().timeIntervalSince($0) } ?? 0
        )
        battleStart = nil
        screen = .result
    }

    private func grant(_ amount: Int) {
        progress?.award(amount)
        earnedCredits += amount
    }

    func leaveBattle() {
        scene?.isPaused = true
        scene = nil
        screen = .modes
    }
}
