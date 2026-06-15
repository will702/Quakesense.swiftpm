import SwiftUI
import SpriteKit

// MARK: - App Screen State

enum AppScreen: Hashable {
    case menu
    case roomSelection
    case game(roomType: RoomBuilder.RoomType)
    case debrief(EnhancedDebriefReport, roomType: RoomBuilder.RoomType)
    case tips
    case achievements
}

// MARK: - Room Unlock Manager

@MainActor
final class RoomUnlockManager: ObservableObject {
    static let shared = RoomUnlockManager()
    
    @Published private(set) var unlockedRooms: Set<RoomBuilder.RoomType>
    @Published private(set) var roomPlayCounts: [RoomBuilder.RoomType: Int]
    @Published private(set) var roomBestScores: [RoomBuilder.RoomType: Int]
    
    private let unlockedKey = "quakesense_unlocked_rooms"
    private let playCountsKey = "quakesense_room_play_counts"
    private let bestScoresKey = "quakesense_room_best_scores"
    
    private init() {
        // Load unlocked rooms
        let savedUnlocked = UserDefaults.standard.stringArray(forKey: unlockedKey) ?? []
        var rooms: Set<RoomBuilder.RoomType> = [.livingRoom, .kitchen] // Default unlocked
        
        for roomName in savedUnlocked {
            if let room = RoomUnlockManager.roomType(from: roomName) {
                rooms.insert(room)
            }
        }
        self.unlockedRooms = rooms
        
        // Load play counts
        if let savedCounts = UserDefaults.standard.dictionary(forKey: playCountsKey) as? [String: Int] {
            var counts: [RoomBuilder.RoomType: Int] = [:]
            for (key, value) in savedCounts {
                if let room = RoomUnlockManager.roomType(from: key) {
                    counts[room] = value
                }
            }
            self.roomPlayCounts = counts
        } else {
            self.roomPlayCounts = [:]
        }
        
        // Load best scores
        if let savedScores = UserDefaults.standard.dictionary(forKey: bestScoresKey) as? [String: Int] {
            var scores: [RoomBuilder.RoomType: Int] = [:]
            for (key, value) in savedScores {
                if let room = RoomUnlockManager.roomType(from: key) {
                    scores[room] = value
                }
            }
            self.roomBestScores = scores
        } else {
            self.roomBestScores = [:]
        }
    }
    
    private static func roomType(from string: String) -> RoomBuilder.RoomType? {
        switch string {
        case "livingRoom": return .livingRoom
        case "kitchen": return .kitchen
        case "office": return .office
        case "bedroom": return .bedroom
        default: return nil
        }
    }
    
    static func string(from roomType: RoomBuilder.RoomType) -> String {
        switch roomType {
        case .livingRoom: return "livingRoom"
        case .kitchen: return "kitchen"
        case .office: return "office"
        case .bedroom: return "bedroom"
        }
    }
    
    func isUnlocked(_ roomType: RoomBuilder.RoomType) -> Bool {
        unlockedRooms.contains(roomType)
    }
    
    func unlock(_ roomType: RoomBuilder.RoomType) {
        unlockedRooms.insert(roomType)
        save()
    }
    
    func recordGamePlayed(roomType: RoomBuilder.RoomType, score: Int) {
        // Update play count
        roomPlayCounts[roomType, default: 0] += 1
        
        // Update best score
        let currentBest = roomBestScores[roomType] ?? 0
        if score > currentBest {
            roomBestScores[roomType] = score
        }
        
        // Check for unlocks
        checkUnlocks(roomType: roomType)
        
        save()
    }
    
    private func checkUnlocks(roomType: RoomBuilder.RoomType) {
        let playCount = roomPlayCounts[roomType] ?? 0
        
        // Office unlocks after 3 games in living room or kitchen
        if !isUnlocked(.office) && (roomType == .livingRoom || roomType == .kitchen) && playCount >= 3 {
            unlock(.office)
        }
        
        // Bedroom unlocks after 5 total games across all rooms
        if !isUnlocked(.bedroom) {
            let totalGames = roomPlayCounts.values.reduce(0, +)
            if totalGames >= 5 {
                unlock(.bedroom)
            }
        }
    }
    
    func getPlayCount(for roomType: RoomBuilder.RoomType) -> Int {
        roomPlayCounts[roomType] ?? 0
    }
    
    func getBestScore(for roomType: RoomBuilder.RoomType) -> Int? {
        roomBestScores[roomType]
    }
    
    private func save() {
        // Save unlocked rooms
        let roomStrings = unlockedRooms.map { RoomUnlockManager.string(from: $0) }
        UserDefaults.standard.set(roomStrings, forKey: unlockedKey)
        
        // Save play counts
        var countsDict: [String: Int] = [:]
        for (room, count) in roomPlayCounts {
            countsDict[RoomUnlockManager.string(from: room)] = count
        }
        UserDefaults.standard.set(countsDict, forKey: playCountsKey)
        
        // Save best scores
        var scoresDict: [String: Int] = [:]
        for (room, score) in roomBestScores {
            scoresDict[RoomUnlockManager.string(from: room)] = score
        }
        UserDefaults.standard.set(scoresDict, forKey: bestScoresKey)
    }
    
    func reset() {
        unlockedRooms = [.livingRoom, .kitchen]
        roomPlayCounts = [:]
        roomBestScores = [:]
        save()
    }
}

// MARK: - Main Content View

struct ContentView: View {
    @State private var currentScreen: AppScreen = .menu
    @State private var selectedMagnitude: Double = 6.5
    @State private var selectedScenarioType: ScenarioType = .standard
    @State private var selectedRoom: RoomBuilder.RoomType = .livingRoom
    @State private var showTips = false
    @State private var showAchievements = false
    @State private var showSettings = false

    // Room unlock manager
    @StateObject private var roomUnlockManager = RoomUnlockManager.shared

    // Achievement store
    @StateObject private var achievementStore = AchievementStore.shared

    // Onboarding manager
    @StateObject private var onboardingManager = OnboardingManager.shared
    @State private var showOnboarding = false

    // Newly unlocked items for notifications
    @State private var newlyUnlockedRoom: RoomBuilder.RoomType?
    @State private var showUnlockNotification = false
    @State private var recentlyUnlockedAchievements: [Achievement] = []
    @State private var showAchievementToast = false
    var body: some View {
        ZStack {
            // Persistent background so transition from game → debrief never shows black
            Color(hex: 0xF2F2F7)
                .ignoresSafeArea()

            // Main navigation content
            mainContent

            // Onboarding overlay
            if showOnboarding {
                OnboardingView(isPresented: $showOnboarding, onSkipToGame: {
                    // Jump straight to game with defaults (M6.5, living room)
                    selectedMagnitude = 6.5
                    selectedRoom = .livingRoom
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
                            currentScreen = .game(roomType: .livingRoom)
                        }
                    }
                })
                .transition(.opacity.combined(with: .scale(scale: 1.1)))
                .zIndex(200)
            }

            // Achievement unlock toast
            if showAchievementToast, let achievement = recentlyUnlockedAchievements.first {
                AchievementUnlockToast(achievement: achievement) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showAchievementToast = false
                        recentlyUnlockedAchievements.removeFirst()
                        
                        // Show next achievement if available
                        if !recentlyUnlockedAchievements.isEmpty {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation(.easeIn(duration: 0.3)) {
                                    showAchievementToast = true
                                }
                            }
                        }
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(100)
            }
            
            // Room unlock notification
            if showUnlockNotification, let room = newlyUnlockedRoom {
                RoomUnlockToast(roomType: room) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showUnlockNotification = false
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(100)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: screenID)
        .sheet(isPresented: $showTips) {
            TipsView()
        }
        .sheet(isPresented: $showAchievements) {
            AchievementsView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onAppear {
            #if DEBUG
            if MarketingCapture.isActive {
                Task { @MainActor in
                    if MarketingCapture.isDemoMode {
                        await runDemoCoordinator()
                    } else {
                        await runStillsCoordinator()
                    }
                }
                return
            }
            #endif
            if !onboardingManager.hasCompletedOnboarding {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showOnboarding = true
                    }
                }
            }
        }
        .onChange(of: achievementStore.recentlyUnlocked) { newUnlocks in
            if !newUnlocks.isEmpty {
                recentlyUnlockedAchievements = newUnlocks
                achievementStore.clearRecentlyUnlocked()
                if !showAchievementToast {
                    withAnimation(.easeIn(duration: 0.3)) {
                        showAchievementToast = true
                    }
                }
            }
        }
    }
    
    // MARK: - Main Content Switcher
    
    @ViewBuilder
    private var mainContent: some View {
        switch currentScreen {
        case .menu:
            MenuView(
                selectedMagnitude: $selectedMagnitude,
                selectedScenarioType: $selectedScenarioType,
                onStartDrill: {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        currentScreen = .roomSelection
                    }
                },
                onShowTips: {
                    showTips = true
                },
                onShowTutorial: {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showOnboarding = true
                    }
                },
                onShowSettings: {
                    showSettings = true
                }
            )
            .transition(.opacity)
            .overlay(achievementsButton, alignment: .topTrailing)
            
        case .roomSelection:
            RoomSelectionView(
                selectedRoom: $selectedRoom,
                onRoomSelected: { roomType in
                    // Update selected room and proceed to game
                    selectedRoom = roomType
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
                        currentScreen = .game(roomType: roomType)
                    }
                },
                onBack: {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                        currentScreen = .menu
                    }
                }
            )
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity).animation(.spring(response: 0.5, dampingFraction: 0.85)),
                removal: .move(edge: .leading).combined(with: .opacity).animation(.spring(response: 0.45, dampingFraction: 0.85))
            ))
            
        case .game(let roomType):
            EnhancedGameView(
                magnitude: selectedMagnitude,
                scenarioType: selectedScenarioType,
                roomType: roomType,
                onFinish: { report in
                    // Process results
                    roomUnlockManager.recordGamePlayed(
                        roomType: roomType,
                        score: report.finalScore
                    )
                    checkForNewUnlocks()
                    updateAchievementProgress(from: report)

                    // Switch to debrief immediately so we don't show a black frame
                    // (no loading overlay + delay that caused game view to be torn down first)
                    withAnimation(.easeInOut(duration: 0.35)) {
                        currentScreen = .debrief(report, roomType: roomType)
                    }
                }
            )
            .transition(.opacity)
            
        case .debrief(let report, let roomType):
            DebriefView(
                report: report,
                onTryAgain: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        currentScreen = .menu
                    }
                },
                onShowTips: {
                    showTips = true
                }
            )
            .transition(.asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity).animation(.spring(response: 0.6, dampingFraction: 0.85)),
                removal: .move(edge: .trailing).combined(with: .opacity).animation(.easeInOut(duration: 0.4))
            ))
            .overlay(debriefActionButtons(roomType: roomType), alignment: .bottom)
            
        case .tips:
            TipsView(showDismiss: false)
                .transition(.opacity)
                
        case .achievements:
            // This case is handled by sheet, but included for completeness
            Color.clear
        }
    }
    
    // MARK: - UI Components
    
    private var achievementsButton: some View {
        Button(action: { showAchievements = true }) {
            HStack(spacing: 6) {
                Image(systemName: "trophy.fill")
                    .font(.system(.subheadline, weight: .semibold))
                Text(String(localized: "Achievements"))
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .light)
            )
            .overlay(
                Capsule()
                    .stroke(AppColors.warning.opacity(0.5), lineWidth: 1)
            )
            .foregroundColor(AppColors.warning)
        }
        .buttonStyle(BounceButtonStyle())
        .padding(.top, 16)
        .padding(.trailing, 16)
    }
    
    private func debriefActionButtons(roomType: RoomBuilder.RoomType) -> some View {
        HStack(spacing: 10) {
            // Replay same room
            Button(action: {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
                    currentScreen = .game(roomType: roomType)
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                    Text(String(localized: "Replay"))
                }
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(AppColors.correctAction.opacity(0.15))
                )
                .overlay(
                    Capsule()
                        .stroke(AppColors.correctAction.opacity(0.4), lineWidth: 1)
                )
                .foregroundColor(AppColors.correctAction)
            }
            .buttonStyle(BounceButtonStyle())
            .accessibilityHint(String(localized: "Replay the same room and magnitude"))

            Button(action: { showAchievements = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                    Text(String(localized: "Achievements"))
                }
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(AppColors.warning.opacity(0.15))
                )
                .overlay(
                    Capsule()
                        .stroke(AppColors.warning.opacity(0.4), lineWidth: 1)
                )
                .foregroundColor(AppColors.warning)
            }
            .buttonStyle(BounceButtonStyle())

            Button(action: {
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentScreen = .roomSelection
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "house.fill")
                    Text(String(localized: "New Room"))
                }
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(AppColors.primaryAccent.opacity(0.15))
                )
                .overlay(
                    Capsule()
                        .stroke(AppColors.primaryAccent.opacity(0.4), lineWidth: 1)
                )
                .foregroundColor(AppColors.primaryAccent)
            }
            .buttonStyle(BounceButtonStyle())
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Helper Properties
    
    private var screenID: String {
        switch currentScreen {
        case .menu: return "menu"
        case .roomSelection: return "roomSelection"
        case .game: return "game"
        case .debrief: return "debrief"
        case .tips: return "tips"
        case .achievements: return "achievements"
        }
    }
    
    // MARK: - Unlock & Achievement Logic
    
    private func checkForNewUnlocks() {
        // Trigger a check on the manager
        if !roomUnlockManager.isUnlocked(.office) {
            let livingRoomPlays = roomUnlockManager.getPlayCount(for: .livingRoom)
            let kitchenPlays = roomUnlockManager.getPlayCount(for: .kitchen)
            if livingRoomPlays >= 3 || kitchenPlays >= 3 {
                roomUnlockManager.unlock(.office)
                newlyUnlockedRoom = .office
                showUnlockNotification = true
                return
            }
        }
        
        if !roomUnlockManager.isUnlocked(.bedroom) {
            let totalGames = roomUnlockManager.getPlayCount(for: .livingRoom) +
                           roomUnlockManager.getPlayCount(for: .kitchen) +
                           roomUnlockManager.getPlayCount(for: .office)
            if totalGames >= 5 {
                roomUnlockManager.unlock(.bedroom)
                newlyUnlockedRoom = .bedroom
                showUnlockNotification = true
            }
        }
    }
    
    private func updateAchievementProgress(from report: EnhancedDebriefReport) {
        // First survival achievement
        achievementStore.incrementProgress(id: "first_survival")
        
        // Perfect health achievement
        if report.heartsRemaining == 3 {
            achievementStore.incrementProgress(id: "perfect_health")
        }
        
        // Close call achievement
        if report.heartsRemaining == 1 {
            achievementStore.incrementProgress(id: "close_call")
        }
        
        // Survival expert achievement
        if report.survivalRating == .survived {
            achievementStore.incrementProgress(id: "survival_expert")
        }
        
        // Iron will achievement (M8.0)
        if report.magnitude >= 8.0 {
            achievementStore.incrementProgress(id: "iron_will")
        }
        
        // Speed achievements
        if report.totalTime < 20 {
            achievementStore.incrementProgress(id: "speed_demon")
        }
        if report.totalTime < 15 && report.magnitude >= 7.0 {
            achievementStore.incrementProgress(id: "flash")
        }
        
        // Perfect drill achievement
        let allCorrect = report.decisions.allSatisfy { $0.isCorrect }
        if allCorrect && !report.decisions.isEmpty {
            achievementStore.incrementProgress(id: "perfect_drill")
        }
        
        // Dedicated/Veteran/Master achievements
        let totalGames = roomUnlockManager.getPlayCount(for: selectedRoom)
        achievementStore.updateProgress(id: "dedicated", progress: totalGames)
        achievementStore.updateProgress(id: "veteran", progress: totalGames)
        achievementStore.updateProgress(id: "earthquake_master", progress: totalGames)
        
        // Difficulty master - track unique magnitudes completed
        // This is simplified - in production would track completed magnitudes
        if report.magnitude >= 8.0 {
            achievementStore.incrementProgress(id: "difficulty_master")
        }
    }

    // MARK: - Marketing Capture Coordinators

    #if DEBUG
    @MainActor
    private func runStillsCoordinator() async {
        func snap(_ name: String) { MarketingCapture.capture(name: name) }
        func sleep(_ ms: Int) async { try? await Task.sleep(for: .milliseconds(ms)) }

        await sleep(1_500)

        // 01-menu
        snap("01-menu")
        await sleep(200)

        // 02–05: onboarding pages
        let onboardingSteps: [(Int, String)] = [
            (0, "02-onboarding-welcome"),
            (1, "03-onboarding-three-phases"),
            (3, "04-onboarding-decisions"),
            (7, "05-onboarding-ready")
        ]
        for (page, name) in onboardingSteps {
            MarketingCapture.targetOnboardingPage = page
            withAnimation(.easeOut(duration: 0.3)) { showOnboarding = true }
            await sleep(2_000)
            snap(name)
            withAnimation { showOnboarding = false }
            await sleep(900)
        }

        // 06-rooms
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            currentScreen = .roomSelection
        }
        await sleep(2_000)
        snap("06-rooms")

        // 07-game-shake: real game during S-wave
        // Timeline: story(10s) + calm(3s) + countdown(3s) + P-wave(2s) = 18s to S-wave start
        // Capture at 23s for mid-S-wave with debris flying
        selectedMagnitude = 6.5
        selectedRoom = .livingRoom
        withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
            currentScreen = .game(roomType: .livingRoom)
        }
        await sleep(23_000)
        snap("07-game-shake")
        await sleep(300)

        // 08–10: debrief variants
        let debriefSteps: [(SurvivalRating, String)] = [
            (.survived, "08-debrief-survived"),
            (.injured,  "09-debrief-injured"),
            (.critical, "10-debrief-critical")
        ]
        for (rating, name) in debriefSteps {
            withAnimation(.easeInOut(duration: 0.35)) {
                currentScreen = .debrief(MarketingCapture.makeMockDebriefReport(rating: rating), roomType: .livingRoom)
            }
            await sleep(3_500)
            snap(name)
            await sleep(400)
        }

        // Back to menu for sheets
        withAnimation(.spring(response: 0.45)) { currentScreen = .menu }
        await sleep(1_000)

        // 11–13: tips sections (pages 2=before checklist, 4=during actions, 6=after checklist)
        let tipsSteps: [(Int, String)] = [(2, "11-tips-before"), (4, "12-tips-during"), (6, "13-tips-after")]
        for (page, name) in tipsSteps {
            MarketingCapture.pendingTipsStoryPage = page
            showTips = true
            await sleep(2_800)   // 300ms asyncAfter + TabView animation + settle
            snap(name)
            showTips = false
            await sleep(900)
        }

        // 14-achievements
        MarketingCapture.pendingAchievementsSeed = true
        showAchievements = true
        await sleep(2_500)
        snap("14-achievements")
        showAchievements = false
        await sleep(900)

        // 15-settings
        showSettings = true
        await sleep(2_000)
        snap("15-settings")
        showSettings = false

        MarketingCapture.printOutputPath()
    }

    @MainActor
    private func runDemoCoordinator() async {
        func sleep(_ ms: Int) async { try? await Task.sleep(for: .milliseconds(ms)) }

        // t0: menu idle
        await sleep(1_000)
        MarketingCapture.logTimecode(label: "t0-menu")
        await sleep(3_000)

        // t1: onboarding — OnboardingView .task auto-advances pages in demo mode
        MarketingCapture.logTimecode(label: "t1-onboarding")
        withAnimation(.easeOut(duration: 0.3)) { showOnboarding = true }
        await sleep(14_000)   // 0.5s settle + 8 pages × 1.5s + 1s buffer
        withAnimation { showOnboarding = false }
        await sleep(800)

        // t2: room selection — RoomSelectionView .task auto-taps living room after 4s
        MarketingCapture.logTimecode(label: "t2-rooms")
        MarketingCapture.isDriving = true   // must be set before game starts
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            currentScreen = .roomSelection
        }
        await sleep(3_000)   // room selection visible 3s, then auto-tap fires at t=4s

        // t3: game loads + countdown
        MarketingCapture.logTimecode(label: "t3-countdown")
        await sleep(5_000)

        // t4: P-wave
        MarketingCapture.logTimecode(label: "t4-pwave")
        await sleep(8_000)

        // t5: S-wave — trigger main decision after 3s
        MarketingCapture.logTimecode(label: "t5-shake")
        await sleep(3_000)
        NotificationCenter.default.post(name: MarketingCapture.autoMainDecisionNotification, object: nil)
        await sleep(9_000)

        // t6: aftershock — trigger first task after 3s
        MarketingCapture.logTimecode(label: "t6-aftershock")
        await sleep(3_000)
        NotificationCenter.default.post(name: MarketingCapture.autoAftershockDecisionNotification, object: nil)
        await sleep(5_000)

        // t7: debrief (bypass game natural end)
        MarketingCapture.isDriving = false
        MarketingCapture.logTimecode(label: "t7-debrief")
        withAnimation(.easeInOut(duration: 0.35)) {
            currentScreen = .debrief(MarketingCapture.makeMockDebriefReport(rating: .survived), roomType: .livingRoom)
        }
        await sleep(8_000)

        // t8: back to menu, open tips — TipsView .task auto-advances pages in demo mode
        MarketingCapture.logTimecode(label: "t8-tips")
        withAnimation(.spring(response: 0.45)) { currentScreen = .menu }
        await sleep(1_000)
        showTips = true
        await sleep(10_000)
        showTips = false
        await sleep(800)

        // t9: done
        MarketingCapture.logTimecode(label: "t9-end")
        MarketingCapture.printOutputPath()
    }
    #endif
}

// MARK: - Enhanced Game View

struct EnhancedGameView: View {
    let magnitude: Double
    let scenarioType: ScenarioType
    let roomType: RoomBuilder.RoomType
    let onFinish: (EnhancedDebriefReport) -> Void

    @StateObject private var decisionEngine: DecisionEngine
    @StateObject private var onboardingManager = OnboardingManager.shared
    @State private var scene: QuakeScene?
    @State private var coordinator: GameViewCoordinator?
    @State private var showPhaseHint = false
    @State private var hintPhase: QuakePhase = .pWave

    init(magnitude: Double, scenarioType: ScenarioType, roomType: RoomBuilder.RoomType, onFinish: @escaping (EnhancedDebriefReport) -> Void) {
        self.magnitude = magnitude
        self.scenarioType = scenarioType
        self.roomType = roomType
        self.onFinish = onFinish
        let scenario = QuakeScenario(
            magnitude: magnitude,
            roomType: RoomUnlockManager.string(from: roomType),
            scenarioType: scenarioType
        )
        _decisionEngine = StateObject(wrappedValue: DecisionEngine(scenario: scenario))
    }

    var body: some View {
        ZStack {
            Color(red: 0xFA/255, green: 0xF8/255, blue: 0xF5/255)
                .ignoresSafeArea()

            if let scene = scene {
                SpriteView(scene: scene)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel(String(localized: "Earthquake survival simulation"))
                    .accessibilityHint(String(localized: "Tap to interact with objects in the room"))
            } else {
                gameLoadingView
            }
            
            // Room indicator overlay
            VStack {
                HStack {
                    roomIndicator
                        .padding(.top, 16)
                        .padding(.leading, 16)
                    Spacer()
                }
                Spacer()
            }
        }
        .onAppear {
            DispatchQueue.main.async {
                setupScene()
            }
        }
        .onChange(of: decisionEngine.currentPhase) { newPhase in
            // Show hints during first game
            if !onboardingManager.hasSeenSafetyTips {
                if newPhase == .pWave || newPhase == .aftershock {
                    hintPhase = newPhase
                    showPhaseHint = true
                }
            }
        }
        .overlay(
            Group {
                if showPhaseHint {
                    FirstGameHintOverlay(phase: hintPhase) {
                        showPhaseHint = false
                        onboardingManager.hasSeenSafetyTips = true
                    }
                }
            }
        )
        .onDisappear {
            scene?.removeAllActions()
            scene?.removeAllChildren()
            AudioManager.shared.stopAll()
            HapticManager.shared.stopAll()
        }
    }
    
    private var gameLoadingView: some View {
        VStack(spacing: 20) {
            Spacer()

            // Room icon
            ZStack {
                Circle()
                    .fill(AppColors.primaryAccent.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: roomIcon)
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundColor(AppColors.primaryAccent)
            }

            // Player sprite
            SpriteBridge.image(named: "player_stand")
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: 64, height: 64)

            Text(roomType.displayName)
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundColor(.primary)

            Text(String(format: String(localized: "Magnitude %.1f"), magnitude))
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundColor(.secondary)

            // Random survival tip
            let tips = SurvivalTip.tips(for: .during)
            if let tip = tips.first {
                HStack(spacing: 10) {
                    Image(systemName: tip.icon)
                        .font(.title3)
                        .foregroundColor(AppColors.primaryAccent)
                        .frame(width: 30)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(tip.title)
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundColor(.primary)
                        Text(tip.detail)
                            .font(.system(.caption2, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
                .padding(.horizontal, 40)
            }

            ProgressView()
                .scaleEffect(1.2)
                .padding(.top, 8)

            Text(String(localized: "Preparing room..."))
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.secondary)

            Spacer()
        }
    }

    private var roomIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: roomIcon)
                .font(.system(.subheadline, weight: .semibold))
            Text(roomType.displayName)
                .font(.system(.caption, design: .rounded).weight(.semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .light)
        )
        .foregroundColor(.primary)
    }
    
    private var roomIcon: String {
        switch roomType {
        case .livingRoom: return "sofa.fill"
        case .kitchen: return "flame.fill"
        case .office: return "desktopcomputer"
        case .bedroom: return "bed.double.fill"
        }
    }

    private func setupScene() {
        let scenario = QuakeScenario(
            magnitude: magnitude,
            roomType: RoomUnlockManager.string(from: roomType),
            scenarioType: scenarioType
        )
        let newScene = QuakeScene(scenario: scenario, decisionEngine: decisionEngine)
        let coord = GameViewCoordinator(onFinish: onFinish)
        newScene.quakeDelegate = coord
        self.coordinator = coord
        self.scene = newScene
    }
}

// MARK: - Achievement Unlock Toast

struct AchievementUnlockToast: View {
    let achievement: Achievement
    let onDismiss: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(achievement.rarity.color.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: achievement.icon)
                        .font(.system(.title3, weight: .semibold))
                        .foregroundColor(achievement.rarity.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "Achievement Unlocked!"))
                        .font(.system(.caption, design: .rounded).weight(.medium))
                        .foregroundColor(.secondary)

                    Text(achievement.title)
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundColor(.primary)

                    Text(achievement.rarity.rawValue)
                        .font(.system(.caption2, design: .rounded).weight(.semibold))
                        .foregroundColor(achievement.rarity.color)
                }

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(.title2))
                    .foregroundColor(AppColors.correctAction)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .light)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(achievement.rarity.color.opacity(0.4), lineWidth: 2)
        )
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -20)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                appeared = true
            }

            // Auto dismiss after 3 seconds with explicit animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeOut(duration: 0.3)) {
                    appeared = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onDismiss()
                }
            }
        }
    }
}

// MARK: - Room Unlock Toast

struct RoomUnlockToast: View {
    let roomType: RoomBuilder.RoomType
    let onDismiss: () -> Void
    
    @State private var appeared = false
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "lock.open.fill")
                        .font(.system(.title3, weight: .semibold))
                        .foregroundColor(.purple)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "New Room Unlocked!"))
                        .font(.system(.caption, design: .rounded).weight(.medium))
                        .foregroundColor(.secondary)
                    
                    Text(roomType.displayName)
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundColor(.primary)
                    
                    Text(String(localized: "Now available in room selection"))
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(.title2))
                    .foregroundColor(.purple)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .light)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.purple.opacity(0.4), lineWidth: 2)
        )
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                appeared = true
            }
            
            // Auto dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                onDismiss()
            }
        }
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

// MARK: - Loading View

struct LoadingView: View {
    let message: String

    var body: some View {
        ZStack {
            Color(hex: 0xF2F2F7)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                Text(message)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
