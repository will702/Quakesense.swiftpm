import CoreHaptics
import UIKit

final class HapticManager: @unchecked Sendable {
    static let shared = HapticManager()

    private var engine: CHHapticEngine?
    private var player: CHHapticAdvancedPatternPlayer?
    private(set) var isSupported: Bool = false

    // Settings
    var isEnabled: Bool = true
    var intensityMultiplier: Float = 0.8

    private init() {
        isSupported = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        guard isSupported else { return }
        setupEngine()
    }

    // MARK: - Engine Setup

    private func setupEngine() {
        do {
            engine = try CHHapticEngine()

            engine?.resetHandler = { [weak self] in
                do {
                    try self?.engine?.start()
                } catch {
                    self?.isSupported = false
                }
            }

            engine?.stoppedHandler = { reason in
                // Engine stopped, will restart on next play
            }

            try engine?.start()
        } catch {
            isSupported = false
        }
    }

    // MARK: - Play Patterns

    func playPattern(_ pattern: CHHapticPattern) {
        guard isEnabled, isSupported, let engine = engine else { return }

        do {
            // Modify pattern intensity based on multiplier
            let modifiedPattern = try modifyPatternIntensity(pattern)
            let player = try engine.makeAdvancedPlayer(with: modifiedPattern)
            self.player = player
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            // Silently fail — haptics are nice-to-have
        }
    }

    private func modifyPatternIntensity(_ pattern: CHHapticPattern) throws -> CHHapticPattern {
        guard intensityMultiplier < 1.0 else { return pattern }

        // Get pattern dictionary and modify intensity
        let patternDict = try pattern.exportDictionary()
        var modifiedDict = patternDict

        // Use CoreHaptics Key types
        let patternKey = CHHapticPattern.Key.pattern
        let eventParamsKey = CHHapticPattern.Key.eventParameters
        let paramIDKey = CHHapticPattern.Key.parameterID
        let paramValueKey = CHHapticPattern.Key.parameterValue

        if let events = patternDict[patternKey] as? [[CHHapticPattern.Key: Any]] {
            var modifiedEvents: [[CHHapticPattern.Key: Any]] = []

            for event in events {
                var modifiedEvent = event
                if let eventParams = event[eventParamsKey] as? [[CHHapticPattern.Key: Any]] {
                    var modifiedParams: [[CHHapticPattern.Key: Any]] = []

                    for param in eventParams {
                        var modifiedParam = param
                        if let paramID = param[paramIDKey] as? CHHapticEvent.ParameterID,
                           paramID == .hapticIntensity || paramID == .hapticSharpness {
                            if let value = param[paramValueKey] as? Float {
                                modifiedParam[paramValueKey] = value * intensityMultiplier
                            }
                        }
                        modifiedParams.append(modifiedParam)
                    }
                    modifiedEvent[eventParamsKey] = modifiedParams
                }
                modifiedEvents.append(modifiedEvent)
            }
            modifiedDict[patternKey] = modifiedEvents
        }

        return try CHHapticPattern(dictionary: modifiedDict)
    }

    func stopAll() {
        try? player?.stop(atTime: CHHapticTimeImmediate)
        player = nil
    }

    func prepareEngine() {
        guard isSupported else { return }
        try? engine?.start()
    }

    // MARK: - Convenience Methods

    func playImpact() {
        if let pattern = QuakePatterns.impactPattern() {
            playPattern(pattern)
        }
    }

    func playCorrectFeedback() {
        if let pattern = QuakePatterns.correctChoicePattern() {
            playPattern(pattern)
        }
    }

    func playPWave() {
        if let pattern = QuakePatterns.pWavePattern() {
            playPattern(pattern)
        }
    }

    func playSWave() {
        if let pattern = QuakePatterns.sWavePattern() {
            playPattern(pattern)
        }
    }

    func playAftershock() {
        if let pattern = QuakePatterns.aftershockPattern() {
            playPattern(pattern)
        }
    }
}
