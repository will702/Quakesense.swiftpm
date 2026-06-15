import SpriteKit

// MARK: - Particle Effects System

/// Comprehensive particle effects system for QuakeSense.
/// Provides material-based, environmental, and interactive particle effects
/// with realistic physics parameters and visual polish.
@MainActor
enum ParticleEffects {
    
    // MARK: - Material-Based Particles
    
    /// Creates wood debris particles when furniture breaks (e.g., bookshelf)
    /// - Parameters:
    ///   - position: The origin point of the debris
    ///   - intensity: The intensity of the destruction (0.0 - 1.0)
    /// - Returns: A configured SKEmitterNode with wood debris effect
    static func woodDebris(at position: CGPoint, intensity: CGFloat = 0.5) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.position = position
        emitter.zPosition = 20
        
        // Texture - small wood chips
        emitter.particleTexture = createWoodChipTexture()
        
        // Birth rate based on intensity
        emitter.particleBirthRate = 80 * intensity
        emitter.numParticlesToEmit = Int(40 * intensity)
        
        // Lifetime
        emitter.particleLifetime = 1.2
        emitter.particleLifetimeRange = 0.4
        
        // Physics - heavier particles fall faster
        emitter.yAcceleration = -400
        emitter.particleSpeed = 150 * intensity
        emitter.particleSpeedRange = 80 * intensity
        
        // Spread in upward arc
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi / 2.5
        
        // Size variation - wood chips of different sizes
        emitter.particleScale = 0.4
        emitter.particleScaleRange = 0.3
        emitter.particleScaleSpeed = -0.15
        
        // Rotation for tumbling debris
        emitter.particleRotationRange = .pi * 2
        emitter.particleRotationSpeed = CGFloat.random(in: -4...4)
        
        // Color variations for wood
        emitter.particleColor = SKColor(red: 0.55, green: 0.38, blue: 0.22, alpha: 1.0)
        emitter.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [
                SKColor(red: 0.65, green: 0.45, blue: 0.28, alpha: 1.0),
                SKColor(red: 0.50, green: 0.35, blue: 0.20, alpha: 1.0),
                SKColor(red: 0.40, green: 0.28, blue: 0.15, alpha: 0.8)
            ],
            times: [0.0, 0.5, 1.0]
        )
        emitter.particleColorBlendFactor = 0.8
        
        // Alpha fade out
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -0.8
        
        // Blend mode
        emitter.particleBlendMode = .alpha
        
        return emitter
    }
    
    /// Creates glass shard particles when windows shatter
    /// - Parameters:
    ///   - position: The origin point of the shatter
    ///   - intensity: The intensity of the shatter (0.0 - 1.0)
    /// - Returns: A configured SKEmitterNode with glass shard effect
    static func glassShards(at position: CGPoint, intensity: CGFloat = 0.7) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.position = position
        emitter.zPosition = 22
        
        // Texture - glass shard shape
        emitter.particleTexture = createGlassShardTexture()
        
        // High birth rate for shatter effect
        emitter.particleBirthRate = 300 * intensity
        emitter.numParticlesToEmit = Int(80 * intensity)
        
        // Short lifetime for shards
        emitter.particleLifetime = 0.8
        emitter.particleLifetimeRange = 0.3
        
        // Physics - lighter than wood, can bounce
        emitter.yAcceleration = -600
        emitter.particleSpeed = 250 * intensity
        emitter.particleSpeedRange = 120 * intensity
        
        // Full 360 spread for explosion
        emitter.emissionAngle = 0
        emitter.emissionAngleRange = .pi * 2
        
        // Size - small reflective shards
        emitter.particleScale = 0.25
        emitter.particleScaleRange = 0.15
        emitter.particleScaleSpeed = -0.1
        
        // Fast rotation for sparkling effect
        emitter.particleRotationRange = .pi * 2
        emitter.particleRotationSpeed = CGFloat.random(in: -8...8)
        
        // Color - icy blue/white glass
        emitter.particleColor = SKColor(red: 0.85, green: 0.92, blue: 1.0, alpha: 0.9)
        emitter.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [
                SKColor(red: 0.95, green: 0.98, blue: 1.0, alpha: 0.95),
                SKColor(red: 0.75, green: 0.88, blue: 0.98, alpha: 0.85),
                SKColor(red: 0.60, green: 0.78, blue: 0.92, alpha: 0.5)
            ],
            times: [0.0, 0.3, 1.0]
        )
        emitter.particleColorBlendFactor = 1.0
        
        // Alpha with sparkle effect
        emitter.particleAlpha = 0.9
        emitter.particleAlphaSpeed = -1.0
        
        // Blend mode for glass shine
        emitter.particleBlendMode = .add
        
        return emitter
    }
    
    /// Creates dust cloud particles for earthquake atmosphere
    /// - Parameters:
    ///   - position: The origin point of the dust
    ///   - intensity: The intensity of the dust cloud (0.0 - 1.0)
    ///   - isContinuous: Whether the dust emits continuously or bursts
    /// - Returns: A configured SKEmitterNode with dust cloud effect
    static func dustCloud(at position: CGPoint, intensity: CGFloat = 0.5, isContinuous: Bool = false) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.position = position
        emitter.zPosition = 15
        
        // Texture - soft dust particle
        emitter.particleTexture = createDustParticleTexture()
        
        // Birth rate
        if isContinuous {
            emitter.particleBirthRate = 30 * intensity
            emitter.numParticlesToEmit = 0 // Continuous
        } else {
            emitter.particleBirthRate = 100 * intensity
            emitter.numParticlesToEmit = Int(50 * intensity)
        }
        
        // Long lifetime for lingering dust
        emitter.particleLifetime = 3.0
        emitter.particleLifetimeRange = 1.0
        
        // Physics - slow floating dust
        emitter.yAcceleration = -50
        emitter.particleSpeed = 30 * intensity
        emitter.particleSpeedRange = 20 * intensity
        
        // Wide spread
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi
        
        // Large soft particles
        emitter.particleScale = 0.8
        emitter.particleScaleRange = 0.5
        emitter.particleScaleSpeed = 0.3 // Grow over time
        
        // Slow rotation
        emitter.particleRotationRange = .pi * 2
        emitter.particleRotationSpeed = CGFloat.random(in: -0.5...0.5)
        
        // Earthy dust colors
        emitter.particleColor = SKColor(red: 0.75, green: 0.70, blue: 0.65, alpha: 0.6)
        emitter.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [
                SKColor(red: 0.85, green: 0.82, blue: 0.78, alpha: 0.4),
                SKColor(red: 0.70, green: 0.65, blue: 0.60, alpha: 0.5),
                SKColor(red: 0.55, green: 0.52, blue: 0.48, alpha: 0.3)
            ],
            times: [0.0, 0.5, 1.0]
        )
        emitter.particleColorBlendFactor = 1.0
        
        // Slow fade
        emitter.particleAlpha = 0.5
        emitter.particleAlphaSpeed = -0.15
        
        // Blend mode for soft look
        emitter.particleBlendMode = .alpha
        
        return emitter
    }
    
    /// Creates electrical sparks for hazards
    /// - Parameters:
    ///   - position: The origin point of the sparks
    ///   - intensity: The intensity of the sparking (0.0 - 1.0)
    /// - Returns: A configured SKEmitterNode with electrical spark effect
    static func electricalSparks(at position: CGPoint, intensity: CGFloat = 0.8) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.position = position
        emitter.zPosition = 25
        
        // Texture - small bright dot
        emitter.particleTexture = createSparkTexture()
        
        // Rapid birth rate
        emitter.particleBirthRate = 200 * intensity
        emitter.numParticlesToEmit = Int(40 * intensity)
        
        // Short lifetime for sparks
        emitter.particleLifetime = 0.4
        emitter.particleLifetimeRange = 0.2
        
        // Physics - sparks fly upward and outward
        emitter.yAcceleration = -100
        emitter.particleSpeed = 180 * intensity
        emitter.particleSpeedRange = 100 * intensity
        
        // Upward spread
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi / 2
        
        // Small spark size
        emitter.particleScale = 0.35
        emitter.particleScaleRange = 0.2
        emitter.particleScaleSpeed = -0.4
        
        // Fast random rotation
        emitter.particleRotationRange = .pi * 2
        emitter.particleRotationSpeed = CGFloat.random(in: -10...10)
        
        // Electric colors - yellow to orange to red
        emitter.particleColor = SKColor(red: 1.0, green: 0.9, blue: 0.2, alpha: 1.0)
        emitter.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [
                SKColor(red: 1.0, green: 1.0, blue: 0.8, alpha: 1.0),  // White-yellow
                SKColor(red: 1.0, green: 0.85, blue: 0.1, alpha: 1.0), // Yellow
                SKColor(red: 1.0, green: 0.5, blue: 0.1, alpha: 0.9),  // Orange
                SKColor(red: 0.9, green: 0.2, blue: 0.1, alpha: 0.5)   // Red fade
            ],
            times: [0.0, 0.2, 0.5, 1.0]
        )
        emitter.particleColorBlendFactor = 1.0
        
        // Bright to fade
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -2.0
        
        // Additive blend for glow effect
        emitter.particleBlendMode = .add
        
        return emitter
    }
    
    /// Creates water spray particles for burst pipes
    /// - Parameters:
    ///   - position: The origin point of the spray
    ///   - direction: The angle of spray (default: upward)
    ///   - intensity: The intensity of the spray (0.0 - 1.0)
    /// - Returns: A configured SKEmitterNode with water spray effect
    static func waterSpray(at position: CGPoint, direction: CGFloat = .pi / 2, intensity: CGFloat = 0.6) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.position = position
        emitter.zPosition = 18
        
        // Texture - water droplet
        emitter.particleTexture = createWaterDropletTexture()
        
        // Continuous spray
        emitter.particleBirthRate = 150 * intensity
        
        // Water droplet lifetime
        emitter.particleLifetime = 1.0
        emitter.particleLifetimeRange = 0.3
        
        // Physics - water arc
        emitter.yAcceleration = -500
        emitter.particleSpeed = 200 * intensity
        emitter.particleSpeedRange = 80 * intensity
        
        // Directional spray
        emitter.emissionAngle = direction
        emitter.emissionAngleRange = .pi / 6
        
        // Droplet size
        emitter.particleScale = 0.3
        emitter.particleScaleRange = 0.2
        emitter.particleScaleSpeed = -0.1
        
        // Slight rotation
        emitter.particleRotationRange = .pi
        emitter.particleRotationSpeed = CGFloat.random(in: -2...2)
        
        // Water colors
        emitter.particleColor = SKColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 0.8)
        emitter.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [
                SKColor(red: 0.85, green: 0.95, blue: 1.0, alpha: 0.9),
                SKColor(red: 0.60, green: 0.80, blue: 0.95, alpha: 0.7),
                SKColor(red: 0.40, green: 0.60, blue: 0.80, alpha: 0.3)
            ],
            times: [0.0, 0.5, 1.0]
        )
        emitter.particleColorBlendFactor = 1.0
        
        // Fade out
        emitter.particleAlpha = 0.8
        emitter.particleAlphaSpeed = -0.6
        
        // Blend mode
        emitter.particleBlendMode = .alpha
        
        return emitter
    }
    
    // MARK: - Environmental Effects
    
    /// Creates a gentle dust settling effect after earthquake ends
    /// Particles drift down from ceiling with very slow, organic movement
    /// - Parameters:
    ///   - duration: How long the dust emission lasts (default: 3.0 seconds)
    ///   - intensity: The density of dust particles (0.0 - 1.0)
    /// - Returns: A configured SKEmitterNode with settling dust effect
    static func settlingDust(duration: TimeInterval = 3.0, intensity: CGFloat = 0.6) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.zPosition = 25

        // Position at ceiling height, spanning full width
        emitter.particlePosition = CGPoint(x: 0, y: 380)
        emitter.particlePositionRange = CGVector(dx: 450, dy: 20)

        // Texture - very fine dust particle
        emitter.particleTexture = createUltraFineDustTexture()

        // Gentle emission over time
        emitter.particleBirthRate = 40 * intensity
        emitter.numParticlesToEmit = Int(duration * 40 * intensity)

        // Very long lifetime for lingering atmosphere
        emitter.particleLifetime = 6.0
        emitter.particleLifetimeRange = 2.0

        // Physics - ultra slow drift like real settling dust
        emitter.yAcceleration = -20
        emitter.particleSpeed = 15
        emitter.particleSpeedRange = 10

        // Slight downward drift with wide spread
        emitter.emissionAngle = -.pi / 2
        emitter.emissionAngleRange = .pi / 3

        // Tiny particles that grow slightly as they catch light
        emitter.particleScale = 0.15
        emitter.particleScaleRange = 0.1
        emitter.particleScaleSpeed = 0.05

        // Gentle drift rotation
        emitter.particleRotationRange = .pi * 2
        emitter.particleRotationSpeed = 0.2

        // Soft gray-beige dust colors with low alpha for subtlety
        emitter.particleColor = SKColor(red: 0.82, green: 0.78, blue: 0.72, alpha: 0.25)
        emitter.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [
                SKColor(red: 0.88, green: 0.85, blue: 0.80, alpha: 0.20),
                SKColor(red: 0.78, green: 0.74, blue: 0.68, alpha: 0.30),
                SKColor(red: 0.68, green: 0.64, blue: 0.58, alpha: 0.15),
                SKColor(red: 0.60, green: 0.56, blue: 0.50, alpha: 0.0)
            ],
            times: [0.0, 0.3, 0.7, 1.0]
        )
        emitter.particleColorBlendFactor = 1.0

        // Very slow fade for lingering effect
        emitter.particleAlpha = 0.25
        emitter.particleAlphaSpeed = -0.04

        emitter.particleBlendMode = .alpha

        return emitter
    }

    /// Creates screen shake dust that falls from ceiling during intense shaking
    /// - Parameters:
    ///   - intensity: The intensity of the shake (0.0 - 1.0)
    /// - Returns: A configured SKEmitterNode with falling dust effect
    static func screenShakeDust(intensity: CGFloat = 0.5) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.zPosition = 30
        
        // Texture
        emitter.particleTexture = createFineDustTexture()
        
        // Continuous emission during shake
        emitter.particleBirthRate = 50 * intensity
        
        // Lifetime
        emitter.particleLifetime = 2.5
        emitter.particleLifetimeRange = 0.8
        
        // Physics - settling dust
        emitter.yAcceleration = -80
        emitter.particleSpeed = 40 * intensity
        emitter.particleSpeedRange = 25 * intensity
        
        // Downward with slight spread
        emitter.emissionAngle = -.pi / 2
        emitter.emissionAngleRange = .pi / 4
        
        // Position at top of screen
        emitter.particlePositionRange = CGVector(dx: 400, dy: 10)
        
        // Small particles
        emitter.particleScale = 0.25
        emitter.particleScaleRange = 0.15
        emitter.particleScaleSpeed = 0.1
        
        // Minimal rotation
        emitter.particleRotationRange = .pi
        emitter.particleRotationSpeed = 0.5
        
        // Gray plaster dust
        emitter.particleColor = SKColor(white: 0.85, alpha: 0.5)
        emitter.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [
                SKColor(white: 0.92, alpha: 0.4),
                SKColor(white: 0.78, alpha: 0.35),
                SKColor(white: 0.65, alpha: 0.2)
            ],
            times: [0.0, 0.5, 1.0]
        )
        emitter.particleColorBlendFactor = 1.0
        
        // Fade
        emitter.particleAlpha = 0.4
        emitter.particleAlphaSpeed = -0.12
        
        emitter.particleBlendMode = .alpha
        
        return emitter
    }
    
    /// Creates falling plaster chunks from ceiling/ walls
    /// - Parameters:
    ///   - position: The origin point
    ///   - intensity: The intensity (0.0 - 1.0)
    /// - Returns: A configured SKEmitterNode with falling plaster effect
    static func fallingPlaster(at position: CGPoint, intensity: CGFloat = 0.4) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.position = position
        emitter.zPosition = 19
        
        // Texture - small plaster chunk
        emitter.particleTexture = createPlasterChunkTexture()
        
        // Burst emission
        emitter.particleBirthRate = 60 * intensity
        emitter.numParticlesToEmit = Int(15 * intensity)
        
        // Lifetime
        emitter.particleLifetime = 1.5
        emitter.particleLifetimeRange = 0.5
        
        // Physics - falling chunks
        emitter.yAcceleration = -450
        emitter.particleSpeed = 100 * intensity
        emitter.particleSpeedRange = 50 * intensity
        
        // Downward spread
        emitter.emissionAngle = -.pi / 2
        emitter.emissionAngleRange = .pi / 3
        
        // Chunk sizes
        emitter.particleScale = 0.35
        emitter.particleScaleRange = 0.25
        emitter.particleScaleSpeed = -0.08
        
        // Tumbling
        emitter.particleRotationRange = .pi * 2
        emitter.particleRotationSpeed = CGFloat.random(in: -3...3)
        
        // White/gray plaster colors
        emitter.particleColor = SKColor(white: 0.95, alpha: 1.0)
        emitter.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [
                SKColor(white: 1.0, alpha: 1.0),
                SKColor(white: 0.88, alpha: 0.9),
                SKColor(white: 0.75, alpha: 0.6)
            ],
            times: [0.0, 0.4, 1.0]
        )
        emitter.particleColorBlendFactor = 0.9
        
        // Fade
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -0.5
        
        emitter.particleBlendMode = .alpha
        
        return emitter
    }
    
    /// Creates smoke particles for electrical fires
    /// - Parameters:
    ///   - position: The origin point of the smoke
    ///   - intensity: The intensity of the smoke (0.0 - 1.0)
    /// - Returns: A configured SKEmitterNode with smoke effect
    static func electricalSmoke(at position: CGPoint, intensity: CGFloat = 0.5) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.position = position
        emitter.zPosition = 24
        
        // Texture - soft smoke
        emitter.particleTexture = createSmokeTexture()
        
        // Continuous emission
        emitter.particleBirthRate = 40 * intensity
        
        // Long lifetime for smoke
        emitter.particleLifetime = 4.0
        emitter.particleLifetimeRange = 1.0
        
        // Physics - smoke rises and spreads
        emitter.yAcceleration = 30
        emitter.particleSpeed = 50 * intensity
        emitter.particleSpeedRange = 25 * intensity
        
        // Upward drift with spread
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi / 3
        
        // Smoke expands
        emitter.particleScale = 0.5
        emitter.particleScaleRange = 0.3
        emitter.particleScaleSpeed = 0.4
        
        // Slow tumbling
        emitter.particleRotationRange = .pi * 2
        emitter.particleRotationSpeed = CGFloat.random(in: -1...1)
        
        // Gray/black smoke colors
        emitter.particleColor = SKColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 0.6)
        emitter.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [
                SKColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 0.5),
                SKColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.4),
                SKColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 0.2)
            ],
            times: [0.0, 0.5, 1.0]
        )
        emitter.particleColorBlendFactor = 1.0
        
        // Fade
        emitter.particleAlpha = 0.5
        emitter.particleAlphaSpeed = -0.1
        
        emitter.particleBlendMode = .alpha
        
        return emitter
    }
    
    /// Creates steam particles from broken pipes
    /// - Parameters:
    ///   - position: The origin point of the steam
    ///   - intensity: The intensity of the steam (0.0 - 1.0)
    /// - Returns: A configured SKEmitterNode with steam effect
    static func pipeSteam(at position: CGPoint, intensity: CGFloat = 0.5) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.position = position
        emitter.zPosition = 16
        
        // Texture - soft steam
        emitter.particleTexture = createSteamTexture()
        
        // Continuous emission
        emitter.particleBirthRate = 60 * intensity
        
        // Steam lifetime
        emitter.particleLifetime = 3.5
        emitter.particleLifetimeRange = 0.8
        
        // Physics - steam rises faster
        emitter.yAcceleration = 80
        emitter.particleSpeed = 80 * intensity
        emitter.particleSpeedRange = 30 * intensity
        
        // Upward spread
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi / 4
        
        // Steam expands as it rises
        emitter.particleScale = 0.6
        emitter.particleScaleRange = 0.3
        emitter.particleScaleSpeed = 0.5
        
        // Gentle rotation
        emitter.particleRotationRange = .pi
        emitter.particleRotationSpeed = CGFloat.random(in: -0.8...0.8)
        
        // White steam colors
        emitter.particleColor = SKColor(white: 0.95, alpha: 0.5)
        emitter.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [
                SKColor(white: 1.0, alpha: 0.4),
                SKColor(white: 0.92, alpha: 0.35),
                SKColor(white: 0.85, alpha: 0.2)
            ],
            times: [0.0, 0.5, 1.0]
        )
        emitter.particleColorBlendFactor = 1.0
        
        // Gentle fade
        emitter.particleAlpha = 0.4
        emitter.particleAlphaSpeed = -0.1
        
        emitter.particleBlendMode = .screen
        
        return emitter
    }
    
    // MARK: - Interactive Particles
    
    /// Creates footstep dust when player runs
    /// - Parameters:
    ///   - position: The foot position
    ///   - direction: The facing direction (1 for right, -1 for left)
    /// - Returns: A configured SKEmitterNode with footstep dust effect
    static func footstepDust(at position: CGPoint, direction: CGFloat = 1) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        // Offset slightly behind foot
        emitter.position = CGPoint(x: position.x - (direction * 10), y: position.y - 5)
        emitter.zPosition = 12
        
        // Texture
        emitter.particleTexture = createDustParticleTexture()
        
        // Quick burst
        emitter.particleBirthRate = 100
        emitter.numParticlesToEmit = 8
        
        // Short lifetime
        emitter.particleLifetime = 0.4
        emitter.particleLifetimeRange = 0.15
        
        // Physics - small puff
        emitter.yAcceleration = -50
        emitter.particleSpeed = 30
        emitter.particleSpeedRange = 15
        
        // Spread behind foot
        emitter.emissionAngle = direction > 0 ? .pi : 0
        emitter.emissionAngleRange = .pi / 4
        
        // Small puff size
        emitter.particleScale = 0.25
        emitter.particleScaleRange = 0.15
        emitter.particleScaleSpeed = 0.2
        
        // Minimal rotation
        emitter.particleRotationRange = .pi
        emitter.particleRotationSpeed = 0
        
        // Light dust color
        emitter.particleColor = SKColor(red: 0.85, green: 0.82, blue: 0.78, alpha: 0.5)
        emitter.particleColorBlendFactor = 1.0
        
        // Fade
        emitter.particleAlpha = 0.5
        emitter.particleAlphaSpeed = -1.0
        
        emitter.particleBlendMode = .alpha
        
        return emitter
    }
    
    /// Creates impact particles when objects hit the ground
    /// - Parameters:
    ///   - position: The impact position
    ///   - material: The material type of the impacting object
    ///   - intensity: The impact intensity (0.0 - 1.0)
    /// - Returns: A configured SKEmitterNode with impact effect
    static func impactParticles(at position: CGPoint, material: MaterialType, intensity: CGFloat = 0.5) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.position = position
        emitter.zPosition = 21
        
        // Configure based on material
        switch material {
        case .wood:
            return woodDebris(at: position, intensity: intensity)
        case .glass:
            return glassShards(at: position, intensity: intensity)
        case .metal:
            return metalImpactSparks(at: position, intensity: intensity)
        case .ceramic:
            return ceramicShards(at: position, intensity: intensity)
        case .fabric, .paper:
            return paperDebris(at: position, intensity: intensity)
        }
    }
    
    /// Creates sparkle particles for correct player decisions
    /// - Parameters:
    ///   - position: The position to show sparkles
    ///   - count: Number of sparkles (default: 12)
    /// - Returns: A configured SKEmitterNode with sparkle effect
    static func correctDecisionSparkles(at position: CGPoint, count: Int = 12) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.position = position
        emitter.zPosition = 50
        
        // Texture - star sparkle
        emitter.particleTexture = createStarSparkleTexture()
        
        // Burst of sparkles
        emitter.particleBirthRate = 150
        emitter.numParticlesToEmit = count
        
        // Sparkle lifetime
        emitter.particleLifetime = 0.8
        emitter.particleLifetimeRange = 0.3
        
        // Physics - sparkles fly outward
        emitter.yAcceleration = -100
        emitter.particleSpeed = 100
        emitter.particleSpeedRange = 40
        
        // 360 spread
        emitter.emissionAngle = 0
        emitter.emissionAngleRange = .pi * 2
        
        // Sparkle size
        emitter.particleScale = 0.5
        emitter.particleScaleRange = 0.3
        emitter.particleScaleSpeed = -0.3
        
        // Rotation
        emitter.particleRotationRange = .pi * 2
        emitter.particleRotationSpeed = CGFloat.random(in: -5...5)
        
        // Gold/green success colors
        emitter.particleColor = SKColor(red: 1.0, green: 0.9, blue: 0.2, alpha: 1.0)
        emitter.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [
                SKColor(red: 1.0, green: 1.0, blue: 0.6, alpha: 1.0),   // Bright yellow
                SKColor(red: 0.3, green: 0.9, blue: 0.4, alpha: 1.0),   // Green
                SKColor(red: 0.2, green: 0.7, blue: 1.0, alpha: 0.6),   // Blue fade
                SKColor(red: 0.5, green: 0.5, blue: 1.0, alpha: 0.0)    // Purple fade out
            ],
            times: [0.0, 0.3, 0.7, 1.0]
        )
        emitter.particleColorBlendFactor = 1.0
        
        // Bright to fade
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -1.2
        
        // Additive blend for glow
        emitter.particleBlendMode = .add
        
        return emitter
    }
    
    /// Creates celebration confetti for achievements
    /// - Parameters:
    ///   - position: The origin position
    ///   - intensity: The intensity of the celebration (0.0 - 1.0)
    /// - Returns: A configured SKEmitterNode with confetti effect
    static func celebrationConfetti(at position: CGPoint, intensity: CGFloat = 1.0) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.position = position
        emitter.zPosition = 100
        
        // Texture - confetti square
        emitter.particleTexture = createConfettiTexture()
        
        // Burst
        emitter.particleBirthRate = 200 * intensity
        emitter.numParticlesToEmit = Int(100 * intensity)
        
        // Lifetime
        emitter.particleLifetime = 2.5
        emitter.particleLifetimeRange = 0.8
        
        // Physics - confetti falls slowly with drift
        emitter.yAcceleration = -150
        emitter.particleSpeed = 200 * intensity
        emitter.particleSpeedRange = 100 * intensity
        
        // Upward burst
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi / 2
        
        // Size
        emitter.particleScale = 0.4
        emitter.particleScaleRange = 0.2
        emitter.particleScaleSpeed = 0
        
        // Tumbling confetti
        emitter.particleRotationRange = .pi * 2
        emitter.particleRotationSpeed = CGFloat.random(in: -8...8)
        
        // Multi-color sequence
        emitter.particleColor = SKColor.red
        emitter.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [
                SKColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0),   // Red
                SKColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 1.0),   // Green
                SKColor(red: 0.2, green: 0.4, blue: 1.0, alpha: 1.0),   // Blue
                SKColor(red: 1.0, green: 0.9, blue: 0.2, alpha: 1.0),   // Yellow
                SKColor(red: 1.0, green: 0.4, blue: 0.9, alpha: 1.0)    // Pink
            ],
            times: [0.0, 0.25, 0.5, 0.75, 1.0]
        )
        emitter.particleColorBlendFactor = 1.0
        
        // Fade
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -0.35
        
        emitter.particleBlendMode = .alpha
        
        return emitter
    }
    
    // MARK: - Private Helper Effects
    
    /// Metal impact sparks (used by impactParticles)
    private static func metalImpactSparks(at position: CGPoint, intensity: CGFloat) -> SKEmitterNode {
        let emitter = electricalSparks(at: position, intensity: intensity)
        emitter.particleBirthRate = 100 * intensity
        emitter.numParticlesToEmit = Int(20 * intensity)
        emitter.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [
                SKColor(white: 1.0, alpha: 1.0),
                SKColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 0.9),
                SKColor(red: 0.8, green: 0.3, blue: 0.1, alpha: 0.5)
            ],
            times: [0.0, 0.3, 1.0]
        )
        return emitter
    }
    
    /// Ceramic shards effect
    private static func ceramicShards(at position: CGPoint, intensity: CGFloat) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.position = position
        emitter.zPosition = 20
        
        emitter.particleTexture = createCeramicShardTexture()
        emitter.particleBirthRate = 120 * intensity
        emitter.numParticlesToEmit = Int(30 * intensity)
        
        emitter.particleLifetime = 0.9
        emitter.particleLifetimeRange = 0.3
        
        emitter.yAcceleration = -500
        emitter.particleSpeed = 130 * intensity
        emitter.particleSpeedRange = 70 * intensity
        
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi / 2
        
        emitter.particleScale = 0.3
        emitter.particleScaleRange = 0.2
        emitter.particleScaleSpeed = -0.1
        
        emitter.particleRotationRange = .pi * 2
        emitter.particleRotationSpeed = CGFloat.random(in: -5...5)
        
        // Terracotta colors
        emitter.particleColor = SKColor(red: 0.82, green: 0.42, blue: 0.22, alpha: 1.0)
        emitter.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [
                SKColor(red: 0.90, green: 0.50, blue: 0.30, alpha: 1.0),
                SKColor(red: 0.75, green: 0.40, blue: 0.20, alpha: 0.9),
                SKColor(red: 0.60, green: 0.32, blue: 0.15, alpha: 0.5)
            ],
            times: [0.0, 0.4, 1.0]
        )
        emitter.particleColorBlendFactor = 0.9
        
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -0.9
        emitter.particleBlendMode = .alpha
        
        return emitter
    }
    
    /// Paper debris effect
    private static func paperDebris(at position: CGPoint, intensity: CGFloat) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.position = position
        emitter.zPosition = 18
        
        emitter.particleTexture = createPaperBitTexture()
        emitter.particleBirthRate = 60 * intensity
        emitter.numParticlesToEmit = Int(25 * intensity)
        
        emitter.particleLifetime = 2.0
        emitter.particleLifetimeRange = 0.6
        
        // Paper flutters - less gravity
        emitter.yAcceleration = -100
        emitter.particleSpeed = 60 * intensity
        emitter.particleSpeedRange = 30 * intensity
        
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi / 1.5
        
        emitter.particleScale = 0.35
        emitter.particleScaleRange = 0.2
        emitter.particleScaleSpeed = 0
        
        // Paper tumbles slowly
        emitter.particleRotationRange = .pi * 2
        emitter.particleRotationSpeed = CGFloat.random(in: -2...2)
        
        // White paper colors
        emitter.particleColor = SKColor(white: 0.95, alpha: 1.0)
        emitter.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [
                SKColor(white: 1.0, alpha: 1.0),
                SKColor(white: 0.92, alpha: 0.9),
                SKColor(white: 0.85, alpha: 0.6)
            ],
            times: [0.0, 0.5, 1.0]
        )
        emitter.particleColorBlendFactor = 0.8
        
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -0.4
        emitter.particleBlendMode = .alpha
        
        return emitter
    }
    
    // MARK: - Texture Generation
    
    private static func createWoodChipTexture() -> SKTexture {
        let size = CGSize(width: 4, height: 4)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            let ctx = context.cgContext
            // Wood chip shape
            ctx.setFillColor(UIColor(red: 0.55, green: 0.38, blue: 0.22, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: 0, y: 1, width: 4, height: 2))
            ctx.fill(CGRect(x: 1, y: 0, width: 2, height: 4))
        }
        
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }
    
    private static func createGlassShardTexture() -> SKTexture {
        let size = CGSize(width: 4, height: 6)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            let ctx = context.cgContext
            // Diamond shard shape
            ctx.setFillColor(UIColor(red: 0.85, green: 0.92, blue: 1.0, alpha: 0.9).cgColor)
            ctx.fill(CGRect(x: 1, y: 0, width: 2, height: 1))
            ctx.fill(CGRect(x: 0, y: 1, width: 4, height: 4))
            ctx.fill(CGRect(x: 1, y: 5, width: 2, height: 1))
        }
        
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }
    
    private static func createDustParticleTexture() -> SKTexture {
        let size = CGSize(width: 8, height: 8)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            let ctx = context.cgContext
            // Soft circular dust
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor(white: 0.9, alpha: 0.6).cgColor,
                    UIColor(white: 0.8, alpha: 0.3).cgColor,
                    UIColor(white: 0.7, alpha: 0.0).cgColor
                ] as CFArray,
                locations: [0.0, 0.5, 1.0]
            )!
            ctx.drawRadialGradient(
                gradient,
                startCenter: CGPoint(x: 4, y: 4),
                startRadius: 0,
                endCenter: CGPoint(x: 4, y: 4),
                endRadius: 4,
                options: []
            )
        }
        
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }
    
    private static func createFineDustTexture() -> SKTexture {
        let size = CGSize(width: 4, height: 4)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            let ctx = context.cgContext
            ctx.setFillColor(UIColor(white: 0.9, alpha: 0.5).cgColor)
            ctx.fillEllipse(in: CGRect(x: 0, y: 0, width: 4, height: 4))
        }
        
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }
    
    private static func createSparkTexture() -> SKTexture {
        let size = CGSize(width: 4, height: 4)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            let ctx = context.cgContext
            // Bright spark center
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor(white: 1.0, alpha: 1.0).cgColor,
                    UIColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 0.8).cgColor,
                    UIColor(red: 1.0, green: 0.6, blue: 0.1, alpha: 0.0).cgColor
                ] as CFArray,
                locations: [0.0, 0.4, 1.0]
            )!
            ctx.drawRadialGradient(
                gradient,
                startCenter: CGPoint(x: 2, y: 2),
                startRadius: 0,
                endCenter: CGPoint(x: 2, y: 2),
                endRadius: 2,
                options: []
            )
        }
        
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }
    
    private static func createWaterDropletTexture() -> SKTexture {
        let size = CGSize(width: 4, height: 6)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            let ctx = context.cgContext
            // Teardrop shape
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor(red: 0.85, green: 0.95, blue: 1.0, alpha: 0.9).cgColor,
                    UIColor(red: 0.60, green: 0.80, blue: 0.95, alpha: 0.7).cgColor,
                    UIColor(red: 0.40, green: 0.60, blue: 0.80, alpha: 0.0).cgColor
                ] as CFArray,
                locations: [0.0, 0.5, 1.0]
            )!
            ctx.drawRadialGradient(
                gradient,
                startCenter: CGPoint(x: 2, y: 3),
                startRadius: 0,
                endCenter: CGPoint(x: 2, y: 3),
                endRadius: 3,
                options: []
            )
        }
        
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }
    
    private static func createPlasterChunkTexture() -> SKTexture {
        let size = CGSize(width: 4, height: 4)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            let ctx = context.cgContext
            // Irregular chunk
            ctx.setFillColor(UIColor(white: 0.95, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: 0, y: 1, width: 4, height: 2))
            ctx.fill(CGRect(x: 1, y: 0, width: 2, height: 4))
        }
        
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }
    
    private static func createSmokeTexture() -> SKTexture {
        let size = CGSize(width: 12, height: 12)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            let ctx = context.cgContext
            // Soft smoke cloud
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor(white: 0.4, alpha: 0.5).cgColor,
                    UIColor(white: 0.5, alpha: 0.3).cgColor,
                    UIColor(white: 0.6, alpha: 0.0).cgColor
                ] as CFArray,
                locations: [0.0, 0.5, 1.0]
            )!
            ctx.drawRadialGradient(
                gradient,
                startCenter: CGPoint(x: 6, y: 6),
                startRadius: 0,
                endCenter: CGPoint(x: 6, y: 6),
                endRadius: 6,
                options: []
            )
        }
        
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }
    
    private static func createSteamTexture() -> SKTexture {
        let size = CGSize(width: 10, height: 10)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            let ctx = context.cgContext
            // Soft steam
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor(white: 1.0, alpha: 0.4).cgColor,
                    UIColor(white: 0.95, alpha: 0.2).cgColor,
                    UIColor(white: 0.9, alpha: 0.0).cgColor
                ] as CFArray,
                locations: [0.0, 0.5, 1.0]
            )!
            ctx.drawRadialGradient(
                gradient,
                startCenter: CGPoint(x: 5, y: 5),
                startRadius: 0,
                endCenter: CGPoint(x: 5, y: 5),
                endRadius: 5,
                options: []
            )
        }
        
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }
    
    private static func createStarSparkleTexture() -> SKTexture {
        let size = CGSize(width: 8, height: 8)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            let ctx = context.cgContext
            // 4-pointed star
            ctx.setFillColor(UIColor(white: 1.0, alpha: 1.0).cgColor)
            
            // Vertical bar
            ctx.fill(CGRect(x: 3, y: 0, width: 2, height: 8))
            // Horizontal bar
            ctx.fill(CGRect(x: 0, y: 3, width: 8, height: 2))
        }
        
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }
    
    private static func createConfettiTexture() -> SKTexture {
        let size = CGSize(width: 6, height: 6)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            let ctx = context.cgContext
            // Square confetti
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.fill(CGRect(x: 1, y: 1, width: 4, height: 4))
        }
        
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }
    
    private static func createCeramicShardTexture() -> SKTexture {
        let size = CGSize(width: 4, height: 4)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            let ctx = context.cgContext
            // Ceramic shard
            ctx.setFillColor(UIColor(red: 0.82, green: 0.42, blue: 0.22, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: 1, y: 0, width: 2, height: 4))
            ctx.fill(CGRect(x: 0, y: 1, width: 4, height: 2))
        }
        
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }
    
    private static func createPaperBitTexture() -> SKTexture {
        let size = CGSize(width: 4, height: 5)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            let ctx = context.cgContext
            // Paper rectangle
            ctx.setFillColor(UIColor(white: 0.95, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: 4, height: 5))
        }

        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }

    private static func createUltraFineDustTexture() -> SKTexture {
        let size = CGSize(width: 6, height: 6)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            let ctx = context.cgContext
            // Ultra soft, almost invisible dust mote
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor(white: 0.92, alpha: 0.35).cgColor,
                    UIColor(white: 0.85, alpha: 0.20).cgColor,
                    UIColor(white: 0.75, alpha: 0.0).cgColor
                ] as CFArray,
                locations: [0.0, 0.4, 1.0]
            )!
            ctx.drawRadialGradient(
                gradient,
                startCenter: CGPoint(x: 3, y: 3),
                startRadius: 0,
                endCenter: CGPoint(x: 3, y: 3),
                endRadius: 3,
                options: []
            )
        }

        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }

    // MARK: - Medical/Healing Particle Effects

    /// Creates healing sparkles for medical treatment effects
    /// - Parameters:
    ///   - position: The origin point of the sparkles
    ///   - intensity: The intensity of the effect (0.0 - 1.0)
    /// - Returns: A configured SKEmitterNode with healing sparkle effect
    static func healingSparkles(at position: CGPoint, intensity: CGFloat = 0.7) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.position = position
        emitter.zPosition = 40

        // Texture - soft glow particle
        emitter.particleTexture = createHealingSparkleTexture()

        // Gentle birth rate
        emitter.particleBirthRate = 40 * intensity
        emitter.numParticlesToEmit = Int(30 * intensity)

        // Medium lifetime
        emitter.particleLifetime = 1.5
        emitter.particleLifetimeRange = 0.5

        // Physics - float upward slowly
        emitter.yAcceleration = -30
        emitter.particleSpeed = 40 * intensity
        emitter.particleSpeedRange = 20 * intensity

        // Upward spread
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi / 3

        // Size with gentle pulse
        emitter.particleScale = 0.4
        emitter.particleScaleRange = 0.2
        emitter.particleScaleSpeed = 0.1

        // Slow rotation
        emitter.particleRotationRange = .pi * 2
        emitter.particleRotationSpeed = CGFloat.random(in: -1...1)

        // Healing green/white colors
        emitter.particleColor = SKColor(red: 0.4, green: 0.95, blue: 0.5, alpha: 0.8)
        emitter.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [
                SKColor(red: 0.6, green: 1.0, blue: 0.7, alpha: 0.9),
                SKColor(red: 0.3, green: 0.9, blue: 0.4, alpha: 0.7),
                SKColor(red: 0.9, green: 1.0, blue: 0.95, alpha: 0.4),
                SKColor(red: 0.8, green: 1.0, blue: 0.9, alpha: 0.0)
            ],
            times: [0.0, 0.3, 0.7, 1.0]
        )
        emitter.particleColorBlendFactor = 1.0

        // Alpha fade
        emitter.particleAlpha = 0.8
        emitter.particleAlphaSpeed = -0.4

        // Additive blend for glow
        emitter.particleBlendMode = .add

        return emitter
    }

    /// Creates water splash particles for wound cleaning
    /// - Parameters:
    ///   - position: The origin point of the splash
    ///   - intensity: The intensity of the splash (0.0 - 1.0)
    /// - Returns: A configured SKEmitterNode with water splash effect
    static func waterSplash(at position: CGPoint, intensity: CGFloat = 0.6) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.position = position
        emitter.zPosition = 35

        // Texture - water droplet
        emitter.particleTexture = createWaterSplashTexture()

        // Burst emission
        emitter.particleBirthRate = 200 * intensity
        emitter.numParticlesToEmit = Int(25 * intensity)

        // Short lifetime - splashes fade quickly
        emitter.particleLifetime = 0.6
        emitter.particleLifetimeRange = 0.2

        // Physics - splash outward then drip
        emitter.yAcceleration = -400
        emitter.particleSpeed = 150 * intensity
        emitter.particleSpeedRange = 80 * intensity

        // 360 spread for splash
        emitter.emissionAngle = 0
        emitter.emissionAngleRange = .pi * 2

        // Droplet sizes
        emitter.particleScale = 0.25
        emitter.particleScaleRange = 0.15
        emitter.particleScaleSpeed = -0.2

        // Rotation
        emitter.particleRotationRange = .pi * 2
        emitter.particleRotationSpeed = CGFloat.random(in: -5...5)

        // Water blue colors
        emitter.particleColor = SKColor(red: 0.4, green: 0.75, blue: 1.0, alpha: 0.9)
        emitter.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [
                SKColor(red: 0.7, green: 0.9, blue: 1.0, alpha: 0.95),
                SKColor(red: 0.4, green: 0.75, blue: 1.0, alpha: 0.8),
                SKColor(red: 0.2, green: 0.5, blue: 0.8, alpha: 0.3)
            ],
            times: [0.0, 0.3, 1.0]
        )
        emitter.particleColorBlendFactor = 1.0

        // Quick fade
        emitter.particleAlpha = 0.9
        emitter.particleAlphaSpeed = -1.5

        // Additive blend for wet look
        emitter.particleBlendMode = .add

        return emitter
    }

    /// Creates bandage wrap particles for bandaging step
    /// - Parameters:
    ///   - position: The origin point
    ///   - direction: The direction of wrap (1 for right, -1 for left)
    /// - Returns: A configured SKEmitterNode with bandage wrap effect
    static func bandageWrap(at position: CGPoint, direction: CGFloat = 1) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.position = position
        emitter.zPosition = 38

        // Texture - fabric strip
        emitter.particleTexture = createBandageTexture()

        // Continuous emission during wrap
        emitter.particleBirthRate = 80
        emitter.numParticlesToEmit = 15

        // Medium lifetime
        emitter.particleLifetime = 0.8
        emitter.particleLifetimeRange = 0.2

        // Physics - wrap around wound
        emitter.yAcceleration = -50
        emitter.particleSpeed = 60
        emitter.particleSpeedRange = 30

        // Directional emission
        emitter.emissionAngle = direction > 0 ? 0 : .pi
        emitter.emissionAngleRange = .pi / 4

        // Fabric strip sizes
        emitter.particleScale = 0.3
        emitter.particleScaleRange = 0.1
        emitter.particleScaleSpeed = 0

        // Minimal rotation - fabric settles
        emitter.particleRotationRange = .pi / 4
        emitter.particleRotationSpeed = 0

        // Bandage beige colors
        emitter.particleColor = SKColor(red: 1.0, green: 0.95, blue: 0.85, alpha: 0.9)
        emitter.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [
                SKColor(red: 1.0, green: 0.98, blue: 0.92, alpha: 1.0),
                SKColor(red: 0.95, green: 0.9, blue: 0.8, alpha: 0.9),
                SKColor(red: 0.9, green: 0.85, blue: 0.75, alpha: 0.5)
            ],
            times: [0.0, 0.5, 1.0]
        )
        emitter.particleColorBlendFactor = 1.0

        // Fade
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -1.0

        emitter.particleBlendMode = .alpha

        return emitter
    }

    /// Creates heart particles for successful healing
    /// - Parameters:
    ///   - position: The origin point
    ///   - count: Number of hearts (default: 8)
    /// - Returns: A configured SKEmitterNode with heart burst effect
    static func healingHearts(at position: CGPoint, count: Int = 8) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.position = position
        emitter.zPosition = 50

        // Texture - heart shape
        emitter.particleTexture = createHeartTexture()

        // Burst
        emitter.particleBirthRate = 100
        emitter.numParticlesToEmit = count

        // Medium lifetime
        emitter.particleLifetime = 1.2
        emitter.particleLifetimeRange = 0.3

        // Physics - float upward and spread
        emitter.yAcceleration = -100
        emitter.particleSpeed = 80
        emitter.particleSpeedRange = 40

        // Upward spread
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi / 2

        // Heart sizes
        emitter.particleScale = 0.5
        emitter.particleScaleRange = 0.2
        emitter.particleScaleSpeed = -0.2

        // Gentle rotation
        emitter.particleRotationRange = .pi / 3
        emitter.particleRotationSpeed = CGFloat.random(in: -2...2)

        // Heart colors - red to pink
        emitter.particleColor = SKColor(red: 1.0, green: 0.2, blue: 0.3, alpha: 1.0)
        emitter.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [
                SKColor(red: 1.0, green: 0.15, blue: 0.2, alpha: 1.0),
                SKColor(red: 1.0, green: 0.4, blue: 0.5, alpha: 0.9),
                SKColor(red: 1.0, green: 0.6, blue: 0.7, alpha: 0.4)
            ],
            times: [0.0, 0.5, 1.0]
        )
        emitter.particleColorBlendFactor = 1.0

        // Fade
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -0.7

        emitter.particleBlendMode = .alpha

        return emitter
    }

    // MARK: - Medical Texture Generation

    private static func createHealingSparkleTexture() -> SKTexture {
        let size = CGSize(width: 8, height: 8)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            let ctx = context.cgContext
            // Soft glowing cross/star
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor(red: 0.8, green: 1.0, blue: 0.8, alpha: 1.0).cgColor,
                    UIColor(red: 0.4, green: 0.9, blue: 0.5, alpha: 0.6).cgColor,
                    UIColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 0.0).cgColor
                ] as CFArray,
                locations: [0.0, 0.5, 1.0]
            )!
            ctx.drawRadialGradient(
                gradient,
                startCenter: CGPoint(x: 4, y: 4),
                startRadius: 0,
                endCenter: CGPoint(x: 4, y: 4),
                endRadius: 4,
                options: []
            )
        }

        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }

    private static func createWaterSplashTexture() -> SKTexture {
        let size = CGSize(width: 5, height: 5)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            let ctx = context.cgContext
            // Round water droplet
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor(red: 0.8, green: 0.95, blue: 1.0, alpha: 0.95).cgColor,
                    UIColor(red: 0.4, green: 0.75, blue: 1.0, alpha: 0.6).cgColor,
                    UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 0.0).cgColor
                ] as CFArray,
                locations: [0.0, 0.5, 1.0]
            )!
            ctx.drawRadialGradient(
                gradient,
                startCenter: CGPoint(x: 2.5, y: 2.5),
                startRadius: 0,
                endCenter: CGPoint(x: 2.5, y: 2.5),
                endRadius: 2.5,
                options: []
            )
        }

        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }

    private static func createBandageTexture() -> SKTexture {
        let size = CGSize(width: 8, height: 4)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            let ctx = context.cgContext
            // Fabric strip
            ctx.setFillColor(UIColor(red: 1.0, green: 0.95, blue: 0.85, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: 8, height: 4))
            // Texture lines
            ctx.setFillColor(UIColor(red: 0.9, green: 0.85, blue: 0.75, alpha: 0.5).cgColor)
            ctx.fill(CGRect(x: 0, y: 1, width: 8, height: 1))
            ctx.fill(CGRect(x: 0, y: 3, width: 8, height: 1))
        }

        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }

    private static func createHeartTexture() -> SKTexture {
        let size = CGSize(width: 10, height: 10)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            let ctx = context.cgContext
            // Simple heart shape using two circles and triangle
            ctx.setFillColor(UIColor(red: 1.0, green: 0.2, blue: 0.3, alpha: 1.0).cgColor)

            // Left circle
            ctx.fillEllipse(in: CGRect(x: 0, y: 4, width: 5, height: 5))
            // Right circle
            ctx.fillEllipse(in: CGRect(x: 5, y: 4, width: 5, height: 5))
            // Bottom triangle
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: 7))
            path.addLine(to: CGPoint(x: 5, y: 0))
            path.addLine(to: CGPoint(x: 10, y: 7))
            path.closeSubpath()
            ctx.addPath(path)
            ctx.fillPath()
        }

        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }
}

