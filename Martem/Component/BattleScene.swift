//
//  BattleScene.swift
//  Martem
//
//  Created by Tufan Cakir on 21.11.26.
//

import SpriteKit
import SwiftUI

enum TimingMechanic: String, Codable {
    case marker, pulse, dual
}

@MainActor
final class BattleScene: SKScene {
    var onMiss: (() -> Void)?
    var onTick: ((TimeInterval) -> Void)?
    private let timingSpeed: Double
    private let mechanic: TimingMechanic
    private let hitWindow: Double
    private let perfectWindow: Double
    private let visualTheme: ThemeValues
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
        perfectWindow: Double = 0.10,
        visualTheme: ThemeValues
    ) {
        self.timingSpeed = speed
        self.mechanic = mechanic
        self.hitWindow = hitWindow
        self.perfectWindow = perfectWindow
        self.visualTheme = visualTheme
        super.init(size: size)
        scaleMode = .aspectFill
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { nil }

    override func didMove(to view: SKView) {
        view.backgroundColor = .clear
        view.isOpaque = false
        view.allowsTransparency = true
        removeAllChildren()
        if mechanic == .pulse {
            let target = SKShapeNode(circleOfRadius: 42)
            target.position = CGPoint(x: size.width / 2, y: size.height / 2)
            target.strokeColor = UIColor(
                visualTheme.componentColor("targetRing", fallback: "highlight")
            )
            target.lineWidth = visualTheme.number("timingLineWidth") * 3
            addChild(target)
            ring.position = target.position
            ring.strokeColor = UIColor(
                visualTheme.componentColor("pulseRing", fallback: "accent")
            )
            ring.lineWidth = visualTheme.number("timingLineWidth") * 2
            ring.glowWidth = visualTheme.number("timingGlow")
            addChild(ring)
        } else {
            let track = SKShapeNode(
                rectOf: CGSize(width: 320, height: 20),
                cornerRadius: 3
            )
            track.fillColor = UIColor(
                visualTheme.componentColor(
                    "trackBackground",
                    fallback: "surface"
                )
            )
            track.strokeColor = UIColor(
                visualTheme.componentColor("trackBorder", fallback: "metal")
            )
            track.lineWidth = visualTheme.number("timingLineWidth")
            track.position = CGPoint(x: size.width / 2, y: size.height / 2)
            addChild(track)
            let centers: [Double] = mechanic == .dual ? [0.3, 0.7] : [0.5]
            for center in centers {
                let zone = SKShapeNode(
                    rectOf: CGSize(width: 320 * hitWindow * 2, height: 20)
                )
                zone.position.x = 320 * (center - 0.5)
                zone.fillColor = UIColor(
                    visualTheme.componentColor("hitZone", fallback: "accent")
                ).withAlphaComponent(visualTheme.number("hitZoneOpacity"))
                zone.strokeColor = .clear
                track.addChild(zone)
                let perfect = SKShapeNode(
                    rectOf: CGSize(width: 320 * perfectWindow * 2, height: 20)
                )
                perfect.fillColor = UIColor(
                    visualTheme.componentColor(
                        "perfectZone",
                        fallback: "highlight"
                    )
                )
                perfect.strokeColor = .clear
                zone.addChild(perfect)
            }
            marker.fillColor = UIColor(
                visualTheme.componentColor(
                    "timingMarker",
                    fallback: "primaryText"
                )
            )
            marker.strokeColor = UIColor(
                visualTheme.componentColor("markerBorder", fallback: "accent")
            )
            marker.lineWidth = visualTheme.number("timingLineWidth")
            marker.glowWidth = visualTheme.number("timingGlow")
            addChild(marker)
        }
    }

    override func update(_ currentTime: TimeInterval) {
        defer { previousTime = currentTime }
        guard let previousTime else { return }
        let delta = max(0, min(currentTime - previousTime, 0.1))
        onTick?(delta)
        guard !isPaused else { return }
        elapsed += delta * timingSpeed
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
