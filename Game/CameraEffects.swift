import SpriteKit
import CoreGraphics

// MARK: - Camera Effect Types

/// Types of directional shake emphasis
enum ShakeDirection {
    case horizontal
    case vertical
    case omni
    case custom(dx: CGFloat, dy: CGFloat)
    
    var vector: CGVector {
        switch self {
        case .horizontal:
            return CGVector(dx: 1.0, dy: 0.2)
        case .vertical:
            return CGVector(dx: 0.2, dy: 1.0)
        case .omni:
            return CGVector(dx: 1.0, dy: 1.0)
        case .custom(let dx, let dy):
            return CGVector(dx: dx, dy: dy)
        }
    }
}

/// Types of cinematic transitions
enum CinematicTransition {
    case zoomIn(target: CGPoint, scale: CGFloat, duration: TimeInterval)
    case zoomOut(duration: TimeInterval)
    case slowMotion(speed: CGFloat, duration: TimeInterval)
    case flash(color: UIColor, intensity: CGFloat, duration: TimeInterval)
    case shake(intensity: CGFloat, duration: TimeInterval)
    case fadeTo(color: UIColor, duration: TimeInterval)
}

/// Configuration for camera effects
struct CameraEffectConfig {
    var shakeIntensity: CGFloat = 1.0
    var shakeDirection: ShakeDirection = .omni
    var noiseOctaves: Int = 3
    var noisePersistence: CGFloat = 0.5
    var zoomShakeEnabled: Bool = true
    var motionBlurEnabled: Bool = true
    var chromaticAberrationEnabled: Bool = true
    var vignetteEnabled: Bool = true
    var recoveryDamping: CGFloat = 0.9
    var maxZoomOffset: CGFloat = 0.15
    var motionBlurThreshold: CGFloat = 0.6
}

// MARK: - Perlin Noise Generator

/// Simplex/Perlin noise generator for organic shake patterns
final class PerlinNoise {
    private var permutation: [Int]
    private let permutationSize = 256
    
    init(seed: Int = Int.random(in: 0...Int.max)) {
        // Initialize permutation table with seed
        var perm = Array(0..<permutationSize)
        var rng = SeededRandom(seed: seed)
        perm.shuffle(using: &rng)
        permutation = perm + perm // Double for overflow handling
    }
    
    /// Generate 1D Perlin noise
    func noise1D(_ x: CGFloat) -> CGFloat {
        let X = Int(floor(x)) & 255
        let xf = x - floor(x)
        
        let u = fade(xf)
        
        let a = permutation[X]
        let b = permutation[X + 1]
        
        return lerp(u, grad1D(a, xf), grad1D(b, xf - 1))
    }
    
    /// Generate 2D Perlin noise
    func noise2D(_ x: CGFloat, _ y: CGFloat) -> CGFloat {
        let X = Int(floor(x)) & 255
        let Y = Int(floor(y)) & 255
        
        let xf = x - floor(x)
        let yf = y - floor(y)
        
        let u = fade(xf)
        let v = fade(yf)
        
        let a = permutation[X] + Y
        let aa = permutation[a]
        let ab = permutation[a + 1]
        let b = permutation[X + 1] + Y
        let ba = permutation[b]
        let bb = permutation[b + 1]
        
        let x1 = lerp(u, grad2D(aa, xf, yf), grad2D(ba, xf - 1, yf))
        let x2 = lerp(u, grad2D(ab, xf, yf - 1), grad2D(bb, xf - 1, yf - 1))
        
        return lerp(v, x1, x2)
    }
    
    /// Generate fractal Brownian motion (FBM) for more detail
    func fbm2D(_ x: CGFloat, _ y: CGFloat, octaves: Int, persistence: CGFloat) -> CGFloat {
        var total: CGFloat = 0
        var frequency: CGFloat = 1
        var amplitude: CGFloat = 1
        var maxValue: CGFloat = 0
        
        for _ in 0..<octaves {
            total += noise2D(x * frequency, y * frequency) * amplitude
            maxValue += amplitude
            amplitude *= persistence
            frequency *= 2
        }
        
        return total / maxValue
    }
    
    // MARK: - Private Helpers
    
    private func fade(_ t: CGFloat) -> CGFloat {
        return t * t * t * (t * (t * 6 - 15) + 10)
    }
    
    private func lerp(_ t: CGFloat, _ a: CGFloat, _ b: CGFloat) -> CGFloat {
        return a + t * (b - a)
    }
    
    private func grad1D(_ hash: Int, _ x: CGFloat) -> CGFloat {
        return (hash & 1) == 0 ? x : -x
    }
    
    private func grad2D(_ hash: Int, _ x: CGFloat, _ y: CGFloat) -> CGFloat {
        let h = hash & 3
        let u = h < 2 ? x : y
        let v = h < 2 ? y : x
        return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v)
    }
}

// MARK: - Seeded Random Generator

struct SeededRandom: RandomNumberGenerator {
    private var state: UInt64
    
    init(seed: Int) {
        state = UInt64(bitPattern: Int64(seed))
    }
    
    mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
}

// MARK: - Visual Effect Nodes

/// Node that applies chromatic aberration effect
final class ChromaticAberrationNode: SKEffectNode {
    private let redChannel: SKSpriteNode
    private let greenChannel: SKSpriteNode
    private let blueChannel: SKSpriteNode
    private var intensity: CGFloat = 0.0
    
    init(size: CGSize) {
        // Create RGB channel sprites
        redChannel = SKSpriteNode(color: .red, size: size)
        greenChannel = SKSpriteNode(color: .green, size: size)
        blueChannel = SKSpriteNode(color: .blue, size: size)
        
        super.init()
        
        // Setup blend modes for channel separation
        redChannel.blendMode = .add
        greenChannel.blendMode = .add
        blueChannel.blendMode = .add
        
        redChannel.alpha = 0.33
        greenChannel.alpha = 0.33
        blueChannel.alpha = 0.33
        
        addChild(redChannel)
        addChild(greenChannel)
        addChild(blueChannel)
        
        self.shouldEnableEffects = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Update aberration intensity (0.0 - 1.0)
    func setIntensity(_ intensity: CGFloat, direction: CGVector = CGVector(dx: 1, dy: 0.5)) {
        self.intensity = intensity
        let maxOffset: CGFloat = 20.0 * intensity
        
        redChannel.position = CGPoint(
            x: -maxOffset * direction.dx,
            y: -maxOffset * direction.dy
        )
        blueChannel.position = CGPoint(
            x: maxOffset * direction.dx,
            y: maxOffset * direction.dy
        )
        greenChannel.position = .zero
        
        // Fade effect based on intensity
        self.alpha = intensity
    }
}

/// Motion blur trail effect node
final class MotionBlurNode: SKNode {
    private var trailSprites: [SKSpriteNode] = []
    private let trailCount = 5
    private var previousPositions: [CGPoint] = []
    private let maxTrailLength = 8
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Update motion blur based on velocity
    func update(velocity: CGVector, intensity: CGFloat) {
        guard intensity > 0.1 else {
            trailSprites.forEach { $0.removeFromParent() }
            trailSprites.removeAll()
            return
        }
        
        // Create trail sprites if needed
        while trailSprites.count < trailCount {
            let sprite = SKSpriteNode()
            sprite.alpha = 0
            addChild(sprite)
            trailSprites.append(sprite)
        }
        
        // Update trail positions with decreasing opacity
        for (i, sprite) in trailSprites.enumerated() {
            let progress = CGFloat(i) / CGFloat(trailCount)
            let offsetX = -velocity.dx * progress * 3.0 * intensity
            let offsetY = -velocity.dy * progress * 3.0 * intensity
            
            sprite.position = CGPoint(x: offsetX, y: offsetY)
            sprite.alpha = (1.0 - progress) * 0.3 * intensity
        }
    }
}

/// Vignette overlay effect
final class VignetteNode: SKShapeNode {
    private var currentIntensity: CGFloat = 0.0
    
    init(size: CGSize) {
        super.init()
        
        // Create radial gradient for vignette
        let rect = CGRect(origin: CGPoint(x: -size.width/2, y: -size.height/2), size: size)
        let path = CGPath(rect: rect, transform: nil)
        self.path = path
        
        self.fillColor = .black
        self.strokeColor = .clear
        self.alpha = 0.0
        self.blendMode = .multiply
        
        // Add radial gradient using inner shadow approach
        setupRadialVignette(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupRadialVignette(size: CGSize) {
        // Create gradient texture for vignette
        let gradientLayer = CAGradientLayer()
        gradientLayer.type = .radial
        gradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.3).cgColor,
            UIColor.black.withAlphaComponent(0.8).cgColor
        ]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        gradientLayer.frame = CGRect(origin: .zero, size: size)
        
        UIGraphicsBeginImageContext(size)
        gradientLayer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let cgImage = image?.cgImage {
            let texture = SKTexture(cgImage: cgImage)
            let sprite = SKSpriteNode(texture: texture, size: size)
            sprite.blendMode = .multiply
            sprite.name = "vignetteSprite"
            addChild(sprite)
        }
    }
    
    /// Set vignette intensity (0.0 - 1.0)
    func setIntensity(_ intensity: CGFloat, color: UIColor = .black) {
        currentIntensity = intensity
        self.alpha = intensity * 0.8
        
        // Update color if needed
        if intensity > 0 {
            if let sprite = childNode(withName: "vignetteSprite") as? SKSpriteNode {
                sprite.color = color
                sprite.colorBlendFactor = intensity * 0.5
            }
        }
    }
}

/// Screen flash effect node
final class FlashNode: SKShapeNode {
    init(size: CGSize) {
        super.init()
        
        let rect = CGRect(origin: CGPoint(x: -size.width/2, y: -size.height/2), size: size)
        self.path = CGPath(rect: rect, transform: nil)
        self.fillColor = .white
        self.strokeColor = .clear
        self.alpha = 0.0
        self.zPosition = 1000
        self.blendMode = .add
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Trigger flash animation
    func flash(color: UIColor = .white, intensity: CGFloat = 1.0, duration: TimeInterval = 0.3) {
        self.fillColor = color
        
        let fadeIn = SKAction.fadeAlpha(to: intensity, duration: duration * 0.2)
        let fadeOut = SKAction.fadeOut(withDuration: duration * 0.8)
        let sequence = SKAction.sequence([fadeIn, fadeOut])
        
        self.run(sequence)
    }
    
    /// Warning flash - pulses before danger
    func warningFlash(count: Int = 3, color: UIColor = .red) {
        self.fillColor = color
        
        var actions: [SKAction] = []
        for _ in 0..<count {
            actions.append(SKAction.fadeAlpha(to: 0.4, duration: 0.1))
            actions.append(SKAction.fadeOut(withDuration: 0.1))
            actions.append(SKAction.wait(forDuration: 0.1))
        }
        
        self.run(SKAction.sequence(actions))
    }
}

// MARK: - Camera Shake State

struct CameraShakeState {
    var position: CGPoint = .zero
    var rotation: CGFloat = 0.0
    var scale: CGFloat = 1.0
    var velocity: CGVector = .zero
    var angularVelocity: CGFloat = 0.0
    var shakeTime: TimeInterval = 0
    var recoveryProgress: CGFloat = 0.0
}

// MARK: - Camera Effects Controller

/// Advanced camera effects system for earthquake simulation
@MainActor
final class CameraEffectsController {
    
    // MARK: - Properties
    
    private weak var cameraNode: SKCameraNode?
    private weak var scene: SKScene?
    
    private var config = CameraEffectConfig()
    private var noise = PerlinNoise()
    
    // State
    private var shakeState = CameraShakeState()
    private var isShaking = false
    private var currentIntensity: CGFloat = 0.0
    private var targetIntensity: CGFloat = 0.0
    private var elapsedTime: TimeInterval = 0
    private var noiseOffset: CGFloat = 0
    
    // Effect nodes
    private var chromaticAberrationNode: ChromaticAberrationNode?
    private var motionBlurNode: MotionBlurNode?
    private var vignetteNode: VignetteNode?
    private var flashNode: FlashNode?
    
    // Cinematic state
    private var isInCinematic = false
    private var originalCameraPosition: CGPoint = .zero
    private var originalCameraScale: CGFloat = 1.0
    private var slowMotionFactor: CGFloat = 1.0
    
    // MARK: - Constants
    
    private struct Constants {
        static let maxShakeOffset: CGFloat = 50.0
        static let maxRotation: CGFloat = 0.15
        static let damping: CGFloat = 0.92
        static let recoverySpeed: CGFloat = 3.0
        static let noiseSpeed: CGFloat = 2.0
        static let zoomShakeAmount: CGFloat = 0.08
    }
    
    // MARK: - Initialization
    
    init(cameraNode: SKCameraNode, scene: SKScene, config: CameraEffectConfig = CameraEffectConfig()) {
        self.cameraNode = cameraNode
        self.scene = scene
        self.config = config
        
        self.originalCameraPosition = cameraNode.position
        self.originalCameraScale = cameraNode.xScale
        
        setupEffectNodes()
    }
    
    // MARK: - Setup
    
    private func setupEffectNodes() {
        guard let camera = cameraNode, let scene = scene else { return }
        
        let screenSize = scene.size
        
        // Setup chromatic aberration
        if config.chromaticAberrationEnabled {
            chromaticAberrationNode = ChromaticAberrationNode(size: screenSize)
            chromaticAberrationNode?.zPosition = 500
            chromaticAberrationNode?.alpha = 0
            camera.addChild(chromaticAberrationNode!)
        }
        
        // Setup motion blur
        if config.motionBlurEnabled {
            motionBlurNode = MotionBlurNode()
            motionBlurNode?.zPosition = 400
            camera.addChild(motionBlurNode!)
        }
        
        // Setup vignette
        if config.vignetteEnabled {
            vignetteNode = VignetteNode(size: CGSize(width: screenSize.width + 100, 
                                                      height: screenSize.height + 100))
            vignetteNode?.zPosition = 450
            vignetteNode?.name = "vignette"
            camera.addChild(vignetteNode!)
        }
        
        // Setup flash
        flashNode = FlashNode(size: CGSize(width: screenSize.width + 200, 
                                           height: screenSize.height + 200))
        flashNode?.zPosition = 1000
        camera.addChild(flashNode!)
    }
    
    // MARK: - Main Update
    
    func update(deltaTime: TimeInterval) {
        let dt = min(deltaTime, 0.1) * Double(slowMotionFactor)
        elapsedTime += dt
        
        // Smooth intensity transition
        currentIntensity = currentIntensity * 0.9 + targetIntensity * 0.1
        
        if isShaking && currentIntensity > 0.01 {
            updateShake(deltaTime: dt)
            updateVisualEffects()
        } else if shakeState.position != .zero || shakeState.rotation != 0 {
            // Recovery phase
            updateRecovery(deltaTime: dt)
        }
        
        applyCameraTransform()
    }
    
    // MARK: - Shake System
    
    private func updateShake(deltaTime: TimeInterval) {
        noiseOffset += CGFloat(deltaTime) * Constants.noiseSpeed
        
        // Calculate Perlin noise-based shake
        let direction = config.shakeDirection.vector
        let intensity = currentIntensity * config.shakeIntensity
        
        // Primary shake using FBM
        let noiseX = noise.fbm2D(
            noiseOffset,
            elapsedTime * 0.5,
            octaves: config.noiseOctaves,
            persistence: config.noisePersistence
        )
        let noiseY = noise.fbm2D(
            noiseOffset + 100,
            elapsedTime * 0.5,
            octaves: config.noiseOctaves,
            persistence: config.noisePersistence
        )
        
        // Apply directional emphasis
        let targetOffset = CGPoint(
            x: noiseX * Constants.maxShakeOffset * intensity * direction.dx,
            y: noiseY * Constants.maxShakeOffset * intensity * direction.dy
        )
        
        // Add secondary high-frequency jitter for impact feel
        let jitterIntensity = max(0, (intensity - 0.4) / 0.6)
        let jitterX = sin(elapsedTime * 50) * 3.0 * jitterIntensity
        let jitterY = cos(elapsedTime * 47) * 3.0 * jitterIntensity
        
        shakeState.position = CGPoint(
            x: targetOffset.x + jitterX,
            y: targetOffset.y + jitterY
        )
        
        // Calculate rotation
        let rotationNoise = noise.fbm2D(
            noiseOffset * 0.5,
            elapsedTime * 0.3,
            octaves: 2,
            persistence: 0.5
        )
        shakeState.rotation = rotationNoise * Constants.maxRotation * intensity
        
        // Calculate zoom shake (camera pulls back during intense moments)
        if config.zoomShakeEnabled && intensity > 0.5 {
            let zoomNoise = noise.noise1D(elapsedTime * 3)
            let zoomDelta = zoomNoise * Constants.zoomShakeAmount * (intensity - 0.5) * 2
            shakeState.scale = 1.0 + zoomDelta
        } else {
            shakeState.scale = 1.0
        }
        
        // Store velocity for motion blur
        shakeState.velocity = CGVector(
            dx: (targetOffset.x - shakeState.position.x) / CGFloat(deltaTime),
            dy: (targetOffset.y - shakeState.position.y) / CGFloat(deltaTime)
        )
        
        shakeState.shakeTime = elapsedTime
    }
    
    private func updateRecovery(deltaTime: TimeInterval) {
        let dt = CGFloat(deltaTime)
        
        // Spring-based recovery to center
        let springStrength: CGFloat = Constants.recoverySpeed
        let damping: CGFloat = config.recoveryDamping
        
        // Position recovery
        let displacementX = -shakeState.position.x
        let displacementY = -shakeState.position.y
        
        shakeState.velocity.dx += displacementX * springStrength * dt
        shakeState.velocity.dy += displacementY * springStrength * dt
        shakeState.velocity.dx *= damping
        shakeState.velocity.dy *= damping
        
        shakeState.position.x += shakeState.velocity.dx * dt
        shakeState.position.y += shakeState.velocity.dy * dt
        
        // Rotation recovery
        let rotDisplacement = -shakeState.rotation
        shakeState.angularVelocity += rotDisplacement * springStrength * dt
        shakeState.angularVelocity *= damping
        shakeState.rotation += shakeState.angularVelocity * dt
        
        // Scale recovery
        let scaleDiff = 1.0 - shakeState.scale
        shakeState.scale += scaleDiff * springStrength * dt
        
        // Fade out visual effects
        vignetteNode?.setIntensity(currentIntensity * 0.6)
        chromaticAberrationNode?.setIntensity(currentIntensity * 0.5)
        motionBlurNode?.update(velocity: .zero, intensity: 0)
    }
    
    private func updateVisualEffects() {
        let intensity = currentIntensity
        
        // Update vignette
        vignetteNode?.setIntensity(intensity * 0.6)
        
        // Update chromatic aberration at high intensities
        if config.chromaticAberrationEnabled && intensity > 0.4 {
            let aberrationIntensity = (intensity - 0.4) / 0.6
            let shakeDirection = CGVector(
                dx: cos(elapsedTime * 5),
                dy: sin(elapsedTime * 5)
            )
            chromaticAberrationNode?.setIntensity(aberrationIntensity, direction: shakeDirection)
        } else {
            chromaticAberrationNode?.setIntensity(0)
        }
        
        // Update motion blur during fast movements
        if config.motionBlurEnabled {
            let velocityMagnitude = hypot(shakeState.velocity.dx, shakeState.velocity.dy)
            let blurThreshold: CGFloat = 100.0
            let blurIntensity = min(1.0, velocityMagnitude / blurThreshold) * intensity
            motionBlurNode?.update(velocity: shakeState.velocity, intensity: blurIntensity)
        }
    }
    
    private func applyCameraTransform() {
        guard let camera = cameraNode else { return }
        
        // Apply shake offset to camera position
        let finalPosition = CGPoint(
            x: originalCameraPosition.x + shakeState.position.x,
            y: originalCameraPosition.y + shakeState.position.y
        )
        
        camera.position = finalPosition
        camera.zRotation = shakeState.rotation
        camera.setScale(originalCameraScale * shakeState.scale)
    }
    
    // MARK: - Public Controls
    
    /// Start shaking with specified intensity
    func startShake(intensity: CGFloat, direction: ShakeDirection = .omni) {
        isShaking = true
        targetIntensity = intensity.clamped(to: 0...1)
        config.shakeDirection = direction
        noise = PerlinNoise(seed: Int(elapsedTime * 1000))
    }
    
    /// Stop shaking with recovery
    func stopShake() {
        isShaking = false
        targetIntensity = 0
    }
    
    /// Set shake intensity (0.0 - 1.0)
    func setIntensity(_ intensity: CGFloat) {
        targetIntensity = intensity.clamped(to: 0...1)
        isShaking = targetIntensity > 0
    }
    
    /// Trigger impact effect
    func triggerImpact(intensity: CGFloat, direction: CGVector? = nil) {
        let clampedIntensity = intensity.clamped(to: 0...1)
        
        // Add instantaneous offset
        let dir = direction ?? CGVector(dx: CGFloat.random(in: -1...1), 
                                        dy: CGFloat.random(in: -1...1))
        let impactOffset = CGPoint(
            x: dir.dx * 30 * clampedIntensity,
            y: dir.dy * 30 * clampedIntensity
        )
        shakeState.position.x += impactOffset.x
        shakeState.position.y += impactOffset.y
        
        // Flash effect
        if clampedIntensity > 0.5 {
            let flashIntensity = (clampedIntensity - 0.5) * 2.0
            flashNode?.flash(intensity: flashIntensity * 0.5, duration: 0.2)
        }
        
        // Extra chromatic aberration
        chromaticAberrationNode?.setIntensity(clampedIntensity * 0.8, direction: dir)
    }
    
    /// Flash screen with color
    func flash(color: UIColor = .white, intensity: CGFloat = 1.0, duration: TimeInterval = 0.3) {
        flashNode?.flash(color: color, intensity: intensity, duration: duration)
    }
    
    /// Warning flash sequence
    func warningFlash(count: Int = 3, color: UIColor = .red) {
        flashNode?.warningFlash(count: count, color: color)
    }
    
    // MARK: - Cinematic Transitions
    
    /// Execute cinematic transition
    func performTransition(_ transition: CinematicTransition, completion: (() -> Void)? = nil) {
        guard cameraNode != nil else {
            completion?()
            return
        }

        isInCinematic = true
        
        switch transition {
        case .zoomIn(let target, let scale, let duration):
            performZoomIn(target: target, scale: scale, duration: duration, completion: completion)
            
        case .zoomOut(let duration):
            performZoomOut(duration: duration, completion: completion)
            
        case .slowMotion(let speed, let duration):
            performSlowMotion(speed: speed, duration: duration, completion: completion)
            
        case .flash(let color, let intensity, let duration):
            flash(color: color, intensity: intensity, duration: duration)
            completion?()
            
        case .shake(let intensity, let duration):
            performShakeTransition(intensity: intensity, duration: duration, completion: completion)
            
        case .fadeTo(let color, let duration):
            performFadeTo(color: color, duration: duration, completion: completion)
        }
    }
    
    private func performZoomIn(target: CGPoint, scale: CGFloat, duration: TimeInterval, completion: (() -> Void)?) {
        guard let camera = cameraNode else { return }
        
        let moveAction = SKAction.move(to: target, duration: duration)
        let scaleAction = SKAction.scale(to: originalCameraScale * scale, duration: duration)
        let group = SKAction.group([moveAction, scaleAction])
        group.timingMode = .easeInEaseOut
        
        camera.run(group) { [weak self] in
            self?.isInCinematic = false
            completion?()
        }
    }
    
    private func performZoomOut(duration: TimeInterval, completion: (() -> Void)?) {
        guard let camera = cameraNode else { return }
        
        let moveAction = SKAction.move(to: originalCameraPosition, duration: duration)
        let scaleAction = SKAction.scale(to: originalCameraScale, duration: duration)
        let rotateAction = SKAction.rotate(toAngle: 0, duration: duration)
        let group = SKAction.group([moveAction, scaleAction, rotateAction])
        group.timingMode = .easeInEaseOut
        
        camera.run(group) { [weak self] in
            self?.isInCinematic = false
            completion?()
        }
    }
    
    private func performSlowMotion(speed: CGFloat, duration: TimeInterval, completion: (() -> Void)?) {
        slowMotionFactor = speed
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.slowMotionFactor = 1.0
            completion?()
        }
    }
    
    private func performShakeTransition(intensity: CGFloat, duration: TimeInterval, completion: (() -> Void)?) {
        startShake(intensity: intensity)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.stopShake()
            completion?()
        }
    }
    
    private func performFadeTo(color: UIColor, duration: TimeInterval, completion: (() -> Void)?) {
        let fadeNode = SKShapeNode(rectOf: CGSize(width: 3000, height: 3000))
        fadeNode.fillColor = color
        fadeNode.strokeColor = .clear
        fadeNode.alpha = 0
        fadeNode.zPosition = 2000
        cameraNode?.addChild(fadeNode)
        
        let fadeIn = SKAction.fadeIn(withDuration: duration * 0.5)
        let fadeOut = SKAction.fadeOut(withDuration: duration * 0.5)
        let remove = SKAction.removeFromParent()
        
        fadeNode.run(SKAction.sequence([fadeIn, fadeOut, remove])) {
            completion?()
        }
    }
    
    /// Reset camera to original state
    func reset(animated: Bool = true, duration: TimeInterval = 0.5) {
        isShaking = false
        isInCinematic = false
        targetIntensity = 0
        currentIntensity = 0
        slowMotionFactor = 1.0
        
        shakeState = CameraShakeState()
        
        guard let camera = cameraNode else { return }
        
        if animated {
            let moveAction = SKAction.move(to: originalCameraPosition, duration: duration)
            let scaleAction = SKAction.scale(to: originalCameraScale, duration: duration)
            let rotateAction = SKAction.rotate(toAngle: 0, duration: duration)
            let group = SKAction.group([moveAction, scaleAction, rotateAction])
            group.timingMode = .easeOut
            camera.run(group)
        } else {
            camera.position = originalCameraPosition
            camera.setScale(originalCameraScale)
            camera.zRotation = 0
        }
        
        // Reset effects
        vignetteNode?.setIntensity(0)
        chromaticAberrationNode?.setIntensity(0)
    }
    
    // MARK: - Integration Helpers
    
    /// Update original camera position (call when camera moves)
    func updateOriginalPosition(_ position: CGPoint) {
        if !isShaking && !isInCinematic {
            originalCameraPosition = position
        }
    }
    
    /// Get current shake offset for external use
    func getCurrentOffset() -> CGPoint {
        return shakeState.position
    }
    
    /// Get current shake intensity
    func getCurrentIntensity() -> CGFloat {
        return currentIntensity
    }
    
    /// Check if currently in cinematic
    func isInCinematicMode() -> Bool {
        return isInCinematic
    }
}

// MARK: - SKCameraNode Extension

extension SKCameraNode {
    /// Add camera effects controller to this camera
    func addEffectsController(scene: SKScene, config: CameraEffectConfig = CameraEffectConfig()) -> CameraEffectsController {
        return CameraEffectsController(cameraNode: self, scene: scene, config: config)
    }
}

// MARK: - ShakeController Integration Extension

extension CameraEffectsController {
    
    /// Sync with ShakeController intensity and phase
    func syncWithShakeController(_ shakeController: ShakeController, deltaTime: TimeInterval) {
        let intensity = shakeController.currentIntensity
        
        // Map ShakeController intensity to camera effects
        setIntensity(intensity)
        
        // Trigger impact effects on major intensity spikes
        if intensity > 0.8 && currentIntensity < 0.6 {
            triggerImpact(intensity: intensity)
        }
        
        // Update vignette based on ShakeController's vignette intensity
        let vignetteIntensity = shakeController.getVignetteIntensity()
        vignetteNode?.setIntensity(vignetteIntensity)
    }
    
    /// Enhanced earthquake start with proper configuration
    func startEarthquake(magnitude: Double, phase: QuakePhase) {
        let baseIntensity = CGFloat((magnitude - 4.0) / 4.0 * 0.7 + 0.3)
        
        switch phase {
        case .pWave:
            // Gentle horizontal rolling
            startShake(intensity: baseIntensity * 0.3, direction: .horizontal)
            
        case .sWave:
            // Intense omni-directional shaking
            startShake(intensity: baseIntensity, direction: .omni)
            warningFlash(count: 2, color: .orange)
            
        case .aftershock:
            // Decaying shaking
            startShake(intensity: baseIntensity * 0.5, direction: .vertical)
            
        default:
            stopShake()
        }
    }
}
