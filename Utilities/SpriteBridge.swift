import SwiftUI
import SpriteKit

/// Bridges procedural SpriteKit textures to SwiftUI Images
@MainActor
struct SpriteBridge {

    /// Cache for generated UIImages to avoid re-rendering every frame
    private static var cache: [String: UIImage] = [:]

    /// Get a SwiftUI Image for a given sprite name
    static func image(named name: String) -> Image {
        if let uiImage = uiImage(named: name) {
            return Image(uiImage: uiImage)
        }
        // Fallback for system symbols or unknown assets
        return Image(systemName: "questionmark.square.dashed")
    }

    /// Get a UIImage for a given sprite name (cached)
    static func uiImage(named name: String) -> UIImage? {
        if let cached = cache[name] {
            return cached
        }

        let texture: SKTexture?

        // Map names to TextureFactory methods
        switch name {
        // Player
        case "player_stand": texture = TextureFactory.playerIdleTexture()
        case "player_idle": texture = TextureFactory.playerIdleTexture()
        case "player_walk1": texture = TextureFactory.playerIdleTexture() // Use idle for frame 1
        case "player_walk2": texture = TextureFactory.playerWalk2Texture()
        case "player_run": texture = TextureFactory.playerRunTexture()
        case "player_duck": texture = TextureFactory.playerDuckTexture()
        case "player_cover": texture = TextureFactory.playerCoverTexture()
        case "player_hurt": texture = TextureFactory.playerHurtTexture()
        case "player_fall": texture = TextureFactory.playerFallTexture()
        case "player_kick": texture = TextureFactory.playerKickTexture()
        case "player_jump": texture = TextureFactory.playerJumpTexture()
        case "player_cheer1": texture = TextureFactory.playerCheer1Texture()
        case "player_hold1": texture = TextureFactory.playerHold1Texture()
        case "player_hold2": texture = TextureFactory.playerHold2Texture()
        case "player_action1": texture = TextureFactory.playerAction1Texture()

        default:
            return UIImage(systemName: name) // Try SFSymbol
        }

        guard let skTexture = texture else { return nil }

        // Convert SKTexture to UIImage
        // Note: SKTexture.cgImage() is synchronous
        let cgImage = skTexture.cgImage()
        let uiImage = UIImage(cgImage: cgImage)
        cache[name] = uiImage
        return uiImage
    }

    /// Pre-warm common textures
    static func prewarm() {
        let common = ["player_idle", "player_walk1", "player_walk2", "player_duck"]
        for name in common {
            _ = uiImage(named: name)
        }
    }
}
