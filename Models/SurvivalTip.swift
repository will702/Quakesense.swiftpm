import Foundation

struct SurvivalTip: Identifiable, Sendable {
    let id = UUID()
    let icon: String
    let title: String
    let detail: String
    let phase: TipPhase
}

enum TipPhase: String, CaseIterable, Sendable {
    case before = "BEFORE an Earthquake"
    case during = "DURING an Earthquake"
    case after = "AFTER an Earthquake"
    case specialized = "Specialized Scenarios"

    var localizedName: String {
        switch self {
        case .before: return String(localized: "BEFORE an Earthquake")
        case .during: return String(localized: "DURING an Earthquake")
        case .after: return String(localized: "AFTER an Earthquake")
        case .specialized: return String(localized: "Specialized Scenarios")
        }
    }
}

extension SurvivalTip {
    static let allTips: [SurvivalTip] = [
        // BEFORE
        SurvivalTip(
            icon: "hammer.fill",
            title: String(localized: "Secure heavy furniture"),
            detail: String(
                localized:
                    "Bolt bookshelves, cabinets, and water heaters to wall studs. Use flexible fasteners for gas appliances. Unsecured furniture is the #1 cause of earthquake injuries indoors."
            ),
            phase: .before
        ),
        SurvivalTip(
            icon: "magnifyingglass",
            title: String(localized: "Identify safe spots"),
            detail: String(
                localized:
                    "In every room, identify sturdy tables or desks you can shelter under. Know where danger zones are — windows, heavy hanging objects, and tall furniture."
            ),
            phase: .before
        ),
        SurvivalTip(
            icon: "cross.case.fill",
            title: String(localized: "Prepare an emergency kit"),
            detail: String(
                localized:
                    "Keep water, flashlight, first aid kit, medications, and important documents ready. Include a whistle to signal for help if trapped."
            ),
            phase: .before
        ),
        SurvivalTip(
            icon: "figure.walk",
            title: String(localized: "Practice Drop, Cover, Hold On"),
            detail: String(
                localized:
                    "Regularly practice the earthquake safety position. DROP to hands and knees, take COVER under sturdy furniture, and HOLD ON until shaking stops. Muscle memory saves lives."
            ),
            phase: .before
        ),
        // NEW: Family communication plan
        SurvivalTip(
            icon: "person.2.fill",
            title: String(localized: "Create a family communication plan"),
            detail: String(
                localized:
                    "Designate an out-of-area contact person that everyone can call to check in. Know how to reach each other after a quake. Establish meeting places: home, neighborhood, and city landmark."
            ),
            phase: .before
        ),
        // NEW: Secure heavy wall items
        SurvivalTip(
            icon: "paintbrush.fill",
            title: String(localized: "Secure heavy items on walls"),
            detail: String(
                localized:
                    "Anchor TVs, mirrors, and artwork to wall studs. Use closed hooks for picture frames. Install flexible straps for water heaters. Falling wall items cause serious injuries."
            ),
            phase: .before
        ),
        // NEW: Identify escape routes
        SurvivalTip(
            icon: "arrow.turn.up.forward",
            title: String(localized: "Identify escape routes"),
            detail: String(
                localized:
                    "Know at least 2 ways to exit each room. Keep pathways clear of obstacles. Practice evacuation drills regularly so you can escape quickly in darkness or smoke."
            ),
            phase: .before
        ),

        // DURING
        SurvivalTip(
            icon: "arrow.down.to.line",
            title: String(localized: "DROP to your hands and knees"),
            detail: String(
                localized:
                    "Getting low prevents you from being knocked down. Crawling allows you to move to shelter while maintaining stability. This is the first and most critical step."
            ),
            phase: .during
        ),
        SurvivalTip(
            icon: "shield.fill",
            title: String(localized: "Take COVER under sturdy furniture"),
            detail: String(
                localized:
                    "Get under a strong desk or table. If there is no shelter nearby, get next to an interior wall and protect your head and neck with your arms."
            ),
            phase: .during
        ),
        SurvivalTip(
            icon: "hand.raised.fill",
            title: String(localized: "HOLD ON until shaking stops"),
            detail: String(
                localized:
                    "If you're under a table, hold on with one hand. Be prepared to move with it if it shifts. Stay in position until the shaking completely stops."
            ),
            phase: .during
        ),
        SurvivalTip(
            icon: "xmark.diamond.fill",
            title: String(localized: "Stay AWAY from windows"),
            detail: String(
                localized:
                    "Windows can shatter violently during earthquakes, sending glass fragments flying. Stay at least 10 feet away from windows, mirrors, and glass doors."
            ),
            phase: .during
        ),
        SurvivalTip(
            icon: "nosign",
            title: String(localized: "Do NOT run outside"),
            detail: String(
                localized:
                    "Most injuries occur when people try to run during shaking. Falling debris, broken glass, and collapsing facades outside are extremely dangerous."
            ),
            phase: .during
        ),
        SurvivalTip(
            icon: "door.left.hand.open",
            title: String(localized: "Doorway myth: NOT safer"),
            detail: String(
                localized:
                    "Modern buildings have doorways no stronger than other parts. This outdated advice comes from old adobe buildings. Under a sturdy table is always safer."
            ),
            phase: .during
        ),
        // NEW: Protect head and neck
        SurvivalTip(
            icon: "shield.fill",
            title: String(localized: "Protect your head and neck"),
            detail: String(
                localized:
                    "Use your arms to shield your head from falling objects. If in bed, stay there and protect your head with a pillow. Keep your head down until shaking stops."
            ),
            phase: .during
        ),
        // NEW: Stay away from glass and exterior walls
        SurvivalTip(
            icon: "xmark.circle.fill",
            title: String(localized: "Stay away from glass and exterior walls"),
            detail: String(
                localized:
                    "Windows can shatter and send glass flying. Exterior walls are more dangerous than interior ones. Stay in the center of the room if possible, away from all glass."
            ),
            phase: .during
        ),

        // AFTER
        SurvivalTip(
            icon: "stethoscope",
            title: String(localized: "Check for injuries"),
            detail: String(
                localized:
                    "Check yourself and others for injuries. Provide first aid where needed. Do not move seriously injured people unless they're in immediate danger."
            ),
            phase: .after
        ),
        SurvivalTip(
            icon: "flame.fill",
            title: String(localized: "Check for gas leaks"),
            detail: String(
                localized:
                    "If you smell gas or hear a hissing sound, open windows, leave the building, and call emergency services. Do not use matches, lighters, or electrical switches."
            ),
            phase: .after
        ),
        SurvivalTip(
            icon: "building.2.fill",
            title: String(localized: "Avoid damaged buildings"),
            detail: String(
                localized:
                    "Leave damaged buildings immediately. Do not re-enter until authorities confirm it's safe. Aftershocks can cause weakened structures to collapse."
            ),
            phase: .after
        ),
        SurvivalTip(
            icon: "waveform.path.ecg",
            title: String(localized: "Expect aftershocks"),
            detail: String(
                localized:
                    "Aftershocks can occur minutes, hours, or even days after the main earthquake. Some can be nearly as strong as the original quake. Stay alert and prepared."
            ),
            phase: .after
        ),
        SurvivalTip(
            icon: "figure.walk.departure",
            title: String(localized: "Move to an open area"),
            detail: String(
                localized:
                    "Once shaking stops, move to an open area away from buildings, power lines, and trees. This is the safest post-earthquake position."
            ),
            phase: .after
        ),
        SurvivalTip(
            icon: "arrow.up.arrow.down.square.fill",
            title: String(localized: "Do NOT use elevators"),
            detail: String(
                localized:
                    "Never use elevators after an earthquake. Power may fail, and the shaft or machinery may be damaged. Always use stairs."
            ),
            phase: .after
        ),
        // NEW: Check utilities for damage
        SurvivalTip(
            icon: "bolt.fill",
            title: String(localized: "Check utilities for damage"),
            detail: String(
                localized:
                    "Look for electrical system damage like sparks or broken wires. Check water and gas lines for leaks. Turn off utilities if you suspect damage. Don't use flames due to gas leak risk."
            ),
            phase: .after
        ),
        // NEW: Use text messages instead of calls
        SurvivalTip(
            icon: "message.fill",
            title: String(localized: "Use text messages instead of calls"),
            detail: String(
                localized:
                    "Phone lines are often overloaded after earthquakes. Text messages use less bandwidth. Keep texts short to save battery and help others communicate."
            ),
            phase: .after
        ),
        // NEW: Listen to emergency broadcasts
        SurvivalTip(
            icon: "radio",
            title: String(localized: "Listen to emergency broadcasts"),
            detail: String(
                localized:
                    "Use a battery-powered or hand-crank radio. Follow official instructions from authorities. Don't spread rumors - verify all information before sharing."
            ),
            phase: .after
        ),

        // SPECIALIZED SCENARIOS
        // If you're in a vehicle
        SurvivalTip(
            icon: "car.fill",
            title: String(localized: "If you're in a vehicle"),
            detail: String(
                localized:
                    "Pull over safely away from buildings, trees, and power lines. Stay inside the vehicle. Set the parking brake. Avoid bridges and overpasses - they can collapse during shaking."
            ),
            phase: .specialized
        ),
        // If you're outdoors
        SurvivalTip(
            icon: "figure.run",
            title: String(localized: "If you're outdoors"),
            detail: String(
                localized:
                    "Move to an open area away from buildings and trees. Watch for falling power lines. Stay there until shaking stops. Never enter damaged buildings after the quake."
            ),
            phase: .specialized
        ),
        // If you're near the coast
        SurvivalTip(
            icon: "water.waves.and.arrow.up",
            title: String(localized: "If you're near the coast"),
            detail: String(
                localized:
                    "Move to higher ground immediately! Earthquakes can cause tsunamis. Get at least 100 feet above sea level or 1 mile inland. Wait for official 'all clear' before returning."
            ),
            phase: .specialized
        ),
        // If you're in a crowded place
        SurvivalTip(
            icon: "person.3.fill",
            title: String(localized: "If you're in a crowded place"),
            detail: String(
                localized:
                    "Don't rush for exits. Drop, Cover, and Hold On where you are. After shaking stops, move calmly to exits. Watch for falling debris and stampeding crowds."
            ),
            phase: .specialized
        ),
        // If you're near the ocean
        SurvivalTip(
            icon: "beach.umbrella.fill",
            title: String(localized: "If you're at the beach"),
            detail: String(
                localized:
                    "A tsunami can arrive within minutes. Move inland immediately to higher ground. Don't wait for official warnings - if you feel strong shaking, go! Stay away until officials say it's safe."
            ),
            phase: .specialized
        ),
        // If you're in a stadium or theater
        SurvivalTip(
            icon: "theatermasks.fill",
            title: String(localized: "If you're in a stadium or theater"),
            detail: String(
                localized:
                    "Stay in your seat and drop to the floor. Protect your head and neck. After shaking stops, walk calmly to exits using stairs, not elevators. Watch for falling debris."
            ),
            phase: .specialized
        ),
    ]

    static func tips(for phase: TipPhase) -> [SurvivalTip] {
        allTips.filter { $0.phase == phase }
    }
}
