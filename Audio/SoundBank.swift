import Foundation

// MARK: - Sound References
// Since this is a Swift Playground App with no bundled audio files,
// we use system sounds via AudioServicesPlaySystemSound and
// synthesized audio via AVAudioEngine as fallback.

enum SoundBank: String, CaseIterable, Sendable {
    // Earthquake phases
    case pWaveRumble = "p_wave_rumble"
    case sWaveIntense = "s_wave_intense"
    case aftershockRumble = "aftershock_rumble"

    // Impacts
    case glassShatter = "glass_shatter"
    case woodCrash = "wood_crash"
    case booksFalling = "books_falling"
    case debrisSettle = "debris_settle"

    // Player feedback
    case correctChoice = "correct_ding"
    case wrongChoice = "wrong_buzz"
    case takeDamage = "damage_hit"

    // UI
    case countdownTick = "countdown_tick"

    var fileName: String { rawValue }
    var fileExtension: String { "m4a" }

    var url: URL? {
        Bundle.main.url(forResource: fileName, withExtension: fileExtension)
    }
}
