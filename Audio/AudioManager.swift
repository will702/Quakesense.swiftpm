import AVFoundation

final class AudioManager: @unchecked Sendable {
    static let shared = AudioManager()

    private let audioEngine = AVAudioEngine()
    private let rumbleNode = AVAudioPlayerNode()
    private let impactNode = AVAudioPlayerNode()
    private let ambientNode = AVAudioPlayerNode()
    private let creakNode = AVAudioPlayerNode()
    private let feedbackNode = AVAudioPlayerNode()
    private let heartbeatNode = AVAudioPlayerNode()
    private let menuThemeNode = AVAudioPlayerNode()
    private let mixerNode: AVAudioMixerNode

    private var isEngineRunning = false

    // Volume multipliers (controlled by SettingsManager)
    var ambientVolume: Float = 0.7
    var sfxVolume: Float = 0.8
    var uiVolume: Float = 0.6

    // Synthesized buffers
    private var rumbleBuffer: AVAudioPCMBuffer?
    private var glassShatterBuffer: AVAudioPCMBuffer?
    private var woodCrashBuffer: AVAudioPCMBuffer?
    private var creakingBuffer: AVAudioPCMBuffer?
    private var debrisFallBuffers: [AVAudioPCMBuffer] = []
    private var correctBuffer: AVAudioPCMBuffer?
    private var wrongBuffer: AVAudioPCMBuffer?
    private var tickBuffer: AVAudioPCMBuffer?
    private var ambientBuffer: AVAudioPCMBuffer?
    private var heartbeatBuffer: AVAudioPCMBuffer?
    private var menuThemeBuffer: AVAudioPCMBuffer?
    private var menuThemeFile: AVAudioFile?
    private var menuThemeWantsToPlay = false

    private init() {
        mixerNode = audioEngine.mainMixerNode
        setupEngine()
        synthesizeAllSounds()
    }

    // MARK: - Setup

    private func setupEngine() {
        let nodes = [rumbleNode, impactNode, ambientNode, creakNode, feedbackNode, heartbeatNode, menuThemeNode]
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!

        for node in nodes {
            audioEngine.attach(node)
            audioEngine.connect(node, to: mixerNode, format: format)
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            // Mute output while engine starts to suppress hardware pop/crack
            mixerNode.outputVolume = 0

            try audioEngine.start()
            isEngineRunning = true

            // Let audio hardware settle before unmuting
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                self?.mixerNode.outputVolume = 1.0
            }
        } catch {
            isEngineRunning = false
        }
    }

    // MARK: - Sound Synthesis

    private func synthesizeAllSounds() {
        rumbleBuffer = SoundSynthesizer.synthesizeRumble()
        glassShatterBuffer = SoundSynthesizer.synthesizeGlassShatter()
        woodCrashBuffer = SoundSynthesizer.synthesizeWoodCrash()
        creakingBuffer = SoundSynthesizer.synthesizeCreaking()
        correctBuffer = SoundSynthesizer.synthesizeCorrectChime()
        wrongBuffer = SoundSynthesizer.synthesizeWrongBuzz()
        tickBuffer = SoundSynthesizer.synthesizeTick()
        ambientBuffer = SoundSynthesizer.synthesizeAmbientTone()
        heartbeatBuffer = SoundSynthesizer.synthesizeHeartbeat()
        menuThemeBuffer = SoundSynthesizer.synthesizeMenuTheme()

        // 3 debris fall variations
        for offset in [-50.0, 0.0, 80.0] {
            if let buf = SoundSynthesizer.synthesizeDebrisFall(pitchOffset: offset) {
                debrisFallBuffers.append(buf)
            }
        }
    }

    // MARK: - Rumble

    func playRumble(intensity: Float) {
        guard isEngineRunning, let buffer = rumbleBuffer else { return }
        rumbleNode.volume = intensity.clamped(to: 0...1) * sfxVolume
        if !rumbleNode.isPlaying {
            rumbleNode.scheduleBuffer(buffer, at: nil, options: .loops)
            rumbleNode.play()
        }
    }

    func updateRumbleIntensity(_ intensity: Float) {
        rumbleNode.volume = intensity.clamped(to: 0...1) * sfxVolume
    }

    func stopRumble() {
        rumbleNode.stop()
    }

    // MARK: - Ambient

    func playAmbient() {
        guard isEngineRunning, let buffer = ambientBuffer else { return }
        ambientNode.volume = 0.5 * ambientVolume
        if !ambientNode.isPlaying {
            ambientNode.scheduleBuffer(buffer, at: nil, options: .loops)
            ambientNode.play()
        }
    }

    func stopAmbient() {
        ambientNode.stop()
    }

    // MARK: - Menu Theme (SSC: short looping menu music)

    private func loadMenuThemeFile() -> AVAudioFile? {
        guard let url = Bundle.main.url(forResource: "ethereal_dawn", withExtension: "mp3") else { return nil }
        return try? AVAudioFile(forReading: url)
    }

    func playMenuTheme() {
        guard isEngineRunning else { return }
        menuThemeWantsToPlay = true
        menuThemeNode.stop()

        guard let file = menuThemeFile ?? loadMenuThemeFile() else { return }
        menuThemeFile = file

        // Start at zero volume, fade in after engine has settled
        menuThemeNode.volume = 0
        menuThemeNode.scheduleFile(file, at: nil) { [weak self] in
            self?.menuThemeFileCompletion()
        }
        menuThemeNode.play()

        let targetVolume = 0.35 * ambientVolume
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self = self, self.menuThemeWantsToPlay else { return }
            self.menuThemeNode.volume = targetVolume
        }
    }

    private func menuThemeFileCompletion() {
        guard menuThemeWantsToPlay, let file = menuThemeFile else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.menuThemeWantsToPlay else { return }
            self.menuThemeNode.scheduleFile(file, at: nil) { [weak self] in
                self?.menuThemeFileCompletion()
            }
            self.menuThemeNode.play()
        }
    }

    func stopMenuTheme() {
        menuThemeWantsToPlay = false
        menuThemeNode.stop()
    }

    // MARK: - Impact Sounds

    func playImpact() {
        guard isEngineRunning else { return }
        // Use a random debris fall sound as generic impact
        guard let buffer = debrisFallBuffers.randomElement() else { return }
        impactNode.stop()
        impactNode.volume = 0.5 * sfxVolume
        impactNode.scheduleBuffer(buffer, at: nil)
        impactNode.play()
    }

    func playGlassShatter() {
        guard isEngineRunning, let buffer = glassShatterBuffer else { return }
        impactNode.stop()
        impactNode.volume = 0.7 * sfxVolume
        impactNode.scheduleBuffer(buffer, at: nil)
        impactNode.play()
    }

    func playWoodCrash() {
        guard isEngineRunning, let buffer = woodCrashBuffer else { return }
        impactNode.stop()
        impactNode.volume = 0.6 * sfxVolume
        impactNode.scheduleBuffer(buffer, at: nil)
        impactNode.play()
    }

    func playCreaking() {
        guard isEngineRunning, let buffer = creakingBuffer else { return }
        creakNode.stop()
        creakNode.volume = 0.3 * ambientVolume
        creakNode.scheduleBuffer(buffer, at: nil)
        creakNode.play()
    }

    func playDebrisFall() {
        guard isEngineRunning, let buffer = debrisFallBuffers.randomElement() else { return }
        impactNode.stop()
        impactNode.volume = 0.5 * sfxVolume
        impactNode.scheduleBuffer(buffer, at: nil)
        impactNode.play()
    }

    // MARK: - Heartbeat

    func startHeartbeat() {
        guard isEngineRunning, let buffer = heartbeatBuffer else { return }
        heartbeatNode.volume = 0.4 * ambientVolume
        if !heartbeatNode.isPlaying {
            heartbeatNode.scheduleBuffer(buffer, at: nil, options: .loops)
            heartbeatNode.play()
        }
    }

    func stopHeartbeat() {
        heartbeatNode.stop()
    }

    // MARK: - Feedback

    func playCorrect() {
        guard isEngineRunning, let buffer = correctBuffer else { return }
        feedbackNode.stop()
        feedbackNode.volume = 0.6 * uiVolume
        feedbackNode.scheduleBuffer(buffer, at: nil)
        feedbackNode.play()
    }

    func playWrong() {
        guard isEngineRunning, let buffer = wrongBuffer else { return }
        feedbackNode.stop()
        feedbackNode.volume = 0.5 * uiVolume
        feedbackNode.scheduleBuffer(buffer, at: nil)
        feedbackNode.play()
    }

    func playTick() {
        guard isEngineRunning, let buffer = tickBuffer else { return }
        feedbackNode.stop()
        feedbackNode.volume = 0.7 * uiVolume
        feedbackNode.scheduleBuffer(buffer, at: nil)
        feedbackNode.play()
    }

    // MARK: - Control

    func stopAll() {
        menuThemeWantsToPlay = false
        rumbleNode.stop()
        impactNode.stop()
        ambientNode.stop()
        creakNode.stop()
        feedbackNode.stop()
        heartbeatNode.stop()
        menuThemeNode.stop()
    }

    func prepareEngine() {
        if !isEngineRunning {
            try? audioEngine.start()
            isEngineRunning = true
        }
    }
}

