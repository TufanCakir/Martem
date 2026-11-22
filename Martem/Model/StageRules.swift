//
//  StageRules.swift
//  Martem
//
//  Created by Tufan Cakir on 21.11.26.
//

import Foundation

struct StageRules {
    let goodFraction: Double
    let perfectFraction: Double
    let enemyHP: Int
    let missDamage: Int

    static func forStage(_ stage: Int) -> StageRules {
        switch stage {
        case ...5:
            return StageRules(
                goodFraction: 0.40,
                perfectFraction: 0.20,
                enemyHP: 60 + max(0, stage - 1) * 10,
                missDamage: 8
            )
        case 6...15:
            return StageRules(
                goodFraction: 0.35,
                perfectFraction: 0.15,
                enemyHP: 100 + (stage - 6) * 60 / 9,
                missDamage: 10
            )
        default:
            return StageRules(
                goodFraction: 0.30,
                perfectFraction: 0.12,
                enemyHP: min(250, 160 + (stage - 16) * 10),
                missDamage: 13
            )
        }
    }
}
