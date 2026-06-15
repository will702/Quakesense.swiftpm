import SpriteKit
import SwiftUI

// MARK: - Room Type Alias

/// RoomType is defined in RoomBuilder.swift to maintain consistency
/// This provides a convenient typealias for easier access
typealias RoomType = RoomBuilder.RoomType

// MARK: - RoomBuilder.RoomType Extensions

extension RoomBuilder.RoomType {
    
    var id: String {
        switch self {
        case .livingRoom: return "livingRoom"
        case .kitchen: return "kitchen"
        case .office: return "office"
        case .bedroom: return "bedroom"
        }
    }
    
    /// Icon name for room selection UI (SF Symbol)
    var iconName: String {
        switch self {
        case .livingRoom: return "sofa.fill"
        case .kitchen: return "fork.knife"
        case .office: return "desk.fill"
        case .bedroom: return "bed.double.fill"
        }
    }
    
    /// Safe zone node name for collision detection
    var safeZoneNodeName: String {
        switch self {
        case .livingRoom: return "table"
        case .kitchen: return "kitchen_island"
        case .office: return "desk"
        case .bedroom: return "bed"
        }
    }
    
    /// Primary danger zones in this room
    var primaryDangers: [String] {
        switch self {
        case .livingRoom:
            return ["Bookshelf", "Window", "Door", "Ceiling Lamp"]
        case .kitchen:
            return ["Refrigerator", "Hanging Pots", "Stove", "Cabinets"]
        case .office:
            return ["Bookshelves", "Filing Cabinet", "Monitor", "Window"]
        case .bedroom:
            return ["Wardrobe", "Ceiling Fan", "Mirror", "Window"]
        }
    }
    
    /// Background color for the room
    var themeColor: SKColor {
        switch self {
        case .livingRoom:
            return SKColor(red: 0.98, green: 0.96, blue: 0.93, alpha: 1.0)  // Warm cream
        case .kitchen:
            return SKColor(red: 0.95, green: 0.97, blue: 0.94, alpha: 1.0)  // Soft green
        case .office:
            return SKColor(red: 0.94, green: 0.95, blue: 0.98, alpha: 1.0)  // Cool blue-gray
        case .bedroom:
            return SKColor(red: 0.96, green: 0.93, blue: 0.97, alpha: 1.0)  // Soft lavender
        }
    }
    
    /// Wall color variation for the room
    var wallTint: SKColor {
        switch self {
        case .livingRoom:
            return SKColor(red: 0.83, green: 0.90, blue: 0.95, alpha: 1.0)  // Pastel blue
        case .kitchen:
            return SKColor(red: 0.88, green: 0.95, blue: 0.87, alpha: 1.0)  // Pastel green
        case .office:
            return SKColor(red: 0.85, green: 0.88, blue: 0.92, alpha: 1.0)  // Steel blue
        case .bedroom:
            return SKColor(red: 0.90, green: 0.87, blue: 0.93, alpha: 1.0)  // Pastel purple
        }
    }
    
    /// Description for room selection
    var roomDescription: String {
        switch self {
        case .livingRoom:
            return String(localized: "A cozy living space with a sturdy table for cover. Watch out for the bookshelf!")
        case .kitchen:
            return String(localized: "The kitchen has many hazards: falling pots, sharp knives, and gas appliances.")
        case .office:
            return String(localized: "An office environment with desks for shelter but watch for falling monitors and bookshelves.")
        case .bedroom:
            return String(localized: "Your bedroom has a bed to hide under, but the wardrobe and ceiling fan are dangerous.")
        }
    }
    
    /// Difficulty rating (1-5)
    var difficultyRating: Int {
        switch self {
        case .livingRoom: return 1
        case .bedroom: return 2
        case .office: return 3
        case .kitchen: return 4
        }
    }
    
    /// Educational tip specific to this room
    var educationalTip: String {
        switch self {
        case .livingRoom:
            return String(localized: "In living rooms, get under sturdy furniture like tables. Stay away from windows and tall bookshelves.")
        case .kitchen:
            return String(localized: "Kitchens are dangerous during earthquakes. Avoid the stove, sharp objects, and hanging items. Get under a sturdy table or the kitchen island.")
        case .office:
            return String(localized: "In offices, use your desk for cover. Stay away from windows, filing cabinets, and equipment that can fall.")
        case .bedroom:
            return String(localized: "If an earthquake happens while sleeping, stay in bed and protect your head with a pillow. Get under the bed frame if possible.")
        }
    }
    
    // MARK: - UI Helper Properties (for SwiftUI compatibility)
    
    /// Short difficulty label for UI
    var difficultyLabel: String {
        switch difficultyRating {
        case 1: return String(localized: "Easy")
        case 2: return String(localized: "Easy")
        case 3: return String(localized: "Medium")
        case 4: return String(localized: "Hard")
        default: return String(localized: "Medium")
        }
    }
    
    /// Color representing difficulty level
    var difficultyColor: Color {
        switch difficultyRating {
        case 1, 2: return AppColors.correctAction
        case 3: return AppColors.warning
        case 4: return AppColors.wrongAction
        default: return AppColors.warning
        }
    }
    
    /// Short description for room cards
    var shortDescription: String {
        switch self {
        case .livingRoom: return String(localized: "Open space with furniture")
        case .kitchen: return String(localized: "High risk, many dangers")
        case .office: return String(localized: "Desks and equipment")
        case .bedroom: return String(localized: "Bed and wardrobe hazards")
        }
    }
}

// MARK: - Room Configuration Protocol

/// Protocol defining the configuration for a room environment
protocol RoomConfiguration {
    var roomType: RoomType { get }
    var furnitureLayout: [FurnitureItem] { get }
    var safeZones: [SafeZone] { get }
    var dangerZones: [DangerZone] { get }
    var uniqueHazards: [RoomHazard] { get }
    var backgroundTheme: RoomTheme { get }
    var educationalContent: RoomEducation { get }
}

/// Represents a furniture item in the room
struct FurnitureItem: Sendable {
    let name: String
    let position: CGPoint
    let size: CGSize
    let isAnchored: Bool  // Whether it's secured to wall/floor
    let mass: CGFloat
    let canTip: Bool
    let textureType: FurnitureTextureType
}

/// Types of furniture textures available
enum FurnitureTextureType: Sendable {
    case table
    case bookshelf
    case bed
    case wardrobe
    case desk
    case chair
    case refrigerator
    case stove
    case cabinet
    case filingCabinet
    case custom(String)
}

/// Defines a safe zone in the room
struct SafeZone: Sendable {
    let name: String
    let nodeName: String
    let position: CGPoint
    let size: CGSize
    let safetyRating: SafetyRating
    let instructions: String
}

/// Safety rating for zones
enum SafetyRating: Int, Sendable {
    case excellent = 5  // Best protection
    case good = 4
    case moderate = 3
    case poor = 2
    case dangerous = 1  // Avoid
    
    var description: String {
        switch self {
        case .excellent: return String(localized: "Excellent Protection")
        case .good: return String(localized: "Good Protection")
        case .moderate: return String(localized: "Moderate Protection")
        case .poor: return String(localized: "Poor Protection")
        case .dangerous: return String(localized: "Dangerous - Avoid")
        }
    }
    
    var color: SKColor {
        switch self {
        case .excellent: return SKColor(red: 0.2, green: 0.8, blue: 0.3, alpha: 1.0)
        case .good: return SKColor(red: 0.3, green: 0.7, blue: 0.4, alpha: 1.0)
        case .moderate: return SKColor(red: 0.9, green: 0.7, blue: 0.2, alpha: 1.0)
        case .poor: return SKColor(red: 0.9, green: 0.5, blue: 0.2, alpha: 1.0)
        case .dangerous: return SKColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
        }
    }
}

/// Defines a danger zone in the room
struct DangerZone: Sendable {
    let name: String
    let nodeName: String
    let position: CGPoint
    let size: CGSize
    let hazardType: HazardType
    let warningMessage: String
}

/// Types of hazards in rooms
enum HazardType: Sendable {
    case fallingObject      // Can fall from above
    case tippingFurniture   // Tall furniture that can tip
    case glass              // Glass that can shatter
    case fire               // Fire/gas hazard
    case sharpObject        // Knives, glass shards
    case electrical         // Electrical hazard
    case structural         // Doorway, window frame
    
    var icon: String {
        switch self {
        case .fallingObject: return "arrow.down.circle.fill"
        case .tippingFurniture: return "arrow.right.arrow.left"
        case .glass: return "square.split.diagonal.2x2"
        case .fire: return "flame.fill"
        case .sharpObject: return "exclamationmark.triangle.fill"
        case .electrical: return "bolt.fill"
        case .structural: return "building.2.fill"
        }
    }
    
    var description: String {
        switch self {
        case .fallingObject: return String(localized: "Objects may fall from above")
        case .tippingFurniture: return String(localized: "Furniture can tip over")
        case .glass: return String(localized: "Glass can break and shatter")
        case .fire: return String(localized: "Fire or gas hazard")
        case .sharpObject: return String(localized: "Sharp objects present")
        case .electrical: return String(localized: "Electrical hazard")
        case .structural: return String(localized: "Structural element - may be unsafe")
        }
    }
}

/// Room-specific hazard with educational information
struct RoomHazard: Sendable {
    let name: String
    let hazardType: HazardType
    let severity: HazardSeverity
    let beforeQuakeAdvice: String
    let duringQuakeAdvice: String
    let afterQuakeAdvice: String
}

/// Severity level for hazards
enum HazardSeverity: Int, Sendable {
    case low = 1
    case moderate = 2
    case high = 3
    case extreme = 4
    
    var description: String {
        switch self {
        case .low: return String(localized: "Low Risk")
        case .moderate: return String(localized: "Moderate Risk")
        case .high: return String(localized: "High Risk")
        case .extreme: return String(localized: "Extreme Risk")
        }
    }
}

/// Theme colors for the room
struct RoomTheme: Sendable {
    let backgroundColor: SKColor
    let wallColor: SKColor
    let floorColor: SKColor
    let accentColor: SKColor
    let lightingIntensity: CGFloat
}

/// Educational content for the room
struct RoomEducation: Sendable {
    let prepChecklist: [String]
    let duringInstructions: [String]
    let afterInstructions: [String]
    let commonMistakes: [String]
    let factoids: [String]
}

// MARK: - Room Configurations

/// Living room configuration
struct LivingRoomConfiguration: RoomConfiguration {
    let roomType: RoomType = .livingRoom
    
    var furnitureLayout: [FurnitureItem] {
        [
            FurnitureItem(
                name: "Coffee Table",
                position: CGPoint(x: 512, y: 125),
                size: CGSize(width: 180, height: 90),
                isAnchored: false,
                mass: 3.0,
                canTip: false,
                textureType: .table
            ),
            FurnitureItem(
                name: "Bookshelf",
                position: CGPoint(x: 924, y: 200),
                size: CGSize(width: 80, height: 200),
                isAnchored: false,
                mass: 5.0,
                canTip: true,
                textureType: .bookshelf
            ),
            FurnitureItem(
                name: "Sofa",
                position: CGPoint(x: 300, y: 130),
                size: CGSize(width: 200, height: 80),
                isAnchored: false,
                mass: 4.0,
                canTip: false,
                textureType: .custom("sofa")
            )
        ]
    }
    
    var safeZones: [SafeZone] {
        [
            SafeZone(
                name: "Under Table",
                nodeName: "table",
                position: CGPoint(x: 512, y: 125),
                size: CGSize(width: 160, height: 75),
                safetyRating: .excellent,
                instructions: "Get under the table and hold on to the legs"
            )
        ]
    }
    
    var dangerZones: [DangerZone] {
        [
            DangerZone(
                name: "Bookshelf Area",
                nodeName: "bookshelf_zone",
                position: CGPoint(x: 924, y: 200),
                size: CGSize(width: 140, height: 220),
                hazardType: .tippingFurniture,
                warningMessage: "Tall bookshelf can tip over during shaking!"
            ),
            DangerZone(
                name: "Window",
                nodeName: "window",
                position: CGPoint(x: 774, y: 280),
                size: CGSize(width: 120, height: 150),
                hazardType: .glass,
                warningMessage: "Glass can shatter and cause injuries!"
            ),
            DangerZone(
                name: "Door",
                nodeName: "door",
                position: CGPoint(x: 70, y: 170),
                size: CGSize(width: 80, height: 180),
                hazardType: .structural,
                warningMessage: "Doorways are NOT safe during earthquakes!"
            )
        ]
    }
    
    var uniqueHazards: [RoomHazard] {
        [
            RoomHazard(
                name: "Ceiling Lamp",
                hazardType: .fallingObject,
                severity: .moderate,
                beforeQuakeAdvice: "Secure ceiling fixtures with safety cables",
                duringQuakeAdvice: "Stay away from hanging lights and ceiling fans",
                afterQuakeAdvice: "Check for loose fixtures before using"
            ),
            RoomHazard(
                name: "Bookshelf",
                hazardType: .tippingFurniture,
                severity: .high,
                beforeQuakeAdvice: "Secure bookshelves to wall studs",
                duringQuakeAdvice: "Never shelter near tall furniture",
                afterQuakeAdvice: "Check for tipping or damage before approaching"
            ),
            RoomHazard(
                name: "Picture Frames",
                hazardType: .fallingObject,
                severity: .low,
                beforeQuakeAdvice: "Use museum putty to secure frames",
                duringQuakeAdvice: "Watch for falling objects from walls",
                afterQuakeAdvice: "Careful of broken glass from fallen frames"
            )
        ]
    }
    
    var backgroundTheme: RoomTheme {
        RoomTheme(
            backgroundColor: SKColor(red: 0.98, green: 0.96, blue: 0.93, alpha: 1.0),
            wallColor: SKColor(red: 0.83, green: 0.90, blue: 0.95, alpha: 1.0),
            floorColor: SKColor(red: 0.75, green: 0.55, blue: 0.35, alpha: 1.0),
            accentColor: SKColor(red: 0.60, green: 0.40, blue: 0.22, alpha: 1.0),
            lightingIntensity: 1.0
        )
    }
    
    var educationalContent: RoomEducation {
        RoomEducation(
            prepChecklist: [
                "Secure bookshelves to wall studs",
                "Use museum putty on picture frames",
                "Install safety cables on ceiling fixtures",
                "Remove heavy objects from high shelves",
                "Anchor TV and electronics"
            ],
            duringInstructions: [
                "Drop to the ground immediately",
                "Take cover under sturdy furniture",
                "Hold on until shaking stops",
                "Stay away from windows and tall furniture",
                "Don't try to run outside"
            ],
            afterInstructions: [
                "Check for injuries first",
                "Extinguish any small fires",
                "Check for gas leaks",
                "Listen for aftershock warnings",
                "Use stairs, not elevators"
            ],
            commonMistakes: [
                "Standing in doorways (old myth)",
                "Trying to run outside during shaking",
                "Sheltering near windows",
                "Holding onto tall furniture"
            ],
            factoids: [
                "Most injuries occur from falling objects, not building collapse",
                "Doorways in modern homes are no safer than other areas",
                "The triangle of life theory has been debunked by experts"
            ]
        )
    }
}

/// Kitchen configuration
struct KitchenConfiguration: RoomConfiguration {
    let roomType: RoomType = .kitchen
    
    var furnitureLayout: [FurnitureItem] {
        [
            FurnitureItem(
                name: "Kitchen Island",
                position: CGPoint(x: 512, y: 130),
                size: CGSize(width: 200, height: 95),
                isAnchored: true,
                mass: 8.0,
                canTip: false,
                textureType: .custom("island")
            ),
            FurnitureItem(
                name: "Refrigerator",
                position: CGPoint(x: 934, y: 170),
                size: CGSize(width: 70, height: 180),
                isAnchored: false,
                mass: 8.0,
                canTip: true,
                textureType: .refrigerator
            ),
            FurnitureItem(
                name: "Stove",
                position: CGPoint(x: 844, y: 122),
                size: CGSize(width: 75, height: 85),
                isAnchored: false,
                mass: 6.0,
                canTip: false,
                textureType: .stove
            )
        ]
    }
    
    var safeZones: [SafeZone] {
        [
            SafeZone(
                name: "Kitchen Island",
                nodeName: "kitchen_island",
                position: CGPoint(x: 512, y: 130),
                size: CGSize(width: 170, height: 75),
                safetyRating: .excellent,
                instructions: "Get under the kitchen island and hold on"
            )
        ]
    }
    
    var dangerZones: [DangerZone] {
        [
            DangerZone(
                name: "Refrigerator Zone",
                nodeName: "refrigerator_zone",
                position: CGPoint(x: 934, y: 170),
                size: CGSize(width: 120, height: 210),
                hazardType: .tippingFurniture,
                warningMessage: "Refrigerator can tip and block exits!"
            ),
            DangerZone(
                name: "Stove Area",
                nodeName: "stove_gas_zone",
                position: CGPoint(x: 844, y: 122),
                size: CGSize(width: 115, height: 115),
                hazardType: .fire,
                warningMessage: "Gas leak and fire hazard! Turn off gas after quake."
            ),
            DangerZone(
                name: "Hanging Pots",
                nodeName: "pot_rack",
                position: CGPoint(x: 512, y: 600),
                size: CGSize(width: 150, height: 60),
                hazardType: .fallingObject,
                warningMessage: "Heavy pots can fall from above!"
            )
        ]
    }
    
    var uniqueHazards: [RoomHazard] {
        [
            RoomHazard(
                name: "Falling Knives",
                hazardType: .sharpObject,
                severity: .extreme,
                beforeQuakeAdvice: "Use a knife block or drawer, not magnetic strips",
                duringQuakeAdvice: "Protect your head and neck from falling objects",
                afterQuakeAdvice: "Wear shoes! Look for fallen sharp objects"
            ),
            RoomHazard(
                name: "Boiling Water",
                hazardType: .fire,
                severity: .high,
                beforeQuakeAdvice: "Never leave cooking unattended",
                duringQuakeAdvice: "Move away from stove immediately",
                afterQuakeAdvice: "Check for spills and burns carefully"
            ),
            RoomHazard(
                name: "Gas Stove",
                hazardType: .fire,
                severity: .extreme,
                beforeQuakeAdvice: "Install automatic gas shutoff valve",
                duringQuakeAdvice: "Don't try to turn off gas during shaking",
                afterQuakeAdvice: "Shut off gas at the main valve if you smell gas"
            ),
            RoomHazard(
                name: "Hanging Pots/Pans",
                hazardType: .fallingObject,
                severity: .high,
                beforeQuakeAdvice: "Remove or secure hanging pot racks",
                duringQuakeAdvice: "Stay away from hanging objects",
                afterQuakeAdvice: "Check for loose items before moving around"
            ),
            RoomHazard(
                name: "Glass Cabinets",
                hazardType: .glass,
                severity: .moderate,
                beforeQuakeAdvice: "Apply safety film to glass cabinet doors",
                duringQuakeAdvice: "Stay away from glass-front cabinets",
                afterQuakeAdvice: "Careful of broken glass when opening cabinets"
            )
        ]
    }
    
    var backgroundTheme: RoomTheme {
        RoomTheme(
            backgroundColor: SKColor(red: 0.95, green: 0.97, blue: 0.94, alpha: 1.0),
            wallColor: SKColor(red: 0.88, green: 0.95, blue: 0.87, alpha: 1.0),
            floorColor: SKColor(red: 0.72, green: 0.62, blue: 0.52, alpha: 1.0),
            accentColor: SKColor(red: 0.30, green: 0.55, blue: 0.40, alpha: 1.0),
            lightingIntensity: 1.1
        )
    }
    
    var educationalContent: RoomEducation {
        RoomEducation(
            prepChecklist: [
                "Install automatic gas shutoff valve",
                "Secure refrigerator to wall",
                "Use knife blocks, not magnetic strips",
                "Remove or secure hanging pot racks",
                "Apply safety film to glass cabinets",
                "Secure upper cabinets to wall studs"
            ],
            duringInstructions: [
                "Move away from stove immediately",
                "Get under kitchen island or sturdy table",
                "Protect your head from falling objects",
                "Don't try to turn off gas during shaking",
                "Stay inside - don't run out during quake"
            ],
            afterInstructions: [
                "Shut off gas if you smell it",
                "Extinguish any fires immediately",
                "Wear shoes to protect from broken glass",
                "Check refrigerator for tipping",
                "Open windows to ventilate if gas leak suspected"
            ],
            commonMistakes: [
                "Trying to turn off gas during shaking",
                "Running outside during the quake",
                "Sheltering near glass cabinets",
                "Going barefoot after the quake"
            ],
            factoids: [
                "Kitchens are the most dangerous room during earthquakes",
                "Gas leaks are a leading cause of post-earthquake fires",
                "Automatic gas shutoff valves activate at magnitude 5.0+",
                "Most kitchen injuries are from falling objects, not burns"
            ]
        )
    }
}

/// Office configuration
struct OfficeConfiguration: RoomConfiguration {
    let roomType: RoomType = .office
    
    var furnitureLayout: [FurnitureItem] {
        [
            FurnitureItem(
                name: "Office Desk",
                position: CGPoint(x: 512, y: 127),
                size: CGSize(width: 180, height: 85),
                isAnchored: false,
                mass: 5.0,
                canTip: false,
                textureType: .desk
            ),
            FurnitureItem(
                name: "Filing Cabinet",
                position: CGPoint(x: 864, y: 160),
                size: CGSize(width: 55, height: 160),
                isAnchored: false,
                mass: 5.0,
                canTip: true,
                textureType: .filingCabinet
            ),
            FurnitureItem(
                name: "Bookshelf",
                position: CGPoint(x: 944, y: 140),
                size: CGSize(width: 60, height: 140),
                isAnchored: false,
                mass: 3.5,
                canTip: true,
                textureType: .bookshelf
            )
        ]
    }
    
    var safeZones: [SafeZone] {
        [
            SafeZone(
                name: "Under Desk",
                nodeName: "desk",
                position: CGPoint(x: 512, y: 127),
                size: CGSize(width: 160, height: 70),
                safetyRating: .excellent,
                instructions: "Get under the desk and hold onto the legs"
            )
        ]
    }
    
    var dangerZones: [DangerZone] {
        [
            DangerZone(
                name: "Filing Cabinet",
                nodeName: "filing_cabinet_zone",
                position: CGPoint(x: 864, y: 160),
                size: CGSize(width: 105, height: 190),
                hazardType: .tippingFurniture,
                warningMessage: "Heavy filing cabinet can tip over!"
            ),
            DangerZone(
                name: "Office Bookshelf",
                nodeName: "office_bookshelf_zone_0",
                position: CGPoint(x: 944, y: 140),
                size: CGSize(width: 110, height: 160),
                hazardType: .tippingFurniture,
                warningMessage: "Bookshelf can tip and spill contents!"
            ),
            DangerZone(
                name: "Window",
                nodeName: "window_blinds",
                position: CGPoint(x: 824, y: 300),
                size: CGSize(width: 120, height: 150),
                hazardType: .glass,
                warningMessage: "Window glass can shatter!"
            )
        ]
    }
    
    var uniqueHazards: [RoomHazard] {
        [
            RoomHazard(
                name: "Falling Monitor",
                hazardType: .fallingObject,
                severity: .high,
                beforeQuakeAdvice: "Secure monitors with safety straps",
                duringQuakeAdvice: "Move away from desk equipment",
                afterQuakeAdvice: "Check equipment before using"
            ),
            RoomHazard(
                name: "Bookshelf",
                hazardType: .tippingFurniture,
                severity: .high,
                beforeQuakeAdvice: "Secure bookshelves to wall",
                duringQuakeAdvice: "Never shelter near tall furniture",
                afterQuakeAdvice: "Check for tipping or loose items"
            ),
            RoomHazard(
                name: "Filing Cabinet",
                hazardType: .tippingFurniture,
                severity: .high,
                beforeQuakeAdvice: "Anchor filing cabinets to walls",
                duringQuakeAdvice: "Stay away from tall furniture",
                afterQuakeAdvice: "Open drawers carefully - contents may have shifted"
            ),
            RoomHazard(
                name: "Whiteboard",
                hazardType: .fallingObject,
                severity: .moderate,
                beforeQuakeAdvice: "Ensure whiteboard is securely mounted",
                duringQuakeAdvice: "Stay away from wall-mounted items",
                afterQuakeAdvice: "Check mounting before using"
            ),
            RoomHazard(
                name: "Glass Door",
                hazardType: .glass,
                severity: .high,
                beforeQuakeAdvice: "Apply safety film to glass doors",
                duringQuakeAdvice: "Stay away from glass partitions",
                afterQuakeAdvice: "Check for cracks before opening"
            )
        ]
    }
    
    var backgroundTheme: RoomTheme {
        RoomTheme(
            backgroundColor: SKColor(red: 0.94, green: 0.95, blue: 0.98, alpha: 1.0),
            wallColor: SKColor(red: 0.85, green: 0.88, blue: 0.92, alpha: 1.0),
            floorColor: SKColor(red: 0.68, green: 0.58, blue: 0.48, alpha: 1.0),
            accentColor: SKColor(red: 0.25, green: 0.45, blue: 0.65, alpha: 1.0),
            lightingIntensity: 1.0
        )
    }
    
    var educationalContent: RoomEducation {
        RoomEducation(
            prepChecklist: [
                "Secure bookshelves to walls",
                "Anchor filing cabinets",
                "Secure monitors with safety straps",
                "Apply safety film to glass partitions",
                "Secure overhead storage",
                "Know the location of fire extinguishers"
            ],
            duringInstructions: [
                "Get under your desk immediately",
                "Hold onto desk legs",
                "Stay away from windows and glass",
                "Protect your head from falling objects",
                "Stay inside until shaking stops"
            ],
            afterInstructions: [
                "Check for injuries",
                "Look for fire or gas leaks",
                "Check filing cabinets before opening",
                "Evacuate using stairs, not elevators",
                "Gather at designated meeting point"
            ],
            commonMistakes: [
                "Trying to save work before taking cover",
                "Running to exits during shaking",
                "Standing near glass partitions",
                "Using elevators after the quake"
            ],
            factoids: [
                "Office buildings often have better earthquake resistance than homes",
                "Falling office equipment causes most workplace earthquake injuries",
                "The 'drop, cover, and hold on' method reduces injury by 50%",
                "Most office earthquakes last less than 2 minutes"
            ]
        )
    }
}

/// Bedroom configuration
struct BedroomConfiguration: RoomConfiguration {
    let roomType: RoomType = .bedroom
    
    var furnitureLayout: [FurnitureItem] {
        [
            FurnitureItem(
                name: "Bed",
                position: CGPoint(x: 512, y: 122),
                size: CGSize(width: 160, height: 75),
                isAnchored: false,
                mass: 4.0,
                canTip: false,
                textureType: .bed
            ),
            FurnitureItem(
                name: "Wardrobe",
                position: CGPoint(x: 914, y: 185),
                size: CGSize(width: 100, height: 210),
                isAnchored: false,
                mass: 7.0,
                canTip: true,
                textureType: .wardrobe
            ),
            FurnitureItem(
                name: "Nightstand",
                position: CGPoint(x: 392, y: 105),
                size: CGSize(width: 45, height: 50),
                isAnchored: false,
                mass: 2.0,
                canTip: false,
                textureType: .custom("nightstand")
            )
        ]
    }
    
    var safeZones: [SafeZone] {
        [
            SafeZone(
                name: "Under Bed",
                nodeName: "bed",
                position: CGPoint(x: 512, y: 122),
                size: CGSize(width: 140, height: 55),
                safetyRating: .excellent,
                instructions: "Get under the bed frame and hold on"
            )
        ]
    }
    
    var dangerZones: [DangerZone] {
        [
            DangerZone(
                name: "Wardrobe Zone",
                nodeName: "wardrobe_zone",
                position: CGPoint(x: 914, y: 185),
                size: CGSize(width: 160, height: 240),
                hazardType: .tippingFurniture,
                warningMessage: "Heavy wardrobe can tip over and trap you!"
            ),
            DangerZone(
                name: "Window",
                nodeName: "window_curtains",
                position: CGPoint(x: 774, y: 280),
                size: CGSize(width: 120, height: 150),
                hazardType: .glass,
                warningMessage: "Glass can shatter and curtains can fall!"
            ),
            DangerZone(
                name: "Ceiling Fan",
                nodeName: "ceiling_fan",
                position: CGPoint(x: 512, y: 700),
                size: CGSize(width: 150, height: 50),
                hazardType: .fallingObject,
                warningMessage: "Ceiling fan can detach and fall!"
            )
        ]
    }
    
    var uniqueHazards: [RoomHazard] {
        [
            RoomHazard(
                name: "Wardrobe",
                hazardType: .tippingFurniture,
                severity: .extreme,
                beforeQuakeAdvice: "Secure wardrobe to wall with L-brackets",
                duringQuakeAdvice: "Never shelter near tall furniture",
                afterQuakeAdvice: "Check for tipping before opening doors"
            ),
            RoomHazard(
                name: "Ceiling Fan",
                hazardType: .fallingObject,
                severity: .high,
                beforeQuakeAdvice: "Ensure fan is properly secured to ceiling joist",
                duringQuakeAdvice: "Stay away from ceiling fan area",
                afterQuakeAdvice: "Check mounting before turning on"
            ),
            RoomHazard(
                name: "Mirror",
                hazardType: .glass,
                severity: .high,
                beforeQuakeAdvice: "Secure mirrors with closed hooks or remove",
                duringQuakeAdvice: "Stay away from wall-mounted mirrors",
                afterQuakeAdvice: "Wear shoes near mirror areas"
            ),
            RoomHazard(
                name: "Lamp on Nightstand",
                hazardType: .fallingObject,
                severity: .low,
                beforeQuakeAdvice: "Use battery-powered bedside lights",
                duringQuakeAdvice: "Keep head covered",
                afterQuakeAdvice: "Check for broken glass"
            ),
            RoomHazard(
                name: "Tall Dresser",
                hazardType: .tippingFurniture,
                severity: .high,
                beforeQuakeAdvice: "Anchor all dressers to walls",
                duringQuakeAdvice: "Don't hold onto furniture for support",
                afterQuakeAdvice: "Check drawers - contents may have shifted"
            )
        ]
    }
    
    var backgroundTheme: RoomTheme {
        RoomTheme(
            backgroundColor: SKColor(red: 0.96, green: 0.93, blue: 0.97, alpha: 1.0),
            wallColor: SKColor(red: 0.90, green: 0.87, blue: 0.93, alpha: 1.0),
            floorColor: SKColor(red: 0.70, green: 0.60, blue: 0.50, alpha: 1.0),
            accentColor: SKColor(red: 0.55, green: 0.40, blue: 0.60, alpha: 1.0),
            lightingIntensity: 0.9
        )
    }
    
    var educationalContent: RoomEducation {
        RoomEducation(
            prepChecklist: [
                "Secure wardrobe to wall studs",
                "Anchor all dressers and tall furniture",
                "Remove or secure heavy mirrors",
                "Ensure ceiling fan is properly mounted",
                "Use closed hooks for wall hangings",
                "Keep a flashlight by the bed"
            ],
            duringInstructions: [
                "If in bed: stay there and cover head with pillow",
                "If awake: get under the bed frame",
                "Stay away from windows and mirrors",
                "Don't try to run outside",
                "Hold on until shaking stops"
            ],
            afterInstructions: [
                "Check for injuries",
                "Put on shoes before getting out of bed",
                "Check for gas leaks",
                "Open wardrobe doors carefully",
                "Be careful of broken glass from mirrors"
            ],
            commonMistakes: [
                "Trying to run outside while half-asleep",
                "Standing near wardrobe for support",
                "Going barefoot on potentially broken glass",
                "Trying to hold up falling furniture"
            ],
            factoids: [
                "Most earthquakes occur when people are sleeping",
                "Your bed is often the safest place during a night quake",
                "Pillow protection can prevent 60% of head injuries",
                "Bedroom furniture causes most home earthquake fatalities"
            ]
        )
    }
}

// MARK: - Room Configuration Factory

/// Factory for creating room configurations
enum RoomConfigurationFactory {
    static func configuration(for roomType: RoomType) -> RoomConfiguration {
        switch roomType {
        case .livingRoom:
            return LivingRoomConfiguration()
        case .kitchen:
            return KitchenConfiguration()
        case .office:
            return OfficeConfiguration()
        case .bedroom:
            return BedroomConfiguration()
        }
    }
}

// MARK: - Room Builder Extensions

extension RoomBuilder {
    
    // MARK: - Public Room Building Interface
    
    /// Builds a complete room with all room-specific hazards and educational content
    static func buildRoomWithConfiguration(type: RoomType, in scene: SKScene) {
        let config = RoomConfigurationFactory.configuration(for: type)
        let size = scene.size
        
        // Apply room theme
        applyTheme(config.backgroundTheme, to: scene)
        
        // Common elements
        buildWallsAndFloor(in: scene, size: size, type: type)
        buildCeilingLamp(in: scene, size: size)
        buildPlayer(in: scene, size: size)
        
        // Room-specific elements with hazards
        switch type {
        case .livingRoom:
            buildLivingRoomWithHazards(in: scene, size: size, config: config)
        case .kitchen:
            buildKitchenWithHazards(in: scene, size: size, config: config)
        case .office:
            buildOfficeWithHazards(in: scene, size: size, config: config)
        case .bedroom:
            buildBedroomWithHazards(in: scene, size: size, config: config)
        }
        
        // Build aftershock zones appropriate for the room
        buildRoomSpecificAftershockZones(type: type, in: scene, size: size)
        
        // Store room configuration for reference
        storeRoomConfiguration(config, in: scene)
    }
    
    // MARK: - Theme Application
    
    private static func applyTheme(_ theme: RoomTheme, to scene: SKScene) {
        scene.backgroundColor = theme.backgroundColor
    }
    
    // MARK: - Room-Specific Hazard Builders
    
    private static func buildLivingRoomWithHazards(in scene: SKScene, size: CGSize, config: RoomConfiguration) {
        buildLivingRoom(in: scene, size: size)
        
        // Add visual hazard indicators
        for hazard in config.uniqueHazards {
            if let position = hazardPosition(for: hazard.name, in: scene) {
                addHazardIndicator(
                    in: scene,
                    at: position,
                    hazard: hazard,
                    visible: false  // Show during educational mode
                )
            }
        }
    }
    
    private static func buildKitchenWithHazards(in scene: SKScene, size: CGSize, config: RoomConfiguration) {
        buildKitchen(in: scene, size: size)
        
        // Add kitchen-specific falling knives hazard
        buildFallingKnivesHazard(in: scene, size: size)
        
        // Add boiling water hazard indicator
        addHazardIndicator(
            in: scene,
            at: CGPoint(x: size.width - 180, y: RoomLayout.floorHeight + 130),
            hazard: RoomHazard(
                name: "Boiling Water",
                hazardType: .fire,
                severity: .high,
                beforeQuakeAdvice: "Never leave cooking unattended",
                duringQuakeAdvice: "Move away from stove immediately",
                afterQuakeAdvice: "Check for spills and burns carefully"
            ),
            visible: false
        )
        
        // Add gas leak warning zone
        buildGasLeakWarning(in: scene, size: size)
    }
    
    private static func buildOfficeWithHazards(in scene: SKScene, size: CGSize, config: RoomConfiguration) {
        buildOffice(in: scene, size: size)
        
        // Add falling monitor hazard
        buildFallingMonitorHazard(in: scene, size: size)
        
        // Add glass door warning
        addHazardIndicator(
            in: scene,
            at: CGPoint(x: 70, y: RoomLayout.floorHeight + 100),
            hazard: RoomHazard(
                name: "Glass Door",
                hazardType: .glass,
                severity: .high,
                beforeQuakeAdvice: "Apply safety film to glass",
                duringQuakeAdvice: "Stay away from glass doors",
                afterQuakeAdvice: "Check for cracks before opening"
            ),
            visible: false
        )
    }
    
    private static func buildBedroomWithHazards(in scene: SKScene, size: CGSize, config: RoomConfiguration) {
        buildBedroom(in: scene, size: size)
        
        // Add ceiling fan hazard
        buildCeilingFanHazard(in: scene, size: size)
        
        // Add mirror hazard
        buildMirrorHazard(in: scene, size: size)
        
        // Add special "in bed" safe zone for night scenario
        buildInBedSafeZone(in: scene, size: size)
    }
    
    // MARK: - Specific Hazard Builders
    
    /// Falling knives hazard for kitchen
    private static func buildFallingKnivesHazard(in scene: SKScene, size: CGSize) {
        // Visual representation of knife rack
        let rackX = size.width - 250
        let rackY = size.height - 180
        
        let rack = SKSpriteNode(color: CartoonPalette.furnitureDark.skColor, size: CGSize(width: 60, height: 8))
        rack.position = CGPoint(x: rackX, y: rackY)
        rack.zPosition = 2
        rack.name = "knife_rack"
        scene.addChild(rack)
        
        // Knives that can fall
        let knifePositions: [CGFloat] = [-20, -5, 10, 25]
        for (i, xOffset) in knifePositions.enumerated() {
            let knifeTex = createKnifeTexture()
            let knife = SKSpriteNode(texture: knifeTex, size: CGSize(width: 6, height: 25))
            knife.position = CGPoint(x: rackX + xOffset, y: rackY - 16)
            knife.zPosition = 3
            knife.name = "falling_knife_\(i)"
            knife.physicsBody = SKPhysicsBody(rectangleOf: knife.size)
            knife.physicsBody?.isDynamic = false
            knife.physicsBody?.categoryBitMask = PhysicsCategory.debris
            knife.physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.floor
            knife.physicsBody?.mass = 0.1
            scene.addChild(knife)
        }
        
        // Danger zone below
        let dangerZone = SKSpriteNode(color: .clear, size: CGSize(width: 80, height: 120))
        dangerZone.position = CGPoint(x: rackX, y: rackY - 70)
        dangerZone.zPosition = 0
        dangerZone.name = "knife_danger_zone"
        dangerZone.physicsBody = SKPhysicsBody(rectangleOf: dangerZone.size)
        dangerZone.physicsBody?.isDynamic = false
        dangerZone.physicsBody?.categoryBitMask = PhysicsCategory.dangerZone
        dangerZone.physicsBody?.contactTestBitMask = PhysicsCategory.player
        scene.addChild(dangerZone)
    }
    
    /// Falling monitor hazard for office
    private static func buildFallingMonitorHazard(in scene: SKScene, size: CGSize) {
        // Extra monitor that can fall (in addition to desk monitor)
        let monitorX = size.width - 100
        let monitorY = RoomLayout.floorHeight + 200
        
        let monitorTex = TextureFactory.monitorTexture(width: 45, height: 35)
        let monitor = SKSpriteNode(texture: monitorTex, size: CGSize(width: 45, height: 35))
        monitor.position = CGPoint(x: monitorX, y: monitorY)
        monitor.zPosition = 3
        monitor.name = "wall_monitor"
        monitor.physicsBody = SKPhysicsBody(rectangleOf: monitor.size)
        monitor.physicsBody?.isDynamic = false
        monitor.physicsBody?.categoryBitMask = PhysicsCategory.debris
        monitor.physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.floor
        monitor.physicsBody?.mass = 0.6
        scene.addChild(monitor)
        
        // Danger zone
        let dangerZone = SKSpriteNode(color: .clear, size: CGSize(width: 60, height: 100))
        dangerZone.position = CGPoint(x: monitorX, y: monitorY - 50)
        dangerZone.zPosition = 0
        dangerZone.name = "monitor_danger_zone"
        dangerZone.physicsBody = SKPhysicsBody(rectangleOf: dangerZone.size)
        dangerZone.physicsBody?.isDynamic = false
        dangerZone.physicsBody?.categoryBitMask = PhysicsCategory.dangerZone
        dangerZone.physicsBody?.contactTestBitMask = PhysicsCategory.player
        scene.addChild(dangerZone)
    }
    
    /// Ceiling fan hazard for bedroom
    private static func buildCeilingFanHazard(in scene: SKScene, size: CGSize) {
        let fanX = size.width / 2 + 150
        let fanY = size.height - 80
        
        // Fan mount
        let mount = SKSpriteNode(color: SKColor(white: 0.4, alpha: 1), size: CGSize(width: 10, height: 15))
        mount.position = CGPoint(x: fanX, y: fanY + 25)
        mount.zPosition = 4
        mount.name = "fan_mount"
        scene.addChild(mount)
        
        // Fan blades
        let bladeTex = createFanBladeTexture()
        let fan = SKSpriteNode(texture: bladeTex, size: CGSize(width: 100, height: 100))
        fan.position = CGPoint(x: fanX, y: fanY)
        fan.zPosition = 4
        fan.name = "ceiling_fan"
        fan.physicsBody = SKPhysicsBody(circleOfRadius: 50)
        fan.physicsBody?.isDynamic = false
        fan.physicsBody?.categoryBitMask = PhysicsCategory.debris
        fan.physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.floor
        fan.physicsBody?.mass = 2.0
        scene.addChild(fan)
        
        // Gentle rotation animation (stops during quake)
        let rotate = SKAction.rotate(byAngle: .pi * 2, duration: 2.0)
        fan.run(SKAction.repeatForever(rotate), withKey: "fan_rotation")
        
        // Danger zone below fan
        let dangerZone = SKSpriteNode(color: .clear, size: CGSize(width: 120, height: 200))
        dangerZone.position = CGPoint(x: fanX, y: fanY - 100)
        dangerZone.zPosition = 0
        dangerZone.name = "fan_danger_zone"
        dangerZone.physicsBody = SKPhysicsBody(rectangleOf: dangerZone.size)
        dangerZone.physicsBody?.isDynamic = false
        dangerZone.physicsBody?.categoryBitMask = PhysicsCategory.dangerZone
        dangerZone.physicsBody?.contactTestBitMask = PhysicsCategory.player
        scene.addChild(dangerZone)
    }
    
    /// Mirror hazard for bedroom
    private static func buildMirrorHazard(in scene: SKScene, size: CGSize) {
        let mirrorX = size.width - 300
        let mirrorY = size.height - 150
        
        let mirrorTex = createMirrorTexture()
        let mirror = SKSpriteNode(texture: mirrorTex, size: CGSize(width: 50, height: 80))
        mirror.position = CGPoint(x: mirrorX, y: mirrorY)
        mirror.zPosition = 2
        mirror.name = "wall_mirror"
        mirror.physicsBody = SKPhysicsBody(rectangleOf: mirror.size)
        mirror.physicsBody?.isDynamic = false
        mirror.physicsBody?.categoryBitMask = PhysicsCategory.debris
        mirror.physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.floor
        mirror.physicsBody?.mass = 0.5
        scene.addChild(mirror)
        
        // Danger zone
        let dangerZone = SKSpriteNode(color: .clear, size: CGSize(width: 70, height: 100))
        dangerZone.position = CGPoint(x: mirrorX, y: mirrorY - 40)
        dangerZone.zPosition = 0
        dangerZone.name = "mirror_danger_zone"
        dangerZone.physicsBody = SKPhysicsBody(rectangleOf: dangerZone.size)
        dangerZone.physicsBody?.isDynamic = false
        dangerZone.physicsBody?.categoryBitMask = PhysicsCategory.dangerZone
        dangerZone.physicsBody?.contactTestBitMask = PhysicsCategory.player
        scene.addChild(dangerZone)
    }
    
    /// Gas leak warning for kitchen
    private static func buildGasLeakWarning(in scene: SKScene, size: CGSize) {
        // Warning sign near stove (hidden until aftershock)
        let warningTex = createGasWarningTexture()
        let warning = SKSpriteNode(texture: warningTex, size: CGSize(width: 30, height: 30))
        warning.position = CGPoint(x: size.width - 180, y: RoomLayout.floorHeight + 150)
        warning.zPosition = 8
        warning.name = "kitchen_gas_valve"  // Same name for compatibility
        warning.alpha = 0
        scene.addChild(warning)
    }
    
    /// In-bed safe zone for bedroom night scenario
    private static func buildInBedSafeZone(in scene: SKScene, size: CGSize) {
        // Safe zone for "stay in bed" scenario
        let safeZone = SKSpriteNode(color: .clear, size: CGSize(width: 140, height: 60))
        safeZone.position = CGPoint(x: size.width / 2, y: RoomLayout.floorHeight + 50)
        safeZone.zPosition = 0
        safeZone.name = "bed_safe_zone"
        safeZone.physicsBody = SKPhysicsBody(rectangleOf: safeZone.size)
        safeZone.physicsBody?.isDynamic = false
        safeZone.physicsBody?.categoryBitMask = PhysicsCategory.safeZone
        safeZone.physicsBody?.contactTestBitMask = PhysicsCategory.player
        scene.addChild(safeZone)
    }
    
    // MARK: - Aftershock Zones
    
    private static func buildRoomSpecificAftershockZones(type: RoomType, in scene: SKScene, size: CGSize) {
        switch type {
        case .livingRoom:
            buildLivingRoomAftershockZones(in: scene, size: size)
        case .kitchen:
            buildKitchenAftershockZones(in: scene, size: size)
        case .office:
            buildOfficeAftershockZones(in: scene, size: size)
        case .bedroom:
            buildBedroomAftershockZones(in: scene, size: size)
        }
    }
    
    private static func buildLivingRoomAftershockZones(in scene: SKScene, size: CGSize) {
        // Standard zones
        buildAftershockZones(in: scene, size: size)
    }
    
    private static func buildKitchenAftershockZones(in scene: SKScene, size: CGSize) {
        // Gas valve (kitchen priority)
        let gasValveTex = TextureFactory.gasValveIcon()
        let gasValve = SKSpriteNode(texture: gasValveTex, size: CGSize(width: 40, height: 40))
        gasValve.position = CGPoint(x: size.width - 60, y: RoomLayout.floorHeight + 30)
        gasValve.zPosition = 8
        gasValve.name = "gas_valve"
        gasValve.alpha = 0
        scene.addChild(gasValve)
        
        let valveLabel = SKLabelNode(text: String(localized: "GAS VALVE"))
        valveLabel.fontSize = DynamicTypeScale.scaled(9)
        valveLabel.fontColor = .white
        valveLabel.fontName = "Helvetica-Bold"
        valveLabel.position = CGPoint(x: 0, y: -28)
        valveLabel.verticalAlignmentMode = .center
        gasValve.addChild(valveLabel)
        
        // Safe exit
        let exitTex = TextureFactory.exitSignIcon()
        let exitMarker = SKSpriteNode(texture: exitTex, size: CGSize(width: 50, height: 30))
        exitMarker.position = CGPoint(x: 70, y: RoomLayout.floorHeight + RoomLayout.doorHeight + 30)
        exitMarker.zPosition = 8
        exitMarker.name = "safe_exit"
        exitMarker.alpha = 0
        scene.addChild(exitMarker)
        
        // Injury check with bandage theme
        let aidTex = TextureFactory.firstAidIcon()
        let injuryCheck = SKSpriteNode(texture: aidTex, size: CGSize(width: 40, height: 40))
        injuryCheck.position = CGPoint(x: size.width / 2, y: RoomLayout.floorHeight + 50)
        injuryCheck.zPosition = 8
        injuryCheck.name = "injury_check"
        injuryCheck.alpha = 0
        scene.addChild(injuryCheck)
    }
    
    private static func buildOfficeAftershockZones(in scene: SKScene, size: CGSize) {
        // Safe exit (office priority)
        let exitTex = TextureFactory.exitSignIcon()
        let exitMarker = SKSpriteNode(texture: exitTex, size: CGSize(width: 55, height: 35))
        exitMarker.position = CGPoint(x: 70, y: RoomLayout.floorHeight + RoomLayout.doorHeight + 35)
        exitMarker.zPosition = 8
        exitMarker.name = "safe_exit"
        exitMarker.alpha = 0
        scene.addChild(exitMarker)
        
        let exitLabel = SKLabelNode(text: String(localized: "EMERGENCY EXIT"))
        exitLabel.fontSize = DynamicTypeScale.scaled(9)
        exitLabel.fontColor = .white
        exitLabel.fontName = "Helvetica-Bold"
        exitLabel.position = CGPoint(x: 0, y: -26)
        exitLabel.verticalAlignmentMode = .center
        exitMarker.addChild(exitLabel)
        
        // Injury check
        let aidTex = TextureFactory.firstAidIcon()
        let injuryCheck = SKSpriteNode(texture: aidTex, size: CGSize(width: 40, height: 40))
        injuryCheck.position = CGPoint(x: size.width / 2 + 120, y: RoomLayout.floorHeight + 50)
        injuryCheck.zPosition = 8
        injuryCheck.name = "injury_check"
        injuryCheck.alpha = 0
        scene.addChild(injuryCheck)
        
        // Fire extinguisher check (office specific)
        let extinguisherTex = createExtinguisherIcon()
        let extinguisher = SKSpriteNode(texture: extinguisherTex, size: CGSize(width: 35, height: 45))
        extinguisher.position = CGPoint(x: size.width - 60, y: RoomLayout.floorHeight + 40)
        extinguisher.zPosition = 8
        extinguisher.name = "fire_check"
        extinguisher.alpha = 0
        scene.addChild(extinguisher)
    }
    
    private static func buildBedroomAftershockZones(in scene: SKScene, size: CGSize) {
        // Injury check (bedroom priority - check for injuries first)
        let aidTex = TextureFactory.firstAidIcon()
        let injuryCheck = SKSpriteNode(texture: aidTex, size: CGSize(width: 45, height: 45))
        injuryCheck.position = CGPoint(x: size.width / 2, y: RoomLayout.floorHeight + 60)
        injuryCheck.zPosition = 8
        injuryCheck.name = "injury_check"
        injuryCheck.alpha = 0
        scene.addChild(injuryCheck)
        
        let injuryLabel = SKLabelNode(text: String(localized: "CHECK INJURIES"))
        injuryLabel.fontSize = DynamicTypeScale.scaled(9)
        injuryLabel.fontColor = SKColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1)
        injuryLabel.fontName = "Helvetica-Bold"
        injuryLabel.position = CGPoint(x: 0, y: -30)
        injuryLabel.verticalAlignmentMode = .center
        injuryCheck.addChild(injuryLabel)
        
        // Safe exit
        let exitTex = TextureFactory.exitSignIcon()
        let exitMarker = SKSpriteNode(texture: exitTex, size: CGSize(width: 50, height: 30))
        exitMarker.position = CGPoint(x: 70, y: RoomLayout.floorHeight + RoomLayout.doorHeight + 30)
        exitMarker.zPosition = 8
        exitMarker.name = "safe_exit"
        exitMarker.alpha = 0
        scene.addChild(exitMarker)
        
        // Wardrobe check (bedroom specific - check if it's blocking)
        let wardrobeTex = createWardrobeCheckIcon()
        let wardrobeCheck = SKSpriteNode(texture: wardrobeTex, size: CGSize(width: 40, height: 40))
        wardrobeCheck.position = CGPoint(x: size.width - 100, y: RoomLayout.floorHeight + 40)
        wardrobeCheck.zPosition = 8
        wardrobeCheck.name = "wardrobe_check"
        wardrobeCheck.alpha = 0
        scene.addChild(wardrobeCheck)
    }
    
    // MARK: - Hazard Indicators
    
    private static func addHazardIndicator(in scene: SKScene, at position: CGPoint, hazard: RoomHazard, visible: Bool) {
        let indicator = SKShapeNode(circleOfRadius: 15)
        indicator.fillColor = severityColor(hazard.severity).withAlphaComponent(0.3)
        indicator.strokeColor = severityColor(hazard.severity)
        indicator.lineWidth = 2
        indicator.position = position
        indicator.zPosition = 20
        indicator.name = "hazard_indicator_\(hazard.name)"
        indicator.alpha = visible ? 1.0 : 0.0
        
        // Warning icon
        let icon = SKLabelNode(text: "!")
        icon.fontSize = DynamicTypeScale.scaled(18)
        icon.fontColor = severityColor(hazard.severity)
        icon.fontName = "Helvetica-Bold"
        icon.verticalAlignmentMode = .center
        indicator.addChild(icon)
        
        scene.addChild(indicator)
    }
    
    private static func severityColor(_ severity: HazardSeverity) -> SKColor {
        switch severity {
        case .low: return SKColor(red: 0.9, green: 0.7, blue: 0.2, alpha: 1.0)
        case .moderate: return SKColor(red: 0.9, green: 0.5, blue: 0.2, alpha: 1.0)
        case .high: return SKColor(red: 0.9, green: 0.3, blue: 0.2, alpha: 1.0)
        case .extreme: return SKColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1.0)
        }
    }
    
    private static func hazardPosition(for name: String, in scene: SKScene) -> CGPoint? {
        // Map hazard names to node positions
        let nodeNames = [
            "Ceiling Lamp": "lamp",
            "Bookshelf": "bookshelf",
            "Picture Frames": "picture_frame_1",
            "Falling Knives": "knife_rack",
            "Boiling Water": "stove",
            "Gas Stove": "stove",
            "Hanging Pots/Pans": "pot_rack",
            "Falling Monitor": "monitor",
            "Filing Cabinet": "filing_cabinet",
            "Whiteboard": "whiteboard",
            "Glass Door": "door",
            "Wardrobe": "wardrobe",
            "Ceiling Fan": "ceiling_fan",
            "Mirror": "wall_mirror",
            "Lamp on Nightstand": "nightstand_left_lamp",
            "Tall Dresser": "wardrobe"
        ]
        
        guard let nodeName = nodeNames[name],
              let node = scene.childNode(withName: nodeName) else {
            return nil
        }
        return node.position
    }
    
    // MARK: - Configuration Storage
    
    private static func storeRoomConfiguration(_ config: RoomConfiguration, in scene: SKScene) {
        // Store as user data for access during gameplay
        scene.userData = NSMutableDictionary()
        scene.userData?["roomType"] = config.roomType.displayName
        scene.userData?["safeZoneName"] = config.roomType.safeZoneName
        scene.userData?["educationalTip"] = config.roomType.educationalTip
        
        // Store hazard information
        let hazardData = config.uniqueHazards.map { hazard -> [String: Any] in
            [
                "name": hazard.name,
                "type": hazard.hazardType.description,
                "severity": hazard.severity.rawValue,
                "before": hazard.beforeQuakeAdvice,
                "during": hazard.duringQuakeAdvice,
                "after": hazard.afterQuakeAdvice
            ]
        }
        scene.userData?["hazards"] = hazardData
    }
    
    // MARK: - Custom Texture Helpers
    
    private static func createKnifeTexture() -> SKTexture {
        let renderer = TextureFactory.makeTransparentRenderer(width: 6, height: 25)
        let image = renderer.image { context in
            let ctx = context.cgContext
            // Blade
            ctx.setFillColor(UIColor(white: 0.8, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: 1, y: 0, width: 4, height: 18))
            // Handle
            ctx.setFillColor(UIColor(red: 0.4, green: 0.25, blue: 0.15, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: 1, y: 18, width: 4, height: 7))
        }
        return TextureFactory.finalize(image)
    }
    
    private static func createFanBladeTexture() -> SKTexture {
        let renderer = TextureFactory.makeTransparentRenderer(width: 100, height: 100)
        let image = renderer.image { context in
            let ctx = context.cgContext
            let center = CGPoint(x: 50, y: 50)
            
            // Draw 3 blades
            for i in 0..<3 {
                let angle = CGFloat(i) * (.pi * 2 / 3)
                ctx.saveGState()
                ctx.translateBy(x: center.x, y: center.y)
                ctx.rotate(by: angle)
                
                // Blade
                ctx.setFillColor(UIColor(white: 0.9, alpha: 1.0).cgColor)
                ctx.fill(CGRect(x: -8, y: -45, width: 16, height: 40))
                ctx.setStrokeColor(UIColor(white: 0.6, alpha: 1.0).cgColor)
                ctx.setLineWidth(1)
                ctx.stroke(CGRect(x: -8, y: -45, width: 16, height: 40))
                
                ctx.restoreGState()
            }
            
            // Center hub
            ctx.setFillColor(UIColor(white: 0.7, alpha: 1.0).cgColor)
            ctx.fillEllipse(in: CGRect(x: 42, y: 42, width: 16, height: 16))
        }
        return TextureFactory.finalize(image)
    }
    
    private static func createMirrorTexture() -> SKTexture {
        let renderer = TextureFactory.makeTransparentRenderer(width: 50, height: 80)
        let image = renderer.image { context in
            let ctx = context.cgContext
            
            // Frame
            ctx.setFillColor(UIColor(red: 0.5, green: 0.35, blue: 0.2, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: 50, height: 80))
            
            // Mirror surface
            ctx.setFillColor(UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 0.8).cgColor)
            ctx.fill(CGRect(x: 4, y: 4, width: 42, height: 72))
            
            // Highlight
            ctx.setStrokeColor(UIColor.white.withAlphaComponent(0.5).cgColor)
            ctx.setLineWidth(2)
            ctx.move(to: CGPoint(x: 8, y: 70))
            ctx.addLine(to: CGPoint(x: 20, y: 10))
            ctx.strokePath()
        }
        return TextureFactory.finalize(image)
    }
    
    private static func createGasWarningTexture() -> SKTexture {
        let renderer = TextureFactory.makeTransparentRenderer(width: 30, height: 30)
        let image = renderer.image { context in
            let ctx = context.cgContext
            
            // Yellow warning triangle
            let triangle = CGMutablePath()
            triangle.move(to: CGPoint(x: 15, y: 2))
            triangle.addLine(to: CGPoint(x: 28, y: 26))
            triangle.addLine(to: CGPoint(x: 2, y: 26))
            triangle.closeSubpath()
            
            ctx.setFillColor(UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0).cgColor)
            ctx.addPath(triangle)
            ctx.fillPath()
            
            // Exclamation mark
            ctx.setFillColor(UIColor.black.cgColor)
            ctx.fill(CGRect(x: 13, y: 8, width: 4, height: 10))
            ctx.fill(CGRect(x: 13, y: 20, width: 4, height: 4))
        }
        return TextureFactory.finalize(image)
    }
    
    private static func createExtinguisherIcon() -> SKTexture {
        let renderer = TextureFactory.makeTransparentRenderer(width: 35, height: 45)
        let image = renderer.image { context in
            let ctx = context.cgContext
            
            // Tank
            ctx.setFillColor(UIColor.red.cgColor)
            ctx.fill(CGRect(x: 8, y: 10, width: 19, height: 30))
            
            // Top
            ctx.setFillColor(UIColor(white: 0.3, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: 12, y: 5, width: 11, height: 8))
            
            // Nozzle/hose
            ctx.setStrokeColor(UIColor.black.cgColor)
            ctx.setLineWidth(3)
            ctx.move(to: CGPoint(x: 20, y: 8))
            ctx.addLine(to: CGPoint(x: 28, y: 15))
            ctx.strokePath()
            
            // Label
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.fill(CGRect(x: 10, y: 22, width: 15, height: 8))
        }
        return TextureFactory.finalize(image)
    }
    
    private static func createWardrobeCheckIcon() -> SKTexture {
        let renderer = TextureFactory.makeTransparentRenderer(width: 40, height: 40)
        let image = renderer.image { context in
            let ctx = context.cgContext
            
            // Cabinet outline
            ctx.setStrokeColor(UIColor(red: 0.4, green: 0.25, blue: 0.15, alpha: 1.0).cgColor)
            ctx.setLineWidth(3)
            ctx.stroke(CGRect(x: 5, y: 5, width: 30, height: 30))
            
            // Doors
            ctx.move(to: CGPoint(x: 20, y: 5))
            ctx.addLine(to: CGPoint(x: 20, y: 35))
            ctx.strokePath()
            
            // Warning overlay
            ctx.setFillColor(UIColor.red.withAlphaComponent(0.3).cgColor)
            ctx.fill(CGRect(x: 5, y: 5, width: 30, height: 30))
            
            // Question mark
            ctx.setFillColor(UIColor.white.cgColor)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 20),
                .foregroundColor: UIColor.red
            ]
            let str = NSAttributedString(string: "?", attributes: attrs)
            str.draw(at: CGPoint(x: 13, y: 8))
        }
        return TextureFactory.finalize(image)
    }
}

// MARK: - Room Type Extensions for Gameplay

extension RoomType {
    
    /// Get decision options specific to this room
    /// Note: Add .stayInBed case for bedroom when implemented in PlayerAction
    var roomSpecificDecisions: [PlayerAction] {
        // Base actions available in all rooms
        let baseActions: [PlayerAction] = [.dropUnderTable, .moveToWindow, .runToDoor, .nearBookshelf]
        
        // Bedroom has special "stay in bed" option for night scenarios
        // This can be added when the case is implemented in PlayerAction
        return baseActions
    }
    
    /// Special actions available during aftershock in this room
    /// Note: Add room-specific cases when implemented in PlayerAction:
    /// - Kitchen: .extinguishFire
    /// - Office: .extinguishFire  
    /// - Bedroom: .checkWardrobe
    var aftershockActions: [PlayerAction] {
        // Base aftershock actions available in all rooms
        return [.shutOffGas, .findSafeExit, .checkInjuries]
    }
    
    /// Get extended action info for room-specific scenarios
    var extendedAftershockActions: [ExtendedActionInfo] {
        switch self {
        case .livingRoom:
            return []
        case .kitchen:
            return [ExtendedActions.extinguishFire]
        case .office:
            return [ExtendedActions.extinguishFire]
        case .bedroom:
            return [ExtendedActions.checkWardrobe]
        }
    }
    
    /// Get safety evaluation for a position in this room
    @MainActor
    func evaluateSafety(at position: CGPoint, in scene: SKScene) -> SafetyEvaluation {
        var score = 100
        var hazards: [String] = []
        var recommendations: [String] = []
        
        // Check distance from danger zones
        for node in scene.children where node.name?.hasSuffix("_zone") == true {
            guard let zone = node as? SKSpriteNode else { continue }
            let distance = hypot(position.x - zone.position.x, position.y - zone.position.y)

            if distance < 50 {
                score -= 40
                hazards.append("Very close to \(zone.name ?? "danger zone")")
                recommendations.append("Move away from \(zone.name ?? "danger") immediately")
            } else if distance < 100 {
                score -= 20
                hazards.append("Near \(zone.name ?? "danger zone")")
            }
        }

        // Check if under safe zone
        var isUnderSafeZone = false
        for node in scene.children where node.name == safeZoneNodeName {
            guard let zone = node as? SKSpriteNode else { continue }
            if zone.frame.contains(position) {
                isUnderSafeZone = true
                score += 20
                break
            }
        }
        
        if isUnderSafeZone {
            recommendations.append("Good! You're in a safe zone. Hold on!")
        } else {
            recommendations.append("Move to \(safeZoneName) for protection")
        }
        
        // Clamp score
        score = max(0, min(100, score))
        
        return SafetyEvaluation(
            score: score,
            rating: SafetyRating(rawValue: max(1, min(5, score / 20))) ?? .moderate,
            hazards: hazards,
            recommendations: recommendations,
            isOptimalPosition: isUnderSafeZone && score >= 80
        )
    }
}

// MARK: - Safety Evaluation

struct SafetyEvaluation: Sendable {
    let score: Int  // 0-100
    let rating: SafetyRating
    let hazards: [String]
    let recommendations: [String]
    let isOptimalPosition: Bool
}

// MARK: - Room-Specific Action Definitions

/// Extended actions that should be added to PlayerAction enum in Decision.swift:
///
/// case stayInBed       // Bedroom: stay in bed during night quake
/// case extinguishFire  // Kitchen/Office: put out small fires  
/// case checkWardrobe   // Bedroom: check if wardrobe blocked exit
///
/// Note: To fully implement room-specific actions, add these cases to the
/// PlayerAction enum in Models/Decision.swift and update the computed properties.

/// Information about additional actions available in specific rooms
struct ExtendedActionInfo: Sendable {
    let rawValue: String
    let isCorrect: Bool
    let basePoints: Int
    let feedback: String
    let educationalNote: String
    let iconName: String
    let applicableRooms: [RoomType]
}

/// Extended actions for room-specific scenarios
enum ExtendedActions {
    /// Stay in bed action for bedroom night scenario
    static let stayInBed = ExtendedActionInfo(
        rawValue: "stay_in_bed",
        isCorrect: true,
        basePoints: 15,
        feedback: String(localized: "Smart! Staying in bed protects you from falling objects"),
        educationalNote: String(localized: "If you're in bed when an earthquake strikes, stay there and protect your head with a pillow."),
        iconName: "bed.double.fill",
        applicableRooms: [.bedroom]
    )
    
    /// Extinguish fire action for kitchen/office
    static let extinguishFire = ExtendedActionInfo(
        rawValue: "extinguish_fire",
        isCorrect: true,
        basePoints: 20,
        feedback: String(localized: "Good thinking! Small fires can become big problems"),
        educationalNote: String(localized: "Only attempt to extinguish small fires. If it's large, evacuate immediately."),
        iconName: "fire.extinguisher.fill",
        applicableRooms: [.kitchen, .office]
    )
    
    /// Check wardrobe action for bedroom
    static let checkWardrobe = ExtendedActionInfo(
        rawValue: "check_wardrobe",
        isCorrect: true,
        basePoints: 10,
        feedback: String(localized: "Good check! Wardrobes can tip and block exits"),
        educationalNote: String(localized: "Always check that tall furniture hasn't tipped over or blocked your escape route."),
        iconName: "cabinet.fill",
        applicableRooms: [.bedroom]
    )
    
    /// All extended actions
    static let all: [ExtendedActionInfo] = [stayInBed, extinguishFire, checkWardrobe]
    
    /// Get actions applicable to a specific room
    static func actions(for room: RoomType) -> [ExtendedActionInfo] {
        all.filter { $0.applicableRooms.contains(room) }
    }
}

// MARK: - UIColor Helper

private extension UIColor {
    var skColor: SKColor {
        return SKColor(cgColor: self.cgColor)
    }
}
