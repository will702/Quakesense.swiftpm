import SpriteKit
import SwiftUI
import UIKit

// MARK: - Physics Categories

struct PhysicsCategory {
    static let none:       UInt32 = 0
    static let player:     UInt32 = 0x1 << 0
    static let furniture:  UInt32 = 0x1 << 1
    static let debris:     UInt32 = 0x1 << 2
    static let safeZone:   UInt32 = 0x1 << 3
    static let dangerZone: UInt32 = 0x1 << 4
    static let floor:      UInt32 = 0x1 << 5
    static let wall:       UInt32 = 0x1 << 6
}

// MARK: - Colors

enum AppColors {
    static let calmBackground = Color(hex: 0xFAF8F5)
    static let dangerBackground = Color(hex: 0xE5E5EA)
    static let correctAction = Color(hex: 0x34C759)
    static let wrongAction = Color(hex: 0xFF3B30)
    static let warning = Color(hex: 0xFF9500)
    static let primaryAccent = Color(hex: 0x007AFF)
    static let textPrimary = Color(hex: 0x1C1C1E)
    static let debrisDamage = Color(hex: 0x8E8E93)
    static let lightBackground = Color(hex: 0xF2F2F7)
    static let lightSurface = Color.black.opacity(0.04)
    static let cardBackground = Color.white

    // SpriteKit versions
    static let skCalmBackground = SKColor(red: 0xFA/255, green: 0xF8/255, blue: 0xF5/255, alpha: 1)
    static let skDangerBackground = SKColor(red: 0xE5/255, green: 0xE5/255, blue: 0xEA/255, alpha: 1)
    static let skCorrect = SKColor(red: 0x34/255, green: 0xC7/255, blue: 0x59/255, alpha: 1)
    static let skWrong = SKColor(red: 0xFF/255, green: 0x3B/255, blue: 0x30/255, alpha: 1)
    static let skWarning = SKColor(red: 0xFF/255, green: 0x95/255, blue: 0x00/255, alpha: 1)
}

// MARK: - Room Dimensions

enum RoomLayout {
    /// The base scene size for design reference (1024x768 = 4:3 iPad aspect ratio)
    /// Use `dynamicSceneSize(for:)` to get size appropriate for the current view bounds
    static let sceneSize = CGSize(width: 1024, height: 768)

    /// Calculates a dynamic scene size that fits within the available bounds
    /// while maintaining the 4:3 aspect ratio used for game design
    static func dynamicSceneSize(for availableSize: CGSize) -> CGSize {
        SceneSizeCalculator.calculate(for: availableSize)
    }

    /// Scale factor for adapting element sizes to different scene sizes
    static func scaleFactor(for sceneSize: CGSize) -> CGFloat {
        SceneSizeCalculator.scaleFactor(for: sceneSize)
    }

    static let floorHeight: CGFloat = 80
    static let wallThickness: CGFloat = 20
    static let tableWidth: CGFloat = 180
    static let tableHeight: CGFloat = 90
    static let bookshelfWidth: CGFloat = 80
    static let bookshelfHeight: CGFloat = 200
    static let windowWidth: CGFloat = 120
    static let windowHeight: CGFloat = 150
    static let doorWidth: CGFloat = 80
    static let doorHeight: CGFloat = 180
    static let lampSize: CGFloat = 40
    static let playerSize = CGSize(width: 40, height: 55)
}

// MARK: - Game Timing

enum GameTiming {
    static let calmDuration: TimeInterval = 3.0
    static let countdownDuration: TimeInterval = 3.0
    static let pWaveDuration: TimeInterval = 2.0
    static let sWaveDuration: TimeInterval = 6.0
    static let aftershockDuration: TimeInterval = 25.0
    static let debriefDelay: TimeInterval = 1.5

    static var totalQuakeDuration: TimeInterval {
        pWaveDuration + sWaveDuration + aftershockDuration
    }
}

// MARK: - Tilt Control

enum TiltControl {
    static let sensitivity: CGFloat = 300
    static let deadZone: CGFloat = 0.05
}

// MARK: - Intensity Thresholds

enum IntensityThreshold {
    static let booksAndSmallItems: CGFloat = 0.3
    static let pictureFrames: CGFloat = 0.5
    static let floorCracks: CGFloat = 0.6
    static let bookshelfTopple: CGFloat = 0.7
    static let windowShatter: CGFloat = 0.7
    static let ceilingLampFall: CGFloat = 0.8
}

// MARK: - High Contrast Support

@MainActor
enum HighContrast {
    /// Returns `true` when the user has enabled "Increase Contrast" in iOS Accessibility settings.
    static var isEnabled: Bool {
        UIAccessibility.isDarkerSystemColorsEnabled
    }

    /// Returns full opacity when high contrast is on, otherwise the provided default.
    static func alpha(_ normal: CGFloat) -> CGFloat {
        isEnabled ? min(normal + 0.4, 1.0) : normal
    }

    /// HUD background alpha: opaque in high contrast, translucent otherwise.
    static var hudBackgroundAlpha: CGFloat {
        isEnabled ? 1.0 : 0.75
    }

    /// HUD background stroke: visible border in high contrast, clear otherwise.
    static var hudStrokeColor: SKColor {
        isEnabled ? SKColor(white: 0, alpha: 0.6) : .clear
    }

    /// Zone label color: high-visibility white or subtle grey.
    static var zoneLabelColor: SKColor {
        isEnabled ? SKColor(white: 1, alpha: 1.0) : SKColor(white: 0.5, alpha: 0.6)
    }

    /// Aftershock glow fill alpha.
    static var glowFillAlpha: CGFloat {
        isEnabled ? 0.4 : 0.15
    }

    /// Aftershock glow stroke alpha.
    static var glowStrokeAlpha: CGFloat {
        isEnabled ? 0.9 : 0.5
    }

    /// Aftershock glow line width.
    static var glowLineWidth: CGFloat {
        isEnabled ? 3.5 : 2.0
    }
}

// MARK: - Dynamic Type Scaling for SpriteKit

@MainActor
enum DynamicTypeScale {
    /// Returns a multiplier (0.8–1.4) based on the user's preferred content size.
    /// Use this to scale SpriteKit `SKLabelNode.fontSize` proportionally.
    static var current: CGFloat {
        let category = UIApplication.shared.preferredContentSizeCategory
        switch category {
        case .extraSmall:                          return 0.8
        case .small:                               return 0.85
        case .medium:                              return 0.9
        case .large:                               return 1.0   // default
        case .extraLarge:                          return 1.1
        case .extraExtraLarge:                     return 1.2
        case .extraExtraExtraLarge:                return 1.3
        case .accessibilityMedium:                 return 1.35
        case .accessibilityLarge:                  return 1.4
        case .accessibilityExtraLarge:             return 1.45
        case .accessibilityExtraExtraLarge:        return 1.5
        case .accessibilityExtraExtraExtraLarge:   return 1.55
        default:                                   return 1.0
        }
    }

    /// Convenience: scale a base font size by the current Dynamic Type multiplier.
    static func scaled(_ base: CGFloat) -> CGFloat {
        base * current
    }
}
