import Foundation
import SpriteKit
import SwiftUI

// MARK: - Scenario Type

/// Defines the type of earthquake scenario with unique gameplay characteristics
enum ScenarioType: String, CaseIterable, Sendable, Identifiable {
    case standard
    case night
    case aftershockHeavy
    case rapidEscalation
    case surpriseQuake
    case trainingMode

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .standard: return String(localized: "Standard")
        case .night: return String(localized: "Nighttime")
        case .aftershockHeavy: return String(localized: "Aftershocks")
        case .rapidEscalation: return String(localized: "Rapid Escalation")
        case .surpriseQuake: return String(localized: "Surprise Quake")
        case .trainingMode: return String(localized: "Training Mode")
        }
    }

    var description: String {
        switch self {
        case .standard:
            return String(localized: "Classic earthquake experience with normal timing and visibility.")
        case .night:
            return String(localized: "Earthquake strikes at night. Reduced visibility makes decisions harder.")
        case .aftershockHeavy:
            return String(localized: "Multiple major aftershocks extend the danger period.")
        case .rapidEscalation:
            return String(localized: "P-wave to S-wave transition happens almost instantly. React fast!")
        case .surpriseQuake:
            return String(localized: "No warning or countdown. The earthquake starts immediately!")
        case .trainingMode:
            return String(localized: "Gentle practice mode with slower debris and longer decision windows.")
        }
    }

    var icon: String {
        switch self {
        case .standard: return "house.fill"
        case .night: return "moon.fill"
        case .aftershockHeavy: return "waveform.path.badge.plus"
        case .rapidEscalation: return "bolt.fill"
        case .surpriseQuake: return "exclamationmark.triangle.fill"
        case .trainingMode: return "graduationcap.fill"
        }
    }

    var difficulty: DifficultyIndicator {
        switch self {
        case .standard: return .medium
        case .night: return .hard
        case .aftershockHeavy: return .hard
        case .rapidEscalation: return .hard
        case .surpriseQuake: return .extreme
        case .trainingMode: return .easy
        }
    }

    /// Whether this scenario allows magnitude adjustment
    var allowsMagnitudeAdjustment: Bool {
        switch self {
        case .trainingMode: return false
        default: return true
        }
    }

    /// Default magnitude for this scenario type
    var defaultMagnitude: Double {
        switch self {
        case .trainingMode: return 5.0
        default: return 6.5
        }
    }
}

// MARK: - Difficulty Indicator

enum DifficultyIndicator: String, Sendable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    case extreme = "Extreme"

    var color: String {
        switch self {
        case .easy: return "34C759"  // Green
        case .medium: return "007AFF"  // Blue
        case .hard: return "FF9500"  // Orange
        case .extreme: return "FF3B30"  // Red
        }
    }

    var swiftUIColor: Color {
        switch self {
        case .easy: return Color(hex: 0x34C759)
        case .medium: return Color(hex: 0x007AFF)
        case .hard: return Color(hex: 0xFF9500)
        case .extreme: return Color(hex: 0xFF3B30)
        }
    }
}

// MARK: - Lighting Mode

enum LightingMode: String, Sendable {
    case normal
    case night
    case surprise

    /// Warm overlay alpha for calm phase
    var warmOverlayAlpha: CGFloat {
        switch self {
        case .normal: return 0.06
        case .night: return 0.02  // Very faint warm
        case .surprise: return 0.0  // No warm phase
        }
    }

    /// Cold overlay alpha during earthquake
    var coldOverlayAlpha: CGFloat {
        switch self {
        case .normal: return 0.12
        case .night: return 0.20  // Darker
        case .surprise: return 0.15  // Immediate cold
        }
    }

    /// Background color during calm phase
    var calmBackgroundColor: SKColor {
        switch self {
        case .normal:
            return SKColor(red: 0xFA/255, green: 0xF8/255, blue: 0xF5/255, alpha: 1)
        case .night:
            // Dark blue-tinted background for night
            return SKColor(red: 0x1A/255, green: 0x1F/255, blue: 0x2E/255, alpha: 1)
        case .surprise:
            // Already tense background
            return SKColor(red: 0xE5/255, green: 0xE5/255, blue: 0xEA/255, alpha: 1)
        }
    }

    /// Vignette alpha during calm phase
    var calmVignetteAlpha: CGFloat {
        switch self {
        case .normal: return 0.0
        case .night: return 0.4  // Dark edges
        case .surprise: return 0.2
        }
    }

    /// Vignette alpha during earthquake
    var quakeVignetteAlpha: CGFloat {
        switch self {
        case .normal: return 0.3
        case .night: return 0.7  // Much darker
        case .surprise: return 0.35
        }
    }

    /// Whether to reduce visibility of interactive elements
    var reducesVisibility: Bool {
        self == .night
    }

    /// Alpha multiplier for interactive elements during night
    var elementVisibilityMultiplier: CGFloat {
        switch self {
        case .normal: return 1.0
        case .night: return 0.7  // Harder to see
        case .surprise: return 1.0
        }
    }
}

// MARK: - Quake Scenario

struct QuakeScenario: Sendable {
    let magnitude: Double
    let roomType: String
    let scenarioType: ScenarioType

    /// Intensity multiplier based on magnitude (4.0-8.0 scale mapped to 0.3-1.0)
    var intensityMultiplier: CGFloat {
        let normalized = (magnitude - 4.0) / 4.0
        return (0.3 + normalized * 0.7).clamped(to: CGFloat(0.3)...CGFloat(1.0))
    }

    /// Training mode uses reduced intensity regardless of magnitude
    var effectiveIntensityMultiplier: CGFloat {
        if scenarioType == .trainingMode {
            return 0.4  // Gentle regardless of magnitude
        }
        return intensityMultiplier
    }

    // MARK: - Phase Timing Overrides

    /// Duration of the calm phase before countdown
    var calmDuration: TimeInterval {
        switch scenarioType {
        case .surpriseQuake:
            return 0.0  // No calm phase
        case .trainingMode:
            return 2.0  // Shorter calm
        default:
            return GameTiming.calmDuration
        }
    }

    /// Whether to show the countdown
    var hasCountdown: Bool {
        scenarioType != .surpriseQuake
    }

    /// Duration of the countdown phase
    var countdownDuration: TimeInterval {
        scenarioType == .surpriseQuake ? 0.0 : GameTiming.countdownDuration
    }

    /// P-wave duration
    var pWaveDuration: TimeInterval {
        switch scenarioType {
        case .rapidEscalation:
            return 0.5  // Very short warning
        case .surpriseQuake:
            return 0.0  // Immediate S-wave
        case .trainingMode:
            return 3.0  // Longer to learn
        default:
            return GameTiming.pWaveDuration
        }
    }

    /// S-wave duration
    var sWaveDuration: TimeInterval {
        let base = GameTiming.sWaveDuration
        let magnitudeExtra = (magnitude - 4.0) / 4.0 * 2.0

        switch scenarioType {
        case .trainingMode:
            return base * 0.7  // Shorter intense phase
        default:
            return base + magnitudeExtra
        }
    }

    /// Aftershock phase duration
    var aftershockDuration: TimeInterval {
        switch scenarioType {
        case .aftershockHeavy:
            return 35.0  // Extended aftershock phase
        case .trainingMode:
            return 15.0  // Shorter
        default:
            return GameTiming.aftershockDuration
        }
    }

    /// Total earthquake duration (P-wave + S-wave + Aftershock)
    var totalQuakeDuration: TimeInterval {
        pWaveDuration + sWaveDuration + aftershockDuration
    }

    // MARK: - Scenario Characteristics

    /// Number of additional aftershock spikes
    var aftershockCount: Int {
        switch scenarioType {
        case .aftershockHeavy:
            return 4  // Multiple major spikes
        case .trainingMode:
            return 1  // Minimal
        default:
            return 2  // Normal occasional spikes
        }
    }

    /// Lighting mode for this scenario
    var lightingMode: LightingMode {
        switch scenarioType {
        case .night:
            return .night
        case .surpriseQuake:
            return .surprise
        default:
            return .normal
        }
    }

    /// Whether this scenario shows the story intro before the earthquake
    var hasStoryIntro: Bool {
        scenarioType != .surpriseQuake && scenarioType != .trainingMode
    }

    /// Whether this scenario has a calm preparation phase
    var hasCalmPhase: Bool {
        scenarioType != .surpriseQuake
    }

    /// Debris count adjusted for scenario
    var debrisCount: Int {
        let baseCount: Int
        switch magnitude {
        case ..<5.0: baseCount = 3
        case ..<6.0: baseCount = 5
        case ..<7.0: baseCount = 8
        default:     baseCount = 12
        }

        switch scenarioType {
        case .aftershockHeavy:
            return baseCount + 3  // More debris from extended shaking
        case .trainingMode:
            return max(2, baseCount - 2)  // Less debris
        default:
            return baseCount
        }
    }

    /// Decision time window in seconds
    var decisionTimeWindow: TimeInterval {
        switch scenarioType {
        case .rapidEscalation, .surpriseQuake:
            return 2.0  // Fast reactions needed
        case .trainingMode:
            return 5.0  // Plenty of time to learn
        case .night:
            return 3.0  // Slightly reduced due to visibility
        default:
            return 3.5
        }
    }

    /// Score multiplier for this scenario
    var scoreMultiplier: Double {
        switch scenarioType {
        case .trainingMode:
            return 0.5  // Reduced scoring in training
        case .night, .rapidEscalation, .surpriseQuake:
            return 1.3  // Bonus for harder scenarios
        case .aftershockHeavy:
            return 1.4  // Highest bonus for endurance
        default:
            return 1.0
        }
    }

    // MARK: - Factory Methods

    static func standard(magnitude: Double = 6.5, roomType: String = "livingRoom") -> QuakeScenario {
        QuakeScenario(magnitude: magnitude, roomType: roomType, scenarioType: .standard)
    }

    static func night(magnitude: Double = 6.5, roomType: String = "livingRoom") -> QuakeScenario {
        QuakeScenario(magnitude: magnitude, roomType: roomType, scenarioType: .night)
    }

    static func aftershockHeavy(magnitude: Double = 6.5, roomType: String = "livingRoom") -> QuakeScenario {
        QuakeScenario(magnitude: magnitude, roomType: roomType, scenarioType: .aftershockHeavy)
    }

    static func rapidEscalation(magnitude: Double = 6.5, roomType: String = "livingRoom") -> QuakeScenario {
        QuakeScenario(magnitude: magnitude, roomType: roomType, scenarioType: .rapidEscalation)
    }

    static func surpriseQuake(magnitude: Double = 6.5, roomType: String = "livingRoom") -> QuakeScenario {
        QuakeScenario(magnitude: magnitude, roomType: roomType, scenarioType: .surpriseQuake)
    }

    static func trainingMode(roomType: String = "livingRoom") -> QuakeScenario {
        QuakeScenario(magnitude: 5.0, roomType: roomType, scenarioType: .trainingMode)
    }

    static let `default` = QuakeScenario.standard()
}
