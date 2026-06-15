import Foundation
import Combine

// MARK: - Difficulty Level

/// Difficulty levels based on earthquake magnitude
enum DifficultyLevel: String, CaseIterable, Sendable, Codable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    
    /// Get difficulty from magnitude
    static func from(magnitude: Double) -> DifficultyLevel {
        switch magnitude {
        case 4.0..<5.5:
            return .easy
        case 5.5..<7.0:
            return .medium
        default:
            return .hard
        }
    }
    
    /// Multiplier for object fall speed
    var objectFallSpeedMultiplier: CGFloat {
        switch self {
        case .easy:   return 0.7
        case .medium: return 1.0
        case .hard:   return 1.4
        }
    }
    
    /// Decision time window in seconds
    var decisionTimeWindow: TimeInterval {
        switch self {
        case .easy:   return 5.0
        case .medium: return 3.5
        case .hard:   return 2.5
        }
    }
    
    /// Additional debris count modifier
    var extraDebrisCount: Int {
        switch self {
        case .easy:   return 0
        case .medium: return 2
        case .hard:   return 5
        }
    }
    
    /// Score multiplier for the difficulty
    var scoreMultiplier: Double {
        switch self {
        case .easy:   return 1.0
        case .medium: return 1.2
        case .hard:   return 1.5
        }
    }
    
    /// Color for UI representation
    var displayColor: String {
        switch self {
        case .easy:   return "34C759"  // Green
        case .medium: return "FF9500"  // Orange
        case .hard:   return "FF3B30"  // Red
        }
    }
}

// MARK: - Combo System

/// Tracks consecutive correct decisions for bonus multipliers
/// 4-tier system: 1x (0-1), 2x (2-3), 3x (4-6), 4x (7+)
struct ComboSystem: Sendable {
    private(set) var consecutiveCorrectDecisions: Int = 0

    /// 4-tier multiplier: 1x (0-1), 2x (2-3), 3x (4-6), 4x (7+)
    var currentMultiplier: Int {
        switch consecutiveCorrectDecisions {
        case 0...1: return 1
        case 2...3: return 2
        case 4...6: return 3
        default: return 4
        }
    }

    /// Rich combo descriptions including UNSTOPPABLE and LEGENDARY
    var comboDescription: String {
        switch consecutiveCorrectDecisions {
        case 0: return ""
        case 1: return "Good!"
        case 2: return "2x COMBO!"
        case 3...4: return "3x COMBO!"
        case 5...6: return "COMBO MASTER!"
        case 7...9: return "UNSTOPPABLE!"
        default: return "LEGENDARY!"
        }
    }

    /// Visual intensity level for UI effects (0-3)
    var visualIntensity: Int {
        min(3, consecutiveCorrectDecisions / 2)
    }

    /// Progress to next tier (0.0 - 1.0)
    var progressToNextTier: Double {
        switch consecutiveCorrectDecisions {
        case 0...1: return Double(consecutiveCorrectDecisions) / 2.0
        case 2...3: return Double(consecutiveCorrectDecisions - 1) / 3.0
        case 4...6: return Double(consecutiveCorrectDecisions - 3) / 4.0
        default: return 1.0
        }
    }

    /// Maximum multiplier achieved
    var isMaxCombo: Bool {
        consecutiveCorrectDecisions >= 7
    }

    /// Call when player makes a correct decision
    mutating func recordCorrectDecision() {
        consecutiveCorrectDecisions += 1
    }

    /// Call when player makes a wrong decision - breaks the combo
    mutating func breakCombo() {
        consecutiveCorrectDecisions = 0
    }

    /// Reset combo at game start
    mutating func reset() {
        consecutiveCorrectDecisions = 0
    }

    /// Check if combo master achievement should unlock (5+ combo)
    var isComboMaster: Bool {
        consecutiveCorrectDecisions >= 5
    }
}

// MARK: - Achievement System

/// Represents a game achievement (legacy - kept for compatibility)
struct GameAchievement: Identifiable, Sendable, Equatable {
    let id: String
    let title: String
    let description: String
    let icon: String
    var isUnlocked: Bool
    let condition: AchievementCondition
    let dateUnlocked: Date?
    
    init(id: String, title: String, description: String, icon: String, 
         isUnlocked: Bool = false, condition: AchievementCondition, dateUnlocked: Date? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.isUnlocked = isUnlocked
        self.condition = condition
        self.dateUnlocked = dateUnlocked
    }
    
    static func == (lhs: GameAchievement, rhs: GameAchievement) -> Bool {
        lhs.id == rhs.id
    }
}

/// Types of achievement conditions
enum AchievementCondition: Sendable {
    case firstGame                    // Play first game
    case speedDemon                   // Decision under 1 second
    case perfectRun                   // All decisions correct
    case survivor                     // End with 3 hearts
    case comboMaster                  // 5x combo reached
    case gasExpert                   // Shut off gas in aftershock
    case quickThinker                // 3 correct decisions under 2s each
}

// MARK: - Player Stats

/// Persistent player statistics
struct PlayerStats: Codable, Sendable {
    var totalGamesPlayed: Int = 0
    var bestScore: Int = 0
    var totalScore: Int = 0  // For calculating average
    var totalCorrectDecisions: Int = 0
    var totalWrongDecisions: Int = 0
    var actionFrequency: [String: Int] = [:]  // Track favorite action
    var achievementsUnlocked: [String: Date] = [:]
    
    var averageScore: Int {
        totalGamesPlayed > 0 ? totalScore / totalGamesPlayed : 0
    }
    
    var accuracyPercentage: Double {
        let total = totalCorrectDecisions + totalWrongDecisions
        return total > 0 ? Double(totalCorrectDecisions) / Double(total) * 100 : 0
    }
    
    var favoriteAction: PlayerAction? {
        guard let maxEntry = actionFrequency.max(by: { $0.value < $1.value }) else { return nil }
        return PlayerAction(rawValue: maxEntry.key)
    }
    
    mutating func recordGame(score: Int, correct: Int, wrong: Int) {
        totalGamesPlayed += 1
        totalScore += score
        bestScore = max(bestScore, score)
        totalCorrectDecisions += correct
        totalWrongDecisions += wrong
    }
    
    mutating func recordAction(_ action: PlayerAction) {
        actionFrequency[action.rawValue, default: 0] += 1
    }
    
    mutating func unlockGameAchievement(id: String) {
        if achievementsUnlocked[id] == nil {
            achievementsUnlocked[id] = Date()
        }
    }
    
    func isAchievementUnlocked(id: String) -> Bool {
        achievementsUnlocked[id] != nil
    }
}

// MARK: - Enhanced Decision

/// Extended decision with combo and timing info
struct EnhancedDecision: Identifiable, Sendable {
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
    
    var totalPoints: Int {
        let subtotal = basePoints + timeBonus + stylePoints - hesitationPenalty
        return isCorrect ? subtotal * comboMultiplier : subtotal
    }
    
    init(action: PlayerAction, timestamp: TimeInterval, previousTimestamp: TimeInterval,
         comboMultiplier: Int, isHesitated: Bool = false) {
        self.id = UUID()
        self.action = action
        self.timestamp = timestamp
        self.isCorrect = action.isCorrect
        self.basePoints = action.basePoints
        self.comboMultiplier = comboMultiplier
        self.responseTime = timestamp - previousTimestamp
        
        // Time bonus calculation (faster = more points)
        if action.isCorrect {
            if responseTime < 1.0 {
                self.timeBonus = 15  // Speed demon territory
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
        
        // Hesitation penalty for taking too long
        self.hesitationPenalty = isHesitated && action.isCorrect ? 5 : 0
        
        // Style points for quick consecutive decisions
        if action.isCorrect && responseTime < 1.5 && comboMultiplier > 1 {
            self.stylePoints = 5 * comboMultiplier
        } else {
            self.stylePoints = 0
        }
    }
}

// MARK: - Enhanced Debrief Report

struct EnhancedDebriefReport: Sendable, Hashable {
    static func == (lhs: EnhancedDebriefReport, rhs: EnhancedDebriefReport) -> Bool {
        lhs.finalScore == rhs.finalScore && lhs.totalTime == rhs.totalTime && lhs.magnitude == rhs.magnitude
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(finalScore)
        hasher.combine(totalTime)
        hasher.combine(magnitude)
    }

    let decisions: [EnhancedDecision]
    let finalScore: Int
    let heartsRemaining: Int
    let survivalRating: SurvivalRating
    let magnitude: Double
    let difficulty: DifficultyLevel
    let totalTime: TimeInterval
    let maxCombo: Int
    let achievementsUnlocked: [GameAchievement]
    let playerStats: PlayerStats
    
    var accuracyPercentage: Double {
        guard !decisions.isEmpty else { return 0 }
        let correct = decisions.filter { $0.isCorrect }.count
        return Double(correct) / Double(decisions.count) * 100
    }
    
    var totalCorrectDecisions: Int {
        decisions.filter { $0.isCorrect }.count
    }
    
    var averageResponseTime: TimeInterval {
        guard !decisions.isEmpty else { return 0 }
        return decisions.map { $0.responseTime }.reduce(0, +) / Double(decisions.count)
    }
}

// MARK: - Enhanced Decision Engine

@MainActor
final class DecisionEngine: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var decisions: [EnhancedDecision] = []
    @Published var currentScore: Int = 0
    @Published var heartsRemaining: Int = 3
    @Published var currentPhase: QuakePhase = .calm
    @Published var isGameOver: Bool = false
    @Published var currentCombo: Int = 0
    @Published var comboMultiplier: Int = 1
    @Published var lastComboDescription: String = ""
    @Published var newlyUnlockedAchievements: [GameAchievement] = []
    @Published var hesitationWarning: Bool = false
    
    // MARK: - Game State
    
    let scenario: QuakeScenario
    var difficulty: DifficultyLevel { DifficultyLevel.from(magnitude: scenario.magnitude) }
    
    private var quakeStartTime: TimeInterval = 0
    var lastDecisionTime: TimeInterval = 0
    private var decisionStartTime: TimeInterval = 0
    private var recordedMainActions: Set<String> = []
    private var recordedAftershockActions: Set<String> = []
    private var comboSystem = ComboSystem()
    private var quickDecisionCount: Int = 0  // For Quick Thinker achievement
    private var hasShutOffGas: Bool = false
    
    // MARK: - Stats & Achievements
    
    @Published var playerStats: PlayerStats = DecisionEngine.loadStats()
    @Published var achievements: [GameAchievement] = []
    private var maxComboReached: Int = 0
    
    // MARK: - Constants
    
    private let hesitationThreshold: TimeInterval = 5.0
    private let speedDemonThreshold: TimeInterval = 1.0
    private let quickThinkerThreshold: TimeInterval = 2.0
    
    // MARK: - Initialization
    
    init(scenario: QuakeScenario = .default) {
        self.scenario = scenario
        self.achievements = DecisionEngine.createDefaultAchievements()
        loadAchievementProgress()
    }
    
    // MARK: - Game Lifecycle
    
    func startQuake(at time: TimeInterval) {
        quakeStartTime = time
        lastDecisionTime = time
        decisionStartTime = time
        currentPhase = .pWave
        comboSystem.reset()
        quickDecisionCount = 0
        hasShutOffGas = false
        maxComboReached = 0
        newlyUnlockedAchievements = []
        updateComboDisplay()
    }
    
    func recordDecision(_ action: PlayerAction, at timestamp: TimeInterval) -> Decision {
        // Check for hesitation
        let responseTime = timestamp - decisionStartTime
        let isHesitated = responseTime > hesitationThreshold
        hesitationWarning = isHesitated
        
        // Update combo system
        if action.isCorrect {
            comboSystem.recordCorrectDecision()
            
            // Track quick decisions for Quick Thinker achievement
            if responseTime < quickThinkerThreshold {
                quickDecisionCount += 1
            }
            
            // Track gas shutoff
            if action == .shutOffGas {
                hasShutOffGas = true
            }
        } else {
            comboSystem.breakCombo()
            quickDecisionCount = 0
        }
        
        // Track max combo
        maxComboReached = max(maxComboReached, comboSystem.consecutiveCorrectDecisions)
        
        // Create enhanced decision
        let decision = EnhancedDecision(
            action: action,
            timestamp: timestamp,
            previousTimestamp: lastDecisionTime,
            comboMultiplier: comboSystem.currentMultiplier,
            isHesitated: isHesitated
        )
        
        decisions.append(decision)
        
        // Calculate score with difficulty multiplier
        let difficultyBonus = Int(Double(decision.totalPoints) * (difficulty.scoreMultiplier - 1.0))
        let finalPoints = decision.totalPoints + (action.isCorrect ? difficultyBonus : 0)
        currentScore += finalPoints
        
        // Update hearts
        if !action.isCorrect {
            heartsRemaining = max(0, heartsRemaining - 1)
            if heartsRemaining == 0 {
                isGameOver = true
            }
        }
        
        // Track actions
        if PlayerAction.mainPhaseActions.contains(action) {
            recordedMainActions.insert(action.rawValue)
        } else {
            recordedAftershockActions.insert(action.rawValue)
        }
        
        // Update display
        lastDecisionTime = timestamp
        decisionStartTime = timestamp
        updateComboDisplay()
        
        // Check achievements
        checkAchievements(decision: decision, responseTime: responseTime)
        
        // Update stats
        playerStats.recordAction(action)
        
        // Convert to Decision for compatibility
        return Decision(
            action: decision.action,
            timestamp: decision.timestamp,
            timeBonusPoints: decision.timeBonus
        )
    }
    
    func updatePhase(_ phase: QuakePhase) {
        currentPhase = phase
        if phase == .debrief {
            isGameOver = true
            finalizeGame()
        }
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
    
    /// Generate legacy DebriefReport for backward compatibility with existing views
    func generateReport(totalTime: TimeInterval) -> DebriefReport {
        // Convert EnhancedDecision array to legacy Decision-compatible format
        let legacyDecisions = decisions.map { enhanced -> Decision in
            // Create a Decision by mapping EnhancedDecision properties
            Decision(
                action: enhanced.action,
                timestamp: enhanced.timestamp,
                timeBonusPoints: enhanced.timeBonus + enhanced.stylePoints - enhanced.hesitationPenalty
            )
        }
        
        return DebriefReport(
            decisions: legacyDecisions,
            finalScore: max(0, currentScore),
            heartsRemaining: heartsRemaining,
            survivalRating: calculateSurvivalRating(),
            magnitude: scenario.magnitude,
            totalTime: totalTime
        )
    }
    
    /// Generate enhanced report with all new features
    func generateEnhancedReport(totalTime: TimeInterval) -> EnhancedDebriefReport {
        EnhancedDebriefReport(
            decisions: decisions,
            finalScore: max(0, currentScore),
            heartsRemaining: heartsRemaining,
            survivalRating: calculateSurvivalRating(),
            magnitude: scenario.magnitude,
            difficulty: difficulty,
            totalTime: totalTime,
            maxCombo: maxComboReached,
            achievementsUnlocked: newlyUnlockedAchievements,
            playerStats: playerStats
        )
    }
    
    // MARK: - Achievement System
    
    private static func createDefaultAchievements() -> [GameAchievement] {
        [
            GameAchievement(
                id: "first_timer",
                title: "First Timer",
                description: "Complete your first earthquake simulation",
                icon: "play.fill",
                condition: .firstGame
            ),
            GameAchievement(
                id: "speed_demon",
                title: "Speed Demon",
                description: "Make a correct decision in under 1 second",
                icon: "bolt.fill",
                condition: .speedDemon
            ),
            GameAchievement(
                id: "perfect_run",
                title: "Perfect Run",
                description: "Make all correct decisions in a single game",
                icon: "checkmark.seal.fill",
                condition: .perfectRun
            ),
            GameAchievement(
                id: "survivor",
                title: "Survivor",
                description: "Complete a game with all 3 hearts remaining",
                icon: "heart.fill",
                condition: .survivor
            ),
            GameAchievement(
                id: "combo_master",
                title: "Combo Master",
                description: "Achieve a 5x combo",
                icon: "flame.fill",
                condition: .comboMaster
            ),
            GameAchievement(
                id: "gas_expert",
                title: "Gas Expert",
                description: "Shut off the gas valve during aftershock",
                icon: "flame.circle.fill",
                condition: .gasExpert
            ),
            GameAchievement(
                id: "quick_thinker",
                title: "Quick Thinker",
                description: "Make 3 correct decisions in under 2 seconds each",
                icon: "brain.head.profile",
                condition: .quickThinker
            )
        ]
    }
    
    private func checkAchievements(decision: EnhancedDecision, responseTime: TimeInterval) {
        var newlyUnlocked: [GameAchievement] = []
        
        for index in achievements.indices where !achievements[index].isUnlocked {
            var shouldUnlock = false
            
            switch achievements[index].condition {
            case .firstGame:
                shouldUnlock = true  // Will be set on game end
                
            case .speedDemon:
                shouldUnlock = decision.isCorrect && responseTime < speedDemonThreshold
                
            case .perfectRun:
                shouldUnlock = false  // Checked at game end
                
            case .survivor:
                shouldUnlock = false  // Checked at game end
                
            case .comboMaster:
                shouldUnlock = comboSystem.isComboMaster
                
            case .gasExpert:
                shouldUnlock = hasShutOffGas
                
            case .quickThinker:
                shouldUnlock = quickDecisionCount >= 3
            }
            
            if shouldUnlock {
                achievements[index].isUnlocked = true
                achievements[index] = GameAchievement(
                    id: achievements[index].id,
                    title: achievements[index].title,
                    description: achievements[index].description,
                    icon: achievements[index].icon,
                    isUnlocked: true,
                    condition: achievements[index].condition,
                    dateUnlocked: Date()
                )
                newlyUnlocked.append(achievements[index])
                playerStats.unlockGameAchievement(id: achievements[index].id)
            }
        }
        
        if !newlyUnlocked.isEmpty {
            newlyUnlockedAchievements.append(contentsOf: newlyUnlocked)
            saveStats()
        }
    }
    
    private func finalizeGame() {
        let correctCount = decisions.filter { $0.isCorrect }.count
        let wrongCount = decisions.count - correctCount
        
        // Update player stats
        playerStats.recordGame(
            score: max(0, currentScore),
            correct: correctCount,
            wrong: wrongCount
        )
        
        // Check end-game achievements
        checkEndGameAchievements(correctCount: correctCount, wrongCount: wrongCount)
        
        saveStats()
    }
    
    private func checkEndGameAchievements(correctCount: Int, wrongCount: Int) {
        var newlyUnlocked: [GameAchievement] = []
        
        // First Timer
        if let index = achievements.firstIndex(where: { $0.id == "first_timer" && !$0.isUnlocked }) {
            achievements[index].isUnlocked = true
            achievements[index] = GameAchievement(
                id: achievements[index].id,
                title: achievements[index].title,
                description: achievements[index].description,
                icon: achievements[index].icon,
                isUnlocked: true,
                condition: achievements[index].condition,
                dateUnlocked: Date()
            )
            newlyUnlocked.append(achievements[index])
            playerStats.unlockGameAchievement(id: "first_timer")
        }
        
        // Perfect Run (all correct decisions, at least 3 decisions made)
        if wrongCount == 0 && correctCount >= 3 {
            if let index = achievements.firstIndex(where: { $0.id == "perfect_run" && !$0.isUnlocked }) {
                achievements[index].isUnlocked = true
                achievements[index] = GameAchievement(
                    id: achievements[index].id,
                    title: achievements[index].title,
                    description: achievements[index].description,
                    icon: achievements[index].icon,
                    isUnlocked: true,
                    condition: achievements[index].condition,
                    dateUnlocked: Date()
                )
                newlyUnlocked.append(achievements[index])
                playerStats.unlockGameAchievement(id: "perfect_run")
            }
        }
        
        // Survivor (3 hearts remaining)
        if heartsRemaining == 3 {
            if let index = achievements.firstIndex(where: { $0.id == "survivor" && !$0.isUnlocked }) {
                achievements[index].isUnlocked = true
                achievements[index] = GameAchievement(
                    id: achievements[index].id,
                    title: achievements[index].title,
                    description: achievements[index].description,
                    icon: achievements[index].icon,
                    isUnlocked: true,
                    condition: achievements[index].condition,
                    dateUnlocked: Date()
                )
                newlyUnlocked.append(achievements[index])
                playerStats.unlockGameAchievement(id: "survivor")
            }
        }
        
        if !newlyUnlocked.isEmpty {
            newlyUnlockedAchievements.append(contentsOf: newlyUnlocked)
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateComboDisplay() {
        currentCombo = comboSystem.consecutiveCorrectDecisions
        comboMultiplier = comboSystem.currentMultiplier
        lastComboDescription = comboSystem.comboDescription
    }
    
    /// Get the adjusted debris count based on difficulty
    func getAdjustedDebrisCount() -> Int {
        scenario.debrisCount + difficulty.extraDebrisCount
    }
    
    /// Check if decision is taking too long
    func checkHesitation(at currentTime: TimeInterval) -> Bool {
        let elapsed = currentTime - decisionStartTime
        hesitationWarning = elapsed > hesitationThreshold
        return hesitationWarning
    }
    
    // MARK: - Persistence
    
    private static func loadStats() -> PlayerStats {
        guard let data = UserDefaults.standard.data(forKey: "quakeSense_playerStats"),
              let stats = try? JSONDecoder().decode(PlayerStats.self, from: data) else {
            return PlayerStats()
        }
        return stats
    }
    
    private func saveStats() {
        if let data = try? JSONEncoder().encode(playerStats) {
            UserDefaults.standard.set(data, forKey: "quakeSense_playerStats")
        }
        
        // Also save achievement states
        let achievementStates = achievements.map { [
            "id": $0.id,
            "unlocked": $0.isUnlocked,
            "date": $0.dateUnlocked?.timeIntervalSince1970 ?? 0
        ] }
        UserDefaults.standard.set(achievementStates, forKey: "quakeSense_achievements")
    }
    
    private func loadAchievementProgress() {
        guard let saved = UserDefaults.standard.array(forKey: "quakeSense_achievements") as? [[String: Any]] else {
            return
        }
        
        for item in saved {
            if let id = item["id"] as? String,
               let unlocked = item["unlocked"] as? Bool,
               unlocked,
               let index = achievements.firstIndex(where: { $0.id == id }) {
                let date = item["date"] as? TimeInterval ?? 0
                achievements[index] = GameAchievement(
                    id: achievements[index].id,
                    title: achievements[index].title,
                    description: achievements[index].description,
                    icon: achievements[index].icon,
                    isUnlocked: true,
                    condition: achievements[index].condition,
                    dateUnlocked: date > 0 ? Date(timeIntervalSince1970: date) : nil
                )
            }
        }
    }
    
    func reset() {
        decisions = []
        currentScore = 0
        heartsRemaining = 3
        currentPhase = .calm
        isGameOver = false
        quakeStartTime = 0
        lastDecisionTime = 0
        decisionStartTime = 0
        recordedMainActions = []
        recordedAftershockActions = []
        comboSystem.reset()
        currentCombo = 0
        comboMultiplier = 1
        lastComboDescription = ""
        newlyUnlockedAchievements = []
        hesitationWarning = false
        quickDecisionCount = 0
        hasShutOffGas = false
        maxComboReached = 0
    }
    
    /// Reset all stats and achievements (for testing/debugging)
    func resetAllProgress() {
        playerStats = PlayerStats()
        achievements = DecisionEngine.createDefaultAchievements()
        saveStats()
    }
}

// MARK: - Difficulty Presets

extension DecisionEngine {
    /// Get recommended game parameters for current difficulty
    var gameParameters: GameParameters {
        GameParameters(
            objectFallSpeed: difficulty.objectFallSpeedMultiplier,
            decisionTimeWindow: difficulty.decisionTimeWindow,
            debrisCount: getAdjustedDebrisCount(),
            scoreMultiplier: difficulty.scoreMultiplier,
            shakeIntensity: scenario.intensityMultiplier
        )
    }
}

/// Game parameters adjusted by difficulty
struct GameParameters: Sendable {
    let objectFallSpeed: CGFloat
    let decisionTimeWindow: TimeInterval
    let debrisCount: Int
    let scoreMultiplier: Double
    let shakeIntensity: CGFloat
}
