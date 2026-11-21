import Foundation
import Observation
import SpriteKit

struct Fighter: Codable, Identifiable {
    let id: String
    let name: String
    let title: String
    let color: String
    let image: String
    let power: Int
    let guardValue: Int

    enum CodingKeys: String, CodingKey {
        case id, name, title, color, image, power
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
}

struct GameCatalog: Codable {
    let fighters: [Fighter]
    let modes: [BattleMode]

    static func load() throws -> GameCatalog {
        guard let url = Bundle.main.url(forResource: "GameData", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        let catalog = try JSONDecoder().decode(GameCatalog.self, from: Data(contentsOf: url))
        guard catalog.fighters.count >= 2, !catalog.modes.isEmpty,
              catalog.fighters.allSatisfy({ $0.guardValue > 0 && $0.power > 0 }),
              catalog.modes.allSatisfy({ $0.speed > 0 && $0.rounds > 0 && $0.enemyDamage > 0 }) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return catalog
    }
}

@MainActor @Observable
final class GameModel {
    enum Screen { case start, modes, roster, battle, result, error }
    var screen: Screen = .start
    var catalog: GameCatalog?
    var selectedModeID: String?
    var selectedFighterID: String?
    var playerHP = 0
    var enemyHP = 0
    var round = 1
    var feedback = "BEREIT?"
    var won = false
    var scene: BattleScene?
    private var battleStart: Date?
    private(set) var battleDuration: TimeInterval = 0
    private(set) var damageDealt = 0
    private(set) var damageReceived = 0
    private(set) var hits = 0
    private(set) var perfectHits = 0

    var mode: BattleMode? { catalog?.modes.first { $0.id == selectedModeID } }
    var player: Fighter? { catalog?.fighters.first { $0.id == selectedFighterID } }
    var enemy: Fighter? {
        guard let fighters = catalog?.fighters, let player else { return nil }
        let opponents = fighters.filter { $0.id != player.id }
        guard !opponents.isEmpty else { return nil }
        return opponents[(round - 1) % opponents.count]
    }

    func load() {
        do { catalog = try GameCatalog.load() }
        catch { screen = .error }
    }

    func selectMode(_ mode: BattleMode) {
        if selectedModeID == mode.id { screen = .roster }
        else { selectedModeID = mode.id }
    }

    func selectFighter(_ fighter: Fighter) {
        if selectedFighterID == fighter.id { startBattle() }
        else { selectedFighterID = fighter.id }
    }

    func startBattle() {
        round = 1
        damageDealt = 0
        damageReceived = 0
        hits = 0
        perfectHits = 0
        battleDuration = 0
        battleStart = Date()
        startRound()
    }

    private func startRound() {
        guard let player, let enemy, let mode else { return }
        playerHP = player.guardValue
        enemyHP = enemy.guardValue
        feedback = "TRIFF DIE ZONE"
        let newScene = BattleScene(size: CGSize(width: 400, height: 120), speed: mode.speed)
        newScene.onMiss = { [weak self] in self?.receiveHit() }
        scene = newScene
        screen = .battle
    }

    func attack() {
        guard screen == .battle, let scene, let player else { return }
        guard let accuracy = scene.strike() else { return }
        if accuracy < 0.16 {
            let perfect = accuracy < 0.065
            let damage = perfect ? player.power + 10 : player.power
            damageDealt += min(enemyHP, damage)
            hits += 1
            if perfect { perfectHits += 1 }
            enemyHP = max(0, enemyHP - damage)
            feedback = perfect ? "PERFECT  •  \(damage)" : "TREFFER  •  \(damage)"
            if enemyHP == 0 {
                completeRound()
            }
        } else {
            receiveHit()
        }
    }

    private func receiveHit() {
        guard screen == .battle, let mode else { return }
        damageReceived += min(playerHP, mode.enemyDamage)
        playerHP = max(0, playerHP - mode.enemyDamage)
        feedback = "DANEBEN  •  -\(mode.enemyDamage)"
        if playerHP == 0 {
            finishBattle(won: false)
        }
    }

    private func completeRound() {
        guard let mode else { return }
        scene?.isPaused = true
        if round < mode.rounds {
            round += 1
            startRound()
        } else {
            finishBattle(won: true)
        }
    }

    private func finishBattle(won: Bool) {
        scene?.isPaused = true
        self.won = won
        battleDuration = max(0, battleStart.map { Date().timeIntervalSince($0) } ?? 0)
        battleStart = nil
        screen = .result
    }

    func leaveBattle() {
        scene?.isPaused = true
        scene = nil
        screen = .modes
    }
}