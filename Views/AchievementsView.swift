import SwiftUI

// MARK: - Achievement Models

enum AchievementCategory: String, CaseIterable, Sendable {
    case survival = "Survival"
    case speed = "Speed"
    case combo = "Combo"
    case knowledge = "Knowledge"
    case mastery = "Mastery"
    
    var icon: String {
        switch self {
        case .survival: return "heart.fill"
        case .speed: return "bolt.fill"
        case .combo: return "flame.fill"
        case .knowledge: return "book.fill"
        case .mastery: return "crown.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .survival: return .red
        case .speed: return .orange
        case .combo: return AppColors.warning
        case .knowledge: return AppColors.primaryAccent
        case .mastery: return Color(hex: 0xFFD700)
        }
    }

    var localizedName: String {
        switch self {
        case .survival: return String(localized: "Survival")
        case .speed: return String(localized: "Speed")
        case .combo: return String(localized: "Combo")
        case .knowledge: return String(localized: "Knowledge")
        case .mastery: return String(localized: "Mastery")
        }
    }
}

enum AchievementRarity: String, Sendable {
    case common = "Common"
    case uncommon = "Uncommon"
    case rare = "Rare"
    case epic = "Epic"
    case legendary = "Legendary"
    case secret = "Secret"
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .uncommon: return Color(hex: 0x4CD964)
        case .rare: return AppColors.primaryAccent
        case .epic: return Color(hex: 0xAF52DE)
        case .legendary: return Color(hex: 0xFFD700)
        case .secret: return Color(hex: 0xFF2D55)
        }
    }
    
    var pointValue: Int {
        switch self {
        case .common: return 10
        case .uncommon: return 25
        case .rare: return 50
        case .epic: return 100
        case .legendary: return 250
        case .secret: return 500
        }
    }

    var localizedName: String {
        switch self {
        case .common: return String(localized: "Common")
        case .uncommon: return String(localized: "Uncommon")
        case .rare: return String(localized: "Rare")
        case .epic: return String(localized: "Epic")
        case .legendary: return String(localized: "Legendary")
        case .secret: return String(localized: "Secret")
        }
    }
}

struct Achievement: Identifiable, Sendable, Equatable, Hashable {
    let id: String
    let title: String
    let description: String
    let condition: String
    let category: AchievementCategory
    let rarity: AchievementRarity
    let icon: String
    let requiredProgress: Int
    var isSecret: Bool
    
    var currentProgress: Int = 0
    var isUnlocked: Bool = false
    var unlockDate: Date?
    
    var progressPercentage: Double {
        min(Double(currentProgress) / Double(requiredProgress), 1.0)
    }
    
    var isNearCompletion: Bool {
        !isUnlocked && progressPercentage >= 0.5
    }
}

// MARK: - Achievement Store

@MainActor
class AchievementStore: ObservableObject {
    static let shared = AchievementStore()
    
    @Published private(set) var achievements: [Achievement] = []
    @Published private(set) var recentlyUnlocked: [Achievement] = []
    
    var totalPoints: Int {
        achievements.filter { $0.isUnlocked }.reduce(0) { $0 + $1.rarity.pointValue }
    }
    
    var unlockedCount: Int {
        achievements.filter { $0.isUnlocked }.count
    }
    
    var completionPercentage: Double {
        Double(unlockedCount) / Double(achievements.count)
    }
    
    private init() {
        setupAchievements()
        loadProgress()
    }
    
    private func setupAchievements() {
        achievements = [
            // MARK: - Survival Achievements
            Achievement(
                id: "first_survival",
                title: String(localized: "First Steps"),
                description: String(localized: "Complete your first earthquake drill"),
                condition: String(localized: "Finish any drill"),
                category: .survival,
                rarity: .common,
                icon: "figure.walk",
                requiredProgress: 1,
                isSecret: false
            ),
            Achievement(
                id: "perfect_health",
                title: String(localized: "Unscathed"),
                description: String(localized: "Complete a drill with all hearts intact"),
                condition: String(localized: "Finish with 3/3 hearts"),
                category: .survival,
                rarity: .uncommon,
                icon: "heart.fill",
                requiredProgress: 1,
                isSecret: false
            ),
            Achievement(
                id: "survival_expert",
                title: String(localized: "Survival Expert"),
                description: String(localized: "Get the 'Survived' rating 10 times"),
                condition: String(localized: "Achieve 'Survived' rating 10 times"),
                category: .survival,
                rarity: .rare,
                icon: "shield.fill",
                requiredProgress: 10,
                isSecret: false
            ),
            Achievement(
                id: "close_call",
                title: String(localized: "Close Call"),
                description: String(localized: "Survive with only 1 heart remaining"),
                condition: String(localized: "Finish with 1/3 hearts"),
                category: .survival,
                rarity: .uncommon,
                icon: "exclamationmark.triangle.fill",
                requiredProgress: 1,
                isSecret: false
            ),
            Achievement(
                id: "iron_will",
                title: String(localized: "Iron Will"),
                description: String(localized: "Survive a magnitude 8.0 earthquake"),
                condition: String(localized: "Complete M8.0 with any rating"),
                category: .survival,
                rarity: .epic,
                icon: "mountain.2.fill",
                requiredProgress: 1,
                isSecret: false
            ),
            
            // MARK: - Speed Achievements
            Achievement(
                id: "quick_thinker",
                title: String(localized: "Quick Thinker"),
                description: String(localized: "Make a correct decision within 2 seconds"),
                condition: String(localized: "React in under 2 seconds"),
                category: .speed,
                rarity: .common,
                icon: "bolt.fill",
                requiredProgress: 1,
                isSecret: false
            ),
            Achievement(
                id: "speed_demon",
                title: String(localized: "Speed Demon"),
                description: String(localized: "Complete a drill in under 20 seconds"),
                condition: String(localized: "Finish drill in < 20s"),
                category: .speed,
                rarity: .uncommon,
                icon: "timer",
                requiredProgress: 1,
                isSecret: false
            ),
            Achievement(
                id: "lightning_reflexes",
                title: String(localized: "Lightning Reflexes"),
                description: String(localized: "Make 5 quick correct decisions in one drill"),
                condition: String(localized: "5 sub-2s correct decisions"),
                category: .speed,
                rarity: .rare,
                icon: "bolt.circle.fill",
                requiredProgress: 1,
                isSecret: false
            ),
            Achievement(
                id: "flash",
                title: String(localized: "The Flash"),
                description: String(localized: "Complete a magnitude 7+ drill in under 15 seconds"),
                condition: String(localized: "Finish M7+ drill in < 15s"),
                category: .speed,
                rarity: .epic,
                icon: "wind",
                requiredProgress: 1,
                isSecret: false
            ),
            
            // MARK: - Combo Achievements
            Achievement(
                id: "double_combo",
                title: String(localized: "Double Trouble"),
                description: String(localized: "Make 2 correct decisions in a row"),
                condition: String(localized: "2 consecutive correct decisions"),
                category: .combo,
                rarity: .common,
                icon: "2.circle.fill",
                requiredProgress: 1,
                isSecret: false
            ),
            Achievement(
                id: "triple_combo",
                title: String(localized: "Triple Threat"),
                description: String(localized: "Make 3 correct decisions in a row"),
                condition: String(localized: "3 consecutive correct decisions"),
                category: .combo,
                rarity: .uncommon,
                icon: "3.circle.fill",
                requiredProgress: 1,
                isSecret: false
            ),
            Achievement(
                id: "perfect_drill",
                title: String(localized: "Perfect Drill"),
                description: String(localized: "Make all correct decisions in a single drill"),
                condition: String(localized: "100% accuracy in one drill"),
                category: .combo,
                rarity: .rare,
                icon: "star.fill",
                requiredProgress: 1,
                isSecret: false
            ),
            Achievement(
                id: "streak_master",
                title: String(localized: "Streak Master"),
                description: String(localized: "Achieve 5 perfect drills in a row"),
                condition: String(localized: "5 consecutive perfect drills"),
                category: .combo,
                rarity: .epic,
                icon: "flame.fill",
                requiredProgress: 1,
                isSecret: false
            ),
            Achievement(
                id: "legendary_combo",
                title: String(localized: "Legendary"),
                description: String(localized: "Achieve a 10x correct decision streak"),
                condition: String(localized: "10 consecutive correct decisions"),
                category: .combo,
                rarity: .legendary,
                icon: "crown.fill",
                requiredProgress: 1,
                isSecret: false
            ),
            
            // MARK: - Knowledge Achievements
            Achievement(
                id: "tip_reader",
                title: String(localized: "Student"),
                description: String(localized: "Read all survival tips"),
                condition: String(localized: "View all tips in TipsView"),
                category: .knowledge,
                rarity: .common,
                icon: "book.fill",
                requiredProgress: 1,
                isSecret: false
            ),
            Achievement(
                id: "myth_buster",
                title: String(localized: "Myth Buster"),
                description: String(localized: "Learn why doorways are NOT safe"),
                condition: String(localized: "Read the doorway tip"),
                category: .knowledge,
                rarity: .common,
                icon: "lightbulb.fill",
                requiredProgress: 1,
                isSecret: false
            ),
            Achievement(
                id: "preparedness_pro",
                title: String(localized: "Preparedness Pro"),
                description: String(localized: "Complete all preparedness checklist items"),
                condition: String(localized: "Acknowledge all before tips"),
                category: .knowledge,
                rarity: .uncommon,
                icon: "checkmark.circle.fill",
                requiredProgress: 1,
                isSecret: false
            ),
            Achievement(
                id: "earthquake_expert",
                title: String(localized: "Earthquake Expert"),
                description: String(localized: "Read all educational facts in debrief"),
                condition: String(localized: "View all facts 3 times"),
                category: .knowledge,
                rarity: .rare,
                icon: "graduationcap.fill",
                requiredProgress: 3,
                isSecret: false
            ),
            Achievement(
                id: "teacher",
                title: String(localized: "Teacher"),
                description: String(localized: "Share your achievements with friends"),
                condition: String(localized: "Use share feature"),
                category: .knowledge,
                rarity: .uncommon,
                icon: "square.and.arrow.up.fill",
                requiredProgress: 1,
                isSecret: false
            ),
            
            // MARK: - Mastery Achievements
            Achievement(
                id: "dedicated",
                title: String(localized: "Dedicated"),
                description: String(localized: "Complete 10 drills"),
                condition: String(localized: "Finish 10 drills total"),
                category: .mastery,
                rarity: .uncommon,
                icon: "10.circle.fill",
                requiredProgress: 10,
                isSecret: false
            ),
            Achievement(
                id: "veteran",
                title: String(localized: "Veteran"),
                description: String(localized: "Complete 50 drills"),
                condition: String(localized: "Finish 50 drills total"),
                category: .mastery,
                rarity: .rare,
                icon: "50.circle.fill",
                requiredProgress: 50,
                isSecret: false
            ),
            Achievement(
                id: "earthquake_master",
                title: String(localized: "Earthquake Master"),
                description: String(localized: "Complete 100 drills"),
                condition: String(localized: "Finish 100 drills total"),
                category: .mastery,
                rarity: .epic,
                icon: "star.circle.fill",
                requiredProgress: 100,
                isSecret: false
            ),
            Achievement(
                id: "difficulty_master",
                title: String(localized: "Difficulty Master"),
                description: String(localized: "Complete drills at every magnitude level"),
                condition: String(localized: "Finish M4.0 through M8.0"),
                category: .mastery,
                rarity: .epic,
                icon: "dial.high.fill",
                requiredProgress: 1,
                isSecret: false
            ),
            Achievement(
                id: "completionist",
                title: String(localized: "Completionist"),
                description: String(localized: "Unlock all other achievements"),
                condition: String(localized: "Unlock all non-secret achievements"),
                category: .mastery,
                rarity: .legendary,
                icon: "trophy.fill",
                requiredProgress: 1,
                isSecret: false
            ),
            
            // MARK: - Secret Achievements
            Achievement(
                id: "secret_perfect",
                title: String(localized: "???"),
                description: String(localized: "Hidden achievement"),
                condition: String(localized: "?????"),
                category: .mastery,
                rarity: .secret,
                icon: "questionmark.circle.fill",
                requiredProgress: 1,
                isSecret: true
            ),
            Achievement(
                id: "secret_survivor",
                title: String(localized: "???"),
                description: String(localized: "Hidden achievement"),
                condition: String(localized: "?????"),
                category: .survival,
                rarity: .secret,
                icon: "questionmark.circle.fill",
                requiredProgress: 1,
                isSecret: true
            ),
        ]
    }
    
    func updateProgress(id: String, progress: Int) {
        if let index = achievements.firstIndex(where: { $0.id == id }) {
            var achievement = achievements[index]
            let wasUnlocked = achievement.isUnlocked
            achievement.currentProgress = progress
            
            if progress >= achievement.requiredProgress && !wasUnlocked {
                unlock(id: id)
            } else {
                achievements[index] = achievement
            }
        }
    }
    
    func incrementProgress(id: String, by amount: Int = 1) {
        if let index = achievements.firstIndex(where: { $0.id == id }) {
            let current = achievements[index].currentProgress
            updateProgress(id: id, progress: current + amount)
        }
    }
    
    func unlock(id: String) {
        if let index = achievements.firstIndex(where: { $0.id == id }) {
            var achievement = achievements[index]
            if !achievement.isUnlocked {
                achievement.isUnlocked = true
                achievement.unlockDate = Date()
                achievement.currentProgress = achievement.requiredProgress
                achievements[index] = achievement
                recentlyUnlocked.insert(achievement, at: 0)
                
                // Keep only last 5 recent unlocks
                if recentlyUnlocked.count > 5 {
                    recentlyUnlocked.removeLast()
                }
                
                saveProgress()
            }
        }
    }
    
    func clearRecentlyUnlocked() {
        recentlyUnlocked.removeAll()
    }

    #if DEBUG
    func debugSeedAchievements() {
        let ids = ["first_survival", "perfect_health", "quick_thinker", "triple_combo", "tip_reader", "earthquake_expert"]
        for id in ids {
            guard let index = achievements.firstIndex(where: { $0.id == id }),
                  !achievements[index].isUnlocked else { continue }
            var achievement = achievements[index]
            achievement.isUnlocked = true
            achievements[index] = achievement
        }
    }
    #endif

    func revealSecret(achievementId: String) -> Achievement? {
        if let index = achievements.firstIndex(where: { $0.id == achievementId }) {
            var achievement = achievements[index]
            if achievement.isSecret {
                achievement.isSecret = false
                achievements[index] = achievement
                return achievement
            }
        }
        return nil
    }
    
    private func saveProgress() {
        // Persist to UserDefaults
        let unlockedIds = achievements.filter { $0.isUnlocked }.map { $0.id }
        UserDefaults.standard.set(unlockedIds, forKey: "unlockedAchievements")
        
        let progressData = achievements.reduce(into: [String: Int]()) { result, achievement in
            result[achievement.id] = achievement.currentProgress
        }
        UserDefaults.standard.set(progressData, forKey: "achievementProgress")
    }
    
    private func loadProgress() {
        let unlockedIds = UserDefaults.standard.stringArray(forKey: "unlockedAchievements") ?? []
        let progressData = UserDefaults.standard.dictionary(forKey: "achievementProgress") as? [String: Int] ?? [:]
        
        for (index, var achievement) in achievements.enumerated() {
            if unlockedIds.contains(achievement.id) {
                achievement.isUnlocked = true
                achievement.unlockDate = Date() // Could store actual dates if needed
                achievement.currentProgress = achievement.requiredProgress
            } else {
                achievement.currentProgress = progressData[achievement.id] ?? 0
            }
            achievements[index] = achievement
        }
    }
    
    func reset() {
        setupAchievements()
        recentlyUnlocked.removeAll()
        saveProgress()
    }

    func resetAllAchievements() {
        // Reset all achievements to initial state
        for (index, var achievement) in achievements.enumerated() {
            achievement.isUnlocked = false
            achievement.unlockDate = nil
            achievement.currentProgress = 0
            achievements[index] = achievement
        }
        recentlyUnlocked.removeAll()
        saveProgress()
    }
}

// MARK: - Sort Options

enum AchievementSort: String, CaseIterable {
    case date = "Date Unlocked"
    case progress = "Progress"
    case rarity = "Rarity"
    case name = "Name"
    case category = "Category"

    var localizedName: String {
        switch self {
        case .date: return String(localized: "Date Unlocked")
        case .progress: return String(localized: "Progress")
        case .rarity: return String(localized: "Rarity")
        case .name: return String(localized: "Name")
        case .category: return String(localized: "Category")
        }
    }
}

// MARK: - Main View

struct AchievementsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = AchievementStore.shared
    
    @State private var selectedCategory: AchievementCategory?
    @State private var sortBy: AchievementSort = .category
    @State private var searchText = ""
    @State private var selectedAchievement: Achievement?
    @State private var showDetail = false
    @State private var appeared = false
    @State private var floatPhase = false
    
    private var filteredAchievements: [Achievement] {
        var result = store.achievements
        
        // Filter by category
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        
        // Filter by search
        if !searchText.isEmpty {
            result = result.filter { achievement in
                let searchLower = searchText.lowercased()
                let matchesTitle = achievement.title.lowercased().contains(searchLower)
                let matchesDesc = achievement.description.lowercased().contains(searchLower)
                let matchesCategory = achievement.category.localizedName.lowercased().contains(searchLower)
                return matchesTitle || matchesDesc || matchesCategory
            }
        }
        
        // Sort
        switch sortBy {
        case .date:
            result.sort {
                guard let d1 = $0.unlockDate, let d2 = $1.unlockDate else {
                    return $0.isUnlocked && !$1.isUnlocked
                }
                return d1 > d2
            }
        case .progress:
            result.sort {
                if $0.isUnlocked != $1.isUnlocked {
                    return $0.isUnlocked
                }
                return $0.progressPercentage > $1.progressPercentage
            }
        case .rarity:
            let rarityOrder: [AchievementRarity] = [.legendary, .epic, .rare, .uncommon, .common, .secret]
            result.sort {
                let idx1 = rarityOrder.firstIndex(of: $0.rarity) ?? 99
                let idx2 = rarityOrder.firstIndex(of: $1.rarity) ?? 99
                return idx1 < idx2
            }
        case .name:
            result.sort { $0.title < $1.title }
        case .category:
            result.sort {
                if $0.category != $1.category {
                    return $0.category.rawValue < $1.category.rawValue
                }
                return $0.isUnlocked && !$1.isUnlocked
            }
        }
        
        return result
    }
    
    private var unlockedAchievements: [Achievement] {
        store.achievements.filter { $0.isUnlocked }
    }
    
    private var lockedAchievements: [Achievement] {
        store.achievements.filter { !$0.isUnlocked }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackground()
                
                floatingIcons
                
                ScrollView {
                    VStack(spacing: 20) {
                        Spacer().frame(height: 8)
                        
                        statsSection
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 20)
                        
                        recentUnlocksSection
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 20)
                        
                        controlsSection
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 20)
                        
                        achievementsGrid
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 20)
                        
                        Spacer().frame(height: 30)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .navigationTitle(String(localized: "Achievements"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Done")) { dismiss() }
                }
            }
            .sheet(item: $selectedAchievement) { achievement in
                AchievementDetailView(achievement: achievement)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    appeared = true
                }
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    floatPhase = true
                }
                #if DEBUG
                if MarketingCapture.pendingAchievementsSeed {
                    store.debugSeedAchievements()
                }
                #endif
            }
        }
    }
    
    // MARK: - Floating Background Icons
    
    private var floatingIcons: some View {
        GeometryReader { geo in
            let icons: [(name: String, x: CGFloat, y: CGFloat, size: CGFloat)] = [
                ("trophy.fill", 0.08, 0.08, 14),
                ("star.fill", 0.92, 0.12, 12),
                ("crown.fill", 0.06, 0.55, 11),
                ("medal.fill", 0.88, 0.72, 13),
                ("sparkle", 0.15, 0.85, 10),
            ]
            
            ForEach(Array(icons.enumerated()), id: \.offset) { _, icon in
                Image(systemName: icon.name)
                    .font(.system(size: icon.size))
                    .foregroundColor(AppColors.primaryAccent.opacity(0.08))
                    .position(
                        x: geo.size.width * icon.x,
                        y: geo.size.height * icon.y + (floatPhase ? -5 : 5)
                    )
                    .rotationEffect(.degrees(floatPhase ? 8 : -8))
            }
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        VStack(spacing: 16) {
            // Progress ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.black.opacity(0.08), lineWidth: 12)
                    .frame(width: 120, height: 120)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: store.completionPercentage)
                    .stroke(
                        AngularGradient(
                            colors: [AppColors.correctAction, AppColors.primaryAccent, AppColors.warning],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: store.completionPercentage)
                
                // Center content
                VStack(spacing: 2) {
                    Text("\(store.unlockedCount)/\(store.achievements.count)")
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundColor(.primary)

                    Text("\(Int(store.completionPercentage * 100))%")
                        .font(.system(.caption2, design: .rounded).weight(.medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 8)
            
            // Stats row
            HStack(spacing: 20) {
                StatBox(value: "\(store.totalPoints)", label: String(localized: "Points"), color: AppColors.warning)
                StatBox(value: "\(unlockedAchievements.filter { $0.rarity == .legendary || $0.rarity == .epic }.count)", label: String(localized: "Rare"), color: AppColors.primaryAccent)
                StatBox(value: "\(store.recentlyUnlocked.count)", label: String(localized: "Recent"), color: AppColors.correctAction)
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
                .stroke(AppColors.primaryAccent.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Recent Unlocks Section
    
    @ViewBuilder
    private var recentUnlocksSection: some View {
        if !store.recentlyUnlocked.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(AppColors.warning)
                    Text(String(localized: "Recently Unlocked"))
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(store.recentlyUnlocked) { achievement in
                            RecentAchievementCard(achievement: achievement)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
            )
        }
    }
    
    // MARK: - Controls Section
    
    private var controlsSection: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField(String(localized: "Search achievements..."), text: $searchText)
                    .font(.system(.subheadline, design: .rounded))
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
            
            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    CategoryFilterButton(
                        title: String(localized: "All"),
                        icon: "square.grid.2x2",
                        color: .gray,
                        isSelected: selectedCategory == nil
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = nil
                        }
                    }
                    
                    ForEach(AchievementCategory.allCases, id: \.self) { category in
                        CategoryFilterButton(
                            title: category.localizedName,
                            icon: category.icon,
                            color: category.color,
                            isSelected: selectedCategory == category
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedCategory = category
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            
            // Sort picker
            HStack {
                Text(String(localized: "Sort by:"))
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
                
                Picker("Sort", selection: $sortBy) {
                    ForEach(AchievementSort.allCases, id: \.self) { sort in
                        Text(sort.localizedName).tag(sort)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }
    
    // MARK: - Achievements Grid
    
    private var achievementsGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {
            ForEach(filteredAchievements) { achievement in
                AchievementBadge(achievement: achievement)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            selectedAchievement = achievement
                        }
                    }
            }
        }
    }
}

// MARK: - Stat Box

private struct StatBox: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(.caption2, design: .rounded).weight(.medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.08))
        )
    }
}

// MARK: - Category Filter Button

private struct CategoryFilterButton: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(.caption, design: .rounded).weight(.semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? color : Color.white)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? color : color.opacity(0.3), lineWidth: 1)
            )
            .foregroundColor(isSelected ? .white : color)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Recent Achievement Card

private struct RecentAchievementCard: View {
    let achievement: Achievement
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(achievement.rarity.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: achievement.icon)
                    .font(.system(.title3, weight: .semibold))
                    .foregroundColor(achievement.rarity.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.title)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundColor(.primary)

                if let date = achievement.unlockDate {
                    Text(date, style: .relative)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(achievement.rarity.color.opacity(0.3), lineWidth: 1.5)
        )
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .pressEvents {
            withAnimation(.spring(response: 0.2)) {
                isPressed = true
            }
        } onRelease: {
            withAnimation(.spring(response: 0.2)) {
                isPressed = false
            }
        }
    }
}

// MARK: - Achievement Badge

private struct AchievementBadge: View {
    let achievement: Achievement
    @State private var isPressed = false
    @State private var showUnlockAnimation = false
    
    private var isSecretLocked: Bool {
        achievement.isSecret && !achievement.isUnlocked
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            ZStack {
                // Glow for near completion
                if achievement.isNearCompletion {
                    Circle()
                        .fill(achievement.category.color.opacity(0.2))
                        .frame(width: 56, height: 56)
                        .scaleEffect(showUnlockAnimation ? 1.2 : 1.0)
                        .opacity(showUnlockAnimation ? 0 : 1)
                }
                
                Circle()
                    .fill(achievement.isUnlocked ? achievement.rarity.color.opacity(0.15) : Color.black.opacity(0.05))
                    .frame(width: 56, height: 56)
                
                Image(systemName: isSecretLocked ? "questionmark" : achievement.icon)
                    .font(.system(.title2, weight: .semibold))
                    .foregroundColor(achievement.isUnlocked ? achievement.rarity.color : .gray)
                
                // Lock overlay
                if !achievement.isUnlocked && !achievement.isSecret {
                    Image(systemName: "lock.fill")
                        .font(.system(.caption2))
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Circle().fill(.black.opacity(0.6)))
                        .offset(x: 18, y: 18)
                }
                
                // Rarity indicator for unlocked
                if achievement.isUnlocked {
                    Circle()
                        .fill(achievement.rarity.color)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .offset(x: 20, y: -20)
                }
            }
            
            // Text
            VStack(spacing: 4) {
                Text(isSecretLocked ? "???" : achievement.title)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundColor(achievement.isUnlocked ? .primary : .secondary)
                    .lineLimit(1)
                
                if achievement.isUnlocked {
                    Text(achievement.rarity.localizedName)
                        .font(.system(.caption2, design: .rounded).weight(.medium))
                        .foregroundColor(achievement.rarity.color)
                } else if !isSecretLocked {
                    // Progress bar for locked
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.black.opacity(0.08))
                                .frame(height: 4)
                            
                            Capsule()
                                .fill(achievement.category.color)
                                .frame(width: geo.size.width * achievement.progressPercentage, height: 4)
                        }
                    }
                    .frame(height: 4)
                    
                    Text("\(achievement.currentProgress)/\(achievement.requiredProgress)")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .frame(height: 140)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(achievement.isUnlocked ? Color.white : Color.white.opacity(0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    achievement.isUnlocked ? achievement.rarity.color.opacity(0.4) : Color.black.opacity(0.08),
                    lineWidth: achievement.isUnlocked ? 2 : 1
                )
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .pressEvents {
            withAnimation(.spring(response: 0.2)) {
                isPressed = true
            }
        } onRelease: {
            withAnimation(.spring(response: 0.2)) {
                isPressed = false
            }
        }
        .onAppear {
            if achievement.isNearCompletion {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    showUnlockAnimation = true
                }
            }
        }
    }
}

// MARK: - Achievement Detail View

struct AchievementDetailView: View {
    let achievement: Achievement
    @Environment(\.dismiss) private var dismiss
    @State private var appeared = false
    @State private var bounce = false
    
    private var isSecretLocked: Bool {
        achievement.isSecret && !achievement.isUnlocked
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero icon
                    ZStack {
                        // Animated rings
                        ForEach(0..<3) { i in
                            Circle()
                                .stroke(achievement.rarity.color.opacity(0.3 - Double(i) * 0.08), lineWidth: 2)
                                .frame(width: 120 + CGFloat(i * 30), height: 120 + CGFloat(i * 30))
                                .scaleEffect(appeared ? 1 : 0.8)
                                .opacity(appeared ? 1 : 0)
                                .animation(.easeOut(duration: 0.5).delay(Double(i) * 0.1), value: appeared)
                        }
                        
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [achievement.rarity.color.opacity(0.2), .clear],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 70
                                )
                            )
                            .frame(width: 140, height: 140)
                        
                        ZStack {
                            Circle()
                                .fill(achievement.rarity.color.opacity(0.15))
                                .frame(width: 100, height: 100)
                            
                            Circle()
                                .stroke(achievement.rarity.color, lineWidth: 3)
                                .frame(width: 90, height: 90)
                            
                            Image(systemName: isSecretLocked ? "questionmark" : achievement.icon)
                                .font(.system(.title, weight: .bold))
                                .foregroundColor(achievement.rarity.color)
                                .offset(y: bounce ? -4 : 4)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Title section
                    VStack(spacing: 8) {
                        Text(isSecretLocked ? String(localized: "Secret Achievement") : achievement.title)
                            .font(.system(.title, design: .rounded).weight(.black))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 8) {
                            Image(systemName: achievement.category.icon)
                                .font(.caption)
                            Text(achievement.category.localizedName)
                                .font(.system(.caption, design: .rounded).weight(.semibold))
                        }
                        .foregroundColor(achievement.category.color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(achievement.category.color.opacity(0.12))
                        )
                        
                        // Rarity badge
                        HStack(spacing: 6) {
                            Image(systemName: "diamond.fill")
                                .font(.system(.caption2))
                            Text(isSecretLocked ? "???" : achievement.rarity.localizedName)
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        }
                        .foregroundColor(achievement.rarity.color)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: appeared)
                    
                    // Description card
                    VStack(alignment: .leading, spacing: 16) {
                        InfoRow(icon: "text.alignleft", title: String(localized: "Description"), content: isSecretLocked ? String(localized: "This achievement is hidden. Complete secret challenges to unlock it!") : achievement.description)
                        
                        Divider()
                        
                        InfoRow(icon: "checkmark.circle", title: String(localized: "Condition"), content: isSecretLocked ? "?????" : achievement.condition)
                        
                        if achievement.isUnlocked, let date = achievement.unlockDate {
                            Divider()
                            
                            InfoRow(icon: "calendar", title: String(localized: "Unlocked"), content: date.formatted(date: .long, time: .shortened))
                        }
                        
                        if !achievement.isUnlocked && !isSecretLocked {
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(String(localized: "Progress"))
                                    .font(.system(.caption, design: .rounded).weight(.medium))
                                    .foregroundColor(.secondary)
                                
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color.black.opacity(0.08))
                                            .frame(height: 8)
                                        
                                        Capsule()
                                            .fill(achievement.category.color)
                                            .frame(width: geo.size.width * achievement.progressPercentage, height: 8)
                                    }
                                }
                                .frame(height: 8)
                                
                                HStack {
                                    Text("\(achievement.currentProgress)/\(achievement.requiredProgress)")
                                        .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                                        .foregroundColor(achievement.category.color)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(achievement.progressPercentage * 100))%")
                                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.black.opacity(0.06), lineWidth: 1)
                    )
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: appeared)
                    
                    // Points badge
                    if achievement.isUnlocked {
                        HStack(spacing: 8) {
                            Image(systemName: "star.fill")
                                .foregroundColor(AppColors.warning)
                            Text(String(localized: "\(achievement.rarity.pointValue) Points Earned"))
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(AppColors.warning.opacity(0.12))
                        )
                        .overlay(
                            Capsule()
                                .stroke(AppColors.warning.opacity(0.3), lineWidth: 1)
                        )
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.4), value: appeared)
                    }
                    
                    // Share button
                    if achievement.isUnlocked {
                        ShareLink(item: shareText) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                Text(String(localized: "Share Achievement"))
                            }
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundColor(AppColors.primaryAccent)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppColors.primaryAccent.opacity(0.08))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppColors.primaryAccent.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.5), value: appeared)
                    }
                    
                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle(String(localized: "Achievement Details"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Done")) { dismiss() }
                }
            }
            .background(
                LinearGradient(
                    colors: [Color(hex: 0xF0F4FF), Color(hex: 0xE8ECF5)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    appeared = true
                }
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    bounce = true
                }
            }
        }
    }
    
    private var shareText: String {
        "I unlocked '\(achievement.title)' in QuakeSense! 🏆 \(achievement.rarity.localizedName) achievement in \(achievement.category.localizedName). Can you survive the earthquake? #QuakeSense"
    }
}

// MARK: - Info Row

private struct InfoRow: View {
    let icon: String
    let title: String
    let content: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(.subheadline, weight: .semibold))
                .foregroundColor(AppColors.primaryAccent)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundColor(.secondary)
                
                Text(content)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Press Events Modifier

private struct PressEventsModifier: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
    }
}

private extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEventsModifier(onPress: onPress, onRelease: onRelease))
    }
}

// MARK: - Preview

#Preview {
    AchievementsView()
}
