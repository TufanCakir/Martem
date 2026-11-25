//
//  BattleModeRules.swift
//  Martem
//
//  Created by Tufan Cakir on 21.11.26.
//

import Foundation

enum BattleModeRules {
    static func isSurvival(_ id: String) -> Bool { id == "survival" }
    static func isTimeAttack(_ id: String) -> Bool { id == "time_attack" }
    static func isOverdrive(_ id: String) -> Bool { id == "overdrive" }
    static func isTraining(_ id: String) -> Bool { id == "training" }
    static func isSuddenDeath(_ id: String) -> Bool { id == "sudden" }
    static let initialTime = 60.0
    static let perfectTimeBonus = 2.0
    static let missTimePenalty = 3.0
}
