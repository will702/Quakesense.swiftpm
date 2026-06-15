import SwiftUI
import Combine

// MARK: - Custom Button Styles

/// Main action button with gradient, glow, and press effects
struct QuakeButtonStyle: ButtonStyle {
    var color: Color = AppColors.correctAction
    var gradient: [Color]?
    var glowRadius: CGFloat = 12
    var cornerRadius: CGFloat = 20
    var scaleEffect: CGFloat = 0.93
    
    func makeBody(configuration: Configuration) -> some View {
        let gradientColors = gradient ?? [color, color.opacity(0.8)]
        
        return configuration.label
            .scaleEffect(configuration.isPressed ? scaleEffect : 1.0)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .background(
                ZStack {
                    // Glow effect
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(color.opacity(0.3))
                        .blur(radius: glowRadius)
                        .opacity(configuration.isPressed ? 0.5 : 1.0)
                    
                    // Main button background
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    // Inner highlight
                    RoundedRectangle(cornerRadius: cornerRadius)
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
            .shadow(
                color: color.opacity(configuration.isPressed ? 0.2 : 0.4),
                radius: configuration.isPressed ? 6 : glowRadius,
                x: 0,
                y: configuration.isPressed ? 2 : 6
            )
    }
}

/// Danger button style for destructive actions
struct DangerButtonStyle: ButtonStyle {
    var glowRadius: CGFloat = 12
    var cornerRadius: CGFloat = 20
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .background(
                ZStack {
                    // Glow effect
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(AppColors.wrongAction.opacity(0.3))
                        .blur(radius: glowRadius)
                        .opacity(configuration.isPressed ? 0.5 : 1.0)
                    
                    // Main gradient
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [AppColors.wrongAction, Color(hex: 0xCC2A20)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    // Inner highlight
                    RoundedRectangle(cornerRadius: cornerRadius)
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
            .shadow(
                color: AppColors.wrongAction.opacity(configuration.isPressed ? 0.2 : 0.4),
                radius: configuration.isPressed ? 6 : glowRadius,
                x: 0,
                y: configuration.isPressed ? 2 : 6
            )
    }
}

/// Success button style for positive actions
struct SuccessButtonStyle: ButtonStyle {
    var glowRadius: CGFloat = 12
    var cornerRadius: CGFloat = 20
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .background(
                ZStack {
                    // Glow effect
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(AppColors.correctAction.opacity(0.3))
                        .blur(radius: glowRadius)
                        .opacity(configuration.isPressed ? 0.5 : 1.0)
                    
                    // Main gradient
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [AppColors.correctAction, Color(hex: 0x2AA84B)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    // Inner highlight
                    RoundedRectangle(cornerRadius: cornerRadius)
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
            .shadow(
                color: AppColors.correctAction.opacity(configuration.isPressed ? 0.2 : 0.4),
                radius: configuration.isPressed ? 6 : glowRadius,
                x: 0,
                y: configuration.isPressed ? 2 : 6
            )
    }
}

/// Circular icon button style
struct IconButtonStyle: ButtonStyle {
    var color: Color = AppColors.primaryAccent
    var size: CGFloat = 56
    var iconScale: CGFloat = 0.4
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size * iconScale, weight: .semibold))
            .frame(width: size, height: size)
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .background(
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .blur(radius: 8)
                        .scaleEffect(configuration.isPressed ? 0.8 : 1.2)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.9), color],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .foregroundColor(.white)
            .shadow(
                color: color.opacity(configuration.isPressed ? 0.2 : 0.4),
                radius: configuration.isPressed ? 4 : 10,
                x: 0,
                y: configuration.isPressed ? 2 : 4
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Progress Indicators

/// Earthquake intensity gauge with color gradient from green to red
struct IntensityGauge: View {
    let value: Double // 0-100
    var label: String = "Intensity"
    var showPercentage: Bool = true
    var height: CGFloat = 24
    
    private var intensityColor: Color {
        switch value {
        case 0..<30: return AppColors.correctAction
        case 30..<60: return AppColors.warning
        case 60..<80: return Color.orange
        default: return AppColors.wrongAction
        }
    }
    
    private var gradientColors: [Color] {
        [AppColors.correctAction, AppColors.warning, Color.orange, AppColors.wrongAction]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if showPercentage {
                    Text("\(Int(value))%")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundColor(intensityColor)
                        .contentTransition(.numericText())
                }
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(Color.black.opacity(0.08))
                    
                    // Gradient fill
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .mask(
                            HStack {
                                RoundedRectangle(cornerRadius: height / 2)
                                    .frame(width: max(0, min(geo.size.width, geo.size.width * value / 100)))
                                Spacer(minLength: 0)
                            }
                        )
                    
                    // Glow effect at the leading edge
                    Circle()
                        .fill(intensityColor)
                        .frame(width: height * 0.6, height: height * 0.6)
                        .blur(radius: 4)
                        .offset(x: max(0, min(geo.size.width - height * 0.6, geo.size.width * value / 100 - height * 0.3)))
                }
            }
            .frame(height: height)
        }
    }
}

/// Animated health/heart display with pulse on damage
struct HealthHeartBar: View {
    let currentHealth: Int
    let maxHealth: Int = 3
    var damageTaken: Bool = false
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var shakeOffset: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<maxHealth, id: \.self) { index in
                Image(systemName: index < currentHealth ? "heart.fill" : "heart.slash.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(index < currentHealth ? AppColors.wrongAction : Color.gray.opacity(0.3))
                    .scaleEffect(index < currentHealth ? pulseScale : 1.0)
                    .offset(x: damageTaken && index >= currentHealth ? shakeOffset : 0)
                    .animation(
                        .spring(response: 0.3, dampingFraction: 0.5)
                        .delay(Double(index) * 0.05),
                        value: currentHealth
                    )
            }
        }
        .onAppear {
            startPulseAnimation()
        }
        .onChange(of: damageTaken) { isDamaged in
            if isDamaged {
                startDamageAnimation()
            }
        }
    }
    
    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            pulseScale = 1.15
        }
    }
    
    private func startDamageAnimation() {
        withAnimation(.easeInOut(duration: 0.05).repeatCount(5)) {
            shakeOffset = 3
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            shakeOffset = 0
        }
    }
}

/// Combo meter with fire particles effect
struct ComboMeter: View {
    let combo: Int
    let multiplier: Double
    
    @State private var particleOffsets: [CGSize] = []
    @State private var particleOpacities: [Double] = []
    @State private var scale: CGFloat = 1.0
    
    private var isActive: Bool { combo > 1 }
    private var comboColor: Color {
        switch combo {
        case 2...4: return AppColors.warning
        case 5...9: return Color.orange
        case 10...: return AppColors.wrongAction
        default: return AppColors.correctAction
        }
    }
    
    var body: some View {
        ZStack {
            // Fire particles
            if isActive {
                ForEach(0..<6, id: \.self) { index in
                    FireParticle(
                        offset: particleOffsets[safe: index] ?? .zero,
                        opacity: particleOpacities[safe: index] ?? 0
                    )
                }
            }
            
            // Main combo badge
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(.subheadline, weight: .bold))

                Text("\(combo)x")
                    .font(.system(.title3, design: .rounded).weight(.black))

                if multiplier > 1 {
                    Text("(\(String(format: "%.1f", multiplier))x)")
                        .font(.system(.caption2, design: .rounded))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(comboColor.opacity(0.2))
                    .overlay(
                        Capsule()
                            .stroke(comboColor, lineWidth: 2)
                    )
            )
            .foregroundColor(comboColor)
            .scaleEffect(scale)
        }
        .opacity(isActive ? 1 : 0)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: combo)
        .onAppear {
            initializeParticles()
            startAnimations()
        }
        .onChange(of: combo) { _ in
            pulseCombo()
            updateParticles()
        }
    }
    
    private func initializeParticles() {
        particleOffsets = Array(repeating: .zero, count: 6)
        particleOpacities = Array(repeating: 0, count: 6)
    }
    
    private func updateParticles() {
        guard isActive else { return }
        
        for i in 0..<6 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                withAnimation(.easeOut(duration: 0.6)) {
                    particleOffsets[i] = CGSize(
                        width: CGFloat.random(in: -30...30),
                        height: CGFloat.random(in: -40...(-10))
                    )
                    particleOpacities[i] = 0
                }
                
                particleOpacities[i] = 1
            }
        }
    }
    
    private func startAnimations() {
        Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { _ in
            Task { @MainActor in
                if self.isActive {
                    self.updateParticles()
                }
            }
        }
    }
    
    private func pulseCombo() {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
            scale = 1.3
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 1.0
            }
        }
    }
}

/// Fire particle for combo meter
private struct FireParticle: View {
    let offset: CGSize
    let opacity: Double
    
    var body: some View {
        Image(systemName: "flame.fill")
            .font(.system(size: CGFloat.random(in: 8...14)))
            .foregroundColor(.orange)
            .offset(offset)
            .opacity(opacity)
            .blur(radius: 1)
    }
}

/// Circular progress ring for achievements
struct ProgressRing: View {
    let progress: Double // 0-1
    var lineWidth: CGFloat = 12
    var color: Color = AppColors.primaryAccent
    var showPercentage: Bool = true
    var size: CGFloat = 100
    
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        colors: [color, color.opacity(0.7)],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            
            // Glow at the end
            Circle()
                .fill(color)
                .frame(width: lineWidth * 0.8, height: lineWidth * 0.8)
                .offset(x: size / 2 - lineWidth / 2)
                .rotationEffect(.degrees(animatedProgress * 360 - 90))
                .blur(radius: 3)
            
            // Center content
            if showPercentage {
                VStack(spacing: 0) {
                    Text("\(Int(animatedProgress * 100))%")
                        .font(.system(size: size * 0.24, weight: .bold, design: .rounded))
                        .foregroundColor(color)
                    
                    if progress >= 1 {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: size * 0.18))
                            .foregroundColor(AppColors.correctAction)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Cards & Panels

/// Shows decision result with animation
struct DecisionCard: View {
    let isCorrect: Bool
    let message: String
    let explanation: String?
    var onDismiss: (() -> Void)?
    
    @State private var appear = false
    @State private var iconScale: CGFloat = 0
    @State private var iconRotation: Double = 0
    
    var body: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(isCorrect ? AppColors.correctAction.opacity(0.2) : AppColors.wrongAction.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Circle()
                    .stroke(isCorrect ? AppColors.correctAction : AppColors.wrongAction, lineWidth: 3)
                    .frame(width: 80, height: 80)
                
                Image(systemName: isCorrect ? "checkmark" : "xmark")
                    .font(.system(.title, weight: .bold))
                    .foregroundColor(isCorrect ? AppColors.correctAction : AppColors.wrongAction)
                    .scaleEffect(iconScale)
                    .rotationEffect(.degrees(iconRotation))
            }
            
            // Message
            Text(message)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundColor(isCorrect ? AppColors.correctAction : AppColors.wrongAction)
                .multilineTextAlignment(.center)
            
            // Explanation
            if let explanation = explanation {
                Text(explanation)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Dismiss button
            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Text("Continue")
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isCorrect ? AppColors.correctAction : AppColors.primaryAccent)
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: (isCorrect ? AppColors.correctAction : AppColors.wrongAction).opacity(0.2), radius: 20, x: 0, y: 10)
        )
        .scaleEffect(appear ? 1.0 : 0.8)
        .opacity(appear ? 1.0 : 0)
        .offset(y: appear ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appear = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5).delay(0.1)) {
                iconScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.3).delay(0.2)) {
                iconRotation = isCorrect ? 0 : 180
            }
        }
    }
}

/// Achievement unlock card
struct AchievementCard: View {
    let title: String
    let description: String
    let icon: String
    var rarity: Rarity = .common
    
    @State private var appear = false
    @State private var glowIntensity: CGFloat = 0.5
    
    enum Rarity {
        case common, rare, epic, legendary
        
        var color: Color {
            switch self {
            case .common: return Color.gray
            case .rare: return AppColors.primaryAccent
            case .epic: return Color.purple
            case .legendary: return Color.orange
            }
        }
        
        var gradient: [Color] {
            switch self {
            case .common: return [Color.gray, Color.gray.opacity(0.7)]
            case .rare: return [AppColors.primaryAccent, Color.cyan]
            case .epic: return [Color.purple, Color.pink]
            case .legendary: return [Color.orange, Color.red, Color.yellow]
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon with glow
            ZStack {
                // Glow effect
                Circle()
                    .fill(rarity.color)
                    .frame(width: 60, height: 60)
                    .blur(radius: 15)
                    .opacity(glowIntensity)
                
                // Icon background
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: rarity.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(.title, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Achievement Unlocked!")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundColor(rarity.color)
                
                Text(title)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(rarity.color.opacity(0.3), lineWidth: 2)
                )
                .shadow(color: rarity.color.opacity(0.2), radius: 15, x: 0, y: 8)
        )
        .scaleEffect(appear ? 1.0 : 0.9)
        .opacity(appear ? 1.0 : 0)
        .offset(x: appear ? 0 : -50)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                appear = true
            }
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                glowIntensity = 1.0
            }
        }
    }
}

/// Room selection card
struct RoomSelectionCard: View {
    let roomType: RoomType
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isHovered = false
    
    // Using RoomBuilder.RoomType for consistency
    // Extensions for UI properties are in RoomTypes.swift
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? AppColors.primaryAccent.opacity(0.15) : Color.gray.opacity(0.1))
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: roomType.iconName)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(isSelected ? AppColors.primaryAccent : .secondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(roomType.displayName)
                            .font(.system(.headline, design: .rounded).weight(.semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Difficulty badge
                        Text(roomType.difficultyLabel)
                            .font(.system(.caption, design: .rounded).weight(.medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(roomType.difficultyColor.opacity(0.15))
                            )
                            .foregroundColor(roomType.difficultyColor)
                    }
                    
                    Text(roomType.shortDescription)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(isSelected ? AppColors.primaryAccent : .gray.opacity(0.3))
                    .scaleEffect(isSelected ? 1.1 : 1.0)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                isSelected ? AppColors.primaryAccent : Color.clear,
                                lineWidth: 2
                            )
                    )
                    .shadow(
                        color: isSelected ? AppColors.primaryAccent.opacity(0.2) : Color.black.opacity(0.05),
                        radius: isSelected ? 12 : 8,
                        x: 0,
                        y: isSelected ? 6 : 4
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

/// Educational tip panel
struct TipPanel: View {
    let icon: String
    let title: String
    let message: String
    var style: TipStyle = .info
    
    @State private var appear = false
    
    enum TipStyle {
        case info, warning, success, danger
        
        var color: Color {
            switch self {
            case .info: return AppColors.primaryAccent
            case .warning: return AppColors.warning
            case .success: return AppColors.correctAction
            case .danger: return AppColors.wrongAction
            }
        }
        
        var icon: String {
            switch self {
            case .info: return "info.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .success: return "checkmark.circle.fill"
            case .danger: return "xmark.octagon.fill"
            }
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            Image(systemName: style.icon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(style.color)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(style.color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(style.color.opacity(0.2), lineWidth: 1)
                )
        )
        .offset(x: appear ? 0 : -20)
        .opacity(appear ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appear = true
            }
        }
    }
}

// MARK: - Animations

/// Text that shakes
struct ShakeText: View {
    let text: String
    var font: Font = .system(.title, design: .rounded)
    var color: Color = .primary
    var intensity: CGFloat = 3
    var speed: Double = 0.1
    var autoShake: Bool = false
    
    @State private var offset: CGSize = .zero
    @State private var shakeTimer: Timer?
    
    var body: some View {
        Text(text)
            .font(font)
            .foregroundColor(color)
            .offset(offset)
            .onAppear {
                if autoShake {
                    startShaking()
                }
            }
            .onDisappear {
                shakeTimer?.invalidate()
            }
    }
    
    func startShaking() {
        let speed = self.speed
        let intensity = self.intensity
        shakeTimer = Timer.scheduledTimer(withTimeInterval: speed, repeats: true) { _ in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: speed / 2)) {
                    self.offset = CGSize(
                        width: CGFloat.random(in: -intensity...intensity),
                        height: CGFloat.random(in: -intensity...intensity)
                    )
                }
            }
        }
    }
    
    func stopShaking() {
        shakeTimer?.invalidate()
        shakeTimer = nil
        withAnimation(.easeOut(duration: 0.2)) {
            offset = .zero
        }
    }
    
    func shakeOnce() {
        withAnimation(.easeInOut(duration: speed)) {
            offset = CGSize(width: intensity, height: 0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + speed) {
            withAnimation(.easeInOut(duration: speed)) {
                offset = CGSize(width: -intensity, height: 0)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + speed * 2) {
            withAnimation(.easeInOut(duration: speed)) {
                offset = .zero
            }
        }
    }
}

/// Pulsing glow effect view modifier
struct PulseGlow: ViewModifier {
    var color: Color = AppColors.primaryAccent
    var radius: CGFloat = 20
    var minOpacity: Double = 0.3
    var maxOpacity: Double = 0.8
    var duration: Double = 1.5
    
    @State private var opacity: Double = 0.3
    @State private var scale: CGFloat = 1.0
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(color.opacity(opacity))
                    .blur(radius: radius)
                    .scaleEffect(scale)
            )
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    opacity = maxOpacity
                    scale = 1.1
                }
            }
    }
}

extension View {
    func pulseGlow(
        color: Color = AppColors.primaryAccent,
        radius: CGFloat = 20,
        minOpacity: Double = 0.3,
        maxOpacity: Double = 0.8,
        duration: Double = 1.5
    ) -> some View {
        modifier(PulseGlow(
            color: color,
            radius: radius,
            minOpacity: minOpacity,
            maxOpacity: maxOpacity,
            duration: duration
        ))
    }
}

/// Animated number counter
struct CountUpNumber: View {
    let value: Int
    var font: Font = .system(.title, design: .rounded)
    var color: Color = .primary
    var duration: Double = 0.8
    var suffix: String = ""
    var prefix: String = ""

    @State private var displayValue: Int = 0
    @State private var timerCancellable: Cancellable?

    var body: some View {
        Text("\(prefix)\(displayValue)\(suffix)")
            .font(font)
            .foregroundColor(color)
            .contentTransition(.numericText())
            .onAppear {
                animateValue()
            }
            .onChange(of: value) { _ in
                timerCancellable?.cancel()
                animateValue()
            }
            .onDisappear {
                timerCancellable?.cancel()
            }
    }

    private func animateValue() {
        let step = max(1, value / 30)
        let stepDuration = duration / Double(value / step)
        let targetValue = value

        var current = 0
        let publisher = Timer.publish(every: stepDuration, on: .main, in: .common)
            .autoconnect()
            .prefix(while: { _ in current < targetValue })

        timerCancellable = publisher
            .sink { _ in
                current += step
                if current >= targetValue {
                    current = targetValue
                    timerCancellable?.cancel()
                }
                displayValue = current
            }
    }
}

/// View that slides in with animation
struct SlideInView<Content: View>: View {
    @ViewBuilder let content: Content
    var direction: SlideDirection = .bottom
    var delay: Double = 0
    var duration: Double = 0.5
    var distance: CGFloat = 50
    
    @State private var offset: CGSize
    @State private var opacity: Double = 0
    
    enum SlideDirection {
        case left, right, top, bottom
        
        var offset: CGSize {
            switch self {
            case .left: return CGSize(width: -50, height: 0)
            case .right: return CGSize(width: 50, height: 0)
            case .top: return CGSize(width: 0, height: -50)
            case .bottom: return CGSize(width: 0, height: 50)
            }
        }
    }
    
    init(
        direction: SlideDirection = .bottom,
        delay: Double = 0,
        duration: Double = 0.5,
        distance: CGFloat = 50,
        @ViewBuilder content: () -> Content
    ) {
        self.direction = direction
        self.delay = delay
        self.duration = duration
        self.distance = distance
        self.content = content()
        self._offset = State(initialValue: direction.offset)
    }
    
    var body: some View {
        content
            .offset(offset)
            .opacity(opacity)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.spring(response: duration, dampingFraction: 0.7)) {
                        offset = .zero
                        opacity = 1
                    }
                }
            }
    }
}

// MARK: - Overlays

/// Big combo announcement overlay
struct ComboOverlay: View {
    let combo: Int
    var onComplete: (() -> Void)?
    
    @State private var scale: CGFloat = 0.1
    @State private var opacity: Double = 0
    @State private var rotation: Double = -30
    
    private var comboText: String {
        switch combo {
        case 2...4: return "COMBO!"
        case 5...9: return "AWESOME!"
        case 10...14: return "INCREDIBLE!"
        case 15...: return "LEGENDARY!"
        default: return ""
        }
    }
    
    private var color: Color {
        switch combo {
        case 2...4: return AppColors.warning
        case 5...9: return Color.orange
        case 10...14: return Color.red
        case 15...: return Color.purple
        default: return .gray
        }
    }
    
    var body: some View {
        ZStack {
            // Glow effect
            Text("\(combo)")
                .font(.system(size: 200, weight: .black, design: .rounded))
                .foregroundColor(color)
                .blur(radius: 30)
                .opacity(opacity * 0.5)
            
            VStack(spacing: -20) {
                Text(comboText)
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundColor(color)
                    .shadow(color: color.opacity(0.5), radius: 10)
                
                HStack(spacing: 0) {
                    Text("\(combo)")
                        .font(.system(size: 120, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("x")
                        .font(.system(size: 60, weight: .black, design: .rounded))
                        .foregroundColor(color)
                        .offset(y: -20)
                }
                .shadow(color: color.opacity(0.8), radius: 20)
            }
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
        }
        .onAppear {
            // Pop in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                scale = 1.0
                rotation = 0
                opacity = 1
            }
            
            // Hold and fade out
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    scale = 1.5
                    opacity = 0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onComplete?()
                }
            }
        }
    }
}

/// Achievement unlock celebration overlay
struct AchievementOverlay: View {
    let title: String
    let icon: String
    var onComplete: (() -> Void)?
    
    @State private var cardOffset: CGFloat = 200
    @State private var cardScale: CGFloat = 0.8
    @State private var particleOffsets: [CGSize] = []
    
    var body: some View {
        ZStack {
            // Celebration particles
            ForEach(0..<20, id: \.self) { index in
                CelebrationParticle(
                    offset: particleOffsets[safe: index] ?? .zero,
                    color: index % 2 == 0 ? AppColors.correctAction : AppColors.primaryAccent
                )
            }
            
            // Achievement card
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.correctAction, Color.orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: icon)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 4) {
                    Text("Achievement Unlocked!")
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Text(title)
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.2), radius: 30, x: 0, y: 15)
            )
            .offset(y: cardOffset)
            .scaleEffect(cardScale)
        }
        .onAppear {
            // Initialize particles
            particleOffsets = (0..<20).map { _ in
                CGSize(
                    width: CGFloat.random(in: -200...200),
                    height: CGFloat.random(in: -300...(-100))
                )
            }
            
            // Animate particles
            withAnimation(.easeOut(duration: 1.0)) {
                particleOffsets = particleOffsets.map { _ in
                    CGSize(
                        width: CGFloat.random(in: -300...300),
                        height: CGFloat.random(in: 100...400)
                    )
                }
            }
            
            // Slide in card
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                cardOffset = 0
                cardScale = 1.0
            }
            
            // Dismiss after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeIn(duration: 0.3)) {
                    cardOffset = -200
                    cardScale = 0.8
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onComplete?()
                }
            }
        }
    }
}

/// Celebration particle for achievement overlay
private struct CelebrationParticle: View {
    let offset: CGSize
    let color: Color
    
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1
    
    var body: some View {
        Image(systemName: ["star.fill", "sparkle", "circle.fill"].randomElement()!)
            .font(.system(size: CGFloat.random(in: 12...24)))
            .foregroundColor(color)
            .offset(offset)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .onAppear {
                withAnimation(.linear(duration: 1.0)) {
                    rotation = Double.random(in: -180...180)
                }
                withAnimation(.easeIn(duration: 1.0)) {
                    opacity = 0
                }
            }
    }
}

/// Warning banner for danger alerts
struct WarningBanner: View {
    let message: String
    var style: BannerStyle = .warning
    var autoDismiss: Bool = true
    var onDismiss: (() -> Void)?
    
    @State private var offset: CGFloat = -100
    @State private var opacity: Double = 0
    
    enum BannerStyle {
        case warning, danger, info
        
        var color: Color {
            switch self {
            case .warning: return AppColors.warning
            case .danger: return AppColors.wrongAction
            case .info: return AppColors.primaryAccent
            }
        }
        
        var icon: String {
            switch self {
            case .warning: return "exclamationmark.triangle.fill"
            case .danger: return "exclamationmark.octagon.fill"
            case .info: return "info.circle.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: style.icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
            
            Text(message)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundColor(.white)
                .lineLimit(2)
            
            Spacer(minLength: 0)
            
            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            ZStack {
                // Main background
                RoundedRectangle(cornerRadius: 0)
                    .fill(style.color)
                
                // Top highlight
                VStack {
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 1)
                    Spacer()
                }
            }
        )
        .offset(y: offset)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                offset = 0
                opacity = 1
            }
            
            if autoDismiss {
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    dismiss()
                }
            }
        }
    }
    
    private func dismiss() {
        withAnimation(.easeIn(duration: 0.3)) {
            offset = -100
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss?()
        }
    }
}

// MARK: - Helper Extensions

private extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Previews

#Preview("Button Styles") {
    ScrollView {
        VStack(spacing: 20) {
            Button("Quake Button") {}
                .buttonStyle(QuakeButtonStyle())
                .foregroundColor(.white)
                .frame(height: 60)
            
            Button("Danger Button") {}
                .buttonStyle(DangerButtonStyle())
                .foregroundColor(.white)
                .frame(height: 60)
            
            Button("Success Button") {}
                .buttonStyle(SuccessButtonStyle())
                .foregroundColor(.white)
                .frame(height: 60)
            
            HStack(spacing: 20) {
                Button(action: {}) {
                    Image(systemName: "star.fill")
                }
                .buttonStyle(IconButtonStyle(color: AppColors.primaryAccent))

                Button(action: {}) {
                    Image(systemName: "heart.fill")
                }
                .buttonStyle(IconButtonStyle(color: AppColors.wrongAction, size: 48))

                Button(action: {}) {
                    Image(systemName: "checkmark")
                }
                .buttonStyle(IconButtonStyle(color: AppColors.correctAction, size: 40))
            }
        }
        .padding()
    }
}

#Preview("Progress Indicators") {
    ScrollView {
        VStack(spacing: 30) {
            IntensityGauge(value: 65, label: "Earthquake Intensity")
            
            IntensityGauge(value: 30, label: "Low Risk", height: 16)
            
            HStack(spacing: 30) {
                HealthHeartBar(currentHealth: 2, damageTaken: false)
                HealthHeartBar(currentHealth: 1, damageTaken: true)
            }
            
            ComboMeter(combo: 5, multiplier: 1.5)
            ComboMeter(combo: 10, multiplier: 2.0)
            
            HStack(spacing: 30) {
                ProgressRing(progress: 0.75, color: AppColors.primaryAccent)
                ProgressRing(progress: 1.0, color: AppColors.correctAction, size: 80)
            }
        }
        .padding()
    }
}

#Preview("Cards & Panels") {
    ScrollView {
        VStack(spacing: 20) {
            DecisionCard(
                isCorrect: true,
                message: "Great Decision!",
                explanation: "You found a safe spot under the table."
            )
            
            DecisionCard(
                isCorrect: false,
                message: "Too Dangerous!",
                explanation: "Windows can shatter during earthquakes."
            )
            
            AchievementCard(
                title: "Survival Expert",
                description: "Complete 10 drills without taking damage",
                icon: "shield.fill",
                rarity: .epic
            )
            
            RoomSelectionCard(
                roomType: .kitchen,
                isSelected: false,
                onTap: {}
            )
            
            RoomSelectionCard(
                roomType: .livingRoom,
                isSelected: true,
                onTap: {}
            )
            
            TipPanel(
                icon: "exclamationmark.triangle",
                title: "Drop, Cover, and Hold On",
                message: "This is the recommended safety action during an earthquake.",
                style: .warning
            )
            
            TipPanel(
                icon: "checkmark.circle",
                title: "Well Done!",
                message: "You found a safe location away from windows.",
                style: .success
            )
        }
        .padding()
    }
}

#Preview("Animations") {
    ScrollView {
        VStack(spacing: 30) {
            ShakeText(text: "Shaking Text!", font: .system(.title, design: .rounded), autoShake: true)
            
            Text("Pulse Glow")
                .font(.title)
                .padding()
                .pulseGlow(color: AppColors.primaryAccent, radius: 20)
            
            CountUpNumber(value: 100, font: .system(.largeTitle, design: .rounded), suffix: " pts")
            
            SlideInView(direction: .left) {
                Text("Slide from Left")
                    .font(.headline)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue.opacity(0.2)))
            }
            
            SlideInView(direction: .bottom, delay: 0.3) {
                Text("Slide from Bottom")
                    .font(.headline)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.green.opacity(0.2)))
            }
        }
        .padding()
    }
}

#Preview("Overlays") {
    ZStack {
        Color.gray.opacity(0.2).ignoresSafeArea()
        
        VStack(spacing: 20) {
            ComboOverlay(combo: 10)
                .frame(height: 200)
        }
    }
}

#Preview("Warning Banner") {
    VStack {
        WarningBanner(
            message: "Strong aftershocks detected! Find cover immediately!",
            style: .danger,
            autoDismiss: false
        )
        
        Spacer()
    }
}
