import SpriteKit

// MARK: - Material Type Enum

/// Material types with specific physics properties for realistic object behavior
enum MaterialType: CaseIterable {
    case wood
    case glass
    case metal
    case ceramic
    case fabric
    case paper
    
    /// Restitution (bounciness) 0-1
    var restitution: CGFloat {
        switch self {
        case .wood: return 0.3
        case .glass: return 0.2
        case .metal: return 0.5
        case .ceramic: return 0.15
        case .fabric: return 0.05
        case .paper: return 0.1
        }
    }
    
    /// Friction coefficient
    var friction: CGFloat {
        switch self {
        case .wood: return 0.6
        case .glass: return 0.1
        case .metal: return 0.4
        case .ceramic: return 0.5
        case .fabric: return 0.8
        case .paper: return 0.7
        }
    }
    
    /// Density (mass per unit volume)
    var density: CGFloat {
        switch self {
        case .wood: return 0.5
        case .glass: return 2.5
        case .metal: return 7.8
        case .ceramic: return 2.3
        case .fabric: return 0.1
        case .paper: return 0.2
        }
    }
    
    /// Angular damping (resistance to rotation)
    var angularDamping: CGFloat {
        switch self {
        case .wood: return 0.4
        case .glass: return 0.2
        case .metal: return 0.3
        case .ceramic: return 0.5
        case .fabric: return 0.8
        case .paper: return 0.9
        }
    }
    
    /// Linear damping (air resistance)
    var linearDamping: CGFloat {
        switch self {
        case .wood: return 0.2
        case .glass: return 0.1
        case .metal: return 0.15
        case .ceramic: return 0.3
        case .fabric: return 0.5
        case .paper: return 0.8
        }
    }
    
    /// Whether the material shatters/breaks on impact
    var isFragile: Bool {
        switch self {
        case .glass, .ceramic: return true
        default: return false
        }
    }
    
    /// Break threshold velocity (for fragile materials)
    var breakThreshold: CGFloat {
        switch self {
        case .glass: return 100
        case .ceramic: return 120
        default: return CGFloat.infinity
        }
    }
}

// MARK: - Particle Types

enum ParticleType {
    case dust
    case sparks
    case glass
    case wood
    case paper
    case ceramic
    
    var birthRate: CGFloat {
        switch self {
        case .dust: return 30
        case .sparks: return 150
        case .glass: return 200
        case .wood: return 120
        case .paper: return 80
        case .ceramic: return 100
        }
    }
    
    var lifetime: CGFloat {
        switch self {
        case .dust: return 3.0
        case .sparks: return 0.6
        case .glass: return 1.2
        case .wood: return 1.0
        case .paper: return 2.0
        case .ceramic: return 1.0
        }
    }
    
    var particleSpeed: CGFloat {
        switch self {
        case .dust: return 15
        case .sparks: return 200
        case .glass: return 150
        case .wood: return 100
        case .paper: return 60
        case .ceramic: return 90
        }
    }
    
    var color: SKColor {
        switch self {
        case .dust:
            return SKColor(red: 0.75, green: 0.70, blue: 0.65, alpha: 0.8)
        case .sparks:
            return SKColor(red: 1.0, green: 0.6, blue: 0.1, alpha: 1.0)
        case .glass:
            return SKColor(red: 0.75, green: 0.88, blue: 1.0, alpha: 0.9)
        case .wood:
            return SKColor(red: 0.55, green: 0.35, blue: 0.18, alpha: 0.9)
        case .paper:
            return SKColor(white: 0.95, alpha: 0.9)
        case .ceramic:
            return SKColor(red: 0.82, green: 0.42, blue: 0.22, alpha: 0.9)
        }
    }
}

// MARK: - Physics Object Data

/// Data structure for physics-enabled objects
struct PhysicsObjectData {
    let name: String
    let material: MaterialType
    let mass: CGFloat
    let size: CGSize
    var isBroken: Bool = false
    
    init(name: String, material: MaterialType, mass: CGFloat, size: CGSize) {
        self.name = name
        self.material = material
        self.mass = mass
        self.size = size
    }
}

// MARK: - Impact Zone

/// Represents a danger zone created by falling objects
struct ImpactZone {
    let node: SKNode
    let position: CGPoint
    let radius: CGFloat
    let damage: CGFloat
    let warningTime: TimeInterval
    let landTime: TimeInterval
    
    var isActive: Bool = false
    var hasLanded: Bool = false
}

// MARK: - Debris Manager

/// Manages interactive debris with lifecycle
@MainActor
final class DebrisManager {
    private weak var scene: SKScene?
    private var debrisNodes: [SKNode] = []
    private var debrisTimers: [SKNode: TimeInterval] = [:]
    
    private let maxDebrisCount = 50
    private let debrisFadeTime: TimeInterval = 8.0
    private let smallDebrisThreshold: CGFloat = 15.0
    
    init(scene: SKScene) {
        self.scene = scene
    }
    
    /// Register debris for management
    func registerDebris(_ node: SKNode, size: CGSize) {
        debrisNodes.append(node)
        
        // Small debris fades out over time
        if max(size.width, size.height) < smallDebrisThreshold {
            debrisTimers[node] = 0
        }
        
        // Limit total debris count
        if debrisNodes.count > maxDebrisCount {
            removeOldestDebris()
        }
    }
    
    /// Update debris timers and fade out old debris
    func update(deltaTime: TimeInterval) {
        for (node, timer) in debrisTimers {
            let newTimer = timer + deltaTime
            debrisTimers[node] = newTimer
            
            if newTimer >= debrisFadeTime {
                fadeOutAndRemove(node)
                debrisTimers.removeValue(forKey: node)
            } else if newTimer >= debrisFadeTime - 2.0 {
                // Start fading in last 2 seconds
                let alpha = CGFloat((debrisFadeTime - newTimer) / 2.0)
                node.alpha = alpha
            }
        }
    }
    
    /// Kick debris away from a point (e.g., player kick)
    func kickDebris(at point: CGPoint, radius: CGFloat, force: CGFloat) {
        for node in debrisNodes {
            guard let body = node.physicsBody,
                  body.isDynamic else { continue }
            
            let distance = node.position.distance(to: point)
            guard distance < radius else { continue }
            
            let direction = CGVector(
                dx: (node.position.x - point.x) / distance,
                dy: (node.position.y - point.y) / distance + 0.5 // Add upward component
            )
            
            let kickForce = CGVector(
                dx: direction.dx * force * (1 - distance / radius),
                dy: direction.dy * force * (1 - distance / radius)
            )
            
            body.applyImpulse(kickForce)
            body.applyAngularImpulse(CGFloat.random(in: -0.5...0.5))
        }
    }
    
    private func removeOldestDebris() {
        guard debrisNodes.count > 5 else { return }
        
        // Remove oldest non-dynamic debris first
        for i in 0..<min(5, debrisNodes.count) {
            let node = debrisNodes[i]
            if node.physicsBody?.isDynamic == false || node.alpha < 0.5 {
                fadeOutAndRemove(node)
                debrisNodes.remove(at: i)
                debrisTimers.removeValue(forKey: node)
                return
            }
        }
    }
    
    private func fadeOutAndRemove(_ node: SKNode) {
        node.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ]))
    }
    
    func reset() {
        debrisNodes.removeAll()
        debrisTimers.removeAll()
    }
}

// MARK: - Particle Pool

/// Object pool for particle emitters to optimize performance
@MainActor
final class ParticlePool {
    static let shared = ParticlePool()
    
    private var availableEmitters: [ParticleType: [SKEmitterNode]] = [:]
    private var activeEmitters: [SKEmitterNode: ParticleType] = [:]
    private let maxPoolSize = 10
    
    private init() {
        // Pre-warm pools
        for type in [ParticleType.dust, .sparks, .glass, .wood] {
            availableEmitters[type] = []
            for _ in 0..<3 {
                if let emitter = createEmitter(for: type) {
                    availableEmitters[type]?.append(emitter)
                }
            }
        }
    }
    
    func acquireEmitter(type: ParticleType) -> SKEmitterNode {
        if var pool = availableEmitters[type], !pool.isEmpty {
            let emitter = pool.removeFirst()
            availableEmitters[type] = pool
            activeEmitters[emitter] = type
            resetEmitter(emitter, type: type)
            return emitter
        }
        
        // Create new if pool empty
        let emitter = createEmitter(for: type) ?? SKEmitterNode()
        activeEmitters[emitter] = type
        return emitter
    }
    
    func releaseEmitter(_ emitter: SKEmitterNode) {
        emitter.removeFromParent()
        
        guard let type = activeEmitters.removeValue(forKey: emitter) else { return }
        
        if (availableEmitters[type]?.count ?? 0) < maxPoolSize {
            availableEmitters[type, default: []].append(emitter)
        }
    }
    
    private func createEmitter(for type: ParticleType) -> SKEmitterNode? {
        let emitter = SKEmitterNode()
        configureEmitter(emitter, type: type)
        return emitter
    }
    
    private func configureEmitter(_ emitter: SKEmitterNode, type: ParticleType) {
        emitter.particleTexture = TextureFactory.particleTexture(for: type)
        emitter.particleBirthRate = type.birthRate
        emitter.particleLifetime = type.lifetime
        emitter.particleLifetimeRange = type.lifetime * 0.3
        emitter.particleSpeed = type.particleSpeed
        emitter.particleSpeedRange = type.particleSpeed * 0.4
        emitter.emissionAngleRange = .pi * 2
        emitter.particleAlpha = 0.8
        emitter.particleAlphaSpeed = -0.6
        emitter.particleScale = 0.3
        emitter.particleScaleRange = 0.2
        emitter.particleScaleSpeed = -0.1
        emitter.particleRotationRange = .pi * 2
        emitter.particleRotationSpeed = 2.0
        emitter.particleColor = type.color
        emitter.particleColorBlendFactor = 1.0
        emitter.yAcceleration = type == .sparks ? -50 : -200
    }
    
    private func resetEmitter(_ emitter: SKEmitterNode, type: ParticleType) {
        emitter.particleBirthRate = type.birthRate
        emitter.particleAlpha = 0.8
        emitter.alpha = 1.0
        emitter.isPaused = false
    }
}

// MARK: - Enhanced Physics Manager

@MainActor
final class PhysicsManager {
    private weak var scene: SKScene?
    private var triggeredItems: Set<String> = []
    private var windowShattered = false
    private var crackOverlayAdded = false
    
    // Material-based object registry
    private var objectRegistry: [String: PhysicsObjectData] = [:]
    
    // Chain reaction tracking
    private var physicsJoints: [SKPhysicsJoint] = []
    private var fallingObjects: [SKNode] = []
    
    // Impact zones for player damage
    private var impactZones: [ImpactZone] = []
    
    // Managers
    private var debrisManager: DebrisManager?
    private var particlePool: ParticlePool { .shared }
    
    // Book scatter data
    private var scatteredBooks: [SKNode] = []
    
    // Lamp spark tracking
    private var hasLampSparked = false
    
    // Damage zone callback
    var onPlayerInDamageZone: ((CGFloat) -> Void)?
    
    init(scene: SKScene) {
        self.scene = scene
        self.debrisManager = DebrisManager(scene: scene)
        registerObjects()
    }
    
    // MARK: - Object Registration
    
    private func registerObjects() {
        // === LIVING ROOM OBJECTS ===
        objectRegistry["bookshelf"] = PhysicsObjectData(
            name: "bookshelf",
            material: .wood,
            mass: 5.0,
            size: CGSize(width: RoomLayout.bookshelfWidth, height: RoomLayout.bookshelfHeight)
        )

        objectRegistry["vase"] = PhysicsObjectData(
            name: "vase",
            material: .ceramic,
            mass: 0.5,
            size: CGSize(width: 20, height: 35)
        )

        objectRegistry["lamp"] = PhysicsObjectData(
            name: "lamp",
            material: .metal,
            mass: 0.8,
            size: CGSize(width: RoomLayout.lampSize, height: 20)
        )

        objectRegistry["picture_frame_1"] = PhysicsObjectData(
            name: "picture_frame_1",
            material: .wood,
            mass: 0.4,
            size: CGSize(width: 50, height: 40)
        )

        objectRegistry["picture_frame_2"] = PhysicsObjectData(
            name: "picture_frame_2",
            material: .wood,
            mass: 0.4,
            size: CGSize(width: 45, height: 55)
        )

        objectRegistry["clock"] = PhysicsObjectData(
            name: "clock",
            material: .metal,
            mass: 0.3,
            size: CGSize(width: 44, height: 44)
        )

        // Register book rows
        for i in 0..<4 {
            objectRegistry["book_row_\(i)"] = PhysicsObjectData(
                name: "book_row_\(i)",
                material: .paper,
                mass: 0.1,
                size: CGSize(width: 30, height: 20)
            )
        }

        // === KITCHEN OBJECTS ===
        objectRegistry["refrigerator"] = PhysicsObjectData(
            name: "refrigerator",
            material: .metal,
            mass: 8.0,
            size: CGSize(width: 70, height: 140)
        )

        objectRegistry["microwave"] = PhysicsObjectData(
            name: "microwave",
            material: .metal,
            mass: 1.2,
            size: CGSize(width: 50, height: 30)
        )

        objectRegistry["coffee_maker"] = PhysicsObjectData(
            name: "coffee_maker",
            material: .metal,
            mass: 0.6,
            size: CGSize(width: 30, height: 35)
        )

        objectRegistry["toaster"] = PhysicsObjectData(
            name: "toaster",
            material: .metal,
            mass: 0.5,
            size: CGSize(width: 28, height: 22)
        )

        objectRegistry["kettle"] = PhysicsObjectData(
            name: "kettle",
            material: .metal,
            mass: 0.4,
            size: CGSize(width: 24, height: 20)
        )

        objectRegistry["knife_block"] = PhysicsObjectData(
            name: "knife_block",
            material: .wood,
            mass: 0.6,
            size: CGSize(width: 20, height: 25)
        )

        objectRegistry["cutting_board"] = PhysicsObjectData(
            name: "cutting_board",
            material: .wood,
            mass: 0.3,
            size: CGSize(width: 35, height: 5)
        )

        objectRegistry["fruit_bowl"] = PhysicsObjectData(
            name: "fruit_bowl",
            material: .ceramic,
            mass: 0.4,
            size: CGSize(width: 30, height: 15)
        )

        // Hanging pots/pans
        for i in 0..<3 {
            objectRegistry["hanging_pot_\(i)"] = PhysicsObjectData(
                name: "hanging_pot_\(i)",
                material: .metal,
                mass: 0.8 + CGFloat(i) * 0.1,
                size: CGSize(width: 35, height: 20)
            )
        }

        // Cabinet items
        for i in 0..<3 {
            objectRegistry["cabinet_item_\(i)"] = PhysicsObjectData(
                name: "cabinet_item_\(i)",
                material: .ceramic,
                mass: 0.3,
                size: CGSize(width: 15, height: 20)
            )
        }

        // === OFFICE OBJECTS ===
        objectRegistry["monitor"] = PhysicsObjectData(
            name: "monitor",
            material: .glass,
            mass: 1.5,
            size: CGSize(width: 60, height: 40)
        )

        objectRegistry["laptop"] = PhysicsObjectData(
            name: "laptop",
            material: .metal,
            mass: 1.0,
            size: CGSize(width: 45, height: 30)
        )

        objectRegistry["filing_cabinet"] = PhysicsObjectData(
            name: "filing_cabinet",
            material: .metal,
            mass: 6.0,
            size: CGSize(width: 50, height: 90)
        )

        objectRegistry["desk_lamp"] = PhysicsObjectData(
            name: "desk_lamp",
            material: .metal,
            mass: 0.5,
            size: CGSize(width: 25, height: 35)
        )

        objectRegistry["printer"] = PhysicsObjectData(
            name: "printer",
            material: .metal,
            mass: 1.8,
            size: CGSize(width: 50, height: 35)
        )

        objectRegistry["books_office"] = PhysicsObjectData(
            name: "books_office",
            material: .paper,
            mass: 0.4,
            size: CGSize(width: 40, height: 25)
        )

        objectRegistry["coffee_mug"] = PhysicsObjectData(
            name: "coffee_mug",
            material: .ceramic,
            mass: 0.2,
            size: CGSize(width: 12, height: 14)
        )

        objectRegistry["whiteboard"] = PhysicsObjectData(
            name: "whiteboard",
            material: .metal,
            mass: 2.0,
            size: CGSize(width: 80, height: 50)
        )

        objectRegistry["potted_plant"] = PhysicsObjectData(
            name: "potted_plant",
            material: .ceramic,
            mass: 0.6,
            size: CGSize(width: 25, height: 30)
        )

        // === BEDROOM OBJECTS ===
        objectRegistry["nightstand_lamp_left"] = PhysicsObjectData(
            name: "nightstand_lamp_left",
            material: .metal,
            mass: 0.4,
            size: CGSize(width: 20, height: 30)
        )

        objectRegistry["nightstand_lamp_right"] = PhysicsObjectData(
            name: "nightstand_lamp_right",
            material: .metal,
            mass: 0.4,
            size: CGSize(width: 20, height: 30)
        )

        objectRegistry["alarm_clock"] = PhysicsObjectData(
            name: "alarm_clock",
            material: .metal,
            mass: 0.15,
            size: CGSize(width: 18, height: 12)
        )

        objectRegistry["teddy_bear"] = PhysicsObjectData(
            name: "teddy_bear",
            material: .fabric,
            mass: 0.2,
            size: CGSize(width: 25, height: 30)
        )

        objectRegistry["book_stack"] = PhysicsObjectData(
            name: "book_stack",
            material: .paper,
            mass: 0.5,
            size: CGSize(width: 30, height: 20)
        )

        objectRegistry["mirror"] = PhysicsObjectData(
            name: "mirror",
            material: .glass,
            mass: 1.2,
            size: CGSize(width: 40, height: 60)
        )

        objectRegistry["wardrobe"] = PhysicsObjectData(
            name: "wardrobe",
            material: .wood,
            mass: 7.0,
            size: CGSize(width: 100, height: 160)
        )

        objectRegistry["window"] = PhysicsObjectData(
            name: "window",
            material: .glass,
            mass: 2.0,
            size: CGSize(width: RoomLayout.windowWidth, height: RoomLayout.windowHeight)
        )
    }
    
    // MARK: - Trigger Physics Based on Intensity
    
    func triggerObjectPhysics(intensity: CGFloat) {
        guard let scene = scene else { return }

        // Books and small items (Living Room + Bedroom)
        if intensity > IntensityThreshold.booksAndSmallItems {
            triggerDebris(named: "book_row_", count: 4, in: scene, intensity: intensity)
            triggerDebris(named: "vase", in: scene, intensity: intensity)
            triggerDebris(named: "book_stack", in: scene, intensity: intensity)
            triggerDebris(named: "teddy_bear", in: scene, intensity: intensity)
            triggerDebris(named: "alarm_clock", in: scene, intensity: intensity)
            triggerDebris(named: "books_office", in: scene, intensity: intensity)
        }

        // Picture frames and wall items
        if intensity > IntensityThreshold.pictureFrames {
            triggerDebris(named: "picture_frame_1", in: scene, intensity: intensity)
            triggerDebris(named: "picture_frame_2", in: scene, intensity: intensity)
            triggerDebris(named: "clock", in: scene, intensity: intensity)
            triggerDebris(named: "mirror", in: scene, intensity: intensity)
            triggerDebris(named: "whiteboard", in: scene, intensity: intensity)
        }

        // Kitchen items (fall at lower intensity)
        if intensity > 0.25 {
            triggerDebris(named: "hanging_pot_", count: 3, in: scene, intensity: intensity)
            triggerDebris(named: "coffee_maker", in: scene, intensity: intensity)
            triggerDebris(named: "kettle", in: scene, intensity: intensity)
            triggerDebris(named: "knife_block", in: scene, intensity: intensity)
            triggerDebris(named: "cabinet_item_", count: 3, in: scene, intensity: intensity)
        }

        // Kitchen counter items (medium intensity)
        if intensity > 0.4 {
            triggerDebris(named: "microwave", in: scene, intensity: intensity)
            triggerDebris(named: "toaster", in: scene, intensity: intensity)
            triggerDebris(named: "coffee_mug", in: scene, intensity: intensity)
            triggerDebris(named: "fruit_bowl", in: scene, intensity: intensity)
            triggerDebris(named: "cutting_board", in: scene, intensity: intensity)
            triggerDebris(named: "cutting_board", in: scene, intensity: intensity)
        }

        // Office desk items
        if intensity > 0.35 {
            triggerDebris(named: "monitor", in: scene, intensity: intensity)
            triggerDebris(named: "laptop", in: scene, intensity: intensity)
            triggerDebris(named: "desk_lamp", in: scene, intensity: intensity)
            triggerDebris(named: "printer", in: scene, intensity: intensity)
            triggerDebris(named: "potted_plant", in: scene, intensity: intensity)
        }

        // Bedroom nightstand items
        if intensity > 0.3 {
            triggerDebris(named: "nightstand_lamp_left", in: scene, intensity: intensity)
            triggerDebris(named: "nightstand_lamp_right", in: scene, intensity: intensity)
        }

        // Floor cracks
        if intensity > IntensityThreshold.floorCracks {
            addFloorCracks(in: scene)
        }

        // Screen crack overlay
        if intensity > 0.6 {
            addScreenCrackOverlay(in: scene)
        }

        // Bookshelf topple (triggers chain reaction)
        if intensity > IntensityThreshold.bookshelfTopple {
            triggerBookshelfTopple(in: scene, intensity: intensity)
        }

        // Heavy furniture topple (office filing cabinet, bedroom wardrobe, kitchen refrigerator)
        if intensity > 0.65 {
            triggerHeavyFurnitureTopple(named: "filing_cabinet", in: scene, intensity: intensity)
            triggerHeavyFurnitureTopple(named: "wardrobe", in: scene, intensity: intensity)
            triggerHeavyFurnitureTopple(named: "refrigerator", in: scene, intensity: intensity)
        }

        // Window shatter with shards
        if intensity > IntensityThreshold.windowShatter && !windowShattered {
            shatterWindow(in: scene)
        }

        // Ceiling lamp with sparks on impact
        if intensity > IntensityThreshold.ceilingLampFall {
            triggerCeilingLamp(in: scene, intensity: intensity)
        }
    }
    
    // MARK: - Material-Based Debris Trigger
    
    private func triggerDebris(named prefix: String, count: Int = 1, in scene: SKScene, intensity: CGFloat) {
        for i in 0..<count {
            let name = count > 1 ? "\(prefix)\(i)" : prefix
            guard !triggeredItems.contains(name),
                  let node = scene.childNode(withName: name),
                  let data = objectRegistry[name] else { continue }
            
            triggeredItems.insert(name)
            
            // Apply material-based physics properties
            applyMaterialPhysics(to: node, data: data)
            
            // Calculate realistic impulse based on material mass
            let dx = CGFloat.random(in: -intensity * 50...intensity * 50)
            let dy = CGFloat.random(in: 0...intensity * 30)
            let impulse = CGVector(
                dx: dx * (1 + data.material.density * 0.1),
                dy: dy * (1 + data.material.density * 0.05)
            )
            
            node.physicsBody?.applyImpulse(impulse)
            
            // Apply angular impulse for realistic rotation
            let angularImpulse = CGFloat.random(in: -0.2...0.2) * (1 / data.material.angularDamping)
            node.physicsBody?.applyAngularImpulse(angularImpulse)
            
            // Enable rolling for round objects
            if name.contains("clock") || data.material == .metal {
                node.physicsBody?.allowsRotation = true
                node.physicsBody?.angularDamping = data.material.angularDamping
            }
            
            // Register with debris manager
            debrisManager?.registerDebris(node, size: data.size)
            
            // Setup break detection for fragile materials
            if data.material.isFragile {
                setupBreakDetection(for: node, data: data)
            }
        }
    }
    
    private func applyMaterialPhysics(to node: SKNode, data: PhysicsObjectData) {
        node.physicsBody?.isDynamic = true
        node.physicsBody?.affectedByGravity = true
        node.physicsBody?.restitution = data.material.restitution
        node.physicsBody?.friction = data.material.friction
        node.physicsBody?.mass = data.mass
        node.physicsBody?.linearDamping = data.material.linearDamping
        node.physicsBody?.angularDamping = data.material.angularDamping
    }
    
    // MARK: - Chain Reactions
    
    private func triggerBookshelfTopple(in scene: SKScene, intensity: CGFloat) {
        guard !triggeredItems.contains("bookshelf"),
              let bookshelf = scene.childNode(withName: "bookshelf") else { return }
        triggeredItems.insert("bookshelf")
        
        // Apply wood material physics
        if let data = objectRegistry["bookshelf"] {
            applyMaterialPhysics(to: bookshelf, data: data)
        }
        
        // Push it to topple with realistic force
        let pushForce = CGVector(dx: 80 * intensity, dy: 20 * intensity)
        bookshelf.physicsBody?.applyImpulse(pushForce)
        bookshelf.physicsBody?.applyAngularImpulse(0.3 * intensity)
        
        // Add to falling objects for chain reaction tracking
        fallingObjects.append(bookshelf)
        
        // Create impact zone warning
        createImpactZone(at: bookshelf.position, radius: 100, damage: 25, delay: 0.8)
        
        // Scatter books when shelf falls
        let wait = SKAction.wait(forDuration: 0.5)
        let scatterBooks = SKAction.run { [weak self] in
            self?.scatterBooksFromShelf(in: scene, intensity: intensity)
        }
        
        // Trigger chain reaction - knock nearby objects
        let chainReaction = SKAction.run { [weak self] in
            self?.triggerChainReaction(from: bookshelf, in: scene, radius: 150, intensity: intensity)
        }
        
        // Spawn particles after impact
        let spawnParticles = SKAction.run { [weak self] in
            self?.addMaterialParticles(at: bookshelf.position, material: .wood, count: 30)
            self?.addImpactFlash(at: bookshelf.position, in: scene)
        }
        
        scene.run(SKAction.sequence([
            wait,
            scatterBooks,
            SKAction.wait(forDuration: 0.3),
            chainReaction,
            SKAction.wait(forDuration: 0.5),
            spawnParticles
        ]))
        
        // Audio
        AudioManager.shared.playWoodCrash()
    }
    
    private func scatterBooksFromShelf(in scene: SKScene, intensity: CGFloat) {
        let bookColors: [SKColor] = [
            SKColor(red: 0.88, green: 0.22, blue: 0.20, alpha: 1.0),
            SKColor(red: 0.22, green: 0.45, blue: 0.82, alpha: 1.0),
            SKColor(red: 0.20, green: 0.68, blue: 0.30, alpha: 1.0),
            SKColor(red: 0.95, green: 0.78, blue: 0.15, alpha: 1.0),
            SKColor(red: 0.60, green: 0.28, blue: 0.72, alpha: 1.0)
        ]
        
        let shelfX = scene.size.width - 100
        let shelfY = RoomLayout.floorHeight + RoomLayout.bookshelfHeight / 2
        
        // Create scattered book physics objects with textured sprites
        for i in 0..<8 {
            let bookSize = CGSize(width: CGFloat.random(in: 15...25), height: CGFloat.random(in: 20...30))
            let bookColor = bookColors[i % bookColors.count]
            let bookTexture = TextureFactory.scatteredBookTexture(color: bookColor, width: bookSize.width, height: bookSize.height)
            let book = SKSpriteNode(texture: bookTexture, size: bookSize)
            
            // Random position near bookshelf
            let offsetX = CGFloat.random(in: -40...60)
            let offsetY = CGFloat.random(in: -80...80)
            book.position = CGPoint(x: shelfX + offsetX, y: shelfY + offsetY)
            book.zPosition = 3
            book.name = "scattered_book_\(i)"
            
            // Paper material physics
            book.physicsBody = SKPhysicsBody(rectangleOf: bookSize)
            book.physicsBody?.isDynamic = true
            book.physicsBody?.affectedByGravity = true
            book.physicsBody?.restitution = MaterialType.paper.restitution
            book.physicsBody?.friction = MaterialType.paper.friction
            book.physicsBody?.mass = 0.1
            book.physicsBody?.linearDamping = MaterialType.paper.linearDamping
            book.physicsBody?.angularDamping = MaterialType.paper.angularDamping
            book.physicsBody?.categoryBitMask = PhysicsCategory.debris
            book.physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.floor
            
            // Apply scatter impulse
            let impulseX = CGFloat.random(in: -30...50) * intensity
            let impulseY = CGFloat.random(in: 20...60) * intensity
            book.physicsBody?.applyImpulse(CGVector(dx: impulseX, dy: impulseY))
            book.physicsBody?.applyAngularImpulse(CGFloat.random(in: -0.5...0.5))
            
            scene.addChild(book)
            scatteredBooks.append(book)
            debrisManager?.registerDebris(book, size: bookSize)
        }
        
        // Add paper particle effect
        addMaterialParticles(at: CGPoint(x: shelfX, y: shelfY), material: .paper, count: 15)
    }

    private func triggerHeavyFurnitureTopple(named name: String, in scene: SKScene, intensity: CGFloat) {
        guard !triggeredItems.contains(name),
              let furniture = scene.childNode(withName: name),
              let data = objectRegistry[name] else { return }
        triggeredItems.insert(name)

        // Apply material physics
        applyMaterialPhysics(to: furniture, data: data)

        // Heavy furniture requires more force to topple
        let pushForce = CGVector(dx: 100 * intensity * (data.mass / 5.0), dy: 30 * intensity)
        furniture.physicsBody?.applyImpulse(pushForce)
        furniture.physicsBody?.applyAngularImpulse(0.2 * intensity)

        // Add to falling objects
        fallingObjects.append(furniture)

        // Create larger impact zone for heavy furniture
        createImpactZone(at: furniture.position, radius: 120, damage: 30, delay: 1.0)

        // Spawn particles after impact
        let wait = SKAction.wait(forDuration: 0.8)
        let spawnParticles = SKAction.run { [weak self] in
            self?.addMaterialParticles(at: furniture.position, material: data.material, count: 25)
            self?.addImpactFlash(at: furniture.position, in: scene)
        }

        scene.run(SKAction.sequence([wait, spawnParticles]))

        // Play appropriate sound based on material
        if data.material == .metal {
            AudioManager.shared.playImpact()
        } else {
            AudioManager.shared.playWoodCrash()
        }
    }

    private func triggerChainReaction(from source: SKNode, in scene: SKScene, radius: CGFloat, intensity: CGFloat) {
        // Find nearby objects that could be knocked over
        let nearbyNodes = [
            scene.childNode(withName: "potted_plant"),
            scene.childNode(withName: "table_top")
        ].compactMap { $0 }
        
        for node in nearbyNodes {
            let distance = node.position.distance(to: source.position)
            guard distance < radius else { continue }
            
            // Only affect if not already triggered
            guard let name = node.name, !triggeredItems.contains(name) else { continue }
            
            triggeredItems.insert(name)
            
            // Apply impulse based on distance (closer = more force)
            let forceMultiplier = (1 - distance / radius) * intensity
            let direction = CGVector(
                dx: (node.position.x - source.position.x) / distance,
                dy: (node.position.y - source.position.y) / distance
            )
            
            node.physicsBody?.isDynamic = true
            node.physicsBody?.affectedByGravity = true
            node.physicsBody?.applyImpulse(CGVector(
                dx: direction.dx * 50 * forceMultiplier,
                dy: direction.dy * 30 * forceMultiplier + 20
            ))
            
            // Domino effect for stacked items
            if name.contains("table") {
                // Table falling could knock other items
                let dominoDelay = SKAction.wait(forDuration: 0.3)
                let dominoEffect = SKAction.run { [weak self] in
                    self?.triggerDominoEffect(from: node, in: scene, intensity: intensity * 0.7)
                }
                scene.run(SKAction.sequence([dominoDelay, dominoEffect]))
            }
        }
    }
    
    private func triggerDominoEffect(from source: SKNode, in scene: SKScene, intensity: CGFloat) {
        // Items on the table could fall
        if let vase = scene.childNode(withName: "vase"), !triggeredItems.contains("vase") {
            triggeredItems.insert("vase")
            
            vase.physicsBody?.isDynamic = true
            vase.physicsBody?.affectedByGravity = true
            vase.physicsBody?.applyImpulse(CGVector(dx: CGFloat.random(in: -20...20), dy: 40 * intensity))
            vase.physicsBody?.applyAngularImpulse(0.2)
            
            // Break detection for ceramic
            setupBreakDetection(for: vase, data: objectRegistry["vase"]!)
        }
    }
    
    // MARK: - Window Shattering with Shards
    
    private func shatterWindow(in scene: SKScene) {
        guard let window = scene.childNode(withName: "window") else { return }
        windowShattered = true
        
        let windowPos = window.position
        window.removeFromParent()
        
        // Create glass shards with physics
        createGlassShards(at: windowPos, in: scene)
        
        // Glass particle effect from pool
        addMaterialParticles(at: windowPos, material: .glass, count: 50)
        addImpactFlash(at: windowPos, in: scene)
        
        // Audio
        AudioManager.shared.playGlassShatter()
    }
    
    private func createGlassShards(at position: CGPoint, in scene: SKScene) {
        let shardCount = 12
        
        for i in 0..<shardCount {
            let size = CGSize(width: CGFloat.random(in: 8...16), height: CGFloat.random(in: 8...16))
            let shard = SKSpriteNode(color: SKColor(red: 0.75, green: 0.88, blue: 1.0, alpha: 0.8), size: size)
            
            // Position in window area
            let angle = (CGFloat(i) / CGFloat(shardCount)) * .pi * 2
            let radius = CGFloat.random(in: 20...50)
            shard.position = CGPoint(
                x: position.x + cos(angle) * radius,
                y: position.y + sin(angle) * radius
            )
            shard.zPosition = 2
            shard.zRotation = CGFloat.random(in: 0...(.pi * 2))
            shard.name = "glass_shard_\(i)"
            
            // Glass physics
            shard.physicsBody = SKPhysicsBody(rectangleOf: size)
            shard.physicsBody?.isDynamic = true
            shard.physicsBody?.affectedByGravity = true
            shard.physicsBody?.restitution = MaterialType.glass.restitution
            shard.physicsBody?.friction = MaterialType.glass.friction
            shard.physicsBody?.mass = 0.05
            shard.physicsBody?.categoryBitMask = PhysicsCategory.debris
            shard.physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.floor
            
            // Explosive scatter
            let force = CGFloat.random(in: 80...150)
            shard.physicsBody?.applyImpulse(CGVector(
                dx: cos(angle) * force,
                dy: sin(angle) * force - 50
            ))
            shard.physicsBody?.applyAngularImpulse(CGFloat.random(in: -2...2))
            
            scene.addChild(shard)
            debrisManager?.registerDebris(shard, size: size)
        }
    }
    
    // MARK: - Ceiling Lamp with Sparks
    
    private func triggerCeilingLamp(in scene: SKScene, intensity: CGFloat) {
        guard !triggeredItems.contains("lamp"),
              let lamp = scene.childNode(withName: "lamp") else { return }
        triggeredItems.insert("lamp")
        
        // Stop sway animation
        lamp.removeAction(forKey: "sway")
        lamp.zRotation = 0
        
        // Apply metal physics
        if let data = objectRegistry["lamp"] {
            applyMaterialPhysics(to: lamp, data: data)
        }
        
        // Fall with pendulum motion
        let fallImpulse = CGVector(dx: CGFloat.random(in: -30...30) * intensity, dy: -10)
        lamp.physicsBody?.applyImpulse(fallImpulse)
        lamp.physicsBody?.applyAngularImpulse(CGFloat.random(in: -0.3...0.3))

        // Spawn electrical sparks at cord detach point
        let sparks = ParticleEffects.electricalSparks(at: lamp.position, intensity: 0.6)
        sparks.numParticlesToEmit = 30
        scene.addChild(sparks)
        sparks.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.8),
            SKAction.removeFromParent()
        ]))

        // Fade out cord and glow
        if let cord = scene.childNode(withName: "lamp_cord") {
            cord.fadeOutAndRemove(duration: 0.2)
        }
        if let glow = scene.childNode(withName: "lamp_glow") {
            glow.fadeOutAndRemove(duration: 0.3)
        }
        
        // Setup impact detection for sparks
        setupLampImpactDetection(for: lamp, in: scene)
    }
    
    private func setupLampImpactDetection(for lamp: SKNode, in scene: SKScene) {
        var hasImpacted = false
        
        let checkImpact = SKAction.run { [weak self] in
            guard !hasImpacted,
                  let body = lamp.physicsBody,
                  body.isDynamic else { return }
            
            // Check if lamp has hit the floor (low velocity and low y position)
            let velocity = body.velocity
            let speed = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
            
            if lamp.position.y < RoomLayout.floorHeight + 30 && speed < 50 {
                hasImpacted = true
                self?.triggerLampSparks(at: lamp.position, in: scene)
                
                // Lamp breaks/bends on impact
                lamp.run(SKAction.sequence([
                    SKAction.scaleY(to: 0.6, duration: 0.1),
                    SKAction.scaleY(to: 0.8, duration: 0.2)
                ]))
            }
        }
        
        let wait = SKAction.wait(forDuration: 0.1)
        let sequence = SKAction.sequence([wait, checkImpact])
        let repeatAction = SKAction.repeat(sequence, count: 50)
        
        scene.run(repeatAction)
    }
    
    private func triggerLampSparks(at position: CGPoint, in scene: SKScene) {
        guard !hasLampSparked else { return }
        hasLampSparked = true
        
        // Use particle pool for sparks
        let sparkEmitter = particlePool.acquireEmitter(type: .sparks)
        sparkEmitter.position = position
        sparkEmitter.zPosition = 25
        sparkEmitter.numParticlesToEmit = 30
        sparkEmitter.emissionAngle = .pi / 2
        sparkEmitter.emissionAngleRange = .pi / 3
        
        scene.addChild(sparkEmitter)
        
        // Return emitter to pool after use
        let wait = SKAction.wait(forDuration: 1.5)
        let release = SKAction.run { [weak self] in
            self?.particlePool.releaseEmitter(sparkEmitter)
        }
        scene.run(SKAction.sequence([wait, release]))
        
        // Flash effect
        addImpactFlash(at: position, in: scene)
        
        // Electrical sound
        AudioManager.shared.playImpact()
    }
    
    // MARK: - Break Detection for Fragile Materials
    
    private func setupBreakDetection(for node: SKNode, data: PhysicsObjectData) {
        guard data.material.isFragile else { return }
        
        var hasBroken = false
        
        let checkBreak = SKAction.run { [weak self] in
            guard !hasBroken,
                  let body = node.physicsBody,
                  body.isDynamic else { return }
            
            let velocity = body.velocity
            let speed = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
            
            if speed > data.material.breakThreshold {
                hasBroken = true
                self?.breakObject(node, data: data)
            }
        }
        
        let sequence = SKAction.sequence([SKAction.wait(forDuration: 0.05), checkBreak])
        let repeatAction = SKAction.repeat(sequence, count: 100)
        
        scene?.run(repeatAction)
    }
    
    private func breakObject(_ node: SKNode, data: PhysicsObjectData) {
        guard let scene = scene else { return }
        
        let position = node.position
        let size = data.size
        
        // Remove original
        node.removeFromParent()
        
        // Create broken pieces
        let pieceCount = data.material == .glass ? 8 : 6
        for i in 0..<pieceCount {
            let pieceSize = CGSize(width: size.width / 3, height: size.height / 3)
            let piece = SKSpriteNode(
                color: data.material == .glass 
                    ? SKColor(red: 0.75, green: 0.88, blue: 1.0, alpha: 0.7)
                    : SKColor(red: 0.82, green: 0.42, blue: 0.22, alpha: 1.0),
                size: pieceSize
            )
            
            let angle = (CGFloat(i) / CGFloat(pieceCount)) * .pi * 2
            piece.position = CGPoint(
                x: position.x + cos(angle) * CGFloat.random(in: 5...15),
                y: position.y + sin(angle) * CGFloat.random(in: 5...15)
            )
            piece.zPosition = 2
            piece.zRotation = CGFloat.random(in: 0...(.pi * 2))
            
            piece.physicsBody = SKPhysicsBody(rectangleOf: pieceSize)
            piece.physicsBody?.isDynamic = true
            piece.physicsBody?.affectedByGravity = true
            piece.physicsBody?.restitution = data.material.restitution * 0.5
            piece.physicsBody?.friction = data.material.friction
            piece.physicsBody?.mass = data.mass / CGFloat(pieceCount)
            piece.physicsBody?.categoryBitMask = PhysicsCategory.debris
            piece.physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.floor
            
            // Scatter pieces
            let force = CGFloat.random(in: 30...60)
            piece.physicsBody?.applyImpulse(CGVector(
                dx: cos(angle) * force,
                dy: sin(angle) * force
            ))
            
            scene.addChild(piece)
            debrisManager?.registerDebris(piece, size: pieceSize)
        }
        
        // Material-specific particles
        addMaterialParticles(at: position, material: data.material, count: 20)
        
        // Sound based on material
        switch data.material {
        case .glass:
            AudioManager.shared.playGlassShatter()
        case .ceramic:
            AudioManager.shared.playWoodCrash() // Reuse for now
        default:
            break
        }
    }
    
    // MARK: - Impact Zones (Damage Zones)
    
    private func createImpactZone(at position: CGPoint, radius: CGFloat, damage: CGFloat, delay: TimeInterval) {
        guard let scene = scene else { return }
        
        // Visual warning indicator
        let warningNode = SKShapeNode(circleOfRadius: radius)
        warningNode.fillColor = SKColor.red.withAlphaComponent(0.2)
        warningNode.strokeColor = SKColor.red.withAlphaComponent(0.5)
        warningNode.lineWidth = 2
        warningNode.position = position
        warningNode.zPosition = 1
        warningNode.alpha = 0
        scene.addChild(warningNode)
        
        // Pulse animation to warn player
        let fadeIn = SKAction.fadeAlpha(to: 0.5, duration: 0.3)
        let fadeOut = SKAction.fadeAlpha(to: 0.2, duration: 0.3)
        let pulse = SKAction.repeat(SKAction.sequence([fadeIn, fadeOut]), count: Int(delay * 2))
        warningNode.run(pulse)
        
        // Create impact zone
        let impactZone = ImpactZone(
            node: warningNode,
            position: position,
            radius: radius,
            damage: damage,
            warningTime: CACurrentMediaTime(),
            landTime: CACurrentMediaTime() + delay
        )
        impactZones.append(impactZone)
        
        // Activate after delay
        let activateAction = SKAction.run { [weak self] in
            self?.activateImpactZone(at: position, radius: radius, damage: damage, warningNode: warningNode)
        }
        scene.run(SKAction.sequence([SKAction.wait(forDuration: delay), activateAction]))
    }
    
    private func activateImpactZone(at position: CGPoint, radius: CGFloat, damage: CGFloat, warningNode: SKNode) {
        // Flash the zone
        let flash = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.8, duration: 0.1),
            SKAction.fadeAlpha(to: 0, duration: 0.3)
        ])
        warningNode.run(SKAction.sequence([flash, SKAction.removeFromParent()]))
        
        // Check if player is in damage zone
        if let player = scene?.childNode(withName: "player") {
            let distance = player.position.distance(to: position)
            if distance < radius {
                onPlayerInDamageZone?(damage)
            }
        }
        
        // Add impact particles
        addImpactParticles(at: position, in: scene!)
    }
    
    /// Check if player is in any active damage zone (called from update)
    func checkPlayerInDamageZones(playerPosition: CGPoint) -> CGFloat {
        var totalDamage: CGFloat = 0
        let currentTime = CACurrentMediaTime()
        
        for zone in impactZones {
            guard currentTime >= zone.landTime,
                  !zone.hasLanded else { continue }
            
            let distance = playerPosition.distance(to: zone.position)
            if distance < zone.radius {
                // Damage falls off with distance
                let damageMultiplier = 1 - (distance / zone.radius)
                totalDamage += zone.damage * damageMultiplier
            }
        }
        
        return totalDamage
    }
    
    // MARK: - Screen Crack Overlay
    
    private func addScreenCrackOverlay(in scene: SKScene) {
        guard !crackOverlayAdded else { return }
        crackOverlayAdded = true
        
        guard let cameraNode = scene.camera else { return }
        
        let crackNode = SKNode()
        crackNode.zPosition = 80
        crackNode.name = "screen_crack"
        crackNode.alpha = 0
        
        // Generate 3 crack branches
        for branch in 0..<3 {
            let path = CGMutablePath()
            let startX: CGFloat
            let startY: CGFloat
            
            switch branch {
            case 0:
                startX = CGFloat.random(in: -200...(-50))
                startY = scene.size.height / 2
            case 1:
                startX = CGFloat.random(in: 50...200)
                startY = scene.size.height / 2
            default:
                startX = CGFloat.random(in: -100...100)
                startY = -scene.size.height / 2
            }
            
            path.move(to: CGPoint(x: startX, y: startY))
            
            var cx = startX
            var cy = startY
            let segments = Int.random(in: 6...12)
            
            for _ in 0..<segments {
                cx += CGFloat.random(in: -40...40)
                cy += CGFloat.random(in: -60...(-10))
                path.addLine(to: CGPoint(x: cx, y: cy))
                
                // Occasional sub-branch
                if Bool.random() {
                    let subPath = CGMutablePath()
                    subPath.move(to: CGPoint(x: cx, y: cy))
                    subPath.addLine(to: CGPoint(
                        x: cx + CGFloat.random(in: -30...30),
                        y: cy + CGFloat.random(in: -25...25)
                    ))
                    let subCrack = SKShapeNode(path: subPath)
                    subCrack.strokeColor = SKColor(white: 0.9, alpha: 0.4)
                    subCrack.lineWidth = 1
                    crackNode.addChild(subCrack)
                }
            }
            
            let crack = SKShapeNode(path: path)
            crack.strokeColor = SKColor(white: 0.9, alpha: 0.6)
            crack.lineWidth = 2
            crackNode.addChild(crack)
        }
        
        cameraNode.addChild(crackNode)
        crackNode.run(SKAction.fadeAlpha(to: 0.7, duration: 0.3))
    }
    
    // MARK: - Floor Cracks
    
    private func addFloorCracks(in scene: SKScene) {
        guard !triggeredItems.contains("floor_crack") else { return }
        triggeredItems.insert("floor_crack")
        
        let crackPath = CGMutablePath()
        let startX = scene.size.width * 0.3
        let y = RoomLayout.floorHeight + 5
        
        crackPath.move(to: CGPoint(x: startX, y: y))
        
        var currentX = startX
        for _ in 0..<8 {
            currentX += CGFloat.random(in: 20...50)
            let yOffset = CGFloat.random(in: -8...8)
            crackPath.addLine(to: CGPoint(x: currentX, y: y + yOffset))
        }
        
        let crack = SKShapeNode(path: crackPath)
        crack.strokeColor = SKColor(red: 0.3, green: 0.25, blue: 0.2, alpha: 0.8)
        crack.lineWidth = 2
        crack.zPosition = -3
        crack.name = "floor_crack"
        crack.alpha = 0
        
        scene.addChild(crack)
        crack.run(SKAction.fadeIn(withDuration: 0.5))
    }
    
    // MARK: - Impact Flash
    
    private func addImpactFlash(at position: CGPoint, in scene: SKScene) {
        let flash = SKSpriteNode(color: .white, size: CGSize(width: 60, height: 60))
        flash.position = position
        flash.zPosition = 25
        flash.alpha = 0.8
        flash.blendMode = .add
        scene.addChild(flash)
        
        flash.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.2),
                SKAction.scale(to: 2.0, duration: 0.2)
            ]),
            SKAction.removeFromParent()
        ]))
    }
    
    // MARK: - Material-Based Particles
    
    private func addMaterialParticles(at position: CGPoint, material: MaterialType, count: Int) {
        guard let scene = scene else { return }
        
        let particleType: ParticleType
        switch material {
        case .glass:
            particleType = .glass
        case .wood:
            particleType = .wood
        case .paper:
            particleType = .paper
        case .ceramic:
            particleType = .ceramic
        default:
            particleType = .dust
        }
        
        let emitter = particlePool.acquireEmitter(type: particleType)
        emitter.position = position
        emitter.zPosition = 20
        emitter.numParticlesToEmit = count
        
        scene.addChild(emitter)
        
        // Return to pool after particles finish
        let wait = SKAction.wait(forDuration: particleType.lifetime + 0.5)
        let release = SKAction.run { [weak self] in
            self?.particlePool.releaseEmitter(emitter)
        }
        scene.run(SKAction.sequence([wait, release]))
    }
    
    // MARK: - Particle Effects
    
    func addDustParticles(in scene: SKScene, intensity: CGFloat) {
        // Use pooled emitters
        let emitter = particlePool.acquireEmitter(type: .dust)
        emitter.particleBirthRate = intensity * 30
        emitter.particlePositionRange = CGVector(dx: scene.size.width, dy: 50)
        emitter.emissionAngle = -.pi / 2
        emitter.emissionAngleRange = .pi / 4
        emitter.position = CGPoint(x: scene.size.width / 2, y: scene.size.height - 30)
        emitter.zPosition = 15
        emitter.name = "dust_emitter"
        
        scene.addChild(emitter)
        
        // Auto-remove after quake
        let wait = SKAction.wait(forDuration: GameTiming.totalQuakeDuration)
        let stopEmitting = SKAction.run { emitter.particleBirthRate = 0 }
        let releaseWait = SKAction.wait(forDuration: 4)
        let release = SKAction.run { [weak self] in
            self?.particlePool.releaseEmitter(emitter)
        }
        
        scene.run(SKAction.sequence([wait, stopEmitting, releaseWait, release]))
        
        // Large dust particles (second emitter)
        let largeEmitter = particlePool.acquireEmitter(type: .dust)
        largeEmitter.particleBirthRate = intensity * 8
        largeEmitter.particleLifetime = 4.0
        largeEmitter.particlePositionRange = CGVector(dx: scene.size.width, dy: 30)
        largeEmitter.particleSpeed = 6
        largeEmitter.particleAlpha = 0.25
        largeEmitter.particleScale = 0.5
        largeEmitter.position = CGPoint(x: scene.size.width / 2, y: scene.size.height - 50)
        largeEmitter.zPosition = 15
        
        scene.addChild(largeEmitter)
        
        scene.run(SKAction.sequence([
            SKAction.wait(forDuration: GameTiming.totalQuakeDuration),
            SKAction.run { largeEmitter.particleBirthRate = 0 },
            SKAction.wait(forDuration: 4),
            SKAction.run { [weak self] in self?.particlePool.releaseEmitter(largeEmitter) }
        ]))
    }
    
    func addImpactParticles(at position: CGPoint, in scene: SKScene, color: SKColor? = nil) {
        let emitter = particlePool.acquireEmitter(type: .dust)
        emitter.particleBirthRate = 80
        emitter.numParticlesToEmit = 20
        emitter.particleLifetime = 0.8
        emitter.particleSpeed = 80
        emitter.particleAlpha = 0.8
        emitter.position = position
        emitter.zPosition = 20
        
        if let color = color {
            emitter.particleColor = color
        }
        
        scene.addChild(emitter)
        
        let wait = SKAction.wait(forDuration: 1.5)
        let release = SKAction.run { [weak self] in
            self?.particlePool.releaseEmitter(emitter)
        }
        scene.run(SKAction.sequence([wait, release]))
    }
    
    // MARK: - Update
    
    func update(deltaTime: TimeInterval, playerPosition: CGPoint) {
        debrisManager?.update(deltaTime: deltaTime)
        
        // Check for damage zones
        let damage = checkPlayerInDamageZones(playerPosition: playerPosition)
        if damage > 0 {
            onPlayerInDamageZone?(damage)
        }
    }
    
    // MARK: - Kick Debris (Enhanced)
    
    func kickDebris(at point: CGPoint, radius: CGFloat = 80, force: CGFloat = 120) {
        debrisManager?.kickDebris(at: point, radius: radius, force: force)
    }
    
    // MARK: - Reset

    func reset() {
        triggeredItems.removeAll()
        windowShattered = false
        crackOverlayAdded = false
        hasLampSparked = false
        physicsJoints.removeAll()
        fallingObjects.removeAll()
        impactZones.removeAll()
        debrisManager?.reset()

        // Remove scattered books
        for book in scatteredBooks {
            book.removeFromParent()
        }
        scatteredBooks.removeAll()
    }

    /// Reset only the triggered items set - call this when a new game starts
    func resetTriggeredItems() {
        triggeredItems.removeAll()
        windowShattered = false
        crackOverlayAdded = false
        hasLampSparked = false
    }
}

// MARK: - Texture Factory Extension

extension TextureFactory {
    static func particleTexture(for type: ParticleType) -> SKTexture? {
        switch type {
        case .dust:
            return dustParticleTexture(size: 4)
        case .sparks:
            return sparkParticleTexture()
        case .glass:
            return glassShardTexture()
        case .wood:
            return woodDebrisTexture()
        case .paper:
            return paperParticleTexture()
        case .ceramic:
            return ceramicParticleTexture()
        }
    }
    
    static func sparkParticleTexture() -> SKTexture {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 3, height: 3), format: format)
        let image = renderer.image { context in
            let ctx = context.cgContext
            ctx.setFillColor(UIColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 1.0).cgColor)
            ctx.fillEllipse(in: CGRect(x: 0, y: 0, width: 3, height: 3))
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }
    
    static func paperParticleTexture() -> SKTexture {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 6, height: 4), format: format)
        let image = renderer.image { context in
            let ctx = context.cgContext
            ctx.setFillColor(UIColor(white: 0.95, alpha: 0.9).cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: 6, height: 4))
            ctx.setStrokeColor(UIColor(white: 0.7, alpha: 0.5).cgColor)
            ctx.setLineWidth(0.5)
            ctx.move(to: CGPoint(x: 1, y: 2))
            ctx.addLine(to: CGPoint(x: 5, y: 2))
            ctx.strokePath()
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }
    
    static func ceramicParticleTexture() -> SKTexture {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4), format: format)
        let image = renderer.image { context in
            let ctx = context.cgContext
            ctx.setFillColor(UIColor(red: 0.82, green: 0.42, blue: 0.22, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }
}
