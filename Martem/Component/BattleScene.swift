//
//  BattleScene.swift
//  Martem
//
//  Created by Tufan Cakir on 21.11.26.
//

import SpriteKit

enum TimingMechanic: String, Codable {
    case marker, pulse, dual
}

@MainActor
final class BattleScene: SKScene {
    var onMiss: (() -> Void)?
    private let timingSpeed: Double
    private let mechanic: TimingMechanic
    private let hitWindow: Double
    private let perfectWindow: Double
    private let marker = SKShapeNode(
        rectOf: CGSize(width: 5, height: 66),
        cornerRadius: 2
    )
    private let ring = SKShapeNode(circleOfRadius: 42)
    private var elapsed = 0.0
    private var previousTime: TimeInterval?
    private var resolved = false

    init(
        size: CGSize,
        speed: Double,
        mechanic: TimingMechanic = .marker,
        hitWindow: Double = 0.20,
        perfectWindow: Double = 0.10
    ) {
        self.timingSpeed = speed
        self.mechanic = mechanic
        self.hitWindow = hitWindow
        self.perfectWindow = perfectWindow
        super.init(size: size)
        scaleMode = .aspectFit
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { nil }

    override func didMove(to view: SKView) {
        removeAllChildren()
        if mechanic == .pulse {
            let target = SKShapeNode(circleOfRadius: 42)
            target.position = CGPoint(x: size.width / 2, y: size.height / 2)
            target.strokeColor = .orange
            target.lineWidth = 6
            addChild(target)
            ring.position = target.position
            ring.strokeColor = .cyan
            ring.lineWidth = 4
            ring.glowWidth = 4
            addChild(ring)
        } else {
            let track = SKShapeNode(
                rectOf: CGSize(width: 320, height: 20),
                cornerRadius: 3
            )
            track.fillColor = .init(white: 0.12, alpha: 1)
            track.strokeColor = .lightGray
            track.position = CGPoint(x: size.width / 2, y: size.height / 2)
            addChild(track)
            let centers: [Double] = mechanic == .dual ? [0.3, 0.7] : [0.5]
            for center in centers {
                let zone = SKShapeNode(
                    rectOf: CGSize(width: 320 * hitWindow * 2, height: 20)
                )
                zone.position.x = 320 * (center - 0.5)
                zone.fillColor = .init(
                    red: 0.08,
                    green: 0.65,
                    blue: 0.85,
                    alpha: 0.5
                )
                zone.strokeColor = .clear
                track.addChild(zone)
                let perfect = SKShapeNode(
                    rectOf: CGSize(width: 320 * perfectWindow * 2, height: 20)
                )
                perfect.fillColor = .orange
                perfect.strokeColor = .clear
                zone.addChild(perfect)
            }
            marker.fillColor = .white
            marker.strokeColor = .cyan
            marker.glowWidth = 5
            addChild(marker)
        }
    }

    override func update(_ currentTime: TimeInterval) {
        defer { previousTime = currentTime }
        guard let previousTime else { return }
        elapsed += min(currentTime - previousTime, 0.1) * timingSpeed
        if elapsed >= 1 {
            elapsed.formTruncatingRemainder(dividingBy: 1)
            let missed = !resolved
            resolved = false
            if missed { onMiss?() }
        }
        marker.position = CGPoint(
            x: size.width / 2 - 160 + 320 * elapsed,
            y: size.height / 2
        )
        ring.setScale(CGFloat(1.75 - 1.5 * elapsed))
    }

    func strike() -> Double? {
        guard !resolved else { return nil }
        resolved = true
        return mechanic == .dual
            ? min(abs(elapsed - 0.3), abs(elapsed - 0.7)) : abs(elapsed - 0.5)
    }
}
