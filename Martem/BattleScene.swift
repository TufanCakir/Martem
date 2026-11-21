import SpriteKit

/// Owns the moving timing marker and resolves missed cycles independently of the UI.
@MainActor
final class BattleScene: SKScene {
    var onMiss: (() -> Void)?
    private let timingSpeed: Double
    private let marker = SKShapeNode(rectOf: CGSize(width: 5, height: 66), cornerRadius: 2)
    private var elapsed = 0.0
    private var previousTime: TimeInterval?
    private var resolved = false

    init(size: CGSize, speed: Double) {
        self.timingSpeed = speed
        super.init(size: size)
        scaleMode = .aspectFit
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { nil }

    override func didMove(to view: SKView) {
        removeAllChildren()
        let track = SKShapeNode(rectOf: CGSize(width: 320, height: 20), cornerRadius: 3)
        track.fillColor = .init(white: 0.12, alpha: 1)
        track.strokeColor = .lightGray
        track.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(track)

        let zone = SKShapeNode(rectOf: CGSize(width: 102, height: 20))
        zone.fillColor = .init(red: 0.08, green: 0.65, blue: 0.85, alpha: 0.5)
        zone.strokeColor = .clear
        track.addChild(zone)

        let perfect = SKShapeNode(rectOf: CGSize(width: 42, height: 20))
        perfect.fillColor = .orange
        perfect.strokeColor = .clear
        track.addChild(perfect)

        marker.fillColor = .white
        marker.strokeColor = .cyan
        marker.glowWidth = 5
        addChild(marker)
    }

    override func update(_ currentTime: TimeInterval) {
        defer { previousTime = currentTime }
        guard let previousTime else { return }
        elapsed += min(currentTime - previousTime, 0.1) * timingSpeed
        if elapsed >= 1 {
            elapsed.formTruncatingRemainder(dividingBy: 1)
            if !resolved { onMiss?() }
            resolved = false
        }
        marker.position = CGPoint(x: size.width / 2 - 160 + 320 * elapsed, y: size.height / 2)
    }

    func strike() -> Double? {
        guard !resolved else { return nil }
        let distance = abs(elapsed - 0.5)
        resolved = true
        return distance
    }
}