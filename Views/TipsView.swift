import SwiftUI

// MARK: - Story Card Enum

private enum StoryCard: Int, CaseIterable {
    case cover = 0
    case beforeIntro = 1
    case beforeTips = 2
    case duringIntro = 3
    case duringAction = 4
    case afterIntro = 5
    case afterTips = 6
    case finale = 7

    var phaseColor: Color {
        switch self {
        case .cover, .beforeIntro, .beforeTips:
            return AppColors.primaryAccent
        case .duringIntro, .duringAction:
            return AppColors.wrongAction
        case .afterIntro, .afterTips:
            return AppColors.warning
        case .finale:
            return AppColors.correctAction
        }
    }
}

// MARK: - Checklist Item

private struct ChecklistItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let detail: String
}

struct TipsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var showDismiss: Bool = true

    @State private var showIntro = true
    @State private var appeared = false
    @State private var introAnimated = false

    // Story walkthrough state
    @State private var storyPage: Int = 0
    @State private var checkedItems: Set<UUID> = []
    @State private var duringStepReached: Int = 0
    @State private var characterBounce: CGFloat = 0
    @State private var floatPhase = false

    // MARK: - Adaptive Layout Helpers

    private var illustrationSize: CGFloat {
        SizeClassConstants.illustrationSize(for: horizontalSizeClass)
    }

    private var smallIllustrationSize: CGFloat {
        SizeClassConstants.smallIllustrationSize(for: horizontalSizeClass)
    }

    private let beforeChecklist: [ChecklistItem] = [
        ChecklistItem(icon: "hammer.fill", title: String(localized: "Secure heavy furniture"), detail: String(localized: "Bolt bookshelves & cabinets to walls")),
        ChecklistItem(icon: "magnifyingglass", title: String(localized: "Identify safe spots"), detail: String(localized: "Find sturdy tables in every room")),
        ChecklistItem(icon: "cross.case.fill", title: String(localized: "Prepare emergency kit"), detail: String(localized: "Water, flashlight, first aid, whistle")),
        ChecklistItem(icon: "figure.walk", title: String(localized: "Practice regularly"), detail: String(localized: "Rehearse Drop, Cover, Hold On")),
    ]

    private let afterChecklist: [ChecklistItem] = [
        ChecklistItem(icon: "stethoscope", title: String(localized: "Check for injuries"), detail: String(localized: "Help yourself, then help others")),
        ChecklistItem(icon: "flame.fill", title: String(localized: "Check for gas leaks"), detail: String(localized: "Smell gas? Leave immediately")),
        ChecklistItem(icon: "building.2.fill", title: String(localized: "Avoid damaged buildings"), detail: String(localized: "Don't re-enter until cleared")),
        ChecklistItem(icon: "waveform.path.ecg", title: String(localized: "Expect aftershocks"), detail: String(localized: "Stay alert for hours or days")),
        ChecklistItem(icon: "figure.walk.departure", title: String(localized: "Move to open area"), detail: String(localized: "Away from buildings & power lines")),
        ChecklistItem(icon: "arrow.up.arrow.down.square.fill", title: String(localized: "Skip the elevator"), detail: String(localized: "Always use stairs after a quake")),
    ]

    private let duringSteps: [(icon: String, title: String, detail: String, sprite: String)] = [
        ("arrow.down.to.line", String(localized: "DROP"), String(localized: "Get to your hands and knees. This prevents you from being knocked down."), "player_duck"),
        ("shield.fill", String(localized: "COVER"), String(localized: "Get under a sturdy desk or table. Protect your head and neck with your arms."), "player_duck"),
        ("hand.raised.fill", String(localized: "HOLD ON"), String(localized: "Hold on to your shelter. Be ready to move with it until shaking stops."), "player_hold1"),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                // Playful gradient background
                LinearGradient(
                    colors: [Color(hex: 0xF0F4FF), Color(hex: 0xE8ECF5)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // Floating background decorations
                tipsFloatingIcons

                if showIntro {
                    storyWalkthrough
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    timelineContent
                        .transition(.opacity)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                if showDismiss {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(String(localized: "Done")) { dismiss() }
                    }
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    introAnimated = true
                }
                if !(reduceMotion || SettingsManager.shared.isReducedMotionEnabled) {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        characterBounce = -6
                        floatPhase = true
                    }
                }
                #if DEBUG
                if MarketingCapture.isActive && !MarketingCapture.isDemoMode {
                    let target = MarketingCapture.pendingTipsStoryPage
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        storyPage = target
                    }
                }
                #endif
            }
            #if DEBUG
            .task {
                guard MarketingCapture.isDemoMode else { return }
                try? await Task.sleep(for: .milliseconds(800))
                showIntro = false
                for page in 1...5 {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        storyPage = page
                    }
                    try? await Task.sleep(for: .milliseconds(1_500))
                }
                NotificationCenter.default.post(name: MarketingCapture.dismissSheetNotification, object: nil)
            }
            .onReceive(NotificationCenter.default.publisher(for: MarketingCapture.dismissSheetNotification)) { _ in
                if MarketingCapture.isActive {
                    dismiss()
                }
            }
            #endif
        }
    }

    // MARK: - Floating Background Icons

    private var tipsFloatingIcons: some View {
        GeometryReader { geo in
            let icons: [(name: String, x: CGFloat, y: CGFloat, size: CGFloat)] = [
                ("star.fill", 0.1, 0.08, 12),
                ("sparkle", 0.88, 0.12, 14),
                ("star.fill", 0.92, 0.45, 10),
                ("sparkle", 0.05, 0.55, 12),
                ("star.fill", 0.85, 0.75, 11),
                ("sparkle", 0.15, 0.82, 13),
            ]

            ForEach(Array(icons.enumerated()), id: \.offset) { _, icon in
                Image(systemName: icon.name)
                    .font(.system(size: icon.size))
                    .foregroundColor(AppColors.primaryAccent.opacity(0.1))
                    .position(
                        x: geo.size.width * icon.x,
                        y: geo.size.height * icon.y + (floatPhase ? -5 : 5)
                    )
                    .rotationEffect(.degrees(floatPhase ? 8 : -8))
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Story Walkthrough

    private var storyWalkthrough: some View {
        VStack(spacing: 0) {
            // Progress bar
            storyProgressBar
                .padding(.top, 8)

            // Card carousel
            TabView(selection: $storyPage) {
                coverCard.tag(0)
                beforeIntroCard.tag(1)
                beforeTipsCard.tag(2)
                duringIntroCard.tag(3)
                duringActionCard.tag(4)
                afterIntroCard.tag(5)
                afterTipsCard.tag(6)
                roomShowcaseCard.tag(7)
                finaleCard.tag(8)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: storyPage)

            // Custom page dots
            storyPageDots
                .padding(.bottom, 16)
        }
    }

    // MARK: - Progress Bar

    private var storyProgressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.black.opacity(0.1))
                    .frame(height: 3)

                Capsule()
                    .fill(progressColor)
                    .frame(width: geo.size.width * CGFloat(storyPage + 1) / 9.0, height: 3)
                    .animation(.easeInOut(duration: 0.3), value: storyPage)
            }
        }
        .frame(height: 3)
        .padding(.horizontal, 24)
    }

    private var progressColor: Color {
        switch storyPage {
        case 0: return AppColors.primaryAccent
        case 1, 2: return AppColors.primaryAccent
        case 3, 4: return AppColors.wrongAction
        case 5, 6: return AppColors.warning
        case 7: return Color.purple
        case 8: return AppColors.correctAction
        default: return AppColors.primaryAccent
        }
    }

    // MARK: - Page Dots

    private var storyPageDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<9, id: \.self) { index in
                if index == storyPage {
                    Capsule()
                        .fill(dotColor(for: index))
                        .frame(width: 20, height: 6)
                } else {
                    Circle()
                        .fill(Color.black.opacity(0.2))
                        .frame(width: 6, height: 6)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: storyPage)
    }

    private func dotColor(for index: Int) -> Color {
        switch index {
        case 0, 1, 2: return AppColors.primaryAccent
        case 3, 4: return AppColors.wrongAction
        case 5, 6: return AppColors.warning
        case 7: return Color.purple
        case 8: return AppColors.correctAction
        default: return AppColors.primaryAccent
        }
    }

    // MARK: - Card 0: Cover

    private var coverCard: some View {
        VStack(spacing: 0) {
            Spacer()

            // Player character as hero
            ZStack {
                // Animated radial glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppColors.primaryAccent.opacity(floatPhase ? 0.18 : 0.1),
                                AppColors.primaryAccent.opacity(0.05),
                                .clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 120
                        )
                    )
                    .frame(width: illustrationSize, height: illustrationSize)
                    .scaleEffect(floatPhase ? 1.1 : 1.0)

                // Floating icons around player with animations
                tipFloatingElement(icon: "shield.fill", color: AppColors.primaryAccent, angle: -60, distance: illustrationSize * 0.35)
                    .rotationEffect(.degrees(floatPhase ? -5 : 5))
                tipFloatingElement(icon: "book.fill", color: AppColors.correctAction, angle: 45, distance: illustrationSize * 0.33)
                    .rotationEffect(.degrees(floatPhase ? 5 : -5))
                tipFloatingElement(icon: "heart.fill", color: AppColors.wrongAction, angle: 160, distance: illustrationSize * 0.31)
                    .rotationEffect(.degrees(floatPhase ? 8 : -8))

                // Animated stars around player
                ForEach(0..<5) { i in
                    let angle = Double(i) * 72.0
                    let distance: CGFloat = illustrationSize * 0.42 + CGFloat(i % 2) * 15
                    Image(systemName: "star.fill")
                        .font(.system(size: CGFloat(8 + i * 2)))
                        .foregroundColor(AppColors.warning.opacity(0.4 + Double(i) * 0.1))
                        .offset(
                            x: cos(angle * .pi / 180) * distance,
                            y: sin(angle * .pi / 180) * distance + (floatPhase ? (i % 2 == 0 ? -5 : 5) : 0)
                        )
                        .scaleEffect(floatPhase ? 1.2 : 0.9)
                        .rotationEffect(.degrees(floatPhase ? 15 : -15))
                }

                // Player cheering
                Image("player_cheer1")
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: illustrationSize * 0.5, height: illustrationSize * 0.5)
                    .offset(y: characterBounce)
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 6)
            }
            .scaleEffect(introAnimated ? 1 : 0.7)
            .opacity(introAnimated ? 1 : 0)
            .animation(.spring(response: 0.7, dampingFraction: 0.7), value: introAnimated)

            Spacer().frame(height: 24)

            Text(String(localized: "Your Survival Story"))
                .font(.system(.title, design: .rounded).weight(.black))
                .foregroundColor(.primary)
                .opacity(introAnimated ? 1 : 0)
                .offset(y: introAnimated ? 0 : 15)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: introAnimated)

            Spacer().frame(height: 10)

            Text(String(localized: "Learn what to do before, during,\nand after an earthquake"))
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .opacity(introAnimated ? 1 : 0)
                .offset(y: introAnimated ? 0 : 15)
                .animation(.easeOut(duration: 0.5).delay(0.3), value: introAnimated)

            Spacer().frame(height: 28)

            phasePreviewDots
                .opacity(introAnimated ? 1 : 0)
                .offset(y: introAnimated ? 0 : 15)
                .animation(.easeOut(duration: 0.5).delay(0.4), value: introAnimated)

            Spacer()

            swipeHint
                .opacity(introAnimated ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.6), value: introAnimated)

            Spacer().frame(height: 24)
        }
        .padding(.horizontal, horizontalSizeClass == .compact ? 16 : 24)
    }

    // MARK: - Card 1: Before Intro

    private var beforeIntroCard: some View {
        phaseIntroCard(
            phaseLabel: "BEFORE",
            color: AppColors.primaryAccent,
            headline: "The Calm Before",
            narrative: "The ground is still beneath your feet. But smart preparation now could save your life later.",
            playerSprite: "player_stand",
            surroundingIcons: [
                ("hammer.fill", -55.0, 75.0),
                ("cross.case.fill", 50.0, 70.0),
                ("wrench.fill", -140.0, 65.0),
            ],
            storyImageName: "story_before"
        )
    }

    // MARK: - Card 2: Before Tips (Checklist)

    private var beforeTipsCard: some View {
        checklistCard(
            title: "Preparation Checklist",
            color: AppColors.primaryAccent,
            items: beforeChecklist,
            playerSprite: "player_action1"
        )
    }

    // MARK: - Card 3: During Intro

    private var duringIntroCard: some View {
        VStack(spacing: 0) {
            Spacer()

            // Phase pill
            Text(String(localized: "DURING"))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(3)
                .foregroundColor(AppColors.wrongAction)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(AppColors.wrongAction.opacity(0.15))
                        .overlay(Capsule().stroke(AppColors.wrongAction.opacity(0.3), lineWidth: 1))
                )

            Spacer().frame(height: 20)

            // Illustration: optional story_during or seismic wave + player
            ZStack {
                if UIImage(named: "story_during") != nil {
                    Image("story_during")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 300, maxHeight: 180)
                } else {
                    // Seismic waves animation
                    SeismicWavesAnimation()
                        .frame(width: 200, height: 100)

                    // Player sprite
                    Image("player_hurt")
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .offset(y: characterBounce)
                        .shadow(color: .black.opacity(0.12), radius: 6, y: 5)

                    // Warning icons
                    tipFloatingElement(icon: "exclamationmark.triangle.fill", color: AppColors.wrongAction, angle: -50, distance: 75)
                    tipFloatingElement(icon: "bolt.fill", color: AppColors.wrongAction, angle: 50, distance: 72)
                }
            }
            .frame(height: 180)

            Spacer().frame(height: 24)

            Text("The Ground Shakes")
                .font(.system(.title, design: .rounded).weight(.black))
                .foregroundColor(.primary)

            Spacer().frame(height: 10)

            Text("The earthquake strikes without warning. Every second matters — your instincts and training take over.")
                .font(.system(.subheadline, design: .rounded).italic())
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            swipeHint

            Spacer().frame(height: 24)
        }
    }

    // MARK: - Card 4: During Action (DROP/COVER/HOLD)

    private var duringActionCard: some View {
        ScrollView {
            VStack(spacing: 16) {
                Spacer().frame(height: 20)

                Text("What Do You Do?")
                    .font(.system(.title2, design: .rounded).weight(.black))
                    .foregroundColor(.primary)

                Text("Tap each step in order")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)

                ForEach(0..<3, id: \.self) { index in
                    duringStepRow(index: index)
                }

                if duringStepReached >= 3 {
                    VStack(spacing: 8) {
                        Image("player_cheer1")
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .offset(y: characterBounce)

                        Text("You know what to do!")
                            .font(.system(.headline, design: .rounded).weight(.bold))
                            .foregroundColor(AppColors.correctAction)
                    }
                    .padding(.top, 8)
                    .transition(.scale.combined(with: .opacity))
                }

                Spacer().frame(height: 20)
            }
            .adaptivePadding(compact: 16, regular: 24)
        }
    }

    private func duringStepRow(index: Int) -> some View {
        let isUnlocked = index <= duringStepReached
        let isCompleted = index < duringStepReached
        let step = duringSteps[index]
        let color = AppColors.wrongAction

        return Button {
            guard index == duringStepReached, duringStepReached < 3 else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                duringStepReached += 1
            }
        } label: {
            HStack(spacing: 14) {
                // Player sprite instead of plain icon
                ZStack {
                    Circle()
                        .fill(isCompleted ? color : (isUnlocked ? color.opacity(0.15) : Color.black.opacity(0.05)))
                        .frame(width: 50, height: 50)

                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    } else if isUnlocked {
                        Image(step.sprite)
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color.black.opacity(0.25))
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(step.title)
                        .font(.system(.headline, design: .rounded).weight(.black))
                        .foregroundColor(isUnlocked ? .primary : Color.black.opacity(0.25))

                    if isCompleted || (isUnlocked && index == duringStepReached) {
                        Text(step.detail)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer()

                if isUnlocked && !isCompleted {
                    Text("TAP")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().stroke(color, lineWidth: 1.5))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(isUnlocked ? Color.white : Color.black.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isCompleted ? color.opacity(0.4) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isUnlocked ? 1 : 0.97)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: duringStepReached)
    }

    // MARK: - Card 5: After Intro

    private var afterIntroCard: some View {
        phaseIntroCard(
            phaseLabel: "AFTER",
            color: AppColors.warning,
            headline: "The Aftermath",
            narrative: "The shaking has stopped, but the danger isn't over. What you do next is just as important.",
            playerSprite: "player_walk1",
            surroundingIcons: [
                ("stethoscope", -50.0, 70.0),
                ("figure.walk.departure", 55.0, 68.0),
                ("flame.fill", 0.0, -78.0),
            ],
            storyImageName: "story_after"
        )
    }

    // MARK: - Card 6: After Tips (Checklist)

    private var afterTipsCard: some View {
        checklistCard(
            title: "Recovery Checklist",
            color: AppColors.warning,
            items: afterChecklist,
            playerSprite: "player_hold1"
        )
    }

    // MARK: - Card 7: Room Showcase

    private var roomShowcaseCard: some View {
        ScrollView {
            VStack(spacing: 16) {
                Spacer().frame(height: 20)

                Text("Practice Different Rooms")
                    .font(.system(.title2, design: .rounded).weight(.black))
                    .foregroundColor(.primary)

                Text("Each room has unique hazards. Master them all.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)

                // Room previews
                VStack(spacing: 12) {
                    roomPreviewRow(
                        icon: "sofa.fill",
                        name: "Living Room",
                        color: AppColors.primaryAccent,
                        difficulty: 2,
                        hazards: ["Bookshelf", "Window", "Lamp"],
                        safeZone: "Table"
                    )

                    roomPreviewRow(
                        icon: "flame.fill",
                        name: "Kitchen",
                        color: .orange,
                        difficulty: 4,
                        hazards: ["Gas Leak", "Pots", "Fridge"],
                        safeZone: "Island"
                    )

                    roomPreviewRow(
                        icon: "desktopcomputer",
                        name: "Office",
                        color: .purple,
                        difficulty: 3,
                        hazards: ["Cabinet", "Monitor", "Chair"],
                        safeZone: "Desk"
                    )

                    roomPreviewRow(
                        icon: "bed.double.fill",
                        name: "Bedroom",
                        color: .pink,
                        difficulty: 5,
                        hazards: ["Wardrobe", "Mirror", "Nightstand"],
                        safeZone: "Bed"
                    )
                }

                Spacer().frame(height: 8)

                // Unlock hint
                HStack(spacing: 6) {
                    Image(systemName: "lock.open.fill")
                        .font(.caption)
                        .foregroundColor(AppColors.correctAction)

                    Text("Office unlocks after 3 games • Bedroom after 5")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(AppColors.correctAction.opacity(0.1))
                )

                Spacer().frame(height: 20)
            }
            .adaptivePadding(compact: 16, regular: 24)
        }
    }

    private func roomPreviewRow(
        icon: String,
        name: String,
        color: Color,
        difficulty: Int,
        hazards: [String],
        safeZone: String
    ) -> some View {
        HStack(spacing: 12) {
            // Room icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(name)
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundColor(.primary)

                    // Difficulty dots
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { i in
                            Circle()
                                .fill(i <= difficulty ? color : Color.gray.opacity(0.2))
                                .frame(width: 4, height: 4)
                        }
                    }
                }

                // Hazards flow layout
                HStack(spacing: 4) {
                    ForEach(hazards, id: \.self) { hazard in
                        Text(hazard)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(AppColors.wrongAction.opacity(0.8))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(AppColors.wrongAction.opacity(0.1))
                            )
                    }
                }

                // Safe zone indicator
                HStack(spacing: 4) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 8))
                        .foregroundColor(AppColors.correctAction)

                    Text("Safe: \(safeZone)")
                        .font(.system(size: 9, design: .rounded))
                        .foregroundColor(AppColors.correctAction)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Card 8: Finale

    private var finaleCard: some View {
        VStack(spacing: 0) {
            Spacer()

            // Player cheering with celebration effects
            ZStack {
                // Outer glow ring
                Circle()
                    .fill(AppColors.correctAction.opacity(floatPhase ? 0.1 : 0.05))
                    .frame(width: illustrationSize * 0.75, height: illustrationSize * 0.75)
                    .scaleEffect(floatPhase ? 1.1 : 1.0)

                // Sparkle decorations
                ForEach(0..<6, id: \.self) { i in
                    let angle = Double(i) * 60.0
                    let rad = angle * .pi / 180
                    Image(systemName: "star.fill")
                        .font(.system(size: CGFloat(8 + i % 3 * 3)))
                        .foregroundColor(AppColors.correctAction.opacity(0.3))
                        .offset(
                            x: cos(rad) * (floatPhase ? illustrationSize * 0.35 : illustrationSize * 0.31),
                            y: sin(rad) * (floatPhase ? illustrationSize * 0.35 : illustrationSize * 0.31)
                        )
                }

                // Player cheering
                Image("player_cheer1")
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: illustrationSize * 0.5, height: illustrationSize * 0.5)
                    .offset(y: characterBounce)
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 6)
            }

            Spacer().frame(height: 32)

            Text("You're Prepared!")
                .font(.system(.title, design: .rounded).weight(.black))
                .foregroundColor(.primary)

            Spacer().frame(height: 10)

            Text("Knowledge is the best protection.\nExplore the full guide for deeper details.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            // Continue button — game style
            Button {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showIntro = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation { appeared = true }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "book.fill")
                    Text("Continue to Full Guide")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            LinearGradient(
                                colors: [AppColors.correctAction, Color(hex: 0x2AA84B)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .shadow(color: AppColors.correctAction.opacity(0.4), radius: 10, y: 4)
            }
            .padding(.horizontal, 40)

            Spacer().frame(height: 12)

            // Skip option
            Button {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showIntro = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation { appeared = true }
                }
            } label: {
                Text("Skip to Timeline")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.secondary)
            }

            Spacer().frame(height: 40)
        }
    }

    // MARK: - Reusable Phase Intro Card (with player character)

    private func phaseIntroCard(
        phaseLabel: String,
        color: Color,
        headline: String,
        narrative: String,
        playerSprite: String,
        surroundingIcons: [(icon: String, angle: Double, distance: CGFloat)],
        storyImageName: String? = nil
    ) -> some View {
        VStack(spacing: 0) {
            Spacer()

            // Phase pill
            Text(phaseLabel)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(3)
                .foregroundColor(color)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(color.opacity(0.15))
                        .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 1))
                )

            Spacer().frame(height: 20)

            // Illustration: optional story image or player character
            ZStack {
                if let name = storyImageName, UIImage(named: name) != nil {
                    Image(name)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 300, maxHeight: 180)
                } else {
                    // Colored glow behind player
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [color.opacity(floatPhase ? 0.15 : 0.08), .clear],
                                center: .center,
                                startRadius: 15,
                                endRadius: 80
                            )
                        )
                        .frame(width: 180, height: 180)

                    // Floating context icons
                    ForEach(Array(surroundingIcons.enumerated()), id: \.offset) { _, item in
                        tipFloatingElement(icon: item.icon, color: color, angle: item.angle, distance: item.distance)
                    }

                    // Player sprite
                    Image(playerSprite)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .offset(y: characterBounce)
                        .shadow(color: .black.opacity(0.12), radius: 6, y: 5)
                }
            }
            .frame(height: 180)
            .frame(maxWidth: 300)

            Spacer().frame(height: 24)

            // Headline
            Text(headline)
                .font(.system(.title, design: .rounded).weight(.black))
                .foregroundColor(.primary)

            Spacer().frame(height: 10)

            // Narrative
            Text(narrative)
                .font(.system(.subheadline, design: .rounded).italic())
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            swipeHint

            Spacer().frame(height: 24)
        }
    }

    // MARK: - Floating Element Helper

    private func tipFloatingElement(icon: String, color: Color, angle: Double, distance: CGFloat) -> some View {
        let rad = angle * .pi / 180
        let x = cos(rad) * distance
        let y = sin(rad) * distance
        return Image(systemName: icon)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(color.opacity(0.45))
            .offset(x: x, y: y + (floatPhase ? -4 : 4))
            .shadow(color: color.opacity(0.15), radius: 3)
    }

    // MARK: - Reusable Checklist Card (with player character header)

    private func checklistCard(title: String, color: Color, items: [ChecklistItem], playerSprite: String) -> some View {
        let checkedCount = items.filter { checkedItems.contains($0.id) }.count
        return ScrollView {
            VStack(spacing: 12) {
                Spacer().frame(height: 12)

                // Player character as header decoration
                HStack(spacing: 12) {
                    Image(playerSprite)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .offset(y: characterBounce * 0.5)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(.title2, design: .rounded).weight(.black))
                            .foregroundColor(.primary)

                        Text("\(checkedCount) of \(items.count) acknowledged")
                            .font(.system(.caption, design: .rounded).weight(.medium))
                            .foregroundColor(color)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer().frame(height: 4)

                ForEach(items) { item in
                    checklistRow(item: item, color: color)
                }

                if checkedCount == items.count {
                    HStack(spacing: 8) {
                        Image("player_cheer1")
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(width: 32, height: 32)

                        Text("All acknowledged!")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundColor(AppColors.correctAction)
                    }
                    .padding(.top, 4)
                    .transition(.scale.combined(with: .opacity))
                }

                Spacer().frame(height: 20)
            }
            .adaptivePadding(compact: 16, regular: 24)
        }
    }

    private func checklistRow(item: ChecklistItem, color: Color) -> some View {
        let isChecked = checkedItems.contains(item.id)
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                if isChecked {
                    checkedItems.remove(item.id)
                } else {
                    checkedItems.insert(item.id)
                }
            }
        } label: {
            HStack(spacing: 12) {
                // Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isChecked ? color : Color.black.opacity(0.2), lineWidth: 1.5)
                        .frame(width: 26, height: 26)

                    if isChecked {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(color)
                            .frame(width: 26, height: 26)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .scaleEffect(isChecked ? 1.0 : 0.95)

                Image(systemName: item.icon)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(color)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(color.opacity(0.15)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundColor(.primary)
                        .strikethrough(isChecked, color: color.opacity(0.5))

                    Text(item.detail)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isChecked ? color.opacity(0.08) : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isChecked ? color.opacity(0.25) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Swipe Hint

    private var swipeHint: some View {
        HStack(spacing: 6) {
            Text("Swipe to continue")
                .font(.system(.caption, design: .rounded).weight(.medium))
                .foregroundColor(Color.black.opacity(0.3))
            Image(systemName: "chevron.right")
                .font(.caption2.weight(.bold))
                .foregroundColor(Color.black.opacity(0.3))
        }
    }

    // MARK: - Phase Preview Dots

    private var phasePreviewDots: some View {
        HStack(spacing: 20) {
            phaseDot(label: "Before", color: AppColors.primaryAccent, sprite: "player_stand")
            phaseDot(label: "During", color: AppColors.wrongAction, sprite: "player_duck")
            phaseDot(label: "After", color: AppColors.warning, sprite: "player_walk1")
            phaseDot(label: "Rooms", color: Color.purple, sprite: "player_cheer1")
        }
    }

    private func phaseDot(label: String, color: Color, sprite: String) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(sprite)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 30, height: 30)
            }

            Text(label)
                .font(.system(.caption2, design: .rounded).weight(.semibold))
                .foregroundColor(color)
        }
    }

    // MARK: - Timeline Content

    private var timelineContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 20)

                heroHeader

                ForEach(Array(TipPhase.allCases.enumerated()), id: \.element.rawValue) { phaseIndex, phase in
                    let tips = SurvivalTip.tips(for: phase)
                    let previousCount = previousTipCount(before: phaseIndex)
                    let color = phaseColor(phase)

                    VStack(spacing: 0) {
                        // Chapter node
                        chapterHeader(phase: phase, index: phaseIndex, color: color)
                            .opacity(appeared ? 1 : 0)
                            .scaleEffect(appeared ? 1 : 0.6)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.7)
                                    .delay(Double(previousCount) * 0.06),
                                value: appeared
                            )

                        // Tip rows with timeline
                        ForEach(Array(tips.enumerated()), id: \.element.id) { tipIndex, tip in
                            let globalIndex = previousCount + tipIndex
                            timelineTipRow(
                                tip: tip,
                                stepNumber: tipIndex + 1,
                                color: color,
                                isLast: tipIndex == tips.count - 1 && phaseIndex == TipPhase.allCases.count - 1
                            )
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 12)
                            .animation(
                                .easeOut(duration: 0.3).delay(Double(globalIndex) * 0.06),
                                value: appeared
                            )
                        }
                    }
                }

                // End node
                endNode
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.6)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.7).delay(0.9),
                        value: appeared
                    )

                sourcesFooter

                Spacer().frame(height: 30)
            }
            .adaptivePadding(compact: 16, regular: 24)
        }
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(AppColors.primaryAccent.opacity(0.08))
                    .frame(width: 80, height: 80)

                Image("player_cheer1")
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                    .offset(y: characterBounce * 0.5)
            }

            Text("Your Survival Story")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(.primary)

            Text("A timeline guide to earthquake preparedness")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Chapter Header

    private func chapterHeader(phase: TipPhase, index: Int, color: Color) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)

                Image(phaseSprite(phase))
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 26, height: 26)
            }
            .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text("CHAPTER \(index + 1)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(2)
                    .foregroundColor(.secondary)

                Text(phase.localizedName)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundColor(color)

                Text(narrativeIntro(for: phase))
                    .font(.system(.caption, design: .rounded).italic())
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.top, index == 0 ? 0 : 16)
        .padding(.bottom, 8)
    }

    // MARK: - Timeline Tip Row

    private func timelineTipRow(tip: SurvivalTip, stepNumber: Int, color: Color, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack(alignment: .top) {
                Rectangle()
                    .fill(color.opacity(0.35))
                    .frame(width: 2)

                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 26, height: 26)

                    Circle()
                        .stroke(color.opacity(0.6), lineWidth: 1.5)
                        .frame(width: 24, height: 24)

                    Text(String(format: "%02d", stepNumber))
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(color)
                }
                .padding(.top, 14)
            }
            .frame(width: 28)

            tipCard(tip, color: color)
        }
    }

    // MARK: - Tip Card

    private func tipCard(_ tip: SurvivalTip, color: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: tip.icon)
                .font(.caption.weight(.semibold))
                .foregroundColor(color)
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(tip.title)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundColor(.primary)

                Text(tip.detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
        )
    }

    // MARK: - End Node

    private var endNode: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(AppColors.correctAction.opacity(0.12))
                    .frame(width: 48, height: 48)

                Image("player_cheer1")
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 34, height: 34)
            }

            Text("You're prepared!")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundColor(AppColors.correctAction)
        }
        .padding(.top, 8)
    }

    // MARK: - Sources Footer

    private var sourcesFooter: some View {
        Text("Sources: USGS, Red Cross, BMKG Indonesia, Ready.gov")
            .font(.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
    }

    // MARK: - Helpers

    private func phaseColor(_ phase: TipPhase) -> Color {
        switch phase {
        case .before: return AppColors.primaryAccent
        case .during: return AppColors.wrongAction
        case .after:  return AppColors.warning
        case .specialized: return Color.purple
        }
    }

    private func phaseSprite(_ phase: TipPhase) -> String {
        switch phase {
        case .before: return "player_stand"
        case .during: return "player_duck"
        case .specialized: return "player_cheer1"
        case .after:  return "player_walk1"
        }
    }

    private func narrativeIntro(for phase: TipPhase) -> String {
        switch phase {
        case .before: return "The ground is still. Now is the time to prepare."
        case .specialized: return "Specialized scenarios require unique responses."
        case .during: return "The shaking has begun. Every second counts."
        case .after:  return "The shaking stopped. But the danger isn't over."
        }
    }

    private func previousTipCount(before phaseIndex: Int) -> Int {
        TipPhase.allCases.prefix(phaseIndex)
            .reduce(0) { $0 + SurvivalTip.tips(for: $1).count }
    }
}

// MARK: - Seismic Waves Animation

private struct SeismicWavesAnimation: View {
    @State private var wavePhase: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Pulsing rings (like earthquake ripples)
            ForEach(0..<3) { index in
                Circle()
                    .stroke(
                        AppColors.wrongAction.opacity(0.3 - Double(index) * 0.08),
                        lineWidth: 2
                    )
                    .frame(width: 60 + CGFloat(index) * 50, height: 60 + CGFloat(index) * 50)
                    .scaleEffect(pulseScale)
                    .animation(
                        .easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.3),
                        value: pulseScale
                    )
            }

            // Seismic wave lines
            ForEach(0..<4) { index in
                SeismicWavePath(
                    amplitude: 8 + CGFloat(index) * 4,
                    frequency: 1.5 + CGFloat(index) * 0.3,
                    phaseShift: wavePhase + CGFloat(index) * 0.25
                )
                .stroke(
                    AppColors.wrongAction.opacity(0.4 - Double(index) * 0.08),
                    lineWidth: 2
                )
                .frame(height: 60)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                wavePhase = 1.0
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.3
            }
        }
    }
}

// MARK: - Seismic Wave Path

private struct SeismicWavePath: Shape {
    var amplitude: CGFloat
    var frequency: CGFloat
    var phaseShift: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY
        let step: CGFloat = 2

        for x in stride(from: 0, through: rect.width, by: step) {
            let relativeX = x / rect.width
            let y = midY + sin((relativeX * frequency * .pi * 2) + (phaseShift * .pi * 2)) * amplitude
            if x == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        return path
    }
}

// MARK: - Triangle Shape

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
