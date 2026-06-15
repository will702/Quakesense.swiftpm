import SwiftUI

struct MenuView: View {
    @Binding var selectedMagnitude: Double
    @Binding var selectedScenarioType: ScenarioType
    var onStartDrill: () -> Void
    var onShowTips: () -> Void
    var onShowTutorial: () -> Void = {}
    var onShowSettings: () -> Void = {}

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var shakeOffset: CGFloat = 0
    @State private var showAbout = false
    @State private var glowPulse = false

    // Entrance animations
    @State private var heroAppeared = false
    @State private var titleAppeared = false
    @State private var scenarioSectionAppeared = false
    @State private var whyItMattersAppeared = false
    @State private var buttonsAppeared = false

    // Player sprite animation
    @State private var playerFrameIndex = 0
    @State private var playerBounce: CGFloat = 0

    // Floating icons — 3 staggered groups with different durations
    @State private var floatPhase = false
    @State private var floatPhase2 = false
    @State private var floatPhase3 = false

    // Scenario carousel
    @State private var selectedScenarioIndex = 0

    // Each frame: (sprite name, mirrored horizontally?)
    // Body direction stays consistent within each segment to avoid jarring flips
    private let playerFrames: [(sprite: String, mirrored: Bool)] = [
        ("player_stand", false),
        ("player_idle", false),
        ("player_walk1", false),
        ("player_walk2", false),
        ("player_kick", false),    // kick while facing same direction as walk
        ("player_jump", false),
        ("player_cheer1", false),
        // Turn around: all mirrored
        ("player_walk1", true),
        ("player_walk2", true),
        ("player_kick", true),     // kick while facing same direction as mirrored walk
        ("player_jump", true),
        ("player_cheer1", true),
    ]

    // MARK: - Adaptive Layout Helpers

    private var heroHeight: CGFloat {
        verticalSizeClass == .compact ? 140 : 200
    }

    private var scenarioCardWidth: CGFloat {
        SizeClassConstants.scenarioCardWidth(for: horizontalSizeClass)
    }

    private var sectionPadding: CGFloat {
        SizeClassConstants.sectionPadding(for: horizontalSizeClass)
    }

    var body: some View {
        ZStack {
            AnimatedBackground()

            // Floating background icons
            floatingIcons

            ScrollView {
                VStack(spacing: 20) {
                    Spacer().frame(height: 16)

                    // Animated player character hero
                    heroSection
                        .scaleEffect(heroAppeared ? 1.0 : 0.5)
                        .opacity(heroAppeared ? 1.0 : 0)

                    // Title
                    titleSection
                        .offset(y: titleAppeared ? 0 : 30)
                        .opacity(titleAppeared ? 1.0 : 0)

                    // Scenario selection carousel
                    scenarioSection
                        .offset(y: scenarioSectionAppeared ? 0 : 30)
                        .opacity(scenarioSectionAppeared ? 1.0 : 0)

                    // Magnitude slider (only for applicable scenarios)
                    if selectedScenarioType.allowsMagnitudeAdjustment {
                        magnitudeSection
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }

                    // Why It Matters section
                    whyItMattersSection
                        .offset(y: whyItMattersAppeared ? 0 : 30)
                        .opacity(whyItMattersAppeared ? 1.0 : 0)

                    // Buttons
                    buttonsSection
                        .offset(y: buttonsAppeared ? 0 : 40)
                        .opacity(buttonsAppeared ? 1.0 : 0)

                    // Attribution
                    Text(String(localized: "Based on real earthquake survival data from USGS & BMKG"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .opacity(buttonsAppeared ? 1.0 : 0)

                    Spacer().frame(height: 30)
                }
                .adaptivePadding(compact: 16, regular: 24)
            }
        }
        .sheet(isPresented: $showAbout) {
            aboutSheet
        }
        .onAppear {
            let motionDisabled = reduceMotion || SettingsManager.shared.isReducedMotionEnabled

            if !motionDisabled {
                startShakeAnimation()
                startPlayerAnimation()

                withAnimation(.easeInOut(duration: 2.1).repeatForever(autoreverses: true)) {
                    glowPulse = true
                    floatPhase = true
                }
                withAnimation(.easeInOut(duration: 2.7).repeatForever(autoreverses: true)) {
                    floatPhase2 = true
                }
                withAnimation(.easeInOut(duration: 1.9).repeatForever(autoreverses: true)) {
                    floatPhase3 = true
                }
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    playerBounce = -8
                }
            }

            // Staggered entrance
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                heroAppeared = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
                titleAppeared = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5)) {
                scenarioSectionAppeared = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.7)) {
                whyItMattersAppeared = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.9)) {
                buttonsAppeared = true
            }

            // Pre-warm audio engine so it doesn't block game startup
            _ = AudioManager.shared
            AudioManager.shared.prepareEngine()
            AudioManager.shared.playMenuTheme()
        }
        .onDisappear {
            AudioManager.shared.stopMenuTheme()
        }
        .onChange(of: selectedScenarioIndex) { newIndex in
            let scenarios = ScenarioType.allCases
            guard newIndex >= 0, newIndex < scenarios.count else { return }
            selectedScenarioType = scenarios[newIndex]

            // Update magnitude if scenario has a default
            if !scenarios[newIndex].allowsMagnitudeAdjustment {
                selectedMagnitude = scenarios[newIndex].defaultMagnitude
            }
        }
    }

    // MARK: - Floating Background Icons

    private var floatingIcons: some View {
        GeometryReader { geo in
            // group: 0 = floatPhase (2.1s), 1 = floatPhase2 (2.7s), 2 = floatPhase3 (1.9s)
            let icons: [(name: String, x: CGFloat, y: CGFloat, size: CGFloat, group: Int)] = [
                ("figure.run", 0.08, 0.12, 22, 0),
                ("house.fill", 0.88, 0.08, 20, 1),
                ("bolt.trianglebadge.exclamationmark", 0.92, 0.35, 18, 2),
                ("hand.raised.fill", 0.06, 0.42, 20, 1),
                ("star.fill", 0.15, 0.72, 14, 2),
                ("star.fill", 0.85, 0.65, 12, 0),
                ("sparkle", 0.78, 0.78, 16, 1),
                ("sparkle", 0.22, 0.28, 14, 2),
            ]

            ForEach(Array(icons.enumerated()), id: \.offset) { index, icon in
                let phase = icon.group == 0 ? floatPhase : (icon.group == 1 ? floatPhase2 : floatPhase3)
                Image(systemName: icon.name)
                    .font(.system(size: icon.size, weight: .medium))
                    .foregroundColor(AppColors.primaryAccent.opacity(0.15))
                    .position(
                        x: geo.size.width * icon.x,
                        y: geo.size.height * icon.y + (phase ? -6 : 6)
                    )
                    .rotationEffect(.degrees(phase ? 5 : -5))
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Hero Section (Animated Player Character)

    private var heroSection: some View {
        Group {
            if UIImage(named: "menu_hero") != nil {
                Image("menu_hero")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 320)
            } else {
                VStack(spacing: 0) {
                    ZStack {
                        // Radial glow behind player
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [AppColors.primaryAccent.opacity(glowPulse ? 0.15 : 0.08), .clear],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 90
                                )
                            )
                            .frame(width: 180, height: 180)

                        // Floating game element icons around the player
                        floatingGameElement(icon: "helmet", angle: -50, distance: 72, group: 0)
                        floatingGameElement(icon: "table.furniture.fill", angle: 50, distance: 72, group: 1)
                        floatingGameElement(icon: "door.left.hand.open", angle: -130, distance: 68, group: 2)

                        // Player character
                        SpriteBridge.image(named: playerFrames[playerFrameIndex].sprite)
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .scaleEffect(x: playerFrames[playerFrameIndex].mirrored ? -1 : 1)
                            .offset(y: playerBounce)
                            .shadow(color: .black.opacity(0.15), radius: 8, y: 6)
                    }

                    // Platform / ground
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.green.opacity(0.35), Color.green.opacity(0.15)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 120, height: 12)
                        .offset(y: -4)

                    // Small shadow under platform
                    Ellipse()
                        .fill(Color.black.opacity(0.06))
                        .frame(width: 100, height: 6)
                }
            }
        }
        .frame(height: heroHeight)
    }

    private func floatingGameElement(icon: String, angle: Double, distance: CGFloat, group: Int = 0) -> some View {
        let rad = angle * .pi / 180
        let x = cos(rad) * distance
        let y = sin(rad) * distance
        let phase = group == 0 ? floatPhase : (group == 1 ? floatPhase2 : floatPhase3)
        return Image(systemName: icon)
            .font(.system(.title3, weight: .semibold))
            .foregroundStyle(AppColors.primaryAccent.opacity(0.5))
            .offset(x: x, y: y + (phase ? -4 : 4))
            .shadow(color: AppColors.primaryAccent.opacity(0.2), radius: 4)
    }

    // MARK: - Title

    private var titleSection: some View {
        VStack(spacing: 8) {
            ZStack {
                // Glow behind title
                Text("QuakeSense")
                    .font(.system(.largeTitle, design: .rounded).weight(.black))
                    .foregroundColor(AppColors.wrongAction.opacity(glowPulse ? 0.3 : 0.15))
                    .blur(radius: 24)

                HStack(spacing: 0) {
                    Text("Quake")
                        .font(.system(.largeTitle, design: .rounded).weight(.black))
                        .foregroundColor(AppColors.wrongAction)
                        .offset(x: shakeOffset)

                    Text("Sense")
                        .font(.system(.largeTitle, design: .rounded).weight(.black))
                        .foregroundColor(AppColors.textPrimary)
                }
            }

            Text(String(localized: "Test Your Survival Skills!"))
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppColors.primaryAccent, AppColors.primaryAccent.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
    }

    // MARK: - Scenario Selection Section

    private var scenarioSection: some View {
        VStack(spacing: 12) {
            // Section header
            HStack {
                Text(String(localized: "Scenario"))
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.primary)
                Spacer()

                // Difficulty badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(selectedScenarioType.difficulty.swiftUIColor)
                        .frame(width: 8, height: 8)
                    Text(selectedScenarioType.difficulty.rawValue)
                        .font(.system(.caption, design: .rounded).weight(.medium))
                        .foregroundColor(selectedScenarioType.difficulty.swiftUIColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(selectedScenarioType.difficulty.swiftUIColor.opacity(0.15))
                )
            }

            // Scenario carousel
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: SizeClassConstants.cardSpacing(for: horizontalSizeClass)) {
                        ForEach(Array(ScenarioType.allCases.enumerated()), id: \.element.id) { index, scenario in
                            ScenarioCard(
                                scenario: scenario,
                                isSelected: selectedScenarioIndex == index,
                                width: scenarioCardWidth
                            )
                            .id(index)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    selectedScenarioIndex = index
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                }
                .onChange(of: selectedScenarioIndex) { newValue in
                    withAnimation {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }

            // Selected scenario description
            Text(selectedScenarioType.description)
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
                .animation(.easeInOut(duration: 0.2), value: selectedScenarioType)
        }
        .adaptivePadding(compact: 16, regular: 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .light)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(selectedScenarioType.difficulty.swiftUIColor.opacity(0.4), lineWidth: 1.5)
        )
    }

    // MARK: - Magnitude Slider

    private var magnitudeSection: some View {
        VStack(spacing: 12) {
            HStack {
                // Player reaction based on magnitude
                SpriteBridge.image(named: magnitudePlayerSprite)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 36, height: 36)

                Text(String(localized: "Magnitude"))
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.primary)
                Spacer()
                Text(String(format: "M %.1f", selectedMagnitude))
                    .font(.system(.title, design: .rounded).weight(.bold))
                    .foregroundColor(magnitudeColor)
                    .contentTransition(.numericText())
            }

            GameSlider(value: $selectedMagnitude, range: 4.0...8.0, step: 0.5, tintColor: magnitudeColor)
                .frame(height: 30)

            HStack {
                Text(String(localized: "Easy Rumble"))
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundColor(AppColors.correctAction)
                Spacer()
                Text(String(localized: "Total Chaos"))
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundColor(AppColors.wrongAction)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .light)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(magnitudeColor.opacity(0.4), lineWidth: 1.5)
        )
    }

    private var magnitudePlayerSprite: String {
        switch selectedMagnitude {
        case ..<5.5: return "player_stand"
        case ..<7.0: return "player_idle"
        default:     return "player_hurt"
        }
    }

    private var magnitudeColor: Color {
        switch selectedMagnitude {
        case ..<5.5: return AppColors.correctAction
        case ..<7.0: return Color.orange
        default:     return AppColors.wrongAction
        }
    }

    // MARK: - Why It Matters Section

    private var whyItMattersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.headline)
                    .foregroundColor(AppColors.primaryAccent)
                Text(String(localized: "Why It Matters"))
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.primary)
            }

            VStack(alignment: .leading, spacing: 8) {
                StatRow(
                    icon: "cross.fill",
                    color: AppColors.wrongAction,
                    title: String(localized: "Earthquakes cause"),
                    value: String(localized: "thousands of deaths annually"),
                    detail: String(localized: "Most are preventable with proper training")
                )

                StatRow(
                    icon: "clock.fill",
                    color: Color.orange,
                    title: String(localized: "You have"),
                    value: String(localized: "seconds to react"),
                    detail: String(localized: "Quick decisions save lives")
                )

                StatRow(
                    icon: "brain.head.profile",
                    color: AppColors.primaryAccent,
                    title: String(localized: "Muscle memory"),
                    value: String(localized: "saves lives"),
                    detail: String(localized: "Practice builds automatic responses")
                )
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .light)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppColors.primaryAccent.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Buttons

    private var buttonsSection: some View {
        VStack(spacing: 14) {
            // Big PLAY button
            Button(action: onStartDrill) {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                        .font(.title2)
                    Text(String(localized: "PLAY"))
                        .font(.system(.title2, design: .rounded).weight(.bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [AppColors.correctAction, Color(hex: 0x2AA84B)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        // Inner highlight
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.15))
                            .padding(2)
                            .mask(
                                LinearGradient(
                                    colors: [.white, .clear],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                    }
                )
                .foregroundColor(.white)
                .shadow(color: AppColors.correctAction.opacity(0.5), radius: 12, y: 6)
            }
            .buttonStyle(BounceButtonStyle())
            .accessibilityHint(String(localized: "Start the earthquake survival drill"))

            // Survival Tips
            Button(action: onShowTips) {
                HStack(spacing: 8) {
                    Image(systemName: "scroll.fill")
                        .font(.body)
                    Text(String(localized: "SURVIVAL TIPS"))
                        .font(.system(.headline, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .light)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.primaryAccent.opacity(0.5), lineWidth: 1.5)
                )
                .foregroundColor(AppColors.primaryAccent)
            }
            .buttonStyle(BounceButtonStyle())
            .accessibilityHint(String(localized: "View earthquake survival tips"))

            // Tutorial Replay
            Button(action: onShowTutorial) {
                HStack(spacing: 8) {
                    Image(systemName: "play.circle.fill")
                        .font(.body)
                    Text(String(localized: "TUTORIAL"))
                        .font(.system(.headline, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .light)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.5), lineWidth: 1.5)
                )
                .foregroundColor(Color.orange)
            }
            .buttonStyle(BounceButtonStyle())
            .accessibilityHint(String(localized: "Replay the tutorial"))

            // Settings
            Button(action: onShowSettings) {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape.fill")
                        .font(.body)
                    Text(String(localized: "SETTINGS"))
                        .font(.system(.headline, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .light)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1.5)
                )
                .foregroundColor(Color.gray)
            }
            .buttonStyle(BounceButtonStyle())
            .accessibilityHint(String(localized: "Open settings"))

            Button(action: { showAbout = true }) {
                HStack {
                    Image(systemName: "info.circle")
                    Text(String(localized: "About"))
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .accessibilityHint(String(localized: "Learn about QuakeSense"))
        }
    }

    // MARK: - About Sheet

    private var aboutSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(String(localized: "QuakeSense is an interactive earthquake survival simulator designed to teach life-saving decisions through real-time pressure and physics simulation."))
                        .font(.body)

                    Text(String(localized: "Built for the Apple Swift Student Challenge 2026."))
                        .font(.body)
                        .foregroundColor(.secondary)

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Label(String(localized: "SpriteKit — Physics & Rendering"), systemImage: "gamecontroller")
                        Label(String(localized: "Core Haptics — Earthquake Rumble"), systemImage: "hand.tap")
                        Label(String(localized: "AVFoundation — Layered Audio"), systemImage: "speaker.wave.3")
                        Label(String(localized: "SwiftUI — Interface & Navigation"), systemImage: "rectangle.3.group")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                    Divider()

                    Text(String(localized: "Sources: USGS, Red Cross, BMKG Indonesia, Ready.gov"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(24)
            }
            .navigationTitle(String(localized: "About QuakeSense"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showAbout = false }
                }
            }
        }
    }

    // MARK: - Animations

    private func startShakeAnimation() {
        withAnimation(.easeInOut(duration: 0.15).repeatForever(autoreverses: true)) {
            shakeOffset = 2.5
        }
    }

    private func startPlayerAnimation() {
        // Cycle through player frames for idle animation
        Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.2)) {
                    playerFrameIndex = (playerFrameIndex + 1) % playerFrames.count
                }
            }
        }
    }
}

// MARK: - Scenario Card

struct ScenarioCard: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let scenario: ScenarioType
    let isSelected: Bool
    let width: CGFloat

    init(scenario: ScenarioType, isSelected: Bool, width: CGFloat = 90) {
        self.scenario = scenario
        self.isSelected = isSelected
        self.width = width
    }

    var body: some View {
        VStack(spacing: 10) {
            // Icon
            ZStack {
                Circle()
                    .fill(isSelected ? scenario.difficulty.swiftUIColor.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 56, height: 56)

                Image(systemName: scenario.icon)
                    .font(.system(.title2, weight: .semibold))
                    .foregroundColor(isSelected ? scenario.difficulty.swiftUIColor : .gray)
            }

            // Name
            Text(scenario.displayName)
                .font(.system(.caption, design: .rounded).weight(isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .primary : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(width: width)
        .padding(.vertical, 12)
        .padding(.horizontal, horizontalSizeClass == .compact ? 6 : 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? scenario.difficulty.swiftUIColor.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? scenario.difficulty.swiftUIColor.opacity(0.5) : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(scenario.displayName) scenario, \(scenario.difficulty.rawValue) difficulty")
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}

// MARK: - Bounce Button Style

private struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: configuration.isPressed)
    }
}

// MARK: - Custom Game Slider (works inside ScrollView)

private struct GameSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    var tintColor: Color = .blue

    @State private var isDragging = false

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let fraction = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
            let thumbX = fraction * width

            ZStack(alignment: .leading) {
                // Track background
                Capsule()
                    .fill(Color.black.opacity(0.08))
                    .frame(height: 6)

                // Filled track
                Capsule()
                    .fill(tintColor)
                    .frame(width: max(0, thumbX), height: 6)

                // Thumb
                Circle()
                    .fill(.white)
                    .frame(width: 28, height: 28)
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                    .overlay(
                        Circle()
                            .fill(tintColor)
                            .frame(width: 12, height: 12)
                    )
                    .scaleEffect(isDragging ? 1.15 : 1.0)
                    .position(x: thumbX, y: geo.size.height / 2)
            }
            .frame(height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        isDragging = true
                        let fraction = max(0, min(1, drag.location.x / width))
                        let raw = range.lowerBound + fraction * (range.upperBound - range.lowerBound)
                        let stepped = (raw / step).rounded() * step
                        value = min(range.upperBound, max(range.lowerBound, stepped))
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
        }
        .accessibilityRepresentation {
            Slider(value: $value, in: range, step: step) {
                Text(String(localized: "Earthquake magnitude"))
            }
        }
        .accessibilityValue(String(format: "M %.1f", value))
    }
}

// MARK: - Stat Row Component

struct StatRow: View {
    let icon: String
    let color: Color
    let title: String
    let value: String
    let detail: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundColor(.primary)
                Text(detail)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
