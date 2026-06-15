import SpriteKit

// MARK: - Mini-Game Protocol

@MainActor
protocol MiniGameDelegate: AnyObject {
    func miniGameDidComplete(_ miniGame: MiniGameNode, action: PlayerAction)
    func miniGameDidFail(_ miniGame: MiniGameNode, action: PlayerAction)
}

// MARK: - Base Mini-Game Node

class MiniGameNode: SKNode {
    weak var miniGameDelegate: MiniGameDelegate?
    let action: PlayerAction
    var isCompleted = false
    var isFailed = false

    init(action: PlayerAction) {
        self.action = action
        super.init()
        self.zPosition = 200
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func handleTouch(at location: CGPoint) {}
    func handleDrag(from start: CGPoint, to current: CGPoint) {}
    func handleTouchEnded(at location: CGPoint) {}

    func present(in scene: SKScene) {
        alpha = 0
        setScale(0.8)
        scene.addChild(self)

        run(SKAction.group([
            SKAction.fadeIn(withDuration: 0.25),
            SKAction.scale(to: 1.0, duration: 0.25)
        ]))
    }

    func dismiss() {
        run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.3),
                SKAction.scale(to: 0.8, duration: 0.3)
            ]),
            SKAction.removeFromParent()
        ]))
    }
}

// MARK: - Gas Valve Mini-Game (Rotation Gesture)

/// Player must drag in a circular motion to turn the valve. A progress ring fills up.
/// Enhanced with click sounds, resistance wobble, color transitions, steam particles,
/// timer urgency effects, and satisfying completion animation.
final class GasValveMiniGame: MiniGameNode {
    private let progressRing: SKShapeNode
    private let progressRingBg: SKShapeNode
    private let valveWheel: SKSpriteNode
    private let backdrop: SKShapeNode
    private let timerBar: SKShapeNode
    private let timerBarBg: SKShapeNode
    private let instructionLabel: SKLabelNode
    private let checkmarkNode: SKSpriteNode
    private let vignetteNode: SKShapeNode

    private var progress: CGFloat = 0.0
    private let requiredProgress: CGFloat = 1.0
    private var lastAngle: CGFloat?
    private var totalRotation: CGFloat = 0.0
    private let fullRotationNeeded: CGFloat = .pi * 3.0 // 1.5 full turns
    private var timeRemaining: TimeInterval = 6.0
    private let timeLimit: TimeInterval = 6.0
    private var gasParticleTimer: TimeInterval = 0
    private var isActive = false

    // Enhanced feedback tracking
    private var lastClickRotation: CGFloat = 0.0
    private let clickInterval: CGFloat = .pi / 4 // 45 degrees
    private var lastDirection: CGFloat = 0.0
    private var lastHapticProgress: CGFloat = 0.0
    private var steamEmitter: SKEmitterNode?
    private let handsNode: SKSpriteNode

    init() {
        // Semi-transparent backdrop with warning color border
        backdrop = SKShapeNode(rectOf: CGSize(width: 240, height: 300), cornerRadius: 20)
        backdrop.fillColor = SKColor(white: 0.05, alpha: 0.9)
        backdrop.strokeColor = SKColor(red: 0.9, green: 0.2, blue: 0.1, alpha: 0.9)
        backdrop.lineWidth = 4
        backdrop.glowWidth = 2

        // Progress ring background (gray track)
        let ringBgPath = CGMutablePath()
        ringBgPath.addArc(center: .zero, radius: 55, startAngle: -.pi / 2, endAngle: .pi * 1.5, clockwise: false)
        progressRingBg = SKShapeNode(path: ringBgPath)
        progressRingBg.strokeColor = SKColor(white: 0.25, alpha: 1.0)
        progressRingBg.lineWidth = 8
        progressRingBg.lineCap = .round

        // Progress ring (fills up)
        let ringPath = CGMutablePath()
        ringPath.addArc(center: .zero, radius: 55, startAngle: -.pi / 2, endAngle: -.pi / 2, clockwise: false)
        progressRing = SKShapeNode(path: ringPath)
        progressRing.strokeColor = SKColor(red: 0.9, green: 0.2, blue: 0.1, alpha: 1.0) // Starts red
        progressRing.lineWidth = 8
        progressRing.lineCap = .round
        progressRing.glowWidth = 4

        // Valve wheel with larger size for better interaction
        valveWheel = SKSpriteNode(texture: TextureFactory.gasValveIcon(), size: CGSize(width: 80, height: 94))
        valveWheel.color = .white
        valveWheel.colorBlendFactor = 0.0

        // Timer bar background
        timerBarBg = SKShapeNode(rectOf: CGSize(width: 180, height: 10), cornerRadius: 5)
        timerBarBg.fillColor = SKColor(white: 0.2, alpha: 1)
        timerBarBg.strokeColor = .clear

        // Timer bar fill (starts green)
        timerBar = SKShapeNode(rectOf: CGSize(width: 180, height: 10), cornerRadius: 5)
        timerBar.fillColor = SKColor(red: 0.3, green: 0.9, blue: 0.3, alpha: 1.0)
        timerBar.strokeColor = .clear

        // Instruction label
        instructionLabel = SKLabelNode(text: String(localized: "TURN CLOCKWISE!"))
        instructionLabel.fontSize = DynamicTypeScale.scaled(14)
        instructionLabel.fontName = "Helvetica-Bold"
        instructionLabel.fontColor = .white

        // Checkmark for completion (hidden initially)
        checkmarkNode = SKSpriteNode()
        checkmarkNode.size = CGSize(width: 50, height: 50)
        checkmarkNode.alpha = 0
        checkmarkNode.zPosition = 100

        // Vignette for urgency effect (darkens screen edges)
        vignetteNode = SKShapeNode(rectOf: CGSize(width: 400, height: 400))
        vignetteNode.fillColor = SKColor(red: 0.5, green: 0, blue: 0, alpha: 0)
        vignetteNode.strokeColor = .clear
        vignetteNode.zPosition = -10

        // Player hands gripping the valve wheel
        handsNode = SKSpriteNode(texture: TextureFactory.playerHandsOnValve(), size: CGSize(width: 80, height: 94))
        handsNode.alpha = 0
        handsNode.zPosition = 2

        super.init(action: .shutOffGas)
    }

    override func present(in scene: SKScene) {
        // Position at camera center
        if let camera = scene.camera {
            position = camera.position
        } else {
            position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        }

        // Accessibility announcement
        UIAccessibility.post(notification: .announcement, argument: String(localized: "Gas valve mini-game. Turn the valve clockwise to shut off the gas. You have 6 seconds."))

        // Layout
        backdrop.position = .zero
        addChild(backdrop)

        // Vignette for urgency
        vignetteNode.position = .zero
        addChild(vignetteNode)

        let titleLabel = SKLabelNode(text: String(localized: "⚠️ SHUT OFF GAS"))
        titleLabel.fontSize = DynamicTypeScale.scaled(18)
        titleLabel.fontName = "Helvetica-Bold"
        titleLabel.fontColor = SKColor(red: 1.0, green: 0.3, blue: 0.15, alpha: 1)
        titleLabel.position = CGPoint(x: 0, y: 120)
        addChild(titleLabel)

        // Progress ring background
        progressRingBg.position = CGPoint(x: 0, y: 20)
        addChild(progressRingBg)

        // Progress ring on top
        progressRing.position = CGPoint(x: 0, y: 20)
        addChild(progressRing)
        updateProgressRing()

        // Valve wheel with pulsing animation
        valveWheel.position = CGPoint(x: 0, y: 20)
        addChild(valveWheel)

        // Idle pulse animation for valve
        let idlePulse = SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.02, duration: 0.4),
            SKAction.scale(to: 0.98, duration: 0.4)
        ]))
        valveWheel.run(idlePulse, withKey: "idlePulse")

        // Direction indicator arrow
        let arrowNode = createDirectionArrow()
        arrowNode.position = CGPoint(x: 0, y: 20)
        addChild(arrowNode)

        instructionLabel.position = CGPoint(x: 0, y: -60)
        addChild(instructionLabel)

        timerBarBg.position = CGPoint(x: 0, y: -90)
        addChild(timerBarBg)

        timerBar.position = CGPoint(x: 0, y: -90)
        addChild(timerBar)

        // Gas warning with pulsing glow
        let warningIcon = SKLabelNode(text: "☠️")
        warningIcon.fontSize = DynamicTypeScale.scaled(28)
        warningIcon.position = CGPoint(x: 0, y: -125)
        addChild(warningIcon)

        // Enhanced pulse warning
        warningIcon.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.group([
                SKAction.fadeAlpha(to: 0.3, duration: 0.3),
                SKAction.scale(to: 0.9, duration: 0.3)
            ]),
            SKAction.group([
                SKAction.fadeAlpha(to: 1.0, duration: 0.3),
                SKAction.scale(to: 1.1, duration: 0.3)
            ])
        ])))

        // Checkmark node (positioned over valve, hidden initially)
        checkmarkNode.position = CGPoint(x: 0, y: 20)
        checkmarkNode.texture = createCheckmarkTexture()
        addChild(checkmarkNode)

        // Hands node parented to valve wheel so they rotate together
        handsNode.position = .zero
        valveWheel.addChild(handsNode)

        // Hide interactive elements initially for intro
        valveWheel.alpha = 0
        progressRingBg.alpha = 0
        progressRing.alpha = 0
        instructionLabel.alpha = 0
        timerBarBg.alpha = 0
        timerBar.alpha = 0

        // Start gas leak intro sequence, then enable interaction
        showLeakIntro()

        super.present(in: scene)
    }

    /// Cinematic intro: gas leak detected → pipe with gas clouds → valve fades in → timer starts
    private func showLeakIntro() {
        // Pipe segment at center of backdrop
        let pipe = SKShapeNode(rectOf: CGSize(width: 20, height: 60), cornerRadius: 2)
        pipe.fillColor = SKColor(white: 0.25, alpha: 1.0)
        pipe.strokeColor = SKColor(white: 0.15, alpha: 1.0)
        pipe.lineWidth = 2
        pipe.position = CGPoint(x: 0, y: 20)
        pipe.zPosition = -2
        pipe.name = "intro_pipe"
        addChild(pipe)

        // Crack line on pipe
        let crack = SKShapeNode()
        let crackPath = CGMutablePath()
        crackPath.move(to: CGPoint(x: -3, y: 8))
        crackPath.addLine(to: CGPoint(x: 2, y: 0))
        crackPath.addLine(to: CGPoint(x: -1, y: -6))
        crack.path = crackPath
        crack.strokeColor = SKColor(red: 0.8, green: 0.3, blue: 0.1, alpha: 0.8)
        crack.lineWidth = 1.5
        pipe.addChild(crack)

        // Intense gas leak from crack (3× birth rate)
        let spawnIntroGas = SKAction.run { [weak self] in
            guard let self = self else { return }
            let cloud = SKShapeNode(circleOfRadius: CGFloat.random(in: 5...14))
            cloud.fillColor = SKColor(red: 0.35, green: 0.55, blue: 0.25, alpha: 0.7)
            cloud.strokeColor = .clear
            cloud.position = CGPoint(
                x: CGFloat.random(in: -15...15),
                y: 20 + CGFloat.random(in: -10...10)
            )
            cloud.zPosition = -1
            self.addChild(cloud)

            cloud.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: CGFloat.random(in: -40...40), y: CGFloat.random(in: 50...90), duration: 0.9),
                    SKAction.fadeOut(withDuration: 0.9),
                    SKAction.scale(to: CGFloat.random(in: 2.0...4.0), duration: 0.9)
                ]),
                SKAction.removeFromParent()
            ]))
        }
        run(SKAction.repeatForever(SKAction.sequence([
            spawnIntroGas,
            SKAction.wait(forDuration: 0.05) // 3× faster than normal
        ])), withKey: "introGasLeak")

        // Warning label
        let warningText = SKLabelNode(text: String(localized: "GAS LEAK DETECTED!"))
        warningText.fontSize = DynamicTypeScale.scaled(16)
        warningText.fontName = "Helvetica-Bold"
        warningText.fontColor = SKColor(red: 1.0, green: 0.2, blue: 0.15, alpha: 1.0)
        warningText.position = CGPoint(x: 0, y: -30)
        warningText.zPosition = 50
        warningText.alpha = 0
        warningText.name = "intro_warning"
        addChild(warningText)

        // Pulsing warning
        warningText.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.3),
            SKAction.fadeIn(withDuration: 0.15),
            SKAction.repeat(SKAction.sequence([
                SKAction.scale(to: 1.1, duration: 0.15),
                SKAction.scale(to: 0.95, duration: 0.15)
            ]), count: 3)
        ]))

        // After ~1.5s intro, transition to interactive phase
        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.5),
            SKAction.run { [weak self] in
                guard let self = self else { return }

                // Stop intense intro gas, switch to normal rate
                self.removeAction(forKey: "introGasLeak")

                // Fade out warning and pipe
                warningText.run(SKAction.sequence([
                    SKAction.fadeOut(withDuration: 0.3),
                    SKAction.removeFromParent()
                ]))
                pipe.run(SKAction.sequence([
                    SKAction.fadeAlpha(to: 0.3, duration: 0.3)
                ]))

                // Fade in valve, rings, UI elements
                let fadeIn = SKAction.fadeIn(withDuration: 0.3)
                self.valveWheel.run(fadeIn)
                self.progressRingBg.run(fadeIn)
                self.progressRing.run(fadeIn)
                self.instructionLabel.run(fadeIn)
                self.timerBarBg.run(fadeIn)
                self.timerBar.run(fadeIn)

                // Show hands gripping the valve
                self.handsNode.run(SKAction.fadeIn(withDuration: 0.2))
            },
            SKAction.wait(forDuration: 0.35),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                // Enable interaction and start timer
                self.isActive = true
                self.startGasLeakEffect()

                // Start timer with urgency updates
                let timerAction = SKAction.customAction(withDuration: self.timeLimit) { [weak self] _, elapsed in
                    guard let self = self, self.isActive else { return }
                    self.timeRemaining = self.timeLimit - TimeInterval(elapsed)
                    self.updateTimerBar()
                    self.updateUrgencyEffects()
                }
                self.run(SKAction.sequence([
                    timerAction,
                    SKAction.run { [weak self] in
                        guard let self = self, !self.isCompleted else { return }
                        self.failMiniGame()
                    }
                ]), withKey: "timer")
            }
        ]))
    }

    override func handleDrag(from start: CGPoint, to current: CGPoint) {
        guard isActive, !isCompleted, !isFailed else { return }

        // Calculate angle relative to valve center
        let centerInScene = convert(valveWheel.position, to: scene!)
        let currentAngle = atan2(current.y - centerInScene.y, current.x - centerInScene.x)

        // Grip squeeze on first touch
        if lastAngle == nil {
            handsNode.run(SKAction.scaleX(to: 0.95, duration: 0.05))
        }

        if let last = lastAngle {
            var delta = currentAngle - last
            // Normalize to avoid jumps
            if delta > .pi { delta -= .pi * 2 }
            if delta < -.pi { delta += .pi * 2 }

            // Track direction for resistance wobble
            let direction: CGFloat = delta < 0 ? -1 : 1

            // Resistance wobble when changing direction
            if direction != lastDirection && lastDirection != 0 && abs(delta) > 0.1 {
                // Small "stuck" wobble animation
                valveWheel.run(SKAction.sequence([
                    SKAction.rotate(byAngle: delta * 0.3, duration: 0.05),
                    SKAction.rotate(byAngle: -delta * 0.15, duration: 0.05)
                ]))
            }
            lastDirection = direction

            // Only count clockwise rotation (negative delta)
            if delta < 0 {
                totalRotation += abs(delta)
                valveWheel.zRotation += delta
                progress = min(totalRotation / fullRotationNeeded, 1.0)
                updateProgressRing()
                updateValveColor()

                // Metallic "click" every 45 degrees
                let currentClickStep = floor(totalRotation / clickInterval)
                if currentClickStep > floor(lastClickRotation / clickInterval) {
                    // Play subtle click haptic
                    HapticManager.shared.playCorrectFeedback()
                    // Brief scale "click" effect
                    valveWheel.run(SKAction.sequence([
                        SKAction.scale(to: 1.05, duration: 0.03),
                        SKAction.scale(to: 1.0, duration: 0.03)
                    ]))
                    // Hands squeeze pulse on click
                    handsNode.run(SKAction.sequence([
                        SKAction.scaleX(to: 0.93, duration: 0.03),
                        SKAction.scaleX(to: 0.95, duration: 0.03)
                    ]))
                }
                lastClickRotation = totalRotation

                // Progress-based haptic feedback
                let progressStep = floor(progress * 10)
                if progressStep > floor(lastHapticProgress * 10) {
                    HapticManager.shared.playCorrectFeedback()
                }
                lastHapticProgress = progress

                // Update instruction text with enthusiasm
                let pct = Int(progress * 100)
                if pct < 30 {
                    instructionLabel.text = String(localized: "\(pct)% — Turn faster!")
                } else if pct < 60 {
                    instructionLabel.text = String(localized: "\(pct)% — Keep going!")
                } else if pct < 90 {
                    instructionLabel.text = String(localized: "\(pct)% — Almost there!")
                } else {
                    instructionLabel.text = String(localized: "\(pct)% — Final push!")
                    startSteamEffectIfNeeded()
                }

                if progress >= requiredProgress {
                    completeMiniGame()
                }
            }
        }
        lastAngle = currentAngle
    }

    override func handleTouchEnded(at location: CGPoint) {
        lastAngle = nil
        // Hands relax
        handsNode.run(SKAction.scaleX(to: 1.0, duration: 0.1))
    }

    private func updateProgressRing() {
        let endAngle = -.pi / 2 + (.pi * 2 * progress)
        let path = CGMutablePath()
        path.addArc(center: .zero, radius: 55, startAngle: -.pi / 2, endAngle: endAngle, clockwise: false)
        progressRing.path = path

        // Color transitions: Red → Orange → Yellow → Green as progress increases
        let ringColor: SKColor
        if progress < 0.33 {
            // Red to Orange
            let t = progress / 0.33
            ringColor = SKColor(red: 0.9, green: 0.2 + t * 0.4, blue: 0.1, alpha: 1.0)
        } else if progress < 0.66 {
            // Orange to Yellow
            let t = (progress - 0.33) / 0.33
            ringColor = SKColor(red: 0.9, green: 0.6 + t * 0.3, blue: 0.1 * (1 - t), alpha: 1.0)
        } else {
            // Yellow to Green
            let t = (progress - 0.66) / 0.34
            ringColor = SKColor(red: 0.9 * (1 - t), green: 0.9 + t * 0.1, blue: 0.1 * (1 - t), alpha: 1.0)
        }
        progressRing.strokeColor = ringColor
        progressRing.glowWidth = 3 + progress * 5 // Glow intensifies
    }

    /// Updates the valve wheel color based on progress
    private func updateValveColor() {
        // Subtle color shift on the valve itself
        let tintColor: SKColor
        if progress < 0.5 {
            // Red range
            let t = progress * 2
            tintColor = SKColor(red: 1.0, green: 0.3 + t * 0.3, blue: 0.3, alpha: 1.0)
        } else {
            // Yellow to green range
            let t = (progress - 0.5) * 2
            tintColor = SKColor(red: 1.0 - t * 0.5, green: 0.6 + t * 0.4, blue: 0.3 * (1 - t), alpha: 1.0)
        }

        // Apply subtle tint using color blend
        valveWheel.color = tintColor
        valveWheel.colorBlendFactor = progress * 0.3 // Max 30% tint
    }

    private func updateTimerBar() {
        let fraction = CGFloat(timeRemaining / timeLimit)
        let maxWidth: CGFloat = 180
        let width = max(0, maxWidth * fraction)

        // Update timer bar path - center-based shrinking
        // The bar shrinks from both sides to stay centered
        let xOffset = (maxWidth - width) / 2 - 90
        timerBar.path = CGPath(roundedRect: CGRect(x: xOffset, y: -5, width: width, height: 10), cornerWidth: 5, cornerHeight: 5, transform: nil)

        // Color changes: Green → Yellow → Red as time runs out
        if fraction < 0.3 {
            timerBar.fillColor = SKColor(red: 0.9, green: 0.2, blue: 0.15, alpha: 1.0) // Red
        } else if fraction < 0.6 {
            timerBar.fillColor = SKColor(red: 1.0, green: 0.8, blue: 0.1, alpha: 1.0) // Yellow
        } else {
            timerBar.fillColor = SKColor(red: 0.3, green: 0.9, blue: 0.3, alpha: 1.0) // Green
        }
    }

    /// Updates urgency visual effects based on remaining time
    private func updateUrgencyEffects() {
        let fraction = CGFloat(timeRemaining / timeLimit)

        // Screen vignette darkens as time runs low
        if fraction < 0.4 {
            let vignetteAlpha = 0.3 * (1.0 - fraction / 0.4)
            vignetteNode.fillColor = SKColor(red: 0.3, green: 0, blue: 0, alpha: vignetteAlpha)
        }

        // Valve pulses faster as time runs low
        if fraction < 0.3 && valveWheel.action(forKey: "urgencyPulse") == nil {
            valveWheel.removeAction(forKey: "idlePulse")
            let urgencyPulse = SKAction.repeatForever(SKAction.sequence([
                SKAction.group([
                    SKAction.scale(to: 1.08, duration: 0.15),
                    SKAction.fadeAlpha(to: 0.8, duration: 0.15)
                ]),
                SKAction.group([
                    SKAction.scale(to: 1.0, duration: 0.15),
                    SKAction.fadeAlpha(to: 1.0, duration: 0.15)
                ])
            ]))
            valveWheel.run(urgencyPulse, withKey: "urgencyPulse")

            // Red flash on backdrop
            let flash = SKAction.sequence([
                SKAction.run { [weak self] in self?.backdrop.strokeColor = SKColor.red },
                SKAction.wait(forDuration: 0.2),
                SKAction.run { [weak self] in self?.backdrop.strokeColor = SKColor(red: 0.9, green: 0.2, blue: 0.1, alpha: 0.9) }
            ])
            run(flash)
        }
    }

    private func startGasLeakEffect() {
        let spawnGas = SKAction.run { [weak self] in
            guard let self = self, self.isActive else { return }
            let cloud = SKShapeNode(circleOfRadius: CGFloat.random(in: 4...10))
            cloud.fillColor = SKColor(red: 0.4, green: 0.5, blue: 0.3, alpha: 0.6)
            cloud.strokeColor = .clear
            cloud.position = CGPoint(
                x: CGFloat.random(in: -40...40),
                y: CGFloat.random(in: -20...20)
            )
            cloud.zPosition = -1
            self.addChild(cloud)

            cloud.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: CGFloat.random(in: -30...30), y: CGFloat.random(in: 60...100), duration: 1.2),
                    SKAction.fadeOut(withDuration: 1.2),
                    SKAction.scale(to: CGFloat.random(in: 1.5...3.0), duration: 1.2)
                ]),
                SKAction.removeFromParent()
            ]))
        }
        run(SKAction.repeatForever(SKAction.sequence([
            spawnGas,
            SKAction.wait(forDuration: 0.15)
        ])), withKey: "gasLeak")
    }

    /// Starts steam particle effect when near completion (progress > 90%)
    private func startSteamEffectIfNeeded() {
        guard steamEmitter == nil else { return }

        let emitter = SKEmitterNode()
        emitter.position = CGPoint(x: 0, y: 20)
        emitter.zPosition = 5

        // Steam bubble texture
        let steamSize = CGSize(width: 8, height: 8)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: steamSize, format: format)
        let image = renderer.image { context in
            let ctx = context.cgContext
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor(white: 1.0, alpha: 0.7).cgColor,
                    UIColor(white: 0.9, alpha: 0.4).cgColor,
                    UIColor(white: 0.8, alpha: 0.0).cgColor
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
        emitter.particleTexture = SKTexture(image: image)
        emitter.particleTexture?.filteringMode = .linear

        // Steam settings
        emitter.particleBirthRate = 15
        emitter.particleLifetime = 1.5
        emitter.particleLifetimeRange = 0.5
        emitter.yAcceleration = -80
        emitter.particleSpeed = 40
        emitter.particleSpeedRange = 20
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi / 3
        emitter.particleScale = 0.8
        emitter.particleScaleRange = 0.4
        emitter.particleScaleSpeed = 0.3
        emitter.particleAlpha = 0.6
        emitter.particleAlphaSpeed = -0.3
        emitter.particleBlendMode = .screen

        addChild(emitter)
        steamEmitter = emitter
    }

    /// Creates a direction arrow indicating clockwise rotation
    private func createDirectionArrow() -> SKNode {
        let container = SKNode()

        // Dotted circle (using small circles instead of lineDashPattern)
        let dotCount = 12
        let radius: CGFloat = 42
        for i in 0..<dotCount {
            let angle = CGFloat(i) * 2 * .pi / CGFloat(dotCount)
            let dot = SKShapeNode(circleOfRadius: 2)
            dot.fillColor = SKColor(white: 1.0, alpha: 0.3)
            dot.strokeColor = .clear
            dot.position = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            container.addChild(dot)
        }

        // Arrow head pointing clockwise direction
        let arrowPath = CGMutablePath()
        arrowPath.move(to: CGPoint(x: 45, y: 5))
        arrowPath.addLine(to: CGPoint(x: 38, y: 12))
        arrowPath.addLine(to: CGPoint(x: 38, y: -2))
        arrowPath.closeSubpath()

        let arrow = SKShapeNode(path: arrowPath)
        arrow.fillColor = SKColor(white: 1.0, alpha: 0.5)
        arrow.strokeColor = .clear
        container.addChild(arrow)

        return container
    }

    /// Creates a checkmark texture for completion
    private func createCheckmarkTexture() -> SKTexture {
        let size = CGSize(width: 50, height: 50)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2.0
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            let ctx = context.cgContext

            // Green circle background
            ctx.setFillColor(UIColor(red: 0.2, green: 0.8, blue: 0.3, alpha: 1.0).cgColor)
            ctx.fillEllipse(in: CGRect(x: 2, y: 2, width: 46, height: 46))

            // White checkmark
            ctx.setStrokeColor(UIColor.white.cgColor)
            ctx.setLineWidth(5)
            ctx.setLineCap(.round)
            ctx.setLineJoin(.round)
            ctx.move(to: CGPoint(x: 12, y: 25))
            ctx.addLine(to: CGPoint(x: 20, y: 35))
            ctx.addLine(to: CGPoint(x: 38, y: 15))
            ctx.strokePath()
        }

        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }

    private func completeMiniGame() {
        guard !isCompleted else { return }
        isCompleted = true
        isActive = false
        removeAction(forKey: "timer")
        removeAction(forKey: "gasLeak")
        valveWheel.removeAction(forKey: "urgencyPulse")
        valveWheel.removeAction(forKey: "idlePulse")

        // Stop steam emitter
        steamEmitter?.particleBirthRate = 0

        instructionLabel.text = String(localized: "✓ GAS SHUT OFF!")
        instructionLabel.fontColor = SKColor(red: 0.2, green: 0.9, blue: 0.3, alpha: 1.0)

        // Accessibility announcement
        UIAccessibility.post(notification: .announcement, argument: String(localized: "Gas valve turned off successfully!"))

        // Enhanced success sequence
        let successSequence = SKAction.sequence([
            // White flash on valve
            SKAction.run { [weak self] in
                guard let self = self else { return }
                let flash = SKShapeNode(circleOfRadius: 60)
                flash.fillColor = .white
                flash.strokeColor = .clear
                flash.alpha = 0.8
                flash.position = CGPoint(x: 0, y: 20)
                self.addChild(flash)
                flash.run(SKAction.sequence([
                    SKAction.fadeOut(withDuration: 0.2),
                    SKAction.removeFromParent()
                ]))
            },
            SKAction.wait(forDuration: 0.1),

            // "Clunk" shake animation - valve settles into locked position
            SKAction.run { [weak self] in
                guard let self = self else { return }
                // Stop any rotation and snap to nearest 90 degrees
                let currentRotation = self.valveWheel.zRotation
                let snappedRotation = round(currentRotation / (.pi / 2)) * (.pi / 2)

                self.valveWheel.run(SKAction.sequence([
                    // Quick settle
                    SKAction.rotate(toAngle: snappedRotation, duration: 0.1),
                    // Satisfaction shake
                    SKAction.sequence([
                        SKAction.moveBy(x: 2, y: 0, duration: 0.03),
                        SKAction.moveBy(x: -4, y: 0, duration: 0.03),
                        SKAction.moveBy(x: 3, y: 0, duration: 0.03),
                        SKAction.moveBy(x: -1, y: 0, duration: 0.03)
                    ]),
                    // Scale "pop" for satisfaction
                    SKAction.sequence([
                        SKAction.scale(to: 1.15, duration: 0.08),
                        SKAction.scale(to: 1.0, duration: 0.12)
                    ])
                ]))
            },
            SKAction.wait(forDuration: 0.15),

            // Hands release and fade out
            SKAction.run { [weak self] in
                guard let self = self else { return }
                // Hands separate outward and fade
                let leftHalf = SKAction.group([
                    SKAction.moveBy(x: -10, y: 0, duration: 0.3),
                    SKAction.fadeOut(withDuration: 0.3)
                ])
                self.handsNode.run(leftHalf)
            },
            SKAction.wait(forDuration: 0.15),

            // Checkmark appears and scales up
            SKAction.run { [weak self] in
                guard let self = self else { return }
                self.checkmarkNode.setScale(0.1)
                self.checkmarkNode.alpha = 1.0
                self.checkmarkNode.run(SKAction.sequence([
                    SKAction.scale(to: 1.3, duration: 0.15),
                    SKAction.scale(to: 1.0, duration: 0.1)
                ]))
            },
            SKAction.wait(forDuration: 0.1),

            // Green ring flash
            SKAction.run { [weak self] in
                guard let self = self else { return }
                self.progressRing.strokeColor = SKColor(red: 0.2, green: 1.0, blue: 0.3, alpha: 1.0)
                self.progressRing.glowWidth = 10
                self.progressRing.run(SKAction.sequence([
                    SKAction.fadeOut(withDuration: 0.3),
                    SKAction.fadeIn(withDuration: 0.1)
                ]))
            }
        ])

        run(successSequence)

        // Haptic and audio feedback
        HapticManager.shared.playCorrectFeedback()
        AudioManager.shared.playCorrect()

        // Sparkle burst
        let sparkles = ParticleEffects.correctDecisionSparkles(at: CGPoint(x: 0, y: 20), count: 16)
        addChild(sparkles)
        sparkles.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.removeFromParent()
        ]))

        // Completion delay then dismiss
        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.2),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                self.miniGameDelegate?.miniGameDidComplete(self, action: .shutOffGas)
                self.dismiss()
            }
        ]))
    }

    private func failMiniGame() {
        guard !isFailed, !isCompleted else { return }
        isFailed = true
        isActive = false
        removeAction(forKey: "gasLeak")
        valveWheel.removeAction(forKey: "urgencyPulse")
        valveWheel.removeAction(forKey: "idlePulse")

        instructionLabel.text = String(localized: "⚠️ TOO SLOW!")
        instructionLabel.fontColor = SKColor(red: 1.0, green: 0.2, blue: 0.15, alpha: 1.0)

        // Accessibility announcement
        UIAccessibility.post(notification: .announcement, argument: String(localized: "Failed to turn off gas valve in time."))

        // Enhanced fail animation
        let failSequence = SKAction.sequence([
            // Red flash
            SKAction.run { [weak self] in
                guard let self = self else { return }
                self.backdrop.strokeColor = SKColor.red
                self.backdrop.fillColor = SKColor(red: 0.3, green: 0, blue: 0, alpha: 0.9)

                // Screen shake
                self.run(SKAction.sequence([
                    SKAction.moveBy(x: 5, y: 0, duration: 0.05),
                    SKAction.moveBy(x: -10, y: 0, duration: 0.05),
                    SKAction.moveBy(x: 8, y: 0, duration: 0.05),
                    SKAction.moveBy(x: -3, y: 0, duration: 0.05)
                ]))
            },
            SKAction.wait(forDuration: 0.1),
            // Valve drops
            SKAction.run { [weak self] in
                guard let self = self else { return }
                self.valveWheel.run(SKAction.sequence([
                    SKAction.scale(to: 0.9, duration: 0.2),
                    SKAction.rotate(byAngle: 0.3, duration: 0.2)
                ]))
            }
        ])

        run(failSequence)

        HapticManager.shared.playImpact()
        AudioManager.shared.playWrong()

        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                self.miniGameDelegate?.miniGameDidFail(self, action: .shutOffGas)
                self.dismiss()
            }
        ]))
    }
}

// MARK: - Safe Exit Mini-Game (Clear Debris)

/// After the earthquake, debris blocks the exit. Player must tap 3 debris pieces
/// to clear them away. Each piece has a visual indicator and slides away when tapped.
final class SafeExitMiniGame: MiniGameNode {
    private let backdrop: SKShapeNode
    private let instructionLabel: SKLabelNode
    private let progressLabel: SKLabelNode
    private var debrisPieces: [SKNode] = []
    private var clearedCount = 0
    private let totalDebris = 3
    private var timeRemaining: TimeInterval = 7.0
    private let timeLimit: TimeInterval = 7.0
    private let timerBar: SKShapeNode
    private let timerBarBg: SKShapeNode
    private var isActive = false

    init() {
        backdrop = SKShapeNode(rectOf: CGSize(width: 280, height: 300), cornerRadius: 20)
        backdrop.fillColor = SKColor(white: 0, alpha: 0.85)
        backdrop.strokeColor = AppColors.skCorrect.withAlphaComponent(0.8)
        backdrop.lineWidth = 3

        instructionLabel = SKLabelNode(text: String(localized: "TAP debris to clear the exit!"))
        instructionLabel.fontSize = DynamicTypeScale.scaled(14)
        instructionLabel.fontName = "Helvetica-Bold"
        instructionLabel.fontColor = .white

        progressLabel = SKLabelNode(text: String(localized: "0 / 3 cleared"))
        progressLabel.fontSize = DynamicTypeScale.scaled(13)
        progressLabel.fontName = "Helvetica"
        progressLabel.fontColor = SKColor(white: 0.7, alpha: 1)

        timerBarBg = SKShapeNode(rectOf: CGSize(width: 200, height: 8), cornerRadius: 4)
        timerBarBg.fillColor = SKColor(white: 0.3, alpha: 1)
        timerBarBg.strokeColor = .clear

        timerBar = SKShapeNode(rectOf: CGSize(width: 200, height: 8), cornerRadius: 4)
        timerBar.fillColor = AppColors.skCorrect
        timerBar.strokeColor = .clear

        super.init(action: .findSafeExit)
    }

    override func present(in scene: SKScene) {
        if let camera = scene.camera {
            position = camera.position
        } else {
            position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        }

        // Accessibility announcement
        UIAccessibility.post(notification: .announcement, argument: String(localized: "Clear the exit mini-game. Tap the three debris pieces blocking the door to clear a path. You have 7 seconds."))

        backdrop.position = .zero
        addChild(backdrop)

        let titleLabel = SKLabelNode(text: String(localized: "CLEAR THE EXIT"))
        titleLabel.fontSize = DynamicTypeScale.scaled(16)
        titleLabel.fontName = "Helvetica-Bold"
        titleLabel.fontColor = AppColors.skCorrect
        titleLabel.position = CGPoint(x: 0, y: 120)
        addChild(titleLabel)

        // Door frame outline
        let doorFrame = SKShapeNode(rectOf: CGSize(width: 100, height: 140), cornerRadius: 4)
        doorFrame.fillColor = SKColor(red: 0.3, green: 0.2, blue: 0.15, alpha: 0.6)
        doorFrame.strokeColor = SKColor(white: 0.5, alpha: 0.6)
        doorFrame.lineWidth = 2
        doorFrame.position = CGPoint(x: 0, y: 10)
        addChild(doorFrame)

        // Exit sign above door
        let exitSign = SKLabelNode(text: String(localized: "EXIT"))
        exitSign.fontSize = DynamicTypeScale.scaled(11)
        exitSign.fontName = "Helvetica-Bold"
        exitSign.fontColor = AppColors.skCorrect
        exitSign.position = CGPoint(x: 0, y: 85)
        addChild(exitSign)

        // Create debris pieces blocking the door
        createDebrisPieces()

        instructionLabel.position = CGPoint(x: 0, y: -80)
        addChild(instructionLabel)

        progressLabel.position = CGPoint(x: 0, y: -100)
        addChild(progressLabel)

        timerBarBg.position = CGPoint(x: 0, y: -125)
        addChild(timerBarBg)
        timerBar.position = CGPoint(x: 0, y: -125)
        addChild(timerBar)

        isActive = true

        // Timer
        let timerAction = SKAction.customAction(withDuration: timeLimit) { [weak self] _, elapsed in
            guard let self = self, self.isActive else { return }
            self.timeRemaining = self.timeLimit - TimeInterval(elapsed)
            self.updateTimerBar()
        }
        run(SKAction.sequence([
            timerAction,
            SKAction.run { [weak self] in
                guard let self = self, !self.isCompleted else { return }
                self.failMiniGame()
            }
        ]), withKey: "timer")

        super.present(in: scene)
    }

    private func createDebrisPieces() {
        let debrisConfigs: [(CGPoint, CGSize, CGFloat, SKColor, String)] = [
            (CGPoint(x: -20, y: 30), CGSize(width: 60, height: 20), 0.2, SKColor(red: 0.5, green: 0.35, blue: 0.2, alpha: 1), "Beam"),
            (CGPoint(x: 15, y: -10), CGSize(width: 40, height: 35), -0.15, SKColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1), "Concrete"),
            (CGPoint(x: -5, y: -45), CGSize(width: 55, height: 18), 0.3, SKColor(red: 0.45, green: 0.3, blue: 0.18, alpha: 1), "Plank"),
        ]

        for (i, config) in debrisConfigs.enumerated() {
            let (pos, size, rotation, color, label) = config

            let container = SKNode()
            container.position = pos
            container.zPosition = CGFloat(10 + i)
            container.zRotation = rotation
            container.name = "debris_piece_\(i)"

            // Debris shape
            let piece = SKShapeNode(rectOf: size, cornerRadius: 3)
            piece.fillColor = color
            piece.strokeColor = CartoonPalette.outline.skColor
            piece.lineWidth = 2
            container.addChild(piece)

            // Crack lines for detail
            let crack = SKShapeNode()
            let crackPath = CGMutablePath()
            crackPath.move(to: CGPoint(x: -size.width/3, y: size.height/4))
            crackPath.addLine(to: CGPoint(x: 0, y: -size.height/4))
            crackPath.addLine(to: CGPoint(x: size.width/4, y: size.height/3))
            crack.path = crackPath
            crack.strokeColor = SKColor(white: 0, alpha: 0.3)
            crack.lineWidth = 1
            container.addChild(crack)

            // Label
            let debrisLabel = SKLabelNode(text: label)
            debrisLabel.fontSize = DynamicTypeScale.scaled(9)
            debrisLabel.fontName = "Helvetica"
            debrisLabel.fontColor = SKColor(white: 1, alpha: HighContrast.isEnabled ? 1.0 : 0.7)
            debrisLabel.position = CGPoint(x: 0, y: -size.height/2 - 10)
            debrisLabel.zRotation = -rotation
            container.addChild(debrisLabel)

            // Pulsing highlight to indicate tappable
            let highlight = SKShapeNode(rectOf: CGSize(width: size.width + 12, height: size.height + 12), cornerRadius: 6)
            highlight.fillColor = .clear
            highlight.strokeColor = SKColor(red: 1, green: 1, blue: 0.3, alpha: 0.6)
            highlight.lineWidth = 2
            highlight.name = "highlight"
            container.addChild(highlight)

            highlight.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.2, duration: 0.5),
                SKAction.fadeAlpha(to: 0.8, duration: 0.5)
            ])))

            addChild(container)
            debrisPieces.append(container)
        }
    }

    override func handleTouch(at location: CGPoint) {
        guard isActive, !isCompleted, !isFailed else { return }

        let localPoint = convert(location, from: scene!)

        for (index, piece) in debrisPieces.enumerated() {
            guard piece.parent != nil else { continue }

            // Check if tap is within debris bounds (generous hit area)
            let pieceFrame = piece.calculateAccumulatedFrame()
            let expandedFrame = pieceFrame.insetBy(dx: -15, dy: -15)

            if expandedFrame.contains(localPoint) {
                clearDebrisPiece(piece, index: index)
                return
            }
        }
    }

    private func clearDebrisPiece(_ piece: SKNode, index: Int) {
        // Remove highlight
        piece.childNode(withName: "highlight")?.removeFromParent()

        clearedCount += 1
        progressLabel.text = String(localized: "\(clearedCount) / \(totalDebris) cleared")

        HapticManager.shared.playImpact()

        // Fly away animation
        let flyDirection: CGFloat = index % 2 == 0 ? -1 : 1
        piece.run(SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: flyDirection * 200, y: CGFloat.random(in: 30...80), duration: 0.4),
                SKAction.rotate(byAngle: flyDirection * .pi, duration: 0.4),
                SKAction.fadeOut(withDuration: 0.4),
                SKAction.scale(to: 0.5, duration: 0.4)
            ]),
            SKAction.removeFromParent()
        ]))

        // Dust puff at debris position
        for _ in 0..<4 {
            let dust = SKShapeNode(circleOfRadius: CGFloat.random(in: 3...7))
            dust.fillColor = SKColor(white: 0.7, alpha: 0.5)
            dust.strokeColor = .clear
            dust.position = piece.position
            dust.zPosition = 5
            addChild(dust)
            dust.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: CGFloat.random(in: -25...25), y: CGFloat.random(in: 10...30), duration: 0.5),
                    SKAction.fadeOut(withDuration: 0.5)
                ]),
                SKAction.removeFromParent()
            ]))
        }

        if clearedCount >= totalDebris {
            completeMiniGame()
        }
    }

    private func updateTimerBar() {
        let fraction = CGFloat(timeRemaining / timeLimit)
        let width = max(0, 200 * fraction)
        timerBar.path = CGPath(roundedRect: CGRect(x: -100, y: -4, width: width, height: 8), cornerWidth: 4, cornerHeight: 4, transform: nil)

        if fraction < 0.3 {
            timerBar.fillColor = AppColors.skWrong
        } else if fraction < 0.6 {
            timerBar.fillColor = AppColors.skWarning
        }
    }

    private func completeMiniGame() {
        guard !isCompleted else { return }
        isCompleted = true
        isActive = false
        removeAction(forKey: "timer")

        instructionLabel.text = String(localized: "Exit cleared!")
        instructionLabel.fontColor = AppColors.skCorrect
        progressLabel.text = String(localized: "Path is safe!")

        // Accessibility announcement
        UIAccessibility.post(notification: .announcement, argument: String(localized: "Exit path cleared successfully."))

        HapticManager.shared.playCorrectFeedback()
        AudioManager.shared.playCorrect()

        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.6),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                self.miniGameDelegate?.miniGameDidComplete(self, action: .findSafeExit)
                self.dismiss()
            }
        ]))
    }

    private func failMiniGame() {
        guard !isFailed, !isCompleted else { return }
        isFailed = true
        isActive = false

        instructionLabel.text = String(localized: "Too slow!")
        instructionLabel.fontColor = AppColors.skWrong
        backdrop.strokeColor = AppColors.skWrong

        // Accessibility announcement
        UIAccessibility.post(notification: .announcement, argument: String(localized: "Failed to clear exit path in time."))

        HapticManager.shared.playImpact()
        AudioManager.shared.playWrong()

        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.8),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                self.miniGameDelegate?.miniGameDidFail(self, action: .findSafeExit)
                self.dismiss()
            }
        ]))
    }
}

// MARK: - Injury Check Mini-Game
// Note: The InjuryCheckMiniGame class has been moved to InjuryCheckMiniGame.swift
// with enhanced anatomical wound visualization, particle effects, and animations.

// MARK: - UIColor SKColor Bridge

private extension UIColor {
    var skColor: SKColor {
        SKColor(cgColor: cgColor)
    }
}

private extension SKColor {
    func withAlphaComponent(_ alpha: CGFloat) -> SKColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return SKColor(red: r, green: g, blue: b, alpha: alpha)
    }
}
