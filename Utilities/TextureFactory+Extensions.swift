import SpriteKit
import UIKit

extension TextureFactory {

    // MARK: - Enums

    enum KitchenColorType {
        case island, counter
    }

    enum CabinetType {
        case base, wall
    }

    // MARK: - Player

    // Helper to load image from bundle
    private static func loadBundleImage(named name: String) -> UIImage? {
        return UIImage(named: name)
    }

    static func playerTexture() -> SKTexture {
        if let image = loadBundleImage(named: "player_stand") {
            return SKTexture(image: image)
        }
        // Fallback if asset missing
        let width: CGFloat = 40
        let height: CGFloat = 80
        let renderer = makeTransparentRenderer(width: width, height: height)
        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)
            ctx.setFillColor(CartoonPalette.pantsGray.cgColor)
            let legPath = roundedRectPath(rect: CGRect(x: 8, y: 45, width: 24, height: 35), cornerRadius: 4)
            ctx.addPath(legPath)
            ctx.fillPath()
            drawOutline(ctx: ctx, path: legPath)
            ctx.setFillColor(CartoonPalette.shirtBlue.cgColor)
            let torsoPath = roundedRectPath(rect: CGRect(x: 6, y: 20, width: 28, height: 30), cornerRadius: 5)
            ctx.addPath(torsoPath)
            ctx.fillPath()
            drawOutline(ctx: ctx, path: torsoPath)
            ctx.setFillColor(CartoonPalette.skin.cgColor)
            let headRect = CGRect(x: 8, y: 0, width: 24, height: 24)
            ctx.fillEllipse(in: headRect)
            drawOutline(ctx: ctx, path: CGPath(ellipseIn: headRect, transform: nil))
        }
        return finalize(image)
    }

    // MARK: - Player States

    static func playerIdleTexture() -> SKTexture {
        if let image = loadBundleImage(named: "player_idle") { return SKTexture(image: image) }
        return playerTexture()
    }

    static func playerWalk2Texture() -> SKTexture {
        if let image = loadBundleImage(named: "player_walk2") { return SKTexture(image: image) }
        return playerTexture()
    }

    static func playerHurtTexture() -> SKTexture {
        if let image = loadBundleImage(named: "player_hurt") { return SKTexture(image: image) }
        return playerTexture()
    }

    static func playerFallTexture() -> SKTexture {
        if let image = loadBundleImage(named: "player_fall") { return SKTexture(image: image) }
        return playerTexture()
    }

    static func playerDuckTexture() -> SKTexture {
        if let image = loadBundleImage(named: "player_duck") { return SKTexture(image: image) }
        return playerTexture()
    }

    static func playerCrouchTexture() -> SKTexture {
        return playerDuckTexture()
    }

    static func playerCoverTexture() -> SKTexture {
        return playerDuckTexture()
    }

    static func playerRunTexture() -> SKTexture {
        if let image = loadBundleImage(named: "player_run") { return SKTexture(image: image) }
        // Fallback to walk1 if run is missing, or procedurally
        if let image = loadBundleImage(named: "player_walk1") { return SKTexture(image: image) }
        return playerTexture()
    }

    static func playerSkidTexture() -> SKTexture {
        if let image = loadBundleImage(named: "player_skid") { return SKTexture(image: image) }
        return playerTexture()
    }

    static func playerKickTexture() -> SKTexture {
        if let image = loadBundleImage(named: "player_kick") { return SKTexture(image: image) }
        return playerTexture()
    }

    static func playerSlideTexture() -> SKTexture {
        if let image = loadBundleImage(named: "player_slide") { return SKTexture(image: image) }
        return playerTexture()
    }

    static func playerClimb1Texture() -> SKTexture {
        if let image = loadBundleImage(named: "player_climb1") { return SKTexture(image: image) }
        return playerTexture()
    }

    static func playerJumpTexture() -> SKTexture {
        if let image = loadBundleImage(named: "player_jump") { return SKTexture(image: image) }
        return playerTexture()
    }

    static func playerCheer1Texture() -> SKTexture {
        if let image = loadBundleImage(named: "player_cheer1") { return SKTexture(image: image) }
        return playerTexture()
    }

    static func playerHold1Texture() -> SKTexture {
        if let image = loadBundleImage(named: "player_hold1") { return SKTexture(image: image) }
        return playerTexture()
    }

    static func playerHold2Texture() -> SKTexture {
        if let image = loadBundleImage(named: "player_hold2") { return SKTexture(image: image) }
        return playerTexture()
    }

    static func playerAction1Texture() -> SKTexture {
        if let image = loadBundleImage(named: "player_action1") { return SKTexture(image: image) }
        return playerTexture()
    }

    static func playerAction2Texture() -> SKTexture {
        if let image = loadBundleImage(named: "player_action2") { return SKTexture(image: image) }
        return playerTexture()
    }

    static func playerCoverProtectTexture() -> SKTexture {
        if let image = loadBundleImage(named: "player_cover_protect") { return SKTexture(image: image) }
        return playerDuckTexture()
    }

    // MARK: - UI

    /// Cute platformer-style skull icon for lives (full life remaining)
    static func lifeFullTexture() -> SKTexture {
        let renderer = makeTransparentRenderer(width: 30, height: 30)
        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)

            // Skull cranium (round, cute)
            let skullPath = CGMutablePath()
            skullPath.addArc(center: CGPoint(x: 15, y: 14), radius: 11, startAngle: 0, endAngle: .pi * 2, clockwise: false)
            ctx.setFillColor(UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0).cgColor)
            ctx.addPath(skullPath)
            ctx.fillPath()
            drawOutline(ctx: ctx, path: skullPath)

            // Eye sockets (cute X eyes)
            ctx.setStrokeColor(UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0).cgColor)
            ctx.setLineWidth(2)
            ctx.setLineCap(.round)

            // Left X eye
            ctx.move(to: CGPoint(x: 9, y: 11))
            ctx.addLine(to: CGPoint(x: 13, y: 15))
            ctx.move(to: CGPoint(x: 13, y: 11))
            ctx.addLine(to: CGPoint(x: 9, y: 15))
            ctx.strokePath()

            // Right X eye
            ctx.move(to: CGPoint(x: 17, y: 11))
            ctx.addLine(to: CGPoint(x: 21, y: 15))
            ctx.move(to: CGPoint(x: 21, y: 11))
            ctx.addLine(to: CGPoint(x: 17, y: 15))
            ctx.strokePath()

            // Cute smile
            let smilePath = CGMutablePath()
            smilePath.move(to: CGPoint(x: 10, y: 20))
            smilePath.addQuadCurve(to: CGPoint(x: 20, y: 20), control: CGPoint(x: 15, y: 23))
            ctx.setStrokeColor(UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0).cgColor)
            ctx.setLineWidth(2)
            ctx.setLineCap(.round)
            ctx.addPath(smilePath)
            ctx.strokePath()
        }
        return finalize(image)
    }

    /// Empty skull icon (life lost) - grayed out version
    static func lifeLostTexture() -> SKTexture {
        let renderer = makeTransparentRenderer(width: 30, height: 30)
        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)

            // Skull outline (grayed out)
            let skullPath = CGMutablePath()
            skullPath.addArc(center: CGPoint(x: 15, y: 14), radius: 11, startAngle: 0, endAngle: .pi * 2, clockwise: false)
            ctx.setFillColor(UIColor(white: 0.3, alpha: 0.5).cgColor)
            ctx.addPath(skullPath)
            ctx.fillPath()

            ctx.setStrokeColor(UIColor(white: 0.4, alpha: 0.6).cgColor)
            ctx.setLineWidth(2)
            ctx.addPath(skullPath)
            ctx.strokePath()

            // Faint X eyes
            ctx.setStrokeColor(UIColor(white: 0.5, alpha: 0.4).cgColor)
            ctx.setLineWidth(1.5)
            ctx.setLineCap(.round)

            ctx.move(to: CGPoint(x: 9, y: 11))
            ctx.addLine(to: CGPoint(x: 13, y: 15))
            ctx.move(to: CGPoint(x: 13, y: 11))
            ctx.addLine(to: CGPoint(x: 9, y: 15))
            ctx.strokePath()

            ctx.move(to: CGPoint(x: 17, y: 11))
            ctx.addLine(to: CGPoint(x: 21, y: 15))
            ctx.move(to: CGPoint(x: 21, y: 11))
            ctx.addLine(to: CGPoint(x: 17, y: 15))
            ctx.strokePath()

            // Faint sad mouth (upside down smile)
            let frownPath = CGMutablePath()
            frownPath.move(to: CGPoint(x: 10, y: 21))
            frownPath.addQuadCurve(to: CGPoint(x: 20, y: 21), control: CGPoint(x: 15, y: 18))
            ctx.addPath(frownPath)
            ctx.strokePath()
        }
        return finalize(image)
    }

    // Deprecated: heart textures kept for compatibility if used elsewhere
    static func heartFullTexture() -> SKTexture {
        let renderer = makeTransparentRenderer(width: 30, height: 30)
        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)

            ctx.setFillColor(UIColor.red.cgColor)
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 15, y: 5))
            path.addCurve(to: CGPoint(x: 15, y: 25), control1: CGPoint(x: 0, y: 0), control2: CGPoint(x: 0, y: 20))
            path.addCurve(to: CGPoint(x: 15, y: 5), control1: CGPoint(x: 30, y: 20), control2: CGPoint(x: 30, y: 0))
            path.closeSubpath()
            ctx.addPath(path)
            ctx.fillPath()
            drawOutline(ctx: ctx, path: path)
        }
        return finalize(image)
    }

    static func heartEmptyTexture() -> SKTexture {
        let renderer = makeTransparentRenderer(width: 30, height: 30)
        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)

            ctx.setFillColor(UIColor(white: 0.8, alpha: 0.5).cgColor)
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 15, y: 5))
            path.addCurve(to: CGPoint(x: 15, y: 25), control1: CGPoint(x: 0, y: 0), control2: CGPoint(x: 0, y: 20))
            path.addCurve(to: CGPoint(x: 15, y: 5), control1: CGPoint(x: 30, y: 20), control2: CGPoint(x: 30, y: 0))
            path.closeSubpath()
            ctx.addPath(path)
            ctx.fillPath()
            drawOutline(ctx: ctx, path: path)
        }
        return finalize(image)
    }

    // MARK: - Rugs

    static func rugTexture(width: CGFloat, height: CGFloat) -> SKTexture {
        return createGenericRug(width: width, height: height, color: CartoonPalette.rugRed)
    }

    static func kitchenRugTexture(width: CGFloat, height: CGFloat) -> SKTexture {
        return createGenericRug(width: width, height: height, color: CartoonPalette.rugBlue)
    }

    static func bedroomRugTexture(width: CGFloat, height: CGFloat) -> SKTexture {
        return createGenericRug(width: width, height: height, color: CartoonPalette.rugGold)
    }

    static func officeRugTexture(width: CGFloat, height: CGFloat) -> SKTexture {
        return createGenericRug(width: width, height: height, color: CartoonPalette.rugBorder)
    }

    private static func createGenericRug(width: CGFloat, height: CGFloat, color: UIColor) -> SKTexture {
        let renderer = makeTransparentRenderer(width: width, height: height)
        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)

            let rect = CGRect(x: 4, y: 2, width: width-8, height: height-4)
            let path = roundedRectPath(rect: rect, cornerRadius: 6)

            ctx.setFillColor(color.cgColor)
            ctx.addPath(path)
            ctx.fillPath()
            drawOutline(ctx: ctx, path: path)

            // Fringe
            ctx.setStrokeColor(CartoonPalette.rugFringe.cgColor)
            ctx.setLineWidth(2)
            // Left
            ctx.move(to: CGPoint(x: 2, y: 4))
            ctx.addLine(to: CGPoint(x: 2, y: height-4))
            // Right
            ctx.move(to: CGPoint(x: width-2, y: 4))
            ctx.addLine(to: CGPoint(x: width-2, y: height-4))
            ctx.strokePath()
        }
        return finalize(image)
    }

    // MARK: - Plants

    static func pottedPlantTexture(width: CGFloat, height: CGFloat) -> SKTexture {
        let renderer = makeTransparentRenderer(width: width, height: height)
        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)

            // Pot
            let potH = height * 0.4
            let potRect = CGRect(x: width*0.2, y: height - potH, width: width*0.6, height: potH)
            ctx.setFillColor(CartoonPalette.potBrown.cgColor)
            let potPath = roundedRectPath(rect: potRect, cornerRadius: 4)
            ctx.addPath(potPath)
            ctx.fillPath()
            drawOutline(ctx: ctx, path: potPath)

            // Leaves
            ctx.setFillColor(CartoonPalette.leafGreen.cgColor)
            let leafR = width * 0.4
            ctx.fillEllipse(in: CGRect(x: 0, y: height*0.1, width: leafR, height: leafR*1.5))
            ctx.fillEllipse(in: CGRect(x: width*0.5, y: 0, width: leafR, height: leafR*1.5))
            ctx.fillEllipse(in: CGRect(x: width*0.2, y: height*0.2, width: leafR*1.2, height: leafR))
        }
        return finalize(image)
    }

    static func smallPlantTexture(width: CGFloat, height: CGFloat) -> SKTexture {
        return pottedPlantTexture(width: width, height: height)
    }

    // MARK: - Decor

    /// Wall poster texture: Indonesian flag (red top, white bottom) for living room.
    static func wallPosterTexture(width: CGFloat, height: CGFloat) -> SKTexture {
        let renderer = makeRenderer(width: width, height: height)
        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)

            let rect = CGRect(x: 0, y: 0, width: width, height: height)
            let halfH = height / 2

            // Indonesian flag (SpriteKit shows texture with y-up, so draw red in lower half = displays as top)
            // Red band (displays as top)
            ctx.setFillColor(CartoonPalette.indonesiaRed.cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: width, height: halfH))

            // White band (displays as bottom)
            ctx.setFillColor(CartoonPalette.indonesiaWhite.cgColor)
            ctx.fill(CGRect(x: 0, y: halfH, width: width, height: halfH))

            // Thin outline so it reads as a framed poster on the wall
            drawOutline(ctx: ctx, path: CGPath(rect: rect, transform: nil))
        }
        return finalize(image)
    }

    static func corkBoardTexture(width: CGFloat, height: CGFloat) -> SKTexture {
        let renderer = makeRenderer(width: width, height: height)
        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)

            // Board
            ctx.setFillColor(CartoonPalette.corkBase.cgColor)
            let rect = CGRect(x: 2, y: 2, width: width-4, height: height-4)
            ctx.fill(rect)
            drawOutline(ctx: ctx, path: CGPath(rect: rect, transform: nil))

            // Notes
            ctx.setFillColor(CartoonPalette.noteYellow.cgColor)
            ctx.fill(CGRect(x: 10, y: 10, width: 20, height: 20))
            ctx.setFillColor(CartoonPalette.notePink.cgColor)
            ctx.fill(CGRect(x: 40, y: 20, width: 20, height: 15))
        }
        return finalize(image)
    }

    static func wallShelfTexture(width: CGFloat, height: CGFloat) -> SKTexture {
        let renderer = makeTransparentRenderer(width: width, height: height)
        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)

            // Shelf board
            ctx.setFillColor(CartoonPalette.furnitureLight.cgColor)
            let rect = CGRect(x: 0, y: height-10, width: width, height: 10)
            ctx.fill(rect)
            drawOutline(ctx: ctx, path: CGPath(rect: rect, transform: nil))

            // Brackets
            ctx.move(to: CGPoint(x: 10, y: height))
            ctx.addLine(to: CGPoint(x: 10, y: height + 10)) // Visual only, drawing outside bounds? No, height is total
            // Actually shelf is usually at bottom
        }
        return finalize(image)
    }

    static func clockTexture(radius: CGFloat) -> SKTexture {
        let size = radius * 2
        let renderer = makeTransparentRenderer(width: size, height: size)
        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)

            ctx.setFillColor(UIColor.white.cgColor)
            ctx.fillEllipse(in: CGRect(x: 0, y: 0, width: size, height: size))
            drawOutline(ctx: ctx, path: CGPath(ellipseIn: CGRect(x: 0, y: 0, width: size, height: size), transform: nil))

            // Hands
            ctx.setStrokeColor(UIColor.black.cgColor)
            ctx.setLineWidth(2)
            ctx.move(to: CGPoint(x: radius, y: radius))
            ctx.addLine(to: CGPoint(x: radius, y: radius * 0.2))
            ctx.move(to: CGPoint(x: radius, y: radius))
            ctx.addLine(to: CGPoint(x: radius * 1.5, y: radius))
            ctx.strokePath()
        }
        return finalize(image)
    }

    static func alarmClockTexture(width: CGFloat, height: CGFloat) -> SKTexture {
        let renderer = makeTransparentRenderer(width: width, height: height)
        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)

            let rect = CGRect(x: 2, y: 4, width: width-4, height: height-4)
            ctx.setFillColor(CartoonPalette.rugRed.cgColor)
            ctx.fill(rect)
            drawOutline(ctx: ctx, path: CGPath(rect: rect, transform: nil))

            // Face
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.fillEllipse(in: CGRect(x: 4, y: 6, width: width-8, height: height-8))
        }
        return finalize(image)
    }

    // MARK: - Kitchen Items

    static func kitchenCounterTexture(width: CGFloat, height: CGFloat, colorType: KitchenColorType) -> SKTexture {
        let renderer = makeTransparentRenderer(width: width, height: height)
        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)

            let color = (colorType == .island) ? CartoonPalette.tileWhite : CartoonPalette.furnitureLight
            ctx.setFillColor(color.cgColor)
            let rect = CGRect(x: 0, y: 0, width: width, height: height)
            let path = roundedRectPath(rect: rect, cornerRadius: 4)
            ctx.addPath(path)
            ctx.fillPath()
            drawOutline(ctx: ctx, path: path)
        }
        return finalize(image)
    }

    static func cabinetTexture(width: CGFloat, height: CGFloat, type: CabinetType) -> SKTexture {
        let renderer = makeTransparentRenderer(width: width, height: height)
        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)

            ctx.setFillColor(CartoonPalette.furnitureLight.cgColor)
            let rect = CGRect(x: 0, y: 0, width: width, height: height)
            ctx.fill(rect)
            drawOutline(ctx: ctx, path: CGPath(rect: rect, transform: nil))

            // Door lines
            ctx.setStrokeColor(CartoonPalette.outline.withAlphaComponent(0.5).cgColor)
            ctx.move(to: CGPoint(x: width/2, y: 2))
            ctx.addLine(to: CGPoint(x: width/2, y: height-2))
            ctx.strokePath()
        }
        return finalize(image)
    }

    static func refrigeratorTexture(width: CGFloat, height: CGFloat) -> SKTexture {
        let renderer = makeTransparentRenderer(width: width, height: height)
        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)

            ctx.setFillColor(UIColor(white: 0.9, alpha: 1.0).cgColor)
            let rect = CGRect(x: 0, y: 0, width: width, height: height)
            let path = roundedRectPath(rect: rect, cornerRadius: 4)
            ctx.addPath(path)
            ctx.fillPath()
            drawOutline(ctx: ctx, path: path)

            // Freezer line
            ctx.move(to: CGPoint(x: 0, y: height*0.3))
            ctx.addLine(to: CGPoint(x: width, y: height*0.3))
            ctx.strokePath()
        }
        return finalize(image)
    }

    static func stoveTexture(width: CGFloat, height: CGFloat) -> SKTexture {
        let renderer = makeTransparentRenderer(width: width, height: height)
        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)

            ctx.setFillColor(UIColor(white: 0.2, alpha: 1.0).cgColor)
            let rect = CGRect(x: 0, y: 0, width: width, height: height)
            ctx.fill(rect)
            drawOutline(ctx: ctx, path: CGPath(rect: rect, transform: nil))

            // Window
            ctx.setFillColor(UIColor(white: 0.1, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: 10, y: 20, width: width-20, height: height-40))
        }
        return finalize(image)
    }

    static func microwaveTexture(width: CGFloat, height: CGFloat) -> SKTexture {
        let renderer = makeTransparentRenderer(width: width, height: height)
        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)

            ctx.setFillColor(UIColor.white.cgColor)
            let rect = CGRect(x: 0, y: 0, width: width, height: height)
            let path = roundedRectPath(rect: rect, cornerRadius: 4)
            ctx.addPath(path)
            ctx.fillPath()
            drawOutline(ctx: ctx, path: path)

            // Window
            ctx.setFillColor(UIColor.black.cgColor)
            ctx.fill(CGRect(x: 5, y: 5, width: width*0.6, height: height-10))
        }
        return finalize(image)
    }

    // MARK: - Office Items

    static func deskTexture(width: CGFloat, height: CGFloat) -> SKTexture {
        return tableTopTexture(width: width, height: height)
    }

    static func filingCabinetTexture(width: CGFloat, height: CGFloat, drawers: Int) -> SKTexture {
        let renderer = makeTransparentRenderer(width: width, height: height)
        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)

            ctx.setFillColor(CartoonPalette.furnitureLight.cgColor)
            let rect = CGRect(x: 0, y: 0, width: width, height: height)
            ctx.fill(rect)
            drawOutline(ctx: ctx, path: CGPath(rect: rect, transform: nil))

            let drawerH = height / CGFloat(drawers)
            for i in 0..<drawers {
                let y = CGFloat(i) * drawerH
                drawOutline(ctx: ctx, path: CGPath(rect: CGRect(x: 0, y: y, width: width, height: drawerH), transform: nil), lineWidth: 1)
                // Handle
                ctx.setFillColor(UIColor.gray.cgColor)
                ctx.fill(CGRect(x: width/2 - 10, y: y + drawerH/2 - 2, width: 20, height: 4))
            }
        }
        return finalize(image)
    }

    static func whiteboardTexture(width: CGFloat, height: CGFloat) -> SKTexture {
        let renderer = makeTransparentRenderer(width: width, height: height)
        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)

            // Frame
            ctx.setFillColor(UIColor.lightGray.cgColor)
            let rect = CGRect(x: 0, y: 0, width: width, height: height)
            ctx.fill(rect)
            drawOutline(ctx: ctx, path: CGPath(rect: rect, transform: nil))

            // White surface
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.fill(CGRect(x: 4, y: 4, width: width-8, height: height-8))

            // Scribbles
            ctx.setStrokeColor(UIColor.blue.cgColor)
            ctx.move(to: CGPoint(x: 10, y: 20))
            ctx.addLine(to: CGPoint(x: 30, y: 25))
            ctx.strokePath()
        }
        return finalize(image)
    }

    static func officeChairTexture(width: CGFloat, height: CGFloat) -> SKTexture {
        let renderer = makeTransparentRenderer(width: width, height: height)
        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)

            ctx.setFillColor(UIColor.black.cgColor)
            // Seat
            ctx.fill(CGRect(x: 0, y: height*0.4, width: width, height: 10))
            // Back
            ctx.fill(CGRect(x: 0, y: 0, width: 10, height: height*0.5))
            // Legs
            ctx.move(to: CGPoint(x: width/2, y: height*0.5))
            ctx.addLine(to: CGPoint(x: width/2, y: height))
            ctx.strokePath()
        }
        return finalize(image)
    }

    static func monitorTexture(width: CGFloat, height: CGFloat) -> SKTexture {
        let renderer = makeTransparentRenderer(width: width, height: height)
        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)

            ctx.setFillColor(UIColor.black.cgColor)
            // Screen
            ctx.fill(CGRect(x: 0, y: 0, width: width, height: height*0.8))
            // Stand
            ctx.fill(CGRect(x: width*0.4, y: height*0.8, width: width*0.2, height: height*0.2))
        }
        return finalize(image)
    }

    static func keyboardTexture(width: CGFloat, height: CGFloat) -> SKTexture {
        let renderer = makeTransparentRenderer(width: width, height: height)
        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)

            ctx.setFillColor(UIColor.darkGray.cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
        return finalize(image)
    }

    static func windowWithBlindsTexture(width: CGFloat, height: CGFloat) -> SKTexture {
        let renderer = makeTransparentRenderer(width: width, height: height)
        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)

            // Window bg
            ctx.setFillColor(CartoonPalette.skyTop.cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
            drawOutline(ctx: ctx, path: CGPath(rect: CGRect(x: 0, y: 0, width: width, height: height), transform: nil))

            // Blinds
            ctx.setFillColor(UIColor.white.cgColor)
            for y in stride(from: 0.0, to: height, by: 15.0) {
                ctx.fill(CGRect(x: 0, y: y, width: width, height: 12))
            }
        }
        return finalize(image)
    }

    // MARK: - Bedroom Items

    static func bedFrameTexture(width: CGFloat, height: CGFloat) -> SKTexture {
        let renderer = makeTransparentRenderer(width: width, height: height)
        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)

            ctx.setFillColor(CartoonPalette.furnitureDark.cgColor)
            let rect = CGRect(x: 0, y: 0, width: width, height: height)
            ctx.fill(rect)
            drawOutline(ctx: ctx, path: CGPath(rect: rect, transform: nil))
        }
        return finalize(image)
    }

    static func mattressTexture(width: CGFloat, height: CGFloat) -> SKTexture {
        let renderer = makeTransparentRenderer(width: width, height: height)
        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)

            ctx.setFillColor(UIColor.white.cgColor)
            let rect = CGRect(x: 0, y: 0, width: width, height: height)
            let path = roundedRectPath(rect: rect, cornerRadius: 5)
            ctx.addPath(path)
            ctx.fillPath()
            drawOutline(ctx: ctx, path: path)
        }
        return finalize(image)
    }

    static func pillowTexture(width: CGFloat, height: CGFloat) -> SKTexture {
        return mattressTexture(width: width, height: height) // Reuse
    }

    static func blanketTexture(width: CGFloat, height: CGFloat) -> SKTexture {
        let renderer = makeTransparentRenderer(width: width, height: height)
        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)

            ctx.setFillColor(CartoonPalette.rugBlue.cgColor)
            let rect = CGRect(x: 0, y: 0, width: width, height: height)
            let path = roundedRectPath(rect: rect, cornerRadius: 5)
            ctx.addPath(path)
            ctx.fillPath()
        }
        return finalize(image)
    }

    static func wardrobeTexture(width: CGFloat, height: CGFloat) -> SKTexture {
        let renderer = makeTransparentRenderer(width: width, height: height)
        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)

            ctx.setFillColor(CartoonPalette.furnitureDark.cgColor)
            let rect = CGRect(x: 0, y: 0, width: width, height: height)
            ctx.fill(rect)
            drawOutline(ctx: ctx, path: CGPath(rect: rect, transform: nil))

            // Doors
            ctx.move(to: CGPoint(x: width/2, y: 10))
            ctx.addLine(to: CGPoint(x: width/2, y: height-10))
            ctx.strokePath()
        }
        return finalize(image)
    }

    static func nightstandTexture(width: CGFloat, height: CGFloat) -> SKTexture {
        return cabinetTexture(width: width, height: height, type: .base)
    }

    static func bedsideLampTexture(width: CGFloat, height: CGFloat) -> SKTexture {
        let renderer = makeTransparentRenderer(width: width, height: height)
        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)

            // Base
            ctx.setFillColor(CartoonPalette.furnitureDark.cgColor)
            ctx.fill(CGRect(x: width*0.3, y: height*0.5, width: width*0.4, height: height*0.5))

            // Shade
            ctx.setFillColor(CartoonPalette.lampYellow.cgColor)
            let path = CGMutablePath()
            path.move(to: CGPoint(x: width*0.2, y: height*0.5))
            path.addLine(to: CGPoint(x: width*0.8, y: height*0.5))
            path.addLine(to: CGPoint(x: width*0.7, y: 0))
            path.addLine(to: CGPoint(x: width*0.3, y: 0))
            path.closeSubpath()
            ctx.addPath(path)
            ctx.fillPath()
            drawOutline(ctx: ctx, path: path)
        }
        return finalize(image)
    }

    static func windowWithCurtainsTexture(width: CGFloat, height: CGFloat) -> SKTexture {
        let renderer = makeTransparentRenderer(width: width, height: height)
        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)

            // Window bg
            ctx.setFillColor(CartoonPalette.skyTop.cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
            drawOutline(ctx: ctx, path: CGPath(rect: CGRect(x: 0, y: 0, width: width, height: height), transform: nil))

            // Curtains
            ctx.setFillColor(CartoonPalette.rugRed.cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: 20, height: height))
            ctx.fill(CGRect(x: width-20, y: 0, width: 20, height: height))
        }
        return finalize(image)
    }

    // MARK: - Debris & Icons

    static func bowlTexture(width: CGFloat, height: CGFloat) -> SKTexture {
        let renderer = makeTransparentRenderer(width: width, height: height)
        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)
            ctx.setFillColor(UIColor.orange.cgColor)
            ctx.fillEllipse(in: CGRect(x: 0, y: 0, width: width, height: height))
            drawOutline(ctx: ctx, path: CGPath(ellipseIn: CGRect(x: 0, y: 0, width: width, height: height), transform: nil))
        }
        return finalize(image)
    }

    static func plateTexture(radius: CGFloat) -> SKTexture {
        let size = radius * 2
        return bowlTexture(width: size, height: size)
    }

    static func glassTexture(width: CGFloat, height: CGFloat) -> SKTexture {
        let renderer = makeTransparentRenderer(width: width, height: height)
        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)
            ctx.setFillColor(UIColor(white: 0.9, alpha: 0.5).cgColor)
            let rect = CGRect(x: 0, y: 0, width: width, height: height)
            ctx.fill(rect)
            drawOutline(ctx: ctx, path: CGPath(rect: rect, transform: nil))
        }
        return finalize(image)
    }

    static func hangingPotTexture(radius: CGFloat) -> SKTexture {
        let size = radius * 2
        let renderer = makeTransparentRenderer(width: size, height: size)
        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)
            ctx.setFillColor(UIColor.darkGray.cgColor)
            ctx.fillEllipse(in: CGRect(x: 0, y: 0, width: size, height: size))
        }
        return finalize(image)
    }

    static func vaseTexture(width: CGFloat, height: CGFloat) -> SKTexture {
        let renderer = makeTransparentRenderer(width: width, height: height)
        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)
            ctx.setFillColor(CartoonPalette.terracotta.cgColor)
            let rect = CGRect(x: width*0.2, y: 0, width: width*0.6, height: height)
            ctx.fill(rect)
            drawOutline(ctx: ctx, path: CGPath(rect: rect, transform: nil))
        }
        return finalize(image)
    }

    static func smallBookTexture(width: CGFloat, height: CGFloat) -> SKTexture {
        let renderer = makeTransparentRenderer(width: width, height: height)
        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)
            ctx.setFillColor(CartoonPalette.bookRed.cgColor)
            let rect = CGRect(x: 0, y: 0, width: width, height: height)
            ctx.fill(rect)
            drawOutline(ctx: ctx, path: CGPath(rect: rect, transform: nil))
        }
        return finalize(image)
    }

    static func scatteredBookTexture(color: UIColor, width: CGFloat, height: CGFloat) -> SKTexture {
        let renderer = makeTransparentRenderer(width: width, height: height)
        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)
            ctx.setFillColor(color.cgColor)
            let rect = CGRect(x: 0, y: 0, width: width, height: height)
            ctx.fill(rect)
            drawOutline(ctx: ctx, path: CGPath(rect: rect, transform: nil))

            // Pages
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.fill(CGRect(x: 2, y: 2, width: width-4, height: height-4))
        }
        return finalize(image)
    }

    static func dustParticleTexture(size: CGFloat) -> SKTexture {
        let renderer = makeTransparentRenderer(width: size, height: size)
        let image = renderer.image { context in
            let ctx = context.cgContext
            ctx.setFillColor(UIColor(white: 0.8, alpha: 0.6).cgColor)
            ctx.fillEllipse(in: CGRect(x: 0, y: 0, width: size, height: size))
        }
        return finalize(image)
    }

    static func glassShardTexture() -> SKTexture {
        let renderer = makeTransparentRenderer(width: 10, height: 10)
        let image = renderer.image { context in
            let ctx = context.cgContext
            ctx.setFillColor(UIColor(white: 0.9, alpha: 0.7).cgColor)
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 5, y: 0))
            path.addLine(to: CGPoint(x: 10, y: 5))
            path.addLine(to: CGPoint(x: 5, y: 10))
            path.addLine(to: CGPoint(x: 0, y: 5))
            path.closeSubpath()
            ctx.addPath(path)
            ctx.fillPath()
        }
        return finalize(image)
    }

    static func woodDebrisTexture() -> SKTexture {
        let renderer = makeTransparentRenderer(width: 8, height: 4)
        let image = renderer.image { context in
            let ctx = context.cgContext
            ctx.setFillColor(CartoonPalette.furnitureDark.cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: 8, height: 4))
        }
        return finalize(image)
    }

    static func gasValveIcon() -> SKTexture {
        if let img = loadBundleImage(named: "zone_gas") {
            return SKTexture(image: img)
        }
        let renderer = makeTransparentRenderer(width: 120, height: 140)
        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)

            let center = CGPoint(x: 60, y: 55)
            let wheelRadius: CGFloat = 45

            // MARK: - Pipe Connection (drawn first, behind wheel)
            let pipeRect = CGRect(x: 52, y: 85, width: 16, height: 40)
            let pipePath = CGPath(rect: pipeRect, transform: nil)

            // Pipe gradient (vertical metallic)
            ctx.saveGState()
            ctx.addPath(pipePath)
            ctx.clip()
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let pipeColors = [
                SKColor(white: 0.25, alpha: 1.0).cgColor,
                SKColor(white: 0.55, alpha: 1.0).cgColor,
                SKColor(white: 0.35, alpha: 1.0).cgColor,
                SKColor(white: 0.2, alpha: 1.0).cgColor
            ] as CFArray
            if let pipeGradient = CGGradient(colorsSpace: colorSpace, colors: pipeColors, locations: [0.0, 0.4, 0.7, 1.0]) {
                ctx.drawLinearGradient(pipeGradient,
                    start: CGPoint(x: pipeRect.minX, y: pipeRect.minY),
                    end: CGPoint(x: pipeRect.maxX, y: pipeRect.minY),
                    options: [])
            }
            ctx.restoreGState()

            // Pipe outline
            ctx.setStrokeColor(SKColor(white: 0.15, alpha: 1.0).cgColor)
            ctx.setLineWidth(2)
            ctx.addPath(pipePath)
            ctx.strokePath()

            // MARK: - Valve Base Flange
            let flangeRect = CGRect(x: 45, y: 80, width: 30, height: 12)
            ctx.setFillColor(SKColor(white: 0.3, alpha: 1.0).cgColor)
            ctx.fillEllipse(in: flangeRect)
            ctx.setStrokeColor(SKColor(white: 0.15, alpha: 1.0).cgColor)
            ctx.setLineWidth(2)
            ctx.addEllipse(in: flangeRect)
            ctx.strokePath()

            // Flange bolts
            for i in 0..<3 {
                let boltX = 48 + CGFloat(i) * 12
                ctx.setFillColor(SKColor(white: 0.5, alpha: 1.0).cgColor)
                ctx.fillEllipse(in: CGRect(x: boltX - 3, y: 82, width: 6, height: 8))
            }

            // MARK: - Outer Wheel Rim (3D beveled effect with radial gradient)
            let wheelRect = CGRect(x: center.x - wheelRadius, y: center.y - wheelRadius,
                                   width: wheelRadius * 2, height: wheelRadius * 2)

            // Outer rim shadow
            ctx.setFillColor(SKColor(white: 0, alpha: 0.3).cgColor)
            ctx.fillEllipse(in: wheelRect.offsetBy(dx: 2, dy: 3))

            // Main wheel rim with radial gradient
            ctx.saveGState()
            ctx.addEllipse(in: wheelRect)
            ctx.clip()
            let rimColors = [
                SKColor(red: 0.95, green: 0.25, blue: 0.15, alpha: 1.0).cgColor,  // Bright red outer
                SKColor(red: 0.8, green: 0.15, blue: 0.08, alpha: 1.0).cgColor,   // Medium red
                SKColor(red: 0.5, green: 0.08, blue: 0.04, alpha: 1.0).cgColor    // Dark red inner
            ] as CFArray
            if let rimGradient = CGGradient(colorsSpace: colorSpace, colors: rimColors, locations: [0.0, 0.6, 1.0]) {
                ctx.drawRadialGradient(rimGradient,
                    startCenter: center, startRadius: wheelRadius * 0.3,
                    endCenter: center, endRadius: wheelRadius,
                    options: [])
            }
            ctx.restoreGState()

            // Rim outline
            ctx.setStrokeColor(SKColor(red: 0.3, green: 0.05, blue: 0.02, alpha: 1.0).cgColor)
            ctx.setLineWidth(3)
            ctx.addEllipse(in: wheelRect)
            ctx.strokePath()

            // Inner rim highlight (metallic sheen)
            ctx.setStrokeColor(SKColor(white: 0.4, alpha: 0.6).cgColor)
            ctx.setLineWidth(2)
            ctx.addArc(center: center, radius: wheelRadius - 4,
                       startAngle: -.pi * 0.8, endAngle: -.pi * 0.2, clockwise: false)
            ctx.strokePath()

            // MARK: - 4 Tapered Spokes with depth shading
            let innerRadius: CGFloat = 14
         

            for i in 0..<4 {
                let angle = CGFloat(i) * .pi / 2
            

                // Spoke path (tapered from center to rim)
                let spokePath = CGMutablePath()
                let innerStart = CGPoint(x: center.x + cos(angle - 0.15) * innerRadius,
                                         y: center.y + sin(angle - 0.15) * innerRadius)
                let innerEnd = CGPoint(x: center.x + cos(angle + 0.15) * innerRadius,
                                       y: center.y + sin(angle + 0.15) * innerRadius)
                let outerStart = CGPoint(x: center.x + cos(angle - 0.08) * (wheelRadius - 6),
                                         y: center.y + sin(angle - 0.08) * (wheelRadius - 6))
               
                                 
                spokePath.move(to: innerStart)
                spokePath.addLine(to: outerStart)
                spokePath.addArc(center: center, radius: wheelRadius - 6,
                                 startAngle: angle - 0.08, endAngle: angle + 0.08, clockwise: false)
                spokePath.addLine(to: innerEnd)
                spokePath.addArc(center: center, radius: innerRadius,
                                 startAngle: angle + 0.15, endAngle: angle - 0.15, clockwise: true)
                spokePath.closeSubpath()

                // Spoke gradient (darker near center, lighter at edges)
                ctx.saveGState()
                ctx.addPath(spokePath)
                ctx.clip()
                let spokeColors = [
                    SKColor(red: 0.6, green: 0.1, blue: 0.05, alpha: 1.0).cgColor,
                    SKColor(red: 0.85, green: 0.2, blue: 0.1, alpha: 1.0).cgColor
                ] as CFArray
                if let spokeGradient = CGGradient(colorsSpace: colorSpace, colors: spokeColors, locations: [0.0, 1.0]) {
                    let gradientStart = CGPoint(x: center.x + cos(angle) * innerRadius,
                                                y: center.y + sin(angle) * innerRadius)
                    let gradientEnd = CGPoint(x: center.x + cos(angle) * wheelRadius,
                                              y: center.y + sin(angle) * wheelRadius)
                    ctx.drawLinearGradient(spokeGradient, start: gradientStart, end: gradientEnd, options: [])
                }
                ctx.restoreGState()

                // Spoke outline
                ctx.setStrokeColor(SKColor(red: 0.4, green: 0.08, blue: 0.04, alpha: 1.0).cgColor)
                ctx.setLineWidth(1.5)
                ctx.addPath(spokePath)
                ctx.strokePath()
            }

            // MARK: - Center Hub (metallic cylindrical)
            let hubRadius: CGFloat = 12
            let hubRect = CGRect(x: center.x - hubRadius, y: center.y - hubRadius,
                                 width: hubRadius * 2, height: hubRadius * 2)

            // Hub shadow
            ctx.setFillColor(SKColor(white: 0, alpha: 0.4).cgColor)
            ctx.fillEllipse(in: hubRect.offsetBy(dx: 1, dy: 2))

            // Hub metallic gradient
            ctx.saveGState()
            ctx.addEllipse(in: hubRect)
            ctx.clip()
            let hubColors = [
                SKColor(white: 0.9, alpha: 1.0).cgColor,
                SKColor(white: 0.5, alpha: 1.0).cgColor,
                SKColor(white: 0.3, alpha: 1.0).cgColor,
                SKColor(white: 0.5, alpha: 1.0).cgColor
            ] as CFArray
            if let hubGradient = CGGradient(colorsSpace: colorSpace, colors: hubColors,
                                            locations: [0.0, 0.3, 0.7, 1.0]) {
                ctx.drawLinearGradient(hubGradient,
                    start: CGPoint(x: hubRect.minX, y: hubRect.minY),
                    end: CGPoint(x: hubRect.maxX, y: hubRect.minY),
                    options: [])
            }
            ctx.restoreGState()

            // Hub outline
            ctx.setStrokeColor(SKColor(white: 0.2, alpha: 1.0).cgColor)
            ctx.setLineWidth(2)
            ctx.addEllipse(in: hubRect)
            ctx.strokePath()

            // Center bolt
            ctx.setFillColor(SKColor(white: 0.25, alpha: 1.0).cgColor)
            ctx.fillEllipse(in: CGRect(x: center.x - 4, y: center.y - 4, width: 8, height: 8))
            // Bolt hexagon hint
            ctx.setStrokeColor(SKColor(white: 0.15, alpha: 1.0).cgColor)
            ctx.setLineWidth(1)
            ctx.addEllipse(in: CGRect(x: center.x - 3, y: center.y - 3, width: 6, height: 6))
            ctx.strokePath()

            // MARK: - Handle Grip on Rim
            let handleAngle: CGFloat = -.pi / 4  // Upper right
            let handleCenter = CGPoint(x: center.x + cos(handleAngle) * (wheelRadius - 8),
                                       y: center.y + sin(handleAngle) * (wheelRadius - 8))
            let handleRect = CGRect(x: handleCenter.x - 5, y: handleCenter.y - 8, width: 10, height: 16)

            // Handle gradient
            ctx.saveGState()
            ctx.addEllipse(in: handleRect)
            ctx.clip()
            let handleColors = [
                SKColor(red: 0.3, green: 0.3, blue: 0.35, alpha: 1.0).cgColor,
                SKColor(red: 0.6, green: 0.6, blue: 0.65, alpha: 1.0).cgColor,
                SKColor(red: 0.25, green: 0.25, blue: 0.3, alpha: 1.0).cgColor
            ] as CFArray
            if let handleGradient = CGGradient(colorsSpace: colorSpace, colors: handleColors, locations: [0.0, 0.5, 1.0]) {
                ctx.drawLinearGradient(handleGradient,
                    start: CGPoint(x: handleRect.minX, y: handleRect.minY),
                    end: CGPoint(x: handleRect.maxX, y: handleRect.minY),
                    options: [])
            }
            ctx.restoreGState()

            ctx.setStrokeColor(SKColor(white: 0.15, alpha: 1.0).cgColor)
            ctx.setLineWidth(1.5)
            ctx.addEllipse(in: handleRect)
            ctx.strokePath()

            // Handle highlight
            ctx.setFillColor(SKColor(white: 0.8, alpha: 0.5).cgColor)
            ctx.fillEllipse(in: CGRect(x: handleCenter.x - 2, y: handleCenter.y - 5, width: 4, height: 6))

            // MARK: - Direction Arrow (clockwise turn indicator)
            let arrowRadius: CGFloat = wheelRadius + 18
            let arrowStartAngle: CGFloat = -.pi * 0.6
            let arrowEndAngle: CGFloat = -.pi * 0.3

            ctx.setStrokeColor(SKColor(white: 0.9, alpha: 0.8).cgColor)
            ctx.setLineWidth(2.5)
            ctx.setLineCap(.round)
            ctx.addArc(center: center, radius: arrowRadius,
                       startAngle: arrowStartAngle, endAngle: arrowEndAngle, clockwise: false)
            ctx.strokePath()

            // Arrow head
            let arrowTipAngle = arrowEndAngle
            let arrowTip = CGPoint(x: center.x + cos(arrowTipAngle) * arrowRadius,
                                   y: center.y + sin(arrowTipAngle) * arrowRadius)
            let arrowHeadPath = CGMutablePath()
            arrowHeadPath.move(to: arrowTip)
            arrowHeadPath.addLine(to: CGPoint(x: arrowTip.x - 8, y: arrowTip.y - 5))
            arrowHeadPath.move(to: arrowTip)
            arrowHeadPath.addLine(to: CGPoint(x: arrowTip.x - 5, y: arrowTip.y + 8))
            ctx.setStrokeColor(SKColor(white: 0.9, alpha: 0.8).cgColor)
            ctx.setLineWidth(2.5)
            ctx.setLineCap(.round)
            ctx.addPath(arrowHeadPath)
            ctx.strokePath()

            // MARK: - Metallic Highlights (specular)
            // Top-left rim highlight
            ctx.setFillColor(SKColor(white: 1.0, alpha: 0.25).cgColor)
            ctx.fillEllipse(in: CGRect(x: center.x - 25, y: center.y - 32, width: 18, height: 10))

            // Lower-right subtle highlight
            ctx.setFillColor(SKColor(white: 1.0, alpha: 0.15).cgColor)
            ctx.fillEllipse(in: CGRect(x: center.x + 15, y: center.y + 22, width: 12, height: 8))

            // Hub top highlight
            ctx.setFillColor(SKColor(white: 1.0, alpha: 0.6).cgColor)
            ctx.fillEllipse(in: CGRect(x: center.x - 3, y: center.y - 8, width: 6, height: 4))
        }
        return finalize(image)
    }

    static func exitSignIcon() -> SKTexture {
        if let img = loadBundleImage(named: "zone_exit") {
            return SKTexture(image: img)
        }
        let renderer = makeTransparentRenderer(width: 50, height: 30)
        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)
            ctx.setFillColor(UIColor.green.cgColor)
            let rect = CGRect(x: 0, y: 0, width: 50, height: 30)
            ctx.fill(rect)
            drawOutline(ctx: ctx, path: CGPath(rect: rect, transform: nil))
        }
        return finalize(image)
    }

    // MARK: - Mini-Game Animation Textures

    /// Two hands gripping opposite sides of a valve wheel, sized to overlay the valve icon (~80×94)
    static func playerHandsOnValve() -> SKTexture {
        let width: CGFloat = 80
        let height: CGFloat = 94
        let renderer = makeTransparentRenderer(width: width, height: height)
        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)

            let skinColor = UIColor(red: 0.96, green: 0.87, blue: 0.71, alpha: 1.0) // #F5DFB0
            let outlineColor = UIColor(red: 0.55, green: 0.38, blue: 0.22, alpha: 1.0)

            // Draw a hand shape at a given center position, mirrored if needed
            func drawHand(centerX: CGFloat, centerY: CGFloat, mirror: Bool) {
                ctx.saveGState()
                ctx.translateBy(x: centerX, y: centerY)
                if mirror { ctx.scaleBy(x: -1, y: 1) }

                let hand = CGMutablePath()
                // Palm
                hand.move(to: CGPoint(x: -8, y: -10))
                hand.addCurve(to: CGPoint(x: -10, y: 10),
                              control1: CGPoint(x: -12, y: -5),
                              control2: CGPoint(x: -13, y: 5))
                // Finger bumps (4 fingers)
                hand.addCurve(to: CGPoint(x: -6, y: 14),
                              control1: CGPoint(x: -10, y: 12),
                              control2: CGPoint(x: -8, y: 14))
                hand.addCurve(to: CGPoint(x: -2, y: 13),
                              control1: CGPoint(x: -4, y: 14),
                              control2: CGPoint(x: -3, y: 14))
                hand.addCurve(to: CGPoint(x: 2, y: 14),
                              control1: CGPoint(x: -1, y: 14),
                              control2: CGPoint(x: 1, y: 14))
                hand.addCurve(to: CGPoint(x: 6, y: 13),
                              control1: CGPoint(x: 3, y: 14),
                              control2: CGPoint(x: 5, y: 14))
                hand.addCurve(to: CGPoint(x: 10, y: 12),
                              control1: CGPoint(x: 7, y: 14),
                              control2: CGPoint(x: 9, y: 13))
                // Back of hand
                hand.addCurve(to: CGPoint(x: 8, y: -10),
                              control1: CGPoint(x: 12, y: 5),
                              control2: CGPoint(x: 11, y: -5))
                hand.closeSubpath()

                ctx.setFillColor(skinColor.cgColor)
                ctx.addPath(hand)
                ctx.fillPath()

                ctx.setStrokeColor(outlineColor.cgColor)
                ctx.setLineWidth(1.5)
                ctx.setLineCap(.round)
                ctx.setLineJoin(.round)
                ctx.addPath(hand)
                ctx.strokePath()

                // Knuckle lines
                ctx.setStrokeColor(outlineColor.withAlphaComponent(0.3).cgColor)
                ctx.setLineWidth(0.8)
                for i in 0..<3 {
                    let kx = CGFloat(-4 + i * 4)
                    ctx.move(to: CGPoint(x: kx, y: 8))
                    ctx.addLine(to: CGPoint(x: kx, y: 10))
                }
                ctx.strokePath()

                ctx.restoreGState()
            }

            // Left hand (gripping left side of valve)
            drawHand(centerX: 14, centerY: height / 2, mirror: false)
            // Right hand (gripping right side of valve, mirrored)
            drawHand(centerX: width - 14, centerY: height / 2, mirror: true)
        }
        return finalize(image)
    }

    /// Suturing needle with trailing thread for the injury check mini-game
    static func sutureNeedleTexture() -> SKTexture {
        let width: CGFloat = 24
        let height: CGFloat = 14
        let renderer = makeTransparentRenderer(width: width, height: height)
        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)

            // Curved needle (metallic gray arc)
            let needlePath = CGMutablePath()
            needlePath.move(to: CGPoint(x: 4, y: 10))
            needlePath.addCurve(to: CGPoint(x: 20, y: 4),
                                control1: CGPoint(x: 8, y: 2),
                                control2: CGPoint(x: 16, y: 1))
            // Needle tip taper
            needlePath.addLine(to: CGPoint(x: 22, y: 5))
            needlePath.addCurve(to: CGPoint(x: 4, y: 10),
                                control1: CGPoint(x: 16, y: 4),
                                control2: CGPoint(x: 8, y: 5))
            needlePath.closeSubpath()

            // Metallic fill
            ctx.setFillColor(UIColor(red: 0.75, green: 0.78, blue: 0.82, alpha: 1.0).cgColor)
            ctx.addPath(needlePath)
            ctx.fillPath()

            // Needle outline
            ctx.setStrokeColor(UIColor(red: 0.4, green: 0.42, blue: 0.45, alpha: 1.0).cgColor)
            ctx.setLineWidth(1.0)
            ctx.addPath(needlePath)
            ctx.strokePath()

            // Highlight on needle
            ctx.setStrokeColor(UIColor(white: 1.0, alpha: 0.5).cgColor)
            ctx.setLineWidth(0.8)
            ctx.move(to: CGPoint(x: 8, y: 6))
            ctx.addCurve(to: CGPoint(x: 18, y: 3),
                         control1: CGPoint(x: 12, y: 3),
                         control2: CGPoint(x: 15, y: 2))
            ctx.strokePath()

            // Thread trailing from needle eye (at the blunt end)
            ctx.setStrokeColor(UIColor(red: 0.6, green: 0.15, blue: 0.1, alpha: 0.9).cgColor)
            ctx.setLineWidth(1.2)
            ctx.setLineCap(.round)
            ctx.move(to: CGPoint(x: 4, y: 10))
            ctx.addCurve(to: CGPoint(x: 0, y: 12),
                         control1: CGPoint(x: 2, y: 11),
                         control2: CGPoint(x: 1, y: 12))
            ctx.strokePath()
        }
        return finalize(image)
    }

    static func firstAidIcon() -> SKTexture {
        if let img = loadBundleImage(named: "zone_first_aid") {
            return SKTexture(image: img)
        }
        // Larger canvas for finer detail, displayed at 50x50
        let canvasSize: CGFloat = 100
        let renderer = makeTransparentRenderer(width: canvasSize, height: canvasSize)
        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)

            let bagWidth: CGFloat = 80
            let bagHeight: CGFloat = 60
            let bagX = (canvasSize - bagWidth) / 2
            let bagY = (canvasSize - bagHeight) / 2 - 5
            let cornerRadius: CGFloat = 8

            // Shadow beneath the kit
            ctx.setFillColor(UIColor.black.withAlphaComponent(0.2).cgColor)
            let shadowRect = CGRect(x: bagX + 4, y: bagY - 4, width: bagWidth, height: bagHeight)
            let shadowPath = CGPath(roundedRect: shadowRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
            ctx.addPath(shadowPath)
            ctx.fillPath()

            // Main bag body (3D depth - darker side)
            let depthOffset: CGFloat = 6
            ctx.setFillColor(UIColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1.0).cgColor)
            let depthRect = CGRect(x: bagX + depthOffset, y: bagY - depthOffset, width: bagWidth, height: bagHeight)
            let depthPath = CGPath(roundedRect: depthRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
            ctx.addPath(depthPath)
            ctx.fillPath()

            // Main bag body (front face) - cream/white color with gradient
            let bagRect = CGRect(x: bagX, y: bagY, width: bagWidth, height: bagHeight)
            let bagPath = CGPath(roundedRect: bagRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

            // Create gradient for bag body
            let bagGradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor(red: 0.98, green: 0.98, blue: 0.96, alpha: 1.0).cgColor,  // Top - lighter
                    UIColor(red: 0.92, green: 0.92, blue: 0.90, alpha: 1.0).cgColor   // Bottom - slightly darker
                ] as CFArray,
                locations: [0.0, 1.0]
            )!
            ctx.addPath(bagPath)
            ctx.clip()
            ctx.drawLinearGradient(bagGradient, start: CGPoint(x: 0, y: bagY + bagHeight), end: CGPoint(x: 0, y: bagY), options: [])
            ctx.resetClip()

            // Draw bag outline
            ctx.setStrokeColor(UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0).cgColor)
            ctx.setLineWidth(1.5)
            ctx.addPath(bagPath)
            ctx.strokePath()

            // Side pockets
            let pocketWidth: CGFloat = 12
            let pocketHeight: CGFloat = 30
            let leftPocketRect = CGRect(x: bagX - pocketWidth + 4, y: bagY + 15, width: pocketWidth, height: pocketHeight)
            let rightPocketRect = CGRect(x: bagX + bagWidth - 4, y: bagY + 15, width: pocketWidth, height: pocketHeight)

            ctx.setFillColor(UIColor(red: 0.90, green: 0.90, blue: 0.88, alpha: 1.0).cgColor)
            let leftPocketPath = CGPath(roundedRect: leftPocketRect, cornerWidth: 3, cornerHeight: 3, transform: nil)
            let rightPocketPath = CGPath(roundedRect: rightPocketRect, cornerWidth: 3, cornerHeight: 3, transform: nil)
            ctx.addPath(leftPocketPath)
            ctx.addPath(rightPocketPath)
            ctx.fillPath()

            // Pocket outlines
            ctx.setStrokeColor(UIColor(red: 0.65, green: 0.65, blue: 0.65, alpha: 1.0).cgColor)
            ctx.setLineWidth(1)
            ctx.addPath(leftPocketPath)
            ctx.strokePath()
            ctx.addPath(rightPocketPath)
            ctx.strokePath()

            // Zipper line across top
            ctx.setStrokeColor(UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0).cgColor)
            ctx.setLineWidth(2)
            ctx.move(to: CGPoint(x: bagX + 8, y: bagY + bagHeight - 8))
            ctx.addLine(to: CGPoint(x: bagX + bagWidth - 8, y: bagY + bagHeight - 8))
            ctx.strokePath()

            // Zipper teeth detail
            ctx.setStrokeColor(UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0).cgColor)
            ctx.setLineWidth(1)
            for i in 0..<12 {
                let x = bagX + 12 + CGFloat(i) * 5
                ctx.move(to: CGPoint(x: x, y: bagY + bagHeight - 10))
                ctx.addLine(to: CGPoint(x: x, y: bagY + bagHeight - 6))
            }
            ctx.strokePath()

            // Handle on top
            let handleWidth: CGFloat = 30
            let handleHeight: CGFloat = 12
            let handleX = bagX + (bagWidth - handleWidth) / 2
            let handleY = bagY + bagHeight - 4

            ctx.setFillColor(UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0).cgColor)
            let handlePath = CGPath(roundedRect: CGRect(x: handleX, y: handleY, width: handleWidth, height: handleHeight),
                                    cornerWidth: 4, cornerHeight: 4, transform: nil)
            ctx.addPath(handlePath)
            ctx.fillPath()

            // Handle inner grip
            ctx.setFillColor(UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0).cgColor)
            let gripPath = CGPath(roundedRect: CGRect(x: handleX + 4, y: handleY + 3, width: handleWidth - 8, height: handleHeight - 6),
                                  cornerWidth: 2, cornerHeight: 2, transform: nil)
            ctx.addPath(gripPath)
            ctx.fillPath()

            // Red cross emblem background (circle)
            let crossCenterX = bagX + bagWidth / 2
            let crossCenterY = bagY + bagHeight / 2 - 3
            let crossCircleRadius: CGFloat = 18

            ctx.setFillColor(UIColor(red: 0.9, green: 0.15, blue: 0.1, alpha: 1.0).cgColor)
            ctx.addArc(center: CGPoint(x: crossCenterX, y: crossCenterY), radius: crossCircleRadius,
                       startAngle: 0, endAngle: .pi * 2, clockwise: false)
            ctx.fillPath()

            // Cross 3D bevel effect (darker edge)
            ctx.setFillColor(UIColor(red: 0.7, green: 0.1, blue: 0.08, alpha: 1.0).cgColor)
            let bevelPath = CGMutablePath()
            bevelPath.move(to: CGPoint(x: crossCenterX + crossCircleRadius, y: crossCenterY))
            bevelPath.addArc(center: CGPoint(x: crossCenterX, y: crossCenterY), radius: crossCircleRadius,
                             startAngle: 0, endAngle: .pi * 2, clockwise: false)
            bevelPath.closeSubpath()
            ctx.addPath(bevelPath)
            ctx.fillPath()

            // Main cross circle again (slightly smaller for bevel effect)
            ctx.setFillColor(UIColor(red: 0.92, green: 0.18, blue: 0.12, alpha: 1.0).cgColor)
            ctx.addArc(center: CGPoint(x: crossCenterX, y: crossCenterY), radius: crossCircleRadius - 1.5,
                       startAngle: 0, endAngle: .pi * 2, clockwise: false)
            ctx.fillPath()

            // White cross bars
            ctx.setFillColor(UIColor.white.cgColor)
            let crossBarWidth: CGFloat = 8
            let crossBarLength: CGFloat = 22

            // Vertical bar
            ctx.fill(CGRect(x: crossCenterX - crossBarWidth/2, y: crossCenterY - crossBarLength/2,
                            width: crossBarWidth, height: crossBarLength))
            // Horizontal bar
            ctx.fill(CGRect(x: crossCenterX - crossBarLength/2, y: crossCenterY - crossBarWidth/2,
                            width: crossBarLength, height: crossBarWidth))

            // Cross highlight (gloss effect)
            ctx.setFillColor(UIColor.white.withAlphaComponent(0.4).cgColor)
            ctx.fill(CGRect(x: crossCenterX - crossBarWidth/2 + 2, y: crossCenterY - crossBarLength/2 + 2,
                            width: 3, height: crossBarLength - 4))
            ctx.fill(CGRect(x: crossCenterX - crossBarLength/2 + 2, y: crossCenterY - crossBarWidth/2 + 2,
                            width: crossBarLength - 4, height: 3))

            // Bag gloss highlights (specular)
            ctx.setFillColor(UIColor.white.withAlphaComponent(0.3).cgColor)
            let highlightPath = CGPath(roundedRect: CGRect(x: bagX + 8, y: bagY + bagHeight - 15, width: 25, height: 8),
                                       cornerWidth: 4, cornerHeight: 4, transform: nil)
            ctx.addPath(highlightPath)
            ctx.fillPath()

            // Second smaller highlight
            ctx.setFillColor(UIColor.white.withAlphaComponent(0.2).cgColor)
            let highlight2Path = CGPath(roundedRect: CGRect(x: bagX + bagWidth - 35, y: bagY + 12, width: 20, height: 5),
                                        cornerWidth: 2.5, cornerHeight: 2.5, transform: nil)
            ctx.addPath(highlight2Path)
            ctx.fillPath()

            // Small medical plus sign badge on corner
            ctx.setFillColor(UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0).cgColor)
            let badgeSize: CGFloat = 12
            let badgeX = bagX + bagWidth - 18
            let badgeY = bagY + 8
            ctx.addArc(center: CGPoint(x: badgeX + badgeSize/2, y: badgeY + badgeSize/2), radius: badgeSize/2,
                       startAngle: 0, endAngle: .pi * 2, clockwise: false)
            ctx.fillPath()

            ctx.setFillColor(UIColor.white.cgColor)
            let plusWidth: CGFloat = 2
            let plusLength: CGFloat = 6
            ctx.fill(CGRect(x: badgeX + badgeSize/2 - plusWidth/2, y: badgeY + 3,
                            width: plusWidth, height: plusLength))
            ctx.fill(CGRect(x: badgeX + 3, y: badgeY + badgeSize/2 - plusWidth/2,
                            width: plusLength, height: plusWidth))
        }
        return finalize(image)
    }
}
