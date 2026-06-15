import Foundation
import SwiftUI
import Combine

// NOTE: EnhancedComboSystem has been integrated into DecisionEngine.swift (ComboSystem struct)
// The class below is kept for reference but is no longer used in the game.
// The 4-tier combo system (1x/2x/3x/4x) with UNSTOPPABLE!/LEGENDARY! descriptions
// is now implemented in DecisionEngine.swift lines 70-123.

// MARK: - Enhanced Combo System (DEPRECATED - Integrated into DecisionEngine)

/// Manages consecutive correct decisions with multipliers and visual feedback
/// Resets when player makes incorrect decisions
/// Enhanced version with more multiplier tiers and visual intensity tracking
@MainActor
final class EnhancedComboSystem: ObservableObject, Sendable {
    
    // MARK: - Published Properties
    
    /// Current number of consecutive correct decisions
    @Published private(set) var consecutiveCorrectDecisions: Int = 0
    
    /// Current multiplier applied to scores (1x, 2x, 3x, or 4x)
    @Published private(set) var currentMultiplier: Int = 1
    
    /// Human-readable combo status for UI display
    @Published private(set) var comboDescription: String = ""
    
    /// Visual intensity level for combo animations (0-3)
    @Published private(set) var visualIntensity: Int = 0
    
    /// Whether combo is at maximum level
    @Published private(set) var isMaxCombo: Bool = false
    
    // MARK: - Constants
    
    /// Multiplier thresholds
    private let multiplierTiers: [ClosedRange<Int>] = [
        0...1,   // 1x
        2...3,   // 2x
        4...6,   // 3x
        7...Int.max // 4x
    ]
    
    /// Maximum combo multiplier
    let maxMultiplier: Int = 4
    
    /// Combo master achievement threshold
    let comboMasterThreshold: Int = 5
    
    // MARK: - Computed Properties
    
    /// Formatted multiplier string for display (e.g., "2x")
    var multiplierDisplay: String {
        "\(currentMultiplier)x"
    }
    
    /// Progress to next multiplier tier (0.0 - 1.0)
    var progressToNextTier: Double {
        switch consecutiveCorrectDecisions {
        case 0...1: return Double(consecutiveCorrectDecisions) / 2.0
        case 2...3: return Double(consecutiveCorrectDecisions - 1) / 3.0
        case 4...6: return Double(consecutiveCorrectDecisions - 3) / 4.0
        default: return 1.0
        }
    }
    
    /// Whether combo master achievement is achieved
    var isComboMaster: Bool {
        consecutiveCorrectDecisions >= comboMasterThreshold
    }
    
    /// Total bonus points from combo for display
    var totalComboBonus: Int {
        // Calculated as (multiplier - 1) * 10 per combo level
        max(0, (consecutiveCorrectDecisions - 1) * 10)
    }
    
    // MARK: - Methods
    
    /// Call when player makes a correct decision
    /// Increments combo and updates multiplier
    func recordCorrectDecision() {
        consecutiveCorrectDecisions += 1
        updateMultiplier()
        updateVisuals()
    }
    
    /// Call when player makes a wrong decision - breaks the combo
    /// Resets all combo state
    func breakCombo() {
        consecutiveCorrectDecisions = 0
        currentMultiplier = 1
        visualIntensity = 0
        isMaxCombo = false
        updateComboDescription()
    }
    
    /// Reset combo at game start
    func reset() {
        consecutiveCorrectDecisions = 0
        currentMultiplier = 1
        comboDescription = ""
        visualIntensity = 0
        isMaxCombo = false
    }
    
    /// Calculate score with combo multiplier applied
    func calculateScore(basePoints: Int) -> Int {
        return basePoints * currentMultiplier
    }
    
    // MARK: - Private Methods
    
    private func updateMultiplier() {
        for (index, range) in multiplierTiers.enumerated() {
            if range.contains(consecutiveCorrectDecisions) {
                currentMultiplier = index + 1
                break
            }
        }
        isMaxCombo = currentMultiplier >= maxMultiplier
        updateComboDescription()
    }
    
    private func updateVisuals() {
        // Visual intensity increases every 2 combos up to 3
        visualIntensity = min(3, consecutiveCorrectDecisions / 2)
    }
    
    private func updateComboDescription() {
        switch consecutiveCorrectDecisions {
        case 0:
            comboDescription = ""
        case 1:
            comboDescription = "Good!"
        case 2:
            comboDescription = "2x COMBO!"
        case 3...4:
            comboDescription = "3x COMBO!"
        case 5...6:
            comboDescription = "COMBO MASTER!"
        case 7...9:
            comboDescription = "UNSTOPPABLE!"
        default:
            comboDescription = "LEGENDARY!"
        }
    }
}

// MARK: - Difficulty Scaler

/// Calculates game parameters based on earthquake magnitude (4.0 - 8.0)
/// Provides continuous scaling rather than discrete difficulty levels
@MainActor
final class DifficultyScaler: ObservableObject, Sendable {
    
    // MARK: - Properties
    
    /// Current earthquake magnitude (4.0 - 8.0)
    @Published private(set) var magnitude: Double = 6.0
    
    /// Cached difficulty parameters
    @Published private(set) var currentParameters: DifficultyParameters
    
    // MARK: - Initialization
    
    init(magnitude: Double = 6.0) {
        self.magnitude = magnitude.clamped(to: 4.0...8.0)
        self.currentParameters = DifficultyScaler.calculateParameters(for: magnitude)
    }
    
    // MARK: - Configuration
    
    /// Update magnitude and recalculate all parameters
    func setMagnitude(_ newMagnitude: Double) {
        magnitude = newMagnitude.clamped(to: 4.0...8.0)
        currentParameters = DifficultyScaler.calculateParameters(for: magnitude)
    }
    
    // MARK: - Static Calculations
    
    /// Calculate all difficulty parameters for a given magnitude
    static func calculateParameters(for magnitude: Double) -> DifficultyParameters {
        let normalized = (magnitude - 4.0) / 4.0 // 0.0 to 1.0
        
        return DifficultyParameters(
            magnitude: magnitude,
            intensityMultiplier: calculateIntensityMultiplier(normalized),
            objectFallSpeedMultiplier: calculateFallSpeed(normalized),
            decisionTimeWindow: calculateDecisionWindow(normalized),
            debrisCount: calculateDebrisCount(magnitude),
            scoreMultiplier: calculateScoreMultiplier(normalized),
            shakeIntensity: calculateShakeIntensity(normalized),
            pWaveDuration: calculatePWaveDuration(normalized),
            sWaveDuration: calculateSWaveDuration(magnitude, normalized),
            aftershockDuration: calculateAftershockDuration(normalized),
            dangerZoneCount: calculateDangerZones(normalized),
            reactionBonusMax: calculateReactionBonus(normalized)
        )
    }
    
    /// Map magnitude to intensity (0.3 - 1.0)
    private static func calculateIntensityMultiplier(_ normalized: Double) -> CGFloat {
        return CGFloat(0.3 + normalized * 0.7)
    }
    
    /// Object fall speed (0.6x - 1.6x)
    private static func calculateFallSpeed(_ normalized: Double) -> CGFloat {
        return CGFloat(0.6 + normalized * 1.0)
    }
    
    /// Decision time window (5.0s - 2.0s, faster at higher magnitudes)
    private static func calculateDecisionWindow(_ normalized: Double) -> TimeInterval {
        return 5.0 - (normalized * 3.0)
    }
    
    /// Debris count based on magnitude
    private static func calculateDebrisCount(_ magnitude: Double) -> Int {
        switch magnitude {
        case 4.0..<4.5: return 2
        case 4.5..<5.0: return 3
        case 5.0..<5.5: return 4
        case 5.5..<6.0: return 6
        case 6.0..<6.5: return 8
        case 6.5..<7.0: return 10
        case 7.0..<7.5: return 13
        default: return 16
        }
    }
    
    /// Score multiplier (1.0x - 2.0x)
    private static func calculateScoreMultiplier(_ normalized: Double) -> Double {
        return 1.0 + (normalized * 1.0)
    }
    
    /// Camera shake intensity (0.5 - 1.5)
    private static func calculateShakeIntensity(_ normalized: Double) -> CGFloat {
        return CGFloat(0.5 + normalized * 1.0)
    }
    
    /// P-wave warning duration (2.0s - 1.0s)
    private static func calculatePWaveDuration(_ normalized: Double) -> TimeInterval {
        return 2.0 - (normalized * 1.0)
    }
    
    /// S-wave main shaking duration (4.0s - 8.0s)
    private static func calculateSWaveDuration(_ magnitude: Double, _ normalized: Double) -> TimeInterval {
        let base: TimeInterval = 4.0
        let extra = normalized * 4.0
        return base + extra
    }
    
    /// Aftershock phase duration (2.0s - 5.0s)
    private static func calculateAftershockDuration(_ normalized: Double) -> TimeInterval {
        return 2.0 + (normalized * 3.0)
    }
    
    /// Number of danger zones to highlight (2 - 5)
    private static func calculateDangerZones(_ normalized: Double) -> Int {
        return 2 + Int(normalized * 3.0)
    }
    
    /// Maximum reaction time bonus points (15 - 25)
    private static func calculateReactionBonus(_ normalized: Double) -> Int {
        return 15 + Int(normalized * 10.0)
    }
}

// MARK: - Difficulty Parameters

/// Container for all difficulty-scaled game parameters
struct DifficultyParameters: Sendable {
    let magnitude: Double
    let intensityMultiplier: CGFloat
    let objectFallSpeedMultiplier: CGFloat
    let decisionTimeWindow: TimeInterval
    let debrisCount: Int
    let scoreMultiplier: Double
    let shakeIntensity: CGFloat
    let pWaveDuration: TimeInterval
    let sWaveDuration: TimeInterval
    let aftershockDuration: TimeInterval
    let dangerZoneCount: Int
    let reactionBonusMax: Int
    
    /// Human-readable difficulty description
    var description: String {
        switch magnitude {
        case 4.0..<5.0: return "Minor (M \(String(format: "%.1f", magnitude)))"
        case 5.0..<6.0: return "Moderate (M \(String(format: "%.1f", magnitude)))"
        case 6.0..<7.0: return "Strong (M \(String(format: "%.1f", magnitude)))"
        default: return "Major (M \(String(format: "%.1f", magnitude)))"
        }
    }
    
    /// Color representing the difficulty
    var displayColor: Color {
        switch magnitude {
        case 4.0..<5.0: return .green
        case 5.0..<6.0: return .orange
        case 6.0..<7.0: return .red
        default: return .purple
        }
    }
}

// MARK: - Enhanced Achievement System

/// Comprehensive achievement system with multiple condition types
enum EnhancedAchievementCategory: String, Codable, Sendable {
    case survival = "Survival"
    case speed = "Speed"
    case combo = "Combo"
    case knowledge = "Knowledge"
    case mastery = "Mastery"
    
    var iconName: String {
        switch self {
        case .survival: return "shield.fill"
        case .speed: return "bolt.fill"
        case .combo: return "flame.fill"
        case .knowledge: return "book.fill"
        case .mastery: return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .survival: return .green
        case .speed: return .yellow
        case .combo: return .orange
        case .knowledge: return .blue
        case .mastery: return .purple
        }
    }
}

/// Achievement definition with unlock conditions
/// Enhanced version with categories, secrets, and progress tracking
struct EnhancedAchievement: Identifiable, Codable, Sendable, Equatable {
    let id: String
    let title: String
    let description: String
    let iconName: String
    let category: EnhancedAchievementCategory
    let condition: EnhancedAchievementCondition
    let secret: Bool
    var isUnlocked: Bool
    var dateUnlocked: Date?
    var progress: Double // 0.0 to 1.0 for partial completion
    
    init(
        id: String,
        title: String,
        description: String,
        iconName: String,
        category: EnhancedAchievementCategory = .survival,
        condition: EnhancedAchievementCondition,
        secret: Bool = false,
        isUnlocked: Bool = false,
        dateUnlocked: Date? = nil,
        progress: Double = 0.0
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.iconName = iconName
        self.category = category
        self.condition = condition
        self.secret = secret
        self.isUnlocked = isUnlocked
        self.dateUnlocked = dateUnlocked
        self.progress = progress
    }
    
    /// Display description (hidden if secret and not unlocked)
    var displayDescription: String {
        secret && !isUnlocked ? "???" : description
    }
    
    /// Display title (hidden if secret and not unlocked)
    var displayTitle: String {
        secret && !isUnlocked ? "Secret Achievement" : title
    }
    
    static func == (lhs: EnhancedAchievement, rhs: EnhancedAchievement) -> Bool {
        lhs.id == rhs.id
    }
}

/// Types of achievement conditions
enum EnhancedAchievementCondition: Codable, Sendable, Equatable {
    case firstGame
    case speedDemon(threshold: TimeInterval)
    case perfectRun
    case survivor
    case comboMaster(threshold: Int)
    case gasExpert
    case quickThinker(count: Int, threshold: TimeInterval)
    case highScore(threshold: Int)
    case gamesPlayed(count: Int)
    case allCorrectDecisions
    case noDamage
    case magnitudeSurvivor(magnitude: Double)
    case streakMaster(games: Int)
    case speedRunner(totalTime: TimeInterval)
    case completionist
    
    /// Human-readable description
    var description: String {
        switch self {
        case .firstGame:
            return "Complete your first simulation"
        case .speedDemon(let threshold):
            return "Make a correct decision in under \(Int(threshold)) second\(threshold == 1 ? "" : "s")"
        case .perfectRun:
            return "Make all correct decisions in a single game"
        case .survivor:
            return "Complete with all 3 hearts remaining"
        case .comboMaster(let threshold):
            return "Achieve a \(threshold)x combo"
        case .gasExpert:
            return "Shut off gas during aftershock"
        case .quickThinker(let count, let threshold):
            return "Make \(count) correct decisions under \(Int(threshold))s each"
        case .highScore(let threshold):
            return "Score \(threshold) points in one game"
        case .gamesPlayed(let count):
            return "Play \(count) games"
        case .allCorrectDecisions:
            return "Make every decision correctly"
        case .noDamage:
            return "Survive without taking any damage"
        case .magnitudeSurvivor(let magnitude):
            return "Survive a magnitude \(Int(magnitude)) earthquake"
        case .streakMaster(let games):
            return "Survive \(games) games in a row"
        case .speedRunner(let time):
            return "Complete a game in under \(Int(time)) seconds"
        case .completionist:
            return "Unlock all other achievements"
        }
    }
    
    // MARK: - Codable Conformance
    
    private enum CodingKeys: String, CodingKey {
        case type, threshold, count, magnitude, games, time
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .firstGame:
            try container.encode("firstGame", forKey: .type)
        case .speedDemon(let threshold):
            try container.encode("speedDemon", forKey: .type)
            try container.encode(threshold, forKey: .threshold)
        case .perfectRun:
            try container.encode("perfectRun", forKey: .type)
        case .survivor:
            try container.encode("survivor", forKey: .type)
        case .comboMaster(let threshold):
            try container.encode("comboMaster", forKey: .type)
            try container.encode(threshold, forKey: .count)
        case .gasExpert:
            try container.encode("gasExpert", forKey: .type)
        case .quickThinker(let count, let threshold):
            try container.encode("quickThinker", forKey: .type)
            try container.encode(count, forKey: .count)
            try container.encode(threshold, forKey: .threshold)
        case .highScore(let threshold):
            try container.encode("highScore", forKey: .type)
            try container.encode(threshold, forKey: .count)
        case .gamesPlayed(let count):
            try container.encode("gamesPlayed", forKey: .type)
            try container.encode(count, forKey: .count)
        case .allCorrectDecisions:
            try container.encode("allCorrectDecisions", forKey: .type)
        case .noDamage:
            try container.encode("noDamage", forKey: .type)
        case .magnitudeSurvivor(let magnitude):
            try container.encode("magnitudeSurvivor", forKey: .type)
            try container.encode(magnitude, forKey: .magnitude)
        case .streakMaster(let games):
            try container.encode("streakMaster", forKey: .type)
            try container.encode(games, forKey: .games)
        case .speedRunner(let time):
            try container.encode("speedRunner", forKey: .type)
            try container.encode(time, forKey: .time)
        case .completionist:
            try container.encode("completionist", forKey: .type)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "firstGame":
            self = .firstGame
        case "speedDemon":
            self = .speedDemon(threshold: try container.decode(TimeInterval.self, forKey: .threshold))
        case "perfectRun":
            self = .perfectRun
        case "survivor":
            self = .survivor
        case "comboMaster":
            self = .comboMaster(threshold: try container.decode(Int.self, forKey: .count))
        case "gasExpert":
            self = .gasExpert
        case "quickThinker":
            self = .quickThinker(
                count: try container.decode(Int.self, forKey: .count),
                threshold: try container.decode(TimeInterval.self, forKey: .threshold)
            )
        case "highScore":
            self = .highScore(threshold: try container.decode(Int.self, forKey: .count))
        case "gamesPlayed":
            self = .gamesPlayed(count: try container.decode(Int.self, forKey: .count))
        case "allCorrectDecisions":
            self = .allCorrectDecisions
        case "noDamage":
            self = .noDamage
        case "magnitudeSurvivor":
            self = .magnitudeSurvivor(magnitude: try container.decode(Double.self, forKey: .magnitude))
        case "streakMaster":
            self = .streakMaster(games: try container.decode(Int.self, forKey: .games))
        case "speedRunner":
            self = .speedRunner(totalTime: try container.decode(TimeInterval.self, forKey: .time))
        case "completionist":
            self = .completionist
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown achievement condition type: \(type)")
        }
    }
}

/// Manages all achievements and their unlock state
/// Enhanced version with more achievements and category organization
@MainActor
final class EnhancedAchievementManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var achievements: [EnhancedAchievement] = []
    @Published private(set) var newlyUnlocked: [EnhancedAchievement] = []
    @Published private(set) var totalUnlocked: Int = 0
    @Published private(set) var completionPercentage: Double = 0.0
    
    // MARK: - Tracking Properties
    
    private var quickDecisionStreak: Int = 0
    private var survivalStreak: Int = 0
    private var hasShutOffGas: Bool = false
    private var fastestDecision: TimeInterval = .infinity
    
    // MARK: - Constants
    
    private let storageKey = "quakeSense_enhancedAchievements"
    
    // MARK: - Initialization
    
    init() {
        loadAchievements()
        updateStats()
    }
    
    // MARK: - Default Achievements
    
    private static func createDefaultAchievements() -> [EnhancedAchievement] {
        [
            // Survival Achievements
            EnhancedAchievement(
                id: "first_timer",
                title: "First Steps",
                description: "Complete your first earthquake simulation",
                iconName: "play.circle.fill",
                category: .survival,
                condition: .firstGame
            ),
            EnhancedAchievement(
                id: "survivor",
                title: "Survivor",
                description: "Complete a game with all 3 hearts remaining",
                iconName: "heart.circle.fill",
                category: .survival,
                condition: .survivor
            ),
            EnhancedAchievement(
                id: "no_damage",
                title: "Untouchable",
                description: "Survive without taking any damage",
                iconName: "shield.checkerboard",
                category: .survival,
                condition: .noDamage
            ),
            EnhancedAchievement(
                id: "magnitude_7",
                title: "Big One Survivor",
                description: "Survive a magnitude 7.0+ earthquake",
                iconName: "exclamationmark.shield.fill",
                category: .survival,
                condition: .magnitudeSurvivor(magnitude: 7.0)
            ),
            EnhancedAchievement(
                id: "magnitude_8",
                title: "Extreme Survivor",
                description: "Survive a magnitude 8.0 earthquake",
                iconName: "hurricane",
                category: .survival,
                condition: .magnitudeSurvivor(magnitude: 8.0)
            ),
            
            // Speed Achievements
            EnhancedAchievement(
                id: "speed_demon",
                title: "Speed Demon",
                description: "Make a correct decision in under 1 second",
                iconName: "bolt.circle.fill",
                category: .speed,
                condition: .speedDemon(threshold: 1.0)
            ),
            EnhancedAchievement(
                id: "lightning_reflexes",
                title: "Lightning Reflexes",
                description: "Make a correct decision in under 0.5 seconds",
                iconName: "bolt.heart.fill",
                category: .speed,
                condition: .speedDemon(threshold: 0.5)
            ),
            EnhancedAchievement(
                id: "quick_thinker",
                title: "Quick Thinker",
                description: "Make 3 correct decisions in under 2 seconds each",
                iconName: "brain.head.profile",
                category: .speed,
                condition: .quickThinker(count: 3, threshold: 2.0)
            ),
            EnhancedAchievement(
                id: "speed_runner",
                title: "Speed Runner",
                description: "Complete a game in under 30 seconds",
                iconName: "stopwatch.fill",
                category: .speed,
                condition: .speedRunner(totalTime: 30.0)
            ),
            
            // Combo Achievements
            EnhancedAchievement(
                id: "combo_starter",
                title: "On a Roll",
                description: "Achieve a 3x combo",
                iconName: "flame.fill",
                category: .combo,
                condition: .comboMaster(threshold: 3)
            ),
            EnhancedAchievement(
                id: "combo_master",
                title: "Combo Master",
                description: "Achieve a 5x combo",
                iconName: "flame.circle.fill",
                category: .combo,
                condition: .comboMaster(threshold: 5)
            ),
            EnhancedAchievement(
                id: "combo_legend",
                title: "Combo Legend",
                description: "Achieve a 10x combo",
                iconName: "flame.circle",
                category: .combo,
                condition: .comboMaster(threshold: 10),
                secret: true
            ),
            
            // Knowledge Achievements
            EnhancedAchievement(
                id: "gas_expert",
                title: "Gas Expert",
                description: "Shut off the gas valve during aftershock",
                iconName: "flame.circle.fill",
                category: .knowledge,
                condition: .gasExpert
            ),
            EnhancedAchievement(
                id: "perfect_run",
                title: "Perfect Run",
                description: "Make all correct decisions in a single game",
                iconName: "checkmark.seal.fill",
                category: .knowledge,
                condition: .perfectRun
            ),
            EnhancedAchievement(
                id: "always_correct",
                title: "Safety Expert",
                description: "Make every decision correctly in a game",
                iconName: "checkmark.shield.fill",
                category: .knowledge,
                condition: .allCorrectDecisions
            ),
            
            // Mastery Achievements
            EnhancedAchievement(
                id: "high_scorer",
                title: "High Scorer",
                description: "Score 200 points in one game",
                iconName: "trophy.fill",
                category: .mastery,
                condition: .highScore(threshold: 200)
            ),
            EnhancedAchievement(
                id: "score_master",
                title: "Score Master",
                description: "Score 500 points in one game",
                iconName: "trophy.circle.fill",
                category: .mastery,
                condition: .highScore(threshold: 500)
            ),
            EnhancedAchievement(
                id: "veteran",
                title: "Veteran",
                description: "Play 10 games",
                iconName: "10.circle.fill",
                category: .mastery,
                condition: .gamesPlayed(count: 10)
            ),
            EnhancedAchievement(
                id: "expert",
                title: "Expert",
                description: "Play 50 games",
                iconName: "50.circle.fill",
                category: .mastery,
                condition: .gamesPlayed(count: 50)
            ),
            EnhancedAchievement(
                id: "streak_5",
                title: "Streak Master",
                description: "Survive 5 games in a row",
                iconName: "sparkles",
                category: .mastery,
                condition: .streakMaster(games: 5)
            ),
            EnhancedAchievement(
                id: "completionist",
                title: "Completionist",
                description: "Unlock all other achievements",
                iconName: "crown.fill",
                category: .mastery,
                condition: .completionist,
                secret: true
            )
        ]
    }
    
    // MARK: - Event Handlers
    
    /// Call when game starts
    func onGameStart() {
        quickDecisionStreak = 0
        hasShutOffGas = false
        fastestDecision = .infinity
    }
    
    /// Call when a decision is made
    func onDecision(action: PlayerAction, isCorrect: Bool, responseTime: TimeInterval) {
        if isCorrect {
            // Track quick decisions
            if responseTime < 2.0 {
                quickDecisionStreak += 1
            } else {
                quickDecisionStreak = 0
            }
            
            // Track fastest decision
            fastestDecision = min(fastestDecision, responseTime)
            
            // Track gas shutoff
            if action == .shutOffGas {
                hasShutOffGas = true
            }
        } else {
            quickDecisionStreak = 0
        }
    }
    
    /// Call when game ends
    func onGameEnd(
        score: Int,
        totalTime: TimeInterval,
        heartsRemaining: Int,
        correctDecisions: Int,
        totalDecisions: Int,
        maxCombo: Int,
        magnitude: Double,
        gamesPlayed: Int
    ) {
        let isSurvived = heartsRemaining == 3 && score >= 50
        let isPerfect = correctDecisions == totalDecisions && totalDecisions >= 3
        let noDamage = heartsRemaining == 3
        
        // Update survival streak
        if isSurvived {
            survivalStreak += 1
        } else {
            survivalStreak = 0
        }
        
        // Check all achievements
        checkAchievements(
            score: score,
            totalTime: totalTime,
            heartsRemaining: heartsRemaining,
            correctDecisions: correctDecisions,
            totalDecisions: totalDecisions,
            maxCombo: maxCombo,
            magnitude: magnitude,
            gamesPlayed: gamesPlayed,
            isSurvived: isSurvived,
            isPerfect: isPerfect,
            noDamage: noDamage
        )
    }
    
    // MARK: - Achievement Checking
    
    private func checkAchievements(
        score: Int,
        totalTime: TimeInterval,
        heartsRemaining: Int,
        correctDecisions: Int,
        totalDecisions: Int,
        maxCombo: Int,
        magnitude: Double,
        gamesPlayed: Int,
        isSurvived: Bool,
        isPerfect: Bool,
        noDamage: Bool
    ) {
        var newlyUnlockedIds: [String] = []
        
        for index in achievements.indices where !achievements[index].isUnlocked {
            var shouldUnlock = false
            
            switch achievements[index].condition {
            case .firstGame:
                shouldUnlock = gamesPlayed >= 1
                
            case .speedDemon(let threshold):
                shouldUnlock = fastestDecision < threshold && fastestDecision != .infinity
                
            case .perfectRun:
                shouldUnlock = isPerfect
                
            case .survivor:
                shouldUnlock = heartsRemaining == 3
                
            case .comboMaster(let threshold):
                shouldUnlock = maxCombo >= threshold
                
            case .gasExpert:
                shouldUnlock = hasShutOffGas
                
            case .quickThinker(let count, _):
                shouldUnlock = quickDecisionStreak >= count
                
            case .highScore(let threshold):
                shouldUnlock = score >= threshold
                
            case .gamesPlayed(let count):
                shouldUnlock = gamesPlayed >= count
                
            case .allCorrectDecisions:
                shouldUnlock = isPerfect
                
            case .noDamage:
                shouldUnlock = noDamage
                
            case .magnitudeSurvivor(let minMagnitude):
                shouldUnlock = magnitude >= minMagnitude && isSurvived
                
            case .streakMaster(let games):
                shouldUnlock = survivalStreak >= games
                
            case .speedRunner(let maxTime):
                shouldUnlock = totalTime < maxTime
                
            case .completionist:
                let totalAchievements = achievements.count - 1 // Exclude completionist
                let unlockedCount = achievements.filter { $0.isUnlocked && $0.id != "completionist" }.count
                shouldUnlock = unlockedCount >= totalAchievements
            }
            
            if shouldUnlock {
                achievements[index].isUnlocked = true
                achievements[index].dateUnlocked = Date()
                achievements[index].progress = 1.0
                newlyUnlockedIds.append(achievements[index].id)
            }
        }
        
        // Update newly unlocked
        newlyUnlocked = achievements.filter { newlyUnlockedIds.contains($0.id) }
        
        if !newlyUnlocked.isEmpty {
            updateStats()
            saveAchievements()
        }
    }
    
    /// Get achievements by category
    func achievements(in category: EnhancedAchievementCategory) -> [EnhancedAchievement] {
        achievements.filter { $0.category == category }
    }
    
    /// Get unlocked achievements
    var unlockedAchievements: [EnhancedAchievement] {
        achievements.filter { $0.isUnlocked }
    }
    
    /// Get locked achievements
    var lockedAchievements: [EnhancedAchievement] {
        achievements.filter { !$0.isUnlocked }
    }
    
    /// Check if specific achievement is unlocked
    func isUnlocked(id: String) -> Bool {
        achievements.first { $0.id == id }?.isUnlocked ?? false
    }
    
    /// Get achievement by ID
    func achievement(id: String) -> EnhancedAchievement? {
        achievements.first { $0.id == id }
    }
    
    // MARK: - Private Methods
    
    private func updateStats() {
        let unlocked = achievements.filter { $0.isUnlocked }.count
        totalUnlocked = unlocked
        completionPercentage = Double(unlocked) / Double(achievements.count)
    }
    
    // MARK: - Persistence
    
    private func saveAchievements() {
        if let data = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    private func loadAchievements() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([EnhancedAchievement].self, from: data) {
            // Merge with default to handle new achievements
            var merged = EnhancedAchievementManager.createDefaultAchievements()
            for savedAchievement in saved {
                if let index = merged.firstIndex(where: { $0.id == savedAchievement.id }) {
                    merged[index] = savedAchievement
                }
            }
            achievements = merged
        } else {
            achievements = EnhancedAchievementManager.createDefaultAchievements()
        }
    }
    
    /// Reset all achievements (for testing)
    func resetAll() {
        achievements = EnhancedAchievementManager.createDefaultAchievements()
        newlyUnlocked = []
        quickDecisionStreak = 0
        survivalStreak = 0
        hasShutOffGas = false
        fastestDecision = .infinity
        updateStats()
        saveAchievements()
    }
}

// MARK: - Game Statistics

/// Comprehensive persistent statistics tracker
struct GameStatistics: Codable, Sendable {
    
    // MARK: - Basic Stats
    
    /// Total games played across all sessions
    var totalGamesPlayed: Int = 0
    
    /// Total games survived (3 hearts + score >= 50)
    var totalGamesSurvived: Int = 0
    
    /// Total games injured (2+ hearts, score >= 20)
    var totalGamesInjured: Int = 0
    
    /// Total games critical (worse than injured)
    var totalGamesCritical: Int = 0
    
    // MARK: - Score Stats
    
    /// Highest score achieved in any game
    var bestScore: Int = 0
    
    /// Sum of all scores for average calculation
    var totalScore: Int = 0
    
    /// Average score per game
    var averageScore: Int {
        totalGamesPlayed > 0 ? totalScore / totalGamesPlayed : 0
    }
    
    // MARK: - Decision Stats
    
    /// Total correct decisions across all games
    var totalCorrectDecisions: Int = 0
    
    /// Total wrong decisions across all games
    var totalWrongDecisions: Int = 0
    
    /// Overall accuracy percentage
    var accuracyPercentage: Double {
        let total = totalCorrectDecisions + totalWrongDecisions
        return total > 0 ? Double(totalCorrectDecisions) / Double(total) * 100 : 0
    }
    
    /// Frequency of each action chosen
    var actionFrequency: [String: Int] = [:]
    
    /// Response times for calculating average
    var totalResponseTime: TimeInterval = 0
    var decisionCountForTiming: Int = 0
    
    /// Average response time in seconds
    var averageResponseTime: TimeInterval {
        decisionCountForTiming > 0 ? totalResponseTime / TimeInterval(decisionCountForTiming) : 0
    }
    
    /// Fastest correct decision recorded
    var fastestDecisionTime: TimeInterval = .infinity
    
    // MARK: - Combo Stats
    
    /// Highest combo achieved in any game
    var maxComboEver: Int = 0
    
    /// Total combo bonuses earned
    var totalComboBonuses: Int = 0
    
    // MARK: - Magnitude Stats
    
    /// Games played at each magnitude level (stored as string key)
    var gamesByMagnitude: [String: Int] = [:]
    
    /// Best score at each magnitude
    var bestScoreByMagnitude: [String: Int] = [:]
    
    // MARK: - Time Stats
    
    /// Total time spent playing (in seconds)
    var totalPlayTime: TimeInterval = 0
    
    /// Fastest game completion time
    var fastestGameTime: TimeInterval = .infinity
    
    // MARK: - Streak Stats
    
    /// Current consecutive survival streak
    var currentSurvivalStreak: Int = 0
    
    /// Longest survival streak ever
    var longestSurvivalStreak: Int = 0
    
    // MARK: - Session Tracking
    
    /// First play date
    var firstPlayDate: Date?
    
    /// Last play date
    var lastPlayDate: Date?
    
    /// Total play sessions (days with at least one game)
    var totalSessions: Int = 0
    
    /// Last session date for tracking unique sessions
    var lastSessionDate: String = ""
    
    // MARK: - Achievement Tracking
    
    /// IDs of unlocked achievements with unlock dates
    var unlockedAchievements: [String: Date] = [:]
    
    /// Achievement points total
    var achievementPoints: Int = 0
    
    // MARK: - Favorite Action
    
    /// Most frequently chosen action
    var favoriteAction: PlayerAction? {
        guard let maxEntry = actionFrequency.max(by: { $0.value < $1.value }) else { return nil }
        return PlayerAction(rawValue: maxEntry.key)
    }
    
    // MARK: - Methods
    
    /// Record a completed game
    mutating func recordGame(
        score: Int,
        heartsRemaining: Int,
        correctDecisions: Int,
        wrongDecisions: Int,
        maxCombo: Int,
        magnitude: Double,
        totalTime: TimeInterval
    ) {
        totalGamesPlayed += 1
        totalScore += score
        bestScore = max(bestScore, score)
        
        // Track survival outcome
        let rating = calculateSurvivalRating(hearts: heartsRemaining, score: score)
        switch rating {
        case .survived: totalGamesSurvived += 1
        case .injured: totalGamesInjured += 1
        case .critical: totalGamesCritical += 1
        }
        
        // Track decisions
        totalCorrectDecisions += correctDecisions
        totalWrongDecisions += wrongDecisions
        
        // Track combo
        maxComboEver = max(maxComboEver, maxCombo)
        
        // Track magnitude
        let magKey = String(format: "%.1f", magnitude)
        gamesByMagnitude[magKey, default: 0] += 1
        bestScoreByMagnitude[magKey] = max(bestScoreByMagnitude[magKey] ?? 0, score)
        
        // Track time
        totalPlayTime += totalTime
        fastestGameTime = min(fastestGameTime, totalTime)
        
        // Track streaks
        if rating == .survived {
            currentSurvivalStreak += 1
            longestSurvivalStreak = max(longestSurvivalStreak, currentSurvivalStreak)
        } else {
            currentSurvivalStreak = 0
        }
        
        // Track dates
        let now = Date()
        if firstPlayDate == nil {
            firstPlayDate = now
        }
        lastPlayDate = now
        
        // Track sessions
        let calendar = Calendar.current
        let sessionDate = calendar.startOfDay(for: now)
        let sessionKey = ISO8601DateFormatter().string(from: sessionDate)
        if sessionKey != lastSessionDate {
            lastSessionDate = sessionKey
            totalSessions += 1
        }
    }
    
    /// Record an action choice
    mutating func recordAction(_ action: PlayerAction) {
        actionFrequency[action.rawValue, default: 0] += 1
    }
    
    /// Record a decision with timing
    mutating func recordDecision(responseTime: TimeInterval, isCorrect: Bool) {
        decisionCountForTiming += 1
        totalResponseTime += responseTime
        
        if isCorrect {
            fastestDecisionTime = min(fastestDecisionTime, responseTime)
        }
    }
    
    /// Record combo bonus
    mutating func recordComboBonus(_ bonus: Int) {
        totalComboBonuses += bonus
    }
    
    /// Unlock an achievement
    mutating func unlockAchievement(id: String, points: Int = 10) {
        if unlockedAchievements[id] == nil {
            unlockedAchievements[id] = Date()
            achievementPoints += points
        }
    }
    
    /// Check if achievement is unlocked
    func isAchievementUnlocked(id: String) -> Bool {
        unlockedAchievements[id] != nil
    }
    
    /// Get games played at specific magnitude
    func gamesPlayedAtMagnitude(_ magnitude: Double) -> Int {
        let magKey = String(format: "%.1f", magnitude)
        return gamesByMagnitude[magKey] ?? 0
    }
    
    /// Get best score at specific magnitude
    func bestScoreAtMagnitude(_ magnitude: Double) -> Int {
        let magKey = String(format: "%.1f", magnitude)
        return bestScoreByMagnitude[magKey] ?? 0
    }
    
    /// Calculate survival rating for stats
    private func calculateSurvivalRating(hearts: Int, score: Int) -> SurvivalRating {
        if hearts == 3 && score >= 50 {
            return .survived
        } else if hearts >= 2 && score >= 20 {
            return .injured
        } else {
            return .critical
        }
    }
    
    /// Statistics summary for display
    var summary: StatisticsSummary {
        StatisticsSummary(
            totalGames: totalGamesPlayed,
            survivalRate: totalGamesPlayed > 0 ? Double(totalGamesSurvived) / Double(totalGamesPlayed) * 100 : 0,
            bestScore: bestScore,
            averageScore: averageScore,
            accuracy: accuracyPercentage,
            averageResponseTime: averageResponseTime,
            maxCombo: maxComboEver,
            totalPlayTime: totalPlayTime,
            achievementsUnlocked: unlockedAchievements.count
        )
    }
}

// MARK: - Statistics Summary

/// Lightweight summary for UI display
struct StatisticsSummary: Sendable {
    let totalGames: Int
    let survivalRate: Double
    let bestScore: Int
    let averageScore: Int
    let accuracy: Double
    let averageResponseTime: TimeInterval
    let maxCombo: Int
    let totalPlayTime: TimeInterval
    let achievementsUnlocked: Int
}

// MARK: - Statistics Manager

/// Manages persistent storage and retrieval of game statistics
@MainActor
final class StatisticsManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var stats: GameStatistics
    
    // MARK: - Constants
    
    private let storageKey = "quakeSense_enhancedStats"
    
    // MARK: - Initialization
    
    init() {
        stats = StatisticsManager.loadStats()
    }
    
    // MARK: - Recording Methods
    
    /// Record a completed game with all details
    func recordGame(
        score: Int,
        heartsRemaining: Int,
        correctDecisions: Int,
        wrongDecisions: Int,
        maxCombo: Int,
        magnitude: Double,
        totalTime: TimeInterval,
        decisions: [AdvancedDecisionRecord]
    ) {
        stats.recordGame(
            score: score,
            heartsRemaining: heartsRemaining,
            correctDecisions: correctDecisions,
            wrongDecisions: wrongDecisions,
            maxCombo: maxCombo,
            magnitude: magnitude,
            totalTime: totalTime
        )
        
        // Record individual decisions
        for decision in decisions {
            stats.recordDecision(responseTime: decision.responseTime, isCorrect: decision.isCorrect)
            stats.recordAction(decision.action)
        }
        
        saveStats()
    }
    
    /// Record a single action
    func recordAction(_ action: PlayerAction) {
        stats.recordAction(action)
        saveStats()
    }
    
    /// Record achievement unlock
    func unlockAchievement(id: String, points: Int = 10) {
        stats.unlockAchievement(id: id, points: points)
        saveStats()
    }
    
    // MARK: - Persistence
    
    private static func loadStats() -> GameStatistics {
        let key = "quakeSense_enhancedStats"
        guard let data = UserDefaults.standard.data(forKey: key),
              let stats = try? JSONDecoder().decode(GameStatistics.self, from: data) else {
            return GameStatistics()
        }
        return stats
    }
    
    private func saveStats() {
        if let data = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    /// Reset all statistics
    func resetAll() {
        stats = GameStatistics()
        saveStats()
    }
}

/// Simplified decision record for statistics
struct AdvancedDecisionRecord: Sendable {
    let action: PlayerAction
    let responseTime: TimeInterval
    let isCorrect: Bool
}

// MARK: - Risk Assessor

/// Assesses danger levels for different zones and actions during earthquake
@MainActor
final class RiskAssessor: ObservableObject, Sendable {
    
    // MARK: - Risk Level
    
    enum RiskLevel: String, Sendable, Comparable {
        case safe = "Safe"
        case low = "Low Risk"
        case moderate = "Moderate Risk"
        case high = "High Risk"
        case extreme = "Extreme Risk"
        
        var color: Color {
            switch self {
            case .safe: return .green
            case .low: return .yellow
            case .moderate: return .orange
            case .high: return .red
            case .extreme: return .purple
            }
        }
        
        var iconName: String {
            switch self {
            case .safe: return "checkmark.shield.fill"
            case .low: return "shield.fill"
            case .moderate: return "exclamationmark.triangle.fill"
            case .high: return "exclamationmark.octagon.fill"
            case .extreme: return "xmark.octagon.fill"
            }
        }
        
        var score: Int {
            switch self {
            case .safe: return 0
            case .low: return 1
            case .moderate: return 2
            case .high: return 3
            case .extreme: return 4
            }
        }
        
        static func < (lhs: RiskLevel, rhs: RiskLevel) -> Bool {
            lhs.score < rhs.score
        }
    }
    
    // MARK: - Zone Risk Assessment
    
    struct ZoneRisk: Identifiable, Sendable {
        let id = UUID()
        let zoneName: String
        let riskLevel: RiskLevel
        let primaryHazard: HazardType
        let secondaryHazards: [HazardType]
        let mitigationStrategy: String
        let pointValue: Int // Negative for danger zones
    }
    
    enum HazardType: String, Sendable {
        case fallingObjects = "Falling Objects"
        case glassShatter = "Shattering Glass"
        case structuralCollapse = "Structural Collapse"
        case fire = "Fire Hazard"
        case electrocution = "Electrocution Risk"
        case gasLeak = "Gas Leak"
        case heavyFurniture = "Heavy Furniture"
        case blockedExit = "Blocked Exit"
        case sharpDebris = "Sharp Debris"
        
        var iconName: String {
            switch self {
            case .fallingObjects: return "arrow.down.circle.fill"
            case .glassShatter: return "window.ceiling"
            case .structuralCollapse: return "house.fill"
            case .fire: return "flame.fill"
            case .electrocution: return "bolt.fill"
            case .gasLeak: return "cloud.fill"
            case .heavyFurniture: return "cabinet.fill"
            case .blockedExit: return "door.left.hand.closed"
            case .sharpDebris: return "triangle.fill"
            }
        }
    }
    
    // MARK: - Properties
    
    @Published private(set) var currentIntensity: CGFloat = 0.0
    @Published private(set) var activeHazards: [HazardType] = []
    
    // MARK: - Zone Definitions
    
    /// Get risk assessment for a specific action/zone
    func assessRisk(for action: PlayerAction, intensity: CGFloat, phase: QuakePhase) -> ZoneRisk {
        switch action {
        case .dropUnderTable:
            return ZoneRisk(
                zoneName: "Under Table",
                riskLevel: .safe,
                primaryHazard: .fallingObjects,
                secondaryHazards: [],
                mitigationStrategy: "Table provides protection from falling debris",
                pointValue: 30
            )
            
        case .moveToWindow:
            let risk: RiskLevel = intensity > 0.6 ? .extreme : .high
            return ZoneRisk(
                zoneName: "Window Area",
                riskLevel: risk,
                primaryHazard: .glassShatter,
                secondaryHazards: [.fallingObjects],
                mitigationStrategy: "Stay away from windows during shaking",
                pointValue: -20
            )
            
        case .runToDoor:
            let risk: RiskLevel = phase == .sWave ? .high : .moderate
            return ZoneRisk(
                zoneName: "Doorway",
                riskLevel: risk,
                primaryHazard: .structuralCollapse,
                secondaryHazards: [.fallingObjects],
                mitigationStrategy: "Modern doorways are not stronger than walls",
                pointValue: -15
            )
            
        case .stayStanding:
            let risk: RiskLevel = intensity > 0.5 ? .extreme : .high
            return ZoneRisk(
                zoneName: "Open Area (Standing)",
                riskLevel: risk,
                primaryHazard: .fallingObjects,
                secondaryHazards: [.sharpDebris],
                mitigationStrategy: "Drop to the ground to avoid being knocked down",
                pointValue: -10
            )
            
        case .nearBookshelf:
            let risk: RiskLevel = intensity > 0.5 ? .extreme : .high
            return ZoneRisk(
                zoneName: "Near Bookshelf",
                riskLevel: risk,
                primaryHazard: .heavyFurniture,
                secondaryHazards: [.fallingObjects],
                mitigationStrategy: "Heavy furniture can topple during shaking",
                pointValue: -20
            )
            
        case .shutOffGas:
            return ZoneRisk(
                zoneName: "Gas Valve",
                riskLevel: .low,
                primaryHazard: .gasLeak,
                secondaryHazards: [.fire],
                mitigationStrategy: "Shutting off gas prevents post-quake fires",
                pointValue: 20
            )
            
        case .findSafeExit:
            let risk: RiskLevel = phase == .sWave ? .high : .low
            return ZoneRisk(
                zoneName: "Exit Route",
                riskLevel: risk,
                primaryHazard: .blockedExit,
                secondaryHazards: [.structuralCollapse],
                mitigationStrategy: "Find exit only after shaking stops",
                pointValue: 20
            )
            
        case .checkInjuries:
            return ZoneRisk(
                zoneName: "Self-Assessment",
                riskLevel: .safe,
                primaryHazard: .sharpDebris,
                secondaryHazards: [],
                mitigationStrategy: "Assess injuries before moving",
                pointValue: 15
            )

        case .clearDebris:
            return ZoneRisk(
                zoneName: "Debris Field",
                riskLevel: .low,
                primaryHazard: .sharpDebris,
                secondaryHazards: [],
                mitigationStrategy: "Clearing debris improves mobility",
                pointValue: 5
            )
        }
    }
    
    /// Get all zones sorted by risk level
    func getAllZoneRisks(intensity: CGFloat, phase: QuakePhase) -> [ZoneRisk] {
        PlayerAction.allCases.map { assessRisk(for: $0, intensity: intensity, phase: phase) }
            .sorted { $0.riskLevel > $1.riskLevel }
    }
    
    /// Calculate overall danger score for a scenario
    func calculateDangerScore(magnitude: Double, phase: QuakePhase) -> Int {
        let baseScore = Int((magnitude - 4.0) * 25) // 0-100 based on magnitude
        let phaseMultiplier: Int
        switch phase {
        case .story: phaseMultiplier = 0
        case .calm: phaseMultiplier = 0
        case .countdown: phaseMultiplier = 1
        case .pWave: phaseMultiplier = 2
        case .sWave: phaseMultiplier = 4
        case .aftershock: phaseMultiplier = 3
        case .debrief: phaseMultiplier = 0
        }
        return min(100, baseScore * phaseMultiplier / 2)
    }
    
    /// Get safety recommendation based on current conditions
    func getSafetyRecommendation(phase: QuakePhase, intensity: CGFloat) -> String {
        switch phase {
        case .story:
            return "Take a moment to observe your surroundings."
        case .calm:
            return "Get ready. Identify safe spots like sturdy tables."
        case .countdown:
            return "Earthquake imminent! Position yourself near cover."
        case .pWave:
            return "Early warning! Drop, Cover, and Hold On NOW!"
        case .sWave:
            return intensity > 0.7 
                ? "INTENSE SHAKING! Stay under cover! Avoid windows and heavy objects!"
                : "Strong shaking! Stay calm and hold your position!"
        case .aftershock:
            return "Check for injuries. Shut off gas if you smell it. Find safe exit."
        case .debrief:
            return "Review your decisions and learn for next time."
        }
    }
    
    /// Update current intensity and active hazards
    func updateConditions(intensity: CGFloat, phase: QuakePhase) {
        currentIntensity = intensity
        updateActiveHazards(intensity: intensity, phase: phase)
    }
    
    private func updateActiveHazards(intensity: CGFloat, phase: QuakePhase) {
        var hazards: [HazardType] = []
        
        if phase == .sWave || phase == .aftershock {
            hazards.append(.fallingObjects)
            
            if intensity > 0.5 {
                hazards.append(.heavyFurniture)
            }
            if intensity > 0.6 {
                hazards.append(.glassShatter)
            }
            if intensity > 0.7 {
                hazards.append(.structuralCollapse)
            }
            if phase == .aftershock {
                hazards.append(.gasLeak)
                hazards.append(.fire)
            }
        }
        
        activeHazards = hazards
    }
    
    /// Get color-coded intensity description
    func getIntensityDescription(_ intensity: CGFloat) -> (text: String, color: Color) {
        switch intensity {
        case 0..<0.3: return ("Minimal", .green)
        case 0.3..<0.5: return ("Light", .yellow)
        case 0.5..<0.7: return ("Moderate", .orange)
        case 0.7..<0.9: return ("Strong", .red)
        default: return ("Extreme", .purple)
        }
    }
}

// MARK: - Enhanced Decision Engine

/// Comprehensive decision engine with combo, scoring, and risk assessment
@MainActor
final class EnhancedDecisionEngine: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var decisions: [AdvancedDecision] = []
    @Published var currentScore: Int = 0
    @Published var heartsRemaining: Int = 3
    @Published var currentPhase: QuakePhase = .calm
    @Published var isGameOver: Bool = false
    @Published var hesitationWarning: Bool = false
    @Published var lastDecisionTime: TimeInterval = 0
    
    // MARK: - Sub-systems
    
    let comboSystem = EnhancedComboSystem()
    let difficultyScaler: DifficultyScaler
    let achievementManager = EnhancedAchievementManager()
    let statisticsManager = StatisticsManager()
    let riskAssessor = RiskAssessor()
    
    // MARK: - Game State
    
    let magnitude: Double
    private var quakeStartTime: TimeInterval = 0
    private var decisionStartTime: TimeInterval = 0
    private var maxComboReached: Int = 0
    private var hasMadeIncorrectDecision: Bool = false
    
    // MARK: - Timing Constants
    
    private let hesitationThreshold: TimeInterval = 5.0
    
    // MARK: - Initialization
    
    init(magnitude: Double = 6.0) {
        self.magnitude = magnitude.clamped(to: 4.0...8.0)
        self.difficultyScaler = DifficultyScaler(magnitude: magnitude)
    }
    
    // MARK: - Game Lifecycle
    
    func startGame(at time: TimeInterval) {
        quakeStartTime = time
        decisionStartTime = time
        lastDecisionTime = time
        
        comboSystem.reset()
        achievementManager.onGameStart()
        riskAssessor.updateConditions(intensity: 0.0, phase: .calm)
        
        maxComboReached = 0
        hasMadeIncorrectDecision = false
        
        currentPhase = .pWave
    }
    
    func recordDecision(_ action: PlayerAction, at timestamp: TimeInterval) -> AdvancedDecision {
        let responseTime = timestamp - decisionStartTime
        let isHesitated = responseTime > hesitationThreshold
        let parameters = difficultyScaler.currentParameters
        
        // Assess risk for this action
        let risk = riskAssessor.assessRisk(for: action, intensity: parameters.intensityMultiplier, phase: currentPhase)
        
        // Update combo system
        if action.isCorrect {
            comboSystem.recordCorrectDecision()
        } else {
            comboSystem.breakCombo()
            hasMadeIncorrectDecision = true
        }
        
        // Track max combo
        maxComboReached = max(maxComboReached, comboSystem.consecutiveCorrectDecisions)
        
        // Create enhanced decision
        let decision = AdvancedDecision(
            action: action,
            timestamp: timestamp,
            previousTimestamp: lastDecisionTime,
            comboMultiplier: comboSystem.currentMultiplier,
            isHesitated: isHesitated,
            riskLevel: risk.riskLevel,
            responseTime: responseTime,
            difficultyMultiplier: parameters.scoreMultiplier
        )
        
        decisions.append(decision)
        
        // Calculate final score with all multipliers
        let finalPoints = decision.calculateFinalScore()
        currentScore += finalPoints
        
        // Update hearts
        if !action.isCorrect {
            heartsRemaining = max(0, heartsRemaining - 1)
            if heartsRemaining == 0 {
                isGameOver = true
            }
        }
        
        // Track in sub-systems
        achievementManager.onDecision(action: action, isCorrect: action.isCorrect, responseTime: responseTime)
        statisticsManager.recordAction(action)
        
        // Update timing
        lastDecisionTime = timestamp
        decisionStartTime = timestamp
        hesitationWarning = false
        
        return decision
    }
    
    func updatePhase(_ phase: QuakePhase) {
        currentPhase = phase
        riskAssessor.updateConditions(
            intensity: difficultyScaler.currentParameters.intensityMultiplier,
            phase: phase
        )
        
        if phase == .debrief {
            finalizeGame()
        }
    }
    
    func checkHesitation(at currentTime: TimeInterval) -> Bool {
        let elapsed = currentTime - decisionStartTime
        hesitationWarning = elapsed > hesitationThreshold
        return hesitationWarning
    }
    
    // MARK: - Finalization
    
    private func finalizeGame() {
        isGameOver = true
        
        let correctDecisions = decisions.filter { $0.isCorrect }.count
        let totalDecisions = decisions.count
        let totalTime = decisions.last?.timestamp ?? 0
        
        // Update achievement manager
        achievementManager.onGameEnd(
            score: currentScore,
            totalTime: totalTime,
            heartsRemaining: heartsRemaining,
            correctDecisions: correctDecisions,
            totalDecisions: totalDecisions,
            maxCombo: maxComboReached,
            magnitude: magnitude,
            gamesPlayed: statisticsManager.stats.totalGamesPlayed + 1
        )
        
        // Record in statistics
        let decisionRecords = decisions.map {
            AdvancedDecisionRecord(
                action: $0.action,
                responseTime: $0.responseTime,
                isCorrect: $0.isCorrect
            )
        }
        
        statisticsManager.recordGame(
            score: currentScore,
            heartsRemaining: heartsRemaining,
            correctDecisions: correctDecisions,
            wrongDecisions: totalDecisions - correctDecisions,
            maxCombo: maxComboReached,
            magnitude: magnitude,
            totalTime: totalTime,
            decisions: decisionRecords
        )
    }
    
    // MARK: - Scoring & Rating
    
    func calculateSurvivalRating() -> SurvivalRating {
        if heartsRemaining == 3 && currentScore >= 50 {
            return .survived
        } else if heartsRemaining >= 2 && currentScore >= 20 {
            return .injured
        } else {
            return .critical
        }
    }
    
    // MARK: - Reset
    
    func reset() {
        decisions = []
        currentScore = 0
        heartsRemaining = 3
        currentPhase = .calm
        isGameOver = false
        hesitationWarning = false
        lastDecisionTime = 0
        quakeStartTime = 0
        decisionStartTime = 0
        maxComboReached = 0
        hasMadeIncorrectDecision = false
        comboSystem.reset()
    }
}

// MARK: - Advanced Decision

/// Extended decision with comprehensive scoring information
struct AdvancedDecision: Identifiable, Sendable {
    let id: UUID
    let action: PlayerAction
    let timestamp: TimeInterval
    let isCorrect: Bool
    let basePoints: Int
    let timeBonus: Int
    let comboMultiplier: Int
    let hesitationPenalty: Int
    let stylePoints: Int
    let responseTime: TimeInterval
    let riskLevel: RiskAssessor.RiskLevel
    let difficultyMultiplier: Double
    
    /// Total calculated points
    var totalPoints: Int {
        calculateFinalScore()
    }
    
    init(
        action: PlayerAction,
        timestamp: TimeInterval,
        previousTimestamp: TimeInterval,
        comboMultiplier: Int,
        isHesitated: Bool,
        riskLevel: RiskAssessor.RiskLevel,
        responseTime: TimeInterval,
        difficultyMultiplier: Double
    ) {
        self.id = UUID()
        self.action = action
        self.timestamp = timestamp
        self.isCorrect = action.isCorrect
        self.basePoints = action.basePoints
        self.comboMultiplier = comboMultiplier
        self.responseTime = responseTime
        self.riskLevel = riskLevel
        self.difficultyMultiplier = difficultyMultiplier
        
        // Time bonus calculation
        if action.isCorrect {
            if responseTime < 0.5 {
                self.timeBonus = 20
            } else if responseTime < 1.0 {
                self.timeBonus = 15
            } else if responseTime < 2.0 {
                self.timeBonus = 10
            } else if responseTime < 3.5 {
                self.timeBonus = 5
            } else {
                self.timeBonus = 0
            }
        } else {
            self.timeBonus = 0
        }
        
        // Hesitation penalty
        self.hesitationPenalty = isHesitated && action.isCorrect ? 5 : 0
        
        // Style points for quick combos
        if action.isCorrect && responseTime < 1.5 && comboMultiplier > 1 {
            self.stylePoints = 5 * comboMultiplier
        } else {
            self.stylePoints = 0
        }
    }
    
    /// Calculate final score with all multipliers applied
    func calculateFinalScore() -> Int {
        guard isCorrect else { return basePoints }
        
        let subtotal = basePoints + timeBonus + stylePoints - hesitationPenalty
        let comboApplied = subtotal * comboMultiplier
        let difficultyApplied = Int(Double(comboApplied) * difficultyMultiplier)
        return difficultyApplied
    }
    
    /// Breakdown of score components for display
    var scoreBreakdown: ScoreBreakdown {
        ScoreBreakdown(
            basePoints: basePoints,
            timeBonus: timeBonus,
            comboMultiplier: comboMultiplier,
            comboBonus: (basePoints + timeBonus) * (comboMultiplier - 1),
            stylePoints: stylePoints,
            hesitationPenalty: hesitationPenalty,
            difficultyMultiplier: difficultyMultiplier,
            total: totalPoints
        )
    }
}

// MARK: - Score Breakdown

/// Detailed breakdown of score calculation
struct ScoreBreakdown: Sendable {
    let basePoints: Int
    let timeBonus: Int
    let comboMultiplier: Int
    let comboBonus: Int
    let stylePoints: Int
    let hesitationPenalty: Int
    let difficultyMultiplier: Double
    let total: Int
    
    /// Formatted description of the breakdown
    var description: String {
        var parts: [String] = []
        parts.append("Base: \(basePoints)")
        if timeBonus > 0 { parts.append("Speed: +\(timeBonus)") }
        if comboBonus > 0 { parts.append("Combo: +\(comboBonus)") }
        if stylePoints > 0 { parts.append("Style: +\(stylePoints)") }
        if hesitationPenalty > 0 { parts.append("Hesitation: -\(hesitationPenalty)") }
        parts.append("Multiplier: \(String(format: "%.1f", difficultyMultiplier))x")
        return parts.joined(separator: " | ")
    }
}

