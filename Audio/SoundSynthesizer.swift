import AVFoundation
import Foundation

enum SoundSynthesizer {
    static let sampleRate: Double = 44100

    private static func makeBuffer(duration: TimeInterval) -> AVAudioPCMBuffer? {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        return buffer
    }

    // MARK: - Rumble (improved, 4-layer)

    static func synthesizeRumble() -> AVAudioPCMBuffer? {
        let duration: TimeInterval = 6.0
        guard let buffer = makeBuffer(duration: duration) else { return nil }
        guard let data = buffer.floatChannelData?[0] else { return nil }
        let count = Int(buffer.frameLength)

        for i in 0..<count {
            let t = Double(i) / sampleRate

            // Layer 1: Sub-bass (25Hz + 35Hz)
            let subBass = sin(2 * .pi * 25 * t) + sin(2 * .pi * 35 * t)

            // Layer 2: Low rumble with AM modulation (55Hz modulated at 0.5Hz)
            let rumble = sin(2 * .pi * 55 * t) * (1.0 + 0.3 * sin(2 * .pi * 0.5 * t))

            // Layer 3: Rattling band (filtered noise 150-400Hz approximation)
            let noise = Double.random(in: -1...1)
            let rattle = noise * 0.12

            // Layer 4: Sparse crackle
            let crackle: Double = (i % 500 < 20) ? Double.random(in: -0.08...0.08) : 0

            let sample = Float((subBass * 0.35 + rumble * 0.25 + rattle + crackle) * 0.35)

            // Crossfade at loop boundary (last 0.1s and first 0.1s)
            let fadeFrames = Int(sampleRate * 0.1)
            var envelope: Float = 1.0
            if i < fadeFrames {
                envelope = Float(i) / Float(fadeFrames)
            } else if i > count - fadeFrames {
                envelope = Float(count - i) / Float(fadeFrames)
            }

            data[i] = sample * envelope
        }

        return buffer
    }

    // MARK: - Glass Shatter

    static func synthesizeGlassShatter() -> AVAudioPCMBuffer? {
        let duration: TimeInterval = 0.6
        guard let buffer = makeBuffer(duration: duration) else { return nil }
        guard let data = buffer.floatChannelData?[0] else { return nil }
        let count = Int(buffer.frameLength)

        // Pre-compute resonant frequencies
        let freqs: [Double] = [2800, 3500, 4200, 5000]
        var phases = [Double](repeating: 0, count: freqs.count)

        for i in 0..<count {
            let t = Double(i) / sampleRate
            var sample: Double = 0

            if t < 0.05 {
                // Phase 1: Initial crack — white noise burst
                let noise = Double.random(in: -1...1)
                sample = noise * 0.8 * (1.0 - t / 0.05)
            }

            if t >= 0.05 && t < 0.3 {
                // Phase 2: Shatter cascade — resonant pings + noise
                let decay = exp(-(t - 0.05) * 12)
                for (j, freq) in freqs.enumerated() {
                    phases[j] += 2 * .pi * freq / sampleRate
                    sample += sin(phases[j]) * decay * 0.2 / Double(j + 1)
                }
                sample += Double.random(in: -1...1) * 0.15 * decay
            }

            if t >= 0.3 {
                // Phase 3: Tinkle/settle — quiet random high pings
                let settleDecay = exp(-(t - 0.3) * 5)
                if i % 800 < 100 {
                    let freq = Double.random(in: 3000...6000)
                    let phase = 2 * .pi * freq * t
                    sample += sin(phase) * 0.05 * settleDecay
                }
            }

            data[i] = Float(sample).clamped(to: -1...1)
        }
        return buffer
    }

    // MARK: - Wood Crash

    static func synthesizeWoodCrash() -> AVAudioPCMBuffer? {
        let duration: TimeInterval = 0.5
        guard let buffer = makeBuffer(duration: duration) else { return nil }
        guard let data = buffer.floatChannelData?[0] else { return nil }
        let count = Int(buffer.frameLength)

        var prevSample: Double = 0

        for i in 0..<count {
            let t = Double(i) / sampleRate
            var sample: Double = 0

            // Thud: low sine with fast decay
            if t < 0.15 {
                sample += sin(2 * .pi * 80 * t) * 0.4 * exp(-t * 20)
            }

            // Band-pass noise (100-800Hz approximation)
            let noise = Double.random(in: -1...1)
            let envelope = exp(-t * 7) * 0.5

            // Simple low-pass at ~800Hz
            let alpha = 2.0 * Double.pi * 800 / (2.0 * Double.pi * 800 + sampleRate)
            prevSample = alpha * noise + (1 - alpha) * prevSample
            sample += prevSample * envelope

            // Higher crack burst at t=0.02s
            if t > 0.02 && t < 0.1 {
                let crackDecay = exp(-(t - 0.02) * 20)
                sample += Double.random(in: -1...1) * 0.2 * crackDecay
            }

            data[i] = Float(sample * 0.6).clamped(to: -1...1)
        }
        return buffer
    }

    // MARK: - Creaking

    static func synthesizeCreaking() -> AVAudioPCMBuffer? {
        let duration: TimeInterval = 2.0
        guard let buffer = makeBuffer(duration: duration) else { return nil }
        guard let data = buffer.floatChannelData?[0] else { return nil }
        let count = Int(buffer.frameLength)

        var phase: Double = 0

        for i in 0..<count {
            let t = Double(i) / sampleRate

            // Frequency sweep: 200 → 350 → 250
            let freq: Double
            if t < 1.0 {
                freq = 200 + 150 * sin(.pi * t / 2.0)
            } else {
                freq = 350 - 100 * (t - 1.0)
            }

            phase += 2 * .pi * freq / sampleRate

            var sample = sin(phase)
            sample += sin(phase * 2) * 0.3   // 2nd harmonic
            sample += sin(phase * 3) * 0.15   // 3rd harmonic

            // Noise modulation
            sample *= (1.0 + Double.random(in: -0.1...0.1))

            // Envelope: fade in, sustain, fade out
            var envelope: Double = 1.0
            if t < 0.2 { envelope = t / 0.2 }
            if t > 1.7 { envelope = (2.0 - t) / 0.3 }

            data[i] = Float(sample * envelope * 0.2).clamped(to: -1...1)
        }
        return buffer
    }

    // MARK: - Debris Fall (3 variations)

    static func synthesizeDebrisFall(pitchOffset: Double = 0) -> AVAudioPCMBuffer? {
        let duration: TimeInterval = 0.25
        guard let buffer = makeBuffer(duration: duration) else { return nil }
        guard let data = buffer.floatChannelData?[0] else { return nil }
        let count = Int(buffer.frameLength)

        var phase: Double = 0

        for i in 0..<count {
            let t = Double(i) / sampleRate

            // Descending pitch
            let freq = (600 + pitchOffset) - 1600 * t
            phase += 2 * .pi * Swift.max(freq, 50) / sampleRate

            let envelope = exp(-t * 12)

            var sample = sin(phase) * 0.4 + Double.random(in: -0.3...0.3)
            sample *= envelope

            // Click at start
            if i < 5 { sample += Double.random(in: -0.8...0.8) }

            data[i] = Float(sample * 0.5).clamped(to: -1...1)
        }
        return buffer
    }

    // MARK: - Correct Chime (C5 → E5)

    static func synthesizeCorrectChime() -> AVAudioPCMBuffer? {
        let duration: TimeInterval = 0.4
        guard let buffer = makeBuffer(duration: duration) else { return nil }
        guard let data = buffer.floatChannelData?[0] else { return nil }
        let count = Int(buffer.frameLength)

        for i in 0..<count {
            let t = Double(i) / sampleRate
            var sample: Double = 0

            // Note 1: C5 (523Hz), t=0-0.2
            if t < 0.2 {
                let env1: Double
                if t < 0.002 { env1 = t / 0.002 }
                else if t < 0.1 { env1 = 1.0 }
                else { env1 = (0.2 - t) / 0.1 }

                sample += sin(2 * .pi * 523.25 * t) * env1
                sample += sin(2 * .pi * 523.25 * 2 * t) * 0.2 * env1  // 2nd harmonic
                sample += sin(2 * .pi * 523.25 * 3 * t) * 0.1 * exp(-t * 15)  // bell
            }

            // Note 2: E5 (659Hz), t=0.1-0.4
            if t >= 0.1 {
                let t2 = t - 0.1
                let env2: Double
                if t2 < 0.002 { env2 = t2 / 0.002 }
                else if t2 < 0.15 { env2 = 1.0 }
                else { env2 = Swift.max(0, (0.3 - t2) / 0.15) }

                sample += sin(2 * .pi * 659.25 * t) * env2
                sample += sin(2 * .pi * 659.25 * 2 * t) * 0.2 * env2
                sample += sin(2 * .pi * 659.25 * 3 * t) * 0.1 * exp(-t2 * 15)
            }

            data[i] = Float(sample * 0.4).clamped(to: -1...1)
        }
        return buffer
    }

    // MARK: - Wrong Buzz (descending sawtooth)

    static func synthesizeWrongBuzz() -> AVAudioPCMBuffer? {
        let duration: TimeInterval = 0.35
        guard let buffer = makeBuffer(duration: duration) else { return nil }
        guard let data = buffer.floatChannelData?[0] else { return nil }
        let count = Int(buffer.frameLength)

        var phase: Double = 0

        for i in 0..<count {
            let t = Double(i) / sampleRate

            // Descending frequency: 180 → 120Hz
            let freq = 180 - 170 * (t / duration)
            phase += 2 * .pi * freq / sampleRate

            // Sawtooth from harmonic sum
            var sample: Double = 0
            for k in 1...5 {
                sample += sin(phase * Double(k)) / Double(k)
            }

            sample += Double.random(in: -0.05...0.05)

            // Envelope: sustain then decay
            let envelope: Double
            if t < 0.2 { envelope = 1.0 }
            else { envelope = Swift.max(0, (0.35 - t) / 0.15) }

            data[i] = Float(sample * envelope * 0.3).clamped(to: -1...1)
        }
        return buffer
    }

    // MARK: - Tick (sharp metronome click)

    static func synthesizeTick() -> AVAudioPCMBuffer? {
        let duration: TimeInterval = 0.08
        guard let buffer = makeBuffer(duration: duration) else { return nil }
        guard let data = buffer.floatChannelData?[0] else { return nil }
        let count = Int(buffer.frameLength)

        for i in 0..<count {
            let t = Double(i) / sampleRate
            var sample: Double = 0

            // Sharp high click
            if t < 0.003 {
                sample += sin(2 * .pi * 3000 * t) * 0.7
            }

            // Rapid decay
            let decay = exp(-t * 80)
            sample += sin(2 * .pi * 3000 * t) * decay * 0.3

            // Low thump body
            sample += sin(2 * .pi * 200 * t) * exp(-t * 60) * 0.2

            data[i] = Float(sample).clamped(to: -1...1)
        }
        return buffer
    }

    // MARK: - Ambient Room Tone (looped)

    static func synthesizeAmbientTone() -> AVAudioPCMBuffer? {
        let duration: TimeInterval = 8.0
        guard let buffer = makeBuffer(duration: duration) else { return nil }
        guard let data = buffer.floatChannelData?[0] else { return nil }
        let count = Int(buffer.frameLength)

        var brownian: Double = 0

        for i in 0..<count {
            let t = Double(i) / sampleRate

            // Electrical hum
            let hum = sin(2 * .pi * 60 * t) * 0.02

            // Brownian noise (very quiet random walk)
            brownian += Double.random(in: -0.001...0.001)
            brownian = brownian.clamped(to: -0.01...0.01)

            // Occasional subtle ping
            var ping: Double = 0
            let pingInterval = Int(sampleRate * 2.3)
            if i % pingInterval < Int(sampleRate * 0.05) {
                let freq = 800 + Double(i / pingInterval % 5) * 300
                ping = sin(2 * .pi * freq * t) * 0.03 * exp(-Double(i % pingInterval) / (sampleRate * 0.02))
            }

            var sample = Float(hum + brownian + ping)

            // Crossfade loop
            let fadeFrames = Int(sampleRate * 0.5)
            if i < fadeFrames {
                sample *= Float(i) / Float(fadeFrames)
            } else if i > count - fadeFrames {
                sample *= Float(count - i) / Float(fadeFrames)
            }

            data[i] = sample
        }
        return buffer
    }

    // MARK: - Menu Theme (calm looping ambience for menu, 15–20 s, SSC polish)

    static func synthesizeMenuTheme() -> AVAudioPCMBuffer? {
        let duration: TimeInterval = 18.0
        guard let buffer = makeBuffer(duration: duration) else { return nil }
        guard let data = buffer.floatChannelData?[0] else { return nil }
        let count = Int(buffer.frameLength)

        var phase1: Double = 0
        var phase2: Double = 0
        var phase3: Double = 0

        for i in 0..<count {
            let t = Double(i) / sampleRate

            // Soft pad: two low sine waves (220 Hz + 277 Hz, gentle)
            phase1 += 2 * .pi * 220.0 / sampleRate
            phase2 += 2 * .pi * 277.0 / sampleRate
            let pad = (sin(phase1) * 0.06 + sin(phase2) * 0.04)

            // Gentle high shimmer (800 Hz, very quiet, slow AM)
            phase3 += 2 * .pi * 800.0 / sampleRate
            let shimmer = sin(phase3) * (0.02 + 0.01 * sin(2 * .pi * 0.3 * t))

            // Very soft noise bed
            let noise = Double.random(in: -0.008...0.008)

            var sample = pad + shimmer + noise

            // Crossfade at loop boundaries for seamless loop
            let fadeFrames = Int(sampleRate * 0.8)
            if i < fadeFrames {
                sample *= Double(i) / Double(fadeFrames)
            } else if i > count - fadeFrames {
                sample *= Double(count - i) / Double(fadeFrames)
            }

            data[i] = Float(sample).clamped(to: -1...1)
        }
        return buffer
    }

    // MARK: - Heartbeat (lub-dub pattern)

    static func synthesizeHeartbeat() -> AVAudioPCMBuffer? {
        let duration: TimeInterval = 1.2
        guard let buffer = makeBuffer(duration: duration) else { return nil }
        guard let data = buffer.floatChannelData?[0] else { return nil }
        let count = Int(buffer.frameLength)

        for i in 0..<count {
            let t = Double(i) / sampleRate
            var sample: Double = 0

            // Lub (t=0-0.12)
            if t < 0.12 {
                sample += sin(2 * .pi * 55 * t) * exp(-t * 25) * 0.5
                sample += sin(2 * .pi * 110 * t) * exp(-t * 35) * 0.25
            }

            // Dub (t=0.28-0.38)
            if t >= 0.28 && t < 0.38 {
                let td = t - 0.28
                sample += sin(2 * .pi * 45 * t) * exp(-td * 30) * 0.35
                sample += sin(2 * .pi * 90 * t) * exp(-td * 40) * 0.2
            }

            data[i] = Float(sample).clamped(to: -1...1)
        }
        return buffer
    }
}

