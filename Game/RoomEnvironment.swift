import SpriteKit

// MARK: - Room Environment Settings

/// Defines the visual environment for a room including time of day, weather, and season
struct RoomEnvironment: Equatable, Sendable {
    let timeOfDay: TimeOfDay
    let weather: Weather
    let season: Season

    static let `default` = RoomEnvironment(timeOfDay: .morning, weather: .clear, season: .spring)

    /// Random environment for variety
    static var random: RoomEnvironment {
        RoomEnvironment(
            timeOfDay: TimeOfDay.allCases.randomElement()!,
            weather: Weather.allCases.randomElement()!,
            season: Season.allCases.randomElement()!
        )
    }

    /// Environment specific to room type for curated experiences
    static func curated(for roomType: RoomBuilder.RoomType) -> RoomEnvironment {
        switch roomType {
        case .livingRoom:
            // Living room gets warm evening lighting
            return RoomEnvironment(timeOfDay: .evening, weather: .clear, season: .autumn)
        case .kitchen:
            // Kitchen gets bright morning light
            return RoomEnvironment(timeOfDay: .morning, weather: .clear, season: .summer)
        case .office:
            // Office gets bright afternoon with clear weather
            return RoomEnvironment(timeOfDay: .afternoon, weather: .clear, season: .winter)
        case .bedroom:
            // Bedroom gets cozy night time
            return RoomEnvironment(timeOfDay: .night, weather: .clear, season: .winter)
        }
    }
}

// MARK: - Time of Day

enum TimeOfDay: CaseIterable, Sendable {
    case morning      // 6-12: Warm, soft light
    case afternoon    // 12-17: Bright, direct light
    case evening      // 17-20: Golden hour, warm
    case night        // 20-6: Dark, artificial lighting

    var displayName: String {
        switch self {
        case .morning: return "Morning"
        case .afternoon: return "Afternoon"
        case .evening: return "Evening"
        case .night: return "Night"
        }
    }

    /// Background color for the room wall
    var wallColor: SKColor {
        switch self {
        case .morning:
            return SKColor(red: 0.98, green: 0.96, blue: 0.92, alpha: 1.0)
        case .afternoon:
            return SKColor(red: 1.0, green: 0.99, blue: 0.95, alpha: 1.0)
        case .evening:
            return SKColor(red: 0.95, green: 0.90, blue: 0.82, alpha: 1.0)
        case .night:
            return SKColor(red: 0.75, green: 0.75, blue: 0.82, alpha: 1.0)
        }
    }

    /// Floor color adjusted for lighting
    var floorColor: SKColor {
        switch self {
        case .morning:
            return SKColor(red: 0.82, green: 0.72, blue: 0.60, alpha: 1.0)
        case .afternoon:
            return SKColor(red: 0.85, green: 0.75, blue: 0.62, alpha: 1.0)
        case .evening:
            return SKColor(red: 0.78, green: 0.68, blue: 0.55, alpha: 1.0)
        case .night:
            return SKColor(red: 0.60, green: 0.55, blue: 0.50, alpha: 1.0)
        }
    }

    /// Ambient lighting overlay color (using alpha blend, not multiply)
    var ambientOverlayColor: SKColor {
        switch self {
        case .morning:
            return SKColor(red: 1.0, green: 0.95, blue: 0.85, alpha: 0.08)  // Warm morning glow
        case .afternoon:
            return SKColor(red: 1.0, green: 1.0, blue: 0.95, alpha: 0.05)   // Bright white
        case .evening:
            return SKColor(red: 1.0, green: 0.75, blue: 0.50, alpha: 0.10)  // Golden hour
        case .night:
            return SKColor(red: 0.60, green: 0.65, blue: 0.85, alpha: 0.15)  // Cool night (lighter, less alpha)
        }
    }

    /// Window light color
    var windowLightColor: SKColor {
        switch self {
        case .morning:
            return SKColor(red: 1.0, green: 0.92, blue: 0.75, alpha: 0.6)
        case .afternoon:
            return SKColor(red: 1.0, green: 0.98, blue: 0.90, alpha: 0.7)
        case .evening:
            return SKColor(red: 1.0, green: 0.65, blue: 0.35, alpha: 0.5)
        case .night:
            return SKColor(red: 0.70, green: 0.75, blue: 0.90, alpha: 0.3)  // Moonlight
        }
    }

    /// Shadow intensity (0-1)
    var shadowIntensity: CGFloat {
        switch self {
        case .morning: return 0.3
        case .afternoon: return 0.4
        case .evening: return 0.5
        case .night: return 0.7
        }
    }
}

// MARK: - Weather

enum Weather: CaseIterable, Sendable {
    case clear
    case rainy
    case stormy
    case snowy

    var displayName: String {
        switch self {
        case .clear: return "Clear"
        case .rainy: return "Rainy"
        case .stormy: return "Stormy"
        case .snowy: return "Snowy"
        }
    }

    /// Should show rain particles
    var hasRain: Bool {
        self == .rainy || self == .stormy
    }

    /// Should show snow particles
    var hasSnow: Bool {
        self == .snowy
    }

    /// Window tint based on weather
    var windowTint: SKColor {
        switch self {
        case .clear:
            return SKColor.clear
        case .rainy:
            return SKColor(red: 0.6, green: 0.65, blue: 0.75, alpha: 0.2)
        case .stormy:
            return SKColor(red: 0.4, green: 0.45, blue: 0.55, alpha: 0.35)
        case .snowy:
            return SKColor(red: 0.85, green: 0.90, blue: 0.95, alpha: 0.15)
        }
    }

    /// Ambient brightness multiplier
    var brightnessMultiplier: CGFloat {
        switch self {
        case .clear: return 1.0
        case .rainy: return 0.85
        case .stormy: return 0.70
        case .snowy: return 0.90
        }
    }
}

// MARK: - Season

enum Season: CaseIterable, Sendable {
    case spring
    case summer
    case autumn
    case winter

    var displayName: String {
        switch self {
        case .spring: return "Spring"
        case .summer: return "Summer"
        case .autumn: return "Autumn"
        case .winter: return "Winter"
        }
    }

    /// Color palette for decorations
    var primaryColor: SKColor {
        switch self {
        case .spring:
            return SKColor(red: 0.5, green: 0.8, blue: 0.4, alpha: 1.0)   // Fresh green
        case .summer:
            return SKColor(red: 1.0, green: 0.7, blue: 0.2, alpha: 1.0)   // Sunny yellow
        case .autumn:
            return SKColor(red: 0.9, green: 0.5, blue: 0.2, alpha: 1.0)   // Orange
        case .winter:
            return SKColor(red: 0.4, green: 0.6, blue: 0.8, alpha: 1.0)   // Icy blue
        }
    }

    /// Secondary accent color
    var secondaryColor: SKColor {
        switch self {
        case .spring:
            return SKColor(red: 1.0, green: 0.7, blue: 0.8, alpha: 1.0)   // Pink blossoms
        case .summer:
            return SKColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0)   // Ocean blue
        case .autumn:
            return SKColor(red: 0.6, green: 0.3, blue: 0.2, alpha: 1.0)   // Brown
        case .winter:
            return SKColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1.0)   // Snow white
        }
    }
}

// MARK: - Room Environment Builder

@MainActor
enum RoomEnvironmentBuilder {

    /// Applies environment settings to a scene
    static func apply(environment: RoomEnvironment, to scene: SKScene) {
        // Apply base lighting
        applyLighting(environment: environment, to: scene)

        // Add weather effects
        if environment.weather.hasRain {
            addRainEffect(to: scene, intensity: environment.weather == .stormy ? 1.0 : 0.5)
        } else if environment.weather.hasSnow {
            addSnowEffect(to: scene)
        }

        // Add seasonal decorations
        addSeasonalDecorations(season: environment.season, to: scene)

        // Add time-of-day specific elements
        addTimeOfDayElements(timeOfDay: environment.timeOfDay, to: scene)
    }

    // MARK: - Lighting

    private static func applyLighting(environment: RoomEnvironment, to scene: SKScene) {
        let timeOfDay = environment.timeOfDay

        // Create ambient lighting overlay
        let overlaySize = CGSize(width: scene.size.width + 100, height: scene.size.height + 100)
        let ambientOverlay = SKSpriteNode(color: timeOfDay.ambientOverlayColor, size: overlaySize)
        ambientOverlay.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        ambientOverlay.zPosition = 100
        ambientOverlay.name = "ambient_lighting"
        ambientOverlay.blendMode = .alpha
        scene.addChild(ambientOverlay)

        // Add window light glow
        if let window = scene.childNode(withName: "window") ??
                        scene.childNode(withName: "window_blinds") ??
                        scene.childNode(withName: "window_curtains") {
            let windowGlow = SKSpriteNode(color: timeOfDay.windowLightColor,
                                          size: CGSize(width: 200, height: 300))
            windowGlow.position = CGPoint(x: window.position.x, y: window.position.y - 50)
            windowGlow.zPosition = -8
            windowGlow.name = "window_glow"
            windowGlow.blendMode = .add
            scene.addChild(windowGlow)

            // Add light rays for morning/evening
            if timeOfDay == .morning || timeOfDay == .evening {
                addLightRays(at: window.position, to: scene, color: timeOfDay.windowLightColor)
            }
        }

        // Add shadows
        if timeOfDay.shadowIntensity > 0 {
            addShadows(to: scene, intensity: timeOfDay.shadowIntensity)
        }

        // Weather darkening overlay (subtle gray instead of black)
        if environment.weather != .clear {
            let darkeningAlpha = (1.0 - environment.weather.brightnessMultiplier) * 0.5
            let weatherOverlay = SKSpriteNode(color: SKColor(white: 0.2, alpha: 1.0), size: overlaySize)
            weatherOverlay.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
            weatherOverlay.zPosition = 99
            weatherOverlay.name = "weather_overlay"
            weatherOverlay.alpha = darkeningAlpha
            weatherOverlay.blendMode = .multiply
            scene.addChild(weatherOverlay)
        }
    }

    private static func addLightRays(at position: CGPoint, to scene: SKScene, color: SKColor) {
        let rayCount = 5
        for i in 0..<rayCount {
            let angle = CGFloat(i - rayCount/2) * 0.15
            let ray = SKSpriteNode(color: color, size: CGSize(width: 40, height: 400))
            ray.position = CGPoint(x: position.x, y: position.y - 200)
            ray.zPosition = -9
            ray.zRotation = angle
            ray.name = "light_ray_\(i)"
            ray.alpha = 0.3
            ray.blendMode = .add
            scene.addChild(ray)

            // Animate light rays
            let fadeIn = SKAction.fadeAlpha(to: 0.4, duration: 2.0)
            let fadeOut = SKAction.fadeAlpha(to: 0.2, duration: 2.0)
            let sequence = SKAction.sequence([fadeIn, fadeOut])
            ray.run(SKAction.repeatForever(sequence))
        }
    }

    private static func addShadows(to scene: SKScene, intensity: CGFloat) {
        // Add subtle vignette for shadows (only if intensity is significant)
        guard intensity > 0.1 else { return }

        let vignette = SKShapeNode(rectOf: CGSize(width: scene.size.width, height: scene.size.height))
        vignette.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        vignette.fillColor = SKColor.black
        vignette.alpha = intensity * 0.15
        vignette.zPosition = 98
        vignette.name = "shadow_overlay"
        vignette.blendMode = .alpha
        scene.addChild(vignette)
    }

    // MARK: - Weather Effects

    private static func addRainEffect(to scene: SKScene, intensity: CGFloat) {
        let emitter = SKEmitterNode()
        emitter.position = CGPoint(x: scene.size.width / 2, y: scene.size.height + 50)
        emitter.zPosition = 50
        emitter.name = "rain_emitter"

        // Rain particle texture
        emitter.particleTexture = createRaindropTexture()

        // Rain properties
        emitter.particleBirthRate = 200 * intensity
        emitter.numParticlesToEmit = 0  // Continuous

        emitter.particleLifetime = 1.0
        emitter.particleLifetimeRange = 0.3

        emitter.yAcceleration = -800
        emitter.particleSpeed = 400
        emitter.particleSpeedRange = 100

        emitter.emissionAngle = -.pi / 2
        emitter.emissionAngleRange = 0.1

        emitter.particlePositionRange = CGVector(dx: scene.size.width + 100, dy: 10)

        emitter.particleScale = 0.5
        emitter.particleScaleRange = 0.2

        emitter.particleColor = SKColor(red: 0.7, green: 0.8, blue: 1.0, alpha: 0.6)
        emitter.particleBlendMode = .add

        scene.addChild(emitter)

        // Add rain sound indicator (visual only - audio handled separately)
        let rainOverlay = SKSpriteNode(color: SKColor(red: 0.8, green: 0.85, blue: 0.95, alpha: 0.1),
                                       size: scene.size)
        rainOverlay.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        rainOverlay.zPosition = 95
        rainOverlay.name = "rain_overlay"
        scene.addChild(rainOverlay)
    }

    private static func addSnowEffect(to scene: SKScene) {
        let emitter = SKEmitterNode()
        emitter.position = CGPoint(x: scene.size.width / 2, y: scene.size.height + 50)
        emitter.zPosition = 50
        emitter.name = "snow_emitter"

        // Snow particle texture
        emitter.particleTexture = createSnowflakeTexture()

        // Snow properties
        emitter.particleBirthRate = 100
        emitter.numParticlesToEmit = 0  // Continuous

        emitter.particleLifetime = 4.0
        emitter.particleLifetimeRange = 1.0

        emitter.yAcceleration = -50
        emitter.particleSpeed = 30
        emitter.particleSpeedRange = 20

        emitter.emissionAngle = -.pi / 2
        emitter.emissionAngleRange = 0.3

        emitter.particlePositionRange = CGVector(dx: scene.size.width + 100, dy: 10)

        emitter.particleScale = 0.3
        emitter.particleScaleRange = 0.2
        emitter.particleScaleSpeed = -0.05

        emitter.particleRotationRange = .pi * 2
        emitter.particleRotationSpeed = 1.0

        emitter.particleColor = SKColor.white
        emitter.particleAlpha = 0.8
        emitter.particleAlphaSpeed = -0.1
        emitter.particleBlendMode = .add

        scene.addChild(emitter)
    }

    // MARK: - Seasonal Decorations

    private static func addSeasonalDecorations(season: Season, to scene: SKScene) {
        let size = scene.size

        switch season {
        case .spring:
            addSpringDecorations(to: scene, size: size)
        case .summer:
            addSummerDecorations(to: scene, size: size)
        case .autumn:
            addAutumnDecorations(to: scene, size: size)
        case .winter:
            addWinterDecorations(to: scene, size: size)
        }
    }

    private static func addSpringDecorations(to scene: SKScene, size: CGSize) {
        // Flower petals falling
        let emitter = SKEmitterNode()
        emitter.position = CGPoint(x: size.width - 150, y: size.height - 150)
        emitter.zPosition = 5
        emitter.name = "flower_petals"

        emitter.particleTexture = createPetalTexture(color: SKColor(red: 1.0, green: 0.7, blue: 0.8, alpha: 1.0))
        emitter.particleBirthRate = 2
        emitter.numParticlesToEmit = 0
        emitter.particleLifetime = 3.0
        emitter.yAcceleration = -30
        emitter.particleSpeed = 10
        emitter.emissionAngleRange = .pi
        emitter.particleScale = 0.3
        emitter.particleRotationSpeed = 0.5
        emitter.particleAlpha = 0.6

        scene.addChild(emitter)
    }

    private static func addSummerDecorations(to scene: SKScene, size: CGSize) {
        // Sunbeams are already handled by lighting
        // Add a sun reflection on the floor
        let sunReflection = SKSpriteNode(color: SKColor.yellow, size: CGSize(width: 100, height: 60))
        sunReflection.position = CGPoint(x: size.width / 2 + 100, y: RoomLayout.floorHeight + 30)
        sunReflection.zPosition = -4
        sunReflection.name = "sun_reflection"
        sunReflection.alpha = 0.2
        sunReflection.blendMode = .add
        scene.addChild(sunReflection)
    }

    private static func addAutumnDecorations(to scene: SKScene, size: CGSize) {
        // Falling autumn leaves
        let colors = [
            SKColor(red: 0.9, green: 0.4, blue: 0.1, alpha: 1.0),  // Orange
            SKColor(red: 0.8, green: 0.2, blue: 0.1, alpha: 1.0),  // Red
            SKColor(red: 0.7, green: 0.5, blue: 0.1, alpha: 1.0)   // Yellow
        ]

        for (i, color) in colors.enumerated() {
            let emitter = SKEmitterNode()
            emitter.position = CGPoint(x: CGFloat(150 + i * 300), y: size.height)
            emitter.zPosition = 5
            emitter.name = "autumn_leaves_\(i)"

            emitter.particleTexture = createLeafTexture(color: color)
            emitter.particleBirthRate = 1
            emitter.numParticlesToEmit = 0
            emitter.particleLifetime = 5.0
            emitter.yAcceleration = -40
            emitter.particleSpeed = 15
            emitter.emissionAngleRange = .pi / 3
            emitter.particleScale = 0.4
            emitter.particleRotationSpeed = 1.0
            emitter.particleAlpha = 0.7

            scene.addChild(emitter)
        }
    }

    private static func addWinterDecorations(to scene: SKScene, size: CGSize) {
        // Frost on windows
        if let window = scene.childNode(withName: "window") ??
                        scene.childNode(withName: "window_blinds") ??
                        scene.childNode(withName: "window_curtains") {
            let frost = SKSpriteNode(color: SKColor.white, size: CGSize(width: 80, height: 120))
            frost.position = window.position
            frost.zPosition = window.zPosition + 0.5
            frost.name = "window_frost"
            frost.alpha = 0.2
            frost.blendMode = .add
            scene.addChild(frost)
        }

        // Icicles near window
        if let window = scene.childNode(withName: "window") {
            for i in 0..<3 {
                let icicle = SKSpriteNode(color: SKColor(red: 0.85, green: 0.95, blue: 1.0, alpha: 0.8),
                                          size: CGSize(width: 8, height: CGFloat(20 + i * 10)))
                icicle.position = CGPoint(x: window.position.x - 30 + CGFloat(i * 30),
                                         y: window.position.y - 70)
                icicle.zPosition = 2
                icicle.name = "icicle_\(i)"
                scene.addChild(icicle)
            }
        }
    }

    // MARK: - Time of Day Elements

    private static func addTimeOfDayElements(timeOfDay: TimeOfDay, to scene: SKScene) {
        switch timeOfDay {
        case .night:
            // Add glowing lamp light
            addLampGlow(to: scene)
        case .evening:
            // Sunset gradient on window
            addSunsetGlow(to: scene)
        default:
            break
        }
    }

    private static func addLampGlow(to scene: SKScene) {
        // Enhance existing lamp glow
        if let lamp = scene.childNode(withName: "lamp") {
            let enhancedGlow = SKSpriteNode(color: SKColor(red: 1.0, green: 0.9, blue: 0.6, alpha: 0.4),
                                            size: CGSize(width: 150, height: 150))
            enhancedGlow.position = lamp.position
            enhancedGlow.zPosition = 3
            enhancedGlow.name = "enhanced_lamp_glow"
            enhancedGlow.blendMode = .add
            scene.addChild(enhancedGlow)

            // Pulsing animation
            let pulseIn = SKAction.scale(to: 1.1, duration: 2.0)
            let pulseOut = SKAction.scale(to: 1.0, duration: 2.0)
            enhancedGlow.run(SKAction.repeatForever(SKAction.sequence([pulseIn, pulseOut])))
        }

        // Turn on bedside lamps in bedroom
        if scene.childNode(withName: "bed") != nil {
            for suffix in ["left", "right"] {
                if let nightstandLamp = scene.childNode(withName: "nightstand_\(suffix)_lamp") {
                    let lampLight = SKSpriteNode(color: SKColor(red: 1.0, green: 0.9, blue: 0.6, alpha: 0.3),
                                                 size: CGSize(width: 60, height: 60))
                    lampLight.position = nightstandLamp.position
                    lampLight.zPosition = 3
                    lampLight.name = "bedside_lamp_light_\(suffix)"
                    lampLight.blendMode = .add
                    scene.addChild(lampLight)
                }
            }
        }
    }

    private static func addSunsetGlow(to scene: SKScene) {
        if let window = scene.childNode(withName: "window") {
            let sunsetGlow = SKSpriteNode(color: SKColor(red: 1.0, green: 0.5, blue: 0.2, alpha: 0.3),
                                          size: CGSize(width: 100, height: 150))
            sunsetGlow.position = CGPoint(x: window.position.x, y: window.position.y)
            sunsetGlow.zPosition = -7
            sunsetGlow.name = "sunset_glow"
            sunsetGlow.blendMode = .add
            scene.addChild(sunsetGlow)
        }
    }

    // MARK: - Texture Generation

    private static func createRaindropTexture() -> SKTexture {
        let size = CGSize(width: 2, height: 8)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            let ctx = context.cgContext
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor(white: 1.0, alpha: 0.8).cgColor,
                    UIColor(white: 1.0, alpha: 0.0).cgColor
                ] as CFArray,
                locations: [0.0, 1.0]
            )!
            ctx.drawLinearGradient(gradient,
                                   start: CGPoint(x: 1, y: 0),
                                   end: CGPoint(x: 1, y: 8),
                                   options: [])
        }

        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }

    private static func createSnowflakeTexture() -> SKTexture {
        let size = CGSize(width: 6, height: 6)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            let ctx = context.cgContext
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.fillEllipse(in: CGRect(x: 1, y: 1, width: 4, height: 4))
        }

        let texture = SKTexture(image: image)
        texture.filteringMode = SKTextureFilteringMode.linear
        return texture
    }

    private static func createPetalTexture(color: SKColor) -> SKTexture {
        let size = CGSize(width: 8, height: 8)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            let ctx = context.cgContext
            ctx.setFillColor(color.cgColor)
            // Draw oval petal shape
            ctx.fillEllipse(in: CGRect(x: 2, y: 1, width: 4, height: 6))
        }

        let texture = SKTexture(image: image)
        texture.filteringMode = SKTextureFilteringMode.linear
        return texture
    }

    private static func createLeafTexture(color: SKColor) -> SKTexture {
        let size = CGSize(width: 10, height: 10)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            let ctx = context.cgContext
            ctx.setFillColor(color.cgColor)
            // Draw simple leaf shape
            ctx.fillEllipse(in: CGRect(x: 3, y: 1, width: 4, height: 8))
            ctx.fillEllipse(in: CGRect(x: 1, y: 3, width: 8, height: 4))
        }

        let texture = SKTexture(image: image)
        texture.filteringMode = SKTextureFilteringMode.linear
        return texture
    }
}
