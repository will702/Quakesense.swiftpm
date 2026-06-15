import SwiftUI
import Combine

// MARK: - Settings Manager

@MainActor
final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    // MARK: - Keys
    private let ambientVolumeKey = "quakesense_ambient_volume"
    private let sfxVolumeKey = "quakesense_sfx_volume"
    private let uiVolumeKey = "quakesense_ui_volume"
    private let hapticEnabledKey = "quakesense_haptic_enabled"
    private let hapticIntensityKey = "quakesense_haptic_intensity"
    private let reducedMotionKey = "quakesense_reduced_motion"
    private let tiltControlKey = "quakesense_tilt_control"

    // MARK: - Published Properties

    @Published var ambientVolume: Double {
        didSet {
            UserDefaults.standard.set(ambientVolume, forKey: ambientVolumeKey)
            AudioManager.shared.updateAmbientVolume(Float(ambientVolume))
        }
    }

    @Published var sfxVolume: Double {
        didSet {
            UserDefaults.standard.set(sfxVolume, forKey: sfxVolumeKey)
            AudioManager.shared.updateSFXVolume(Float(sfxVolume))
        }
    }

    @Published var uiVolume: Double {
        didSet {
            UserDefaults.standard.set(uiVolume, forKey: uiVolumeKey)
            AudioManager.shared.updateUIVolume(Float(uiVolume))
        }
    }

    @Published var hapticEnabled: Bool {
        didSet {
            UserDefaults.standard.set(hapticEnabled, forKey: hapticEnabledKey)
            HapticManager.shared.setEnabled(hapticEnabled)
        }
    }

    @Published var hapticIntensity: Double {
        didSet {
            UserDefaults.standard.set(hapticIntensity, forKey: hapticIntensityKey)
            HapticManager.shared.setIntensity(Float(hapticIntensity))
        }
    }

    @Published var reducedMotion: Bool {
        didSet {
            UserDefaults.standard.set(reducedMotion, forKey: reducedMotionKey)
        }
    }

    @Published var tiltControlEnabled: Bool {
        didSet {
            UserDefaults.standard.set(tiltControlEnabled, forKey: tiltControlKey)
        }
    }

    // MARK: - Computed

    var isReducedMotionEnabled: Bool {
        reducedMotion || UIAccessibility.isReduceMotionEnabled
    }

    // MARK: - Initialization

    private init() {
        // Load from UserDefaults or use defaults
        self.ambientVolume = UserDefaults.standard.object(forKey: ambientVolumeKey) as? Double ?? 0.7
        self.sfxVolume = UserDefaults.standard.object(forKey: sfxVolumeKey) as? Double ?? 0.8
        self.uiVolume = UserDefaults.standard.object(forKey: uiVolumeKey) as? Double ?? 0.6
        self.hapticEnabled = UserDefaults.standard.object(forKey: hapticEnabledKey) as? Bool ?? true
        self.hapticIntensity = UserDefaults.standard.object(forKey: hapticIntensityKey) as? Double ?? 0.8
        self.reducedMotion = UserDefaults.standard.object(forKey: reducedMotionKey) as? Bool ?? false
        self.tiltControlEnabled = UserDefaults.standard.object(forKey: tiltControlKey) as? Bool ?? true

        // Observe system accessibility changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(accessibilitySettingsChanged),
            name: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(accessibilitySettingsChanged),
            name: UIAccessibility.darkerSystemColorsStatusDidChangeNotification,
            object: nil
        )
    }

    @objc private func accessibilitySettingsChanged() {
        objectWillChange.send()
    }

    // MARK: - Reset

    func resetToDefaults() {
        ambientVolume = 0.7
        sfxVolume = 0.8
        uiVolume = 0.6
        hapticEnabled = true
        hapticIntensity = 0.8
        reducedMotion = false
        tiltControlEnabled = true
    }

    func resetAllProgress() {
        // Reset room unlocks
        RoomUnlockManager.shared.reset()

        // Reset achievements
        AchievementStore.shared.resetAllAchievements()

        // Reset onboarding
        OnboardingManager.shared.resetOnboarding()

        // Reset settings to defaults
        resetToDefaults()
    }
}

// MARK: - Audio Manager Integration

extension SettingsManager {
    func applyAudioSettings() {
        // Direct property assignment - AudioManager properties are now public
        AudioManager.shared.ambientVolume = Float(ambientVolume)
        AudioManager.shared.sfxVolume = Float(sfxVolume)
        AudioManager.shared.uiVolume = Float(uiVolume)
    }

    func applyHapticSettings() {
        // Direct property assignment - HapticManager properties are now public
        HapticManager.shared.isEnabled = hapticEnabled
        HapticManager.shared.intensityMultiplier = Float(hapticIntensity)
    }
}

// MARK: - Settings Integration for Managers

extension AudioManager {
    func updateAmbientVolume(_ volume: Float) {
        ambientVolume = volume
    }

    func updateSFXVolume(_ volume: Float) {
        sfxVolume = volume
    }

    func updateUIVolume(_ volume: Float) {
        uiVolume = volume
    }
}

extension HapticManager {
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }

    func setIntensity(_ intensity: Float) {
        intensityMultiplier = intensity
    }
}
