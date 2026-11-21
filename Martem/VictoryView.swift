import SwiftUI

struct VictoryView: View {
    let model: GameModel

    private var duration: String {
        let seconds = Int(model.battleDuration)
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text(model.won ? "VICTORY" : "DEFEAT")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .italic()
                    .foregroundStyle(model.won ? .orange : .white)
                    .shadow(color: .cyan.opacity(0.7), radius: 14)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                Text(model.won ? "DEIN SIEGER" : "DER GEGNER GEWINNT")
                    .font(.caption.bold()).tracking(3).foregroundStyle(.cyan)

                if let winner = model.won ? model.player : model.enemy {
                    Image(winner.image)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .background(.white.opacity(0.06))
                        .overlay(Rectangle().stroke(.cyan.opacity(0.6), lineWidth: 2))
                        .shadow(color: .cyan.opacity(0.35), radius: 14)

                    Text(winner.name)
                        .font(.system(size: 28, weight: .black)).italic()
                    Text(winner.title)
                        .font(.caption.bold()).tracking(2).foregroundStyle(.gray)
                }

                VStack(spacing: 0) {
                    ResultRow(title: "KAMPFDAUER", value: duration)
                    ResultRow(title: "DEIN SCHADEN GESAMT", value: "\(model.damageDealt)")
                    ResultRow(title: "ERHALTENER SCHADEN", value: "\(model.damageReceived)")
                    ResultRow(title: "TREFFER", value: "\(model.hits)")
                    ResultRow(title: "PERFEKTE TREFFER", value: "\(model.perfectHits)")
                    ResultRow(title: "STAGE", value: "\(model.round) / \(model.mode?.rounds ?? 1)")
                }
                .padding(.horizontal, 16)
                .background(.white.opacity(0.07))
                .overlay(Rectangle().stroke(.white.opacity(0.2)))

                Button("▶  NOCHMAL KÄMPFEN") { model.startBattle() }
                    .font(.headline.italic()).foregroundStyle(.orange)
                    .frame(maxWidth: .infinity).padding(.top, 8)
                Button("MODUS WÄHLEN") { model.leaveBattle() }
                    .font(.headline.italic()).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.bottom, 12)
            }
            .padding(24)
            .frame(maxWidth: 500)
            .frame(maxWidth: .infinity)
        }
    }
}

private struct ResultRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title).foregroundStyle(.white.opacity(0.7))
            Spacer()
            Text(value).foregroundStyle(.white)
        }
        .font(.system(size: 12, weight: .bold, design: .monospaced))
        .padding(.vertical, 9)
        .overlay(alignment: .bottom) {
            Rectangle().fill(.white.opacity(0.12)).frame(height: 1)
        }
    }
}