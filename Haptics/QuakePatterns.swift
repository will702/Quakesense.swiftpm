import CoreHaptics

enum QuakePatterns {

    // MARK: - P-Wave (gentle building rumble, ~2 seconds)

    static func pWavePattern() -> CHHapticPattern? {
        var events: [CHHapticEvent] = []

        let duration: TimeInterval = 2.0
        let step: TimeInterval = 0.1

        for t in stride(from: 0.0, to: duration, by: step) {
            let progress = Float(t / duration)
            let intensity = CHHapticEventParameter(
                parameterID: .hapticIntensity,
                value: 0.2 + progress * 0.2
            )
            let sharpness = CHHapticEventParameter(
                parameterID: .hapticSharpness,
                value: 0.1 + progress * 0.1
            )
            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [intensity, sharpness],
                relativeTime: t,
                duration: step
            )
            events.append(event)
        }

        return try? CHHapticPattern(events: events, parameters: [])
    }

    // MARK: - S-Wave (intense chaotic shaking, ~6 seconds)

    static func sWavePattern() -> CHHapticPattern? {
        var events: [CHHapticEvent] = []

        // Continuous rumble base
        let rumbleIntensity = CHHapticEventParameter(
            parameterID: .hapticIntensity, value: 0.7
        )
        let rumbleSharpness = CHHapticEventParameter(
            parameterID: .hapticSharpness, value: 0.3
        )
        events.append(CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [rumbleIntensity, rumbleSharpness],
            relativeTime: 0,
            duration: 6.0
        ))

        // Transient hits at irregular intervals
        var t: TimeInterval = 0.1
        while t < 6.0 {
            let intensity = CHHapticEventParameter(
                parameterID: .hapticIntensity,
                value: Float.random(in: 0.7...1.0)
            )
            let sharpness = CHHapticEventParameter(
                parameterID: .hapticSharpness,
                value: Float.random(in: 0.5...1.0)
            )
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [intensity, sharpness],
                relativeTime: t
            ))
            t += TimeInterval.random(in: 0.1...0.3)
        }

        return try? CHHapticPattern(events: events, parameters: [])
    }

    // MARK: - Aftershock (decreasing with jolts, ~4 seconds)

    static func aftershockPattern() -> CHHapticPattern? {
        var events: [CHHapticEvent] = []

        let duration: TimeInterval = 4.0

        // Continuous decaying rumble
        let step: TimeInterval = 0.2
        for t in stride(from: 0.0, to: duration, by: step) {
            let progress = Float(t / duration)
            let intensity = CHHapticEventParameter(
                parameterID: .hapticIntensity,
                value: max(0.1, 0.5 * (1.0 - progress))
            )
            let sharpness = CHHapticEventParameter(
                parameterID: .hapticSharpness,
                value: 0.2
            )
            events.append(CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [intensity, sharpness],
                relativeTime: t,
                duration: step
            ))
        }

        // Occasional sharp jolts
        for t in stride(from: 0.5, to: duration, by: TimeInterval.random(in: 0.8...1.5)) {
            let intensity = CHHapticEventParameter(
                parameterID: .hapticIntensity,
                value: Float.random(in: 0.3...0.6)
            )
            let sharpness = CHHapticEventParameter(
                parameterID: .hapticSharpness,
                value: Float.random(in: 0.6...0.9)
            )
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [intensity, sharpness],
                relativeTime: t
            ))
        }

        return try? CHHapticPattern(events: events, parameters: [])
    }

    // MARK: - Impact (single strong hit)

    static func impactPattern() -> CHHapticPattern? {
        let intensity = CHHapticEventParameter(
            parameterID: .hapticIntensity, value: 1.0
        )
        let sharpness = CHHapticEventParameter(
            parameterID: .hapticSharpness, value: 1.0
        )
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [intensity, sharpness],
            relativeTime: 0
        )

        return try? CHHapticPattern(events: [event], parameters: [])
    }

    // MARK: - Correct Choice (double gentle tap)

    static func correctChoicePattern() -> CHHapticPattern? {
        var events: [CHHapticEvent] = []

        for t in [0.0, 0.15] {
            let intensity = CHHapticEventParameter(
                parameterID: .hapticIntensity, value: 0.5
            )
            let sharpness = CHHapticEventParameter(
                parameterID: .hapticSharpness, value: 0.3
            )
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [intensity, sharpness],
                relativeTime: t
            ))
        }

        return try? CHHapticPattern(events: events, parameters: [])
    }
}
