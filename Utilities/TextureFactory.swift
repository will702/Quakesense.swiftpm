import SpriteKit
import UIKit

// MARK: - Cartoon Style Color Palette

enum CartoonPalette {
    // Outline & shadows
    static let outline = UIColor(red: 0.15, green: 0.12, blue: 0.10, alpha: 1.0)
    static let shadowDark = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.20)
    static let highlightWhite = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.35)

    // Walls — cheerful pastel blue
    static let wallBase = UIColor(red: 0.83, green: 0.90, blue: 0.95, alpha: 1.0)        // #D4E6F1
    static let wallStripe = UIColor(red: 0.78, green: 0.86, blue: 0.92, alpha: 1.0)
    static let wallMotif = UIColor(red: 0.68, green: 0.80, blue: 0.90, alpha: 0.45)
    static let wallPastelLight = UIColor(red: 0.90, green: 0.94, blue: 0.97, alpha: 1.0) // lighter below rail
    static let chairRail = UIColor(red: 0.92, green: 0.90, blue: 0.85, alpha: 1.0)       // warm cream divider

    // Rug — warm woven
    static let rugRed = UIColor(red: 0.78, green: 0.18, blue: 0.15, alpha: 1.0)
    static let rugGold = UIColor(red: 0.88, green: 0.72, blue: 0.20, alpha: 1.0)
    static let rugBlue = UIColor(red: 0.20, green: 0.35, blue: 0.65, alpha: 1.0)
    static let rugFringe = UIColor(red: 0.85, green: 0.78, blue: 0.60, alpha: 1.0)
    static let rugBorder = UIColor(red: 0.60, green: 0.12, blue: 0.10, alpha: 1.0)

    // Plant
    static let leafGreen = UIColor(red: 0.28, green: 0.72, blue: 0.30, alpha: 1.0)
    static let leafDark = UIColor(red: 0.18, green: 0.52, blue: 0.20, alpha: 1.0)
    static let flowerPink = UIColor(red: 0.95, green: 0.45, blue: 0.55, alpha: 1.0)
    static let potBrown = UIColor(red: 0.72, green: 0.42, blue: 0.22, alpha: 1.0)
    static let potDark = UIColor(red: 0.55, green: 0.30, blue: 0.15, alpha: 1.0)

    // Poster (and Indonesian flag for living room wall)
    static let posterBackground = UIColor(red: 1.0, green: 0.98, blue: 0.90, alpha: 1.0)
    static let posterBorder = UIColor(red: 0.90, green: 0.30, blue: 0.15, alpha: 1.0)
    static let posterText = UIColor(red: 0.20, green: 0.20, blue: 0.25, alpha: 1.0)
    /// Indonesian flag: red (top band)
    static let indonesiaRed = UIColor(red: 0.89, green: 0.0, blue: 0.09, alpha: 1.0)
    /// Indonesian flag: white (bottom band)
    static let indonesiaWhite = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)

    // Cork board
    static let corkBase = UIColor(red: 0.82, green: 0.68, blue: 0.48, alpha: 1.0)
    static let corkDark = UIColor(red: 0.72, green: 0.58, blue: 0.38, alpha: 1.0)
    static let pinRed = UIColor(red: 0.92, green: 0.20, blue: 0.15, alpha: 1.0)
    static let pinBlue = UIColor(red: 0.20, green: 0.45, blue: 0.85, alpha: 1.0)
    static let pinGreen = UIColor(red: 0.20, green: 0.70, blue: 0.30, alpha: 1.0)
    static let noteYellow = UIColor(red: 1.0, green: 0.95, blue: 0.60, alpha: 1.0)
    static let notePink = UIColor(red: 1.0, green: 0.78, blue: 0.82, alpha: 1.0)

    // Floor — warm honey wood
    static let floorLight = UIColor(red: 0.82, green: 0.62, blue: 0.40, alpha: 1.0)
    static let floorDark = UIColor(red: 0.68, green: 0.48, blue: 0.30, alpha: 1.0)
    static let floorGap = UIColor(red: 0.40, green: 0.26, blue: 0.14, alpha: 1.0)

    // Carpet
    static let carpetBeige = UIColor(red: 0.85, green: 0.82, blue: 0.75, alpha: 1.0)
    static let carpetDark = UIColor(red: 0.75, green: 0.72, blue: 0.65, alpha: 1.0)

    // Tile
    static let tileWhite = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
    static let tileBlack = UIColor(red: 0.20, green: 0.20, blue: 0.20, alpha: 1.0)

    // Baseboard
    static let baseboardFill = UIColor(red: 0.40, green: 0.28, blue: 0.18, alpha: 1.0)
    static let baseboardHighlight = UIColor(red: 0.55, green: 0.42, blue: 0.30, alpha: 1.0)

    // Furniture — chocolate/mahogany
    static let furnitureLight = UIColor(red: 0.60, green: 0.40, blue: 0.22, alpha: 1.0)
    static let furnitureDark = UIColor(red: 0.42, green: 0.28, blue: 0.15, alpha: 1.0)
    static let furnitureBack = UIColor(red: 0.30, green: 0.20, blue: 0.12, alpha: 1.0)

    // Books — vivid saturated
    static let bookRed = UIColor(red: 0.88, green: 0.22, blue: 0.20, alpha: 1.0)
    static let bookBlue = UIColor(red: 0.22, green: 0.45, blue: 0.82, alpha: 1.0)
    static let bookGreen = UIColor(red: 0.20, green: 0.68, blue: 0.30, alpha: 1.0)
    static let bookYellow = UIColor(red: 0.95, green: 0.78, blue: 0.15, alpha: 1.0)
    static let bookPurple = UIColor(red: 0.60, green: 0.28, blue: 0.72, alpha: 1.0)

    // Sky / nature
    static let skyTop = UIColor(red: 0.45, green: 0.72, blue: 0.95, alpha: 1.0)
    static let skyBottom = UIColor(red: 0.68, green: 0.85, blue: 0.98, alpha: 1.0)
    static let cloudWhite = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.9)
    static let treeGreen = UIColor(red: 0.25, green: 0.72, blue: 0.32, alpha: 1.0)
    static let treeDarkGreen = UIColor(red: 0.18, green: 0.55, blue: 0.22, alpha: 1.0)
    static let treeTrunk = UIColor(red: 0.50, green: 0.35, blue: 0.20, alpha: 1.0)

    // Lamp
    static let lampYellow = UIColor(red: 1.0, green: 0.92, blue: 0.55, alpha: 1.0)
    static let lampDarkYellow = UIColor(red: 0.92, green: 0.82, blue: 0.40, alpha: 1.0)
    static let lampGlow = UIColor(red: 1.0, green: 0.95, blue: 0.60, alpha: 1.0)

    // Vase
    static let terracotta = UIColor(red: 0.82, green: 0.42, blue: 0.22, alpha: 1.0)
    static let terracottaDark = UIColor(red: 0.65, green: 0.30, blue: 0.15, alpha: 1.0)
    static let goldBand = UIColor(red: 0.92, green: 0.80, blue: 0.30, alpha: 1.0)

    // Player
    static let skin = UIColor(red: 0.96, green: 0.82, blue: 0.68, alpha: 1.0)
    static let hair = UIColor(red: 0.28, green: 0.20, blue: 0.12, alpha: 1.0)
    static let shirtBlue = UIColor(red: 0.30, green: 0.55, blue: 0.88, alpha: 1.0)
    static let pantsGray = UIColor(red: 0.38, green: 0.38, blue: 0.45, alpha: 1.0)
    static let shoeDark = UIColor(red: 0.22, green: 0.18, blue: 0.15, alpha: 1.0)

    // Door
    static let doorBrown = UIColor(red: 0.62, green: 0.42, blue: 0.22, alpha: 1.0)
    static let doorLight = UIColor(red: 0.72, green: 0.55, blue: 0.35, alpha: 1.0)
    static let doorPanel = UIColor(red: 0.68, green: 0.48, blue: 0.28, alpha: 1.0)
    static let handleBrass = UIColor(red: 0.88, green: 0.75, blue: 0.30, alpha: 1.0)

    // Glass
    static let glassHighlight = UIColor(red: 0.85, green: 0.92, blue: 1.0, alpha: 0.25)

    // Frame
    static let frameWood = UIColor(red: 0.55, green: 0.38, blue: 0.22, alpha: 1.0)
}

// MARK: - Texture Factory (Cartoon Style)

enum TextureFactory {

    enum WallPattern {
        case stars, stripes, plain, polka
    }

    enum FloorType {
        case wood, carpet, tile
    }

    enum CharacterPart {
        case head, torso, arm, leg
    }

    // MARK: - Rendering Infrastructure

    static func makeRenderer(width: CGFloat, height: CGFloat) -> UIGraphicsImageRenderer {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2.0
        format.opaque = true
        return UIGraphicsImageRenderer(
            size: CGSize(width: width, height: height),
            format: format
        )
    }

    static func makeTransparentRenderer(width: CGFloat, height: CGFloat) -> UIGraphicsImageRenderer {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2.0
        format.opaque = false
        return UIGraphicsImageRenderer(
            size: CGSize(width: width, height: height),
            format: format
        )
    }

    static func finalize(_ image: UIImage) -> SKTexture {
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }

    static func setupContext(_ ctx: CGContext) {
        ctx.setShouldAntialias(true)
        ctx.interpolationQuality = .high
    }

    // MARK: - Cartoon Helper Utilities

    /// Creates a rounded rect CGPath
    static func roundedRectPath(rect: CGRect, cornerRadius: CGFloat) -> CGPath {
        let r = min(cornerRadius, min(rect.width, rect.height) / 2)
        return CGPath(roundedRect: rect, cornerWidth: r, cornerHeight: r, transform: nil)
    }

    /// Strokes a path with the bold dark outline
    static func drawOutline(ctx: CGContext, path: CGPath, lineWidth: CGFloat = 2.0) {
        ctx.saveGState()
        ctx.setStrokeColor(CartoonPalette.outline.cgColor)
        ctx.setLineWidth(lineWidth)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.addPath(path)
        ctx.strokePath()
        ctx.restoreGState()
    }

    /// Draws a vertical linear gradient fill within a rect
    static func verticalGradient(ctx: CGContext, rect: CGRect, topColor: UIColor, bottomColor: UIColor) {
        ctx.saveGState()
        ctx.clip(to: rect)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors = [topColor.cgColor, bottomColor.cgColor] as CFArray
        if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0]) {
            ctx.drawLinearGradient(gradient,
                                  start: CGPoint(x: rect.midX, y: rect.minY),
                                  end: CGPoint(x: rect.midX, y: rect.maxY),
                                  options: [])
        }
        ctx.restoreGState()
    }

    /// Draws a vertical gradient clipped to a CGPath
    static func verticalGradientInPath(ctx: CGContext, path: CGPath, topColor: UIColor, bottomColor: UIColor) {
        ctx.saveGState()
        ctx.addPath(path)
        ctx.clip()
        let bounds = path.boundingBox
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors = [topColor.cgColor, bottomColor.cgColor] as CFArray
        if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0]) {
            ctx.drawLinearGradient(gradient,
                                  start: CGPoint(x: bounds.midX, y: bounds.minY),
                                  end: CGPoint(x: bounds.midX, y: bounds.maxY),
                                  options: [])
        }
        ctx.restoreGState()
    }

    /// Adds a white semi-transparent highlight strip near the top
    static func addHighlight(ctx: CGContext, rect: CGRect, cornerRadius: CGFloat = 4) {
        let highlightRect = CGRect(x: rect.minX + 2, y: rect.minY + 2,
                                   width: rect.width - 4, height: max(rect.height * 0.25, 3))
        let path = roundedRectPath(rect: highlightRect, cornerRadius: cornerRadius * 0.6)
        ctx.saveGState()
        ctx.addPath(path)
        ctx.setFillColor(CartoonPalette.highlightWhite.cgColor)
        ctx.fillPath()
        ctx.restoreGState()
    }

    /// Adds a dark semi-transparent shadow strip near the bottom
    static func addShadow(ctx: CGContext, rect: CGRect, cornerRadius: CGFloat = 4) {
        let shadowH = max(rect.height * 0.15, 2)
        let shadowRect = CGRect(x: rect.minX + 2, y: rect.maxY - shadowH - 1,
                                width: rect.width - 4, height: shadowH)
        let path = roundedRectPath(rect: shadowRect, cornerRadius: cornerRadius * 0.4)
        ctx.saveGState()
        ctx.addPath(path)
        ctx.setFillColor(CartoonPalette.shadowDark.cgColor)
        ctx.fillPath()
        ctx.restoreGState()
    }

    // MARK: - Wall

    static func wallTexture(size: CGSize, pattern: WallPattern = .stars, baseColor: SKColor? = nil) -> SKTexture {
        let w = size.width
        let h = size.height
        let renderer = makeRenderer(width: w, height: h)

        // Convert baseColor to CartoonPalette if provided
        let lowerColor = baseColor ?? CartoonPalette.wallPastelLight
        let upperColor = baseColor?.withBrightness(adjustedBy: -0.05) ?? CartoonPalette.wallBase

        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)

            // Chair rail at ~40% from bottom
            let railY = h * 0.40

            // Lower section — lighter pastel (adjusted by environment)
            ctx.setFillColor(lowerColor.cgColor)
            ctx.fill(CGRect(x: 0, y: railY, width: w, height: h - railY))

            // Upper section — slightly darker
            ctx.setFillColor(upperColor.cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: w, height: railY))

            // Patterns on upper wall
            ctx.setFillColor(CartoonPalette.wallMotif.cgColor)

            switch pattern {
            case .stripes:
                 let stripeW: CGFloat = 40.0
                 for x in stride(from: 0.0, to: w, by: stripeW * 2) {
                     ctx.fill(CGRect(x: x, y: 0, width: stripeW, height: railY))
                 }

            case .polka:
                let dotSize: CGFloat = 10.0
                let spacing: CGFloat = 40.0
                for y in stride(from: 10.0, to: railY, by: spacing) {
                    for x in stride(from: 10.0, to: w, by: spacing) {
                        ctx.fillEllipse(in: CGRect(x: x, y: y, width: dotSize, height: dotSize))
                    }
                }

            case .stars:
                // Original Star motifs
                let motifSpacingX: CGFloat = 72.0
                let motifSpacingY: CGFloat = 56.0
                var my: CGFloat = 28
                var rowIdx = 0
                while my < railY - 20 {
                    var mx: CGFloat = (rowIdx % 2 == 0) ? 36 : 72
                    while mx < w - 20 {
                        let s: CGFloat = 5.0
                        let star = CGMutablePath()
                        // 4-pointed star
                        star.move(to: CGPoint(x: mx, y: my - s))
                        star.addLine(to: CGPoint(x: mx + s * 0.3, y: my - s * 0.3))
                        star.addLine(to: CGPoint(x: mx + s, y: my))
                        star.addLine(to: CGPoint(x: mx + s * 0.3, y: my + s * 0.3))
                        star.addLine(to: CGPoint(x: mx, y: my + s))
                        star.addLine(to: CGPoint(x: mx - s * 0.3, y: my + s * 0.3))
                        star.addLine(to: CGPoint(x: mx - s, y: my))
                        star.addLine(to: CGPoint(x: mx - s * 0.3, y: my - s * 0.3))
                        star.closeSubpath()
                        ctx.addPath(star)
                        ctx.fillPath()
                        mx += motifSpacingX
                    }
                    my += motifSpacingY
                    rowIdx += 1
                }

            case .plain:
                break // No pattern
            }

            // Chair rail — warm cream horizontal band
            let railH: CGFloat = 6
            ctx.setFillColor(CartoonPalette.chairRail.cgColor)
            ctx.fill(CGRect(x: 0, y: railY - railH / 2, width: w, height: railH))
            // Rail highlight
            ctx.setFillColor(CartoonPalette.highlightWhite.cgColor)
            ctx.fill(CGRect(x: 0, y: railY - railH / 2, width: w, height: 1.5))
            // Rail shadow
            ctx.setFillColor(CartoonPalette.shadowDark.withAlphaComponent(0.12).cgColor)
            ctx.fill(CGRect(x: 0, y: railY + railH / 2 - 1, width: w, height: 1.5))

            // Bottom shadow strip
            ctx.setFillColor(CartoonPalette.shadowDark.cgColor)
            ctx.fill(CGRect(x: 0, y: h - 16, width: w, height: 16))
        }
        return finalize(image)
    }

    // MARK: - Floor

    static func floorTexture(width: CGFloat, height: CGFloat, type: FloorType = .wood, baseColor: SKColor? = nil) -> SKTexture {
        let renderer = makeRenderer(width: width, height: height)

        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)

            switch type {
            case .wood:
                let baseWood = baseColor ?? CartoonPalette.floorLight
                let darkWood = baseColor?.withBrightness(adjustedBy: -0.1) ?? CartoonPalette.floorDark

                // Base warm wood fill
                ctx.setFillColor(baseWood.cgColor)
                ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))

                // Plank rows with alternating shades and rounded corners
                let plankH: CGFloat = 16.0
                var py: CGFloat = 0
                var toggle = false
                while py < height {
                    let color = toggle ? darkWood : baseWood
                    let plankRect = CGRect(x: 1, y: py + 1, width: width - 2, height: plankH - 2)
                    let plankPath = roundedRectPath(rect: plankRect, cornerRadius: 2)
                    ctx.setFillColor(color.cgColor)
                    ctx.addPath(plankPath)
                    ctx.fillPath()

                    // Thin dark gap line between planks
                    ctx.setFillColor(CartoonPalette.floorGap.cgColor)
                    ctx.fill(CGRect(x: 0, y: py, width: width, height: 1.5))

                    // Subtle grain highlight lines
                    ctx.setStrokeColor(UIColor.white.withAlphaComponent(0.15).cgColor)
                    ctx.setLineWidth(0.5)
                    let grainY = py + plankH * 0.35
                    ctx.move(to: CGPoint(x: 4, y: grainY))
                    ctx.addLine(to: CGPoint(x: width * 0.6, y: grainY))
                    ctx.strokePath()

                    py += plankH
                    toggle.toggle()
                }

            case .carpet:
                let base = baseColor ?? CartoonPalette.carpetBeige
                let dark = baseColor?.withBrightness(adjustedBy: -0.1) ?? CartoonPalette.carpetDark

                // Base fill
                ctx.setFillColor(base.cgColor)
                ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))

                // Noise/Texture
                ctx.setFillColor(dark.withAlphaComponent(0.5).cgColor)
                for _ in 0..<100 {
                    let x = CGFloat.random(in: 0...width)
                    let y = CGFloat.random(in: 0...height)
                    ctx.fillEllipse(in: CGRect(x: x, y: y, width: 2, height: 2))
                }

            case .tile:
                let c1 = baseColor ?? CartoonPalette.tileWhite
                let c2 = CartoonPalette.tileBlack

                let size: CGFloat = 40
                var isBlack = false
                for y in stride(from: 0, to: height, by: size) {
                    for x in stride(from: 0, to: width, by: size) {
                        ctx.setFillColor(isBlack ? c2.cgColor : c1.cgColor)
                        ctx.fill(CGRect(x: x, y: y, width: size, height: size))
                        // Grout
                        ctx.setStrokeColor(UIColor.gray.cgColor)
                        ctx.stroke(CGRect(x: x, y: y, width: size, height: size))
                        isBlack.toggle()
                    }
                    if Int(width / size) % 2 == 0 {
                         isBlack.toggle()
                    }
                }
            }
        }
        return finalize(image)
    }

    // MARK: - Baseboard

    static func baseboardTexture(width: CGFloat, height: CGFloat) -> SKTexture {
        let renderer = makeRenderer(width: width, height: height)

        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)

            // Dark brown fill
            verticalGradient(ctx: ctx, rect: CGRect(x: 0, y: 0, width: width, height: height),
                             topColor: CartoonPalette.baseboardHighlight, bottomColor: CartoonPalette.baseboardFill)

            // Top highlight line
            ctx.setStrokeColor(CartoonPalette.highlightWhite.cgColor)
            ctx.setLineWidth(1.0)
            ctx.move(to: CGPoint(x: 0, y: 1))
            ctx.addLine(to: CGPoint(x: width, y: 1))
            ctx.strokePath()

            // Bottom edge shadow
            ctx.setFillColor(CartoonPalette.shadowDark.cgColor)
            ctx.fill(CGRect(x: 0, y: height - 2, width: width, height: 2))
        }
        return finalize(image)
    }

    // MARK: - Table Top

    static func tableTopTexture(width: CGFloat, height: CGFloat) -> SKTexture {
        let w = Swift.max(width, 4)
        let h = Swift.max(height, 4)
        let renderer = makeRenderer(width: w, height: h)

        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)

            // Background (will be covered)
            ctx.setFillColor(CartoonPalette.furnitureLight.cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))

            let tableRect = CGRect(x: 1, y: 1, width: w - 2, height: h - 2)
            let cr: CGFloat = 4
            let path = roundedRectPath(rect: tableRect, cornerRadius: cr)

            // Wood gradient fill
            verticalGradientInPath(ctx: ctx, path: path,
                                   topColor: CartoonPalette.furnitureLight, bottomColor: CartoonPalette.furnitureDark)

            // Top highlight strip
            addHighlight(ctx: ctx, rect: tableRect, cornerRadius: cr)

            // Bottom shadow strip
            addShadow(ctx: ctx, rect: tableRect, cornerRadius: cr)

            // Bold outline
            drawOutline(ctx: ctx, path: path, lineWidth: 2.0)
        }
        return finalize(image)
    }

    // MARK: - Table Leg

    static func tableLegTexture(width: CGFloat, height: CGFloat) -> SKTexture {
        let w = Swift.max(width, 4)
        let h = Swift.max(height, 8)
        let renderer = makeRenderer(width: w, height: h)

        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)

            // Background
            ctx.setFillColor(CartoonPalette.furnitureLight.cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))

            let legRect = CGRect(x: 1, y: 0, width: w - 2, height: h)
            let cr: CGFloat = 3
            let path = roundedRectPath(rect: legRect, cornerRadius: cr)

            // Gradient fill
            verticalGradientInPath(ctx: ctx, path: path,
                                   topColor: CartoonPalette.furnitureLight, bottomColor: CartoonPalette.furnitureDark)

            // Left highlight edge
            ctx.saveGState()
            ctx.setStrokeColor(CartoonPalette.highlightWhite.cgColor)
            ctx.setLineWidth(1.5)
            ctx.move(to: CGPoint(x: 2.5, y: 2))
            ctx.addLine(to: CGPoint(x: 2.5, y: h - 2))
            ctx.strokePath()
            ctx.restoreGState()

            // Bold outline
            drawOutline(ctx: ctx, path: path, lineWidth: 1.5)
        }
        return finalize(image)
    }

    // MARK: - Bookshelf

    static func bookshelfTexture(width: CGFloat, height: CGFloat) -> SKTexture {
        let renderer = makeRenderer(width: width, height: height)

        let bookColors: [UIColor] = [
            CartoonPalette.bookRed, CartoonPalette.bookBlue, CartoonPalette.bookGreen,
            CartoonPalette.bookYellow, CartoonPalette.bookPurple
        ]

        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)
            srand48(400)

            // Outer shelf background
            let outerRect = CGRect(x: 0, y: 0, width: width, height: height)
            ctx.setFillColor(CartoonPalette.furnitureDark.cgColor)
            ctx.fill(outerRect)

            // Inner back fill (slightly lighter)
            let innerRect = CGRect(x: 6, y: 6, width: width - 12, height: height - 12)
            ctx.setFillColor(CartoonPalette.furnitureBack.cgColor)
            ctx.fill(innerRect)

            // Outer frame rounded rect with bold outline
            let frameRect = CGRect(x: 2, y: 2, width: width - 4, height: height - 4)
            let framePath = roundedRectPath(rect: frameRect, cornerRadius: 4)
            verticalGradientInPath(ctx: ctx, path: framePath,
                                   topColor: CartoonPalette.furnitureLight, bottomColor: CartoonPalette.furnitureDark)

            // Re-fill inner area so books have dark background
            ctx.setFillColor(CartoonPalette.furnitureBack.cgColor)
            ctx.fill(innerRect)

            // Shelves
            let shelfCount = 4
            let innerH = height - 12
            let shelfGap = innerH / CGFloat(shelfCount)

            // Draw shelf lines
            for s in 0...shelfCount {
                let sy = 6 + CGFloat(s) * shelfGap
                let shelfRect = CGRect(x: 4, y: sy - 1.5, width: width - 8, height: 3)
                ctx.setFillColor(CartoonPalette.furnitureDark.cgColor)
                ctx.fill(shelfRect)
                // Shelf highlight
                ctx.setFillColor(CartoonPalette.highlightWhite.withAlphaComponent(0.2).cgColor)
                ctx.fill(CGRect(x: 4, y: sy - 1.5, width: width - 8, height: 1))
            }

            // Books on each shelf
            var colorIdx = 0
            for s in 0..<shelfCount {
                let shelfTop = 6 + CGFloat(s) * shelfGap + 3
                let shelfBottom = 6 + CGFloat(s + 1) * shelfGap - 2
                let bookH = shelfBottom - shelfTop
                guard bookH > 2 else { continue }

                var bx: CGFloat = 8
                while bx < width - 10 {
                    let bw = CGFloat(6 + drand48() * 6)
                    if bx + bw >= width - 8 { break }

                    let color = bookColors[colorIdx % bookColors.count]
                    colorIdx += 1

                    let bookRect = CGRect(x: bx, y: shelfTop, width: bw, height: bookH)
                    let bookPath = roundedRectPath(rect: bookRect, cornerRadius: 1.5)

                    // Book fill
                    ctx.setFillColor(color.cgColor)
                    ctx.addPath(bookPath)
                    ctx.fillPath()

                    // Book outline
                    drawOutline(ctx: ctx, path: bookPath, lineWidth: 0.8)

                    // Spine highlight
                    ctx.setStrokeColor(CartoonPalette.highlightWhite.cgColor)
                    ctx.setLineWidth(0.8)
                    ctx.move(to: CGPoint(x: bx + 1.5, y: shelfTop + 1))
                    ctx.addLine(to: CGPoint(x: bx + 1.5, y: shelfBottom - 1))
                    ctx.strokePath()

                    bx += bw + CGFloat(2 + drand48() * 2)
                }
            }

            // Frame outline on top
            drawOutline(ctx: ctx, path: framePath, lineWidth: 2.5)
        }
        return finalize(image)
    }

    // MARK: - Window

    static func windowTexture(width: CGFloat, height: CGFloat) -> SKTexture {
        let renderer = makeRenderer(width: width, height: height)

        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)

            // White frame background
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))

            let glassRect = CGRect(x: 6, y: 6, width: width - 12, height: height - 12)

            // Sky gradient fill
            verticalGradient(ctx: ctx, rect: glassRect,
                             topColor: CartoonPalette.skyTop, bottomColor: CartoonPalette.skyBottom)

            // Bright yellow sun in upper-right
            let sunX = width * 0.78
            let sunY = height * 0.15
            let sunR: CGFloat = width * 0.10
            // Sun glow
            ctx.setFillColor(UIColor(red: 1.0, green: 0.92, blue: 0.40, alpha: 0.3).cgColor)
            ctx.fillEllipse(in: CGRect(x: sunX - sunR * 1.6, y: sunY - sunR * 1.6, width: sunR * 3.2, height: sunR * 3.2))
            // Sun body
            ctx.setFillColor(UIColor(red: 1.0, green: 0.88, blue: 0.20, alpha: 1.0).cgColor)
            ctx.fillEllipse(in: CGRect(x: sunX - sunR, y: sunY - sunR, width: sunR * 2, height: sunR * 2))

            // Sun highlight
            ctx.setFillColor(UIColor(red: 1.0, green: 0.95, blue: 0.60, alpha: 0.6).cgColor)
            ctx.fillEllipse(in: CGRect(x: sunX - sunR * 0.5, y: sunY - sunR * 0.6, width: sunR, height: sunR * 0.7))

            // White cloud ellipses (puffier)
            ctx.setFillColor(CartoonPalette.cloudWhite.cgColor)
            ctx.fillEllipse(in: CGRect(x: width * 0.08, y: height * 0.10, width: width * 0.22, height: height * 0.10))
            ctx.fillEllipse(in: CGRect(x: width * 0.15, y: height * 0.06, width: width * 0.20, height: height * 0.10))
            ctx.fillEllipse(in: CGRect(x: width * 0.25, y: height * 0.09, width: width * 0.14, height: height * 0.08))
            ctx.fillEllipse(in: CGRect(x: width * 0.45, y: height * 0.18, width: width * 0.18, height: height * 0.07))

            // Green ground area
            let groundY = height * 0.7
            let grassColor = UIColor(red: 0.35, green: 0.75, blue: 0.30, alpha: 1.0)
            let grassDark = UIColor(red: 0.25, green: 0.62, blue: 0.22, alpha: 1.0)
            ctx.saveGState()
            ctx.clip(to: glassRect)
            verticalGradient(ctx: ctx, rect: CGRect(x: 6, y: groundY, width: width - 12, height: height - 6 - groundY),
                             topColor: grassColor, bottomColor: grassDark)
            ctx.restoreGState()

            // Trees
            let t1x = width * 0.30
            let trunkRect1 = CGRect(x: t1x - 3, y: groundY - height * 0.22, width: 6, height: height * 0.22)
            ctx.setFillColor(CartoonPalette.treeTrunk.cgColor)
            ctx.fill(trunkRect1)
            ctx.setFillColor(CartoonPalette.treeGreen.cgColor)
            ctx.fillEllipse(in: CGRect(x: t1x - width * 0.11, y: groundY - height * 0.42,
                                       width: width * 0.22, height: height * 0.22))
            ctx.setFillColor(CartoonPalette.treeDarkGreen.cgColor)
            ctx.fillEllipse(in: CGRect(x: t1x - width * 0.07, y: groundY - height * 0.35,
                                       width: width * 0.16, height: height * 0.14))

            let t2x = width * 0.62
            let trunkRect2 = CGRect(x: t2x - 2, y: groundY - height * 0.13, width: 4, height: height * 0.13)
            ctx.setFillColor(CartoonPalette.treeTrunk.cgColor)
            ctx.fill(trunkRect2)
            ctx.setFillColor(CartoonPalette.treeGreen.cgColor)
            ctx.fillEllipse(in: CGRect(x: t2x - width * 0.07, y: groundY - height * 0.26,
                                       width: width * 0.14, height: height * 0.14))

            // Small flowers on the ground
            let flowerColors: [UIColor] = [
                UIColor(red: 1.0, green: 0.40, blue: 0.45, alpha: 1.0),
                UIColor(red: 1.0, green: 0.80, blue: 0.20, alpha: 1.0),
                UIColor(red: 0.70, green: 0.40, blue: 0.85, alpha: 1.0)
            ]
            let flowerXs: [CGFloat] = [0.15, 0.42, 0.52, 0.80]
            for (i, fx) in flowerXs.enumerated() {
                let fxp = width * fx
                let fyp = groundY + height * 0.05
                // Stem
                ctx.setStrokeColor(UIColor(red: 0.2, green: 0.55, blue: 0.2, alpha: 1.0).cgColor)
                ctx.setLineWidth(1.2)
                ctx.move(to: CGPoint(x: fxp, y: fyp + 6))
                ctx.addLine(to: CGPoint(x: fxp, y: fyp))
                ctx.strokePath()
                // Petals
                let fc = flowerColors[i % flowerColors.count]
                ctx.setFillColor(fc.cgColor)
                for angle in stride(from: 0.0, to: CGFloat.pi * 2, by: CGFloat.pi / 2.5) {
                    let px = fxp + 2.5 * cos(angle)
                    let py = fyp + 2.5 * sin(angle)
                    ctx.fillEllipse(in: CGRect(x: px - 1.5, y: py - 1.5, width: 3, height: 3))
                }
                // Center
                ctx.setFillColor(UIColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 1.0).cgColor)
                ctx.fillEllipse(in: CGRect(x: fxp - 1, y: fyp - 1, width: 2, height: 2))
            }

            // Small butterfly
            let bx = width * 0.55
            let by = height * 0.35
            ctx.setFillColor(UIColor(red: 0.95, green: 0.55, blue: 0.20, alpha: 0.85).cgColor)
            ctx.fillEllipse(in: CGRect(x: bx - 4, y: by - 2.5, width: 5, height: 4))
            ctx.fillEllipse(in: CGRect(x: bx + 1, y: by - 2, width: 4, height: 3.5))
            // Body
            ctx.setFillColor(CartoonPalette.outline.withAlphaComponent(0.6).cgColor)
            ctx.fill(CGRect(x: bx - 0.5, y: by - 1, width: 1, height: 3))

            // Glass highlight overlay
            ctx.setFillColor(CartoonPalette.glassHighlight.cgColor)
            ctx.fill(glassRect)

            // Diagonal highlight streak
            ctx.saveGState()
            ctx.clip(to: glassRect)
            ctx.setStrokeColor(UIColor.white.withAlphaComponent(0.4).cgColor)
            ctx.setLineWidth(3.0)
            ctx.move(to: CGPoint(x: 10, y: 10))
            ctx.addLine(to: CGPoint(x: Swift.min(width, height) * 0.4, y: Swift.min(width, height) * 0.4))
            ctx.strokePath()
            ctx.restoreGState()

            // Crossbar rounded rects
            let barW: CGFloat = 4
            let barPath1 = roundedRectPath(rect: CGRect(x: width / 2 - barW / 2, y: 6,
                                                         width: barW, height: height - 12), cornerRadius: 2)
            let barPath2 = roundedRectPath(rect: CGRect(x: 6, y: height / 2 - barW / 2,
                                                         width: width - 12, height: barW), cornerRadius: 2)
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.addPath(barPath1)
            ctx.fillPath()
            ctx.addPath(barPath2)
            ctx.fillPath()
            drawOutline(ctx: ctx, path: barPath1, lineWidth: 1.5)
            drawOutline(ctx: ctx, path: barPath2, lineWidth: 1.5)

            // Bold frame outline
            let framePath = roundedRectPath(rect: CGRect(x: 3, y: 3, width: width - 6, height: height - 6),
                                            cornerRadius: 3)
            drawOutline(ctx: ctx, path: framePath, lineWidth: 2.5)
        }
        return finalize(image)
    }

    // MARK: - Door

    static func doorTexture(width: CGFloat, height: CGFloat) -> SKTexture {
        let renderer = makeRenderer(width: width, height: height)

        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)

            // Door body with gradient
            let doorRect = CGRect(x: 2, y: 2, width: width - 4, height: height - 4)
            let doorPath = roundedRectPath(rect: doorRect, cornerRadius: 4)
            verticalGradientInPath(ctx: ctx, path: doorPath,
                                   topColor: CartoonPalette.doorLight, bottomColor: CartoonPalette.doorBrown)

            // Two inset panels
            let panelInset: CGFloat = 10
            let panelGap: CGFloat = 8
            let panelH = (height - panelInset * 2 - panelGap) / 2

            // Upper panel
            let upperRect = CGRect(x: panelInset, y: panelInset, width: width - panelInset * 2, height: panelH)
            let upperPath = roundedRectPath(rect: upperRect, cornerRadius: 3)
            ctx.setFillColor(CartoonPalette.doorPanel.cgColor)
            ctx.addPath(upperPath)
            ctx.fillPath()
            addHighlight(ctx: ctx, rect: upperRect, cornerRadius: 3)
            drawOutline(ctx: ctx, path: upperPath, lineWidth: 1.2)

            // Lower panel
            let lowerY = panelInset + panelH + panelGap
            let lowerRect = CGRect(x: panelInset, y: lowerY, width: width - panelInset * 2, height: panelH)
            let lowerPath = roundedRectPath(rect: lowerRect, cornerRadius: 3)
            ctx.setFillColor(CartoonPalette.doorPanel.cgColor)
            ctx.addPath(lowerPath)
            ctx.fillPath()
            addHighlight(ctx: ctx, rect: lowerRect, cornerRadius: 3)
            drawOutline(ctx: ctx, path: lowerPath, lineWidth: 1.2)

            // Circular brass handle with highlight
            let handleX = width - 16
            let handleY = height / 2
            let handleRect = CGRect(x: handleX - 5, y: handleY - 5, width: 10, height: 10)
            ctx.setFillColor(CartoonPalette.handleBrass.cgColor)
            ctx.fillEllipse(in: handleRect)
            // Handle highlight
            ctx.setFillColor(CartoonPalette.highlightWhite.cgColor)
            ctx.fillEllipse(in: CGRect(x: handleX - 3, y: handleY - 4, width: 4, height: 4))
            // Handle outline
            let handlePath = CGPath(ellipseIn: handleRect, transform: nil)
            drawOutline(ctx: ctx, path: handlePath, lineWidth: 1.2)

            // Subtle grain lines
            ctx.setStrokeColor(CartoonPalette.shadowDark.withAlphaComponent(0.1).cgColor)
            ctx.setLineWidth(0.5)
            ctx.move(to: CGPoint(x: 14, y: height * 0.25))
            ctx.addLine(to: CGPoint(x: width - 14, y: height * 0.25))
            ctx.strokePath()
            ctx.move(to: CGPoint(x: 14, y: height * 0.75))
            ctx.addLine(to: CGPoint(x: width - 14, y: height * 0.75))
            ctx.strokePath()

            // Bold door outline
            drawOutline(ctx: ctx, path: doorPath, lineWidth: 2.5)
        }
        return finalize(image)
    }

    // MARK: - Lamp

    static func lampTexture(width: CGFloat, height: CGFloat) -> SKTexture {
        let renderer = makeTransparentRenderer(width: width, height: height)

        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)

            // Trapezoid shade path
            let topInset = width * 0.2
            let path = CGMutablePath()
            path.move(to: CGPoint(x: topInset, y: 0))
            path.addLine(to: CGPoint(x: width - topInset, y: 0))
            path.addLine(to: CGPoint(x: width, y: height))
            path.addLine(to: CGPoint(x: 0, y: height))
            path.closeSubpath()

            // Warm yellow gradient fill clipped to shade
            verticalGradientInPath(ctx: ctx, path: path,
                                   topColor: CartoonPalette.lampYellow, bottomColor: CartoonPalette.lampDarkYellow)

            // Bold outline edges
            drawOutline(ctx: ctx, path: path, lineWidth: 2.0)

            // Bottom glow line
            ctx.setStrokeColor(CartoonPalette.lampGlow.withAlphaComponent(0.7).cgColor)
            ctx.setLineWidth(2.5)
            ctx.move(to: CGPoint(x: 1, y: height - 1))
            ctx.addLine(to: CGPoint(x: width - 1, y: height - 1))
            ctx.strokePath()
        }
        return finalize(image)
    }

    // MARK: - Lamp Glow

    static func lampGlowTexture(radius: CGFloat) -> SKTexture {
        let size = radius * 2
        let renderer = makeTransparentRenderer(width: size, height: size)

        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)

            let center = CGPoint(x: size / 2, y: size / 2)

            // Concentric clean circles with warm yellow at decreasing alpha
            let steps: [(CGFloat, CGFloat)] = [
                (1.0, 0.03), (0.8, 0.06), (0.6, 0.10), (0.4, 0.18), (0.25, 0.28)
            ]
            for (radiusFraction, alpha) in steps {
                let r = radius * radiusFraction
                let color = CartoonPalette.lampGlow.withAlphaComponent(alpha)
                ctx.setFillColor(color.cgColor)
                let rect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
                ctx.fillEllipse(in: rect)
            }
        }
        return finalize(image)
    }

    // MARK: - Picture Frame

    static func pictureFrameTexture(width: CGFloat, height: CGFloat, pictureHue: CGFloat) -> SKTexture {
        let renderer = makeRenderer(width: width, height: height)

        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)

            // Frame background fill
            ctx.setFillColor(CartoonPalette.frameWood.cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))

            // Frame rounded rect outline
            let frameRect = CGRect(x: 2, y: 2, width: width - 4, height: height - 4)
            let framePath = roundedRectPath(rect: frameRect, cornerRadius: 3)
            ctx.setFillColor(CartoonPalette.frameWood.cgColor)
            ctx.addPath(framePath)
            ctx.fillPath()

            // Interior landscape
            let inset: CGFloat = 6
            let innerW = width - inset * 2
            let innerH = height - inset * 2
            let innerRect = CGRect(x: inset, y: inset, width: innerW, height: innerH)

            // Sky gradient top half
            let skyRect = CGRect(x: inset, y: inset, width: innerW, height: innerH / 2)
            verticalGradient(ctx: ctx, rect: skyRect,
                             topColor: CartoonPalette.skyTop, bottomColor: CartoonPalette.skyBottom)

            // Colored ground gradient bottom half
            let groundTop = UIColor(hue: pictureHue, saturation: 0.5, brightness: 0.7, alpha: 1.0)
            let groundBot = UIColor(hue: pictureHue, saturation: 0.4, brightness: 0.5, alpha: 1.0)
            let groundRect = CGRect(x: inset, y: inset + innerH / 2, width: innerW, height: innerH / 2)
            verticalGradient(ctx: ctx, rect: groundRect, topColor: groundTop, bottomColor: groundBot)

            // Horizon line
            ctx.setStrokeColor(CartoonPalette.outline.withAlphaComponent(0.3).cgColor)
            ctx.setLineWidth(0.8)
            ctx.move(to: CGPoint(x: inset, y: inset + innerH / 2))
            ctx.addLine(to: CGPoint(x: width - inset, y: inset + innerH / 2))
            ctx.strokePath()

            // Inner border outline
            let innerPath = roundedRectPath(rect: innerRect, cornerRadius: 1)
            drawOutline(ctx: ctx, path: innerPath, lineWidth: 1.0)

            // Bold frame outline
            drawOutline(ctx: ctx, path: framePath, lineWidth: 2.5)
        }
        return finalize(image)
    }

    static func createCharacterPart(_ part: CharacterPart, width: CGFloat, height: CGFloat) -> SKTexture {
        let renderer = makeTransparentRenderer(width: width, height: height)
        let image = renderer.image { context in
            let ctx = context.cgContext
            setupContext(ctx)

            switch part {
            case .head:
                // Head shape
                let rect = CGRect(x: 2, y: 2, width: width-4, height: height-4)
                ctx.setFillColor(CartoonPalette.skin.cgColor)
                ctx.fillEllipse(in: rect)
                drawOutline(ctx: ctx, path: CGPath(ellipseIn: rect, transform: nil))

                // Eyes
                ctx.setFillColor(UIColor.black.cgColor)
                ctx.fillEllipse(in: CGRect(x: width*0.3, y: height*0.4, width: 4, height: 4))
                ctx.fillEllipse(in: CGRect(x: width*0.7, y: height*0.4, width: 4, height: 4))

                // Mouth
                ctx.setStrokeColor(UIColor.black.cgColor)
                ctx.setLineWidth(1.5)
                ctx.beginPath()
                ctx.addArc(center: CGPoint(x: width/2, y: height*0.6), radius: 6, startAngle: 0.1, endAngle: 3.0, clockwise: false)
                ctx.strokePath()

            case .torso:
                let rect = CGRect(x: 2, y: 2, width: width-4, height: height-4)
                let path = roundedRectPath(rect: rect, cornerRadius: 5)
                ctx.setFillColor(CartoonPalette.shirtBlue.cgColor)
                ctx.addPath(path)
                ctx.fillPath()
                drawOutline(ctx: ctx, path: path)

            case .arm:
                let rect = CGRect(x: 2, y: 2, width: width-4, height: height-4)
                let path = roundedRectPath(rect: rect, cornerRadius: 3)
                ctx.setFillColor(CartoonPalette.skin.cgColor)
                ctx.addPath(path)
                ctx.fillPath()
                drawOutline(ctx: ctx, path: path)
                // Sleeve
                ctx.setFillColor(CartoonPalette.shirtBlue.cgColor)
                ctx.fill(CGRect(x: 2, y: 2, width: width-4, height: height*0.3))

            case .leg:
                let rect = CGRect(x: 2, y: 2, width: width-4, height: height-4)
                let path = roundedRectPath(rect: rect, cornerRadius: 3)
                ctx.setFillColor(CartoonPalette.pantsGray.cgColor)
                ctx.addPath(path)
                ctx.fillPath()
                drawOutline(ctx: ctx, path: path)
                // Shoe
                ctx.setFillColor(CartoonPalette.shoeDark.cgColor)
                ctx.fill(CGRect(x: 2, y: height*0.8, width: width-4, height: height*0.2))
            }
        }
        return finalize(image)
    }
}

// MARK: - Color Extension

extension SKColor {
    func withBrightness(adjustedBy amount: CGFloat) -> SKColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            return SKColor(hue: h, saturation: s, brightness: max(0, min(1, b + amount)), alpha: a)
        }
        return self
    }
}
