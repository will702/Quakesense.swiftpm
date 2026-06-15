import SwiftUI

// MARK: - Onboarding Manager

@MainActor
final class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()

    private let hasCompletedOnboardingKey = "quakesense_completed_onboarding"
    private let hasSeenSafetyTipsKey = "quakesense_seen_safety_tips"

    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: hasCompletedOnboardingKey)
        }
    }

    @Published var hasSeenSafetyTips: Bool {
        didSet {
            UserDefaults.standard.set(hasSeenSafetyTips, forKey: hasSeenSafetyTipsKey)
        }
    }

    private init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: hasCompletedOnboardingKey)
        self.hasSeenSafetyTips = UserDefaults.standard.bool(forKey: hasSeenSafetyTipsKey)
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
        hasSeenSafetyTips = false
    }
}

// MARK: - Onboarding Page Model

struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let description: String
    let systemImage: String
    let accentColor: Color
    let tips: [String]
}

// MARK: - Onboarding View

struct OnboardingView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool
    var onSkipToGame: (() -> Void)?
    @StateObject private var manager = OnboardingManager.shared

    @State private var currentPage = 0
    @State private var appearProgress: CGFloat = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: String(localized: "Welcome to QuakeSense"),
            subtitle: String(localized: "In Jakarta, I learned that seconds matter."),
            description: String(localized: "Learn life-saving decisions through realistic earthquake simulations. Test your instincts under pressure and build muscle memory for real emergencies."),
            systemImage: "bolt.shield.fill",
            accentColor: AppColors.primaryAccent,
            tips: [String(localized: "Based on real USGS & Red Cross data"), String(localized: "Safe practice environment"), String(localized: "No internet required")]
        ),
        OnboardingPage(
            title: String(localized: "The Three Phases"),
            subtitle: String(localized: "Understanding Earthquake Waves"),
            description: String(localized: "Earthquakes happen in distinct phases. Each phase requires different survival actions. Recognizing them quickly can save your life."),
            systemImage: "waveform.path.ecg",
            accentColor: Color.orange,
            tips: [String(localized: "P-Wave: Initial gentle warning rumble"), String(localized: "S-Wave: Violent shaking begins"), String(localized: "Aftershock: Secondary waves follow")]
        ),
        // NEW: DROP-COVER-HOLD Tutorial Page
        OnboardingPage(
            title: String(localized: "DROP, COVER, HOLD ON"),
            subtitle: String(localized: "The Life-Saving Technique"),
            description: String(localized: "This simple technique can save your life during an earthquake. Practice until it becomes automatic—muscle memory is your best defense."),
            systemImage: "figure.roll",
            accentColor: AppColors.correctAction,
            tips: [
                String(localized: "DROP to hands and knees immediately"),
                String(localized: "Take COVER under sturdy furniture"),
                String(localized: "HOLD ON until shaking stops completely"),
                String(localized: "Practice regularly—it could save your life!")
            ]
        ),
        OnboardingPage(
            title: String(localized: "Phase 1: P-Wave"),
            subtitle: String(localized: "The Warning"),
            description: String(localized: "The first seismic waves arrive gently. This is your crucial window to find cover. You have only seconds before the main shaking hits."),
            systemImage: "bell.fill",
            accentColor: Color.yellow,
            tips: [String(localized: "Drop to the ground immediately"), String(localized: "Take cover under sturdy furniture"), String(localized: "Stay away from windows and glass")]
        ),
        OnboardingPage(
            title: String(localized: "Phase 2: S-Wave"),
            subtitle: String(localized: "The Main Shock"),
            description: String(localized: "Violent shaking begins. Objects fall, glass shatters, furniture topples. If you're not under cover, protect your head and neck immediately."),
            systemImage: "exclamationmark.triangle.fill",
            accentColor: AppColors.wrongAction,
            tips: [String(localized: "Stay under cover until shaking stops"), String(localized: "Hold on to furniture legs"), String(localized: "Don't run outside - falling debris is deadly")]
        ),
        OnboardingPage(
            title: String(localized: "Phase 3: Aftershock"),
            subtitle: String(localized: "Safety Tasks"),
            description: String(localized: "Main shaking stops, but danger isn't over. Complete critical safety tasks: shut off gas, check injuries, and find safe exit routes."),
            systemImage: "checklist",
            accentColor: AppColors.correctAction,
            tips: [String(localized: "Shut off gas valves to prevent fires"), String(localized: "Check yourself and others for injuries"), String(localized: "Identify safe exit paths")]
        ),
        // NEW: Room Hazard Preview Page
        OnboardingPage(
            title: String(localized: "Know Your Hazards"),
            subtitle: String(localized: "Identify Danger Zones"),
            description: String(localized: "Every room has hazards you should avoid. Learn to identify safe zones (green) versus danger zones (red) before an earthquake strikes."),
            systemImage: "exclamationmark.octagon.fill",
            accentColor: AppColors.wrongAction,
            tips: [
                String(localized: "AVOID: Windows and glass doors"),
                String(localized: "AVOID: Tall furniture that can tip over"),
                String(localized: "AVOID: Heavy hanging objects"),
                String(localized: "SAFE: Under sturdy tables or desks"),
                String(localized: "SAFE: Interior walls away from windows")
            ]
        ),
        OnboardingPage(
            title: String(localized: "How to Play"),
            subtitle: String(localized: "Tap to Survive"),
            description: String(localized: "During the earthquake, tap on safe zones to move your character. Tap on aftershock icons to complete safety tasks. Think fast - every second counts!"),
            systemImage: "hand.tap.fill",
            accentColor: AppColors.primaryAccent,
            tips: [String(localized: "Tap green zones (furniture) for cover"), String(localized: "Avoid red zones (windows, doors)"), String(localized: "Tap icons quickly during aftershock")]
        )
    ]

    var body: some View {
        ZStack {
            // Solid background that fully covers content
            Color(red: 0xFA/255, green: 0xF8/255, blue: 0xF5/255)
                .ignoresSafeArea()

            // Dynamic gradient overlay based on current page
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip buttons
                HStack {
                    // Skip to Game button (visible from page 1+)
                    if currentPage >= 1, let onSkipToGame {
                        Button(action: {
                            manager.completeOnboarding()
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                                isPresented = false
                            }
                            onSkipToGame()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "play.fill")
                                    .font(.caption)
                                Text(String(localized: "Skip to Game"))
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            }
                            .foregroundColor(AppColors.correctAction)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(AppColors.correctAction.opacity(0.12))
                            )
                        }
                    }

                    Spacer()
                    Button(action: skipOnboarding) {
                        Text(String(localized: "Skip"))
                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                    .opacity(currentPage < pages.count - 1 ? 1 : 0)
                }
                .padding(.top, 16)
                .padding(.horizontal, 16)

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        OnboardingPageView(page: page, progress: appearProgress, pageIndex: index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: currentPage)

                // Bottom controls
                bottomControls
                    .padding(.bottom, 40)
                    .padding(.horizontal, 32)
            }
        }
        .onAppear {
            #if DEBUG
            if MarketingCapture.isActive {
                currentPage = MarketingCapture.targetOnboardingPage
            }
            #endif
            withAnimation(.easeOut(duration: 0.6)) {
                appearProgress = 1.0
            }
        }
        #if DEBUG
        .onReceive(NotificationCenter.default.publisher(for: MarketingCapture.dismissSheetNotification)) { _ in
            if MarketingCapture.isActive {
                dismiss()
            }
        }
        .task {
            guard MarketingCapture.isDemoMode else { return }
            // Wait for initial settle
            try? await Task.sleep(for: .milliseconds(500))
            for page in 0..<pages.count {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    currentPage = page
                }
                try? await Task.sleep(for: .milliseconds(1_500))
            }
            // Signal completion — ContentView will dismiss
            NotificationCenter.default.post(name: MarketingCapture.dismissSheetNotification, object: nil)
        }
        #endif
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                pages[currentPage].accentColor.opacity(0.08),
                Color(red: 0xFA/255, green: 0xF8/255, blue: 0xF5/255),
                Color(red: 0xFA/255, green: 0xF8/255, blue: 0xF5/255)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.5), value: currentPage)
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 20) {
            // Page indicators
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Capsule()
                        .fill(index == currentPage ? pages[currentPage].accentColor : Color.gray.opacity(0.3))
                        .frame(width: index == currentPage ? 24 : 8, height: 8)
                        .animation(.spring(response: 0.3), value: currentPage)
                }
            }

            // Navigation buttons
            HStack(spacing: 16) {
                // Back button
                if currentPage > 0 {
                    Button(action: previousPage) {
                        Image(systemName: "chevron.left")
                            .font(.system(.title3, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 56, height: 56)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                // Next/Get Started button
                Button(action: nextPage) {
                    HStack(spacing: 8) {
                        Text(currentPage == pages.count - 1 ? String(localized: "Get Started") : String(localized: "Next"))
                            .font(.system(.headline, design: .rounded).weight(.bold))

                        Image(systemName: currentPage == pages.count - 1 ? "checkmark" : "chevron.right")
                            .font(.system(.subheadline, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [pages[currentPage].accentColor, pages[currentPage].accentColor.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .shadow(color: pages[currentPage].accentColor.opacity(0.4), radius: 12, y: 4)
                }
            }
        }
    }

    // MARK: - Actions

    private func nextPage() {
        if currentPage < pages.count - 1 {
            withAnimation {
                currentPage += 1
            }
        } else {
            completeOnboarding()
        }
    }

    private func previousPage() {
        if currentPage > 0 {
            withAnimation {
                currentPage -= 1
            }
        }
    }

    private func skipOnboarding() {
        completeOnboarding()
    }

    private func completeOnboarding() {
        manager.completeOnboarding()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            isPresented = false
        }
    }
}

// MARK: - Onboarding Page View

struct OnboardingPageView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let page: OnboardingPage
    let progress: CGFloat
    var pageIndex: Int = 0

    @State private var iconBounce = false

    private var iconSize: CGFloat {
        horizontalSizeClass == .compact ? 100 : 140
    }

    private var contentPadding: CGFloat {
        horizontalSizeClass == .compact ? 16 : 24
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer().frame(height: 20)

                // Custom illustrations for specific pages, SF Symbol for others
                if pageIndex == 1 {
                    // Seismic wave diagram for "The Three Phases"
                    SeismicWaveIllustration()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(page.accentColor.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.horizontal, 8)
                } else if pageIndex == 2 {
                    // DROP-COVER-HOLD tutorial illustration
                    DropCoverHoldIllustration()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(page.accentColor.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.horizontal, 8)
                } else if pageIndex == 3 {
                    MiniRoomIllustrationView(phaseType: "pwave")
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(page.accentColor.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.horizontal, 8)
                } else if pageIndex == 4 {
                    MiniRoomIllustrationView(phaseType: "swave")
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(page.accentColor.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.horizontal, 8)
                } else if pageIndex == 5 {
                    MiniRoomIllustrationView(phaseType: "aftershock")
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(page.accentColor.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.horizontal, 8)
                } else if pageIndex == 6 {
                    // Hazard preview illustration
                    HazardPreviewIllustration()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(page.accentColor.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.horizontal, 8)
                } else {
                // Animated icon (default)
                ZStack {
                    // Background glow
                    Circle()
                        .fill(page.accentColor.opacity(0.15))
                        .frame(width: iconSize, height: iconSize)
                        .scaleEffect(iconBounce ? 1.1 : 1.0)

                    // Icon container
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [page.accentColor.opacity(0.2), page.accentColor.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: iconSize * 0.7, height: iconSize * 0.7)

                        Image(systemName: page.systemImage)
                            .font(.system(horizontalSizeClass == .compact ? .title2 : .title, weight: .semibold))
                            .foregroundColor(page.accentColor)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .offset(y: iconBounce ? -8 : 0)
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        iconBounce = true
                    }
                }
                }

                // Text content
                VStack(spacing: 16) {
                    Text(page.title)
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)

                    Text(page.subtitle)
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(page.accentColor)

                    Text(page.description)
                        .font(.system(.body, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                        .padding(.horizontal, 8)
                }
                .opacity(progress)
                .offset(y: (1 - progress) * 20)

                // Tips section
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(page.tips, id: \.self) { tip in
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(page.accentColor)

                            Text(tip)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(.primary)

                            Spacer()
                        }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(page.accentColor.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal, 8)
                .opacity(progress)
                .offset(y: (1 - progress) * 30)

                Spacer().frame(height: 40)
            }
            .adaptivePadding(compact: 16, regular: 24)
        }
    }
}

// MARK: - Seismic Wave Illustration

struct SeismicWaveIllustration: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        Canvas { context, size in
            let midY = size.height / 2
            _ = size.width

            // P-Wave (yellow, gentle)
            drawWave(context: context, size: size, yCenter: midY - 30,
                    amplitude: 8, frequency: 3, phase: phase * 2,
                    color: .yellow, label: "P-Wave")

            // S-Wave (red, violent)
            drawWave(context: context, size: size, yCenter: midY,
                    amplitude: 20, frequency: 5, phase: phase * 4,
                    color: .red, label: "S-Wave")

            // Aftershock (orange, decaying)
            drawWave(context: context, size: size, yCenter: midY + 30,
                    amplitude: 12, frequency: 4, phase: phase * 3,
                    color: .orange, label: "Aftershock", decaying: true)
        }
        .frame(height: 120)
        .onAppear {
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                phase = 1.0
            }
        }
    }

    private func drawWave(context: GraphicsContext, size: CGSize, yCenter: CGFloat,
                          amplitude: CGFloat, frequency: CGFloat, phase: CGFloat,
                          color: Color, label: String, decaying: Bool = false) {
        var path = Path()
        let steps = 80
        let w = size.width - 70
        let startX: CGFloat = 70

        for i in 0...steps {
            let x = startX + (CGFloat(i) / CGFloat(steps)) * w
            let progress = CGFloat(i) / CGFloat(steps)
            let decay: CGFloat = decaying ? (1.0 - progress * 0.7) : 1.0
            let y = yCenter + sin((progress * frequency + phase) * .pi * 2) * amplitude * decay

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        context.stroke(path, with: .color(color), lineWidth: 2.5)

        // Label
        let text = Text(label).font(.system(size: 10, weight: .bold, design: .rounded)).foregroundColor(color)
        context.draw(text, at: CGPoint(x: 36, y: yCenter))
    }
}

// MARK: - Mini Room Illustration

struct MiniRoomIllustrationView: View {
    let phaseType: String // "pwave", "swave", "aftershock"
    @State private var shakeOffset: CGFloat = 0

    var body: some View {
        Canvas { context, size in
            let floorY = size.height * 0.75
            let roomLeft: CGFloat = size.width * 0.15
            let roomRight: CGFloat = size.width * 0.85
            let ceilingY: CGFloat = size.height * 0.2

            // Floor
            var floorPath = Path()
            floorPath.addRect(CGRect(x: roomLeft, y: floorY, width: roomRight - roomLeft, height: 4))
            context.fill(floorPath, with: .color(Color.brown.opacity(0.6)))

            // Walls
            var wallPath = Path()
            wallPath.move(to: CGPoint(x: roomLeft, y: ceilingY))
            wallPath.addLine(to: CGPoint(x: roomLeft, y: floorY))
            wallPath.move(to: CGPoint(x: roomRight, y: ceilingY))
            wallPath.addLine(to: CGPoint(x: roomRight, y: floorY))
            // Ceiling
            wallPath.move(to: CGPoint(x: roomLeft, y: ceilingY))
            wallPath.addLine(to: CGPoint(x: roomRight, y: ceilingY))
            context.stroke(wallPath, with: .color(Color.gray.opacity(0.5)), lineWidth: 2)

            // Table
            let tableX = size.width * 0.45
            let tableW: CGFloat = 50
            let tableH: CGFloat = 25
            let tableY = floorY - tableH
            var tablePath = Path()
            tablePath.addRect(CGRect(x: tableX, y: tableY, width: tableW, height: 4))
            // Legs
            tablePath.addRect(CGRect(x: tableX + 4, y: tableY + 4, width: 3, height: tableH - 4))
            tablePath.addRect(CGRect(x: tableX + tableW - 7, y: tableY + 4, width: 3, height: tableH - 4))
            context.fill(tablePath, with: .color(Color.brown))

            // Player
            let playerX = phaseType == "pwave" ? size.width * 0.35 : tableX + tableW / 2
            let playerY = phaseType == "swave" ? floorY - 8 : floorY - 20
            let playerSize: CGFloat = phaseType == "swave" ? 12 : 16

            // Body
            var playerPath = Path()
            playerPath.addEllipse(in: CGRect(x: playerX - playerSize / 2, y: playerY - playerSize, width: playerSize, height: playerSize))
            context.fill(playerPath, with: .color(Color.blue))

            // Head
            var headPath = Path()
            headPath.addEllipse(in: CGRect(x: playerX - 4, y: playerY - playerSize - 8, width: 8, height: 8))
            context.fill(headPath, with: .color(Color(red: 0.96, green: 0.82, blue: 0.68)))

            // Phase-specific elements
            if phaseType == "pwave" {
                // Warning lines
                let warningText = Text("⚠️").font(.system(size: 14))
                context.draw(warningText, at: CGPoint(x: playerX + 14, y: playerY - playerSize - 10))
            } else if phaseType == "swave" {
                // Falling objects
                for i in 0..<3 {
                    var debrisPath = Path()
                    let dx = CGFloat(i) * 20 + roomLeft + 30
                    debrisPath.addRect(CGRect(x: dx + shakeOffset, y: ceilingY + 20 + CGFloat(i) * 15, width: 6, height: 6))
                    context.fill(debrisPath, with: .color(Color.gray.opacity(0.6)))
                }
            } else {
                // Aftershock task icons
                let icons = ["🔧", "🚪", "🩹"]
                for (i, icon) in icons.enumerated() {
                    let ix = roomLeft + 30 + CGFloat(i) * 60
                    let text = Text(icon).font(.system(size: 12))
                    context.draw(text, at: CGPoint(x: ix, y: floorY - 40))
                }
            }
        }
        .frame(height: 120)
        .onAppear {
            if phaseType == "swave" {
                withAnimation(.easeInOut(duration: 0.15).repeatForever(autoreverses: true)) {
                    shakeOffset = 3
                }
            }
        }
    }
}

// MARK: - DROP-COVER-HOLD Tutorial Illustration

struct DropCoverHoldIllustration: View {
    @State private var animationPhase: Int = 0
    @State private var isCrouching = false

    var body: some View {
        Canvas { context, size in
            let midY = size.height / 2
            let centerX = size.width / 2

            // Step indicators
            let steps = ["DROP", "COVER", "HOLD ON"]
            let stepColors: [Color] = [.blue, .green, .orange]

            for (index, step) in steps.enumerated() {
                let xPos = centerX + CGFloat(index - 1) * 80
                let color = stepColors[index]
                let isHighlighted = animationPhase == index

                // Step circle
                var circle = Path()
                circle.addEllipse(in: CGRect(x: xPos - 20, y: 30, width: 40, height: 40))
                context.fill(circle, with: .color(isHighlighted ? color : color.opacity(0.3)))

                // Step text
                let stepText = Text(step).font(.system(size: 10, weight: .bold)).foregroundColor(.white)
                context.draw(stepText, at: CGPoint(x: xPos, y: 50))

                // Step label
                let labelText = isHighlighted ? stepLabel(for: index) : ""
                let label = Text(labelText).font(.system(size: 9)).foregroundColor(color)
                context.draw(label, at: CGPoint(x: xPos, y: 85))
            }

            // Animated figure
            drawPlayer(context: context, size: size, phase: animationPhase, centerX: centerX, midY: midY)
        }
        .frame(height: 140)
        .onAppear {
            startAnimation()
        }
    }

    private func stepLabel(for index: Int) -> String {
        switch index {
        case 0: return "Get low!"
        case 1: return "Under table!"
        case 2: return "Tight grip!"
        default: return ""
        }
    }

    private func drawPlayer(context: GraphicsContext, size: CGSize, phase: Int, centerX: CGFloat, midY: CGFloat) {
        let playerX = centerX
        let playerY = midY + 20

        switch phase {
        case 0: // DROP - Standing to crouching
            // Body
            var body = Path()
            body.addEllipse(in: CGRect(x: playerX - 12, y: playerY - 15, width: 24, height: 15))
            context.fill(body, with: .color(.blue))

            // Head
            var head = Path()
            head.addEllipse(in: CGRect(x: playerX - 6, y: playerY - 30, width: 12, height: 12))
            context.fill(head, with: .color(Color(red: 0.96, green: 0.82, blue: 0.68)))

            // Arrow pointing down
            let arrow = Text("⬇️").font(.system(size: 20))
            context.draw(arrow, at: CGPoint(x: playerX + 20, y: playerY - 10))

        case 1: // COVER - Under table
            // Table
            var tableTop = Path()
            tableTop.addRect(CGRect(x: centerX - 40, y: playerY - 40, width: 80, height: 5))
            context.fill(tableTop, with: .color(.brown))

            // Table legs
            var legL = Path()
            legL.addRect(CGRect(x: centerX - 35, y: playerY - 35, width: 4, height: 20))
            context.fill(legL, with: .color(.brown))

            var legR = Path()
            legR.addRect(CGRect(x: centerX + 31, y: playerY - 35, width: 4, height: 20))
            context.fill(legR, with: .color(.brown))

            // Player under table (crouched)
            var player = Path()
            player.addEllipse(in: CGRect(x: playerX - 10, y: playerY - 28, width: 20, height: 12))
            context.fill(player, with: .color(.green))

            // Head
            var head = Path()
            head.addEllipse(in: CGRect(x: playerX - 5, y: playerY - 42, width: 10, height: 10))
            context.fill(head, with: .color(Color(red: 0.96, green: 0.82, blue: 0.68)))

            // Shield icon
            let shield = Text("🛡️").font(.system(size: 16))
            context.draw(shield, at: CGPoint(x: playerX + 35, y: playerY - 25))

        case 2: // HOLD ON - Holding table leg
            // Table
            var tableTop = Path()
            tableTop.addRect(CGRect(x: centerX - 40, y: playerY - 40, width: 80, height: 5))
            context.fill(tableTop, with: .color(.brown))

            // Table legs
            var legL = Path()
            legL.addRect(CGRect(x: centerX - 35, y: playerY - 35, width: 4, height: 20))
            context.fill(legL, with: .color(.brown))

            var legR = Path()
            legR.addRect(CGRect(x: centerX + 31, y: playerY - 35, width: 4, height: 20))
            context.fill(legR, with: .color(.brown))

            // Player holding leg
            var player = Path()
            player.addEllipse(in: CGRect(x: playerX - 10, y: playerY - 28, width: 20, height: 12))
            context.fill(player, with: .color(.orange))

            // Head
            var head = Path()
            head.addEllipse(in: CGRect(x: playerX - 5, y: playerY - 42, width: 10, height: 10))
            context.fill(head, with: .color(Color(red: 0.96, green: 0.82, blue: 0.68)))

            // Arm reaching to table leg
            var arm = Path()
            arm.move(to: CGPoint(x: playerX + 8, y: playerY - 22))
            arm.addLine(to: CGPoint(x: centerX + 28, y: playerY - 25))
            arm.addLine(to: CGPoint(x: centerX + 28, y: playerY - 20))
            context.stroke(arm, with: .color(.blue), lineWidth: 3)

            // Hand icon
            let hand = Text("✋").font(.system(size: 14))
            context.draw(hand, at: CGPoint(x: centerX + 38, y: playerY - 20))

        default:
            break
        }
    }

    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.5)) {
                    animationPhase = (animationPhase + 1) % 3
                }
            }
        }
    }
}

// MARK: - Hazard Preview Illustration

struct HazardPreviewIllustration: View {
    @State private var showHazards = false

    var body: some View {
        Canvas { context, size in
            let centerX = size.width / 2
            let centerY = size.height / 2
            let roomWidth: CGFloat = 280
            let roomHeight: CGFloat = 100
            let roomLeft = centerX - roomWidth / 2
            let roomRight = centerX + roomWidth / 2
            let ceilingY = centerY - roomHeight / 2
            let floorY = centerY + roomHeight / 2

            // Room outline
            var room = Path()
            room.move(to: CGPoint(x: roomLeft, y: ceilingY))
            room.addLine(to: CGPoint(x: roomLeft, y: floorY))
            room.addLine(to: CGPoint(x: roomRight, y: floorY))
            room.addLine(to: CGPoint(x: roomRight, y: ceilingY))
            room.closeSubpath()
            context.stroke(room, with: .color(.gray), lineWidth: 2)

            // Safe zone (table) - GREEN
            var tableTop = Path()
            tableTop.addRect(CGRect(x: centerX - 30, y: centerY + 10, width: 60, height: 4))
            context.fill(tableTop, with: .color(.brown))

            var tableLegL = Path()
            tableLegL.addRect(CGRect(x: centerX - 25, y: centerY + 14, width: 3, height: 15))
            context.fill(tableLegL, with: .color(.brown))

            var tableLegR = Path()
            tableLegR.addRect(CGRect(x: centerX + 22, y: centerY + 14, width: 3, height: 15))
            context.fill(tableLegR, with: .color(.brown))

            // SAFE label
            let safeLabel = Text("✓ SAFE").font(.system(size: 10, weight: .bold)).foregroundColor(.green)
            context.draw(safeLabel, at: CGPoint(x: centerX, y: centerY + 45))

            // Window (danger) - RED
            var window = Path()
            window.addRect(CGRect(x: roomLeft + 15, y: ceilingY + 10, width: 35, height: 40))
            context.stroke(window, with: .color(.red), lineWidth: 2)
            context.fill(window, with: .color(.red.opacity(0.2)))

            // DANGER label
            let dangerLabel = Text("✗ DANGER").font(.system(size: 9, weight: .bold)).foregroundColor(.red)
            context.draw(dangerLabel, at: CGPoint(x: roomLeft + 32, y: ceilingY - 8))

            // Door (danger) - RED
            var door = Path()
            door.addRect(CGRect(x: roomRight - 50, y: ceilingY + 5, width: 40, height: 50))
            context.stroke(door, with: .color(.red), lineWidth: 2)

            let doorLabel = Text("✗").font(.system(size: 12)).foregroundColor(.red)
            context.draw(doorLabel, at: CGPoint(x: roomRight - 30, y: ceilingY - 8))

            // Bookshelf (fall hazard) - RED
            var bookshelf = Path()
            bookshelf.addRect(CGRect(x: roomRight - 70, y: floorY - 35, width: 12, height: 35))
            context.fill(bookshelf, with: .color(.gray))

            let fallLabel = Text("⚠️").font(.system(size: 12))
            context.draw(fallLabel, at: CGPoint(x: roomRight - 64, y: floorY - 50))

            // Ceiling lamp (fall hazard) - RED
            var lampCord = Path()
            lampCord.move(to: CGPoint(x: centerX, y: ceilingY))
            lampCord.addLine(to: CGPoint(x: centerX, y: ceilingY + 20))
            context.stroke(lampCord, with: .color(.gray), lineWidth: 1)

            var lamp = Path()
            lamp.addEllipse(in: CGRect(x: centerX - 8, y: ceilingY + 20, width: 16, height: 10))
            context.fill(lamp, with: .color(.yellow))

            // Legend
            let legendY = floorY + 25
            let legendSafe = Text("✓ Safe Zone").font(.system(size: 9)).foregroundColor(.green)
            context.draw(legendSafe, at: CGPoint(x: roomLeft + 10, y: legendY))

            let legendDanger = Text("✗ Danger Zone").font(.system(size: 9)).foregroundColor(.red)
            context.draw(legendDanger, at: CGPoint(x: roomLeft + 80, y: legendY))

            let legendFall = Text("⚠️ Fall Hazard").font(.system(size: 9)).foregroundColor(.orange)
            context.draw(legendFall, at: CGPoint(x: roomLeft + 170, y: legendY))
        }
        .frame(height: 140)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                showHazards = true
            }
        }
    }
}

// MARK: - First Game Hint Overlay

struct FirstGameHintOverlay: View {
    let phase: QuakePhase
    let onDismiss: () -> Void

    @State private var appearProgress: CGFloat = 0
    @State private var pulseAnimation = false

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black
                .opacity(0.6 * appearProgress)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // Hint content
            VStack(spacing: 20) {
                Spacer()

                // Pulsing indicator pointing to action area
                if phase == .pWave || phase == .sWave {
                    VStack(spacing: 12) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(.largeTitle))
                            .foregroundColor(.white)
                            .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                            .opacity(pulseAnimation ? 0.8 : 1.0)

                        Text(String(localized: "Tap the table to take cover!"))
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                } else if phase == .aftershock {
                    VStack(spacing: 12) {
                        Image(systemName: "checklist")
                            .font(.system(.largeTitle))
                            .foregroundColor(.white)
                            .scaleEffect(pulseAnimation ? 1.2 : 1.0)

                        Text(String(localized: "Complete the safety tasks!"))
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Text(String(localized: "Tap the glowing icons to shut off gas, check injuries, and find exits"))
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }

                Spacer()

                // Dismiss button
                Button(action: dismiss) {
                    Text(String(localized: "Got it"))
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.white)
                        )
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 32)
            .opacity(appearProgress)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                appearProgress = 1.0
            }
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeIn(duration: 0.3)) {
            appearProgress = 0.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(isPresented: .constant(true))
}
