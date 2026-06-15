import SpriteKit
import UIKit

// MARK: - Injury Check Mini-Game (Treatment Sequence)

/// Shows an injury and presents 3 treatment steps that must be tapped in the correct order.
/// Features anatomical wound visualization, healing progression animations, and particle effects.
/// Wrong order = penalty shake + retry. Correct sequence = complete with celebration.
@MainActor
final class InjuryCheckMiniGame: MiniGameNode {
    private let backdrop: SKShapeNode
    private let instructionLabel: SKLabelNode
    private let stepIndicator: SKLabelNode
    private let titleLabel: SKLabelNode
    private var stepButtons: [SKNode] = []
    private var currentStep = 0
    private let totalSteps = 3
    private var timeRemaining: TimeInterval = 8.0
    private let timeLimit: TimeInterval = 8.0
    private let timerBar: SKShapeNode
    private let timerBarBg: SKShapeNode
    private let urgencyOverlay: SKShapeNode
    private var isActive = false
    private var mistakes = 0
    private var woundContainer: SKNode?
    private var woundMark: SKShapeNode?
    private var woundGlow: SKShapeNode?
    private var progressLine: SKShapeNode?
    private var completedSteps: [Int] = []

    private let steps: [(icon: String, label: String, color: SKColor)] = [
        ("💧", String(localized: "Clean"), SKColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 1)),
        ("🩹", String(localized: "Bandage"), SKColor(red: 1.0, green: 0.85, blue: 0.6, alpha: 1)),
        ("✋", String(localized: "Secure"), SKColor(red: 0.3, green: 0.9, blue: 0.4, alpha: 1))
    ]

    init() {
        backdrop = SKShapeNode(rectOf: CGSize(width: 300, height: 360), cornerRadius: 24)
        backdrop.fillColor = SKColor(white: 0.08, alpha: 0.92)
        backdrop.strokeColor = SKColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 0.8)
        backdrop.lineWidth = 3

        titleLabel = SKLabelNode(text: String(localized: "TREAT INJURY"))
        titleLabel.fontSize = DynamicTypeScale.scaled(18)
        titleLabel.fontName = "Helvetica-Bold"
        titleLabel.fontColor = SKColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 1)

        instructionLabel = SKLabelNode(text: String(localized: "Tap steps in order!"))
        instructionLabel.fontSize = DynamicTypeScale.scaled(14)
        instructionLabel.fontName = "Helvetica-Bold"
        instructionLabel.fontColor = .white

        stepIndicator = SKLabelNode(text: String(localized: "Step 1 of 3"))
        stepIndicator.fontSize = DynamicTypeScale.scaled(12)
        stepIndicator.fontName = "Helvetica"
        stepIndicator.fontColor = SKColor(white: HighContrast.isEnabled ? 0.9 : 0.6, alpha: 1)

        timerBarBg = SKShapeNode(rectOf: CGSize(width: 220, height: 10), cornerRadius: 5)
        timerBarBg.fillColor = SKColor(white: 0.25, alpha: 1)
        timerBarBg.strokeColor = .clear

        timerBar = SKShapeNode(rectOf: CGSize(width: 220, height: 10), cornerRadius: 5)
        timerBar.fillColor = SKColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 1)
        timerBar.strokeColor = .clear

        // Urgency overlay for low time
        urgencyOverlay = SKShapeNode(rectOf: CGSize(width: 400, height: 400))
        urgencyOverlay.fillColor = SKColor(red: 0.9, green: 0.2, blue: 0.15, alpha: 0)
        urgencyOverlay.strokeColor = .clear
        urgencyOverlay.zPosition = -5
        urgencyOverlay.alpha = 0

        super.init(action: .checkInjuries)
    }

    override func present(in scene: SKScene) {
        if let camera = scene.camera {
            position = camera.position
        } else {
            position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        }

        // Accessibility announcement
        UIAccessibility.post(notification: .announcement, argument: String(localized: "Injury treatment mini-game. Tap the treatment steps in the correct order: Clean, then Bandage, then Secure. You have 8 seconds."))

        backdrop.position = .zero
        addChild(backdrop)
        addChild(urgencyOverlay)

        titleLabel.position = CGPoint(x: 0, y: 145)
        addChild(titleLabel)

        // Create anatomical arm/hand with wound visualization
        createAnatomicalWound()

        // Treatment step buttons (shown shuffled for challenge)
        let shuffledOrder = [1, 2, 0] // Pre-shuffled: Bandage, Secure, Clean — correct is 0,1,2
        let buttonY: CGFloat = -30

        // Progress connection line
        let linePath = CGMutablePath()
        linePath.move(to: CGPoint(x: -85, y: buttonY))
        linePath.addLine(to: CGPoint(x: 85, y: buttonY))
        progressLine = SKShapeNode(path: linePath)
        progressLine?.strokeColor = SKColor(white: 0.3, alpha: 0.5)
        progressLine?.lineWidth = 2
        progressLine?.zPosition = 5
        addChild(progressLine!)

        for (displayIndex, stepIndex) in shuffledOrder.enumerated() {
            let step = steps[stepIndex]

            let container = SKNode()
            let xPos = CGFloat(displayIndex - 1) * 85
            container.position = CGPoint(x: xPos, y: buttonY)
            container.zPosition = 10
            container.name = "step_\(stepIndex)"

            // Button background with gradient effect
            let bg = SKShapeNode(rectOf: CGSize(width: 76, height: 90), cornerRadius: 14)
            bg.fillColor = SKColor(white: 0.15, alpha: 1)
            bg.strokeColor = step.color.withAlphaComponent(0.6)
            bg.lineWidth = 3
            bg.name = "step_bg"
            container.addChild(bg)

            // Inner glow
            let innerGlow = SKShapeNode(rectOf: CGSize(width: 68, height: 82), cornerRadius: 10)
            innerGlow.fillColor = step.color.withAlphaComponent(0.1)
            innerGlow.strokeColor = .clear
            innerGlow.name = "step_inner_glow"
            container.addChild(innerGlow)

            // Icon with shadow for depth
            let iconShadow = SKLabelNode(text: step.icon)
            iconShadow.fontSize = DynamicTypeScale.scaled(32)
            iconShadow.position = CGPoint(x: 1, y: 7)
            iconShadow.verticalAlignmentMode = .center
            iconShadow.fontColor = SKColor.black.withAlphaComponent(0.3)
            container.addChild(iconShadow)

            let icon = SKLabelNode(text: step.icon)
            icon.fontSize = DynamicTypeScale.scaled(32)
            icon.position = CGPoint(x: 0, y: 8)
            icon.verticalAlignmentMode = .center
            icon.name = "step_icon"
            container.addChild(icon)

            // Label
            let label = SKLabelNode(text: step.label)
            label.fontSize = DynamicTypeScale.scaled(12)
            label.fontName = "Helvetica-Bold"
            label.fontColor = step.color
            label.position = CGPoint(x: 0, y: -28)
            container.addChild(label)

            // Step number hint with circle background
            let hintBg = SKShapeNode(circleOfRadius: 10)
            hintBg.fillColor = SKColor(white: 0.25, alpha: 1)
            hintBg.strokeColor = step.color.withAlphaComponent(0.4)
            hintBg.lineWidth = 1
            hintBg.position = CGPoint(x: 0, y: -45)
            container.addChild(hintBg)

            let hint = SKLabelNode(text: "\(stepIndex + 1)")
            hint.fontSize = DynamicTypeScale.scaled(10)
            hint.fontName = "Helvetica-Bold"
            hint.fontColor = SKColor(white: 0.7, alpha: 1)
            hint.verticalAlignmentMode = .center
            hint.position = CGPoint(x: 0, y: -45)
            container.addChild(hint)

            // Selection indicator (hidden initially)
            let selectionRing = SKShapeNode(rectOf: CGSize(width: 84, height: 98), cornerRadius: 16)
            selectionRing.strokeColor = AppColors.skCorrect
            selectionRing.lineWidth = 3
            selectionRing.fillColor = .clear
            selectionRing.alpha = 0
            selectionRing.name = "selection_ring"
            container.addChild(selectionRing)

            addChild(container)
            stepButtons.append(container)
        }

        instructionLabel.position = CGPoint(x: 0, y: -85)
        addChild(instructionLabel)

        stepIndicator.position = CGPoint(x: 0, y: -105)
        addChild(stepIndicator)

        timerBarBg.position = CGPoint(x: 0, y: -135)
        addChild(timerBarBg)
        timerBar.position = CGPoint(x: 0, y: -135)
        addChild(timerBar)

        isActive = true

        // Timer with urgency effects
        let timerAction = SKAction.customAction(withDuration: timeLimit) { [weak self] _, elapsed in
            guard let self = self, self.isActive else { return }
            self.timeRemaining = self.timeLimit - TimeInterval(elapsed)
            self.updateTimerBar()
            self.updateUrgencyEffects()
        }
        run(SKAction.sequence([
            timerAction,
            SKAction.run { [weak self] in
                guard let self = self, !self.isCompleted else { return }
                self.failMiniGame()
            }
        ]), withKey: "timer")

        // Entrance animation for wound
        woundContainer?.setScale(0.8)
        woundContainer?.alpha = 0
        woundContainer?.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.2),
            SKAction.group([
                SKAction.fadeIn(withDuration: 0.3),
                SKAction.scale(to: 1.0, duration: 0.3)
            ])
        ]))

        super.present(in: scene)
    }

    private func createAnatomicalWound() {
        let container = SKNode()
        container.position = CGPoint(x: 0, y: 65)
        container.name = "wound_container"
        woundContainer = container

        // Arm/hand base shape (anatomical)
        let armBg = SKShapeNode()
        let armPath = CGMutablePath()

        // Wrist area (left side)
        armPath.move(to: CGPoint(x: -70, y: -15))
        armPath.addCurve(to: CGPoint(x: -60, y: 25),
                         control1: CGPoint(x: -70, y: 0),
                         control2: CGPoint(x: -68, y: 15))

        // Back of hand going toward knuckles
        armPath.addCurve(to: CGPoint(x: 40, y: 30),
                         control1: CGPoint(x: -30, y: 35),
                         control2: CGPoint(x: 10, y: 38))

        // Knuckle ridge
        armPath.addCurve(to: CGPoint(x: 55, y: 25),
                         control1: CGPoint(x: 48, y: 30),
                         control2: CGPoint(x: 52, y: 28))

        // Between knuckles dip
        armPath.addCurve(to: CGPoint(x: 65, y: 28),
                         control1: CGPoint(x: 58, y: 22),
                         control2: CGPoint(x: 62, y: 24))

        // Second knuckle
        armPath.addCurve(to: CGPoint(x: 75, y: 22),
                         control1: CGPoint(x: 68, y: 32),
                         control2: CGPoint(x: 72, y: 26))

        // Finger base tapering
        armPath.addCurve(to: CGPoint(x: 85, y: 15),
                         control1: CGPoint(x: 80, y: 18),
                         control2: CGPoint(x: 83, y: 16))

        // Bottom of fingers going back
        armPath.addLine(to: CGPoint(x: 85, y: -5))

        // Bottom of hand
        armPath.addCurve(to: CGPoint(x: -60, y: -25),
                         control1: CGPoint(x: 30, y: -35),
                         control2: CGPoint(x: -20, y: -32))

        // Back to wrist
        armPath.addCurve(to: CGPoint(x: -70, y: -15),
                         control1: CGPoint(x: -65, y: -22),
                         control2: CGPoint(x: -68, y: -18))

        armPath.closeSubpath()
        armBg.path = armPath
        armBg.fillColor = SKColor(red: 0.96, green: 0.87, blue: 0.78, alpha: 1) // Skin tone
        armBg.strokeColor = SKColor(red: 0.75, green: 0.60, blue: 0.50, alpha: 0.9)
        armBg.lineWidth = HighContrast.isEnabled ? 3 : 2
        container.addChild(armBg)

        // Skin shading gradient effect (subtle)
        let shading = SKShapeNode()
        let shadingPath = CGMutablePath()
        shadingPath.move(to: CGPoint(x: -50, y: -10))
        shadingPath.addCurve(to: CGPoint(x: 30, y: 15),
                             control1: CGPoint(x: -10, y: 0),
                             control2: CGPoint(x: 10, y: 10))
        shadingPath.addCurve(to: CGPoint(x: 60, y: 5),
                             control1: CGPoint(x: 45, y: 18),
                             control2: CGPoint(x: 55, y: 10))
        shadingPath.addCurve(to: CGPoint(x: -30, y: -20),
                             control1: CGPoint(x: 20, y: -10),
                             control2: CGPoint(x: -10, y: -18))
        shadingPath.closeSubpath()
        shading.path = shadingPath
        shading.fillColor = SKColor(red: 0.88, green: 0.75, blue: 0.65, alpha: 0.3)
        shading.strokeColor = .clear
        container.addChild(shading)

        // Wound glow (healing aura)
        let glow = SKShapeNode()
        let glowPath = CGMutablePath()
        glowPath.move(to: CGPoint(x: -15, y: -5))
        glowPath.addCurve(to: CGPoint(x: 25, y: -8),
                          control1: CGPoint(x: 5, y: 5),
                          control2: CGPoint(x: 15, y: 2))
        glowPath.addCurve(to: CGPoint(x: 15, y: -15),
                          control1: CGPoint(x: 22, y: -12),
                          control2: CGPoint(x: 18, y: -14))
        glowPath.addCurve(to: CGPoint(x: -15, y: -5),
                          control1: CGPoint(x: 0, y: -12),
                          control2: CGPoint(x: -8, y: -8))
        glowPath.closeSubpath()
        glow.path = glowPath
        glow.fillColor = SKColor(red: 0.9, green: 0.2, blue: 0.15, alpha: 0.15)
        glow.strokeColor = .clear
        glow.alpha = 0
        glow.name = "wound_glow"
        woundGlow = glow
        container.addChild(glow)

        // Main wound gash (realistic shape)
        let wound = SKShapeNode()
        let woundPath = CGMutablePath()
        woundPath.move(to: CGPoint(x: -12, y: 0))
        woundPath.addCurve(to: CGPoint(x: 22, y: -3),
                           control1: CGPoint(x: 3, y: 8),
                           control2: CGPoint(x: 12, y: 5))
        woundPath.addCurve(to: CGPoint(x: 18, y: -8),
                           control1: CGPoint(x: 20, y: -5),
                           control2: CGPoint(x: 19, y: -7))
        woundPath.addCurve(to: CGPoint(x: -12, y: 0),
                           control1: CGPoint(x: 2, y: -6),
                           control2: CGPoint(x: -5, y: -3))
        woundPath.closeSubpath()

        wound.path = woundPath
        wound.fillColor = SKColor(red: 0.75, green: 0.1, blue: 0.08, alpha: 0.8)
        wound.strokeColor = SKColor(red: 0.85, green: 0.15, blue: 0.1, alpha: 1)
        wound.lineWidth = HighContrast.isEnabled ? 2.5 : 1.5
        wound.name = "wound"
        woundMark = wound
        container.addChild(wound)

        // Wound depth shadow
        let woundDepth = SKShapeNode()
        let depthPath = CGMutablePath()
        depthPath.move(to: CGPoint(x: -10, y: -1))
        depthPath.addCurve(to: CGPoint(x: 20, y: -4),
                           control1: CGPoint(x: 4, y: 5),
                           control2: CGPoint(x: 11, y: 3))
        depthPath.addCurve(to: CGPoint(x: -10, y: -1),
                           control1: CGPoint(x: 5, y: -4),
                           control2: CGPoint(x: -2, y: -2))
        depthPath.closeSubpath()
        woundDepth.path = depthPath
        woundDepth.fillColor = SKColor(red: 0.5, green: 0.05, blue: 0.03, alpha: 0.6)
        woundDepth.strokeColor = .clear
        woundDepth.name = "wound_depth"
        container.addChild(woundDepth)

        // Blood drops/details
        for i in 0..<3 {
            let drop = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...2.5))
            drop.fillColor = SKColor(red: 0.7, green: 0.08, blue: 0.05, alpha: 0.8)
            drop.strokeColor = .clear
            let offsetX = CGFloat.random(in: -5...15)
            let offsetY = CGFloat.random(in: -12...(-5))
            drop.position = CGPoint(x: offsetX, y: offsetY)
            drop.name = "blood_drop_\(i)"
            container.addChild(drop)
        }

        // Inflammation around wound (redness)
        let inflammation = SKShapeNode()
        let inflamPath = CGMutablePath()
        inflamPath.move(to: CGPoint(x: -20, y: -5))
        inflamPath.addCurve(to: CGPoint(x: 30, y: -8),
                            control1: CGPoint(x: 5, y: 12),
                            control2: CGPoint(x: 18, y: 8))
        inflamPath.addCurve(to: CGPoint(x: 25, y: -20),
                            control1: CGPoint(x: 28, y: -12),
                            control2: CGPoint(x: 26, y: -16))
        inflamPath.addCurve(to: CGPoint(x: -20, y: -5),
                            control1: CGPoint(x: 0, y: -16),
                            control2: CGPoint(x: -10, y: -12))
        inflamPath.closeSubpath()
        inflammation.path = inflamPath
        inflammation.fillColor = SKColor(red: 0.9, green: 0.3, blue: 0.2, alpha: 0.15)
        inflammation.strokeColor = .clear
        inflammation.name = "inflammation"
        container.addChild(inflammation)

        addChild(container)
    }

    override func handleTouch(at location: CGPoint) {
        guard isActive, !isCompleted, !isFailed else { return }

        let localPoint = convert(location, from: scene!)

        for button in stepButtons {
            guard button.parent != nil else { continue }

            let buttonFrame = button.calculateAccumulatedFrame()
            let expandedFrame = buttonFrame.insetBy(dx: -10, dy: -10)

            if expandedFrame.contains(localPoint) {
                let stepName = button.name ?? ""
                let tappedStepIndex = Int(stepName.replacingOccurrences(of: "step_", with: "")) ?? -1

                if tappedStepIndex == currentStep {
                    correctStepTapped(button, stepIndex: tappedStepIndex)
                } else {
                    wrongStepTapped(button)
                }
                return
            }
        }
    }

    private func correctStepTapped(_ button: SKNode, stepIndex: Int) {
        currentStep += 1
        completedSteps.append(stepIndex)
        stepIndicator.text = currentStep < totalSteps ? String(localized: "Step \(currentStep + 1) of \(totalSteps)") : String(localized: "Complete!")

        let step = steps[stepIndex]

        // Button press animation
        button.run(SKAction.sequence([
            SKAction.scale(to: 0.9, duration: 0.05),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))

        // Green flash on button
        if let bg = button.childNode(withName: "step_bg") as? SKShapeNode {
            bg.fillColor = AppColors.skCorrect.withAlphaComponent(0.4)
            bg.strokeColor = AppColors.skCorrect

            // Spring back to normal after delay
            bg.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.3),
                SKAction.run { bg.fillColor = step.color.withAlphaComponent(0.1) }
            ]))
        }

        // Show selection ring
        if let ring = button.childNode(withName: "selection_ring") {
            ring.alpha = 1
            ring.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.5),
                SKAction.run { ring.alpha = 0 }
            ]))
        }

        // Animated checkmark
        let check = SKLabelNode(text: "✓")
        check.fontSize = DynamicTypeScale.scaled(36)
        check.fontColor = AppColors.skCorrect
        check.fontName = "Helvetica-Bold"
        check.position = CGPoint(x: 0, y: 5)
        check.zPosition = 20
        check.setScale(0)
        button.addChild(check)
        check.run(SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.15)
        ]))

        // Add connecting line to progress
        updateProgressLine()

        // Step-specific effects
        switch stepIndex {
        case 0: // Clean - water splash particles
            playWaterSplashEffect()
        case 1: // Bandage - wrap effect
            playBandageWrapEffect()
        case 2: // Secure - healing sparkles
            playHealingSparklesEffect()
        default:
            break
        }

        // Update wound visualization
        updateWoundProgress(stepIndex)

        HapticManager.shared.playCorrectFeedback()

        // Disable the button visually with fade
        button.run(SKAction.fadeAlpha(to: 0.5, duration: 0.2))
        button.isUserInteractionEnabled = false

        if currentStep >= totalSteps {
            completeMiniGame()
        }
    }

    private func wrongStepTapped(_ button: SKNode) {
        mistakes += 1

        // Button press animation even for wrong
        button.run(SKAction.sequence([
            SKAction.scale(to: 0.95, duration: 0.05),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))

        // Red shake on button
        if let bg = button.childNode(withName: "step_bg") as? SKShapeNode {
            let originalColor = bg.fillColor
            bg.fillColor = AppColors.skWrong.withAlphaComponent(0.4)
            bg.strokeColor = AppColors.skWrong

            button.run(SKAction.sequence([
                SKAction.moveBy(x: 10, y: 0, duration: 0.05),
                SKAction.moveBy(x: -20, y: 0, duration: 0.05),
                SKAction.moveBy(x: 20, y: 0, duration: 0.05),
                SKAction.moveBy(x: -10, y: 0, duration: 0.05),
                SKAction.run {
                    bg.fillColor = originalColor
                    bg.strokeColor = SKColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 0.6)
                }
            ]))
        }

        // Wrong label with animation
        let wrongLabel = SKLabelNode(text: String(localized: "Wrong order!"))
        wrongLabel.fontSize = DynamicTypeScale.scaled(14)
        wrongLabel.fontColor = AppColors.skWrong
        wrongLabel.fontName = "Helvetica-Bold"
        wrongLabel.position = CGPoint(x: 0, y: 40)
        wrongLabel.zPosition = 30
        wrongLabel.alpha = 0
        addChild(wrongLabel)

        wrongLabel.run(SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.1),
            SKAction.moveBy(x: 0, y: 30, duration: 0.4),
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.removeFromParent()
        ]))

        // Screen edge flash red
        let flash = SKShapeNode(rectOf: CGSize(width: 320, height: 360))
        flash.fillColor = AppColors.skWrong.withAlphaComponent(0.2)
        flash.strokeColor = .clear
        flash.zPosition = 20
        flash.alpha = 0
        addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.05),
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.removeFromParent()
        ]))

        HapticManager.shared.playImpact()
        AudioManager.shared.playWrong()
    }

    private func updateProgressLine() {
        guard let line = progressLine else { return }

        let progressFraction = CGFloat(completedSteps.count) / CGFloat(totalSteps)
        let startX: CGFloat = -85
        let endX: CGFloat = 85
        let currentEndX = startX + (endX - startX) * progressFraction

        let newPath = CGMutablePath()
        newPath.move(to: CGPoint(x: startX, y: -30))
        newPath.addLine(to: CGPoint(x: currentEndX, y: -30))
        line.path = newPath
        line.strokeColor = AppColors.skCorrect.withAlphaComponent(0.6)
        line.lineWidth = 3
    }

    private func playWaterSplashEffect() {
        guard let woundPos = woundContainer?.position else { return }
        let splash = ParticleEffects.waterSplash(at: CGPoint(x: woundPos.x, y: woundPos.y - 5), intensity: 0.7)
        addChild(splash)
        splash.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.8),
            SKAction.removeFromParent()
        ]))
    }

    private func playBandageWrapEffect() {
        guard let woundPos = woundContainer?.position else { return }
        let wrap = ParticleEffects.bandageWrap(at: CGPoint(x: woundPos.x - 10, y: woundPos.y - 5), direction: 1)
        addChild(wrap)
        wrap.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.6),
            SKAction.removeFromParent()
        ]))
    }

    private func playHealingSparklesEffect() {
        guard let container = woundContainer else { return }

        // Suturing animation: needle stitches across the wound
        let needle = SKSpriteNode(texture: TextureFactory.sutureNeedleTexture(), size: CGSize(width: 24, height: 14))
        needle.position = CGPoint(x: -14, y: -3) // Start left of wound
        needle.zPosition = 20
        needle.alpha = 0
        container.addChild(needle)

        // Build stitch sequence: 3 stitches across the wound
        var stitchActions: [SKAction] = [
            SKAction.fadeIn(withDuration: 0.1)
        ]

        let stitchPositions: [CGFloat] = [-6, 5, 16] // X positions across wound
        for (i, xPos) in stitchPositions.enumerated() {
            let stitchPass = SKAction.sequence([
                // Move to stitch position
                SKAction.move(to: CGPoint(x: xPos, y: -1), duration: 0.08),
                // Dip needle down through wound
                SKAction.moveBy(x: 0, y: -8, duration: 0.06),
                // Cross over
                SKAction.moveBy(x: 6, y: 0, duration: 0.06),
                // Come back up
                SKAction.moveBy(x: 0, y: 8, duration: 0.06),
                // Leave a stitch mark behind
                SKAction.run { [weak container] in
                    guard let container = container else { return }
                    let stitch = SKShapeNode()
                    let stitchPath = CGMutablePath()
                    stitchPath.move(to: CGPoint(x: xPos - 4, y: -5))
                    stitchPath.addLine(to: CGPoint(x: xPos + 4, y: -5))
                    stitch.path = stitchPath
                    stitch.strokeColor = SKColor(red: 0.35, green: 0.2, blue: 0.15, alpha: 0.9)
                    stitch.lineWidth = 2
                    stitch.lineCap = .round
                    stitch.zPosition = 15
                    stitch.name = "stitch_mark_\(i)"
                    stitch.alpha = 0
                    container.addChild(stitch)
                    stitch.run(SKAction.fadeIn(withDuration: 0.08))
                }
            ])
            stitchActions.append(stitchPass)
        }

        // Needle exits and fades
        stitchActions.append(SKAction.group([
            SKAction.moveBy(x: 12, y: 8, duration: 0.2),
            SKAction.fadeOut(withDuration: 0.2)
        ]))
        stitchActions.append(SKAction.removeFromParent())

        // After suturing, play healing sparkles
        stitchActions.append(SKAction.run { [weak self] in
            guard let self = self, let woundPos = self.woundContainer?.position else { return }
            let sparkles = ParticleEffects.healingSparkles(at: woundPos, intensity: 1.0)
            self.addChild(sparkles)
            sparkles.run(SKAction.sequence([
                SKAction.wait(forDuration: 1.0),
                SKAction.removeFromParent()
            ]))
        })

        needle.run(SKAction.sequence(stitchActions))
    }

    private func updateWoundProgress(_ stepIndex: Int) {
        guard let wound = woundMark,
              let glow = woundGlow,
              let container = woundContainer else { return }

        switch stepIndex {
        case 0: // Clean - reduce redness, wound stays visible but cleaner
            wound.run(SKAction.colorize(with: SKColor(red: 0.6, green: 0.25, blue: 0.2, alpha: 0.7),
                                        colorBlendFactor: 0.5, duration: 0.3))
            wound.lineWidth = max(1, wound.lineWidth - 0.5)

            // Reduce inflammation
            if let inflammation = container.childNode(withName: "inflammation") as? SKShapeNode {
                inflammation.run(SKAction.fadeAlpha(to: 0.08, duration: 0.3))
            }

            // Reduce blood drops
            for i in 0..<3 {
                if let drop = container.childNode(withName: "blood_drop_\(i)") {
                    drop.run(SKAction.sequence([
                        SKAction.fadeOut(withDuration: 0.3),
                        SKAction.removeFromParent()
                    ]))
                }
            }

        case 1: // Bandage - wound starts covering
            wound.run(SKAction.colorize(with: SKColor(white: 0.7, alpha: 0.5),
                                        colorBlendFactor: 0.6, duration: 0.4))
            wound.lineWidth = 4

            // Add bandage visual overlay
            let bandageOverlay = SKShapeNode()
            let bandPath = CGMutablePath()
            bandPath.move(to: CGPoint(x: -18, y: 5))
            bandPath.addCurve(to: CGPoint(x: 28, y: 2),
                              control1: CGPoint(x: 5, y: 12),
                              control2: CGPoint(x: 16, y: 10))
            bandPath.addCurve(to: CGPoint(x: 24, y: -8),
                              control1: CGPoint(x: 26, y: -2),
                              control2: CGPoint(x: 25, y: -6))
            bandPath.addCurve(to: CGPoint(x: -18, y: 5),
                              control1: CGPoint(x: 2, y: -10),
                              control2: CGPoint(x: -8, y: -5))
            bandPath.closeSubpath()
            bandageOverlay.path = bandPath
            bandageOverlay.fillColor = SKColor(red: 1.0, green: 0.95, blue: 0.85, alpha: 0.85)
            bandageOverlay.strokeColor = SKColor(red: 0.85, green: 0.78, blue: 0.68, alpha: 0.9)
            bandageOverlay.lineWidth = 1
            bandageOverlay.alpha = 0
            bandageOverlay.name = "bandage_overlay"
            container.addChild(bandageOverlay)

            bandageOverlay.run(SKAction.fadeIn(withDuration: 0.4))

        case 2: // Secure - wound fully healed
            wound.run(SKAction.sequence([
                SKAction.colorize(with: AppColors.skCorrect, colorBlendFactor: 0.7, duration: 0.3),
                SKAction.fadeAlpha(to: 0.3, duration: 0.3)
            ]))

            // Update bandage
            if let bandage = container.childNode(withName: "bandage_overlay") as? SKShapeNode {
                bandage.run(SKAction.colorize(with: SKColor(red: 0.9, green: 1.0, blue: 0.9, alpha: 0.9),
                                              colorBlendFactor: 0.3, duration: 0.3))
            }

            // Healing glow bursts
            glow.fillColor = SKColor(red: 0.3, green: 0.9, blue: 0.4, alpha: 0.4)
            glow.run(SKAction.sequence([
                SKAction.fadeIn(withDuration: 0.2),
                SKAction.fadeOut(withDuration: 0.5)
            ]))

        default:
            break
        }
    }

    private func updateTimerBar() {
        let fraction = CGFloat(timeRemaining / timeLimit)
        let width = max(0, 220 * fraction)
        timerBar.path = CGPath(roundedRect: CGRect(x: -110, y: -5, width: width, height: 10),
                               cornerWidth: 5, cornerHeight: 5, transform: nil)

        // Color change based on urgency
        if fraction < 0.3 {
            timerBar.fillColor = AppColors.skWrong
        } else if fraction < 0.5 {
            timerBar.fillColor = SKColor(red: 1.0, green: 0.65, blue: 0.1, alpha: 1) // Orange
        } else if fraction < 0.7 {
            timerBar.fillColor = SKColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1) // Yellow
        }
    }

    private func updateUrgencyEffects() {
        // Urgency overlay fade in when time is low
        if timeRemaining < 3 {
            let urgencyAlpha = (3 - timeRemaining) / 3 * 0.15
            urgencyOverlay.fillColor = AppColors.skWrong.withAlphaComponent(urgencyAlpha)
            urgencyOverlay.alpha = 1

            // Subtle pulse on backdrop
            backdrop.strokeColor = AppColors.skWrong.withAlphaComponent(0.5 + 0.3 * sin(timeRemaining * 10))
        }
    }

    private func completeMiniGame() {
        guard !isCompleted else { return }
        isCompleted = true
        isActive = false
        removeAction(forKey: "timer")

        // Success text
        instructionLabel.text = mistakes == 0 ? String(localized: "Perfect treatment!") : String(localized: "Injury treated!")
        instructionLabel.fontColor = AppColors.skCorrect

        // "HEALED!" celebration text
        let healedLabel = SKLabelNode(text: String(localized: "HEALED!"))
        healedLabel.fontSize = DynamicTypeScale.scaled(28)
        healedLabel.fontName = "Helvetica-Bold"
        healedLabel.fontColor = AppColors.skCorrect
        healedLabel.position = CGPoint(x: 0, y: 110)
        healedLabel.zPosition = 50
        healedLabel.setScale(0)
        addChild(healedLabel)

        healedLabel.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.2, duration: 0.2),
                SKAction.fadeIn(withDuration: 0.1)
            ]),
            SKAction.scale(to: 1.0, duration: 0.1),
            SKAction.repeat(SKAction.sequence([
                SKAction.scale(to: 1.05, duration: 0.3),
                SKAction.scale(to: 1.0, duration: 0.3)
            ]), count: 3),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))

        // Green flash across screen
        let flash = SKShapeNode(rectOf: CGSize(width: 350, height: 400))
        flash.fillColor = AppColors.skCorrect.withAlphaComponent(0.3)
        flash.strokeColor = .clear
        flash.zPosition = 40
        flash.alpha = 0
        addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.05),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))

        // Particle burst
        guard let woundPos = woundContainer?.position else { return }
        let hearts = ParticleEffects.healingHearts(at: woundPos, count: 10)
        addChild(hearts)

        let sparkles = ParticleEffects.healingSparkles(at: CGPoint(x: 0, y: 0), intensity: 1.2)
        addChild(sparkles)

        // Perfect bonus gold sparkles
        if mistakes == 0 {
            let goldSparkles = ParticleEffects.correctDecisionSparkles(at: CGPoint(x: 0, y: 0), count: 20)
            addChild(goldSparkles)

            // Perfect text
            let perfectLabel = SKLabelNode(text: String(localized: "PERFECT!"))
            perfectLabel.fontSize = DynamicTypeScale.scaled(16)
            perfectLabel.fontName = "Helvetica-Bold"
            perfectLabel.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1)
            perfectLabel.position = CGPoint(x: 0, y: -120)
            perfectLabel.alpha = 0
            addChild(perfectLabel)
            perfectLabel.run(SKAction.sequence([
                SKAction.fadeIn(withDuration: 0.2),
                SKAction.wait(forDuration: 1.0),
                SKAction.fadeOut(withDuration: 0.2),
                SKAction.removeFromParent()
            ]))
        }

        // Accessibility announcement
        let message = mistakes == 0
            ? String(localized: "Injury treated perfectly with no mistakes.")
            : String(localized: "Injury treated successfully with \(mistakes) mistakes.")
        UIAccessibility.post(notification: .announcement, argument: message)

        HapticManager.shared.playCorrectFeedback()
        AudioManager.shared.playCorrect()

        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.2),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                self.miniGameDelegate?.miniGameDidComplete(self, action: .checkInjuries)
                self.dismiss()
            }
        ]))
    }

    private func failMiniGame() {
        guard !isFailed, !isCompleted else { return }
        isFailed = true
        isActive = false

        instructionLabel.text = String(localized: "Time's up!")
        instructionLabel.fontColor = AppColors.skWrong

        // Red pulse on backdrop
        backdrop.run(SKAction.sequence([
            SKAction.colorize(with: AppColors.skWrong, colorBlendFactor: 0.3, duration: 0.1),
            SKAction.wait(forDuration: 0.2),
            SKAction.colorize(withColorBlendFactor: 0, duration: 0.2)
        ]))

        backdrop.strokeColor = AppColors.skWrong

        // Wound darkens
        if let wound = woundMark {
            wound.run(SKAction.colorize(with: SKColor(red: 0.4, green: 0.1, blue: 0.08, alpha: 1),
                                        colorBlendFactor: 0.5, duration: 0.3))
        }

        // Screen edge flash
        urgencyOverlay.fillColor = AppColors.skWrong.withAlphaComponent(0.3)
        urgencyOverlay.alpha = 1
        urgencyOverlay.run(SKAction.fadeOut(withDuration: 0.5))

        // "Time's up!" shake
        let urgencyShake = SKAction.sequence([
            SKAction.moveBy(x: 5, y: 0, duration: 0.03),
            SKAction.moveBy(x: -10, y: 0, duration: 0.03),
            SKAction.moveBy(x: 10, y: 0, duration: 0.03),
            SKAction.moveBy(x: -5, y: 0, duration: 0.03)
        ])
        run(SKAction.repeat(urgencyShake, count: 3))

        // Accessibility announcement
        UIAccessibility.post(notification: .announcement, argument: String(localized: "Failed to treat injury in time."))

        HapticManager.shared.playImpact()
        AudioManager.shared.playWrong()

        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                self.miniGameDelegate?.miniGameDidFail(self, action: .checkInjuries)
                self.dismiss()
            }
        ]))
    }
}
