import SwiftUI
import SpriteKit
import UIKit

struct DebriefView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let report: EnhancedDebriefReport
    var onTryAgain: () -> Void
    var onShowTips: () -> Void

    @State private var displayedScore = 0
    @State private var visibleDecisions: Int = 0
    @State private var showFacts = false
    @State private var visibleFacts: Int = 0
    @State private var ratingGlow = false
    @State private var showConfetti = false
    @State private var confettiOpacity: Double = 0
    @State private var showTimeline = false
    @State private var randomTips: [SurvivalTip] = []
    @State private var badgeScale: CGFloat = 0.85

    // MARK: - Adaptive Layout Helpers

    private var badgeSize: CGFloat {
        horizontalSizeClass == .compact ? 80 : 96
    }

    private var statGridColumns: [GridItem] {
        SizeClassConstants.adaptiveStatColumns(minWidth: 70)
    }

    var body: some View {
        ZStack {
            // Solid color fallback to prevent black flash during Canvas init
            Color(hex: 0xF2F2F7)
                .ignoresSafeArea()

            AnimatedBackground()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 20)

                    headerSection
                    scoreSection
                    decisionsSection
                    timelineSection
                    factsSection
                    actionsSection

                    Spacer().frame(height: 30)
                }
                .adaptivePadding(compact: 16, regular: 24)
            }

            // Confetti overlay for survived rating (options: .allowsTransparency avoids black flash)
            if showConfetti && report.survivalRating == .survived {
                SpriteView(
                    scene: ConfettiScene(),
                    transition: nil,
                    isPaused: false,
                    preferredFramesPerSecond: 60,
                    options: [.allowsTransparency],
                    shouldRender: { _ in true }
                )
                .allowsHitTesting(false)
                .ignoresSafeArea()
                .opacity(confettiOpacity)
            }
        }
        .onAppear {
            randomTips = pickRandomTips()
            animateResults()
            let motionDisabled = reduceMotion || SettingsManager.shared.isReducedMotionEnabled
            if !motionDisabled {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.72)) {
                    badgeScale = 1.0
                }
            } else {
                badgeScale = 1.0
            }
            if !motionDisabled {
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                    ratingGlow = true
                }
            }
            if report.survivalRating == .survived {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showConfetti = true
                    withAnimation(.easeOut(duration: 0.25)) {
                        confettiOpacity = 1
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    showConfetti = false
                    confettiOpacity = 0
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Text(String(localized: "DRILL COMPLETE"))
                .font(.system(.caption, design: .monospaced).weight(.bold))
                .foregroundColor(.secondary)
                .tracking(4)

            // Rating badge with pulsing glow and scale-in animation (SSC polish)
            ZStack {
                // Outer pulse ring
                Circle()
                    .fill(ratingColor.opacity(ratingGlow ? 0.12 : 0.04))
                    .frame(width: horizontalSizeClass == .compact ? 110 : 130, height: horizontalSizeClass == .compact ? 110 : 130)
                    .scaleEffect(ratingGlow ? 1.15 : 1.0)

                // Inner glow ring
                Circle()
                    .stroke(ratingColor.opacity(ratingGlow ? 0.4 : 0.15), lineWidth: 2)
                    .frame(width: horizontalSizeClass == .compact ? 90 : 110, height: horizontalSizeClass == .compact ? 90 : 110)
                    .scaleEffect(ratingGlow ? 1.05 : 1.0)

                // Badge background
                Circle()
                    .fill(ratingColor.opacity(0.12))
                    .frame(width: badgeSize, height: badgeSize)

                // Badge border
                Circle()
                    .stroke(ratingColor, lineWidth: 3)
                    .frame(width: horizontalSizeClass == .compact ? 74 : 90, height: horizontalSizeClass == .compact ? 74 : 90)

                // Optional bundle badge image or procedural rating symbol
                if let badgeName = optionalDebriefBadgeName {
                    Image(badgeName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: badgeSize, height: badgeSize)
                } else {
                    ratingSymbol
                        .frame(width: horizontalSizeClass == .compact ? 48 : 60, height: horizontalSizeClass == .compact ? 48 : 60)
                }

                // Laurel decoration for survived rating
                if report.survivalRating == .survived {
                    Image(systemName: "laurel.leading")
                        .font(.system(size: horizontalSizeClass == .compact ? 24 : 28))
                        .foregroundColor(ratingColor.opacity(0.5))
                        .offset(x: horizontalSizeClass == .compact ? -40 : -48, y: 8)
                    Image(systemName: "laurel.trailing")
                        .font(.system(size: horizontalSizeClass == .compact ? 24 : 28))
                        .foregroundColor(ratingColor.opacity(0.5))
                        .offset(x: horizontalSizeClass == .compact ? 40 : 48, y: 8)
                }
            }
            .scaleEffect(badgeScale)

            Text(report.survivalRating.rawValue)
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundColor(ratingColor)

            Text(report.survivalRating.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Hearts remaining
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: i < report.heartsRemaining ? "heart.fill" : "heart")
                        .foregroundColor(i < report.heartsRemaining ? .red : .gray)
                }
            }
            .font(.title2)

            // Post-debrief impact line (SSC: social impact + story)
            Text(String(localized: "In 2024, Indonesia had 11,000+ earthquakes. You're now better prepared than most."))
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
                .padding(.horizontal, 24)
        }
    }

    private var ratingColor: Color {
        switch report.survivalRating {
        case .survived: return AppColors.correctAction
        case .injured:  return AppColors.warning
        case .critical: return AppColors.wrongAction
        }
    }

    /// Bundle image name for the current rating when the asset exists (badge_survived, badge_injured, badge_critical).
    private var optionalDebriefBadgeName: String? {
        let name: String
        switch report.survivalRating {
        case .survived: name = "badge_survived"
        case .injured: name = "badge_injured"
        case .critical: name = "badge_critical"
        }
        return UIImage(named: name) != nil ? name : nil
    }

    @ViewBuilder
    private var ratingSymbol: some View {
        switch report.survivalRating {
        case .survived:
            ZStack {
                Image(systemName: "shield.fill")
                    .font(.system(size: 44))
                    .foregroundColor(ratingColor.opacity(0.3))
                Image(systemName: "checkmark")
                    .font(.system(.title, weight: .bold))
                    .foregroundColor(ratingColor)
            }
        case .injured:
            ZStack {
                Image(systemName: "shield.fill")
                    .font(.system(size: 44))
                    .foregroundColor(ratingColor.opacity(0.3))
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(.title2))
                    .foregroundColor(ratingColor)
            }
        case .critical:
            ZStack {
                Image(systemName: "shield.fill")
                    .font(.system(size: 44))
                    .foregroundColor(ratingColor.opacity(0.3))
                Image(systemName: "xmark")
                    .font(.system(.title, weight: .bold))
                    .foregroundColor(ratingColor)
            }
        }
    }

    // MARK: - Score

    private var scoreSection: some View {
        VStack(spacing: 8) {
            Text("\(displayedScore)")
                .font(.system(.largeTitle, design: .monospaced).weight(.bold))
                .foregroundColor(.primary)
                .contentTransition(.numericText())

            ProgressView(value: Double(min(displayedScore, 100)), total: 100)
                .tint(ratingColor)
                .scaleEffect(y: 2)
                .padding(.horizontal, 40)

            Text(String(localized: "out of 100 points"))
                .font(.caption)
                .foregroundColor(.secondary)

            Text(String(format: "Magnitude %.1f  |  %.0fs", report.magnitude, report.totalTime))
                .font(.caption2)
                .foregroundColor(.secondary)

            // Stat pills row - adaptive grid layout
            LazyVGrid(columns: statGridColumns, spacing: 10) {
                statPill(
                    label: String(localized: "Max Combo"),
                    value: "\(report.maxCombo)x",
                    icon: "flame.fill",
                    color: .orange
                )
                statPill(
                    label: String(localized: "Accuracy"),
                    value: String(format: "%.0f%%", report.accuracyPercentage),
                    icon: "target",
                    color: AppColors.correctAction
                )
                statPill(
                    label: String(localized: "Difficulty"),
                    value: report.difficulty.rawValue,
                    icon: "speedometer",
                    color: difficultyColor
                )
            }
            .padding(.top, 6)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(ratingColor.opacity(0.3), lineWidth: 1)
        )
    }

    private var difficultyColor: Color {
        switch report.difficulty {
        case .easy:   return AppColors.correctAction
        case .medium: return AppColors.warning
        case .hard:   return AppColors.wrongAction
        }
    }

    private func statPill(label: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(.caption2, weight: .semibold))
                .foregroundColor(color)
            Text(value)
                .font(.system(.caption, design: .monospaced).weight(.bold))
                .foregroundColor(.primary)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.08))
        )
    }

    // MARK: - Decisions

    private var decisionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "YOUR DECISIONS"))
                .font(.system(.caption2, design: .monospaced).weight(.bold))
                .foregroundColor(.secondary)
                .tracking(2)

            if report.decisions.isEmpty {
                Text(String(localized: "No decisions recorded — you froze!"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(Array(report.decisions.enumerated()), id: \.element.id) { index, decision in
                    if index < visibleDecisions {
                        DecisionDetailRow(decision: decision)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        )
    }

    private func decisionRow(_ decision: EnhancedDecision) -> some View {
        HStack(spacing: 0) {
            // Left accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(decision.isCorrect ? AppColors.correctAction : AppColors.wrongAction)
                .frame(width: 3, height: 48)
                .padding(.trailing, 10)

            Image(systemName: decision.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(decision.isCorrect ? AppColors.correctAction : AppColors.wrongAction)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(decision.action.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)

                    // Combo badge
                    if decision.comboMultiplier > 1 {
                        Text("\(decision.comboMultiplier)x")
                            .font(.system(.caption2, design: .rounded).weight(.bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.orange))
                    }
                }

                HStack(spacing: 8) {
                    Text(String(format: "%.1fs", decision.responseTime))
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.secondary)

                    if decision.timeBonus > 0 {
                        Text("+\(decision.timeBonus) bonus")
                            .font(.system(.caption2, design: .rounded).weight(.medium))
                            .foregroundColor(AppColors.primaryAccent)
                    }
                }
            }
            .padding(.leading, 12)

            Spacer()

            Text(decision.totalPoints >= 0 ? "+\(decision.totalPoints)" : "\(decision.totalPoints)")
                .font(.system(.subheadline, design: .monospaced).weight(.bold))
                .foregroundColor(decision.isCorrect ? AppColors.correctAction : AppColors.wrongAction)
        }
        .padding(.vertical, 6)
    }

    // MARK: - Phase Timeline

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "PHASE TIMELINE"))
                .font(.system(.caption2, design: .monospaced).weight(.bold))
                .foregroundColor(.secondary)
                .tracking(2)

            if showTimeline && !report.decisions.isEmpty {
                // Main phase decisions (P-Wave / S-Wave)
                let mainDecisions = report.decisions.filter { PlayerAction.mainPhaseActions.contains($0.action) }
                let aftershockDecisions = report.decisions.filter { PlayerAction.aftershockActions.contains($0.action) }

                if !mainDecisions.isEmpty {
                    phaseGroup(
                        title: String(localized: "EARTHQUAKE"),
                        subtitle: String(localized: "P-Wave / S-Wave"),
                        color: AppColors.wrongAction,
                        icon: "waveform.path.ecg",
                        decisions: mainDecisions
                    )
                }

                if !aftershockDecisions.isEmpty {
                    phaseGroup(
                        title: String(localized: "AFTERSHOCK"),
                        subtitle: String(localized: "Safety Tasks"),
                        color: AppColors.warning,
                        icon: "exclamationmark.triangle.fill",
                        decisions: aftershockDecisions
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        )
    }

    private func phaseGroup(title: String, subtitle: String, color: Color, icon: String, decisions: [EnhancedDecision]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Phase header
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 3, height: 24)

                Image(systemName: icon)
                    .font(.system(.caption, weight: .semibold))
                    .foregroundColor(color)

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(.caption, design: .monospaced).weight(.bold))
                        .foregroundColor(color)
                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Phase score subtotal
                let phasePoints = decisions.reduce(0) { $0 + $1.totalPoints }
                Text(phasePoints >= 0 ? "+\(phasePoints)" : "\(phasePoints)")
                    .font(.system(.caption, design: .monospaced).weight(.bold))
                    .foregroundColor(color)
            }

            // Timeline entries
            ForEach(decisions) { decision in
                HStack(spacing: 10) {
                    // Vertical connector line
                    Rectangle()
                        .fill(color.opacity(0.2))
                        .frame(width: 1)
                        .padding(.leading, 12)

                    Image(systemName: decision.action.iconName)
                        .font(.system(.caption2, weight: .medium))
                        .foregroundColor(decision.isCorrect ? AppColors.correctAction : AppColors.wrongAction)
                        .frame(width: 20)

                    Text(decision.action.displayName)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Spacer()

                    Text(String(format: "%.1fs", decision.responseTime))
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.secondary)

                    Text(decision.totalPoints >= 0 ? "+\(decision.totalPoints)" : "\(decision.totalPoints)")
                        .font(.system(.caption2, design: .monospaced).weight(.semibold))
                        .foregroundColor(decision.isCorrect ? AppColors.correctAction : AppColors.wrongAction)
                }
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: - Facts (Random Survival Tips)

    private func pickRandomTips() -> [SurvivalTip] {
        // Pick one tip from each phase category for variety
        let beforeTips = SurvivalTip.tips(for: .before).shuffled()
        let duringTips = SurvivalTip.tips(for: .during).shuffled()
        let afterTips = SurvivalTip.tips(for: .after).shuffled()

        var tips: [SurvivalTip] = []
        if let tip = beforeTips.first { tips.append(tip) }
        if let tip = duringTips.first { tips.append(tip) }
        if let tip = afterTips.first { tips.append(tip) }
        return tips
    }

    private var factsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    // Warm glow behind lightbulb
                    Circle()
                        .fill(AppColors.warning.opacity(0.15))
                        .frame(width: 30, height: 30)

                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(AppColors.warning)
                }

                Text(String(localized: "SURVIVAL TIPS"))
                    .font(.system(.caption2, design: .monospaced).weight(.bold))
                    .foregroundColor(.secondary)
                    .tracking(2)
            }

            if showFacts {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(randomTips.enumerated()), id: \.element.id) { index, tip in
                        if index < visibleFacts {
                            tipItem(tip)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .leading).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        )
    }

    private func tipItem(_ tip: SurvivalTip) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: tip.icon)
                .font(.system(.caption, weight: .semibold))
                .foregroundColor(AppColors.warning)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(tip.title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.primary)
                Text(tip.detail)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button(action: onTryAgain) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text(String(localized: "TRY AGAIN"))
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [AppColors.primaryAccent, AppColors.primaryAccent.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(14)
                .shadow(color: AppColors.primaryAccent.opacity(0.4), radius: 12, y: 4)
            }

            Button(action: onShowTips) {
                HStack {
                    Image(systemName: "book.fill")
                    Text(String(localized: "SURVIVAL TIPS"))
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.black.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(AppColors.primaryAccent.opacity(0.5), lineWidth: 1.5)
                )
                .foregroundColor(AppColors.primaryAccent)
            }

            if let shareText = generateShareText() {
                ShareLink(item: shareText) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text(String(localized: "SHARE"))
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
            }
        }
    }

    private func generateShareText() -> String? {
        let rating = report.survivalRating.rawValue
        let score = report.finalScore
        return "I scored \(score)/100 on QuakeSense earthquake survival drill (M\(String(format: "%.1f", report.magnitude))) — Rating: \(rating). Would you survive? #QuakeSense #EarthquakeSafety"
    }

    // MARK: - Animation

    private func animateResults() {
        let motionDisabled = reduceMotion || SettingsManager.shared.isReducedMotionEnabled

        // When reduced motion is on, show everything immediately
        if motionDisabled {
            displayedScore = report.finalScore
            visibleDecisions = report.decisions.count
            showTimeline = true
            showFacts = true
            visibleFacts = randomTips.count
            return
        }

        // Score count-up
        let targetScore = report.finalScore
        let steps = 30
        let stepDuration = 1.0 / Double(steps)

        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * stepDuration) {
                withAnimation(.easeOut(duration: 0.05)) {
                    displayedScore = Int(Double(targetScore) * Double(i) / Double(steps))
                }
            }
        }

        // Decisions appear one by one
        for i in 0..<report.decisions.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2 + Double(i) * 0.3) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    visibleDecisions = i + 1
                }
            }
        }

        // Timeline appears after decisions
        let timelineDelay = 1.4 + Double(report.decisions.count) * 0.3
        DispatchQueue.main.asyncAfter(deadline: .now() + timelineDelay) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showTimeline = true
            }
        }

        // Facts appear with staggered slide-in
        let factsDelay = timelineDelay + 0.5
        DispatchQueue.main.asyncAfter(deadline: .now() + factsDelay) {
            withAnimation(.easeInOut(duration: 0.5)) {
                showFacts = true
            }
            // Stagger each tip 0.4s apart
            let tipCount = randomTips.count
            for i in 0..<tipCount {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.4) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        visibleFacts = i + 1
                    }
                }
            }
        }
    }
}

// MARK: - Decision Detail Row Component

struct DecisionDetailRow: View {
    let decision: EnhancedDecision
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Main row (tappable)
            HStack(spacing: 0) {
                // Left accent bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(decision.isCorrect ? AppColors.correctAction : AppColors.wrongAction)
                    .frame(width: 3, height: 48)
                    .padding(.trailing, 10)

                Image(systemName: decision.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(decision.isCorrect ? AppColors.correctAction : AppColors.wrongAction)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(decision.action.displayName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)

                        // Combo badge
                        if decision.comboMultiplier > 1 {
                            Text("\(decision.comboMultiplier)x")
                                .font(.system(.caption2, design: .rounded).weight(.bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.orange))
                        }
                    }

                    HStack(spacing: 8) {
                        Text(String(format: "%.1fs", decision.responseTime))
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.secondary)

                        if decision.timeBonus > 0 {
                            Text("+\(decision.timeBonus) bonus")
                                .font(.system(.caption2, design: .rounded).weight(.medium))
                                .foregroundColor(AppColors.primaryAccent)
                        }

                    }
                }
                .padding(.leading, 12)

                Spacer()

                HStack(spacing: 8) {
                    Text(decision.totalPoints >= 0 ? "+\(decision.totalPoints)" : "\(decision.totalPoints)")
                        .font(.system(.subheadline, design: .monospaced).weight(.bold))
                        .foregroundColor(decision.isCorrect ? AppColors.correctAction : AppColors.wrongAction)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }

            // Expanded detail section
            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    Divider()

                    // Educational feedback
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: decision.isCorrect ? "lightbulb.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(decision.isCorrect ? AppColors.correctAction : AppColors.wrongAction)
                            .font(.caption)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(decision.isCorrect ? "Good choice!" : "Not the safest option")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(decision.isCorrect ? AppColors.correctAction : AppColors.wrongAction)

                            Text(educationalFeedback)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    // "What if?" scenario
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundColor(AppColors.primaryAccent)
                            .font(.caption)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("What if?")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(AppColors.primaryAccent)

                            Text(whatIfScenario)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    // Performance analysis
                    HStack(spacing: 16) {
                        performanceBadge(
                            icon: "timer",
                            label: "Response Time",
                            value: String(format: "%.1fs", decision.responseTime),
                            color: AppColors.primaryAccent
                        )

                        if decision.comboMultiplier > 1 {
                            performanceBadge(
                                icon: "flame.fill",
                                label: "Combo",
                                value: "\(decision.comboMultiplier)x",
                                color: .orange
                            )
                        }

                        if decision.timeBonus > 0 {
                            performanceBadge(
                                icon: "star.fill",
                                label: "Speed Bonus",
                                value: "+\(decision.timeBonus)",
                                color: AppColors.primaryAccent
                            )
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            }
        }
    }

    private var educationalFeedback: String {
        switch decision.action {
        case .dropUnderTable:
            return "You made the right choice! Getting under sturdy furniture is the safest place during an earthquake. This protects you from falling debris."
        case .stayStanding:
            return "Standing during an earthquake is dangerous. You could be hit by falling objects, thrown furniture, or shattered glass. Drop, Cover, and Hold On!"
        case .moveToWindow:
            return "Windows are extremely dangerous during earthquakes. Glass can shatter and send sharp fragments flying. Stay away from all windows and glass doors."
        case .runToDoor:
            return "Doorways are NOT safer than other parts of modern buildings. This is a myth from old adobe construction. Under a table is always safer."
        case .shutOffGas:
            return "Excellent! Turning off gas prevents fires, which are a major secondary hazard after earthquakes. This is one of the most important aftershock tasks."
        case .checkInjuries:
            return "Checking injuries first is smart. You can't help others if you're hurt. Always assess yourself before assisting others."
        case .findSafeExit:
            return "Finding a safe exit is crucial, but check for debris first. Falling objects can block doors and create new hazards."
        default:
            return decision.isCorrect ? "Well done! You made a safe choice." : "This wasn't the safest option."
        }
    }

    private var whatIfScenario: String {
        switch decision.action {
        case .stayStanding:
            return "If you had dropped under the table, you'd be protected from 90% of earthquake injuries. Remember: Drop, Cover, Hold On!"
        case .moveToWindow:
            return "If you had moved away from the window, you'd avoid the #1 cause of earthquake injuries: shattered glass."
        case .runToDoor:
            return "If you had stayed under cover instead of running to the door, you'd avoid falling debris and be much safer."
        case .dropUnderTable:
            return "You did great! Keep practicing this response to build muscle memory - it could save your life in a real earthquake."
        case .shutOffGas:
            return "Gas fires are responsible for many post-earthquake disasters. By turning off the gas, you may have prevented a major fire!"
        case .checkInjuries:
            return "Quick injury assessment is crucial - every second counts when treating serious injuries. Good prioritization!"
        default:
            return decision.isCorrect ? "You followed the right procedure. Keep practicing to build your survival instincts!" : "Next time, remember: Drop, Cover, and Hold On is the safest response."
        }
    }

    private func performanceBadge(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(.caption2).weight(.semibold))
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(6)
    }
}

// MARK: - Confetti SpriteKit Scene

@MainActor
final class ConfettiScene: SKScene {
    override init() {
        super.init(size: UIScreen.main.bounds.size)
        scaleMode = .resizeFill
        backgroundColor = .clear
        view?.allowsTransparency = true
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        view.allowsTransparency = true
        backgroundColor = .clear

        let emitter = ParticleEffects.celebrationConfetti(
            at: CGPoint(x: size.width / 2, y: size.height + 20),
            intensity: 1.0
        )
        emitter.particlePositionRange = CGVector(dx: size.width, dy: 0)
        addChild(emitter)

        // Auto-stop emission after 2s, let remaining particles finish
        run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.run { emitter.particleBirthRate = 0 }
        ]))
    }
}
