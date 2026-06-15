import SpriteKit
import UIKit

protocol QuakeSceneDelegate: AnyObject {
    func quakeSceneDidFinish(report: EnhancedDebriefReport)
}

final class QuakeScene: SKScene, @preconcurrency SKPhysicsContactDelegate, ShakeControllerDelegate,
    MiniGameDelegate
{
    weak var quakeDelegate: QuakeSceneDelegate?

    private var shakeController: ShakeController!
    private var physicsManager: PhysicsManager!
    private let decisionEngine: DecisionEngine
    private let scenario: QuakeScenario

    private var cameraNode: SKCameraNode!
    private var playerNode: SKNode?
    private var isPlayerUnderCover = false
    private var isExitingScene = false
    private var hasProcessedMainDecision = false
    private var processedAftershockActions: Set<String> = []
    private var lastUpdateTime: TimeInterval = 0
    private var gameStartTime: TimeInterval = 0
    private var countdownValue = 3

    // Mini-game state
    private var activeMiniGame: MiniGameNode?
    private var touchStartLocation: CGPoint?

    // Aftershock sequential task queue state
    // Order: 1) Check injuries → 2) Turn off gas valve → 3) Open door (safe exit)
    private let aftershockTasks: [(name: String, action: PlayerAction)] = [
        ("injury_check", .checkInjuries),
        ("gas_valve", .shutOffGas),
        ("safe_exit", .findSafeExit),
    ]
    private var currentTaskIndex = 0
    private var isTaskAnimatingIn = false
    private var miniGameLaunchedForCurrentTask = false

    // Hints system
    private var hintLabel: SKLabelNode?
    private var hintsShown = 0
    private let maxHints = 2
    private var lastHintTime: TimeInterval = 0
    private let hintCooldown: TimeInterval = 8.0

    // Story slideshow state
    private var storyOverlayNode: SKNode?
    private var currentStorySlide = 0
    private var isStoryPlaying = false

    // Debris interaction state
    private var debrisClearedCount = 0
    private var lastDebrisClearTime: TimeInterval = 0

    // MARK: - Push-Through Movement

    /// Simple horizontal push-through movement. Player walks directly to target,
    /// and if there's an obstacle in the way, kicks through it with visual effects
    /// Simple horizontal push-through movement. Player walks directly to target,
    /// kicks through any obstacles (like table) in the way, and continues to the target.
    private func movePlayerWithPushThrough(
        to target: CGPoint,
        action: PlayerAction,
        onComplete: (() -> Void)? = nil
    ) {
        guard let player = playerNode as? SKSpriteNode else {
            NSLog("[PUSH] FAILED - no player node")
            onComplete?()
            return
        }

        // Store the FINAL target position - this never changes
        let floorY = RoomLayout.floorHeight + RoomLayout.playerSize.height / 2 + 5
        let finalTargetPos = CGPoint(x: target.x, y: floorY)
        let startX = player.position.x
        let direction: CGFloat = finalTargetPos.x > startX ? 1 : -1

        NSLog(
            "[PUSH] action=\(action) from x=\(startX) to target x=\(finalTargetPos.x) direction=\(direction)"
        )

        // Remove any existing movement
        player.removeAllActions()
        resetPlayerTransforms()

        // CRITICAL: Check for obstacles BEFORE movement starts and remove them
        let centerX = size.width / 2
        let tableMinX = centerX - RoomLayout.tableWidth / 2
        let tableMaxX = centerX + RoomLayout.tableWidth / 2
        let minX = min(startX, finalTargetPos.x)
        let maxX = max(startX, finalTargetPos.x)

        // Check if path crosses through the table
        let pathCrossesTable = minX < tableMaxX && maxX > tableMinX

        var obstacleHitX: CGFloat?
        if pathCrossesTable {
            // Calculate where we hit the table
            obstacleHitX = direction > 0 ? tableMinX : tableMaxX
            NSLog("[PUSH] Path crosses table at x=\(obstacleHitX ?? 0)")

            // IMMEDIATELY remove table physics and visual - don't wait
            removeTableObstacle()
        }

        // Disable player collision with ALL obstacles during movement
        if let playerBody = player.physicsBody {
            playerBody.categoryBitMask = PhysicsCategory.player
            playerBody.collisionBitMask = PhysicsCategory.floor | PhysicsCategory.wall
            playerBody.contactTestBitMask = PhysicsCategory.none
            NSLog("[PUSH] Disabled all collisions - player walks through everything")
        }

        // Face the target direction
        faceDirection(player: player, toward: finalTargetPos.x)

        // Calculate duration based on distance
        let xDistance = abs(finalTargetPos.x - startX)
        let moveDuration = max(0.5, Double(xDistance) / 200.0)

        // Walk animation
        let walk1 = TextureFactory.playerRunTexture()
        let walk2 = TextureFactory.playerWalk2Texture()
        let stand = TextureFactory.playerTexture()
        let walkCycle = SKAction.animate(with: [walk1, stand, walk2, stand], timePerFrame: 0.08)
        let walkAnim = SKAction.repeatForever(walkCycle)
        player.run(walkAnim, withKey: "walkAnim")

        // Create the movement action to the FINAL target (never changes)
        let moveAction = SKAction.move(to: finalTargetPos, duration: moveDuration)
        moveAction.timingMode = .linear

        // If there was an obstacle, trigger kick effects when player reaches that position
        if let hitX = obstacleHitX {
            let distanceToObstacle = abs(hitX - startX)
            let timeToObstacle = Double(distanceToObstacle) / 200.0

            run(
                SKAction.sequence([
                    SKAction.wait(forDuration: timeToObstacle),
                    SKAction.run { [weak self] in
                        guard let self = self else { return }
                        NSLog("[PUSH] Kicking obstacle at x=\(hitX)")
                        // Visual kick effects
                        self.spawnKickEffect(at: CGPoint(x: hitX, y: floorY + 30))
                        self.shakeController?.triggerManualImpact(intensity: 0.3)
                        self.spawnDebrisFromObstacle(
                            at: CGPoint(x: hitX, y: floorY + 40),
                            obstacleName: "table", direction: direction)
                        self.spawnDustCloud(at: CGPoint(x: hitX, y: floorY + 10))
                    },
                ]), withKey: "kickEffects")
        }

        // Run the movement - always to the FINAL target
        player.run(
            SKAction.sequence([
                moveAction,
                SKAction.run { [weak self] in
                    guard self != nil else { return }
                    player.removeAction(forKey: "walkAnim")
                    player.xScale = abs(player.xScale)
                    player.texture = TextureFactory.playerTexture()
                    NSLog("[PUSH] Arrived at target x=\(finalTargetPos.x)")

                    // Re-enable normal collisions after movement
                    if let playerBody = player.physicsBody {
                        playerBody.collisionBitMask =
                            PhysicsCategory.floor | PhysicsCategory.wall | PhysicsCategory.furniture
                            | PhysicsCategory.debris
                        playerBody.contactTestBitMask =
                            PhysicsCategory.debris | PhysicsCategory.furniture
                    }

                    onComplete?()
                },
            ]), withKey: "aftershockMove")
    }

    /// Immediately removes ALL obstacles (furniture and debris) from the scene
    /// This ensures the player can walk to any task location without getting stuck
    private func removeTableObstacle() {
        NSLog("[PUSH] Removing ALL obstacles from the scene")

        // Remove ALL furniture items (table, desk, kitchen island, bed, bookshelf, etc.)
        let furnitureNames = [
            "table", "desk", "kitchen_island", "bed", "bookshelf", "cabinet", "shelf",
        ]

        // First pass: Remove main furniture
        for furnitureName in furnitureNames {
            if let node = childNode(withName: furnitureName) {
                NSLog("[PUSH] Removing furniture: \(furnitureName) at x=\(node.position.x)")
                node.physicsBody = nil
                let fadeOut = SKAction.fadeOut(withDuration: 0.2)
                let scaleDown = SKAction.scale(to: 0.5, duration: 0.2)
                scaleDown.timingMode = .easeOut
                node.run(
                    SKAction.sequence([
                        SKAction.group([fadeOut, scaleDown]),
                        SKAction.removeFromParent(),
                    ]))
            }
        }

        // Second pass: Remove ALL nodes with physics bodies that are furniture/debris
        // This catches any items that might have fallen or been placed dynamically
        enumerateChildNodes(withName: "//*") { node, _ in
            // Skip the player themselves
            if node.name == "player" { return }

            // Skip HUD, camera, and UI elements
            if let name = node.name,
                name.contains("hud") || name.contains("label") || name.contains("bg")
            {
                return
            }

            // Check if this node has a physics body (it's an obstacle)
            guard let body = node.physicsBody else { return }

            // Check if it's furniture or debris category
            let isObstacle =
                (body.categoryBitMask & PhysicsCategory.furniture != 0)
                || (body.categoryBitMask & PhysicsCategory.debris != 0)

            if isObstacle && node.alpha > 0 {
                NSLog(
                    "[PUSH] Removing obstacle: \(node.name ?? "unnamed") category=\(body.categoryBitMask)"
                )

                // Remove physics immediately
                node.physicsBody = nil

                // Fade out quickly
                let quickFade = SKAction.fadeOut(withDuration: 0.15)
                quickFade.timingMode = .easeOut
                node.run(SKAction.sequence([quickFade, SKAction.removeFromParent()]))
            }
        }

        NSLog("[PUSH] All obstacles cleared, path is now clear")
    }

    /// Spawns a kick/punch visual effect
    private func spawnKickEffect(at position: CGPoint) {
        // Impact flash
        let flash = SKSpriteNode(color: .white, size: CGSize(width: 30, height: 30))
        flash.position = position
        flash.zPosition = 10
        flash.alpha = 0.8
        addChild(flash)

        let fade = SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.15),
            SKAction.removeFromParent(),
        ])
        flash.run(fade)

        // Speed lines
        for i in 0..<3 {
            let line = SKSpriteNode(
                color: SKColor(white: 1, alpha: 0.6), size: CGSize(width: 20, height: 3))
            line.position = CGPoint(x: position.x, y: position.y + CGFloat(i * 8 - 8))
            line.zPosition = 9
            line.zRotation = CGFloat.random(in: -0.3...0.3)
            addChild(line)

            let move = SKAction.moveBy(
                x: CGFloat.random(in: 20...40) * (i % 2 == 0 ? 1 : -1),
                y: 0, duration: 0.2)
            move.timingMode = .easeOut
            line.run(SKAction.sequence([move, SKAction.removeFromParent()]))
        }
    }

    /// Spawns debris when pushing through an obstacle
    private func spawnDebrisFromObstacle(
        at position: CGPoint, obstacleName: String, direction: CGFloat
    ) {
        let debrisCount = obstacleName == "table" ? 5 : 8

        for _ in 0..<debrisCount {
            let size = CGFloat.random(in: 4...10)
            let color: SKColor

            if obstacleName == "table" {
                color = SKColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1)  // Wood color
            } else {
                color = SKColor(white: CGFloat.random(in: 0.3...0.6), alpha: 1)  // Gray for bookshelf
            }

            let particle = SKSpriteNode(color: color, size: CGSize(width: size, height: size))
            particle.position = CGPoint(
                x: position.x + CGFloat.random(in: -30...30),
                y: position.y + CGFloat.random(in: -20...40)
            )
            particle.zPosition = 6
            particle.zRotation = CGFloat.random(in: 0...(2 * .pi))
            addChild(particle)

            // Physics-based debris movement
            let flyX =
                CGFloat.random(in: 30...80) * (direction > 0 ? -1 : 1)
                * CGFloat.random(in: 0.5...1.5)
            let flyY = CGFloat.random(in: 20...60)

            let fly = SKAction.moveBy(x: flyX, y: flyY, duration: 0.3)
            fly.timingMode = .easeOut

            let fall = SKAction.moveBy(x: flyX * 0.3, y: -flyY - 40, duration: 0.4)
            fall.timingMode = .easeIn

            let fade = SKAction.fadeOut(withDuration: 0.3)
            fade.timingMode = .easeOut

            particle.run(
                SKAction.sequence([
                    fly,
                    fall,
                    fade,
                    SKAction.removeFromParent(),
                ]))
        }

        // Dust cloud
        spawnDustCloud(at: CGPoint(x: position.x, y: RoomLayout.floorHeight + 10))
    }

    /// Spawns a dust cloud effect
    private func spawnDustCloud(at position: CGPoint) {
        let cloud = SKNode()
        cloud.position = position
        cloud.zPosition = 5

        for _ in 0..<8 {
            let size = CGFloat.random(in: 10...25)
            let dust = SKSpriteNode(
                color: SKColor(white: 0.8, alpha: 0.4), size: CGSize(width: size, height: size))
            dust.position = CGPoint(x: CGFloat.random(in: -20...20), y: CGFloat.random(in: 0...30))
            dust.alpha = 0.5
            cloud.addChild(dust)

            let expand = SKAction.scale(to: CGFloat.random(in: 1.5...2.5), duration: 0.4)
            expand.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: 0.4)
            fade.timingMode = .easeOut
            let drift = SKAction.moveBy(
                x: CGFloat.random(in: -30...30),
                y: CGFloat.random(in: 10...40),
                duration: 0.4)
            drift.timingMode = .easeOut

            dust.run(
                SKAction.sequence([
                    SKAction.group([expand, fade, drift]),
                    SKAction.removeFromParent(),
                ]))
        }

        addChild(cloud)

        run(SKAction.wait(forDuration: 0.5)) {
            cloud.removeFromParent()
        }
    }

    /// Resolved room type from scenario string
    private var currentRoomType: RoomBuilder.RoomType {
        RoomBuilder.RoomType.allCases.first {
            RoomUnlockManager.string(from: $0) == scenario.roomType
        } ?? .livingRoom
    }

    /// The node name of the safe zone (cover) for the current room
    private var safeZoneNodeName: String {
        switch currentRoomType {
        case .livingRoom: return "table"
        case .kitchen: return "kitchen_island"
        case .office: return "desk"
        case .bedroom: return "bed"
        }
    }

    // Lighting overlays
    private var warmOverlay: SKSpriteNode?
    private var coldOverlay: SKSpriteNode?

    // Creaking timer
    private var lastCreakTime: TimeInterval = 0
    private var nextCreakInterval: TimeInterval = 3.0

    // HUD
    private var heartsLabel: SKLabelNode!
    private var heartNodes: [SKSpriteNode] = []
    private var lastHeartsCount: Int = 3
    private var scoreLabel: SKLabelNode!
    private var phaseLabel: SKLabelNode!
    private var instructionLabel: SKLabelNode!
    private var magnitudeLabel: SKLabelNode!
    private var timerLabel: SKLabelNode!
    private var hudInsets: (horizontal: CGFloat, vertical: CGFloat) = (0, 0)

    // Vignette
    private var vignetteNode: SKShapeNode?

    // MARK: - Accessibility
    private var isReduceMotionEnabled: Bool { UIAccessibility.isReduceMotionEnabled }
    private var lastAnnouncedPhase: QuakePhase?
    private var accessibleElements: [UIAccessibilityElement] = []
    private var hasAnnouncedSafeZone = false

    /// Scale factor for adapting game elements to different scene sizes
    private var contentScale: CGFloat = 1.0

    /// Original positions of nodes for repositioning on size change
    private var originalNodePositions: [String: CGPoint] = [:]

    init(scenario: QuakeScenario, decisionEngine: DecisionEngine, size: CGSize? = nil) {
        self.scenario = scenario
        self.decisionEngine = decisionEngine

        // Calculate dynamic scene size based on available space
        let sceneSize: CGSize
        if let providedSize = size {
            sceneSize = RoomLayout.dynamicSceneSize(for: providedSize)
        } else {
            sceneSize = RoomLayout.sceneSize
        }

        super.init(size: sceneSize)
        self.scaleMode = .aspectFit
        self.contentScale = RoomLayout.scaleFactor(for: sceneSize)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Size Change Handling

    /// Called when the view size changes (rotation, multitasking, etc.)
    func handleSizeChange(newSize: CGSize) {
        // Update scale factor
        contentScale = RoomLayout.scaleFactor(for: newSize)

        // Update camera position
        cameraNode.position = CGPoint(x: newSize.width / 2, y: newSize.height / 2)

        // Reposition HUD elements
        repositionHUD()

        // Update physics world bounds if needed
        updatePhysicsBounds()
    }

    private func updatePhysicsBounds() {
        // Update floor position based on new scene size
        if let floor = childNode(withName: "floor") {
            floor.position = CGPoint(x: size.width / 2, y: RoomLayout.floorHeight / 2)
        }

        // Update wall positions
        if let leftWall = childNode(withName: "leftWall") {
            leftWall.position = CGPoint(x: -RoomLayout.wallThickness / 2, y: size.height / 2)
        }
        if let rightWall = childNode(withName: "rightWall") {
            rightWall.position = CGPoint(
                x: size.width + RoomLayout.wallThickness / 2, y: size.height / 2)
        }
    }

    // MARK: - Scene Setup

    override func didMove(to view: SKView) {
        // Set background based on scenario lighting mode
        backgroundColor = scenario.lightingMode.calmBackgroundColor
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        physicsWorld.contactDelegate = self

        setupCamera()
        let roomType =
            RoomBuilder.RoomType.allCases.first {
                RoomUnlockManager.string(from: $0) == scenario.roomType
            } ?? .livingRoom
        RoomBuilder.buildRoom(type: roomType, in: self)
        playerNode = childNode(withName: "player")
        setupLightingOverlays()
        setupHUD()
        setupVignette()

        // Apply visibility reduction for night mode
        if scenario.lightingMode.reducesVisibility {
            applyNighttimeVisibilityReduction()
        }

        physicsManager = PhysicsManager(scene: self)
        shakeController = ShakeController(cameraNode: cameraNode, scene: self)
        shakeController.delegate = self

        // Start game flow based on scenario type
        startGame()

        // Setup accessibility
        setupAccessibility()

        #if DEBUG
        if MarketingCapture.isDemoMode {
            setupMarketingCaptureObservers()
        }
        #endif
    }

    private func startGame() {
        // Reset physics manager completely so objects can fall again
        physicsManager.reset()

        if scenario.hasStoryIntro {
            startStorySequence()
        } else if scenario.hasCalmPhase {
            startCalmPhase()
        } else if scenario.hasCountdown {
            startCountdown()
        } else {
            // Surprise quake - start immediately
            startEarthquake()
        }
    }

    // MARK: - Accessibility Setup

    private func setupAccessibility() {
        // Announce game start to VoiceOver users
        postAccessibilityAnnouncement(String(localized: "Earthquake drill starting. Get ready."))

        // Configure accessibility elements after a brief delay to ensure nodes exist
        run(SKAction.wait(forDuration: 0.5)) { [weak self] in
            self?.configureAccessibleElements()
        }
    }

    private func configureAccessibleElements() {
        guard let view = self.view else { return }

        // Create accessibility elements for interactive zones
        var elements: [UIAccessibilityElement] = []

        // Safe zone (table/kitchen island/desk/bed)
        if let safeZone = childNode(withName: safeZoneNodeName) {
            let safeZoneElement = UIAccessibilityElement(accessibilityContainer: view)
            safeZoneElement.accessibilityLabel =
                "\(currentRoomType.safeZoneName). Safe cover location."
            safeZoneElement.accessibilityHint =
                "Double tap to take cover here. This is the safest place during an earthquake."
            safeZoneElement.accessibilityTraits = .button
            safeZoneElement.accessibilityFrame = convertFrameToScreen(safeZone.frame)
            elements.append(safeZoneElement)
        }

        // Window (danger zone)
        if let window = childNode(withName: "window") {
            let windowElement = UIAccessibilityElement(accessibilityContainer: view)
            windowElement.accessibilityLabel = "Window. Danger zone."
            windowElement.accessibilityHint =
                "Danger! Glass can shatter and cause injury. Avoid during earthquake."
            windowElement.accessibilityTraits = .button
            windowElement.accessibilityFrame = convertFrameToScreen(window.frame)
            elements.append(windowElement)
        }

        // Door (danger zone during quake)
        if let door = childNode(withName: "door") {
            let doorElement = UIAccessibilityElement(accessibilityContainer: view)
            doorElement.accessibilityLabel = "Door. Exit."
            doorElement.accessibilityHint =
                "Danger during earthquake. Doorways are not safer. Stay inside until shaking stops."
            doorElement.accessibilityTraits = .button
            doorElement.accessibilityFrame = convertFrameToScreen(door.frame)
            elements.append(doorElement)
        }

        // Bookshelf (danger zone)
        if let bookshelf = childNode(withName: "bookshelf") {
            let bookshelfElement = UIAccessibilityElement(accessibilityContainer: view)
            bookshelfElement.accessibilityLabel = "Bookshelf. Heavy furniture. Danger zone."
            bookshelfElement.accessibilityHint = "Danger! Can topple during earthquake. Stay away."
            bookshelfElement.accessibilityTraits = .button
            bookshelfElement.accessibilityFrame = convertFrameToScreen(bookshelf.frame)
            elements.append(bookshelfElement)
        }

        // Aftershock zones (initially hidden)
        let aftershockZoneNames = [
            (
                "gas_valve", "Gas valve",
                "Double tap to shut off the gas valve. Prevents fire hazard.", ".button"
            ),
            ("safe_exit", "Safe exit", "Double tap to find and clear the exit path.", ".button"),
            ("injury_check", "Injury check", "Double tap to check and treat injuries.", ".button"),
        ]

        for (name, label, hint, _) in aftershockZoneNames {
            if let zone = childNode(withName: name) {
                let zoneElement = UIAccessibilityElement(accessibilityContainer: view)
                zoneElement.accessibilityLabel = label
                zoneElement.accessibilityHint = hint
                zoneElement.accessibilityTraits = .button
                zoneElement.accessibilityFrame = convertFrameToScreen(zone.frame)
                zoneElement.isAccessibilityElement = false  // Hidden until aftershock phase
                elements.append(zoneElement)
            }
        }

        accessibleElements = elements
        view.accessibilityElements = elements
    }

    private func convertFrameToScreen(_ frame: CGRect) -> CGRect {
        guard let view = self.view else { return frame }
        // Convert scene coordinates to view coordinates
        let originInView = convertPoint(fromView: CGPoint(x: frame.origin.x, y: frame.origin.y))
        return CGRect(
            x: originInView.x,
            y: view.bounds.height - originInView.y - frame.height,
            width: frame.width,
            height: frame.height
        )
    }

    private func postAccessibilityAnnouncement(_ message: String, delay: TimeInterval = 0) {
        guard delay == 0 else {
            run(SKAction.wait(forDuration: delay)) { [weak self] in
                self?.postAccessibilityAnnouncement(message)
            }
            return
        }
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    private func updateAccessibleElementsForPhase(_ phase: QuakePhase) {
        guard self.view != nil else { return }

        // Update which elements are accessible based on game phase
        for (_, element) in accessibleElements.enumerated() {
            switch phase {
            case .story, .calm, .countdown:
                // Only safe zone is discoverable before earthquake
                element.isAccessibilityElement =
                    element.accessibilityLabel?.contains("Safe") ?? false

            case .pWave, .sWave:
                // During earthquake, all main zones are accessible
                let isMainZone =
                    element.accessibilityLabel?.contains("gas valve") == false
                    && element.accessibilityLabel?.contains("Safe exit") == false
                    && element.accessibilityLabel?.contains("Injury check") == false
                element.isAccessibilityElement = isMainZone

            case .aftershock:
                // Aftershock: only aftershock zones are accessible
                let isAftershockZone =
                    element.accessibilityLabel?.contains("gas valve") == true
                    || element.accessibilityLabel?.contains("Safe exit") == true
                    || element.accessibilityLabel?.contains("Injury check") == true
                element.isAccessibilityElement = isAftershockZone

            case .debrief:
                element.isAccessibilityElement = false
            }
        }

        // Post screen changed notification
        UIAccessibility.post(notification: .screenChanged, argument: nil)
    }

    private func announcePhaseChange(_ phase: QuakePhase) {
        guard lastAnnouncedPhase != phase else { return }
        lastAnnouncedPhase = phase

        let announcement: String
        switch phase {
        case .story:
            announcement = String(localized: "Story introduction playing. Tap to skip.")
        case .calm:
            announcement = String(localized: "Get ready. An earthquake simulation will begin soon.")
        case .countdown:
            announcement = String(localized: "Earthquake starting in 3, 2, 1.")
        case .pWave:
            announcement = String(
                localized:
                    "Warning! P-wave detected. Gentle shaking starting. Find cover under the \(currentRoomType.safeZoneName.lowercased()) now."
            )
        case .sWave:
            announcement = String(
                localized:
                    "Strong shaking! Earthquake in progress. If not under cover, stay where you are and protect your head."
            )
        case .aftershock:
            announcement = String(
                localized:
                    "Main shaking stopped. Aftershock phase. Check for gas leaks, find safe exit, and check for injuries. Tap to complete these tasks."
            )
        case .debrief:
            announcement = String(localized: "Drill complete. Viewing results.")
        }

        postAccessibilityAnnouncement(announcement)
        updateAccessibleElementsForPhase(phase)
    }

    private func setupCamera() {
        cameraNode = SKCameraNode()
        cameraNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(cameraNode)
        camera = cameraNode
    }

    // MARK: - Lighting Overlays

    private func setupLightingOverlays() {
        let overlaySize = CGSize(width: size.width + 100, height: size.height + 100)
        let lightingMode = scenario.lightingMode

        // Warm overlay (calm phase) — adjusted by lighting mode
        let warmColor: SKColor
        switch lightingMode {
        case .night:
            // Very faint warm for night
            warmColor = SKColor(red: 0.9, green: 0.8, blue: 0.6, alpha: 1.0)
        case .surprise:
            // No warm overlay for surprise - skip to cold
            warmColor = SKColor.clear
        default:
            warmColor = SKColor(red: 1.0, green: 0.9, blue: 0.7, alpha: 1.0)
        }
        let warm = SKSpriteNode(color: warmColor, size: overlaySize)
        warm.blendMode = .add
        warm.alpha = lightingMode.warmOverlayAlpha
        warm.zPosition = 45
        warm.name = "warm_overlay"
        cameraNode.addChild(warm)
        warmOverlay = warm

        // For surprise quake, pre-create cold overlay with higher initial alpha
        if lightingMode == .surprise {
            let cold = SKSpriteNode(
                color: SKColor(red: 0.5, green: 0.55, blue: 0.65, alpha: 1.0), size: overlaySize)
            cold.blendMode = .alpha
            cold.alpha = lightingMode.coldOverlayAlpha
            cold.zPosition = 46
            cold.name = "cold_overlay"
            cameraNode.addChild(cold)
            coldOverlay = cold
        }
    }

    private func applyNighttimeVisibilityReduction() {
        // Reduce visibility of interactive elements during night
        let visibilityMultiplier = scenario.lightingMode.elementVisibilityMultiplier

        // Apply to safe zone
        if let safeZone = childNode(withName: safeZoneNodeName) {
            safeZone.alpha = visibilityMultiplier
        }

        // Apply to danger zones
        for name in ["window", "door", "bookshelf"] {
            if let node = childNode(withName: name) {
                node.alpha = visibilityMultiplier
            }
        }

        // Apply to player
        if let player = playerNode {
            player.alpha = visibilityMultiplier
        }
    }

    // MARK: - HUD

    /// Returns the visible half-size in scene coordinates, accounting for aspectFit scaling.
    private func visibleHalfSize() -> CGSize {
        guard let view = self.view else {
            return CGSize(width: size.width / 2, height: size.height / 2)
        }
        let viewAspect = view.bounds.width / view.bounds.height
        let sceneAspect = size.width / size.height

        if viewAspect > sceneAspect {
            // View is wider — height is the constraint
            let visibleW = size.height * viewAspect / 2
            return CGSize(width: visibleW, height: size.height / 2)
        } else {
            // View is taller — width is the constraint
            let visibleH = size.width / viewAspect / 2
            return CGSize(width: size.width / 2, height: visibleH)
        }
    }

    private func setupHUD() {
        let hudContainer = SKNode()
        hudContainer.zPosition = 100
        hudContainer.name = "hud"
        cameraNode.addChild(hudContainer)

        // Use conservative insets that work on all aspect ratios
        let halfW = size.width / 2 - 30
        let halfH = size.height / 2 - 30

        // Store insets for repositioning on size change
        self.hudInsets = (horizontal: halfW, vertical: halfH)

        // Timer (top left)
        timerLabel = SKLabelNode(text: "0:00")
        timerLabel.fontSize = DynamicTypeScale.scaled(20)
        timerLabel.fontName = "Helvetica-Bold"
        timerLabel.fontColor = SKColor(
            red: 0x1C / 255, green: 0x1C / 255, blue: 0x1E / 255, alpha: 1)
        timerLabel.horizontalAlignmentMode = .left
        timerLabel.position = CGPoint(x: -halfW, y: halfH - 20)
        hudContainer.addChild(timerLabel)

        let timerBg = SKShapeNode(rectOf: CGSize(width: 70, height: 28), cornerRadius: 6)
        timerBg.fillColor = SKColor(white: 1, alpha: HighContrast.hudBackgroundAlpha)
        timerBg.strokeColor = HighContrast.hudStrokeColor
        timerBg.position = CGPoint(x: -halfW + 30, y: halfH - 15)
        timerBg.zPosition = -1
        timerBg.name = "timer_bg"
        hudContainer.addChild(timerBg)

        // Hearts (top center) — procedural heart sprites
        heartsLabel = SKLabelNode(text: "")
        heartsLabel.fontSize = DynamicTypeScale.scaled(22)
        heartsLabel.position = CGPoint(x: 0, y: halfH - 20)
        hudContainer.addChild(heartsLabel)

        let heartFullTex = TextureFactory.heartFullTexture()
        let heartSize = CGSize(width: 24, height: 24)
        for i in 0..<3 {
            let heart = SKSpriteNode(texture: heartFullTex, size: heartSize)
            heart.position = CGPoint(x: CGFloat(i - 1) * 30, y: halfH - 16)
            heart.name = "heart_\(i)"
            hudContainer.addChild(heart)
            heartNodes.append(heart)
        }

        // Magnitude (top right)
        magnitudeLabel = SKLabelNode(text: String(format: "M %.1f", scenario.magnitude))
        magnitudeLabel.fontSize = DynamicTypeScale.scaled(18)
        magnitudeLabel.fontName = "Helvetica-Bold"
        magnitudeLabel.fontColor = SKColor(
            red: 0x1C / 255, green: 0x1C / 255, blue: 0x1E / 255, alpha: 1)
        magnitudeLabel.horizontalAlignmentMode = .right
        magnitudeLabel.position = CGPoint(x: halfW, y: halfH - 20)
        hudContainer.addChild(magnitudeLabel)

        let magBg = SKShapeNode(rectOf: CGSize(width: 65, height: 28), cornerRadius: 6)
        magBg.fillColor = SKColor(white: 1, alpha: HighContrast.hudBackgroundAlpha)
        magBg.strokeColor = HighContrast.hudStrokeColor
        magBg.position = CGPoint(x: halfW - 28, y: halfH - 15)
        magBg.zPosition = -1
        magBg.name = "mag_bg"
        hudContainer.addChild(magBg)

        // Phase label (below HUD bar)
        phaseLabel = SKLabelNode(text: "")
        phaseLabel.fontSize = DynamicTypeScale.scaled(26)
        phaseLabel.fontName = "Helvetica-Bold"
        phaseLabel.fontColor = AppColors.skWarning
        phaseLabel.position = CGPoint(x: 0, y: halfH - 55)
        hudContainer.addChild(phaseLabel)

        // Score
        scoreLabel = SKLabelNode(text: String(localized: "Score: 0"))
        scoreLabel.fontSize = DynamicTypeScale.scaled(15)
        scoreLabel.fontName = "Helvetica"
        scoreLabel.fontColor = SKColor(
            red: 0x1C / 255, green: 0x1C / 255, blue: 0x1E / 255, alpha: 1)
        scoreLabel.position = CGPoint(x: 0, y: halfH - 78)
        scoreLabel.alpha = HighContrast.isEnabled ? 1.0 : 0.8
        hudContainer.addChild(scoreLabel)

        // Instruction (bottom)
        instructionLabel = SKLabelNode(text: "")
        instructionLabel.fontSize = DynamicTypeScale.scaled(18)
        instructionLabel.fontName = "Helvetica-Bold"
        instructionLabel.fontColor = SKColor(
            red: 0x1C / 255, green: 0x1C / 255, blue: 0x1E / 255, alpha: 1)
        instructionLabel.position = CGPoint(x: 0, y: -halfH + 10)
        hudContainer.addChild(instructionLabel)

        let instructBg = SKShapeNode(rectOf: CGSize(width: 320, height: 32), cornerRadius: 8)
        instructBg.fillColor = SKColor(white: 1, alpha: HighContrast.hudBackgroundAlpha)
        instructBg.strokeColor = HighContrast.hudStrokeColor
        instructBg.position = CGPoint(x: 0, y: -halfH + 15)
        instructBg.zPosition = -1
        instructBg.name = "instruction_bg"
        hudContainer.addChild(instructBg)
    }

    private func updateHUD() {
        let currentHearts = decisionEngine.heartsRemaining
        let heartFullTex = TextureFactory.heartFullTexture()
        let heartEmptyTex = TextureFactory.heartEmptyTexture()
        for i in 0..<heartNodes.count {
            heartNodes[i].texture = i < currentHearts ? heartFullTex : heartEmptyTex
        }
        // Animate heart loss
        if currentHearts < lastHeartsCount {
            let lostIndex = currentHearts
            if lostIndex < heartNodes.count {
                let heart = heartNodes[lostIndex]
                let pop1Scale = SKAction.scale(to: 1.6, duration: 0.1)
                let pop1Rotate = SKAction.rotate(byAngle: 0.3, duration: 0.1)
                pop1Scale.timingMode = .easeOut
                pop1Rotate.timingMode = .easeOut
                let pop2Scale = SKAction.scale(to: 0.8, duration: 0.1)
                let pop2Rotate = SKAction.rotate(byAngle: -0.6, duration: 0.1)
                pop2Scale.timingMode = .easeOut
                pop2Rotate.timingMode = .easeOut
                let pop3Scale = SKAction.scale(to: 1.0, duration: 0.1)
                let pop3Rotate = SKAction.rotate(toAngle: 0, duration: 0.1)
                pop3Scale.timingMode = .easeOut
                pop3Rotate.timingMode = .easeOut
                heart.run(
                    SKAction.sequence([
                        SKAction.group([pop1Scale, pop1Rotate]),
                        SKAction.group([pop2Scale, pop2Rotate]),
                        SKAction.group([pop3Scale, pop3Rotate]),
                    ]))
            }
            lastHeartsCount = currentHearts
        }
        scoreLabel.text = String(localized: "Score: \(max(0, decisionEngine.currentScore))")

        if gameStartTime > 0 {
            let elapsed = lastUpdateTime - gameStartTime
            let seconds = Int(elapsed) % 60
            let minutes = Int(elapsed) / 60
            timerLabel.text = String(format: "%d:%02d", minutes, seconds)
        }
    }

    private func repositionHUD() {
        // Recalculate insets based on new size
        let halfW = size.width / 2 - 30
        let halfH = size.height / 2 - 30
        hudInsets = (horizontal: halfW, vertical: halfH)

        // Update timer position
        timerLabel?.position = CGPoint(x: -halfW, y: halfH - 20)
        if let timerBg = cameraNode.childNode(withName: "//timer_bg") as? SKShapeNode {
            timerBg.position = CGPoint(x: -halfW + 30, y: halfH - 15)
        }

        // Update hearts position
        for (index, heart) in heartNodes.enumerated() {
            heart.position = CGPoint(x: CGFloat(index - 1) * 30, y: halfH - 16)
        }

        // Update magnitude label position
        magnitudeLabel?.position = CGPoint(x: halfW, y: halfH - 20)
        if let magBg = cameraNode.childNode(withName: "//mag_bg") as? SKShapeNode {
            magBg.position = CGPoint(x: halfW - 28, y: halfH - 15)
        }

        // Update phase label position
        phaseLabel?.position = CGPoint(x: 0, y: halfH - 55)

        // Update score label position
        scoreLabel?.position = CGPoint(x: 0, y: halfH - 78)

        // Update instruction label position
        instructionLabel?.position = CGPoint(x: 0, y: -halfH + 10)
        if let instructBg = cameraNode.childNode(withName: "//instruction_bg") as? SKShapeNode {
            instructBg.position = CGPoint(x: 0, y: -halfH + 15)
        }
    }

    // MARK: - Vignette Effect

    private func setupVignette() {
        let vignette = SKShapeNode(
            rectOf: CGSize(width: size.width + 100, height: size.height + 100))
        vignette.fillColor = .black
        vignette.strokeColor = .clear
        vignette.alpha = 0
        vignette.zPosition = 50
        vignette.name = "vignette"
        cameraNode.addChild(vignette)
        vignetteNode = vignette
    }

    // MARK: - Game Flow

    private func startCalmPhase() {
        decisionEngine.updatePhase(.calm)
        instructionLabel.text = String(localized: "Get ready...")

        // Ensure menu theme is stopped before starting game audio
        AudioManager.shared.stopMenuTheme()

        // Play ambient audio during calm
        AudioManager.shared.prepareEngine()
        AudioManager.shared.playAmbient()

        // Apply calm vignette for night mode
        if scenario.lightingMode == .night {
            vignetteNode?.run(
                SKAction.fadeAlpha(to: scenario.lightingMode.calmVignetteAlpha, duration: 0.5))
        }

        // Countdown after calm (using scenario-specific duration)
        run(SKAction.wait(forDuration: scenario.calmDuration)) { [weak self] in
            self?.startCountdown()
        }
    }

    private func startCountdown() {
        decisionEngine.updatePhase(.countdown)
        countdownValue = 3

        // Fade out ambient
        AudioManager.shared.stopAmbient()

        showCountdownNumber()
    }

    private func showCountdownNumber() {
        guard countdownValue > 0 else {
            startEarthquake()
            return
        }

        let label = SKLabelNode(text: "\(countdownValue)")
        label.fontSize = DynamicTypeScale.scaled(100)
        label.fontName = "Helvetica-Bold"
        label.fontColor = SKColor(red: 0x1C / 255, green: 0x1C / 255, blue: 0x1E / 255, alpha: 1)
        label.position = .zero
        label.zPosition = 200
        label.setScale(0.3)
        cameraNode.addChild(label)

        AudioManager.shared.playTick()

        let scaleUp = SKAction.scale(to: 1.2, duration: 0.3)
        scaleUp.timingMode = .easeOut
        let wait = SKAction.wait(forDuration: 0.5)
        let fadeOutScale = SKAction.scale(to: 1.5, duration: 0.2)
        fadeOutScale.timingMode = .easeOut
        let fadeOutGroup = SKAction.group([
            SKAction.fadeOut(withDuration: 0.2),
            fadeOutScale,
        ])
        let remove = SKAction.removeFromParent()

        label.run(SKAction.sequence([scaleUp, wait, fadeOutGroup, remove])) { [weak self] in
            guard let self = self else { return }
            self.countdownValue -= 1
            self.showCountdownNumber()
        }
    }

    // MARK: - Phase Banner

    private func showPhaseBanner(text: String, color: SKColor, subtitle: String? = nil) {
        let banner = SKNode()
        banner.zPosition = 180
        banner.position = CGPoint(x: -(size.width / 2 + 150), y: 0)
        cameraNode.addChild(banner)

        // Pill background
        let pillWidth: CGFloat = 280
        let pillHeight: CGFloat = subtitle != nil ? 58 : 44
        let bg = SKShapeNode(
            rectOf: CGSize(width: pillWidth, height: pillHeight), cornerRadius: pillHeight / 2)
        bg.fillColor = color
        bg.strokeColor = SKColor(white: 1, alpha: 0.3)
        bg.lineWidth = 2
        bg.alpha = 0.92
        banner.addChild(bg)

        // Main text
        let label = SKLabelNode(text: text)
        label.fontSize = DynamicTypeScale.scaled(22)
        label.fontName = "Helvetica-Bold"
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.position = subtitle != nil ? CGPoint(x: 0, y: 7) : .zero
        banner.addChild(label)

        // Subtitle
        if let subtitle = subtitle {
            let sub = SKLabelNode(text: subtitle)
            sub.fontSize = DynamicTypeScale.scaled(13)
            sub.fontName = "Helvetica"
            sub.fontColor = SKColor(white: 1, alpha: 0.8)
            sub.verticalAlignmentMode = .center
            sub.position = CGPoint(x: 0, y: -12)
            banner.addChild(sub)
        }

        // Impact scale: start slightly larger, settle to 1.0 when slide finishes (SSC polish)
        banner.setScale(1.05)
        let slideIn = SKAction.moveTo(x: 0, duration: 0.35)
        slideIn.timingMode = .easeOut
        let impactScale = SKAction.scale(to: 1.0, duration: 0.12)
        impactScale.timingMode = .easeOut
        let stay = SKAction.wait(forDuration: 1.4)
        let slideOut = SKAction.moveTo(x: size.width / 2 + 150, duration: 0.3)
        slideOut.timingMode = .easeIn

        banner.run(SKAction.sequence([slideIn, impactScale, stay, slideOut, SKAction.removeFromParent()]))
    }

    // MARK: - Educational Phase Narration

    /// Shows educational narration at phase transitions with learning moments

    // MARK: - Phase Extensions

    private func startEarthquake() {
        gameStartTime = lastUpdateTime

        // Initialize decision engine timing for proper response time calculation
        decisionEngine.startQuake(at: lastUpdateTime)

        instructionLabel.text = String(localized: "⚠️ TAP where to take cover!")
        phaseLabel.text = String(localized: "EARTHQUAKE!")
        phaseLabel.fontColor = AppColors.skWrong

        // Cinematic phase banner
        showPhaseBanner(
            text: String(localized: "EARTHQUAKE!"), color: AppColors.skWrong,
            subtitle: String(localized: "Find cover now!"))

        // Respect Reduced Motion setting - use color changes instead of shake
        if isReduceMotionEnabled {
            startReducedMotionEarthquake()
        } else {
            shakeController.startEarthquake(scenario: scenario)
        }
        physicsManager.addDustParticles(in: self, intensity: scenario.effectiveIntensityMultiplier)

        // Haptics
        HapticManager.shared.prepareEngine()
        HapticManager.shared.playPWave()

        // Audio
        AudioManager.shared.prepareEngine()
        AudioManager.shared.playRumble(intensity: Float(scenario.effectiveIntensityMultiplier))

        // Transition lighting: warm → cold (based on scenario)
        let lightingMode = scenario.lightingMode
        warmOverlay?.run(SKAction.fadeOut(withDuration: lightingMode == .surprise ? 0.3 : 1.5))

        // Create cold overlay on demand if not already created
        if coldOverlay == nil {
            let overlaySize = CGSize(width: size.width + 100, height: size.height + 100)
            let cold = SKSpriteNode(
                color: SKColor(red: 0.6, green: 0.65, blue: 0.75, alpha: 1.0), size: overlaySize)
            cold.blendMode = .alpha
            cold.alpha = 0
            cold.zPosition = 46
            cold.name = "cold_overlay"
            cameraNode.addChild(cold)
            coldOverlay = cold
        }
        coldOverlay?.run(
            SKAction.fadeAlpha(
                to: lightingMode.coldOverlayAlpha, duration: lightingMode == .surprise ? 0.5 : 2.0))

        // Darken background based on lighting mode
        if lightingMode == .night {
            // Even darker for night
            backgroundColor = SKColor(
                red: 0x12 / 255, green: 0x15 / 255, blue: 0x20 / 255, alpha: 1)
        } else {
            backgroundColor = AppColors.skDangerBackground
        }
        vignetteNode?.run(
            SKAction.fadeAlpha(
                to: lightingMode.quakeVignetteAlpha, duration: lightingMode == .surprise ? 0.3 : 1.0
            ))

        // Initialize creaking timer
        lastCreakTime = lastUpdateTime
        nextCreakInterval = Double.random(in: 2.0...4.0)

        // Activate lamp flicker during earthquake
        if let lampGlow = childNode(withName: "//lamp_glow") {
            // Resume flicker animation
            lampGlow.speed = 1.0
            // Increase sway intensity
            if let lamp = childNode(withName: "//lamp") {
                lamp.removeAction(forKey: "sway")
                let intenseSwayRight = SKAction.rotate(toAngle: 0.08, duration: 0.8)
                intenseSwayRight.timingMode = .easeInEaseOut
                let intenseSwayLeft = SKAction.rotate(toAngle: -0.08, duration: 0.8)
                intenseSwayLeft.timingMode = .easeInEaseOut
                lamp.run(
                    SKAction.repeatForever(SKAction.sequence([intenseSwayRight, intenseSwayLeft])),
                    withKey: "sway")
            }
        }

        // Announce earthquake start for VoiceOver
        announcePhaseChange(.pWave)
    }

    // MARK: - Reduced Motion Support

    private func startReducedMotionEarthquake() {
        // For users with Reduced Motion enabled, use color pulsing instead of screen shake
        // This maintains the intensity feedback without causing motion sickness

        let pulseIntensity = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 0.3),
            SKAction.fadeAlpha(to: 0.3, duration: 0.3),
        ])

        // Vignette pulsing to indicate intensity
        vignetteNode?.run(SKAction.repeat(pulseIntensity, count: 20))

        // Cold overlay intensification
        coldOverlay?.run(SKAction.fadeAlpha(to: 0.3, duration: 2.0))

        // Still trigger object physics for gameplay
        run(
            SKAction.sequence([
                SKAction.wait(forDuration: 2.0),
                SKAction.run { [weak self] in
                    self?.physicsManager.triggerObjectPhysics(intensity: 0.7)
                },
            ]))

        // Trigger aftershock sequence without shake
        run(
            SKAction.sequence([
                SKAction.wait(forDuration: 8.0),
                SKAction.run { [weak self] in
                    self?.shakePhaseDidChange(.aftershock)
                },
            ]))
    }

    // MARK: - Phase Transitions (from ShakeController)

    nonisolated func shakeIntensityDidChange(_ intensity: CGFloat, phase: QuakePhase) {
        Task { @MainActor in
            self.physicsManager.triggerObjectPhysics(intensity: intensity)
            AudioManager.shared.updateRumbleIntensity(Float(intensity))

            // Update vignette based on shake intensity
            self.updateVignetteForIntensity(intensity)
        }
    }

    @MainActor
    private func updateVignetteForIntensity(_ intensity: CGFloat) {
        guard let vignette = vignetteNode else { return }
        let targetAlpha = 0.3 + (intensity * 0.4)  // 0.3 to 0.7 based on intensity
        vignette.run(SKAction.fadeAlpha(to: targetAlpha, duration: 0.1))
    }

    func shakeControllerDidTriggerImpact(_ intensity: CGFloat, position: CGPoint) {
        // Add impact particles at the impact position
        physicsManager.addImpactParticles(at: position, in: self)

        // Play impact sound
        AudioManager.shared.playImpact()

        // Trigger haptic
        HapticManager.shared.playImpact()

        // Enhanced screen flash for major impacts
        if intensity > 0.6 {
            flashImpact(
                color: SKColor(red: 0.9, green: 0.3, blue: 0.1, alpha: 0.3),
                position: position,
                magnitude: intensity)
        }
    }

    func shakeControllerDidUpdateDustIntensity(_ intensity: CGFloat) {
        // Dust intensity is already handled by the initial setup
        // This could be used to dynamically adjust dust emission
        if let dustEmitter = childNode(withName: "dust_emitter") as? SKEmitterNode {
            dustEmitter.particleBirthRate = intensity
        }
    }

    nonisolated func shakePhaseDidChange(_ phase: QuakePhase) {
        Task { @MainActor in
            self.decisionEngine.updatePhase(phase)

            // Show educational phase narration

            // Announce phase change for VoiceOver users
            self.announcePhaseChange(phase)

            switch phase {
            case .pWave:
                // Suggest safe zone on first opportunity
                if !self.hasAnnouncedSafeZone {
                    self.hasAnnouncedSafeZone = true
                    self.postAccessibilityAnnouncement(
                        "Double tap the \(self.currentRoomType.safeZoneName.lowercased()) area to take cover.",
                        delay: 2.0)
                }

                // Show hint after 3 seconds if player hasn't moved
                self.run(
                    SKAction.sequence([
                        SKAction.wait(forDuration: 3.0),
                        SKAction.run { [weak self] in
                            guard let self = self,
                                !self.hasProcessedMainDecision
                            else { return }
                            self.showContextualHint()
                        },
                    ]), withKey: "pwave_hint")

            case .sWave:
                self.phaseLabel.text = String(localized: "INTENSE SHAKING!")
                self.instructionLabel.text = String(
                    localized: "⚠️ TAP the \(self.currentRoomType.safeZoneName) to take cover!")
                self.showPhaseBanner(
                    text: String(localized: "INTENSE SHAKING!"), color: AppColors.skWrong,
                    subtitle: String(localized: "Hold on!"))

                // Show hint immediately if player isn't under cover
                if !self.isPlayerUnderCover {
                    self.showContextualHint()
                }

                // Start heartbeat during intense shaking
                AudioManager.shared.startHeartbeat()

                // Intensify cold overlay
                self.coldOverlay?.run(SKAction.fadeAlpha(to: 0.25, duration: 1.0))

            case .aftershock:
                self.phaseLabel.text = String(localized: "Aftershock...")
                self.phaseLabel.fontColor = AppColors.skWarning
                self.instructionLabel.text = String(localized: "Tap icons to start safety tasks!")
                self.showAftershockZones()

                // Start tilt control if enabled and available
                if SettingsManager.shared.tiltControlEnabled
                    && !SettingsManager.shared.isReducedMotionEnabled
                {
                    MotionManager.shared.startTiltUpdates()
                }

                // Room-specific ambient particles
                self.addRoomAmbientParticles()

                // Stop heartbeat
                AudioManager.shared.stopHeartbeat()

                // Ease cold overlay
                self.coldOverlay?.run(SKAction.fadeAlpha(to: 0.1, duration: 1.0))

                // If player hasn't made a main decision, penalize for inaction
                if !self.hasProcessedMainDecision {
                    let decision = self.decisionEngine.recordDecision(
                        .stayStanding, at: self.lastUpdateTime)
                    self.showDecisionFeedback(decision)
                }

            case .debrief:
                self.postAccessibilityAnnouncement(
                    "Simulation complete. Final score: \(self.decisionEngine.currentScore) points. You had \(self.decisionEngine.heartsRemaining) of 3 hearts remaining."
                )
                self.endGame()

            default:
                break
            }
        }
    }

    // MARK: - Aftershock Zones

    /// Animates a task zone with a satisfying "jump and bounce" entrance animation.
    /// The animation completes before the zone becomes interactive.
    private func animateTaskZoneEntrance(zone: SKNode, completion: @escaping () -> Void) {
        isTaskAnimatingIn = true

        // Store final position
        let finalY = zone.position.y
        let startY = finalY + 80  // Start 80 points above

        // Start position: above and scaled down
        zone.position = CGPoint(x: zone.position.x, y: startY)
        zone.setScale(0.1)
        zone.alpha = 0

        // Jump arc: parabolic motion with bounce settle
        let jumpDown = SKAction.moveTo(y: finalY - 12, duration: 0.22)
        jumpDown.timingMode = .easeOut

        let bounceUp = SKAction.moveTo(y: finalY + 4, duration: 0.14)
        bounceUp.timingMode = .easeOut

        let settleDown = SKAction.moveTo(y: finalY - 2, duration: 0.08)
        settleDown.timingMode = .easeIn

        let finalSettle = SKAction.moveTo(y: finalY, duration: 0.06)
        finalSettle.timingMode = .easeOut

        // Scale animations with elastic bounce
        let scaleIn = SKAction.scale(to: 1.25, duration: 0.22)
        scaleIn.timingMode = .easeOut

        let scaleBounce = SKAction.scale(to: 0.9, duration: 0.14)
        scaleBounce.timingMode = .easeOut

        let scaleSettle = SKAction.scale(to: 1.08, duration: 0.08)
        scaleSettle.timingMode = .easeIn

        let scaleFinal = SKAction.scale(to: 1.0, duration: 0.06)
        scaleFinal.timingMode = .easeOut

        // Fade in quickly at start
        let fadeIn = SKAction.fadeIn(withDuration: 0.15)

        let entrance = SKAction.sequence([
            // Wait a beat before showing
            SKAction.wait(forDuration: 0.3),
            // Fade in quickly
            fadeIn,
            // Jump down with scale in
            SKAction.group([jumpDown, scaleIn]),
            // Bounce up with scale bounce
            SKAction.group([bounceUp, scaleBounce]),
            // Settle down
            SKAction.group([settleDown, scaleSettle]),
            // Final settle
            SKAction.group([finalSettle, scaleFinal]),
            // Mark as interactive after animation
            SKAction.run { [weak self] in
                self?.isTaskAnimatingIn = false
                completion()
            },
        ])

        zone.run(entrance, withKey: "task_entrance")
    }

    private func showAftershockZones() {
        // Trigger falling debris cascade as aftershock phase begins (aftermath of earthquake)
        runPostAftershockDebrisFall()

        // Reset task state for sequential progression
        currentTaskIndex = 0
        processedAftershockActions.removeAll()

        // Hide all zones initially and remove any existing animations
        for (name, _) in aftershockTasks {
            if let zone = childNode(withName: name) {
                zone.alpha = 0
                zone.removeAllActions()
                // Remove any existing glow rings
                zone.childNode(withName: "\(name)_glow")?.removeFromParent()
            }
        }

        // Show only the first task
        showNextAftershockTask()
    }

    /// Shows the next aftershock task in the sequential queue.
    /// When all tasks are complete, ends the earthquake.
    private func showNextAftershockTask() {
        guard currentTaskIndex < aftershockTasks.count else {
            // All tasks complete, end earthquake
            NSLog("[TASK] All aftershock tasks complete, ending earthquake")
            shakeController.stopEarthquake()
            return
        }

        let task = aftershockTasks[currentTaskIndex]
        guard let zone = childNode(withName: task.name) else {
            NSLog("[TASK] Zone '\(task.name)' not found, skipping to next task")
            currentTaskIndex += 1
            showNextAftershockTask()
            return
        }

        NSLog("[TASK] Showing task \(currentTaskIndex + 1)/\(aftershockTasks.count): \(task.name)")

        // Setup zone appearance with glow ring and colors
        setupZoneAppearance(zone, taskName: task.name)

        // Animate entrance with jump and bounce
        animateTaskZoneEntrance(zone: zone) {
            // Enable interaction after animation completes
            NSLog("[TASK] \(task.name) entrance animation complete, now interactive")
        }

        // Start task-specific special animations
        startTaskSpecificAnimations(for: task.name, zone: zone)
    }

    /// Sets up the visual appearance of a task zone with glow ring and colors.
    private func setupZoneAppearance(_ zone: SKNode, taskName: String) {
        let zoneColors: [String: SKColor] = [
            "gas_valve": SKColor(red: 1.0, green: 0.2, blue: 0.1, alpha: 1.0),
            "safe_exit": SKColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 1.0),
            "injury_check": SKColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 1.0),
        ]

        let color = zoneColors[taskName] ?? .white

        // Add glow ring behind icon
        let glowRing = SKShapeNode(circleOfRadius: 30)
        glowRing.fillColor = color.withAlphaComponent(HighContrast.glowFillAlpha)
        glowRing.strokeColor = color.withAlphaComponent(HighContrast.glowStrokeAlpha)
        glowRing.lineWidth = HighContrast.glowLineWidth
        glowRing.zPosition = -1
        glowRing.name = "\(taskName)_glow"
        glowRing.alpha = 0
        zone.addChild(glowRing)

        // Glow pulse animation (starts after entrance)
        let glowPulse = SKAction.repeatForever(
            SKAction.sequence([
                SKAction.fadeAlpha(to: 0.8, duration: 0.6),
                SKAction.fadeAlpha(to: 0.4, duration: 0.6),
            ]))

        // Fade in glow ring after entrance
        run(
            SKAction.sequence([
                SKAction.wait(forDuration: 0.8),  // Wait for entrance animation
                SKAction.run {
                    glowRing.run(
                        SKAction.sequence([
                            SKAction.fadeIn(withDuration: 0.2),
                            glowPulse,
                        ]))
                },
            ]))

        // Gentle ongoing pulse for the zone itself
        let pulse = SKAction.repeatForever(
            SKAction.sequence([
                SKAction.scale(to: 1.08, duration: 0.5),
                SKAction.scale(to: 1.0, duration: 0.5),
            ]))
        run(
            SKAction.sequence([
                SKAction.wait(forDuration: 0.8),
                SKAction.run { zone.run(pulse, withKey: "task_pulse") },
            ]))
    }

    /// Starts task-specific animations for gas valve and injury check zones.
    private func startTaskSpecificAnimations(for taskName: String, zone: SKNode) {
        // Special gas valve animations
        if taskName == "gas_valve" {
            // Animate pipe segment
            if let pipe = childNode(withName: "gas_valve_pipe") {
                pipe.alpha = 0
                pipe.run(
                    SKAction.sequence([
                        SKAction.wait(forDuration: 0.8),
                        SKAction.fadeIn(withDuration: 0.3),
                    ]))
            }

            // Animate warning glow with faster pulse
            if let warningGlow = childNode(withName: "gas_valve_glow") {
                warningGlow.alpha = 0
                let fastPulse = SKAction.repeatForever(
                    SKAction.sequence([
                        SKAction.fadeAlpha(to: 0.6, duration: 0.4),
                        SKAction.fadeAlpha(to: 0.2, duration: 0.4),
                    ]))
                warningGlow.run(
                    SKAction.sequence([
                        SKAction.wait(forDuration: 0.9),
                        SKAction.fadeIn(withDuration: 0.3),
                        fastPulse,
                    ]))
            }

            // Fade in gas emitter
            if let gasEmitter = childNode(withName: "gas_valve_emitter") as? SKEmitterNode {
                gasEmitter.run(
                    SKAction.sequence([
                        SKAction.wait(forDuration: 1.3),
                        SKAction.fadeIn(withDuration: 0.5),
                    ]))
            }

            // Room-level gas cloud leak — visible green clouds billowing from the pipe area
            startRoomGasLeakEffect(near: zone)
        }

        // Special injury check animations
        if taskName == "injury_check" {
            // Medical cross floor marker
            if let floorMarker = zone.childNode(withName: "injury_floor_marker") {
                floorMarker.alpha = 0
                floorMarker.setScale(0.5)
                floorMarker.run(
                    SKAction.sequence([
                        SKAction.wait(forDuration: 1.1),
                        SKAction.group([
                            SKAction.fadeAlpha(to: 0.6, duration: 0.3),
                            SKAction.scale(to: 1.0, duration: 0.3),
                        ]),
                    ]))
            }

            // Healing sparkle emitter
            if let healingEmitter = zone.childNode(withName: "injury_healing_emitter")
                as? SKEmitterNode
            {
                healingEmitter.alpha = 0
                healingEmitter.run(
                    SKAction.sequence([
                        SKAction.wait(forDuration: 1.2),
                        SKAction.fadeIn(withDuration: 0.5),
                    ]))
            }

            // Heart rate pulse ring
            if let pulseRing = zone.childNode(withName: "injury_pulse_ring") {
                pulseRing.alpha = 0
                let heartbeat = SKAction.repeatForever(
                    SKAction.sequence([
                        SKAction.group([
                            SKAction.scale(to: 1.15, duration: 0.15),
                            SKAction.fadeAlpha(to: 0.5, duration: 0.15),
                        ]),
                        SKAction.group([
                            SKAction.scale(to: 1.0, duration: 0.15),
                            SKAction.fadeAlpha(to: 0.3, duration: 0.15),
                        ]),
                        SKAction.wait(forDuration: 0.4),
                        SKAction.group([
                            SKAction.scale(to: 1.1, duration: 0.1),
                            SKAction.fadeAlpha(to: 0.45, duration: 0.1),
                        ]),
                        SKAction.group([
                            SKAction.scale(to: 1.0, duration: 0.1),
                            SKAction.fadeAlpha(to: 0.3, duration: 0.1),
                        ]),
                        SKAction.wait(forDuration: 0.6),
                    ]))
                pulseRing.run(
                    SKAction.sequence([
                        SKAction.wait(forDuration: 1.3),
                        SKAction.fadeAlpha(to: 0.3, duration: 0.3),
                        heartbeat,
                    ]))
            }

            // Medical supplies scattered nearby
            if let supplies = zone.childNode(withName: "medical_supplies") {
                supplies.alpha = 0
                supplies.setScale(0.8)
                supplies.run(
                    SKAction.sequence([
                        SKAction.wait(forDuration: 1.4),
                        SKAction.group([
                            SKAction.fadeIn(withDuration: 0.3),
                            SKAction.scale(to: 1.0, duration: 0.3),
                        ]),
                    ]))
            }

            // Extra healing sparkle burst on entrance
            let extraSparkle = SKAction.run { [weak self] in
                guard let self = self else { return }
                let sparkles = ParticleEffects.healingSparkles(at: zone.position, intensity: 0.8)
                self.addChild(sparkles)
                sparkles.run(
                    SKAction.sequence([
                        SKAction.wait(forDuration: 1.5),
                        SKAction.removeFromParent(),
                    ]))
            }
            run(
                SKAction.sequence([
                    SKAction.wait(forDuration: 1.3),
                    extraSparkle,
                ]))
        }

        // Special safe exit animations
        if taskName == "safe_exit" {
            startRoomBlockedDoorEffect(near: zone)
        }
    }

    /// Spawns visible green gas clouds in the room around the gas valve pipe area.
    /// Clouds drift upward and spread, creating an urgent atmosphere.
    private func startRoomGasLeakEffect(near zone: SKNode) {
        let pipePos = childNode(withName: "gas_valve_pipe")?.position ?? zone.position

        // Container for all room gas clouds so we can remove them easily
        let gasContainer = SKNode()
        gasContainer.name = "room_gas_leak"
        gasContainer.zPosition = 6
        addChild(gasContainer)

        // Spawn gas clouds continuously from the pipe crack area
        let spawnCloud = SKAction.run { [weak self, weak gasContainer] in
            guard let self = self, let container = gasContainer else { return }
            let cloud = SKShapeNode(circleOfRadius: CGFloat.random(in: 6...18))
            cloud.fillColor = SKColor(red: 0.35, green: 0.55, blue: 0.25, alpha: CGFloat.random(in: 0.3...0.55))
            cloud.strokeColor = .clear
            cloud.position = CGPoint(
                x: pipePos.x + CGFloat.random(in: -12...12),
                y: pipePos.y + CGFloat.random(in: -5...15)
            )
            container.addChild(cloud)

            // Drift upward and outward, expand, then fade
            cloud.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(
                        x: CGFloat.random(in: -50...50),
                        y: CGFloat.random(in: 40...100),
                        duration: 2.0
                    ),
                    SKAction.scale(to: CGFloat.random(in: 2.0...4.5), duration: 2.0),
                    SKAction.fadeOut(withDuration: 2.0),
                ]),
                SKAction.removeFromParent(),
            ]))
        }

        // Start after a short delay to sync with zone entrance
        gasContainer.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.8),
            SKAction.repeatForever(SKAction.sequence([
                spawnCloud,
                SKAction.wait(forDuration: 0.12),
            ])),
        ]), withKey: "room_gas_spawn")

        // Haze overlay near the valve — a lingering fog patch
        let haze = SKShapeNode(ellipseOf: CGSize(width: 120, height: 60))
        haze.fillColor = SKColor(red: 0.35, green: 0.5, blue: 0.25, alpha: 0.12)
        haze.strokeColor = .clear
        haze.position = CGPoint(x: pipePos.x, y: pipePos.y + 40)
        haze.name = "room_gas_haze"
        haze.alpha = 0
        gasContainer.addChild(haze)

        haze.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.fadeAlpha(to: 0.8, duration: 0.5),
            SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.5, duration: 1.0),
                SKAction.fadeAlpha(to: 0.8, duration: 1.0),
            ])),
        ]))
    }

    /// Stops room-level gas leak clouds (called after gas valve mini-game completes or fails).
    private func stopRoomGasLeakEffect() {
        if let gasContainer = childNode(withName: "room_gas_leak") {
            gasContainer.removeAction(forKey: "room_gas_spawn")
            // Fade out all remaining clouds gracefully
            gasContainer.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.8),
                SKAction.removeFromParent(),
            ]))
        }
    }

    /// Shows debris blocking the door in the room and spawns dust particles around it.
    private func startRoomBlockedDoorEffect(near zone: SKNode) {
        // Reveal the pre-built debris container
        if let debrisContainer = childNode(withName: "door_debris") {
            debrisContainer.alpha = 0

            // Stagger each piece falling into place
            let pieces = ["door_debris_beam", "door_debris_chunk", "door_debris_plank"]
            for (i, name) in pieces.enumerated() {
                if let piece = debrisContainer.childNode(withName: name) {
                    let originalPos = piece.position
                    let originalRot = piece.zRotation
                    // Start above and drop in
                    piece.position = CGPoint(x: originalPos.x + CGFloat.random(in: -10...10),
                                             y: originalPos.y + 80)
                    piece.zRotation = originalRot + CGFloat.random(in: -0.3...0.3)
                    piece.alpha = 0

                    piece.run(SKAction.sequence([
                        SKAction.wait(forDuration: 0.8 + Double(i) * 0.25),
                        SKAction.group([
                            SKAction.fadeIn(withDuration: 0.15),
                            SKAction.move(to: originalPos, duration: 0.3),
                            SKAction.rotate(toAngle: originalRot, duration: 0.3),
                        ]),
                        // Impact bounce
                        SKAction.sequence([
                            SKAction.moveBy(x: 0, y: -4, duration: 0.05),
                            SKAction.moveBy(x: 0, y: 4, duration: 0.08),
                        ]),
                    ]))
                }
            }

            // Fade in the container and dust haze
            debrisContainer.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.7),
                SKAction.fadeIn(withDuration: 0.2),
            ]))

            // Dust haze pulse
            if let dust = debrisContainer.childNode(withName: "door_debris_dust") {
                dust.alpha = 0
                dust.run(SKAction.sequence([
                    SKAction.wait(forDuration: 1.5),
                    SKAction.fadeAlpha(to: 0.7, duration: 0.3),
                    SKAction.repeatForever(SKAction.sequence([
                        SKAction.fadeAlpha(to: 0.4, duration: 1.2),
                        SKAction.fadeAlpha(to: 0.7, duration: 1.2),
                    ])),
                ]))
            }
        }

        // Spawn settling dust particles near the door
        let doorX: CGFloat = 70
        let dustContainer = SKNode()
        dustContainer.name = "room_door_dust"
        dustContainer.zPosition = 4
        addChild(dustContainer)

        let spawnDust = SKAction.run { [weak dustContainer] in
            guard let container = dustContainer else { return }
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...5))
            particle.fillColor = SKColor(white: CGFloat.random(in: 0.6...0.85),
                                         alpha: CGFloat.random(in: 0.3...0.5))
            particle.strokeColor = .clear
            particle.position = CGPoint(
                x: doorX + CGFloat.random(in: -35...35),
                y: RoomLayout.floorHeight + CGFloat.random(in: 20...120)
            )
            container.addChild(particle)

            particle.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: CGFloat.random(in: -20...20),
                                    y: CGFloat.random(in: -15...25),
                                    duration: 1.5),
                    SKAction.fadeOut(withDuration: 1.5),
                    SKAction.scale(to: CGFloat.random(in: 1.5...2.5), duration: 1.5),
                ]),
                SKAction.removeFromParent(),
            ]))
        }

        dustContainer.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.repeatForever(SKAction.sequence([
                spawnDust,
                SKAction.wait(forDuration: 0.2),
            ])),
        ]), withKey: "room_door_dust_spawn")
    }

    /// Clears door debris from the room after the safe exit mini-game.
    private func stopRoomBlockedDoorEffect() {
        // Fade out dust particles
        if let dustContainer = childNode(withName: "room_door_dust") {
            dustContainer.removeAction(forKey: "room_door_dust_spawn")
            dustContainer.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.6),
                SKAction.removeFromParent(),
            ]))
        }

        // Animate debris pieces flying away, then remove
        if let debrisContainer = childNode(withName: "door_debris") {
            let pieces = ["door_debris_beam", "door_debris_chunk", "door_debris_plank"]
            for (i, name) in pieces.enumerated() {
                if let piece = debrisContainer.childNode(withName: name) {
                    let dir: CGFloat = (i % 2 == 0) ? -1 : 1
                    piece.run(SKAction.sequence([
                        SKAction.wait(forDuration: Double(i) * 0.1),
                        SKAction.group([
                            SKAction.moveBy(x: dir * 120, y: CGFloat.random(in: 20...60), duration: 0.4),
                            SKAction.rotate(byAngle: dir * .pi * 0.5, duration: 0.4),
                            SKAction.fadeOut(withDuration: 0.4),
                        ]),
                    ]))
                }
            }

            // Remove container after animations
            debrisContainer.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.6),
                SKAction.fadeOut(withDuration: 0.3),
                SKAction.removeFromParent(),
            ]))
        }
    }

    /// Spawns a dramatic cascade of falling debris after aftershock tasks complete.
    /// Various items fall from ceiling height and scatter across the floor.
    private func runPostAftershockDebrisFall() {
        let debrisContainer = SKNode()
        debrisContainer.name = "post_aftershock_debris"
        debrisContainer.zPosition = 5
        addChild(debrisContainer)

        // Debris types: various sizes and colors to create chaos
        let debrisTypes: [(size: CGSize, color: SKColor, shape: String)] = [
            (CGSize(width: 25, height: 8), SKColor(red: 0.50, green: 0.35, blue: 0.20, alpha: 1.0), "plank"),
            (CGSize(width: 18, height: 18), SKColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0), "chunk"),
            (CGSize(width: 12, height: 16), SKColor(red: 0.45, green: 0.30, blue: 0.18, alpha: 1.0), "wood"),
            (CGSize(width: 8, height: 10), SKColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0), "rubble"),
            (CGSize(width: 30, height: 6), SKColor(red: 0.55, green: 0.40, blue: 0.25, alpha: 1.0), "beam"),
        ]

        // Spawn 30-40 debris pieces falling from ceiling
        let debrisCount = Int.random(in: 30...40)
        for i in 0..<debrisCount {
            let type = debrisTypes.randomElement()!
            let debris = createDebrisPiece(size: type.size, color: type.color, shape: type.shape)

            // Start near ceiling, scattered across room width
            let startX = CGFloat.random(in: 50...size.width - 50)
            let startY = size.height - CGFloat.random(in: 20...100)
            debris.position = CGPoint(x: startX, y: startY)

            // Random initial rotation
            debris.zRotation = CGFloat.random(in: -0.3...0.3)

            debrisContainer.addChild(debris)

            // Stagger fall times for cascading effect
            let delay = Double(i) * 0.04 + Double.random(in: 0...0.1)
            let fallDistance = startY - RoomLayout.floorHeight - CGFloat.random(in: 0...30)
            let fallDuration = fallDistance / 600 // Fall speed

            debris.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.group([
                    // Fall with gravity acceleration feel
                    SKAction.moveBy(x: CGFloat.random(in: -30...30), y: -fallDistance, duration: fallDuration),
                    // Tumble while falling
                    SKAction.rotate(byAngle: CGFloat.random(in: -2...2), duration: fallDuration),
                ]),
                // Impact bounce/land
                SKAction.run { [weak self] in
                    // Small dust puff on landing
                    if let self = self {
                        let dust = self.createDebrisDust()
                        dust.position = debris.position
                        dust.position.y = RoomLayout.floorHeight + 5
                        debrisContainer.addChild(dust)
                        dust.run(SKAction.sequence([
                            SKAction.scale(to: 1.5, duration: 0.2),
                            SKAction.fadeOut(withDuration: 0.3),
                            SKAction.removeFromParent()
                        ]))
                    }
                    // Small bounce on impact
                    debris.run(SKAction.sequence([
                        SKAction.moveBy(x: 0, y: 3, duration: 0.05),
                        SKAction.moveBy(x: 0, y: -3, duration: 0.05),
                    ]))
                },
            ]))
        }

        // Add some ceiling chunks (larger, more dramatic)
        for _ in 0..<5 {
            let chunk = createDebrisPiece(size: CGSize(width: 35, height: 25),
                                         color: SKColor(red: 0.65, green: 0.65, blue: 0.65, alpha: 1.0),
                                         shape: "ceiling")
            chunk.position = CGPoint(x: CGFloat.random(in: 100...size.width - 100),
                                     y: size.height - 30)
            chunk.zRotation = CGFloat.random(in: -0.2...0.2)
            debrisContainer.addChild(chunk)

            let fallDistance = size.height - 30 - RoomLayout.floorHeight - 10
            let delay = Double.random(in: 0.3...0.8)

            chunk.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.group([
                    SKAction.moveBy(x: CGFloat.random(in: -20...20), y: -fallDistance, duration: 0.6),
                    SKAction.rotate(byAngle: CGFloat.random(in: -1...1), duration: 0.6),
                ]),
                SKAction.run { [weak self] in
                    // Larger dust cloud for big chunk
                    if let self = self {
                        let dust = self.createDebrisDust()
                        dust.setScale(2.5)
                        dust.position = chunk.position
                        dust.position.y = RoomLayout.floorHeight + 10
                        debrisContainer.addChild(dust)
                        dust.run(SKAction.sequence([
                            SKAction.scale(to: 3.5, duration: 0.3),
                            SKAction.fadeOut(withDuration: 0.4),
                            SKAction.removeFromParent()
                        ]))
                    }
                    // Heavy impact shake
                    chunk.run(SKAction.sequence([
                        SKAction.moveBy(x: 0, y: 5, duration: 0.06),
                        SKAction.moveBy(x: 0, y: -5, duration: 0.06),
                    ]))
                },
            ]))
        }

        // Dust haze settling across the floor after debris falls
        let floorHaze = SKShapeNode(rectOf: CGSize(width: size.width, height: 60))
        floorHaze.fillColor = SKColor(white: CGFloat.random(in: 0.6...0.8), alpha: 0)
        floorHaze.strokeColor = .clear
        floorHaze.position = CGPoint(x: size.width / 2, y: RoomLayout.floorHeight + 30)
        floorHaze.zPosition = 4
        debrisContainer.addChild(floorHaze)

        floorHaze.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.5),
            SKAction.fadeAlpha(to: 0.15, duration: 0.8),
            SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.12, duration: 2.0),
                SKAction.fadeAlpha(to: 0.15, duration: 2.0),
            ])),
        ]))
    }

    /// Creates a single debris piece with appropriate shape and styling.
    private func createDebrisPiece(size: CGSize, color: SKColor, shape: String) -> SKNode {
        let container = SKNode()

        let debris: SKShapeNode
        switch shape {
        case "plank", "beam", "wood":
            debris = SKShapeNode(rectOf: size, cornerRadius: 2)
        case "chunk", "ceiling", "rubble":
            // Irregular polygon for chunks
            let path = CGMutablePath()
            path.move(to: CGPoint(x: -size.width/2, y: -size.height/2))
            path.addLine(to: CGPoint(x: size.width/2 - CGFloat.random(in: 0...5), y: -size.height/2 + CGFloat.random(in: 0...5)))
            path.addLine(to: CGPoint(x: size.width/2 - CGFloat.random(in: 0...5), y: size.height/2 - CGFloat.random(in: 0...5)))
            path.addLine(to: CGPoint(x: -size.width/2 + CGFloat.random(in: 0...5), y: size.height/2))
            path.closeSubpath()
            debris = SKShapeNode(path: path)
        default:
            debris = SKShapeNode(rectOf: size, cornerRadius: 2)
        }

        debris.fillColor = color
        debris.strokeColor = SKColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 0.8)
        debris.lineWidth = 1.5
        container.addChild(debris)

        // Add crack/detail to larger pieces
        if size.width > 20 {
            let crack = SKShapeNode()
            let crackPath = CGMutablePath()
            let startX = CGFloat.random(in: -size.width/4...size.width/4)
            crackPath.move(to: CGPoint(x: startX, y: -size.height/4))
            crackPath.addLine(to: CGPoint(x: startX + CGFloat.random(in: -5...5), y: size.height/4))
            crack.path = crackPath
            crack.strokeColor = SKColor(white: 0.0, alpha: 0.25)
            crack.lineWidth = 1
            container.addChild(crack)
        }

        return container
    }

    /// Creates a small dust puff effect for debris landing.
    private func createDebrisDust() -> SKNode {
        let dust = SKShapeNode(circleOfRadius: 8)
        dust.fillColor = SKColor(white: 0.75, alpha: 0.5)
        dust.strokeColor = .clear
        return dust
    }

    // MARK: - Room Ambient Particles

    private func addRoomAmbientParticles() {
        let emitter: SKEmitterNode
        let pos: CGPoint

        switch currentRoomType {
        case .kitchen:
            // Water spray near sink area
            emitter = ParticleEffects.waterSpray(
                at: .zero, direction: .pi / 2, intensity: 0.3
            )
            pos = CGPoint(x: size.width * 0.3, y: RoomLayout.floorHeight + 60)
        case .office:
            // Electrical smoke near desk
            emitter = ParticleEffects.electricalSmoke(
                at: .zero, intensity: 0.3
            )
            pos = CGPoint(x: size.width * 0.5, y: RoomLayout.floorHeight + 80)
        case .livingRoom:
            // Pipe steam from wall
            emitter = ParticleEffects.pipeSteam(
                at: .zero, intensity: 0.3
            )
            pos = CGPoint(x: 40, y: RoomLayout.floorHeight + 120)
        case .bedroom:
            // Settling dust from ceiling
            emitter = ParticleEffects.settlingDust(duration: 6.0, intensity: 0.4)
            pos = CGPoint(x: size.width * 0.5, y: size.height - 40)
        }

        emitter.position = pos
        addChild(emitter)

        // Auto-remove after 8s
        emitter.run(
            SKAction.sequence([
                SKAction.wait(forDuration: 6.0),
                SKAction.run { emitter.particleBirthRate = 0 },
                SKAction.wait(forDuration: 2.0),
                SKAction.removeFromParent(),
            ]))
    }

    // MARK: - Story Slideshow

    private func startStorySequence() {
        isStoryPlaying = true
        currentStorySlide = 0
        decisionEngine.updatePhase(.story)

        // Ensure menu theme is stopped
        AudioManager.shared.stopMenuTheme()
        AudioManager.shared.prepareEngine()
        AudioManager.shared.playAmbient()

        // Create overlay container on camera node
        let overlay = SKNode()
        overlay.zPosition = 150
        overlay.name = "storyOverlay"
        cameraNode.addChild(overlay)
        storyOverlayNode = overlay

        // Move player to left edge to start walk-in
        if let player = playerNode as? SKSpriteNode {
            player.position.x = 60
            player.texture = TextureFactory.playerTexture()
        }

        showStorySlide(index: 0)
    }

    private func showStorySlide(index: Int) {
        guard isStoryPlaying, let overlay = storyOverlayNode else { return }
        currentStorySlide = index

        // Remove previous caption
        overlay.removeAllChildren()

        let slides: [(text: String, duration: TimeInterval)] = [
            ("Just another quiet evening at home...", 3.0),
            ("Everything feels perfectly still...", 3.0),
            ("Wait — did something just move?", 4.0),
        ]

        guard index < slides.count else {
            // All slides done — transition to calm phase
            skipStorySequence()
            return
        }

        let slide = slides[index]
        let caption = createStoryCaption(text: slide.text)
        overlay.addChild(caption)

        // Player/room animations per slide
        switch index {
        case 0:
            // Player walks from left to center
            if let player = playerNode as? SKSpriteNode {
                let centerX = size.width / 2
                let walkDuration = 2.5
                let walkAction = SKAction.moveTo(x: centerX, duration: walkDuration)
                walkAction.timingMode = .easeInEaseOut

                // Alternate walk textures
                let walkCycle = SKAction.repeatForever(SKAction.sequence([
                    SKAction.run { player.texture = TextureFactory.playerTexture() },
                    SKAction.wait(forDuration: 0.25),
                    SKAction.run { player.texture = TextureFactory.playerWalk2Texture() },
                    SKAction.wait(forDuration: 0.25),
                ]))
                player.run(walkCycle, withKey: "storyWalk")
                player.run(walkAction) { [weak self] in
                    player.removeAction(forKey: "storyWalk")
                    player.texture = TextureFactory.playerTexture()
                    self?.run(SKAction.wait(forDuration: 0.3)) { [weak self] in
                        self?.showStorySlide(index: 1)
                    }
                }
            }

        case 1:
            // Player idle sway, clock ticks, lamp glows
            if let player = playerNode as? SKSpriteNode {
                let sway = SKAction.sequence([
                    SKAction.rotate(toAngle: 0.02, duration: 1.0),
                    SKAction.rotate(toAngle: -0.02, duration: 1.0),
                ])
                player.run(SKAction.repeatForever(sway), withKey: "storySway")
            }

            // Subtle lamp glow pulse
            if let lamp = childNode(withName: "lamp") {
                let pulse = SKAction.sequence([
                    SKAction.fadeAlpha(to: 0.85, duration: 1.0),
                    SKAction.fadeAlpha(to: 1.0, duration: 1.0),
                ])
                lamp.run(SKAction.repeatForever(pulse), withKey: "storyLampPulse")
            }

            run(SKAction.wait(forDuration: slide.duration)) { [weak self] in
                self?.showStorySlide(index: 2)
            }

        case 2:
            // Player looks up, lamp sways, faint camera nudge
            if let player = playerNode as? SKSpriteNode {
                player.removeAction(forKey: "storySway")
                player.zRotation = 0

                // Head tilt effect — slight scale shift
                player.run(SKAction.sequence([
                    SKAction.wait(forDuration: 0.5),
                    SKAction.scaleY(to: 1.05, duration: 0.3),
                ]))
            }

            // Lamp sway
            if let lamp = childNode(withName: "lamp") {
                lamp.removeAction(forKey: "storyLampPulse")
                let sway = SKAction.sequence([
                    SKAction.moveBy(x: 4, y: 0, duration: 0.4),
                    SKAction.moveBy(x: -8, y: 0, duration: 0.8),
                    SKAction.moveBy(x: 4, y: 0, duration: 0.4),
                ])
                lamp.run(SKAction.repeat(sway, count: 2))
            }

            // Very slight camera nudge
            if !isReduceMotionEnabled {
                let nudge = SKAction.sequence([
                    SKAction.wait(forDuration: 1.5),
                    SKAction.moveBy(x: 2, y: 1, duration: 0.15),
                    SKAction.moveBy(x: -2, y: -1, duration: 0.15),
                ])
                cameraNode.run(nudge, withKey: "storyNudge")
            }

            // Low rumble hint
            AudioManager.shared.playRumble(intensity: 0.15)

            run(SKAction.wait(forDuration: slide.duration)) { [weak self] in
                self?.skipStorySequence()
            }

        default:
            break
        }
    }

    private func skipStorySequence() {
        guard isStoryPlaying else { return }
        isStoryPlaying = false

        // Clean up story overlay
        storyOverlayNode?.removeAllChildren()
        storyOverlayNode?.removeFromParent()
        storyOverlayNode = nil

        // Remove story-related actions
        removeAction(forKey: "storyAdvance")
        cameraNode?.removeAction(forKey: "storyNudge")
        playerNode?.removeAction(forKey: "storyWalk")
        playerNode?.removeAction(forKey: "storySway")
        childNode(withName: "lamp")?.removeAction(forKey: "storyLampPulse")

        // Reset player transforms
        if let player = playerNode as? SKSpriteNode {
            player.zRotation = 0
            player.yScale = abs(player.yScale) < 0.5 ? 1.0 : abs(player.yScale)
            player.setScale(1.0)
            player.texture = TextureFactory.playerTexture()
            // Ensure player is at center
            player.position.x = size.width / 2
        }

        // Stop rumble from slide 3
        AudioManager.shared.stopRumble()

        // Transition to calm phase
        startCalmPhase()
    }

    private func createStoryCaption(text: String) -> SKNode {
        let container = SKNode()
        let halfH = size.height / 2

        // Position at bottom of camera view
        container.position = CGPoint(x: 0, y: -halfH + 60)

        // Background pill
        let bgWidth: CGFloat = min(500, size.width - 60)
        let bgHeight: CGFloat = 60
        let bg = SKShapeNode(rectOf: CGSize(width: bgWidth, height: bgHeight), cornerRadius: 16)
        bg.fillColor = SKColor(white: 0, alpha: 0.7)
        bg.strokeColor = SKColor(white: 1, alpha: 0.15)
        bg.lineWidth = 1
        container.addChild(bg)

        // Caption text with typewriter animation
        let label = SKLabelNode(text: "")
        label.fontSize = DynamicTypeScale.scaled(20)
        label.fontName = "Helvetica"
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: 2)
        container.addChild(label)

        // Typewriter effect
        var charIndex = 0
        let typeAction = SKAction.repeat(
            SKAction.sequence([
                SKAction.run {
                    charIndex += 1
                    let idx = text.index(text.startIndex, offsetBy: min(charIndex, text.count))
                    label.text = String(text[..<idx])
                },
                SKAction.wait(forDuration: 0.04),
            ]),
            count: text.count
        )
        label.run(typeAction)

        // "Tap to skip" hint
        let hint = SKLabelNode(text: String(localized: "Tap to skip"))
        hint.fontSize = DynamicTypeScale.scaled(12)
        hint.fontName = "Helvetica"
        hint.fontColor = SKColor(white: 1, alpha: 0.5)
        hint.verticalAlignmentMode = .center
        hint.position = CGPoint(x: 0, y: -bgHeight / 2 - 14)
        container.addChild(hint)

        // Fade in
        container.alpha = 0
        container.run(SKAction.fadeIn(withDuration: 0.3))

        return container
    }

    // MARK: - Debris Interaction

    private func tryInteractWithDebris(at location: CGPoint) -> Bool {
        // Find closest debris node within 40pt of touch
        var closestDebris: SKNode?
        var closestDist: CGFloat = 40.0

        enumerateChildNodes(withName: "//debris_*") { node, _ in
            guard let body = node.physicsBody,
                  body.categoryBitMask & PhysicsCategory.debris != 0,
                  body.isDynamic,
                  node.alpha > 0.3 else { return }

            let dist = hypot(node.position.x - location.x, node.position.y - location.y)
            if dist < closestDist {
                closestDist = dist
                closestDebris = node
            }
        }

        // Also check nodes named with debris patterns
        enumerateChildNodes(withName: "//*") { node, _ in
            guard let body = node.physicsBody,
                  body.categoryBitMask & PhysicsCategory.debris != 0,
                  body.isDynamic,
                  node.alpha > 0.3,
                  closestDebris == nil || node !== closestDebris else { return }

            let dist = hypot(node.position.x - location.x, node.position.y - location.y)
            if dist < closestDist {
                closestDist = dist
                closestDebris = node
            }
        }

        guard let debris = closestDebris else { return false }

        kickDebrisNode(debris, from: location)
        return true
    }

    private func kickDebrisNode(_ node: SKNode, from touchPoint: CGPoint) {
        guard let body = node.physicsBody else { return }

        // Direction away from touch
        let dx = node.position.x - touchPoint.x
        let dy = node.position.y - touchPoint.y
        let len = max(hypot(dx, dy), 1)
        let dirX = dx / len
        let dirY = dy / len

        // Apply impulse
        let force: CGFloat = 150
        body.applyImpulse(CGVector(dx: dirX * force, dy: dirY * force + 30))
        body.applyAngularImpulse(dirX > 0 ? 2.0 : -2.0)

        // Dust particles at debris position
        let dust = SKEmitterNode()
        dust.particleBirthRate = 40
        dust.numParticlesToEmit = 12
        dust.particleLifetime = 0.5
        dust.particleLifetimeRange = 0.2
        dust.particleSize = CGSize(width: 6, height: 6)
        dust.particleScaleRange = 0.5
        dust.particleColor = SKColor(white: 0.7, alpha: 0.6)
        dust.particleColorBlendFactor = 1
        dust.particleAlphaSpeed = -2.0
        dust.particleSpeed = 30
        dust.particleSpeedRange = 20
        dust.emissionAngleRange = .pi * 2
        dust.position = node.position
        dust.zPosition = 50
        addChild(dust)
        dust.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.8),
            SKAction.removeFromParent(),
        ]))

        // Haptic + audio feedback
        HapticManager.shared.playImpact()
        AudioManager.shared.playImpact()

        // Score bonus
        let timeSinceLast = lastUpdateTime - lastDebrisClearTime
        let timeBonus = timeSinceLast < 2.0 && debrisClearedCount > 0 ? 3 : 0
        let points = 5 + timeBonus
        decisionEngine.currentScore += points
        debrisClearedCount += 1
        lastDebrisClearTime = lastUpdateTime

        // Floating score text
        showFloatingScore(at: node.position, points: points)

        // Update HUD
        updateHUD()

        // Fade out debris after kick
        node.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.run { node.physicsBody?.isDynamic = false },
            SKAction.removeFromParent(),
        ]))
    }

    private func trySwipePushDebris(from start: CGPoint, to end: CGPoint) {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let swipeLen = hypot(dx, dy)
        guard swipeLen > 40 else { return }

        let dirX = dx / swipeLen
        let dirY = dy / swipeLen
        let midX = (start.x + end.x) / 2
        let midY = (start.y + end.y) / 2

        var pushedCount = 0

        // Find debris along swipe path
        enumerateChildNodes(withName: "//*") { [weak self] node, _ in
            guard let body = node.physicsBody,
                  body.categoryBitMask & PhysicsCategory.debris != 0,
                  body.isDynamic,
                  node.alpha > 0.3 else { return }

            // Check if debris is near the swipe line
            let nodeToMid = hypot(node.position.x - midX, node.position.y - midY)
            guard nodeToMid < swipeLen / 2 + 40 else { return }

            // Apply impulse in swipe direction
            let force: CGFloat = 120
            let distScale = max(0.5, 1.0 - nodeToMid / swipeLen)
            body.applyImpulse(CGVector(
                dx: dirX * force * distScale,
                dy: dirY * force * distScale + 20
            ))
            body.applyAngularImpulse(dirX > 0 ? 1.5 : -1.5)

            pushedCount += 1

            // Fade out after push
            node.run(SKAction.sequence([
                SKAction.wait(forDuration: 1.5),
                SKAction.fadeOut(withDuration: 0.5),
                SKAction.run { node.physicsBody?.isDynamic = false },
                SKAction.removeFromParent(),
            ]))
        }

        if pushedCount > 0 {
            // Dust at midpoint
            let dust = SKEmitterNode()
            dust.particleBirthRate = 30
            dust.numParticlesToEmit = 10
            dust.particleLifetime = 0.4
            dust.particleSize = CGSize(width: 5, height: 5)
            dust.particleScaleRange = 0.4
            dust.particleColor = SKColor(white: 0.7, alpha: 0.5)
            dust.particleColorBlendFactor = 1
            dust.particleAlphaSpeed = -2.0
            dust.particleSpeed = 25
            dust.emissionAngleRange = .pi * 2
            dust.position = CGPoint(x: midX, y: midY)
            dust.zPosition = 50
            addChild(dust)
            dust.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.6),
                SKAction.removeFromParent(),
            ]))

            let points = pushedCount * 3
            decisionEngine.currentScore += points
            debrisClearedCount += pushedCount
            lastDebrisClearTime = lastUpdateTime

            showFloatingScore(at: CGPoint(x: midX, y: midY), points: points)
            updateHUD()

            HapticManager.shared.playImpact()
            AudioManager.shared.playImpact()
        }
    }

    private func showFloatingScore(at position: CGPoint, points: Int) {
        let label = SKLabelNode(text: "+\(points)")
        label.fontSize = DynamicTypeScale.scaled(22)
        label.fontName = "Helvetica-Bold"
        label.fontColor = AppColors.skCorrect
        label.position = position
        label.zPosition = 160
        addChild(label)

        let floatUp = SKAction.moveBy(x: 0, y: 50, duration: 0.8)
        floatUp.timingMode = .easeOut
        let fadeOut = SKAction.fadeOut(withDuration: 0.4)

        label.run(SKAction.sequence([
            SKAction.group([floatUp, SKAction.sequence([
                SKAction.wait(forDuration: 0.4),
                fadeOut,
            ])]),
            SKAction.removeFromParent(),
        ]))
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        // Story phase: tap to skip
        if isStoryPlaying {
            skipStorySequence()
            return
        }

        // Route to active mini-game first
        if let miniGame = activeMiniGame {
            miniGame.handleTouch(at: location)
            touchStartLocation = location
            return
        }

        let phase = decisionEngine.currentPhase
        NSLog(
            "[TOUCH] phase=\(phase) location=\(location) playerPos=\(playerNode?.position ?? .zero) isUnderTable=\(isPlayerUnderCover)"
        )

        if phase == .pWave || phase == .sWave {
            // Try debris interaction first during S-wave (not P-wave — player needs to find cover)
            if phase == .sWave && hasProcessedMainDecision && tryInteractWithDebris(at: location) {
                touchStartLocation = location
                return
            }
            handleMainPhaseTouch(at: location)
        } else if phase == .aftershock {
            // Try debris interaction before aftershock zone check
            if activeMiniGame == nil && tryInteractWithDebris(at: location) {
                touchStartLocation = location
                return
            }
            handleAftershockTouch(at: location)
        }

        touchStartLocation = location
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if let miniGame = activeMiniGame {
            let start = touchStartLocation ?? location
            miniGame.handleDrag(from: start, to: location)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if let miniGame = activeMiniGame {
            miniGame.handleTouchEnded(at: location)
        } else if let start = touchStartLocation {
            let phase = decisionEngine.currentPhase
            let swipeDistance = hypot(location.x - start.x, location.y - start.y)
            if swipeDistance > 40 && (phase == .sWave || phase == .aftershock) {
                trySwipePushDebris(from: start, to: location)
            }
        }

        touchStartLocation = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        activeMiniGame?.handleTouchEnded(at: .zero)
        touchStartLocation = nil
    }

    private func handleMainPhaseTouch(at location: CGPoint) {
        guard !hasProcessedMainDecision else {
            return
        }

        let action: PlayerAction

        // Determine which zone was tapped
        if let safeZone = childNode(withName: safeZoneNodeName),
            safeZone.frame.insetBy(dx: -30, dy: -30).contains(location)
        {
            action = .dropUnderTable
        } else if let window = childNode(withName: "window"),
            window.frame.insetBy(dx: -25, dy: -25).contains(location)
        {
            action = .moveToWindow
        } else if let door = childNode(withName: "door"),
            door.frame.insetBy(dx: -25, dy: -25).contains(location)
        {
            action = .runToDoor
        } else if let bookshelf = childNode(withName: "bookshelf"),
            bookshelf.frame.insetBy(dx: -25, dy: -25).contains(location)
        {
            action = .nearBookshelf
        } else {
            // Tapped empty area — ignore, player only moves to interactive targets
            return
        }

        hasProcessedMainDecision = true
        movePlayer(to: location, action: action)

        let decision = decisionEngine.recordDecision(action, at: lastUpdateTime)
        showDecisionFeedback(decision)
    }

    @discardableResult
    private func handleAftershockTouch(at location: CGPoint) -> Bool {
        // Don't allow interaction while animating or during mini-game
        guard activeMiniGame == nil, !isTaskAnimatingIn else { return false }

        // Only check the current task in the sequence
        guard currentTaskIndex < aftershockTasks.count else { return false }

        let currentTask = aftershockTasks[currentTaskIndex]
        let taskName = currentTask.name
        let action = currentTask.action

        guard let zone = childNode(withName: taskName) else {
            NSLog("[AFTERSHOCK] Zone '\(taskName)' not found")
            return false
        }

        // Require zone to be fully visible (not still animating in)
        guard zone.alpha > 0.8,
            zone.frame.insetBy(dx: -20, dy: -20).contains(location)
        else {
            return false
        }

        NSLog(
            "[AFTERSHOCK] HIT current task \(taskName) at zone pos \(zone.position) — launching mini-game"
        )
        processedAftershockActions.insert(taskName)

        // Stand up from crouch if needed, then walk to zone
        if isPlayerUnderCover {
            if let player = playerNode as? SKSpriteNode {
                isPlayerUnderCover = false
                player.removeAllActions()
                resetPlayerTransforms()
                player.texture = TextureFactory.playerTexture()
                player.position.y = RoomLayout.floorHeight + RoomLayout.playerSize.height / 2 + 5
            }
        }

        // Move to the exact zone position for all tasks
        // The zone icons are already positioned at the correct visual locations
        let movePos = zone.position

        // Hide the zone icon
        zone.removeAllActions()
        zone.run(SKAction.fadeOut(withDuration: 0.3))

        NSLog("[AFTERSHOCK] Starting movement to \(movePos) for action \(action)")

        // Reset flag for new task
        miniGameLaunchedForCurrentTask = false

        // Move with push-through - kicks/pushes obstacles and continues to target
        movePlayerWithPushThrough(to: movePos, action: action) { [weak self] in
            guard let self = self else { return }

            // Remove the fallback timer to prevent double-launch
            self.removeAction(forKey: "fallback_\(action)")

            // Check if already launched (shouldn't happen, but safety check)
            guard !self.miniGameLaunchedForCurrentTask else {
                NSLog("[AFTERSHOCK] Mini-game already launched, skipping duplicate launch")
                return
            }
            self.miniGameLaunchedForCurrentTask = true

            NSLog("[AFTERSHOCK] Arrived at destination, launching mini-game for \(action)")
            self.launchMiniGame(for: action)
        }

        // Fallback: launch mini-game after 3 seconds if movement hasn't completed
        run(
            SKAction.sequence([
                SKAction.wait(forDuration: 3.0),
                SKAction.run { [weak self] in
                    guard let self = self,
                        !self.miniGameLaunchedForCurrentTask,
                        self.activeMiniGame == nil,
                        !self.processedAftershockActions.isEmpty
                    else { return }
                    // Force launch if movement didn't trigger it
                    self.miniGameLaunchedForCurrentTask = true
                    NSLog(
                        "[AFTERSHOCK] Fallback timer triggered, launching mini-game for \(action)")
                    self.launchMiniGame(for: action)
                },
            ]), withKey: "fallback_\(action)")

        return true
    }

    // MARK: - Mini-Game Launch

    private func launchMiniGame(for action: PlayerAction) {
        NSLog("[MINIGAME] Launching mini-game for action: \(action)")
        let miniGame: MiniGameNode

        switch action {
        case .shutOffGas:
            miniGame = GasValveMiniGame()
        case .findSafeExit:
            miniGame = SafeExitMiniGame()
        case .checkInjuries:
            miniGame = InjuryCheckMiniGame()
        default:
            return
        }

        miniGame.miniGameDelegate = self
        activeMiniGame = miniGame
        miniGame.present(in: self)
    }

    // MARK: - MiniGameDelegate

    func miniGameDidComplete(_ miniGame: MiniGameNode, action: PlayerAction) {
        activeMiniGame = nil

        // Clean up room-level gas leak effect when gas valve task finishes
        if action == .shutOffGas {
            stopRoomGasLeakEffect()
        }

        // Clean up room-level blocked door effect when safe exit task finishes
        if action == .findSafeExit {
            stopRoomBlockedDoorEffect()
        }

        // Announce mini-game completion for accessibility
        let actionName = action.displayName
        postAccessibilityAnnouncement("Task completed: \(actionName).")

        let decision = decisionEngine.recordDecision(action, at: lastUpdateTime)
        showDecisionFeedback(decision)

        // Player cheer animation
        if let player = playerNode as? SKSpriteNode {
            player.removeAllActions()
            player.run(
                SKAction.sequence([
                    SKAction.run { player.texture = TextureFactory.playerCheer1Texture() },
                    SKAction.wait(forDuration: 0.4),
                    SKAction.run { player.texture = TextureFactory.playerTexture() },
                ]))
        }

        // Advance to next task after feedback animation completes
        run(
            SKAction.sequence([
                SKAction.wait(forDuration: 1.0),  // Wait for feedback animation
                SKAction.run { [weak self] in
                    guard let self = self else { return }
                    self.currentTaskIndex += 1
                    NSLog("[TASK] Mini-game completed, advancing to task \(self.currentTaskIndex)")
                    self.showNextAftershockTask()
                },
            ]))
    }

    func miniGameDidFail(_ miniGame: MiniGameNode, action: PlayerAction) {
        activeMiniGame = nil

        // Clean up room-level gas leak effect when gas valve task finishes
        if action == .shutOffGas {
            stopRoomGasLeakEffect()
        }

        // Clean up room-level blocked door effect when safe exit task finishes
        if action == .findSafeExit {
            stopRoomBlockedDoorEffect()
        }

        // Announce mini-game failure for accessibility
        let actionName = action.displayName
        postAccessibilityAnnouncement("Task failed: \(actionName). Time ran out.")

        // On failure, penalize — the player tried the right action but was too slow
        // Record as stayStanding (inaction) to trigger a penalty
        let decision = decisionEngine.recordDecision(.stayStanding, at: lastUpdateTime)
        showDecisionFeedback(decision)

        // Show specific failure feedback
        let failLabel = SKLabelNode(text: String(localized: "Failed: \(action.displayName)"))
        failLabel.fontSize = DynamicTypeScale.scaled(16)
        failLabel.fontName = "Helvetica-Bold"
        failLabel.fontColor = AppColors.skWrong
        failLabel.position = .zero
        failLabel.zPosition = 160
        cameraNode.addChild(failLabel)
        failLabel.run(
            SKAction.sequence([
                SKAction.moveBy(x: 0, y: 40, duration: 1.0),
                SKAction.fadeOut(withDuration: 0.3),
                SKAction.removeFromParent(),
            ]))

        // Player hurt animation
        if let player = playerNode as? SKSpriteNode {
            player.removeAllActions()
            player.run(
                SKAction.sequence([
                    SKAction.run { player.texture = TextureFactory.playerHurtTexture() },
                    SKAction.wait(forDuration: 0.3),
                    SKAction.run { player.texture = TextureFactory.playerTexture() },
                ]))
        }

        // Move to next task anyway (player attempted but failed)
        run(
            SKAction.sequence([
                SKAction.wait(forDuration: 1.0),
                SKAction.run { [weak self] in
                    guard let self = self else { return }
                    self.currentTaskIndex += 1
                    NSLog("[TASK] Mini-game failed, advancing to task \(self.currentTaskIndex)")
                    self.showNextAftershockTask()
                },
            ]))
    }

    // MARK: - Hints System

    private let hintMessages: [PlayerAction: String] = [
        .dropUnderTable: String(localized: "DROP under the table now!"),
        .stayStanding: String(localized: "You should DROP, COVER, and HOLD ON!"),
        .findSafeExit: String(localized: "Check for debris blocking the exit"),
        .checkInjuries: String(localized: "Look for any injuries - help yourself first"),
        .shutOffGas: String(localized: "Turn off gas to prevent fires!"),
        .moveToWindow: String(localized: "Stay away from windows! Glass can shatter!"),
        .runToDoor: String(localized: "Don't run to doors! They're not safer!"),
        .nearBookshelf: String(localized: "Get under sturdy furniture, not next to it!"),
    ]

    private func showHint(for action: PlayerAction) {
        guard hintsShown < maxHints,
            let message = hintMessages[action]
        else { return }

        let currentTime = lastUpdateTime
        guard currentTime - lastHintTime >= hintCooldown else {
            NSLog("[HINT] Hint on cooldown, skipping")
            return
        }
        lastHintTime = currentTime
        hintsShown += 1

        // Remove existing hint if present
        hintLabel?.removeFromParent()

        // Create new hint label
        let hint = SKLabelNode(text: message)
        hint.fontSize = DynamicTypeScale.scaled(14)
        hint.fontName = "Helvetica-Bold"
        hint.fontColor = AppColors.skWarning
        hint.horizontalAlignmentMode = .center
        hint.numberOfLines = 2
        hint.preferredMaxLayoutWidth = 300
        hint.position = CGPoint(x: 0, y: 80)
        hint.zPosition = 150
        hint.alpha = 0

        // Background pill
        let background = SKShapeNode(rectOf: CGSize(width: 320, height: 50), cornerRadius: 12)
        background.fillColor = SKColor.black.withAlphaComponent(0.75)
        background.strokeColor = AppColors.skWarning.withAlphaComponent(0.5)
        background.lineWidth = 2
        background.position = .zero
        background.zPosition = -1
        hint.addChild(background)

        cameraNode.addChild(hint)
        hintLabel = hint

        // Fade in, wait, fade out animation
        hint.run(
            SKAction.sequence([
                SKAction.fadeIn(withDuration: 0.3),
                SKAction.wait(forDuration: 2.5),
                SKAction.fadeOut(withDuration: 0.3),
                SKAction.removeFromParent(),
            ]))

        NSLog("[HINT] Showing hint #\(hintsShown): \(message)")
    }

    /// Show contextual hint based on current game state
    private func showContextualHint() {
        let phase = decisionEngine.currentPhase
        let action: PlayerAction

        switch phase {
        case .pWave:
            action = .dropUnderTable
        case .sWave:
            action = isPlayerUnderCover ? .dropUnderTable : .stayStanding
        case .aftershock:
            // No hints during aftershock - tasks are self-explanatory
            return
        default:
            return
        }

        showHint(for: action)
    }

    // MARK: - Player Movement

    /// Flips the player sprite to face the direction of movement.
    private func faceDirection(player: SKSpriteNode, toward targetX: CGFloat) {
        if targetX < player.position.x {
            player.xScale = -abs(player.xScale)  // face left
        } else {
            player.xScale = abs(player.xScale)  // face right
        }
    }

    /// Builds the standard walk cycle action to move player to a target.
    private func buildWalkAction(player: SKSpriteNode, to target: CGPoint, distance: CGFloat)
        -> SKAction
    {
        let walk1 = TextureFactory.playerRunTexture()
        let stand = TextureFactory.playerTexture()
        let walk2 = TextureFactory.playerWalk2Texture()
        let moveDuration = max(0.3, Double(distance) / 200.0)

        let walkAnim = SKAction.repeatForever(
            SKAction.animate(with: [walk1, stand, walk2, stand], timePerFrame: 0.09)
        )
        let moveAction = SKAction.move(to: target, duration: moveDuration)
        moveAction.timingMode = .easeInEaseOut

        // Footstep dust puffs during walk
        let direction: CGFloat = target.x > player.position.x ? 1 : -1
        let dustAction = SKAction.repeatForever(
            SKAction.sequence([
                SKAction.wait(forDuration: 0.18),
                SKAction.run { [weak self] in
                    guard let self = self else { return }
                    let dust = ParticleEffects.footstepDust(
                        at: player.position, direction: direction)
                    self.addChild(dust)
                    dust.run(
                        SKAction.sequence([
                            SKAction.wait(forDuration: 0.6),
                            SKAction.removeFromParent(),
                        ]))
                },
            ]))

        return SKAction.sequence([
            SKAction.run { [weak self] in
                self?.faceDirection(player: player, toward: target.x)
                player.texture = walk1
            },
            SKAction.group([moveAction, walkAnim, dustAction]),
            // Face right again after arriving
            SKAction.run { player.xScale = abs(player.xScale) },
        ])
    }

    /// Builds a fast run action (for running to door).
    private func buildRunAction(player: SKSpriteNode, to target: CGPoint, distance: CGFloat)
        -> SKAction
    {
        let run = TextureFactory.playerRunTexture()
        let walk2 = TextureFactory.playerWalk2Texture()
        let jump = TextureFactory.playerJumpTexture()
        let runDuration = max(0.2, Double(distance) / 300.0)

        let runAnim = SKAction.repeatForever(
            SKAction.animate(with: [run, walk2, jump, walk2], timePerFrame: 0.06)
        )
        let runMove = SKAction.move(to: target, duration: runDuration)
        runMove.timingMode = .easeIn

        // Footstep dust puffs during run (faster frequency)
        let direction: CGFloat = target.x > player.position.x ? 1 : -1
        let dustAction = SKAction.repeatForever(
            SKAction.sequence([
                SKAction.wait(forDuration: 0.12),
                SKAction.run { [weak self] in
                    guard let self = self else { return }
                    let dust = ParticleEffects.footstepDust(
                        at: player.position, direction: direction)
                    self.addChild(dust)
                    dust.run(
                        SKAction.sequence([
                            SKAction.wait(forDuration: 0.6),
                            SKAction.removeFromParent(),
                        ]))
                },
            ]))

        return SKAction.sequence([
            SKAction.run { [weak self] in
                self?.faceDirection(player: player, toward: target.x)
                player.texture = run
            },
            SKAction.group([runMove, runAnim, dustAction]),
            SKAction.run { player.xScale = abs(player.xScale) },
        ])
    }

    /// Builds aftershock walk — stands up first, then uses a distinct cautious walk cycle.
    private func buildAftershockWalkAction(
        player: SKSpriteNode, to target: CGPoint, distance: CGFloat
    ) -> SKAction {
        let walk1 = TextureFactory.playerWalk2Texture()
        let stand = TextureFactory.playerTexture()
        let idle = TextureFactory.playerIdleTexture()
        let moveDuration = max(0.3, Double(distance) / 180.0)

        // Distinct aftershock walk: idle → walk2 → stand (slower, cautious)
        let walkAnim = SKAction.repeatForever(
            SKAction.animate(with: [idle, walk1, stand, walk1], timePerFrame: 0.12)
        )
        let moveAction = SKAction.move(to: target, duration: moveDuration)
        moveAction.timingMode = .easeInEaseOut

        return SKAction.sequence([
            // Stand up first
            SKAction.run { player.texture = stand },
            SKAction.wait(forDuration: 0.15),
            // Face direction and walk cautiously
            SKAction.run { [weak self] in
                self?.faceDirection(player: player, toward: target.x)
            },
            SKAction.group([moveAction, walkAnim]),
            // Face right again after arriving
            SKAction.run { player.xScale = abs(player.xScale) },
        ])
    }

    /// Resets player sprite transforms to prevent stuck rotation/scale from interrupted animations.
    private func resetPlayerTransforms() {
        guard let player = playerNode as? SKSpriteNode else { return }
        player.zRotation = 0
        player.yScale = 1.0
        player.xScale = 1.0
    }

    /// Creates a squash and stretch animation for impact effects
    private func squashAndStretchAction() -> SKAction {
        return SKAction.sequence([
            // Squash on impact (wide and short)
            SKAction.scaleX(to: 1.3, y: 0.7, duration: 0.08),
            // Stretch back up (narrow and tall)
            SKAction.scaleX(to: 0.9, y: 1.15, duration: 0.08),
            // Return to normal
            SKAction.scaleX(to: 1.0, y: 1.0, duration: 0.08),
        ])
    }

    private func movePlayer(to target: CGPoint, action: PlayerAction) {
        guard let player = playerNode as? SKSpriteNode else {
            NSLog(
                "[MOVE] FAILED — playerNode is nil or not SKSpriteNode. playerNode=\(String(describing: playerNode))"
            )
            return
        }

        NSLog(
            "[MOVE] action=\(action) from=\(player.position) to=\(target) texture=\(String(describing: player.texture)) yScale=\(player.yScale)"
        )
        player.removeAllActions()
        resetPlayerTransforms()

        let playerH = RoomLayout.playerSize.height
        let floorY = RoomLayout.floorHeight + playerH / 2 + 5

        let clampedTarget: CGPoint
        if action == .dropUnderTable {
            clampedTarget = CGPoint(x: size.width / 2, y: floorY)
        } else if action == .findSafeExit {
            // For exit, respect the Y passed in (calculated to be "in front" of door)
            clampedTarget = CGPoint(
                x: target.x.clamped(to: 60...size.width - 60),
                y: target.y
            )
        } else {
            clampedTarget = CGPoint(
                x: target.x.clamped(to: 60...size.width - 60),
                y: floorY
            )
        }

        let distance = abs(clampedTarget.x - player.position.x)

        // Build movement + arrival as a single sequence per action
        let fullSequence: SKAction

        switch action {
        case .dropUnderTable:
            // Crouch in place immediately, then move to table while staying crouched
            let moveDuration = max(0.2, Double(distance) / 250.0)
            let slideMove = SKAction.move(to: clampedTarget, duration: moveDuration)
            slideMove.timingMode = .easeInEaseOut

            fullSequence = SKAction.sequence([
                // Immediately crouch with hands protecting head
                SKAction.run { [weak self] in
                    self?.faceDirection(player: player, toward: clampedTarget.x)
                    player.texture = TextureFactory.playerCrouchTexture()
                },
                // Move to table while staying crouched
                slideMove,
                // Arrive and tuck in with hands over head (protective pose)
                SKAction.run {
                    player.xScale = abs(player.xScale)
                    // Scale down slightly to show "tucking in" under table
                    player.yScale = 0.9
                    player.texture = TextureFactory.playerCoverProtectTexture()
                },
                // Subtle shake synchronized with earthquake intensity
                SKAction.repeat(
                    SKAction.sequence([
                        SKAction.moveBy(x: 1, y: 0, duration: 0.05),
                        SKAction.moveBy(x: -2, y: 0, duration: 0.05),
                        SKAction.moveBy(x: 1, y: 0, duration: 0.05),
                    ]),
                    count: 5
                ),
            ])

        case .findSafeExit:
            // Walk to target (in front of door), then face door
            let walkToTarget = buildWalkAction(
                player: player, to: clampedTarget, distance: distance)
            let arrival = SKAction.sequence([
                SKAction.run {
                    // Face "up/away" (reset scale/texture)
                    player.xScale = abs(player.xScale)
                    player.texture = TextureFactory.playerTexture()  // Stand facing forward/back
                },
                SKAction.wait(forDuration: 0.5),
            ])
            fullSequence = SKAction.sequence([walkToTarget, arrival])

        case .moveToWindow:
            // Walk to window, kick it, glass shatters, get hurt, stumble back
            let walkToTarget = buildWalkAction(
                player: player, to: clampedTarget, distance: distance)
            let arrival = SKAction.sequence([
                // Wind up for kick
                SKAction.run { player.texture = TextureFactory.playerIdleTexture() },
                SKAction.wait(forDuration: 0.15),
                // Kick the window with impact
                SKAction.run { [weak self] in
                    player.texture = TextureFactory.playerKickTexture()
                    // Screen shake on impact
                    self?.shakeController.triggerManualImpact(intensity: 0.4)
                },
                SKAction.moveBy(x: 8, y: 0, duration: 0.1),
                SKAction.wait(forDuration: 0.1),
                // Glass shatters — visual effects
                SKAction.run { [weak self] in
                    guard let self = self else { return }
                    // Glass particle explosion
                    let glassShards = ParticleEffects.glassShards(at: clampedTarget, intensity: 0.8)
                    self.addChild(glassShards)
                    // Screen flash
                    self.flashImpact(
                        color: SKColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 0.4),
                        position: clampedTarget, magnitude: 0.5)
                    // Play impact sound
                    AudioManager.shared.playImpact()
                },
                SKAction.wait(forDuration: 0.1),
                // Glass shatters — hurt reaction
                SKAction.run { player.texture = TextureFactory.playerHurtTexture() },
                SKAction.moveBy(x: -12, y: 0, duration: 0.12),
                // Stumble and fall
                SKAction.run { player.texture = TextureFactory.playerFallTexture() },
                SKAction.moveBy(x: -8, y: 0, duration: 0.15),
                SKAction.wait(forDuration: 0.1),
                // Recover to standing
                SKAction.run { player.texture = TextureFactory.playerSkidTexture() },
                SKAction.wait(forDuration: 0.1),
                SKAction.run { player.texture = TextureFactory.playerTexture() },
            ])
            fullSequence = SKAction.sequence([walkToTarget, arrival])

        case .runToDoor:
            // Sprint to door, kick it hard, bounce back hurt
            let runToTarget = buildRunAction(player: player, to: clampedTarget, distance: distance)
            let arrival = SKAction.sequence([
                // Kick the door hard
                SKAction.run { player.texture = TextureFactory.playerKickTexture() },
                SKAction.moveBy(x: -8, y: 0, duration: 0.08),
                SKAction.wait(forDuration: 0.35),
                // Skid back from impact
                SKAction.run { player.texture = TextureFactory.playerSkidTexture() },
                SKAction.moveBy(x: 15, y: 0, duration: 0.12),
                // Hurt reaction
                SKAction.run { player.texture = TextureFactory.playerHurtTexture() },
                SKAction.wait(forDuration: 0.15),
                // Fall briefly
                SKAction.run { player.texture = TextureFactory.playerFallTexture() },
                SKAction.wait(forDuration: 0.1),
                // Recover
                SKAction.run { player.texture = TextureFactory.playerTexture() },
            ])
            fullSequence = SKAction.sequence([runToTarget, arrival])

        case .nearBookshelf:
            // Walk to bookshelf, kick it, it topples on player
            let walkToTarget = buildWalkAction(
                player: player, to: clampedTarget, distance: distance)
            let arrival = SKAction.sequence([
                // Look at bookshelf
                SKAction.run { player.texture = TextureFactory.playerIdleTexture() },
                SKAction.wait(forDuration: 0.15),
                // Kick the bookshelf
                SKAction.run { player.texture = TextureFactory.playerKickTexture() },
                SKAction.wait(forDuration: 0.2),
                // Try to climb/brace
                SKAction.run { player.texture = TextureFactory.playerClimb1Texture() },
                SKAction.wait(forDuration: 0.15),
                // Get hit — hurt and fall with squash effect
                SKAction.group([
                    SKAction.run { player.texture = TextureFactory.playerHurtTexture() },
                    squashAndStretchAction(),
                ]),
                SKAction.moveBy(x: 0, y: -5, duration: 0.1),
                SKAction.run { player.texture = TextureFactory.playerFallTexture() },
                SKAction.moveBy(x: 0, y: 5, duration: 0.15),
                // Recover
                SKAction.run { player.texture = TextureFactory.playerTexture() },
            ])
            fullSequence = SKAction.sequence([walkToTarget, arrival])

        case .stayStanding:
            // Wobble in place using multiple hurt/fall/slide poses with squash/stretch
            fullSequence = SKAction.sequence([
                SKAction.run { player.texture = TextureFactory.playerFallTexture() },
                SKAction.scaleX(to: 1.1, y: 0.9, duration: 0.06),
                SKAction.wait(forDuration: 0.06),
                SKAction.run { player.texture = TextureFactory.playerHurtTexture() },
                SKAction.scaleX(to: 0.95, y: 1.05, duration: 0.06),
                SKAction.wait(forDuration: 0.06),
                SKAction.run { player.texture = TextureFactory.playerSlideTexture() },
                SKAction.scaleX(to: 1.15, y: 0.85, duration: 0.06),
                SKAction.wait(forDuration: 0.06),
                SKAction.run { player.texture = TextureFactory.playerFallTexture() },
                SKAction.scaleX(to: 0.9, y: 1.1, duration: 0.06),
                SKAction.wait(forDuration: 0.06),
                SKAction.run { player.texture = TextureFactory.playerSkidTexture() },
                SKAction.scaleX(to: 1.05, y: 0.95, duration: 0.06),
                SKAction.wait(forDuration: 0.06),
                SKAction.run { player.texture = TextureFactory.playerHurtTexture() },
                SKAction.scaleX(to: 1.0, y: 1.0, duration: 0.06),
                SKAction.wait(forDuration: 0.06),
                SKAction.run { player.texture = TextureFactory.playerTexture() },
            ])

        case .shutOffGas, .checkInjuries:
            // These actions use movePlayerWithPushThrough during aftershock phase
            // This case exists only for switch exhaustiveness
            fullSequence = SKAction.sequence([
                SKAction.run { player.texture = TextureFactory.playerTexture() },
                SKAction.wait(forDuration: 0.1),
            ])

        case .clearDebris:
            // Debris clearing is handled via direct touch interaction, not movement
            fullSequence = SKAction.sequence([
                SKAction.run { player.texture = TextureFactory.playerTexture() },
                SKAction.wait(forDuration: 0.1),
            ])
        }

        player.run(fullSequence, withKey: "playerMove")

        if action == .dropUnderTable {
            isPlayerUnderCover = true
        }
    }

    private func movePlayerFreely(to target: CGPoint) {
        guard let player = playerNode as? SKSpriteNode else { return }

        player.removeAllActions()
        resetPlayerTransforms()

        let playerH = RoomLayout.playerSize.height
        let floorY = RoomLayout.floorHeight + playerH / 2 + 5
        let clampedTarget = CGPoint(
            x: target.x.clamped(to: 60...size.width - 60),
            y: floorY
        )

        // If currently crouched under the table, stand first so movement looks natural.
        if isPlayerUnderCover {
            isPlayerUnderCover = false
            player.texture = TextureFactory.playerTexture()
            player.position.y = floorY
        }

        // 4-frame walk cycle for smoother movement
        let stand = TextureFactory.playerTexture()
        let walk1 = TextureFactory.playerRunTexture()
        let walk2 = TextureFactory.playerWalk2Texture()
        let distance = abs(clampedTarget.x - player.position.x)
        let moveDuration = max(0.2, Double(distance) / 240.0)

        let walkAnim = SKAction.repeatForever(
            SKAction.animate(with: [walk1, stand, walk2, stand], timePerFrame: 0.08)
        )
        let moveAction = SKAction.move(to: clampedTarget, duration: moveDuration)
        moveAction.timingMode = .easeInEaseOut

        let sequence = SKAction.sequence([
            SKAction.run { [weak self] in
                self?.faceDirection(player: player, toward: clampedTarget.x)
                player.texture = walk1
            },
            SKAction.group([moveAction, walkAnim]),
            SKAction.run { player.xScale = abs(player.xScale) },
            SKAction.run { player.texture = TextureFactory.playerIdleTexture() },
        ])

        player.run(sequence, withKey: "playerMove")
    }

    // MARK: - Decision Feedback

    private func showDecisionFeedback(_ decision: Decision) {
        // Announce decision result for VoiceOver users
        let actionName = decision.action.displayName
        let resultText = decision.isCorrect ? "Correct." : "Incorrect."
        let voiceOverPointsText =
            decision.pointsAwarded >= 0
            ? "Plus \(decision.pointsAwarded) points."
            : "Minus \(abs(decision.pointsAwarded)) points."
        postAccessibilityAnnouncement(
            "\(resultText) \(actionName). \(voiceOverPointsText) \(decision.feedback)")

        let feedbackNode = SKNode()
        feedbackNode.position = .zero
        feedbackNode.zPosition = 150
        cameraNode.addChild(feedbackNode)

        // Icon
        let icon = SKLabelNode(text: decision.isCorrect ? "✅" : "❌")
        icon.fontSize = DynamicTypeScale.scaled(50)
        icon.position = CGPoint(x: 0, y: 30)
        feedbackNode.addChild(icon)

        // Points
        let pointsText =
            decision.pointsAwarded >= 0 ? "+\(decision.pointsAwarded)" : "\(decision.pointsAwarded)"
        let points = SKLabelNode(text: pointsText)
        points.fontSize = DynamicTypeScale.scaled(28)
        points.fontName = "Helvetica-Bold"
        points.fontColor = decision.isCorrect ? AppColors.skCorrect : AppColors.skWrong
        points.position = CGPoint(x: 0, y: -10)
        feedbackNode.addChild(points)

        // Feedback text
        let feedback = SKLabelNode(text: decision.action.displayName)
        feedback.fontSize = DynamicTypeScale.scaled(18)
        feedback.fontName = "Helvetica"
        feedback.fontColor = SKColor(red: 0x1C / 255, green: 0x1C / 255, blue: 0x1E / 255, alpha: 1)
        feedback.position = CGPoint(x: 0, y: -40)
        feedbackNode.addChild(feedback)

        // Background
        let bg = SKShapeNode(rectOf: CGSize(width: 300, height: 130), cornerRadius: 12)
        bg.fillColor = SKColor(white: 1, alpha: 0.85)
        bg.strokeColor = decision.isCorrect ? AppColors.skCorrect : AppColors.skWrong
        bg.lineWidth = 3
        bg.zPosition = -1
        feedbackNode.addChild(bg)

        // Animate
        feedbackNode.setScale(0.5)
        feedbackNode.alpha = 0

        let appear = SKAction.group([
            SKAction.fadeIn(withDuration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.3),
        ])
        let stay = SKAction.wait(forDuration: 1.2)
        let disappear = SKAction.group([
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.move(by: CGVector(dx: 0, dy: 30), duration: 0.3),
        ])

        feedbackNode.run(SKAction.sequence([appear, stay, disappear, SKAction.removeFromParent()]))

        // Screen flash with intensity based on decision impact
        let flashIntensity =
            decision.pointsAwarded >= 20 || decision.pointsAwarded <= -20 ? 0.8 : 0.4
        if decision.isCorrect {
            HapticManager.shared.playCorrectFeedback()
            AudioManager.shared.playCorrect()
            flashScreen(
                color: AppColors.skCorrect.withAlphaComponent(0.2), intensity: flashIntensity)

            // Gold sparkle burst at player position
            if let playerPos = playerNode?.position {
                let sparkles = ParticleEffects.correctDecisionSparkles(at: playerPos)
                addChild(sparkles)
                sparkles.run(
                    SKAction.sequence([
                        SKAction.wait(forDuration: 1.2),
                        SKAction.removeFromParent(),
                    ]))
            }
        } else {
            HapticManager.shared.playImpact()
            AudioManager.shared.playWrong()
            flashScreen(color: AppColors.skWrong.withAlphaComponent(0.2), intensity: flashIntensity)
            heartsLabel.pulse(scale: 1.5, duration: 0.4)
        }

        updateHUD()
    }

    private func flashScreen(color: SKColor, intensity: CGFloat = 0.6) {
        let flash = SKShapeNode(rectOf: CGSize(width: size.width + 100, height: size.height + 100))
        flash.fillColor = color
        flash.strokeColor = .clear
        flash.zPosition = 90
        flash.alpha = 0
        cameraNode.addChild(flash)

        // Scale duration and peak alpha based on intensity
        let peakAlpha = min(0.3 + (intensity * 0.5), 0.8)
        let fadeInDuration = max(0.05, 0.15 - (intensity * 0.05))
        let fadeOutDuration = max(0.2, 0.4 - (intensity * 0.1))

        flash.run(
            SKAction.sequence([
                SKAction.fadeAlpha(to: peakAlpha, duration: fadeInDuration),
                SKAction.fadeOut(withDuration: fadeOutDuration),
                SKAction.removeFromParent(),
            ]))
    }

    /// Enhanced impact flash with screen shake integration
    private func flashImpact(color: SKColor, position: CGPoint? = nil, magnitude: CGFloat = 0.5) {
        // Main screen flash
        let flash = SKShapeNode(rectOf: CGSize(width: size.width + 100, height: size.height + 100))
        flash.fillColor = color
        flash.strokeColor = .clear
        flash.zPosition = 95
        flash.alpha = 0
        cameraNode.addChild(flash)

        // Calculate flash parameters based on magnitude
        let peakAlpha = min(0.4 + (magnitude * 0.4), 0.9)
        let holdDuration = magnitude * 0.15

        // Create flash sequence with optional "shockwave" from impact point
        let flashActions: [SKAction] = [
            SKAction.fadeAlpha(to: peakAlpha, duration: 0.05),
            SKAction.wait(forDuration: holdDuration),
            SKAction.fadeOut(withDuration: 0.25),
        ]

        // Add radial flash from impact position if provided
        if let pos = position {
            let radialFlash = SKShapeNode(circleOfRadius: 10)
            radialFlash.fillColor = color.withAlphaComponent(0.3)
            radialFlash.strokeColor = .clear
            radialFlash.position = convert(pos, to: cameraNode)
            radialFlash.zPosition = 94
            radialFlash.alpha = 0
            cameraNode.addChild(radialFlash)

            radialFlash.run(
                SKAction.sequence([
                    SKAction.group([
                        SKAction.fadeAlpha(to: 0.5, duration: 0.1),
                        SKAction.scale(to: 8.0 * magnitude, duration: 0.3),
                    ]),
                    SKAction.fadeOut(withDuration: 0.2),
                    SKAction.removeFromParent(),
                ]))
        }

        flash.run(SKAction.sequence(flashActions + [SKAction.removeFromParent()]))
    }

    // MARK: - Physics Contact

    func didBegin(_ contact: SKPhysicsContact) {
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB

        let categories = bodyA.categoryBitMask | bodyB.categoryBitMask

        // Debris hitting the floor
        if categories & PhysicsCategory.debris != 0 && categories & PhysicsCategory.floor != 0 {
            let debrisBody = bodyA.categoryBitMask == PhysicsCategory.debris ? bodyA : bodyB
            if let pos = debrisBody.node?.position {
                physicsManager.addImpactParticles(at: pos, in: self)
                AudioManager.shared.playDebrisFall()
            }
        }

        // Debris or furniture hitting the player — kick it away
        if categories & PhysicsCategory.player != 0
            && (categories & PhysicsCategory.debris != 0
                || categories & PhysicsCategory.furniture != 0)
        {
            if !isPlayerUnderCover && !isExitingScene {
                HapticManager.shared.playImpact()
                AudioManager.shared.playDebrisFall()

                // Identify the item node that hit the player
                let itemBody = bodyA.categoryBitMask == PhysicsCategory.player ? bodyB : bodyA
                guard let player = playerNode as? SKSpriteNode,
                    let itemNode = itemBody.node as? SKSpriteNode
                else { return }

                // Determine kick direction: push item away from player
                let kickRight = itemNode.position.x >= player.position.x
                let kickDirX: CGFloat = kickRight ? 1.0 : -1.0

                // Face the item before kicking
                player.xScale = kickRight ? -abs(player.xScale) : abs(player.xScale)

                // Player kick animation
                player.removeAllActions()
                player.texture = TextureFactory.playerKickTexture()
                let kickAnim = SKAction.sequence([
                    SKAction.wait(forDuration: 0.3),
                    SKAction.run { [weak self] in
                        player.texture = TextureFactory.playerTexture()
                        player.xScale = abs(player.xScale)
                        self?.resetPlayerTransforms()
                    },
                ])
                player.run(kickAnim, withKey: "kickReaction")

                // Kick the item away — make it dynamic so it flies
                itemNode.physicsBody?.isDynamic = true
                itemNode.physicsBody?.affectedByGravity = true
                let kickForce = CGVector(dx: kickDirX * 120, dy: 60)
                itemNode.physicsBody?.applyImpulse(kickForce)
                itemNode.run(SKAction.rotate(byAngle: kickDirX * .pi, duration: 0.5))

                // Fade out and remove the kicked item
                itemNode.run(
                    SKAction.sequence([
                        SKAction.wait(forDuration: 0.8),
                        SKAction.fadeOut(withDuration: 0.3),
                        SKAction.removeFromParent(),
                    ]))
            }
        }
    }

    // MARK: - End Game

    private func endGame() {
        isExitingScene = true
        AudioManager.shared.stopAll()
        HapticManager.shared.stopAll()
        MotionManager.shared.stopTiltUpdates()

        // Clear accessibility elements to prevent interaction after game ends
        view?.accessibilityElements = []
        accessibleElements.removeAll()

        phaseLabel.text = String(localized: "Shaking stopped.")
        phaseLabel.fontColor = SKColor(
            red: 0x1C / 255, green: 0x1C / 255, blue: 0x1E / 255, alpha: 1)
        instructionLabel.text = ""

        // Settle animation — restore warm lighting
        vignetteNode?.run(SKAction.fadeOut(withDuration: 1.5))
        coldOverlay?.run(SKAction.fadeOut(withDuration: 1.5))
        warmOverlay?.run(SKAction.fadeAlpha(to: 0.04, duration: 2.0))

        // Stop lamp flicker and return to gentle sway
        if let lampGlow = childNode(withName: "//lamp_glow") {
            lampGlow.speed = 0
            lampGlow.alpha = 1.0
        }
        if let lamp = childNode(withName: "//lamp") {
            lamp.removeAction(forKey: "sway")
            let swayRight = SKAction.rotate(toAngle: 0.03, duration: 1.5)
            swayRight.timingMode = .easeInEaseOut
            let swayLeft = SKAction.rotate(toAngle: -0.03, duration: 1.5)
            swayLeft.timingMode = .easeInEaseOut
            lamp.run(
                SKAction.repeatForever(SKAction.sequence([swayRight, swayLeft])), withKey: "sway")
        }

        // Add settling dust particles for atmospheric effect
        let settlingDustEmitter = ParticleEffects.settlingDust(duration: 4.0, intensity: 0.7)
        settlingDustEmitter.position = CGPoint(x: size.width / 2, y: size.height)
        addChild(settlingDustEmitter)

        // Remove emitter after emission completes
        run(SKAction.wait(forDuration: 5.0)) { [weak settlingDustEmitter] in
            settlingDustEmitter?.run(
                SKAction.sequence([
                    SKAction.wait(forDuration: 2.0),
                    SKAction.fadeOut(withDuration: 1.0),
                    SKAction.removeFromParent(),
                ]))
        }

        // Player walks to door, kicks it open, then transition
        guard let player = playerNode as? SKSpriteNode,
            let door = childNode(withName: "door") as? SKSpriteNode
        else {
            // Fallback if no player/door
            run(SKAction.wait(forDuration: GameTiming.debriefDelay)) { [weak self] in
                guard let self = self else { return }
                let totalTime = self.lastUpdateTime - self.gameStartTime
                let report = self.decisionEngine.generateEnhancedReport(totalTime: totalTime)
                self.quakeDelegate?.quakeSceneDidFinish(report: report)
            }
            return
        }

        player.removeAllActions()
        resetPlayerTransforms()
        player.texture = TextureFactory.playerTexture()
        // Disable all physics so player walks through everything
        player.physicsBody?.collisionBitMask = PhysicsCategory.none
        player.physicsBody?.contactTestBitMask = PhysicsCategory.none
        if isPlayerUnderCover {
            isPlayerUnderCover = false
            player.position.y = RoomLayout.floorHeight + RoomLayout.playerSize.height / 2 + 5
        }

        // Clear all physics so nothing blocks the exit walk
        physicsWorld.speed = 0
        door.physicsBody = nil

        // Remove all fallen debris/furniture
        enumerateChildNodes(withName: "//*") { node, _ in
            if let body = node.physicsBody,
                body.categoryBitMask == PhysicsCategory.debris
                    || body.categoryBitMask == PhysicsCategory.furniture
            {
                node.removeFromParent()
            }
        }

        // Target: just to the right of the door
        let doorRightEdge = door.position.x + RoomLayout.doorWidth / 2
        let stopX = doorRightEdge + 5
        let doorTarget = CGPoint(
            x: stopX, y: RoomLayout.floorHeight + RoomLayout.playerSize.height / 2 + 5)
        let distance = abs(doorTarget.x - player.position.x)
        let walkDuration = max(0.3, Double(distance) / 200.0)

        // Walk textures
        let walk1 = TextureFactory.playerRunTexture()
        let stand = TextureFactory.playerTexture()
        let walk2 = TextureFactory.playerWalk2Texture()
        let walkAnim = SKAction.repeatForever(
            SKAction.animate(with: [walk1, stand, walk2, stand], timePerFrame: 0.09)
        )

        // Run the full exit sequence on the scene (not the player) to avoid conflicts
        run(
            SKAction.sequence([
                // Face left and walk to door
                SKAction.run {
                    player.xScale = -abs(player.xScale)
                    player.texture = walk1
                    player.run(walkAnim, withKey: "exitWalk")
                    player.run(
                        SKAction.move(to: doorTarget, duration: walkDuration), withKey: "exitMove")
                },
                SKAction.wait(forDuration: walkDuration + 0.05),
                // Stop walking, face door, kick
                SKAction.run {
                    player.removeAction(forKey: "exitWalk")
                    player.xScale = -abs(player.xScale)
                    player.texture = TextureFactory.playerKickTexture()
                    AudioManager.shared.playDebrisFall()
                    HapticManager.shared.playImpact()
                },
                SKAction.wait(forDuration: 0.3),
                // Door swings open
                SKAction.run { [weak self] in
                    guard self != nil else { return }
                    let hingeX = door.position.x - RoomLayout.doorWidth / 2
                    door.anchorPoint = CGPoint(x: 0, y: 0.5)
                    door.position = CGPoint(x: hingeX, y: door.position.y)
                    door.run(SKAction.scaleX(to: -0.1, duration: 0.3))
                },
                SKAction.wait(forDuration: 0.35),
                // Player runs through door and fades out
                SKAction.run {
                    player.texture = TextureFactory.playerRunTexture()
                    player.xScale = -abs(player.xScale)
                    player.run(
                        SKAction.group([
                            SKAction.moveBy(x: -120, y: 0, duration: 0.5),
                            SKAction.sequence([
                                SKAction.wait(forDuration: 0.15),
                                SKAction.fadeOut(withDuration: 0.35),
                            ]),
                        ]))
                },
                SKAction.wait(forDuration: 0.6),
                // Fade to black
                SKAction.run { [weak self] in
                    guard let self = self else { return }
                    let black = SKSpriteNode(color: .black, size: self.size)
                    black.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
                    black.zPosition = 1000
                    black.alpha = 0
                    black.name = "transition_black"
                    self.addChild(black)
                    black.run(SKAction.fadeIn(withDuration: 0.5))
                },
                SKAction.wait(forDuration: 0.8),
                // Transition to debrief
                SKAction.run { [weak self] in
                    guard let self = self else { return }
                    let totalTime = self.lastUpdateTime - self.gameStartTime
                    let report = self.decisionEngine.generateEnhancedReport(totalTime: totalTime)

                    // Remove black node before transition
                    if let black = self.childNode(withName: "transition_black") {
                        black.removeFromParent()
                    }

                    self.quakeDelegate?.quakeSceneDidFinish(report: report)
                },
            ]))
    }

    // MARK: - Update Loop

    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }

        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        shakeController?.update(deltaTime: deltaTime)
        updateHUD()

        // Periodic creaking sounds during earthquake
        let phase = decisionEngine.currentPhase
        if phase == .sWave || phase == .pWave {
            let timeSinceLastCreak = currentTime - lastCreakTime
            if timeSinceLastCreak >= nextCreakInterval {
                lastCreakTime = currentTime
                nextCreakInterval = Double.random(in: 2.0...4.0)
                AudioManager.shared.playCreaking()
            }
        }

        // Tilt-based player movement during aftershock
        if phase == .aftershock,
            SettingsManager.shared.tiltControlEnabled,
            !SettingsManager.shared.isReducedMotionEnabled,
            let player = playerNode as? SKSpriteNode
        {
            let tilt = MotionManager.shared.currentTilt
            if abs(tilt) > TiltControl.deadZone {
                let dx = tilt * TiltControl.sensitivity * CGFloat(deltaTime)
                let newX = (player.position.x + dx).clamped(to: 60...size.width - 60)
                player.position.x = newX

                // Flip sprite to face movement direction
                if tilt < 0 {
                    player.xScale = -abs(player.xScale)
                } else {
                    player.xScale = abs(player.xScale)
                }
            }
        }

        // Check game over
        if decisionEngine.heartsRemaining <= 0 && decisionEngine.currentPhase != .debrief {
            shakeController.stopEarthquake()
        }
    }

    // MARK: - Debug / Marketing Capture

    #if DEBUG
    private func setupMarketingCaptureObservers() {
        NotificationCenter.default.addObserver(
            forName: MarketingCapture.autoMainDecisionNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.debug_triggerMainDecision()
        }
        NotificationCenter.default.addObserver(
            forName: MarketingCapture.autoAftershockDecisionNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.debug_triggerAftershockDecision()
        }
    }

    private func debug_triggerMainDecision() {
        guard !hasProcessedMainDecision else { return }
        // Find the safe zone node center and simulate a tap there
        if let safeZone = childNode(withName: safeZoneNodeName) {
            let center = safeZone.position
            handleMainPhaseTouch(at: center)
        }
    }

    private func debug_triggerAftershockDecision() {
        // Simulate tapping the first aftershock task node
        guard currentTaskIndex < aftershockTasks.count else { return }
        let task = aftershockTasks[currentTaskIndex]
        if let zone = childNode(withName: task.name) {
            _ = handleAftershockTouch(at: zone.position)
        }
    }
    #endif
}

// MARK: - QuakePhase Extensions

extension QuakePhase {
    var iconEmoji: String {
        switch self {
        case .story: return "📖"
        case .pWave: return "⚠️"
        case .sWave: return "🚨"
        case .aftershock: return "⚡"
        case .calm: return "🏠"
        case .countdown: return "3️⃣"
        case .debrief: return "📊"
        }
    }
}
