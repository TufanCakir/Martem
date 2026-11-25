//
//  VictoryView.swift
//  Martem
//
//  Created by Tufan Cakir on 21.11.26.
//

import SwiftUI

struct VictoryView: View {

    @Environment(\.martemTheme) private var theme

    let model: GameModel

    private var duration: String {
        let seconds = Int(model.battleDuration)
        return String(
            format: "%02d:%02d",
            seconds / 60,
            seconds % 60
        )
    }

    var body: some View {
        VStack(spacing: 12) {

            header

            if let winner = model.won ? model.player : model.enemy {
                HStack(spacing: 16) {

                    FighterImage(
                        fighter: winner,
                        skin: model.won
                            ? model.progress?.selectedSkin(for: winner.id)
                            : nil
                    )
                    .frame(width: 88, height: 88)
                    .background(theme.surface)
                    .overlay {
                        Rectangle()
                            .stroke(
                                theme.metal,
                                lineWidth: theme.number("borderWidth")
                            )
                    }

                    VStack(alignment: .leading, spacing: 4) {

                        Text("WINNER")
                            .font(.caption2.bold())
                            .tracking(2)
                            .foregroundStyle(theme.accent)

                        Text(winner.name)
                            .font(.system(size: 24, weight: .black))
                            .italic()
                            .foregroundStyle(.white)

                        if !winner.title.isEmpty {
                            Text(winner.title)
                                .font(.caption2.bold())
                                .foregroundStyle(theme.secondaryText)
                        }
                    }

                    Spacer(minLength: 0)
                }
            }

            statistics

            Spacer(minLength: 0)

            footer
        }
        .padding(16)
        .frame(maxWidth: 500)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 4) {

            Text(model.won ? "VICTORY" : "DEFEAT")
                .font(.system(size: 36, weight: .black))
                .italic()
                .foregroundStyle(
                    theme.feedbackColor(
                        model.won ? "victory" : "defeat"
                    )
                )
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text("BATTLE COMPLETE")
                .font(.caption2.bold())
                .tracking(3)
                .foregroundStyle(theme.accent)
        }
    }

    // MARK: - Statistics

    private var statistics: some View {
        VStack(spacing: 0) {

            ResultRow(
                title: "CREDITS EARNED",
                value: "+\(model.earnedCredits)"
            )

            ResultRow(
                title: "BATTLE TIME",
                value: duration
            )

            ResultRow(
                title: "DAMAGE DEALT",
                value: "\(model.damageDealt)"
            )

            ResultRow(
                title: "DAMAGE TAKEN",
                value: "\(model.damageReceived)"
            )

            ResultRow(
                title: "HITS",
                value: "\(model.hits)"
            )

            ResultRow(
                title: "PERFECT HITS",
                value: "\(model.perfectHits)"
            )

            ResultRow(
                title: "STAGE",
                value: "\(model.round) / \(model.mode?.rounds ?? 1)"
            )
        }
        .padding(.horizontal, 12)
        .background(theme.surface)
        .overlay {
            Rectangle()
                .stroke(
                    theme.border,
                    lineWidth: theme.number("borderWidth")
                )
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 4) {

            Button {
                model.startBattle()
            } label: {
                Text("▶ FIGHT AGAIN")
                    .font(.system(size: 18, weight: .black))
                    .italic()
                    .foregroundStyle(theme.highlight)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }

            Button {
                model.leaveBattle()
            } label: {
                Text("SELECT MODE")
                    .font(.subheadline.bold())
                    .italic()
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Result Row

private struct ResultRow: View {

    @Environment(\.martemTheme) private var theme

    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {

            Text(title)
                .foregroundStyle(theme.secondaryText)

            Spacer(minLength: 0)

            Text(value)
                .foregroundStyle(.white)
                .monospacedDigit()
        }
        .font(.system(size: 12, weight: .bold, design: .monospaced))
        .padding(.vertical, 7)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(theme.border)
                .frame(height: 1)
        }
    }
}
