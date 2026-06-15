import SwiftUI

// MARK: - Room Data Model

struct RoomInfo: Identifiable {
    let id = UUID()
    let type: RoomBuilder.RoomType
    let name: String
    let difficulty: Int // 1-5
    let isUnlocked: Bool
    let timesPlayed: Int
    let bestScore: Int?
    let keyHazards: [String]
    let safetyTip: String
    let strategyHint: String
    let iconName: String
    let accentColor: Color
    let previewSprites: [String]
    
    static let allRooms: [RoomInfo] = [
        RoomInfo(
            type: .livingRoom,
            name: String(localized: "Living Room"),
            difficulty: 2,
            isUnlocked: true,
            timesPlayed: 0,
            bestScore: nil,
            keyHazards: [String(localized: "Falling Bookshelf"), String(localized: "Broken Glass"), String(localized: "Ceiling Lamp")],
            safetyTip: String(localized: "Get under the table quickly"),
            strategyHint: String(localized: "Center position for quick table access"),
            iconName: "sofa.fill",
            accentColor: AppColors.primaryAccent,
            previewSprites: ["player_stand", "player_duck", "player_hold1"]
        ),
        RoomInfo(
            type: .kitchen,
            name: String(localized: "Kitchen"),
            difficulty: 4,
            isUnlocked: true,
            timesPlayed: 0,
            bestScore: nil,
            keyHazards: [String(localized: "Gas Leak Risk"), String(localized: "Falling Pots"), String(localized: "Refrigerator Tip")],
            safetyTip: String(localized: "Hide under the kitchen island"),
            strategyHint: String(localized: "Avoid stove area - gas leak danger"),
            iconName: "flame.fill",
            accentColor: Color.orange,
            previewSprites: ["player_idle", "player_duck", "player_action1"]
        ),
        RoomInfo(
            type: .office,
            name: String(localized: "Office"),
            difficulty: 3,
            isUnlocked: false,
            timesPlayed: 0,
            bestScore: nil,
            keyHazards: [String(localized: "Filing Cabinet"), String(localized: "Falling Monitor"), String(localized: "Rolling Chair")],
            safetyTip: String(localized: "Use the desk as shelter"),
            strategyHint: String(localized: "Watch for rolling office chair"),
            iconName: "desktopcomputer",
            accentColor: Color.purple,
            previewSprites: ["player_walk1", "player_duck", "player_hold2"]
        ),
        RoomInfo(
            type: .bedroom,
            name: String(localized: "Bedroom"),
            difficulty: 5,
            isUnlocked: false,
            timesPlayed: 0,
            bestScore: nil,
            keyHazards: [String(localized: "Tall Wardrobe"), String(localized: "Mirror Shatter"), String(localized: "Nightstand Items")],
            safetyTip: String(localized: "Get under the bed frame"),
            strategyHint: String(localized: "Stay away from wardrobe - it tips easily"),
            iconName: "bed.double.fill",
            accentColor: Color.pink,
            previewSprites: ["player_cheer1", "player_duck", "player_hold1"]
        )
    ]
}

// MARK: - Room Selection View

struct RoomSelectionView: View {
    @Binding var selectedRoom: RoomBuilder.RoomType
    var onRoomSelected: (RoomBuilder.RoomType) -> Void
    var onBack: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @StateObject private var roomUnlockManager = RoomUnlockManager.shared

    @State private var scrollOffset: CGFloat = 0
    @State private var appeared = false
    @State private var floatPhase = false
    @State private var selectedCardIndex: Int = 0
    @State private var cardScale: CGFloat = 1.0

    private var cardWidth: CGFloat {
        SizeClassConstants.cardWidth(for: horizontalSizeClass)
    }

    private var cardSpacing: CGFloat {
        SizeClassConstants.cardSpacing(for: horizontalSizeClass)
    }

    private var carouselHeight: CGFloat {
        SizeClassConstants.carouselHeight(for: verticalSizeClass)
    }

    private var rooms: [RoomInfo] { RoomInfo.allRooms }
    
    var body: some View {
        ZStack {
            AnimatedBackground()
            
            // Floating background icons
            floatingIcons
            
            VStack(spacing: 0) {
                // Header
                headerSection
                    .padding(.top, 20)
                    .adaptivePadding(compact: 16, regular: 24)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : -20)
                
                // Room carousel
                carouselSection
                    .padding(.vertical, 20)
                
                // Page indicator
                pageIndicator
                    .padding(.bottom, 16)
                    .opacity(appeared ? 1 : 0)
                
                Spacer()
            }
        }
        .onAppear {
            // Set initial selected index based on binding
            selectedCardIndex = rooms.firstIndex(where: { $0.type == selectedRoom }) ?? 0
            
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                floatPhase = true
            }
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                appeared = true
            }
        }
        .onChange(of: selectedCardIndex) { newIndex in
            let roomType = rooms[newIndex].type
            selectedRoom = roomType
        }
        #if DEBUG
        .task {
            guard MarketingCapture.isActive else { return }
            // Stills: highlight the pending card
            selectedCardIndex = MarketingCapture.pendingRoomCardIndex
            // Demo: after 4s, navigate into the living room
            guard MarketingCapture.isDemoMode else { return }
            try? await Task.sleep(for: .seconds(4))
            onRoomSelected(.livingRoom)
        }
        #endif
    }
    
    // MARK: - Floating Background Icons
    
    private var floatingIcons: some View {
        GeometryReader { geo in
            let icons: [(name: String, x: CGFloat, y: CGFloat, size: CGFloat, color: Color)] = [
                ("house.fill", 0.08, 0.15, 22, AppColors.primaryAccent),
                ("door.left.hand.open", 0.92, 0.12, 18, Color.orange),
                ("window.ceiling", 0.06, 0.45, 20, Color.purple),
                ("lamp.desk.fill", 0.9, 0.55, 16, Color.pink),
                ("star.fill", 0.15, 0.75, 12, AppColors.primaryAccent.opacity(0.5)),
                ("star.fill", 0.85, 0.78, 10, Color.orange.opacity(0.5)),
                ("sparkle", 0.5, 0.08, 14, AppColors.correctAction),
            ]
            
            ForEach(Array(icons.enumerated()), id: \.offset) { _, icon in
                Image(systemName: icon.name)
                    .font(.system(size: icon.size, weight: .medium))
                    .foregroundColor(icon.color.opacity(0.12))
                    .position(
                        x: geo.size.width * icon.x,
                        y: geo.size.height * icon.y + (floatPhase ? -5 : 5)
                    )
                    .rotationEffect(.degrees(floatPhase ? 5 : -5))
            }
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Back button and title row
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(.subheadline, weight: .semibold))
                        Text(String(localized: "Back"))
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    }
                    .foregroundColor(AppColors.primaryAccent)
                }
                
                Spacer()
            }
            
            // Title
            VStack(spacing: 6) {
                Text(String(localized: "Choose Location"))
                    .font(.system(.title, design: .rounded).weight(.black))
                    .foregroundColor(.primary)

                Text(String(localized: "Select a room to start your drill"))
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Carousel Section
    
    private var carouselSection: some View {
        GeometryReader { geo in
            let totalWidth = CGFloat(rooms.count) * (cardWidth + cardSpacing)
            let screenWidth = geo.size.width
            let offset = CGFloat(selectedCardIndex) * -(cardWidth + cardSpacing) + (screenWidth - cardWidth) / 2
            
            HStack(spacing: cardSpacing) {
                ForEach(Array(rooms.enumerated()), id: \.element.id) { index, room in
                    RoomCard(
                        room: room,
                        isSelected: selectedCardIndex == index,
                        isUnlocked: roomUnlockManager.isUnlocked(room.type),
                        timesPlayed: roomUnlockManager.getPlayCount(for: room.type),
                        bestScore: roomUnlockManager.getBestScore(for: room.type),
                        onSelect: {
                            selectRoom(at: index)
                        }
                    )
                    .frame(width: cardWidth)
                    .scaleEffect(scaleForCard(at: index, in: geo.size.width))
                    .opacity(opacityForCard(at: index))
                    .offset(y: selectedCardIndex == index ? -10 : 0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.75), value: selectedCardIndex)
                }
            }
            .frame(width: totalWidth)
            .offset(x: offset)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: selectedCardIndex)
            .gesture(
                DragGesture()
                    .onEnded { value in
                        let threshold: CGFloat = 50
                        if value.translation.width < -threshold && selectedCardIndex < rooms.count - 1 {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                selectedCardIndex += 1
                            }
                        } else if value.translation.width > threshold && selectedCardIndex > 0 {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                selectedCardIndex -= 1
                            }
                        }
                    }
            )
        }
        .frame(height: 420)
    }
    
    // MARK: - Page Indicator
    
    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<rooms.count, id: \.self) { index in
                Capsule()
                    .fill(selectedCardIndex == index ? rooms[index].accentColor : Color.black.opacity(0.2))
                    .frame(width: selectedCardIndex == index ? 24 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: selectedCardIndex)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func selectRoom(at index: Int) {
        guard roomUnlockManager.isUnlocked(rooms[index].type) else { return }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            selectedCardIndex = index
        }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Notify callback after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onRoomSelected(rooms[index].type)
        }
    }
    
    private func scaleForCard(at index: Int, in screenWidth: CGFloat) -> CGFloat {
        let distance = abs(index - selectedCardIndex)
        switch distance {
        case 0: return 1.0
        case 1: return 0.9
        default: return 0.8
        }
    }
    
    private func opacityForCard(at index: Int) -> Double {
        let distance = abs(index - selectedCardIndex)
        switch distance {
        case 0: return 1.0
        case 1: return 0.7
        default: return 0.5
        }
    }
}

// MARK: - Room Card

struct RoomCard: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let room: RoomInfo
    let isSelected: Bool
    let isUnlocked: Bool
    var timesPlayed: Int = 0
    var bestScore: Int? = nil
    let onSelect: () -> Void

    @State private var floatPhase = false
    @State private var bounce = false

    private var unlockRequirement: String {
        switch room.type {
        case .office: return String(localized: "Play 3 games in\nLiving Room or Kitchen")
        case .bedroom: return String(localized: "Play 5 total games\nacross all rooms")
        default: return String(localized: "Complete previous room\nto unlock")
        }
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 0) {
                // Card header with icon
                headerSection
                
                // Room preview illustration
                previewSection
                    .frame(height: 100)
                    .background(room.accentColor.opacity(0.08))
                
                // Content
                contentSection
                    .padding(16)
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
                    .shadow(
                        color: isSelected ? room.accentColor.opacity(0.3) : Color.black.opacity(0.1),
                        radius: isSelected ? 20 : 12,
                        x: 0,
                        y: isSelected ? 8 : 4
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        isSelected ? room.accentColor.opacity(0.6) : Color.clear,
                        lineWidth: 3
                    )
            )
            .overlay(
                // Locked overlay
                lockedOverlay
                    .opacity(isUnlocked ? 0 : 1)
            )
        }
        .buttonStyle(RoomCardButtonStyle())
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                floatPhase = true
            }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                bounce = true
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            // Room icon
            ZStack {
                Circle()
                    .fill(room.accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: room.iconName)
                    .font(.system(.title3, weight: .semibold))
                    .foregroundColor(room.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(room.name)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(.primary)
                
                // Difficulty stars
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= room.difficulty ? "star.fill" : "star")
                            .font(.system(.caption2))
                            .foregroundColor(star <= room.difficulty ? AppColors.warning : Color.gray.opacity(0.3))
                    }
                }
            }
            
            Spacer()
            
            // Selected indicator
            if isSelected && isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(.title2))
                    .foregroundColor(room.accentColor)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
    
    // MARK: - Preview Section
    
    private var previewSection: some View {
        ZStack {
            // Background gradient
            RadialGradient(
                colors: [
                    room.accentColor.opacity(0.15),
                    room.accentColor.opacity(0.05)
                ],
                center: .center,
                startRadius: 20,
                endRadius: 100
            )
            
            // Floating hazard icons
            previewHazardIcons
            
            // Player sprite
            if isUnlocked {
                SpriteBridge.image(named: room.previewSprites[1])
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 70, height: 70)
                    .offset(y: bounce ? -4 : 4)
                    .shadow(color: .black.opacity(0.15), radius: 6, y: 4)
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(.title, weight: .bold))
                    .foregroundColor(Color.gray.opacity(0.4))
            }
        }
    }
    
    private var previewHazardIcons: some View {
        ZStack {
            // Position hazard icons around the player
            ForEach(Array(room.keyHazards.enumerated()), id: \.offset) { index, hazard in
                let angle = Double(index) * 120.0 - 60.0
                let rad = angle * .pi / 180
                let distance: CGFloat = 50
                
                hazardIcon(for: hazard)
                    .offset(
                        x: cos(rad) * distance,
                        y: sin(rad) * distance + (floatPhase ? -3 : 3)
                    )
                    .opacity(0.6)
            }
        }
    }
    
    private func hazardIcon(for hazard: String) -> some View {
        let iconName: String
        if hazard.contains("Bookshelf") || hazard.contains("Wardrobe") || hazard.contains("Cabinet") {
            iconName = "cabinet.fill"
        } else if hazard.contains("Glass") || hazard.contains("Mirror") {
            iconName = "square.split.2x1"
        } else if hazard.contains("Lamp") || hazard.contains("Light") {
            iconName = "lamp.ceiling.fill"
        } else if hazard.contains("Gas") || hazard.contains("Stove") {
            iconName = "flame.fill"
        } else if hazard.contains("Pot") || hazard.contains("Pan") {
            iconName = "frying.pan"
        } else if hazard.contains("Monitor") || hazard.contains("Screen") {
            iconName = "display"
        } else if hazard.contains("Chair") {
            iconName = "chair.lounge.fill"
        } else if hazard.contains("Refrigerator") {
            iconName = "refrigerator.fill"
        } else {
            iconName = "exclamationmark.triangle.fill"
        }
        
        return ZStack {
            Circle()
                .fill(AppColors.wrongAction.opacity(0.15))
                .frame(width: 28, height: 28)
            
            Image(systemName: iconName)
                .font(.system(.caption2, weight: .semibold))
                .foregroundColor(AppColors.wrongAction)
        }
    }
    
    // MARK: - Content Section
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Key hazards
            VStack(alignment: .leading, spacing: 6) {
                Text(String(localized: "KEY HAZARDS"))
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundColor(.secondary)
                    .tracking(1)
                
                FlowLayout(spacing: 6) {
                    ForEach(room.keyHazards, id: \.self) { hazard in
                        HazardTag(text: hazard, color: AppColors.wrongAction)
                    }
                }
            }
            
            Divider()
                .padding(.vertical, 4)
            
            // Safety tip
            HStack(spacing: 8) {
                Image(systemName: "shield.fill")
                    .font(.caption)
                    .foregroundColor(AppColors.correctAction)
                
                Text(room.safetyTip)
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            
            // Strategy hint
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.caption)
                    .foregroundColor(AppColors.warning)
                
                Text(room.strategyHint)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            // Stats row
            HStack(spacing: horizontalSizeClass == .compact ? 12 : 16) {
                StatBadge(
                    icon: "play.fill",
                    value: "\(timesPlayed)",
                    label: String(localized: "Plays")
                )

                if let bestScore = bestScore {
                    StatBadge(
                        icon: "star.fill",
                        value: "\(bestScore)",
                        label: String(localized: "Best")
                    )
                }

                Spacer(minLength: 8)

                // Select button
                Text(isUnlocked ? String(localized: "SELECT") : String(localized: "LOCKED"))
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundColor(isUnlocked ? .white : .secondary)
                    .padding(.horizontal, horizontalSizeClass == .compact ? 10 : 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(isUnlocked ? room.accentColor : Color.gray.opacity(0.2))
                    )
            }
            .padding(.top, 4)
        }
    }
    
    // MARK: - Locked Overlay
    
    private var lockedOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.7))
            
            VStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(.title, weight: .bold))
                    .foregroundColor(.gray)

                Text(unlockRequirement)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Hazard Tag

struct HazardTag: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.system(.caption2, design: .rounded).weight(.medium))
            .foregroundColor(color.opacity(0.9))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(color.opacity(0.12))
            )
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(.caption2))
                .foregroundColor(.secondary)

            Text(value)
                .font(.system(.caption2, design: .rounded).weight(.bold))
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// MARK: - Room Card Button Style

struct RoomCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    RoomSelectionView(
        selectedRoom: .constant(.livingRoom),
        onRoomSelected: { roomType in
            print("Selected room: \(roomType)")
        },
        onBack: {
            print("Back pressed")
        }
    )
}
