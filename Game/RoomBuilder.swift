import SpriteKit

@MainActor
enum RoomBuilder {

    // MARK: - Room Types

    enum RoomType: CaseIterable, Hashable, Sendable {
        case livingRoom
        case kitchen
        case office
        case bedroom

        var displayName: String {
            switch self {
            case .livingRoom: return String(localized: "Living Room")
            case .kitchen: return String(localized: "Kitchen")
            case .office: return String(localized: "Office")
            case .bedroom: return String(localized: "Bedroom")
            }
        }

        var safeZoneName: String {
            switch self {
            case .livingRoom: return String(localized: "TABLE")
            case .kitchen: return String(localized: "ISLAND")
            case .office: return String(localized: "DESK")
            case .bedroom: return String(localized: "BED")
            }
        }
    }

    // MARK: - Build Complete Room

    static func buildRoom(type: RoomType, in scene: SKScene, environment: RoomEnvironment? = nil) {
        let size = scene.size

        // Determine environment
        let env = environment ?? RoomEnvironment.curated(for: type)

        // Store environment in scene userData for later reference
        scene.userData = NSMutableDictionary()
        scene.userData?["environment"] = env

        // Common elements for all rooms
        buildWallsAndFloor(in: scene, size: size, type: type, environment: env)
        buildCeilingLamp(in: scene, size: size)
        buildPlayer(in: scene, size: size)
        buildAftershockZones(in: scene, size: size)

        // Room-specific elements
        switch type {
        case .livingRoom:
            buildLivingRoom(in: scene, size: size)
        case .kitchen:
            buildKitchen(in: scene, size: size)
        case .office:
            buildOffice(in: scene, size: size)
        case .bedroom:
            buildBedroom(in: scene, size: size)
        }

        // Apply environment effects (lighting, weather, season)
        RoomEnvironmentBuilder.apply(environment: env, to: scene)
    }

    // Backward compatibility - defaults to living room
    static func buildRoom(in scene: SKScene) {
        buildRoom(type: .livingRoom, in: scene)
    }

    // MARK: - Living Room

    static func buildLivingRoom(in scene: SKScene, size: CGSize) {
        buildDecorations(in: scene, size: size)
        buildTable(in: scene, size: size)
        buildBookshelf(in: scene, size: size)
        buildWindow(in: scene, size: size)
        buildDoor(in: scene, size: size)
        buildLivingRoomDebris(in: scene, size: size)
    }

    // MARK: - Kitchen

    static func buildKitchen(in scene: SKScene, size: CGSize) {
        // Kitchen island (safe zone - sturdy)
        buildKitchenIsland(in: scene, size: size)

        // Refrigerator (danger - can tip)
        buildRefrigerator(in: scene, size: size)

        // Cabinets (objects fall from above)
        buildKitchenCabinets(in: scene, size: size)

        // Stove (special: gas leak danger after quake)
        buildStove(in: scene, size: size)

        // Hanging pots/pans (fall first)
        buildHangingPots(in: scene, size: size)

        // Microwave on counter
        buildMicrowave(in: scene, size: size)

        // Window and door
        buildWindow(in: scene, size: size, xOffset: size.width - 200)
        buildDoor(in: scene, size: size)

        // Kitchen decorations
        buildKitchenDecorations(in: scene, size: size)

        // Breakable items
        buildKitchenDebris(in: scene, size: size)
    }

    // MARK: - Office

    static func buildOffice(in scene: SKScene, size: CGSize) {
        // Large desk (safe zone)
        buildOfficeDesk(in: scene, size: size)

        // Office chair (rolls away)
        buildOfficeChair(in: scene, size: size)

        // Bookshelves (2 smaller ones)
        buildOfficeBookshelves(in: scene, size: size)

        // Filing cabinet (danger)
        buildFilingCabinet(in: scene, size: size)

        // Whiteboard on wall
        buildWhiteboard(in: scene, size: size)

        // Window with blinds
        buildWindowWithBlinds(in: scene, size: size)

        // Door
        buildDoor(in: scene, size: size)

        // Office decorations
        buildOfficeDecorations(in: scene, size: size)

        // Breakable items
        buildOfficeDebris(in: scene, size: size)
    }

    // MARK: - Bedroom

    static func buildBedroom(in scene: SKScene, size: CGSize) {
        // Bed (safe zone - get under it)
        buildBed(in: scene, size: size)

        // Wardrobe (danger - tall furniture)
        buildWardrobe(in: scene, size: size)

        // Nightstands
        buildNightstands(in: scene, size: size)

        // Window with curtains
        buildWindowWithCurtains(in: scene, size: size)

        // Door
        buildDoor(in: scene, size: size)

        // Rug
        buildBedroomRug(in: scene, size: size)

        // Bedroom decorations
        buildBedroomDecorations(in: scene, size: size)

        // Breakable items
        buildBedroomDebris(in: scene, size: size)
    }

    // MARK: - Walls and Floor

    static func buildWallsAndFloor(
        in scene: SKScene, size: CGSize, type: RoomType, environment: RoomEnvironment? = nil
    ) {
        _ = environment ?? RoomEnvironment.default

        // Back wall with environment color
        let wallColor =
            environment?.timeOfDay.wallColor
            ?? SKColor(red: 0.95, green: 0.93, blue: 0.90, alpha: 1)

        // Add solid color background first (fallback if texture fails)
        let solidWall = SKSpriteNode(color: wallColor, size: size)
        solidWall.position = CGPoint(x: size.width / 2, y: size.height / 2)
        solidWall.zPosition = -11
        solidWall.name = "wall_solid"
        scene.addChild(solidWall)

        // Determine wall pattern based on room type
        let wallPattern: TextureFactory.WallPattern
        switch type {
        case .livingRoom: wallPattern = .stars
        case .kitchen: wallPattern = .stripes
        case .office: wallPattern = .plain
        case .bedroom: wallPattern = .polka
        }

        // Then add textured wall on top
        let wallTex = TextureFactory.wallTexture(
            size: size, pattern: wallPattern, baseColor: wallColor)
        let wall = SKSpriteNode(texture: wallTex, size: size)
        wall.position = CGPoint(x: size.width / 2, y: size.height / 2)
        wall.zPosition = -10
        wall.name = "wall"
        scene.addChild(wall)

        // Floor with environment color
        let floorColor =
            environment?.timeOfDay.floorColor
            ?? SKColor(red: 0.82, green: 0.72, blue: 0.60, alpha: 1)

        // Add solid color floor background first (fallback if texture fails)
        let solidFloor = SKSpriteNode(
            color: floorColor, size: CGSize(width: size.width, height: RoomLayout.floorHeight))
        solidFloor.position = CGPoint(x: size.width / 2, y: RoomLayout.floorHeight / 2)
        solidFloor.zPosition = -6
        solidFloor.name = "floor_solid"
        scene.addChild(solidFloor)

        // Determine floor type based on room
        let floorType: TextureFactory.FloorType
        switch type {
        case .livingRoom, .office: floorType = .wood
        case .kitchen: floorType = .tile
        case .bedroom: floorType = .carpet
        }

        // Then add textured floor on top
        let floorTex = TextureFactory.floorTexture(
            width: size.width, height: RoomLayout.floorHeight, type: floorType,
            baseColor: floorColor)
        let floor = SKSpriteNode(
            texture: floorTex, size: CGSize(width: size.width, height: RoomLayout.floorHeight))
        floor.position = CGPoint(x: size.width / 2, y: RoomLayout.floorHeight / 2)
        floor.zPosition = -5
        floor.name = "floor"
        floor.physicsBody = SKPhysicsBody(rectangleOf: floor.size)
        floor.physicsBody?.isDynamic = false
        floor.physicsBody?.categoryBitMask = PhysicsCategory.floor
        floor.physicsBody?.friction = 0.8
        scene.addChild(floor)

        // Baseboard
        let bbTex = TextureFactory.baseboardTexture(width: size.width, height: 12)
        let baseboard = SKSpriteNode(texture: bbTex, size: CGSize(width: size.width, height: 12))
        baseboard.position = CGPoint(x: size.width / 2, y: RoomLayout.floorHeight + 6)
        baseboard.zPosition = -4
        scene.addChild(baseboard)

        // Ceiling line
        let ceiling = SKSpriteNode(
            color: SKColor(red: 0.75, green: 0.72, blue: 0.68, alpha: 1),
            size: CGSize(width: size.width, height: 8))
        ceiling.position = CGPoint(x: size.width / 2, y: size.height - 4)
        ceiling.zPosition = -4
        scene.addChild(ceiling)
    }

    // MARK: - Living Room Elements

    static func buildDecorations(in scene: SKScene, size: CGSize) {
        // Area rug on the floor, centered near table area
        let rugW: CGFloat = 200
        let rugH: CGFloat = 50
        let rugTex = TextureFactory.rugTexture(width: rugW, height: rugH)
        let rug = SKSpriteNode(texture: rugTex, size: CGSize(width: rugW, height: rugH))
        rug.position = CGPoint(x: size.width / 2, y: RoomLayout.floorHeight + rugH / 2 + 2)
        rug.zPosition = -3
        rug.name = "rug"
        scene.addChild(rug)

        // Potted plant to the left of the bookshelf
        let plantW: CGFloat = 35
        let plantH: CGFloat = 60
        let plantTex = TextureFactory.pottedPlantTexture(width: plantW, height: plantH)
        let plant = SKSpriteNode(texture: plantTex, size: CGSize(width: plantW, height: plantH))
        plant.position = CGPoint(x: size.width - 155, y: RoomLayout.floorHeight + plantH / 2)
        plant.zPosition = 2
        plant.name = "potted_plant"
        scene.addChild(plant)

        // Safety poster on the back wall
        let posterW: CGFloat = 70
        let posterH: CGFloat = 90
        let posterTex = TextureFactory.wallPosterTexture(width: posterW, height: posterH)
        let poster = SKSpriteNode(texture: posterTex, size: CGSize(width: posterW, height: posterH))
        poster.position = CGPoint(x: 220, y: size.height - 200)
        poster.zPosition = 1
        poster.name = "wall_poster"
        scene.addChild(poster)

        // Cork board on wall
        let corkW: CGFloat = 80
        let corkH: CGFloat = 55
        let corkTex = TextureFactory.corkBoardTexture(width: corkW, height: corkH)
        let cork = SKSpriteNode(texture: corkTex, size: CGSize(width: corkW, height: corkH))
        cork.position = CGPoint(x: size.width - 200, y: size.height - 180)
        cork.zPosition = 1
        cork.name = "cork_board"
        scene.addChild(cork)

        // Small wall shelf above the door area
        let shelfW: CGFloat = 60
        let shelfH: CGFloat = 45
        let shelfTex = TextureFactory.wallShelfTexture(width: shelfW, height: shelfH)
        let shelf = SKSpriteNode(texture: shelfTex, size: CGSize(width: shelfW, height: shelfH))
        shelf.position = CGPoint(x: 70, y: RoomLayout.floorHeight + RoomLayout.doorHeight + 50)
        shelf.zPosition = 1
        shelf.name = "wall_shelf"
        scene.addChild(shelf)
    }

    static func buildLivingRoomDebris(in scene: SKScene, size: CGSize) {
        // Picture frame 1
        let frame1Tex = TextureFactory.pictureFrameTexture(width: 50, height: 40, pictureHue: 0.35)
        let frame1 = SKSpriteNode(texture: frame1Tex, size: CGSize(width: 50, height: 40))
        frame1.position = CGPoint(x: size.width / 2 - 150, y: size.height - 180)
        frame1.zPosition = 2
        frame1.name = "picture_frame_1"
        frame1.physicsBody = SKPhysicsBody(rectangleOf: frame1.size)
        frame1.physicsBody?.isDynamic = false
        frame1.physicsBody?.categoryBitMask = PhysicsCategory.debris
        frame1.physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.floor
        frame1.physicsBody?.mass = 0.3
        scene.addChild(frame1)

        // Picture frame 2
        let frame2Tex = TextureFactory.pictureFrameTexture(width: 45, height: 55, pictureHue: 0.1)
        let frame2 = SKSpriteNode(texture: frame2Tex, size: CGSize(width: 45, height: 55))
        frame2.position = CGPoint(x: size.width / 2 + 100, y: size.height - 150)
        frame2.zPosition = 2
        frame2.name = "picture_frame_2"
        frame2.physicsBody = SKPhysicsBody(rectangleOf: frame2.size)
        frame2.physicsBody?.isDynamic = false
        frame2.physicsBody?.categoryBitMask = PhysicsCategory.debris
        frame2.physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.floor
        frame2.physicsBody?.mass = 0.3
        scene.addChild(frame2)

        // Vase (on the table)
        let tableTopY = RoomLayout.floorHeight + RoomLayout.tableHeight
        let vaseTex = TextureFactory.vaseTexture(width: 20, height: 35)
        let vase = SKSpriteNode(texture: vaseTex, size: CGSize(width: 20, height: 35))
        vase.position = CGPoint(x: size.width / 2 + 40, y: tableTopY + 35 / 2)
        vase.zPosition = 3
        vase.name = "vase"
        vase.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 20, height: 35))
        vase.physicsBody?.isDynamic = false
        vase.physicsBody?.categoryBitMask = PhysicsCategory.debris
        vase.physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.floor
        vase.physicsBody?.mass = 0.2
        scene.addChild(vase)

        // Clock
        let clockTex = TextureFactory.clockTexture(radius: 22)
        let clock = SKSpriteNode(texture: clockTex, size: CGSize(width: 44, height: 44))
        clock.position = CGPoint(x: size.width / 2 + 200, y: size.height - 120)
        clock.zPosition = 2
        clock.name = "clock"
        clock.physicsBody = SKPhysicsBody(circleOfRadius: 22)
        clock.physicsBody?.isDynamic = false
        clock.physicsBody?.categoryBitMask = PhysicsCategory.debris
        clock.physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.floor
        clock.physicsBody?.mass = 0.3
        scene.addChild(clock)
    }

    // MARK: - Table (Safe Zone) - Living Room

    static func buildTable(in scene: SKScene, size: CGSize) {
        let tableW = RoomLayout.tableWidth
        let tableH = RoomLayout.tableHeight
        let tableY = RoomLayout.floorHeight + tableH / 2

        // Table top
        let topTex = TextureFactory.tableTopTexture(width: tableW, height: 12)
        let tableTop = SKSpriteNode(texture: topTex, size: CGSize(width: tableW, height: 12))
        tableTop.position = CGPoint(x: size.width / 2, y: tableY + tableH / 2 - 6)
        tableTop.zPosition = 2
        tableTop.name = "table_top"
        scene.addChild(tableTop)

        // Table legs
        let legTex = TextureFactory.tableLegTexture(width: 8, height: tableH - 12)
        for xOffset in [-tableW / 2 + 10, tableW / 2 - 10] {
            let leg = SKSpriteNode(texture: legTex, size: CGSize(width: 8, height: tableH - 12))
            leg.position = CGPoint(x: size.width / 2 + xOffset, y: tableY - 6)
            leg.zPosition = 1
            scene.addChild(leg)
        }

        // Safe zone (invisible, for collision detection)
        let safeZone = SKSpriteNode(
            color: .clear, size: CGSize(width: tableW - 20, height: tableH - 15))
        safeZone.position = CGPoint(x: size.width / 2, y: tableY - 6)
        safeZone.zPosition = 0
        safeZone.name = "table"
        safeZone.physicsBody = SKPhysicsBody(rectangleOf: safeZone.size)
        safeZone.physicsBody?.isDynamic = false
        safeZone.physicsBody?.categoryBitMask = PhysicsCategory.safeZone
        safeZone.physicsBody?.contactTestBitMask = PhysicsCategory.player
        scene.addChild(safeZone)

        // Label
        let label = SKLabelNode(text: "TABLE")
        label.fontSize = DynamicTypeScale.scaled(14)
        label.fontColor = HighContrast.zoneLabelColor
        label.fontName = "Helvetica-Bold"
        label.position = CGPoint(x: size.width / 2, y: tableY + tableH / 2 + 10)
        label.zPosition = 3
        label.name = "table_label"
        scene.addChild(label)
    }

    // MARK: - Bookshelf (Danger) - Living Room

    static func buildBookshelf(in scene: SKScene, size: CGSize) {
        let shelfX = size.width - 100
        let shelfY = RoomLayout.floorHeight + RoomLayout.bookshelfHeight / 2

        let shelfTex = TextureFactory.bookshelfTexture(
            width: RoomLayout.bookshelfWidth, height: RoomLayout.bookshelfHeight)
        let shelf = SKSpriteNode(
            texture: shelfTex,
            size: CGSize(width: RoomLayout.bookshelfWidth, height: RoomLayout.bookshelfHeight))
        shelf.position = CGPoint(x: shelfX, y: shelfY)
        shelf.zPosition = 2
        shelf.name = "bookshelf"
        shelf.physicsBody = SKPhysicsBody(rectangleOf: shelf.size)
        shelf.physicsBody?.isDynamic = false
        shelf.physicsBody?.categoryBitMask = PhysicsCategory.furniture
        shelf.physicsBody?.contactTestBitMask = PhysicsCategory.player
        shelf.physicsBody?.mass = 5.0
        scene.addChild(shelf)

        // Danger zone around bookshelf
        let dangerZone = SKSpriteNode(
            color: .clear,
            size: CGSize(
                width: RoomLayout.bookshelfWidth + 60, height: RoomLayout.bookshelfHeight + 20))
        dangerZone.position = CGPoint(x: shelfX, y: shelfY)
        dangerZone.zPosition = 0
        dangerZone.name = "bookshelf_zone"
        dangerZone.physicsBody = SKPhysicsBody(rectangleOf: dangerZone.size)
        dangerZone.physicsBody?.isDynamic = false
        dangerZone.physicsBody?.categoryBitMask = PhysicsCategory.dangerZone
        dangerZone.physicsBody?.contactTestBitMask = PhysicsCategory.player
        scene.addChild(dangerZone)
    }

    // MARK: - Window

    static func buildWindow(in scene: SKScene, size: CGSize, xOffset: CGFloat? = nil) {
        let winX = xOffset ?? (size.width - 250)
        let winY = RoomLayout.floorHeight + 200

        let winTex = TextureFactory.windowTexture(
            width: RoomLayout.windowWidth, height: RoomLayout.windowHeight)
        let window = SKSpriteNode(
            texture: winTex,
            size: CGSize(width: RoomLayout.windowWidth, height: RoomLayout.windowHeight))
        window.position = CGPoint(x: winX, y: winY)
        window.zPosition = 2
        window.name = "window"
        window.physicsBody = SKPhysicsBody(rectangleOf: window.size)
        window.physicsBody?.isDynamic = false
        window.physicsBody?.categoryBitMask = PhysicsCategory.dangerZone
        window.physicsBody?.contactTestBitMask = PhysicsCategory.player
        scene.addChild(window)
    }

    // MARK: - Door

    static func buildDoor(in scene: SKScene, size: CGSize) {
        let doorX = CGFloat(70)
        let doorY = RoomLayout.floorHeight + RoomLayout.doorHeight / 2

        let doorTex = TextureFactory.doorTexture(
            width: RoomLayout.doorWidth, height: RoomLayout.doorHeight)
        let door = SKSpriteNode(
            texture: doorTex,
            size: CGSize(width: RoomLayout.doorWidth, height: RoomLayout.doorHeight))
        door.position = CGPoint(x: doorX, y: doorY)
        door.zPosition = 2
        door.name = "door"
        door.physicsBody = SKPhysicsBody(rectangleOf: door.size)
        door.physicsBody?.isDynamic = false
        door.physicsBody?.categoryBitMask = PhysicsCategory.dangerZone
        door.physicsBody?.contactTestBitMask = PhysicsCategory.player
        scene.addChild(door)
    }

    // MARK: - Ceiling Lamp

    static func buildCeilingLamp(in scene: SKScene, size: CGSize) {
        let lampX = size.width / 2
        let lampY = size.height - 50

        // Cord
        let cord = SKSpriteNode(
            color: SKColor(white: 0.3, alpha: 1), size: CGSize(width: 2, height: 40))
        cord.position = CGPoint(x: lampX, y: lampY + 20)
        cord.zPosition = 4
        cord.name = "lamp_cord"
        scene.addChild(cord)

        // Lamp shade
        let lampTex = TextureFactory.lampTexture(width: RoomLayout.lampSize, height: 20)
        let lamp = SKSpriteNode(
            texture: lampTex, size: CGSize(width: RoomLayout.lampSize, height: 20))
        lamp.position = CGPoint(x: lampX, y: lampY)
        lamp.zPosition = 5
        lamp.name = "lamp"
        lamp.physicsBody = SKPhysicsBody(
            rectangleOf: CGSize(width: RoomLayout.lampSize, height: 20))
        lamp.physicsBody?.isDynamic = false
        lamp.physicsBody?.categoryBitMask = PhysicsCategory.debris
        lamp.physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.floor
        lamp.physicsBody?.mass = 0.5
        scene.addChild(lamp)

        // Warm glow
        let glowTex = TextureFactory.lampGlowTexture(radius: 40)
        let glow = SKSpriteNode(texture: glowTex, size: CGSize(width: 80, height: 80))
        glow.position = CGPoint(x: lampX, y: lampY - 20)
        glow.zPosition = 4
        glow.name = "lamp_glow"
        glow.blendMode = .add
        scene.addChild(glow)

        // Gentle sway animation for calm phase
        let swayRight = SKAction.rotate(toAngle: 0.03, duration: 1.5)
        swayRight.timingMode = .easeInEaseOut
        let swayLeft = SKAction.rotate(toAngle: -0.03, duration: 1.5)
        swayLeft.timingMode = .easeInEaseOut
        lamp.run(SKAction.repeatForever(SKAction.sequence([swayRight, swayLeft])), withKey: "sway")

        // Flicker animation (starts paused, activated during earthquake)
        let flickerSequence = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.6, duration: 0.05),
            SKAction.fadeAlpha(to: 1.0, duration: 0.05),
            SKAction.wait(forDuration: 0.1),
            SKAction.fadeAlpha(to: 0.7, duration: 0.03),
            SKAction.fadeAlpha(to: 1.0, duration: 0.07),
            SKAction.wait(forDuration: 0.15),
            SKAction.fadeAlpha(to: 0.5, duration: 0.04),
            SKAction.fadeAlpha(to: 0.9, duration: 0.06),
        ])
        glow.run(SKAction.repeatForever(flickerSequence), withKey: "flicker")
        // Pause flicker initially (will be resumed during earthquake)
        if let flickerAction = glow.action(forKey: "flicker") {
            flickerAction.speed = 0
        }
    }

    // MARK: - Kitchen Elements

    static func buildKitchenIsland(in scene: SKScene, size: CGSize) {
        let islandW: CGFloat = 200
        let islandH: CGFloat = 95
        let islandY = RoomLayout.floorHeight + islandH / 2

        // Island countertop
        let topTex = TextureFactory.kitchenCounterTexture(
            width: islandW, height: 15, colorType: .island)
        let counterTop = SKSpriteNode(texture: topTex, size: CGSize(width: islandW, height: 15))
        counterTop.position = CGPoint(x: size.width / 2, y: islandY + islandH / 2 - 7)
        counterTop.zPosition = 2
        counterTop.name = "island_top"
        scene.addChild(counterTop)

        // Island base cabinets
        let baseTex = TextureFactory.cabinetTexture(
            width: islandW - 20, height: islandH - 15, type: .base)
        let base = SKSpriteNode(
            texture: baseTex, size: CGSize(width: islandW - 20, height: islandH - 15))
        base.position = CGPoint(x: size.width / 2, y: islandY - 7)
        base.zPosition = 1
        base.name = "island_base"
        scene.addChild(base)

        // Safe zone under island
        let safeZone = SKSpriteNode(
            color: .clear, size: CGSize(width: islandW - 30, height: islandH - 20))
        safeZone.position = CGPoint(x: size.width / 2, y: islandY - 5)
        safeZone.zPosition = 0
        safeZone.name = "kitchen_island"
        safeZone.physicsBody = SKPhysicsBody(rectangleOf: safeZone.size)
        safeZone.physicsBody?.isDynamic = false
        safeZone.physicsBody?.categoryBitMask = PhysicsCategory.safeZone
        safeZone.physicsBody?.contactTestBitMask = PhysicsCategory.player
        scene.addChild(safeZone)

        // Label
        let label = SKLabelNode(text: "ISLAND")
        label.fontSize = DynamicTypeScale.scaled(14)
        label.fontColor = HighContrast.zoneLabelColor
        label.fontName = "Helvetica-Bold"
        label.position = CGPoint(x: size.width / 2, y: islandY + islandH / 2 + 10)
        label.zPosition = 3
        label.name = "island_label"
        scene.addChild(label)
    }

    static func buildRefrigerator(in scene: SKScene, size: CGSize) {
        let fridgeW: CGFloat = 70
        let fridgeH: CGFloat = 180
        let fridgeX = size.width - 90
        let fridgeY = RoomLayout.floorHeight + fridgeH / 2

        let fridgeTex = TextureFactory.refrigeratorTexture(width: fridgeW, height: fridgeH)
        let fridge = SKSpriteNode(texture: fridgeTex, size: CGSize(width: fridgeW, height: fridgeH))
        fridge.position = CGPoint(x: fridgeX, y: fridgeY)
        fridge.zPosition = 2
        fridge.name = "refrigerator"
        fridge.physicsBody = SKPhysicsBody(rectangleOf: fridge.size)
        fridge.physicsBody?.isDynamic = false
        fridge.physicsBody?.categoryBitMask = PhysicsCategory.furniture
        fridge.physicsBody?.contactTestBitMask = PhysicsCategory.player
        fridge.physicsBody?.mass = 8.0
        scene.addChild(fridge)

        // Danger zone (refrigerator can tip)
        let dangerZone = SKSpriteNode(
            color: .clear, size: CGSize(width: fridgeW + 50, height: fridgeH + 30))
        dangerZone.position = CGPoint(x: fridgeX, y: fridgeY)
        dangerZone.zPosition = 0
        dangerZone.name = "refrigerator_zone"
        dangerZone.physicsBody = SKPhysicsBody(rectangleOf: dangerZone.size)
        dangerZone.physicsBody?.isDynamic = false
        dangerZone.physicsBody?.categoryBitMask = PhysicsCategory.dangerZone
        dangerZone.physicsBody?.contactTestBitMask = PhysicsCategory.player
        scene.addChild(dangerZone)

        // Fridge magnets (fall during quake)
        let magnetColors: [SKColor] = [.red, .blue, .green, .yellow, .orange]
        for i in 0..<5 {
            let magnetSize: CGFloat = 8
            let magnet = SKSpriteNode(
                color: magnetColors[i], size: CGSize(width: magnetSize, height: magnetSize))
            let magX = fridgeX - fridgeW / 3 + CGFloat(i) * 12
            let magY = fridgeY + fridgeH / 4 + CGFloat(i % 2) * 15
            magnet.position = CGPoint(x: magX, y: magY)
            magnet.zPosition = 3
            magnet.name = "fridge_magnet_\(i)"
            magnet.physicsBody = SKPhysicsBody(rectangleOf: magnet.size)
            magnet.physicsBody?.isDynamic = false
            magnet.physicsBody?.categoryBitMask = PhysicsCategory.debris
            magnet.physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.floor
            magnet.physicsBody?.mass = 0.05
            scene.addChild(magnet)
        }
    }

    static func buildKitchenCabinets(in scene: SKScene, size: CGSize) {
        // Upper cabinets
        let cabinetW: CGFloat = 80
        let cabinetH: CGFloat = 70
        let startY = size.height - 100

        for i in 0..<3 {
            let cabX = CGFloat(150 + i * 90)
            let cabTex = TextureFactory.cabinetTexture(
                width: cabinetW, height: cabinetH, type: .wall)
            let cabinet = SKSpriteNode(
                texture: cabTex, size: CGSize(width: cabinetW, height: cabinetH))
            cabinet.position = CGPoint(x: cabX, y: startY)
            cabinet.zPosition = 2
            cabinet.name = "upper_cabinet_\(i)"
            cabinet.physicsBody = SKPhysicsBody(rectangleOf: cabinet.size)
            cabinet.physicsBody?.isDynamic = false
            cabinet.physicsBody?.categoryBitMask = PhysicsCategory.furniture
            cabinet.physicsBody?.contactTestBitMask = PhysicsCategory.player
            cabinet.physicsBody?.mass = 4.0
            scene.addChild(cabinet)

            // Danger zone (objects can fall from cabinets)
            let dangerZone = SKSpriteNode(
                color: .clear, size: CGSize(width: cabinetW + 20, height: cabinetH + 40))
            dangerZone.position = CGPoint(x: cabX, y: startY - 20)
            dangerZone.zPosition = 0
            dangerZone.name = "cabinet_zone_\(i)"
            dangerZone.physicsBody = SKPhysicsBody(rectangleOf: dangerZone.size)
            dangerZone.physicsBody?.isDynamic = false
            dangerZone.physicsBody?.categoryBitMask = PhysicsCategory.dangerZone
            dangerZone.physicsBody?.contactTestBitMask = PhysicsCategory.player
            scene.addChild(dangerZone)
        }
    }

    static func buildStove(in scene: SKScene, size: CGSize) {
        let stoveW: CGFloat = 75
        let stoveH: CGFloat = 85
        let stoveX = size.width - 180
        let stoveY = RoomLayout.floorHeight + stoveH / 2

        let stoveTex = TextureFactory.stoveTexture(width: stoveW, height: stoveH)
        let stove = SKSpriteNode(texture: stoveTex, size: CGSize(width: stoveW, height: stoveH))
        stove.position = CGPoint(x: stoveX, y: stoveY)
        stove.zPosition = 2
        stove.name = "stove"
        stove.physicsBody = SKPhysicsBody(rectangleOf: stove.size)
        stove.physicsBody?.isDynamic = false
        stove.physicsBody?.categoryBitMask = PhysicsCategory.furniture
        stove.physicsBody?.contactTestBitMask = PhysicsCategory.player
        stove.physicsBody?.mass = 6.0
        scene.addChild(stove)

        // Gas leak danger zone (special hazard after quake)
        let gasZone = SKSpriteNode(
            color: .clear, size: CGSize(width: stoveW + 40, height: stoveH + 30))
        gasZone.position = CGPoint(x: stoveX, y: stoveY)
        gasZone.zPosition = 0
        gasZone.name = "stove_gas_zone"
        gasZone.physicsBody = SKPhysicsBody(rectangleOf: gasZone.size)
        gasZone.physicsBody?.isDynamic = false
        gasZone.physicsBody?.categoryBitMask = PhysicsCategory.dangerZone
        gasZone.physicsBody?.contactTestBitMask = PhysicsCategory.player
        scene.addChild(gasZone)

        // Gas valve icon (hidden, shows after quake)
        let valveTex = TextureFactory.gasValveIcon()
        let valve = SKSpriteNode(texture: valveTex, size: CGSize(width: 30, height: 30))
        valve.position = CGPoint(x: stoveX, y: stoveY + stoveH / 2 + 20)
        valve.zPosition = 8
        valve.name = "kitchen_gas_valve"
        valve.alpha = 0
        scene.addChild(valve)
    }

    static func buildHangingPots(in scene: SKScene, size: CGSize) {
        // Hanging pot rack
        let rackW: CGFloat = 150
        let rackH: CGFloat = 8
        let rackX = size.width / 2
        let rackY = size.height - 120

        let rack = SKSpriteNode(
            color: CartoonPalette.furnitureDark.skColor, size: CGSize(width: rackW, height: rackH))
        rack.position = CGPoint(x: rackX, y: rackY)
        rack.zPosition = 3
        rack.name = "pot_rack"
        scene.addChild(rack)

        // Hanging pots/pans
        let potPositions: [CGFloat] = [-50, -15, 20, 55]
        for (i, xOffset) in potPositions.enumerated() {
            let potSize: CGFloat = 18 + CGFloat(i % 2) * 6
            let potTex = TextureFactory.hangingPotTexture(radius: potSize / 2)
            let pot = SKSpriteNode(texture: potTex, size: CGSize(width: potSize, height: potSize))
            pot.position = CGPoint(x: rackX + xOffset, y: rackY - 25)
            pot.zPosition = 4
            pot.name = "hanging_pot_\(i)"
            pot.physicsBody = SKPhysicsBody(circleOfRadius: potSize / 2)
            pot.physicsBody?.isDynamic = false
            pot.physicsBody?.categoryBitMask = PhysicsCategory.debris
            pot.physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.floor
            pot.physicsBody?.mass = 0.4
            scene.addChild(pot)

            // Chain/cord connecting pot to rack
            let chain = SKSpriteNode(
                color: SKColor(white: 0.5, alpha: 1), size: CGSize(width: 1, height: 20))
            chain.position = CGPoint(x: rackX + xOffset, y: rackY - 10)
            chain.zPosition = 3
            chain.name = "pot_chain_\(i)"
            scene.addChild(chain)
        }
    }

    static func buildMicrowave(in scene: SKScene, size: CGSize) {
        let microW: CGFloat = 55
        let microH: CGFloat = 35
        let microX = size.width - 280
        let microY = RoomLayout.floorHeight + 95

        let microTex = TextureFactory.microwaveTexture(width: microW, height: microH)
        let microwave = SKSpriteNode(texture: microTex, size: CGSize(width: microW, height: microH))
        microwave.position = CGPoint(x: microX, y: microY)
        microwave.zPosition = 3
        microwave.name = "microwave"
        microwave.physicsBody = SKPhysicsBody(rectangleOf: microwave.size)
        microwave.physicsBody?.isDynamic = false
        microwave.physicsBody?.categoryBitMask = PhysicsCategory.debris
        microwave.physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.floor
        microwave.physicsBody?.mass = 0.8
        scene.addChild(microwave)
    }

    static func buildKitchenDecorations(in scene: SKScene, size: CGSize) {
        // Kitchen rug
        let rugW: CGFloat = 120
        let rugH: CGFloat = 80
        let rugTex = TextureFactory.kitchenRugTexture(width: rugW, height: rugH)
        let rug = SKSpriteNode(texture: rugTex, size: CGSize(width: rugW, height: rugH))
        rug.position = CGPoint(x: size.width - 140, y: RoomLayout.floorHeight + rugH / 2)
        rug.zPosition = -3
        rug.name = "kitchen_rug"
        scene.addChild(rug)

        // Fruit bowl on island
        let bowlTex = TextureFactory.bowlTexture(width: 30, height: 12)
        let bowl = SKSpriteNode(texture: bowlTex, size: CGSize(width: 30, height: 12))
        bowl.position = CGPoint(x: size.width / 2, y: RoomLayout.floorHeight + 95)
        bowl.zPosition = 4
        bowl.name = "fruit_bowl"
        scene.addChild(bowl)
    }

    static func buildKitchenDebris(in scene: SKScene, size: CGSize) {
        // Plates in upper cabinets (potential falling debris)
        let platePositions = [
            CGPoint(x: 150, y: size.height - 140),
            CGPoint(x: 240, y: size.height - 135),
            CGPoint(x: 330, y: size.height - 140),
        ]

        for (i, pos) in platePositions.enumerated() {
            let plateTex = TextureFactory.plateTexture(radius: 12)
            let plate = SKSpriteNode(texture: plateTex, size: CGSize(width: 24, height: 24))
            plate.position = pos
            plate.zPosition = 3
            plate.name = "plate_\(i)"
            plate.physicsBody = SKPhysicsBody(circleOfRadius: 12)
            plate.physicsBody?.isDynamic = false
            plate.physicsBody?.categoryBitMask = PhysicsCategory.debris
            plate.physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.floor
            plate.physicsBody?.mass = 0.15
            scene.addChild(plate)
        }

        // Glasses on counter
        let glassPositions = [
            CGPoint(x: size.width - 230, y: RoomLayout.floorHeight + 100),
            CGPoint(x: size.width - 210, y: RoomLayout.floorHeight + 98),
        ]

        for (i, pos) in glassPositions.enumerated() {
            let glassTex = TextureFactory.glassTexture(width: 10, height: 14)
            let glass = SKSpriteNode(texture: glassTex, size: CGSize(width: 10, height: 14))
            glass.position = pos
            glass.zPosition = 4
            glass.name = "glass_\(i)"
            glass.physicsBody = SKPhysicsBody(rectangleOf: glass.size)
            glass.physicsBody?.isDynamic = false
            glass.physicsBody?.categoryBitMask = PhysicsCategory.debris
            glass.physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.floor
            glass.physicsBody?.mass = 0.1
            scene.addChild(glass)
        }
    }

    // MARK: - Office Elements

    static func buildOfficeDesk(in scene: SKScene, size: CGSize) {
        let deskW: CGFloat = 180
        let deskH: CGFloat = 85
        let deskY = RoomLayout.floorHeight + deskH / 2

        // Desk top
        let topTex = TextureFactory.deskTexture(width: deskW, height: 12)
        let deskTop = SKSpriteNode(texture: topTex, size: CGSize(width: deskW, height: 12))
        deskTop.position = CGPoint(x: size.width / 2, y: deskY + deskH / 2 - 6)
        deskTop.zPosition = 2
        deskTop.name = "desk_top"
        scene.addChild(deskTop)

        // Desk legs
        let legTex = TextureFactory.tableLegTexture(width: 8, height: deskH - 12)
        for xOffset in [-deskW / 2 + 15, deskW / 2 - 15] {
            let leg = SKSpriteNode(texture: legTex, size: CGSize(width: 8, height: deskH - 12))
            leg.position = CGPoint(x: size.width / 2 + xOffset, y: deskY - 6)
            leg.zPosition = 1
            scene.addChild(leg)
        }

        // Desk drawers
        let drawerTex = TextureFactory.filingCabinetTexture(
            width: 50, height: deskH - 15, drawers: 2)
        let drawers = SKSpriteNode(texture: drawerTex, size: CGSize(width: 50, height: deskH - 15))
        drawers.position = CGPoint(x: size.width / 2 + deskW / 2 - 35, y: deskY - 7)
        drawers.zPosition = 1
        drawers.name = "desk_drawers"
        scene.addChild(drawers)

        // Safe zone under desk
        let safeZone = SKSpriteNode(
            color: .clear, size: CGSize(width: deskW - 20, height: deskH - 15))
        safeZone.position = CGPoint(x: size.width / 2, y: deskY - 6)
        safeZone.zPosition = 0
        safeZone.name = "desk"
        safeZone.physicsBody = SKPhysicsBody(rectangleOf: safeZone.size)
        safeZone.physicsBody?.isDynamic = false
        safeZone.physicsBody?.categoryBitMask = PhysicsCategory.safeZone
        safeZone.physicsBody?.contactTestBitMask = PhysicsCategory.player
        scene.addChild(safeZone)

        // Label
        let label = SKLabelNode(text: "DESK")
        label.fontSize = DynamicTypeScale.scaled(14)
        label.fontColor = HighContrast.zoneLabelColor
        label.fontName = "Helvetica-Bold"
        label.position = CGPoint(x: size.width / 2, y: deskY + deskH / 2 + 10)
        label.zPosition = 3
        label.name = "desk_label"
        scene.addChild(label)
    }

    static func buildOfficeChair(in scene: SKScene, size: CGSize) {
        let chairX = size.width / 2
        let chairY = RoomLayout.floorHeight + 35

        let chairTex = TextureFactory.officeChairTexture(width: 50, height: 65)
        let chair = SKSpriteNode(texture: chairTex, size: CGSize(width: 50, height: 65))
        chair.position = CGPoint(x: chairX, y: chairY)
        chair.zPosition = 2
        chair.name = "office_chair"
        chair.physicsBody = SKPhysicsBody(rectangleOf: chair.size)
        chair.physicsBody?.isDynamic = false
        chair.physicsBody?.categoryBitMask = PhysicsCategory.furniture
        chair.physicsBody?.contactTestBitMask = PhysicsCategory.player
        chair.physicsBody?.mass = 1.5
        scene.addChild(chair)

        // Chair danger zone (rolls away during quake)
        let dangerZone = SKSpriteNode(color: .clear, size: CGSize(width: 80, height: 80))
        dangerZone.position = CGPoint(x: chairX, y: chairY)
        dangerZone.zPosition = 0
        dangerZone.name = "chair_zone"
        dangerZone.physicsBody = SKPhysicsBody(rectangleOf: dangerZone.size)
        dangerZone.physicsBody?.isDynamic = false
        dangerZone.physicsBody?.categoryBitMask = PhysicsCategory.dangerZone
        dangerZone.physicsBody?.contactTestBitMask = PhysicsCategory.player
        scene.addChild(dangerZone)
    }

    static func buildOfficeBookshelves(in scene: SKScene, size: CGSize) {
        // Two smaller bookshelves
        let shelfW: CGFloat = 60
        let shelfH: CGFloat = 140

        let positions = [
            CGPoint(x: size.width - 80, y: RoomLayout.floorHeight + shelfH / 2),
            CGPoint(x: 130, y: RoomLayout.floorHeight + shelfH / 2),
        ]

        for (i, pos) in positions.enumerated() {
            let shelfTex = TextureFactory.bookshelfTexture(width: shelfW, height: shelfH)
            let shelf = SKSpriteNode(texture: shelfTex, size: CGSize(width: shelfW, height: shelfH))
            shelf.position = pos
            shelf.zPosition = 2
            shelf.name = "office_bookshelf_\(i)"
            shelf.physicsBody = SKPhysicsBody(rectangleOf: shelf.size)
            shelf.physicsBody?.isDynamic = false
            shelf.physicsBody?.categoryBitMask = PhysicsCategory.furniture
            shelf.physicsBody?.contactTestBitMask = PhysicsCategory.player
            shelf.physicsBody?.mass = 3.5
            scene.addChild(shelf)

            // Danger zone
            let dangerZone = SKSpriteNode(
                color: .clear, size: CGSize(width: shelfW + 50, height: shelfH + 20))
            dangerZone.position = pos
            dangerZone.zPosition = 0
            dangerZone.name = "office_bookshelf_zone_\(i)"
            dangerZone.physicsBody = SKPhysicsBody(rectangleOf: dangerZone.size)
            dangerZone.physicsBody?.isDynamic = false
            dangerZone.physicsBody?.categoryBitMask = PhysicsCategory.dangerZone
            dangerZone.physicsBody?.contactTestBitMask = PhysicsCategory.player
            scene.addChild(dangerZone)
        }
    }

    static func buildFilingCabinet(in scene: SKScene, size: CGSize) {
        let cabinetW: CGFloat = 55
        let cabinetH: CGFloat = 160
        let cabinetX = size.width - 160
        let cabinetY = RoomLayout.floorHeight + cabinetH / 2

        let cabTex = TextureFactory.filingCabinetTexture(
            width: cabinetW, height: cabinetH, drawers: 4)
        let cabinet = SKSpriteNode(texture: cabTex, size: CGSize(width: cabinetW, height: cabinetH))
        cabinet.position = CGPoint(x: cabinetX, y: cabinetY)
        cabinet.zPosition = 2
        cabinet.name = "filing_cabinet"
        cabinet.physicsBody = SKPhysicsBody(rectangleOf: cabinet.size)
        cabinet.physicsBody?.isDynamic = false
        cabinet.physicsBody?.categoryBitMask = PhysicsCategory.furniture
        cabinet.physicsBody?.contactTestBitMask = PhysicsCategory.player
        cabinet.physicsBody?.mass = 5.0
        scene.addChild(cabinet)

        // Danger zone (tall, can tip)
        let dangerZone = SKSpriteNode(
            color: .clear, size: CGSize(width: cabinetW + 50, height: cabinetH + 30))
        dangerZone.position = CGPoint(x: cabinetX, y: cabinetY)
        dangerZone.zPosition = 0
        dangerZone.name = "filing_cabinet_zone"
        dangerZone.physicsBody = SKPhysicsBody(rectangleOf: dangerZone.size)
        dangerZone.physicsBody?.isDynamic = false
        dangerZone.physicsBody?.categoryBitMask = PhysicsCategory.dangerZone
        dangerZone.physicsBody?.contactTestBitMask = PhysicsCategory.player
        scene.addChild(dangerZone)
    }

    static func buildWhiteboard(in scene: SKScene, size: CGSize) {
        let boardW: CGFloat = 140
        let boardH: CGFloat = 90
        let boardX = size.width - 280
        let boardY = RoomLayout.floorHeight + 200

        let boardTex = TextureFactory.whiteboardTexture(width: boardW, height: boardH)
        let board = SKSpriteNode(texture: boardTex, size: CGSize(width: boardW, height: boardH))
        board.position = CGPoint(x: boardX, y: boardY)
        board.zPosition = 2
        board.name = "whiteboard"
        board.physicsBody = SKPhysicsBody(rectangleOf: board.size)
        board.physicsBody?.isDynamic = false
        board.physicsBody?.categoryBitMask = PhysicsCategory.dangerZone
        board.physicsBody?.contactTestBitMask = PhysicsCategory.player
        scene.addChild(board)
    }

    static func buildWindowWithBlinds(in scene: SKScene, size: CGSize) {
        let winX = size.width - 200
        let winY = RoomLayout.floorHeight + 220

        let winTex = TextureFactory.windowWithBlindsTexture(
            width: RoomLayout.windowWidth, height: RoomLayout.windowHeight)
        let window = SKSpriteNode(
            texture: winTex,
            size: CGSize(width: RoomLayout.windowWidth, height: RoomLayout.windowHeight))
        window.position = CGPoint(x: winX, y: winY)
        window.zPosition = 2
        window.name = "window_blinds"
        window.physicsBody = SKPhysicsBody(rectangleOf: window.size)
        window.physicsBody?.isDynamic = false
        window.physicsBody?.categoryBitMask = PhysicsCategory.dangerZone
        window.physicsBody?.contactTestBitMask = PhysicsCategory.player
        scene.addChild(window)
    }

    static func buildOfficeDecorations(in scene: SKScene, size: CGSize) {
        // Plant on desk
        let plantTex = TextureFactory.smallPlantTexture(width: 25, height: 35)
        let plant = SKSpriteNode(texture: plantTex, size: CGSize(width: 25, height: 35))
        plant.position = CGPoint(x: size.width / 2 - 60, y: RoomLayout.floorHeight + 92)
        plant.zPosition = 4
        plant.name = "desk_plant"
        plant.physicsBody = SKPhysicsBody(rectangleOf: plant.size)
        plant.physicsBody?.isDynamic = false
        plant.physicsBody?.categoryBitMask = PhysicsCategory.debris
        plant.physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.floor
        plant.physicsBody?.mass = 0.2
        scene.addChild(plant)

        // Office rug
        let rugW: CGFloat = 160
        let rugH: CGFloat = 60
        let rugTex = TextureFactory.officeRugTexture(width: rugW, height: rugH)
        let rug = SKSpriteNode(texture: rugTex, size: CGSize(width: rugW, height: rugH))
        rug.position = CGPoint(x: size.width / 2, y: RoomLayout.floorHeight + rugH / 2 + 2)
        rug.zPosition = -3
        rug.name = "office_rug"
        scene.addChild(rug)
    }

    static func buildOfficeDebris(in scene: SKScene, size: CGSize) {
        // Computer monitor on desk
        let monitorW: CGFloat = 50
        let monitorH: CGFloat = 40
        let monitorTex = TextureFactory.monitorTexture(width: monitorW, height: monitorH)
        let monitor = SKSpriteNode(
            texture: monitorTex, size: CGSize(width: monitorW, height: monitorH))
        monitor.position = CGPoint(x: size.width / 2 + 30, y: RoomLayout.floorHeight + 95)
        monitor.zPosition = 4
        monitor.name = "monitor"
        monitor.physicsBody = SKPhysicsBody(rectangleOf: monitor.size)
        monitor.physicsBody?.isDynamic = false
        monitor.physicsBody?.categoryBitMask = PhysicsCategory.debris
        monitor.physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.floor
        monitor.physicsBody?.mass = 0.8
        scene.addChild(monitor)

        // Keyboard
        let kbTex = TextureFactory.keyboardTexture(width: 40, height: 12)
        let keyboard = SKSpriteNode(texture: kbTex, size: CGSize(width: 40, height: 12))
        keyboard.position = CGPoint(x: size.width / 2 + 20, y: RoomLayout.floorHeight + 88)
        keyboard.zPosition = 4
        keyboard.name = "keyboard"
        keyboard.physicsBody = SKPhysicsBody(rectangleOf: keyboard.size)
        keyboard.physicsBody?.isDynamic = false
        keyboard.physicsBody?.categoryBitMask = PhysicsCategory.debris
        keyboard.physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.floor
        keyboard.physicsBody?.mass = 0.3
        scene.addChild(keyboard)

        // Picture frame on wall
        let frameTex = TextureFactory.pictureFrameTexture(width: 40, height: 35, pictureHue: 0.55)
        let frame = SKSpriteNode(texture: frameTex, size: CGSize(width: 40, height: 35))
        frame.position = CGPoint(x: 200, y: size.height - 180)
        frame.zPosition = 2
        frame.name = "office_picture"
        frame.physicsBody = SKPhysicsBody(rectangleOf: frame.size)
        frame.physicsBody?.isDynamic = false
        frame.physicsBody?.categoryBitMask = PhysicsCategory.debris
        frame.physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.floor
        frame.physicsBody?.mass = 0.3
        scene.addChild(frame)
    }

    // MARK: - Bedroom Elements

    static func buildBed(in scene: SKScene, size: CGSize) {
        let bedW: CGFloat = 160
        let bedH: CGFloat = 75
        let bedX = size.width / 2
        let bedY = RoomLayout.floorHeight + bedH / 2

        // Bed frame
        let frameTex = TextureFactory.bedFrameTexture(width: bedW, height: 20)
        let frame = SKSpriteNode(texture: frameTex, size: CGSize(width: bedW, height: 20))
        frame.position = CGPoint(x: bedX, y: bedY - bedH / 2 + 10)
        frame.zPosition = 2
        frame.name = "bed_frame"
        scene.addChild(frame)

        // Mattress
        let mattressTex = TextureFactory.mattressTexture(width: bedW - 10, height: 35)
        let mattress = SKSpriteNode(
            texture: mattressTex, size: CGSize(width: bedW - 10, height: 35))
        mattress.position = CGPoint(x: bedX, y: bedY + 5)
        mattress.zPosition = 3
        mattress.name = "mattress"
        scene.addChild(mattress)

        // Pillow
        let pillowTex = TextureFactory.pillowTexture(width: 40, height: 15)
        let pillow = SKSpriteNode(texture: pillowTex, size: CGSize(width: 40, height: 15))
        pillow.position = CGPoint(x: bedX - bedW / 3, y: bedY + 20)
        pillow.zPosition = 4
        pillow.name = "pillow"
        scene.addChild(pillow)

        // Blanket (covers lower half)
        let blanketTex = TextureFactory.blanketTexture(width: bedW - 8, height: 40)
        let blanket = SKSpriteNode(texture: blanketTex, size: CGSize(width: bedW - 8, height: 40))
        blanket.position = CGPoint(x: bedX + 5, y: bedY - 5)
        blanket.zPosition = 4
        blanket.name = "blanket"
        scene.addChild(blanket)

        // Safe zone under bed (get under it)
        let safeZone = SKSpriteNode(
            color: .clear, size: CGSize(width: bedW - 20, height: bedH - 20))
        safeZone.position = CGPoint(x: bedX, y: bedY - 5)
        safeZone.zPosition = 0
        safeZone.name = "bed"
        safeZone.physicsBody = SKPhysicsBody(rectangleOf: safeZone.size)
        safeZone.physicsBody?.isDynamic = false
        safeZone.physicsBody?.categoryBitMask = PhysicsCategory.safeZone
        safeZone.physicsBody?.contactTestBitMask = PhysicsCategory.player
        scene.addChild(safeZone)

        // Label
        let label = SKLabelNode(text: "BED")
        label.fontSize = DynamicTypeScale.scaled(14)
        label.fontColor = HighContrast.zoneLabelColor
        label.fontName = "Helvetica-Bold"
        label.position = CGPoint(x: bedX, y: bedY + bedH / 2 + 10)
        label.zPosition = 5
        label.name = "bed_label"
        scene.addChild(label)
    }

    static func buildWardrobe(in scene: SKScene, size: CGSize) {
        let wardrobeW: CGFloat = 100
        let wardrobeH: CGFloat = 210
        let wardrobeX = size.width - 110
        let wardrobeY = RoomLayout.floorHeight + wardrobeH / 2

        let wardrobeTex = TextureFactory.wardrobeTexture(width: wardrobeW, height: wardrobeH)
        let wardrobe = SKSpriteNode(
            texture: wardrobeTex, size: CGSize(width: wardrobeW, height: wardrobeH))
        wardrobe.position = CGPoint(x: wardrobeX, y: wardrobeY)
        wardrobe.zPosition = 2
        wardrobe.name = "wardrobe"
        wardrobe.physicsBody = SKPhysicsBody(rectangleOf: wardrobe.size)
        wardrobe.physicsBody?.isDynamic = false
        wardrobe.physicsBody?.categoryBitMask = PhysicsCategory.furniture
        wardrobe.physicsBody?.contactTestBitMask = PhysicsCategory.player
        wardrobe.physicsBody?.mass = 7.0
        scene.addChild(wardrobe)

        // Danger zone (tall furniture, can tip)
        let dangerZone = SKSpriteNode(
            color: .clear, size: CGSize(width: wardrobeW + 60, height: wardrobeH + 30))
        dangerZone.position = CGPoint(x: wardrobeX, y: wardrobeY)
        dangerZone.zPosition = 0
        dangerZone.name = "wardrobe_zone"
        dangerZone.physicsBody = SKPhysicsBody(rectangleOf: dangerZone.size)
        dangerZone.physicsBody?.isDynamic = false
        dangerZone.physicsBody?.categoryBitMask = PhysicsCategory.dangerZone
        dangerZone.physicsBody?.contactTestBitMask = PhysicsCategory.player
        scene.addChild(dangerZone)
    }

    static func buildNightstands(in scene: SKScene, size: CGSize) {
        let nightstandW: CGFloat = 45
        let nightstandH: CGFloat = 50

        // Left nightstand
        let leftPos = CGPoint(x: size.width / 2 - 120, y: RoomLayout.floorHeight + nightstandH / 2)
        buildNightstand(
            in: scene, at: leftPos, width: nightstandW, height: nightstandH, name: "nightstand_left"
        )

        // Right nightstand
        let rightPos = CGPoint(x: size.width / 2 + 120, y: RoomLayout.floorHeight + nightstandH / 2)
        buildNightstand(
            in: scene, at: rightPos, width: nightstandW, height: nightstandH,
            name: "nightstand_right")
    }

    static func buildNightstand(
        in scene: SKScene, at position: CGPoint, width: CGFloat, height: CGFloat, name: String
    ) {
        let nsTex = TextureFactory.nightstandTexture(width: width, height: height)
        let nightstand = SKSpriteNode(texture: nsTex, size: CGSize(width: width, height: height))
        nightstand.position = position
        nightstand.zPosition = 2
        nightstand.name = name
        nightstand.physicsBody = SKPhysicsBody(rectangleOf: nightstand.size)
        nightstand.physicsBody?.isDynamic = false
        nightstand.physicsBody?.categoryBitMask = PhysicsCategory.furniture
        nightstand.physicsBody?.contactTestBitMask = PhysicsCategory.player
        nightstand.physicsBody?.mass = 2.0
        scene.addChild(nightstand)

        // Lamp on nightstand
        let lampTex = TextureFactory.bedsideLampTexture(width: 20, height: 28)
        let lamp = SKSpriteNode(texture: lampTex, size: CGSize(width: 20, height: 28))
        lamp.position = CGPoint(x: position.x, y: position.y + height / 2 + 14)
        lamp.zPosition = 4
        lamp.name = "\(name)_lamp"
        lamp.physicsBody = SKPhysicsBody(rectangleOf: lamp.size)
        lamp.physicsBody?.isDynamic = false
        lamp.physicsBody?.categoryBitMask = PhysicsCategory.debris
        lamp.physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.floor
        lamp.physicsBody?.mass = 0.4
        scene.addChild(lamp)
    }

    static func buildWindowWithCurtains(in scene: SKScene, size: CGSize) {
        let winX = size.width - 250
        let winY = RoomLayout.floorHeight + 200

        let winTex = TextureFactory.windowWithCurtainsTexture(
            width: RoomLayout.windowWidth, height: RoomLayout.windowHeight)
        let window = SKSpriteNode(
            texture: winTex,
            size: CGSize(width: RoomLayout.windowWidth, height: RoomLayout.windowHeight))
        window.position = CGPoint(x: winX, y: winY)
        window.zPosition = 2
        window.name = "window_curtains"
        window.physicsBody = SKPhysicsBody(rectangleOf: window.size)
        window.physicsBody?.isDynamic = false
        window.physicsBody?.categoryBitMask = PhysicsCategory.dangerZone
        window.physicsBody?.contactTestBitMask = PhysicsCategory.player
        scene.addChild(window)
    }

    static func buildBedroomRug(in scene: SKScene, size: CGSize) {
        let rugW: CGFloat = 180
        let rugH: CGFloat = 60
        let rugTex = TextureFactory.bedroomRugTexture(width: rugW, height: rugH)
        let rug = SKSpriteNode(texture: rugTex, size: CGSize(width: rugW, height: rugH))
        rug.position = CGPoint(x: size.width / 2, y: RoomLayout.floorHeight + rugH / 2 + 2)
        rug.zPosition = -3
        rug.name = "bedroom_rug"
        scene.addChild(rug)
    }

    static func buildBedroomDecorations(in scene: SKScene, size: CGSize) {
        // Picture frames on walls
        let frame1Tex = TextureFactory.pictureFrameTexture(width: 35, height: 45, pictureHue: 0.15)
        let frame1 = SKSpriteNode(texture: frame1Tex, size: CGSize(width: 35, height: 45))
        frame1.position = CGPoint(x: size.width - 250, y: size.height - 150)
        frame1.zPosition = 2
        frame1.name = "bedroom_frame_1"
        frame1.physicsBody = SKPhysicsBody(rectangleOf: frame1.size)
        frame1.physicsBody?.isDynamic = false
        frame1.physicsBody?.categoryBitMask = PhysicsCategory.debris
        frame1.physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.floor
        frame1.physicsBody?.mass = 0.25
        scene.addChild(frame1)

        let frame2Tex = TextureFactory.pictureFrameTexture(width: 40, height: 30, pictureHue: 0.65)
        let frame2 = SKSpriteNode(texture: frame2Tex, size: CGSize(width: 40, height: 30))
        frame2.position = CGPoint(x: 150, y: size.height - 200)
        frame2.zPosition = 2
        frame2.name = "bedroom_frame_2"
        frame2.physicsBody = SKPhysicsBody(rectangleOf: frame2.size)
        frame2.physicsBody?.isDynamic = false
        frame2.physicsBody?.categoryBitMask = PhysicsCategory.debris
        frame2.physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.floor
        frame2.physicsBody?.mass = 0.25
        scene.addChild(frame2)
    }

    static func buildBedroomDebris(in scene: SKScene, size: CGSize) {
        // Alarm clock on nightstand
        let clockTex = TextureFactory.alarmClockTexture(width: 18, height: 15)
        let clock = SKSpriteNode(texture: clockTex, size: CGSize(width: 18, height: 15))
        clock.position = CGPoint(x: size.width / 2 + 120, y: RoomLayout.floorHeight + 57)
        clock.zPosition = 5
        clock.name = "alarm_clock"
        clock.physicsBody = SKPhysicsBody(rectangleOf: clock.size)
        clock.physicsBody?.isDynamic = false
        clock.physicsBody?.categoryBitMask = PhysicsCategory.debris
        clock.physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.floor
        clock.physicsBody?.mass = 0.15
        scene.addChild(clock)

        // Books on nightstand
        let bookTex = TextureFactory.smallBookTexture(width: 12, height: 18)
        let book = SKSpriteNode(texture: bookTex, size: CGSize(width: 12, height: 18))
        book.position = CGPoint(x: size.width / 2 - 125, y: RoomLayout.floorHeight + 58)
        book.zPosition = 5
        book.name = "bedside_book"
        book.physicsBody = SKPhysicsBody(rectangleOf: book.size)
        book.physicsBody?.isDynamic = false
        book.physicsBody?.categoryBitMask = PhysicsCategory.debris
        book.physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.floor
        book.physicsBody?.mass = 0.2
        scene.addChild(book)
    }

    // MARK: - Player

    static func buildPlayer(in scene: SKScene, size: CGSize) {
        let playerTex = TextureFactory.playerTexture()
        let playerNode = SKSpriteNode(texture: playerTex, size: RoomLayout.playerSize)
        playerNode.position = CGPoint(
            x: size.width / 2, y: RoomLayout.floorHeight + RoomLayout.playerSize.height / 2 + 5)
        playerNode.zPosition = 10
        playerNode.name = "player"
        playerNode.physicsBody = SKPhysicsBody(rectangleOf: RoomLayout.playerSize)
        playerNode.physicsBody?.isDynamic = false
        playerNode.physicsBody?.categoryBitMask = PhysicsCategory.player
        playerNode.physicsBody?.contactTestBitMask =
            PhysicsCategory.debris | PhysicsCategory.furniture | PhysicsCategory.safeZone
            | PhysicsCategory.dangerZone
        playerNode.physicsBody?.collisionBitMask = PhysicsCategory.floor | PhysicsCategory.wall

        // Add dynamic shadow beneath player
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 28, height: 7))
        shadow.fillColor = SKColor(white: 0, alpha: 0.18)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -RoomLayout.playerSize.height / 2 - 2)
        shadow.zPosition = -1
        shadow.name = "player_shadow"
        playerNode.addChild(shadow)

        scene.addChild(playerNode)
    }

    // MARK: - Aftershock Interactive Zones

    static func buildAftershockZones(in scene: SKScene, size: CGSize) {
        // MARK: - Gas Valve Zone
        let valveX = size.width - 60
        let valveY = RoomLayout.floorHeight + 35

        // Pipe extending into floor (behind valve)
        let pipeSegment = SKShapeNode(rectOf: CGSize(width: 12, height: 40))
        pipeSegment.fillColor = SKColor(white: 0.3, alpha: 1.0)
        pipeSegment.strokeColor = SKColor(white: 0.15, alpha: 1.0)
        pipeSegment.lineWidth = 2
        pipeSegment.position = CGPoint(x: valveX, y: valveY - 35)
        pipeSegment.zPosition = 7
        pipeSegment.name = "gas_valve_pipe"
        pipeSegment.alpha = 0
        scene.addChild(pipeSegment)

        // Gas valve sprite with enhanced size
        let gasValveTex = TextureFactory.gasValveIcon()
        let gasValve = SKSpriteNode(texture: gasValveTex, size: CGSize(width: 50, height: 58))
        gasValve.position = CGPoint(x: valveX, y: valveY)
        gasValve.zPosition = 8
        gasValve.name = "gas_valve"
        gasValve.alpha = 0
        scene.addChild(gasValve)

        // "GAS" warning label plate above valve
        let warningPlate = SKShapeNode(rectOf: CGSize(width: 44, height: 18), cornerRadius: 4)
        warningPlate.fillColor = SKColor(red: 0.9, green: 0.15, blue: 0.1, alpha: 1.0)
        warningPlate.strokeColor = SKColor(white: 0.9, alpha: 1.0)
        warningPlate.lineWidth = 2
        warningPlate.position = CGPoint(x: 0, y: 45)
        warningPlate.zPosition = 1
        gasValve.addChild(warningPlate)

        let warningLabel = SKLabelNode(text: "GAS")
        warningLabel.fontSize = DynamicTypeScale.scaled(11)
        warningLabel.fontColor = .white
        warningLabel.fontName = "Helvetica-Bold"
        warningLabel.position = CGPoint(x: 0, y: 0)
        warningLabel.verticalAlignmentMode = .center
        warningPlate.addChild(warningLabel)

        // Valve label below
        let valveLabel = SKLabelNode(text: String(localized: "GAS VALVE"))
        valveLabel.fontSize = DynamicTypeScale.scaled(9)
        valveLabel.fontColor = .white
        valveLabel.fontName = "Helvetica-Bold"
        valveLabel.position = CGPoint(x: 0, y: -38)
        valveLabel.verticalAlignmentMode = .center
        gasValve.addChild(valveLabel)

        // Red warning light glow (pulsing)
        let warningGlow = SKShapeNode(circleOfRadius: 35)
        warningGlow.fillColor = SKColor(red: 1.0, green: 0.2, blue: 0.1, alpha: 0.15)
        warningGlow.strokeColor = SKColor(red: 1.0, green: 0.3, blue: 0.2, alpha: 0.3)
        warningGlow.lineWidth = 2
        warningGlow.position = CGPoint(x: valveX, y: valveY)
        warningGlow.zPosition = 7
        warningGlow.name = "gas_valve_glow"
        warningGlow.alpha = 0
        scene.addChild(warningGlow)

        // Gas leak particles (faint bubbles)
        let gasEmitter = SKEmitterNode()
        gasEmitter.position = CGPoint(x: valveX, y: valveY + 10)
        gasEmitter.zPosition = 9
        gasEmitter.name = "gas_valve_emitter"
        gasEmitter.alpha = 0

        // Gas bubble texture
        let bubbleSize = CGSize(width: 6, height: 6)
        let bubbleFormat = UIGraphicsImageRendererFormat()
        bubbleFormat.scale = 1.0
        bubbleFormat.opaque = false
        let bubbleRenderer = UIGraphicsImageRenderer(size: bubbleSize, format: bubbleFormat)
        let bubbleImage = bubbleRenderer.image { context in
            let ctx = context.cgContext
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor(red: 0.5, green: 0.6, blue: 0.4, alpha: 0.5).cgColor,
                    UIColor(red: 0.4, green: 0.5, blue: 0.3, alpha: 0.3).cgColor,
                    UIColor(red: 0.3, green: 0.4, blue: 0.2, alpha: 0.0).cgColor,
                ] as CFArray,
                locations: [0.0, 0.5, 1.0]
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
        gasEmitter.particleTexture = SKTexture(image: bubbleImage)
        gasEmitter.particleTexture?.filteringMode = .linear

        // Gas bubble settings
        gasEmitter.particleBirthRate = 8
        gasEmitter.particleLifetime = 2.0
        gasEmitter.particleLifetimeRange = 0.5
        gasEmitter.yAcceleration = -30
        gasEmitter.particleSpeed = 25
        gasEmitter.particleSpeedRange = 15
        gasEmitter.emissionAngle = .pi / 2
        gasEmitter.emissionAngleRange = .pi / 4
        gasEmitter.particleScale = 0.6
        gasEmitter.particleScaleRange = 0.3
        gasEmitter.particleScaleSpeed = 0.2
        gasEmitter.particleAlpha = 0.5
        gasEmitter.particleAlphaSpeed = -0.2
        gasEmitter.particleBlendMode = .alpha
        scene.addChild(gasEmitter)

        // Safe exit
        let exitTex = TextureFactory.exitSignIcon()
        let exitMarker = SKSpriteNode(texture: exitTex, size: CGSize(width: 50, height: 30))
        exitMarker.position = CGPoint(x: 70, y: RoomLayout.floorHeight + RoomLayout.doorHeight + 30)
        exitMarker.zPosition = 8
        exitMarker.name = "safe_exit"
        exitMarker.alpha = 0
        scene.addChild(exitMarker)

        let exitLabel = SKLabelNode(text: String(localized: "SAFE EXIT"))
        exitLabel.fontSize = DynamicTypeScale.scaled(9)
        exitLabel.fontColor = AppColors.skCorrect
        exitLabel.fontName = "Helvetica-Bold"
        exitLabel.position = CGPoint(x: 0, y: -24)
        exitLabel.verticalAlignmentMode = .center
        exitMarker.addChild(exitLabel)

        // Debris blocking the door (hidden, shown during safe_exit task)
        let doorX: CGFloat = 70
        let debrisContainer = SKNode()
        debrisContainer.name = "door_debris"
        debrisContainer.zPosition = 3
        debrisContainer.alpha = 0
        scene.addChild(debrisContainer)

        // Fallen beam across the doorway
        let beam = SKShapeNode(rectOf: CGSize(width: 70, height: 14), cornerRadius: 3)
        beam.fillColor = SKColor(red: 0.50, green: 0.35, blue: 0.20, alpha: 1.0)
        beam.strokeColor = CartoonPalette.outline.skColor
        beam.lineWidth = 2
        beam.position = CGPoint(x: doorX + 5, y: RoomLayout.floorHeight + 50)
        beam.zRotation = 0.2
        beam.name = "door_debris_beam"
        debrisContainer.addChild(beam)

        // Concrete chunk
        let chunk = SKShapeNode(rectOf: CGSize(width: 30, height: 25), cornerRadius: 4)
        chunk.fillColor = SKColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
        chunk.strokeColor = CartoonPalette.outline.skColor
        chunk.lineWidth = 2
        chunk.position = CGPoint(x: doorX - 15, y: RoomLayout.floorHeight + 20)
        chunk.zRotation = -0.15
        chunk.name = "door_debris_chunk"
        debrisContainer.addChild(chunk)

        // Crack detail on chunk
        let chunkCrack = SKShapeNode()
        let chunkCrackPath = CGMutablePath()
        chunkCrackPath.move(to: CGPoint(x: -8, y: 5))
        chunkCrackPath.addLine(to: CGPoint(x: 2, y: -3))
        chunkCrackPath.addLine(to: CGPoint(x: 6, y: 4))
        chunkCrack.path = chunkCrackPath
        chunkCrack.strokeColor = SKColor(white: 0.0, alpha: 0.3)
        chunkCrack.lineWidth = 1
        chunk.addChild(chunkCrack)

        // Broken plank leaning against door frame
        let plank = SKShapeNode(rectOf: CGSize(width: 55, height: 10), cornerRadius: 2)
        plank.fillColor = SKColor(red: 0.45, green: 0.30, blue: 0.18, alpha: 1.0)
        plank.strokeColor = CartoonPalette.outline.skColor
        plank.lineWidth = 2
        plank.position = CGPoint(x: doorX + 10, y: RoomLayout.floorHeight + 95)
        plank.zRotation = -0.45
        plank.name = "door_debris_plank"
        debrisContainer.addChild(plank)

        // Dust cloud settling around debris
        let dustHaze = SKShapeNode(ellipseOf: CGSize(width: 100, height: 40))
        dustHaze.fillColor = SKColor(white: 0.7, alpha: 0.12)
        dustHaze.strokeColor = .clear
        dustHaze.position = CGPoint(x: doorX, y: RoomLayout.floorHeight + 40)
        dustHaze.name = "door_debris_dust"
        debrisContainer.addChild(dustHaze)

        // Injury check
        let aidTex = TextureFactory.firstAidIcon()
        let injuryCheck = SKSpriteNode(texture: aidTex, size: CGSize(width: 50, height: 50))
        injuryCheck.position = CGPoint(x: size.width / 2 + 120, y: RoomLayout.floorHeight + 55)
        injuryCheck.zPosition = 8
        injuryCheck.name = "injury_check"
        injuryCheck.alpha = 0
        scene.addChild(injuryCheck)

        // Medical cross floor marker
        let floorMarker = SKShapeNode()
        let markerPath = CGMutablePath()
        let markerSize: CGFloat = 25
        let markerY: CGFloat = -30
        // Cross horizontal
        markerPath.addRect(CGRect(x: -markerSize / 2, y: markerY - 4, width: markerSize, height: 8))
        // Cross vertical
        markerPath.addRect(CGRect(x: -4, y: markerY - markerSize / 2, width: 8, height: markerSize))
        floorMarker.path = markerPath
        floorMarker.fillColor = SKColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 0.4)
        floorMarker.strokeColor = SKColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 0.6)
        floorMarker.lineWidth = 1
        floorMarker.zPosition = -1
        floorMarker.alpha = 0
        floorMarker.name = "injury_floor_marker"
        injuryCheck.addChild(floorMarker)

        // Healing sparkle emitter (continuous, subtle)
        let healingEmitter = ParticleEffects.healingSparkles(at: .zero, intensity: 0.4)
        healingEmitter.name = "injury_healing_emitter"
        healingEmitter.alpha = 0
        injuryCheck.addChild(healingEmitter)

        // Heartbeat pulse ring
        let pulseRing = SKShapeNode(circleOfRadius: 35)
        pulseRing.fillColor = .clear
        pulseRing.strokeColor = SKColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 0.4)
        pulseRing.lineWidth = 2
        pulseRing.zPosition = -2
        pulseRing.alpha = 0
        pulseRing.name = "injury_pulse_ring"
        injuryCheck.addChild(pulseRing)

        let injuryLabel = SKLabelNode(text: String(localized: "FIRST AID"))
        injuryLabel.fontSize = DynamicTypeScale.scaled(9)
        injuryLabel.fontColor = SKColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1)
        injuryLabel.fontName = "Helvetica-Bold"
        injuryLabel.position = CGPoint(x: 0, y: -32)
        injuryLabel.verticalAlignmentMode = .center
        injuryCheck.addChild(injuryLabel)

        // Small medical supplies scattered nearby (bandage, ointment)
        let supplies = SKNode()
        supplies.name = "medical_supplies"
        supplies.alpha = 0
        supplies.position = CGPoint(x: 25, y: -8)
        injuryCheck.addChild(supplies)

        // Bandage roll
        let bandage = SKShapeNode(rectOf: CGSize(width: 12, height: 8), cornerRadius: 2)
        bandage.fillColor = SKColor(red: 1.0, green: 0.9, blue: 0.8, alpha: 1)
        bandage.strokeColor = SKColor(red: 0.8, green: 0.7, blue: 0.6, alpha: 0.8)
        bandage.lineWidth = 1
        bandage.position = CGPoint(x: 0, y: 0)
        bandage.zRotation = 0.3
        supplies.addChild(bandage)

        // Small red cross on bandage
        let bandageCross = SKNode()
        let crossH = SKShapeNode(rectOf: CGSize(width: 6, height: 2))
        crossH.fillColor = SKColor(red: 0.9, green: 0.15, blue: 0.1, alpha: 1)
        let crossV = SKShapeNode(rectOf: CGSize(width: 2, height: 6))
        crossV.fillColor = SKColor(red: 0.9, green: 0.15, blue: 0.1, alpha: 1)
        bandageCross.addChild(crossH)
        bandageCross.addChild(crossV)
        bandageCross.position = CGPoint(x: 0, y: 0)
        bandageCross.zPosition = 1
        bandage.addChild(bandageCross)
    }
}

// MARK: - UIColor Extension for SKColor compatibility

extension UIColor {
    fileprivate var skColor: SKColor {
        return SKColor(cgColor: self.cgColor)
    }
}
