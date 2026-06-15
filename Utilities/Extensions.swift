import SwiftUI
import SpriteKit

// MARK: - Color Hex Initializer

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}

// MARK: - CGPoint Helpers

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        let dx = x - point.x
        let dy = y - point.y
        return sqrt(dx * dx + dy * dy)
    }

    static func random(in rect: CGRect) -> CGPoint {
        CGPoint(
            x: CGFloat.random(in: rect.minX...rect.maxX),
            y: CGFloat.random(in: rect.minY...rect.maxY)
        )
    }
}

// MARK: - SKNode Helpers

extension SKNode {
    func pulse(scale: CGFloat = 1.3, duration: TimeInterval = 0.3) {
        let scaleUp = SKAction.scale(to: scale, duration: duration / 2)
        let scaleDown = SKAction.scale(to: 1.0, duration: duration / 2)
        scaleUp.timingMode = .easeOut
        scaleDown.timingMode = .easeIn
        run(SKAction.sequence([scaleUp, scaleDown]))
    }

    func flash(color: SKColor, duration: TimeInterval = 0.3) {
        let colorize = SKAction.colorize(with: color, colorBlendFactor: 0.8, duration: duration / 2)
        let decolorize = SKAction.colorize(withColorBlendFactor: 0.0, duration: duration / 2)
        run(SKAction.sequence([colorize, decolorize]))
    }

    func fadeOutAndRemove(duration: TimeInterval = 0.5) {
        run(SKAction.sequence([
            SKAction.fadeOut(withDuration: duration),
            SKAction.removeFromParent()
        ]))
    }
}

// MARK: - CGFloat Helpers

extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Float Helpers

extension Float {
    func clamped(to range: ClosedRange<Float>) -> Float {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Double Helpers

extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - SKEmitterNode Helpers

extension SKEmitterNode {
    /// Automatically removes the emitter after its particles have faded
    func autoRemove(after duration: TimeInterval? = nil) {
        let waitDuration = duration ?? TimeInterval(particleLifetime + particleLifetimeRange)
        let wait = SKAction.wait(forDuration: waitDuration + 0.5)
        let remove = SKAction.removeFromParent()
        run(SKAction.sequence([wait, remove]))
    }
    
    /// Stops emission and removes the emitter after existing particles fade
    func stopAndRemove() {
        particleBirthRate = 0
        autoRemove()
    }
}
