import Foundation

// MARK: - Player Action

enum PlayerAction: String, CaseIterable, Sendable {
    case dropUnderTable
    case moveToWindow
    case runToDoor
    case stayStanding
    case nearBookshelf
    case shutOffGas
    case findSafeExit
    case checkInjuries
    case clearDebris

    var isCorrect: Bool {
        switch self {
        case .dropUnderTable, .shutOffGas, .findSafeExit, .checkInjuries, .clearDebris:
            return true
        case .moveToWindow, .runToDoor, .stayStanding, .nearBookshelf:
            return false
        }
    }

    var basePoints: Int {
        switch self {
        case .dropUnderTable:   return 30
        case .moveToWindow:     return -20
        case .runToDoor:        return -15
        case .stayStanding:     return -10
        case .nearBookshelf:    return -20
        case .shutOffGas:       return 20
        case .findSafeExit:     return 20
        case .checkInjuries:    return 15
        case .clearDebris:      return 5
        }
    }

    var feedback: String {
        switch self {
        case .dropUnderTable:
            return String(localized: "Tables protect from falling debris — great instinct!")
        case .moveToWindow:
            return String(localized: "Windows shatter during earthquakes — stay away from glass!")
        case .runToDoor:
            return String(localized: "Doorways are NOT safer — this is a common myth!")
        case .stayStanding:
            return String(localized: "Drop, Cover, Hold On! Standing makes you a target for debris.")
        case .nearBookshelf:
            return String(localized: "Heavy furniture can topple — never shelter near bookshelves!")
        case .shutOffGas:
            return String(localized: "Checking gas prevents fires after earthquakes — smart move!")
        case .findSafeExit:
            return String(localized: "Finding a safe exit after shaking stops is crucial.")
        case .checkInjuries:
            return String(localized: "Checking for injuries helps you assess the situation.")
        case .clearDebris:
            return String(localized: "Clearing debris from your path improves your mobility!")
        }
    }

    var displayName: String {
        switch self {
        case .dropUnderTable: return String(localized: "Took cover under table")
        case .moveToWindow:   return String(localized: "Moved to window")
        case .runToDoor:      return String(localized: "Ran to door")
        case .stayStanding:   return String(localized: "Stayed standing")
        case .nearBookshelf:  return String(localized: "Went near bookshelf")
        case .shutOffGas:     return String(localized: "Shut off gas valve")
        case .findSafeExit:   return String(localized: "Found safe exit")
        case .checkInjuries:  return String(localized: "Checked for injuries")
        case .clearDebris:    return String(localized: "Cleared debris")
        }
    }

    var iconName: String {
        switch self {
        case .dropUnderTable: return "arrow.down.to.line"
        case .moveToWindow:   return "window.ceiling"
        case .runToDoor:      return "door.left.hand.open"
        case .stayStanding:   return "figure.stand"
        case .nearBookshelf:  return "books.vertical"
        case .shutOffGas:     return "flame.fill"
        case .findSafeExit:   return "figure.walk.departure"
        case .checkInjuries:  return "cross.case"
        case .clearDebris:    return "hand.raised.fill"
        }
    }

    /// Actions available during earthquake main phase
    static var mainPhaseActions: [PlayerAction] {
        [.dropUnderTable, .moveToWindow, .runToDoor, .stayStanding, .nearBookshelf]
    }

    /// Actions available during aftershock phase
    static var aftershockActions: [PlayerAction] {
        [.shutOffGas, .findSafeExit, .checkInjuries]
    }
}

// MARK: - Decision

struct Decision: Identifiable, Sendable, Hashable {
    let id: UUID
    let action: PlayerAction
    let timestamp: TimeInterval
    let isCorrect: Bool
    let pointsAwarded: Int
    let feedback: String

    init(action: PlayerAction, timestamp: TimeInterval, timeBonusPoints: Int = 0) {
        self.id = UUID()
        self.action = action
        self.timestamp = timestamp
        self.isCorrect = action.isCorrect
        self.pointsAwarded = action.basePoints + (action.isCorrect ? timeBonusPoints : 0)
        self.feedback = action.feedback
    }
}

// MARK: - Survival Rating

enum SurvivalRating: String, Sendable, Hashable {
    case survived = "SURVIVED"
    case injured = "INJURED"
    case critical = "CRITICAL"

    var iconName: String {
        switch self {
        case .survived: return "checkmark.shield.fill"
        case .injured:  return "exclamationmark.triangle.fill"
        case .critical: return "xmark.octagon.fill"
        }
    }

    var description: String {
        switch self {
        case .survived: return String(localized: "You made smart choices and survived!")
        case .injured:  return String(localized: "You survived but sustained injuries.")
        case .critical: return String(localized: "Your choices put you in serious danger.")
        }
    }
}

// MARK: - Quake Phase

enum QuakePhase: String, Sendable {
    case story
    case calm
    case countdown
    case pWave
    case sWave
    case aftershock
    case debrief
}

// MARK: - Debrief Report

struct DebriefReport: Sendable, Hashable {
    let decisions: [Decision]
    let finalScore: Int
    let heartsRemaining: Int
    let survivalRating: SurvivalRating
    let magnitude: Double
    let totalTime: TimeInterval
}
