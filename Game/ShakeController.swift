import SpriteKit

// MARK: - Shake Controller Delegate

@MainActor
protocol ShakeControllerDelegate: AnyObject {
    func shakeIntensityDidChange(_ intensity: CGFloat, phase: QuakePhase)
    func shakePhaseDidChange(_ phase: QuakePhase)
    func shakeControllerDidTriggerImpact(_ intensity: CGFloat, position: CGPoint)
    func shakeControllerDidUpdateDustIntensity(_ intensity: CGFloat)
}

// MARK: - Wave Types

enum SeismicWaveType {
    case pWave      // Primary wave - gentle horizontal rolling
    case sWave      // Secondary wave - violent vertical+horizontal
    case aftershock // Decaying oscillation with spikes
    case surface    // Slow rolling motion (Love/Rayleigh waves)
}

// MARK: - Shake Layer

/// Represents a single layer of the multi-layered shake system
struct ShakeLayer {
    let name: String
    let amplitude: CGFloat
    let frequency: CGFloat
    let phaseOffset: CGFloat
    let damping: CGFloat
    let isDirectional: Bool          // If true, follows wave direction; if false, is random
    let direction: CGVector          // Primary shake direction (for P-waves, etc.)
    let octave: Int                  // For fractal noise layering
}

// MARK: - Camera Effect State

struct CameraEffectState {
    var currentZoom: CGFloat = 1.0
    var targetZoom: CGFloat = 1.0
    var zoomVelocity: CGFloat = 0.0
    var currentBlur: CGFloat = 0.0
    var targetBlur: CGFloat = 0.0
    var vignetteIntensity: CGFloat = 0.0
    var targetVignette: CGFloat = 0.0
    var isStunned: Bool = false
    var stunDuration: TimeInterval = 0.0
    var stunTimer: TimeInterval = 0.0
}

// MARK: - Intensity Curve Point

struct IntensityCurvePoint {
    let time: TimeInterval
    let intensity: CGFloat
    let waveType: SeismicWaveType
}

// MARK: - Shake Controller

@MainActor
final class ShakeController {
    weak var delegate: ShakeControllerDelegate?
    private weak var cameraNode: SKCameraNode?
    private weak var scene: SKScene?
    
    // MARK: - State
    
    private var isShaking = false
    private(set) var currentIntensity: CGFloat = 0
    private(set) var currentPhase: QuakePhase = .calm
    private var magnitude: Double = 6.5
    private var elapsedTime: TimeInterval = 0
    private var phaseStartTime: TimeInterval = 0
    
    // MARK: - Camera & Position
    
    private let cameraRestPosition: CGPoint
    private var cameraRestScale: CGFloat = 1.0
    private var effectState = CameraEffectState()
    
    // MARK: - Multi-Layer Shake System
    
    private var shakeLayers: [ShakeLayer] = []
    private var layerOffsets: [String: CGPoint] = [:]
    private var layerRotations: [String: CGFloat] = [:]
    private var primaryOffset: CGPoint = .zero
    private var secondaryOffset: CGPoint = .zero
    private var rotationAngle: CGFloat = 0.0
    
    // MARK: - Seismic Wave Simulation
    
    private var wavePhase: CGFloat = 0.0
    private var waveFrequency: CGFloat = 1.0
    private var currentWaveType: SeismicWaveType = .pWave
    private var intensityCurve: [IntensityCurvePoint] = []
    private var lastSpikeTime: TimeInterval = 0.0
    private var nextSpikeTime: TimeInterval = 0.0
    
    // MARK: - Environmental Feedback
    
    private var dustIntensity: CGFloat = 0.0
    private var warningObjects: [String: TimeInterval] = [:]
    private var impactedObjects: Set<String> = []
    private var lastImpactTime: TimeInterval = 0.0
    
    // MARK: - Sync & Timing
    
    private var hapticLatency: TimeInterval = 0.008    // 8ms typical haptic latency
    private var audioLatency: TimeInterval = 0.040     // 40ms typical audio latency
    private var visualLeadTime: TimeInterval = 0.016   // 16ms for 60fps
    private var syncBuffer: [(TimeInterval, CGFloat, QuakePhase)] = []
    
    // MARK: - Random Generators (for deterministic behavior)
    
    private var randomSeed: UInt64 = 0
    private var currentRandom: CGFloat = 0.5
    
    // MARK: - Constants
    
    private struct ShakeConstants {
        // Multi-layer shake amplitudes
        static let primaryAmplitude: CGFloat = 25.0
        static let secondaryAmplitude: CGFloat = 8.0
        static let microJitterAmplitude: CGFloat = 3.0
        static let rotationAmplitude: CGFloat = 0.08
        
        // Wave frequencies
        static let pWaveFrequency: CGFloat = 0.5
        static let sWaveFrequency: CGFloat = 2.5
        static let aftershockFrequency: CGFloat = 1.2
        static let surfaceWaveFrequency: CGFloat = 0.3
        
        // Zoom effect
        static let zoomInAmount: CGFloat = 0.95
        static let zoomOutAmount: CGFloat = 1.05
        static let zoomSpeed: CGFloat = 2.0
        static let zoomDamping: CGFloat = 0.85
        
        // Vignette
        static let vignetteBase: CGFloat = 0.0
        static let vignetteMax: CGFloat = 0.6
        
        // Stun effect
        static let stunRecoveryTime: TimeInterval = 0.5
        static let impactStunThreshold: CGFloat = 0.85
        
        // Environmental
        static let warningTime: TimeInterval = 0.5
        static let dustEmissionMultiplier: CGFloat = 50.0
    }
    
    // MARK: - Initialization
    
    init(cameraNode: SKCameraNode, scene: SKScene? = nil) {
        self.cameraNode = cameraNode
        self.scene = scene
        self.cameraRestPosition = cameraNode.position
        self.cameraRestScale = cameraNode.xScale
        
        setupShakeLayers()
        initializeIntensityCurve()
    }
    
    // MARK: - Setup
    
    private func setupShakeLayers() {
        // Primary layer - large movements following seismic waves
        shakeLayers.append(ShakeLayer(
            name: "primary",
            amplitude: ShakeConstants.primaryAmplitude,
            frequency: ShakeConstants.pWaveFrequency,
            phaseOffset: 0.0,
            damping: 0.95,
            isDirectional: true,
            direction: CGVector(dx: 1, dy: 0.3),
            octave: 1
        ))
        
        // Secondary layer - rapid jitter for texture
        shakeLayers.append(ShakeLayer(
            name: "secondary",
            amplitude: ShakeConstants.secondaryAmplitude,
            frequency: ShakeConstants.sWaveFrequency,
            phaseOffset: .pi / 4,
            damping: 0.9,
            isDirectional: false,
            direction: CGVector(dx: 0, dy: 0),
            octave: 2
        ))
        
        // Micro jitter - simulates blur through rapid small movements
        shakeLayers.append(ShakeLayer(
            name: "micro",
            amplitude: ShakeConstants.microJitterAmplitude,
            frequency: 15.0,
            phaseOffset: .pi / 2,
            damping: 0.8,
            isDirectional: false,
            direction: CGVector(dx: 0, dy: 0),
            octave: 3
        ))
        
        // Surface wave layer - slow rolling
        shakeLayers.append(ShakeLayer(
            name: "surface",
            amplitude: 12.0,
            frequency: ShakeConstants.surfaceWaveFrequency,
            phaseOffset: .pi,
            damping: 0.97,
            isDirectional: true,
            direction: CGVector(dx: 0.8, dy: 0.6),
            octave: 1
        ))
        
        // Initialize offsets
        for layer in shakeLayers {
            layerOffsets[layer.name] = .zero
            layerRotations[layer.name] = 0.0
        }
    }
    
    private func initializeIntensityCurve() {
        // Generate a realistic seismograph-like intensity curve
        // Based on typical earthquake patterns
        intensityCurve = []
    }
    
    // MARK: - Start/Stop

    private var scenario: QuakeScenario?

    func startEarthquake(magnitude: Double) {
        // Legacy method for backward compatibility
        let scenario = QuakeScenario(magnitude: magnitude, roomType: "livingRoom", scenarioType: .standard)
        startEarthquake(scenario: scenario)
    }

    func startEarthquake(scenario: QuakeScenario) {
        self.scenario = scenario
        self.magnitude = scenario.magnitude
        self.isShaking = true
        self.elapsedTime = 0
        self.phaseStartTime = 0
        self.wavePhase = 0
        self.randomSeed = UInt64(Date().timeIntervalSince1970 * 1000)

        // Reset effect state
        effectState = CameraEffectState()

        // Generate intensity curve based on scenario type
        generateIntensityCurve(for: scenario)

        // Skip to S-wave for surprise quake or rapid escalation
        if scenario.scenarioType == .surpriseQuake {
            transitionToPhase(.sWave)
        } else {
            transitionToPhase(.pWave)
        }
    }
    
    func stopEarthquake() {
        isShaking = false
        currentIntensity = 0
        
        // Reset camera with smooth animation
        resetCameraWithAnimation()
        
        transitionToPhase(.debrief)
    }
    
    func forceStop() {
        isShaking = false
        currentIntensity = 0
        
        // Immediate reset
        cameraNode?.position = cameraRestPosition
        cameraNode?.setScale(cameraRestScale)
        cameraNode?.zRotation = 0
        
        // Reset all offsets
        primaryOffset = .zero
        secondaryOffset = .zero
        rotationAngle = 0.0
        layerOffsets.removeAll()
        layerRotations.removeAll()
    }
    
    // MARK: - Main Update Loop
    
    func update(deltaTime: TimeInterval) {
        guard isShaking else { return }
        
        // Clamp delta time to avoid huge jumps
        let dt = min(deltaTime, 0.1)
        
        elapsedTime += dt
        let phaseElapsed = elapsedTime - phaseStartTime
        
        // Update phase
        updatePhase(phaseElapsed: phaseElapsed)
        
        // Calculate intensity from curve
        updateIntensity(elapsedTime: elapsedTime, phaseElapsed: phaseElapsed)
        
        // Update wave simulation
        updateWaveSimulation(deltaTime: dt)
        
        // Calculate multi-layer shake
        calculateShakeLayers(deltaTime: dt)
        
        // Update camera effects
        updateCameraEffects(deltaTime: dt)
        
        // Apply shake and effects
        applyShake()
        
        // Update environmental feedback
        updateEnvironmentalFeedback()
        
        // Sync with haptics and audio (with latency compensation)
        syncWithHapticsAndAudio()
        
        // Notify delegate
        delegate?.shakeIntensityDidChange(currentIntensity, phase: currentPhase)
    }
    
    // MARK: - Phase Management

    private func updatePhase(phaseElapsed: TimeInterval) {
        guard let scenario = scenario else { return }

        switch currentPhase {
        case .pWave:
            if phaseElapsed >= scenario.pWaveDuration {
                transitionToPhase(.sWave)
            }

        case .sWave:
            if phaseElapsed >= scenario.sWaveDuration {
                transitionToPhase(.aftershock)
            }

        case .aftershock:
            if phaseElapsed >= scenario.aftershockDuration {
                stopEarthquake()
            }

        default:
            break
        }
    }
    
    private func transitionToPhase(_ phase: QuakePhase) {
        currentPhase = phase
        phaseStartTime = elapsedTime
        
        // Set wave type based on phase
        switch phase {
        case .pWave:
            currentWaveType = .pWave
            waveFrequency = ShakeConstants.pWaveFrequency
        case .sWave:
            currentWaveType = .sWave
            waveFrequency = ShakeConstants.sWaveFrequency
            // Trigger zoom effect on phase transition to intense shaking
            triggerZoomEffect()
        case .aftershock:
            currentWaveType = .aftershock
            waveFrequency = ShakeConstants.aftershockFrequency
        default:
            currentWaveType = .surface
        }
        
        delegate?.shakePhaseDidChange(phase)
    }
    
    // MARK: - Intensity Curve Generation

    private func generateIntensityCurve() {
        // Legacy method - generates standard curve
        let scenario = QuakeScenario(magnitude: magnitude, roomType: "", scenarioType: .standard)
        generateIntensityCurve(for: scenario)
    }

    private func generateIntensityCurve(for scenario: QuakeScenario) {
        intensityCurve.removeAll()

        let baseMultiplier = CGFloat((scenario.magnitude - 4.0) / 4.0 * 0.7 + 0.3)
        // Apply scenario-specific intensity multiplier
        let magnitudeMultiplier = scenario.scenarioType == .trainingMode ? 0.4 : baseMultiplier

        let pWaveDuration = scenario.pWaveDuration
        let sWaveDuration = scenario.sWaveDuration
        let aftershockDuration = scenario.aftershockDuration

        // P-wave: gentle building intensity
        let pWavePoints = max(2, Int(pWaveDuration * 10))
        for i in 0..<pWavePoints {
            let t = Double(i) / Double(pWavePoints) * pWaveDuration
            let progress = CGFloat(i) / CGFloat(pWavePoints)
            let intensity = (0.1 + progress * 0.25) * magnitudeMultiplier
            intensityCurve.append(IntensityCurvePoint(
                time: t,
                intensity: intensity,
                waveType: .pWave
            ))
        }

        // S-wave: varies by scenario type
        let sWavePoints = Int(sWaveDuration * 30) // 30 points per second

        for i in 0..<sWavePoints {
            let t = pWaveDuration + Double(i) / 30.0
            let progress = CGFloat(i) / CGFloat(sWavePoints)

            var baseIntensity: CGFloat

            switch scenario.scenarioType {
            case .rapidEscalation:
                // Rapid escalation: immediate high intensity
                baseIntensity = 0.7 + 0.3 * sin(progress * .pi)

            case .surpriseQuake:
                // Surprise: starts at high intensity
                baseIntensity = 0.65 + 0.35 * sin(progress * .pi)

            case .trainingMode:
                // Training: gentler S-wave
                baseIntensity = 0.4 + 0.3 * sin(progress * .pi)

            default:
                // Standard: intense with peak in the middle
                baseIntensity = 0.6 + 0.4 * sin(progress * .pi)
            }

            // Add random spikes based on magnitude
            if scenario.magnitude > 6.0 && Int.random(in: 0...100) < 5 {
                baseIntensity += CGFloat.random(in: 0.15...0.3)
            }

            // Multiple peaks for high magnitude or aftershock-heavy
            if scenario.magnitude > 7.0 || scenario.scenarioType == .aftershockHeavy {
                let secondaryPeak = 0.2 * sin(progress * 4 * .pi)
                baseIntensity += secondaryPeak
            }

            let intensity = baseIntensity.clamped(to: 0.3...1.0) * magnitudeMultiplier
            intensityCurve.append(IntensityCurvePoint(
                time: t,
                intensity: intensity,
                waveType: .sWave
            ))
        }

        // Aftershock: varies by scenario type
        let aftershockPoints = Int(aftershockDuration * 20)
        let aftershockCount = scenario.aftershockCount

        for i in 0..<aftershockPoints {
            let t = pWaveDuration + sWaveDuration + Double(i) / 20.0
            let progress = CGFloat(i) / CGFloat(aftershockPoints)

            // Exponential decay
            var decayingBase: CGFloat = 0.4 * exp(-progress * 3.0)

            // Aftershock spikes based on scenario
            let spikeChance: Int
            let spikeIntensity: ClosedRange<CGFloat>

            switch scenario.scenarioType {
            case .aftershockHeavy:
                // Multiple major spikes
                spikeChance = 85  // More frequent spikes
                spikeIntensity = 0.3...0.6
            case .trainingMode:
                // Minimal spikes
                spikeChance = 97
                spikeIntensity = 0.1...0.25
            default:
                // Occasional aftershock spikes
                spikeChance = 92
                spikeIntensity = 0.2...0.4
            }

            // Generate spikes at specific intervals for aftershock-heavy
            if scenario.scenarioType == .aftershockHeavy {
                let spikeInterval = 1.0 / CGFloat(aftershockCount)
                let spikePositions = (1..<aftershockCount).map { CGFloat($0) * spikeInterval }

                for spikePos in spikePositions {
                    if abs(progress - spikePos) < 0.05 {  // Within spike window
                        decayingBase += CGFloat.random(in: spikeIntensity)
                    }
                }
            } else if Int.random(in: 0...100) > spikeChance {
                decayingBase += CGFloat.random(in: spikeIntensity)
            }

            let maxIntensity: CGFloat = scenario.scenarioType == .trainingMode ? 0.4 : 0.6
            let intensity = decayingBase.clamped(to: 0...maxIntensity) * magnitudeMultiplier
            intensityCurve.append(IntensityCurvePoint(
                time: t,
                intensity: intensity,
                waveType: .aftershock
            ))
        }

        // Sort by time
        intensityCurve.sort { $0.time < $1.time }
    }
    
    private func updateIntensity(elapsedTime: TimeInterval, phaseElapsed: TimeInterval) {
        // Find the current point in the intensity curve
        var targetIntensity: CGFloat = 0.0
        
        for i in 0..<(intensityCurve.count - 1) {
            let point1 = intensityCurve[i]
            let point2 = intensityCurve[i + 1]
            
            if elapsedTime >= point1.time && elapsedTime < point2.time {
                let progress = CGFloat((elapsedTime - point1.time) / (point2.time - point1.time))
                targetIntensity = point1.intensity + (point2.intensity - point1.intensity) * progress
                break
            }
        }
        
        // If past the end of curve, use last value
        if let last = intensityCurve.last, elapsedTime >= last.time {
            targetIntensity = last.intensity
        }
        
        // Apply smooth transition
        currentIntensity = currentIntensity * 0.9 + targetIntensity * 0.1
        
        // Check for major impact
        if currentIntensity > ShakeConstants.impactStunThreshold {
            checkForMajorImpact()
        }
    }
    
    // MARK: - Seismic Wave Simulation
    
    private func updateWaveSimulation(deltaTime: TimeInterval) {
        // Advance wave phase
        wavePhase += CGFloat(deltaTime) * waveFrequency * .pi * 2
        
        // Update wave frequency based on phase
        switch currentPhase {
        case .pWave:
            waveFrequency = ShakeConstants.pWaveFrequency + currentIntensity * 0.5
        case .sWave:
            waveFrequency = ShakeConstants.sWaveFrequency + currentIntensity * 2.0
        case .aftershock:
            waveFrequency = ShakeConstants.aftershockFrequency * (1.0 - currentIntensity * 0.3)
        default:
            break
        }
    }
    
    private func getWaveOffset(for layer: ShakeLayer, at time: TimeInterval) -> CGPoint {
        let intensity = currentIntensity
        let phase = wavePhase + layer.phaseOffset
        
        switch layer.name {
        case "primary":
            return getPrimaryWaveOffset(intensity: intensity, phase: phase, layer: layer)
            
        case "secondary":
            return getSecondaryWaveOffset(intensity: intensity, phase: phase)
            
        case "micro":
            return getMicroJitterOffset(intensity: intensity, time: time)
            
        case "surface":
            return getSurfaceWaveOffset(intensity: intensity, phase: phase, layer: layer)
            
        default:
            return .zero
        }
    }
    
    private func getPrimaryWaveOffset(intensity: CGFloat, phase: CGFloat, layer: ShakeLayer) -> CGPoint {
        // P-wave: Horizontal rolling (sine wave in X)
        // S-wave: Violent vertical+horizontal with spikes
        // Aftershock: Decaying oscillation
        
        let amplitude = layer.amplitude * intensity
        
        switch currentWaveType {
        case .pWave:
            // Gentle horizontal motion with slight vertical
            let dx = sin(phase) * amplitude
            let dy = sin(phase * 0.5) * amplitude * 0.3
            return CGPoint(x: dx, y: dy)
            
        case .sWave:
            // Violent motion with random spikes
            var dx = sin(phase) * amplitude + sin(phase * 2.3) * amplitude * 0.5
            var dy = cos(phase * 0.8) * amplitude * 1.2
            
            // Add random spike
            if elapsedTime >= nextSpikeTime {
                nextSpikeTime = elapsedTime + Double.random(in: 0.3...0.8)
                let spikeX = CGFloat.random(in: -amplitude...amplitude) * 0.5
                let spikeY = CGFloat.random(in: -amplitude...amplitude) * 0.5
                dx += spikeX
                dy += spikeY
            }
            
            return CGPoint(x: dx, y: dy)
            
        case .aftershock:
            // Decaying oscillation
            let decay = exp(-CGFloat(elapsedTime - phaseStartTime) * 0.5)
            let dx = sin(phase) * amplitude * decay
            let dy = cos(phase * 0.7) * amplitude * decay * 0.8
            return CGPoint(x: dx, y: dy)
            
        case .surface:
            // Slow rolling
            let dx = sin(phase * 0.5) * amplitude * 0.8
            let dy = sin(phase * 0.3) * amplitude * 0.5
            return CGPoint(x: dx, y: dy)
        }
    }
    
    private func getSecondaryWaveOffset(intensity: CGFloat, phase: CGFloat) -> CGPoint {
        // Rapid jitter for texture
        let jitterAmplitude = ShakeConstants.secondaryAmplitude * intensity * intensity
        
        // Use multiple sine waves for complex motion
        let dx = sin(phase * 2.1) * jitterAmplitude + sin(phase * 3.7) * jitterAmplitude * 0.5
        let dy = cos(phase * 1.9) * jitterAmplitude + cos(phase * 4.2) * jitterAmplitude * 0.5
        
        return CGPoint(x: dx, y: dy)
    }
    
    private func getMicroJitterOffset(intensity: CGFloat, time: TimeInterval) -> CGPoint {
        // Very rapid micro-movements to simulate blur effect
        // Only active during high intensity
        guard intensity > 0.4 else { return .zero }
        
        let jitterIntensity = (intensity - 0.4) / 0.6 // Normalize 0.4-1.0 to 0-1
        let amplitude = ShakeConstants.microJitterAmplitude * jitterIntensity
        
        let t = CGFloat(time * 100) // High frequency
        let dx = sin(t) * amplitude + sin(t * 1.7) * amplitude * 0.7
        let dy = cos(t * 1.3) * amplitude + cos(t * 2.1) * amplitude * 0.6
        
        return CGPoint(x: dx, y: dy)
    }
    
    private func getSurfaceWaveOffset(intensity: CGFloat, phase: CGFloat, layer: ShakeLayer) -> CGPoint {
        // Surface waves (Love/Rayleigh waves) - slow rolling motion
        let amplitude = layer.amplitude * intensity * 0.8
        
        let dx = sin(phase * 0.5) * amplitude
        let dy = sin(phase * 0.4 + .pi/4) * amplitude * 0.6
        
        return CGPoint(x: dx, y: dy)
    }
    
    // MARK: - Multi-Layer Shake Calculation
    
    private func calculateShakeLayers(deltaTime: TimeInterval) {
        // Update each layer's offset based on wave simulation
        for layer in shakeLayers {
            let offset = getWaveOffset(for: layer, at: elapsedTime)
            layerOffsets[layer.name] = offset
        }
        
        // Calculate rotation based on intensity and wave phase
        let rotationIntensity = min(currentIntensity, 1.0)
        let targetRotation = sin(wavePhase * 0.5) * ShakeConstants.rotationAmplitude * rotationIntensity
        rotationAngle = rotationAngle * 0.9 + targetRotation * 0.1
        
        // Apply stun effect
        if effectState.isStunned {
            effectState.stunTimer += deltaTime
            if effectState.stunTimer >= effectState.stunDuration {
                effectState.isStunned = false
            } else {
                // During stun, add extra random shake
                let stunProgress = CGFloat(effectState.stunTimer / effectState.stunDuration)
                let stunIntensity = (1.0 - stunProgress) * 0.5
                let stunOffset = CGPoint(
                    x: CGFloat.random(in: -20...20) * stunIntensity,
                    y: CGFloat.random(in: -20...20) * stunIntensity
                )
                layerOffsets["stun"] = stunOffset
            }
        }
    }
    
    // MARK: - Camera Effects
    
    private func updateCameraEffects(deltaTime: TimeInterval) {
        // Update zoom with spring physics
        updateZoomEffect(deltaTime: deltaTime)
        
        // Update vignette based on intensity
        updateVignetteEffect()
        
        // Check for screen flash triggers
        checkForScreenFlash()
    }
    
    private func updateZoomEffect(deltaTime: TimeInterval) {
        let dt = CGFloat(deltaTime)
        
        // Spring physics for smooth zoom
        let displacement = effectState.targetZoom - effectState.currentZoom
        let springForce = displacement * ShakeConstants.zoomSpeed
        effectState.zoomVelocity += springForce * dt
        effectState.zoomVelocity *= ShakeConstants.zoomDamping
        effectState.currentZoom += effectState.zoomVelocity * dt
        
        // Target zoom based on intensity
        // High intensity = zoom in slightly, then release
        let baseZoom: CGFloat = 1.0
        let intensityZoom = 1.0 - (currentIntensity * 0.05) // Zoom in up to 5%
        
        effectState.targetZoom = baseZoom * intensityZoom
    }
    
    private func triggerZoomEffect() {
        // Dramatic zoom on phase transitions
        effectState.targetZoom = ShakeConstants.zoomInAmount
        effectState.zoomVelocity = -0.1
        
        // Return to normal after brief moment
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.effectState.targetZoom = 1.0
        }
    }
    
    private func updateVignetteEffect() {
        // Vignette intensifies with shake intensity
        let targetVignette = ShakeConstants.vignetteBase + 
                            (ShakeConstants.vignetteMax - ShakeConstants.vignetteBase) * currentIntensity
        
        effectState.targetVignette = targetVignette
        effectState.vignetteIntensity = effectState.vignetteIntensity * 0.95 + targetVignette * 0.05
    }
    
    private func checkForScreenFlash() {
        // Flash screen on major intensity spikes
        let timeSinceLastImpact = elapsedTime - lastImpactTime
        
        if currentIntensity > ShakeConstants.impactStunThreshold && 
           timeSinceLastImpact > 0.5 && 
           Int.random(in: 0...100) < 10 {
            
            triggerScreenFlash()
            lastImpactTime = elapsedTime
        }
    }
    
    private func triggerScreenFlash() {
        guard let camera = cameraNode else { return }
        
        // Create flash overlay
        let flash = SKShapeNode(rectOf: CGSize(
            width: (scene?.size.width ?? 1024) + 200,
            height: (scene?.size.height ?? 768) + 200
        ))
        flash.fillColor = .white
        flash.strokeColor = .clear
        flash.alpha = 0.0
        flash.zPosition = 100
        flash.blendMode = .add
        camera.addChild(flash)
        
        // Flash animation
        let flashIn = SKAction.fadeAlpha(to: 0.4, duration: 0.05)
        let flashOut = SKAction.fadeOut(withDuration: 0.2)
        let remove = SKAction.removeFromParent()
        
        flash.run(SKAction.sequence([flashIn, flashOut, remove]))
        
        // Trigger impact delegate
        let impactPos = CGPoint(
            x: cameraRestPosition.x + CGFloat.random(in: -100...100),
            y: cameraRestPosition.y + CGFloat.random(in: -100...100)
        )
        delegate?.shakeControllerDidTriggerImpact(currentIntensity, position: impactPos)
    }
    
    private func checkForMajorImpact() {
        // Stun camera on major impacts
        guard !effectState.isStunned else { return }
        
        let timeSinceLastStun = elapsedTime - Double(effectState.stunTimer)
        guard timeSinceLastStun > 1.0 else { return }
        
        if Int.random(in: 0...100) < 5 {
            effectState.isStunned = true
            effectState.stunTimer = 0
            effectState.stunDuration = ShakeConstants.stunRecoveryTime
        }
    }
    
    // MARK: - Apply Shake
    
    private func applyShake() {
        guard let camera = cameraNode else { return }
        
        // Combine all layer offsets
        var totalOffset: CGPoint = .zero
        for (name, offset) in layerOffsets {
            if name == "primary" {
                totalOffset.x += offset.x
                totalOffset.y += offset.y
            } else if name == "secondary" {
                totalOffset.x += offset.x * 0.6
                totalOffset.y += offset.y * 0.6
            } else if name == "micro" {
                // Micro jitter adds to blur effect, not position
                totalOffset.x += offset.x * 0.3
                totalOffset.y += offset.y * 0.3
            } else if name == "surface" {
                totalOffset.x += offset.x * 0.4
                totalOffset.y += offset.y * 0.4
            } else if name == "stun" {
                totalOffset.x += offset.x
                totalOffset.y += offset.y
            }
        }
        
        // Store for reference
        primaryOffset = layerOffsets["primary"] ?? .zero
        secondaryOffset = layerOffsets["secondary"] ?? .zero
        
        // Apply position with zoom compensation
        let zoomCompensation = 1.0 / effectState.currentZoom
        let finalPosition = CGPoint(
            x: cameraRestPosition.x + totalOffset.x * zoomCompensation,
            y: cameraRestPosition.y + totalOffset.y * zoomCompensation
        )
        
        camera.position = finalPosition
        camera.zRotation = rotationAngle
        camera.setScale(effectState.currentZoom)
        
        // Update vignette node if exists
        updateVignetteNode()
    }
    
    private func updateVignetteNode() {
        guard let camera = cameraNode,
              let vignette = camera.childNode(withName: "vignette") as? SKShapeNode else { return }
        
        vignette.alpha = effectState.vignetteIntensity
    }
    
    private func resetCameraWithAnimation() {
        guard let camera = cameraNode else { return }
        
        // Smooth reset animation
        let resetAction = SKAction.group([
            SKAction.move(to: cameraRestPosition, duration: 0.5),
            SKAction.scale(to: cameraRestScale, duration: 0.5),
            SKAction.rotate(toAngle: 0, duration: 0.5)
        ])
        resetAction.timingMode = .easeOut
        
        camera.run(resetAction)
    }
    
    // MARK: - Environmental Feedback
    
    private func updateEnvironmentalFeedback() {
        // Update dust intensity
        let newDustIntensity = currentIntensity * ShakeConstants.dustEmissionMultiplier
        if abs(newDustIntensity - dustIntensity) > 1.0 {
            dustIntensity = newDustIntensity
            delegate?.shakeControllerDidUpdateDustIntensity(dustIntensity)
        }
        
        // Update object warning states
        updateObjectWarnings()
    }
    
    private func updateObjectWarnings() {
        // Objects shake before falling as a warning
        let warningThresholds: [(String, CGFloat)] = [
            ("book_row_", IntensityThreshold.booksAndSmallItems),
            ("picture_frame_", IntensityThreshold.pictureFrames),
            ("bookshelf", IntensityThreshold.bookshelfTopple),
            ("lamp", IntensityThreshold.ceilingLampFall)
        ]
        
        for (prefix, threshold) in warningThresholds {
            let warningThreshold = threshold - 0.15
            
            if currentIntensity > warningThreshold && currentIntensity < threshold {
                // Object is in warning zone - add slight shake
                if warningObjects[prefix] == nil {
                    warningObjects[prefix] = elapsedTime
                    shakeObject(named: prefix)
                }
            } else if currentIntensity >= threshold {
                // Object should fall - remove from warnings
                warningObjects.removeValue(forKey: prefix)
            }
        }
        
        // Clean up old warnings
        for (name, time) in warningObjects {
            if elapsedTime - time > 1.0 {
                warningObjects.removeValue(forKey: name)
            }
        }
    }
    
    private func shakeObject(named prefix: String) {
        guard let scene = scene else { return }
        
        // Find matching nodes
        scene.enumerateChildNodes(withName: "//\(prefix)*") { node, _ in
            // Smoother warning wobble: eased rotation and scale so "teeter" reads clearly
            let moveR = SKAction.moveBy(x: 3, y: 0, duration: 0.08)
            let moveL = SKAction.moveBy(x: -6, y: 0, duration: 0.08)
            let moveBack = SKAction.moveBy(x: 3, y: 0, duration: 0.08)
            moveR.timingMode = .easeInEaseOut
            moveL.timingMode = .easeInEaseOut
            moveBack.timingMode = .easeInEaseOut
            let rotR = SKAction.rotate(toAngle: 0.03, duration: 0.12)
            let rotL = SKAction.rotate(toAngle: -0.03, duration: 0.12)
            rotR.timingMode = .easeInEaseOut
            rotL.timingMode = .easeInEaseOut
            let scale1 = SKAction.scaleX(to: 1.02, y: 0.98, duration: 0.12)
            let scale2 = SKAction.scaleX(to: 0.98, y: 1.02, duration: 0.12)
            let scale3 = SKAction.scaleX(to: 1.0, y: 1.0, duration: 0.12)
            scale1.timingMode = .easeInEaseOut
            scale2.timingMode = .easeInEaseOut
            scale3.timingMode = .easeInEaseOut
            let wobble = SKAction.group([
                SKAction.sequence([moveR, moveL, moveBack]),
                SKAction.sequence([rotR, rotL]),
                SKAction.sequence([scale1, scale2, scale3])
            ])
            node.run(wobble)
            
            // Add small dust particles at base of object
            let basePos = CGPoint(x: node.position.x, y: node.position.y - node.frame.height / 2)
            let dust = SKShapeNode(circleOfRadius: 2)
            dust.fillColor = SKColor(red: 0.6, green: 0.55, blue: 0.5, alpha: 0.4)
            dust.position = basePos
            dust.zPosition = 5
            scene.addChild(dust)
            
            dust.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.5),
                SKAction.removeFromParent()
            ]))
        }
    }
    
    // MARK: - Haptic-Audio-Visual Sync
    
    private func syncWithHapticsAndAudio() {
        // Store current state with timestamp for latency compensation
        let syncPoint = (
            elapsedTime,
            currentIntensity,
            currentPhase
        )
        syncBuffer.append(syncPoint)
        
        // Keep buffer size manageable
        if syncBuffer.count > 10 {
            syncBuffer.removeFirst()
        }
        
        // The delegate already receives real-time updates
        // Audio and haptic managers can use the current intensity directly
        // This ensures tight synchronization
    }
    
    // MARK: - Public Accessors
    
    func getCurrentWaveOffset() -> CGPoint {
        return primaryOffset
    }
    
    func getSecondaryOffset() -> CGPoint {
        return secondaryOffset
    }
    
    func getRotationAngle() -> CGFloat {
        return rotationAngle
    }
    
    func getVignetteIntensity() -> CGFloat {
        return effectState.vignetteIntensity
    }
    
    func isCameraStunned() -> Bool {
        return effectState.isStunned
    }
    
    func getWarningObjects() -> [String] {
        return Array(warningObjects.keys)
    }
    
    // MARK: - Manual Controls (for testing/debugging)
    
    func setIntensity(_ intensity: CGFloat) {
        currentIntensity = intensity.clamped(to: 0...1)
    }
    
    func triggerManualImpact(intensity: CGFloat) {
        let clampedIntensity = intensity.clamped(to: 0...1)
        currentIntensity = max(currentIntensity, clampedIntensity)
        
        effectState.isStunned = true
        effectState.stunTimer = 0
        effectState.stunDuration = ShakeConstants.stunRecoveryTime * Double(intensity)
        
        triggerScreenFlash()
    }
    
    func setZoom(_ zoom: CGFloat) {
        effectState.targetZoom = zoom.clamped(to: 0.5...2.0)
    }
}

// MARK: - Default Delegate Implementation

extension ShakeControllerDelegate {
    func shakeControllerDidTriggerImpact(_ intensity: CGFloat, position: CGPoint) {
        // Default empty implementation
    }
    
    func shakeControllerDidUpdateDustIntensity(_ intensity: CGFloat) {
        // Default empty implementation
    }
}
