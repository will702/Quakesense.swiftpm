import SwiftUI

// MARK: - Size Class Constants

/// Adaptive constants that change based on horizontal size class
struct SizeClassConstants {
    // MARK: - Card Dimensions

    static func cardWidth(for horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        horizontalSizeClass == .compact ? 280 : 320
    }

    static func cardSpacing(for horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        horizontalSizeClass == .compact ? 16 : 20
    }

    // MARK: - Hero Section

    static func heroHeight(for verticalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        verticalSizeClass == .compact ? 140 : 200
    }

    static func heroHeight(for size: CGSize) -> CGFloat {
        min(size.width, size.height) < 500 ? 140 : 200
    }

    // MARK: - Scenario Cards

    static func scenarioCardWidth(for horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        horizontalSizeClass == .compact ? 80 : 90
    }

    // MARK: - Carousel

    static func carouselHeight(for verticalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        verticalSizeClass == .compact ? 360 : 420
    }

    static func carouselHeight(for size: CGSize) -> CGFloat {
        size.height < 600 ? 360 : 420
    }

    // MARK: - Illustrations

    static func illustrationSize(for horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        horizontalSizeClass == .compact ? 200 : 240
    }

    static func smallIllustrationSize(for horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        horizontalSizeClass == .compact ? 100 : 120
    }

    // MARK: - Badges

    static func badgeSize(for horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        horizontalSizeClass == .compact ? 80 : 96
    }

    // MARK: - Padding

    static func sectionPadding(for horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        horizontalSizeClass == .compact ? 16 : 24
    }

    static func contentSpacing(for horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        horizontalSizeClass == .compact ? 12 : 20
    }

    // MARK: - Grid Columns

    static func statGridColumns(for horizontalSizeClass: UserInterfaceSizeClass?) -> [GridItem] {
        if horizontalSizeClass == .compact {
            return [
                GridItem(.flexible()),
                GridItem(.flexible())
            ]
        } else {
            return [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ]
        }
    }

    static func adaptiveStatColumns(minWidth: CGFloat = 80) -> [GridItem] {
        [GridItem(.adaptive(minimum: minWidth, maximum: 120))]
    }
}

// MARK: - View Modifiers

/// Modifier that applies different padding based on size class
struct AdaptivePadding: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let compact: CGFloat
    let regular: CGFloat

    func body(content: Content) -> some View {
        content.padding(horizontalSizeClass == .compact ? compact : regular)
    }
}

/// Modifier that applies different frame height based on vertical size class
struct AdaptiveHeight: ViewModifier {
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    let compact: CGFloat
    let regular: CGFloat

    func body(content: Content) -> some View {
        content.frame(height: verticalSizeClass == .compact ? compact : regular)
    }
}

// MARK: - View Extensions

extension View {
    /// Applies padding that adapts to the horizontal size class
    func adaptivePadding(compact: CGFloat = 16, regular: CGFloat = 24) -> some View {
        modifier(AdaptivePadding(compact: compact, regular: regular))
    }

    /// Applies frame height that adapts to the vertical size class
    func adaptiveHeight(compact: CGFloat, regular: CGFloat) -> some View {
        modifier(AdaptiveHeight(compact: compact, regular: regular))
    }

    /// Adapts a view based on horizontal size class
    func adaptive<Compact: View, Regular: View>(
        @ViewBuilder compact: () -> Compact,
        @ViewBuilder regular: () -> Regular
    ) -> some View {
        self.modifier(AdaptiveViewModifier(
            compact: compact(),
            regular: regular()
        ))
    }
}

// MARK: - Adaptive View Modifier

struct AdaptiveViewModifier<Compact: View, Regular: View>: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let compact: Compact
    let regular: Regular

    func body(content: Content) -> some View {
        Group {
            if horizontalSizeClass == .compact {
                compact
            } else {
                regular
            }
        }
    }
}

// MARK: - Device Type Detection

enum DeviceType {
    case iPhone
    case iPad
    case iPadCompact // iPad in Split View or Slide Over

    @MainActor
    static var current: DeviceType {
        #if os(iOS)
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        let isCompact = UIScreen.main.traitCollection.horizontalSizeClass == .compact

        if isIPad && isCompact {
            return .iPadCompact
        } else if isIPad {
            return .iPad
        } else {
            return .iPhone
        }
        #else
        return .iPhone
        #endif
    }

    var isCompact: Bool {
        self == .iPhone || self == .iPadCompact
    }
}

// MARK: - Scene Size Calculator

/// Calculates appropriate scene size based on available view size
struct SceneSizeCalculator {
    /// The base aspect ratio we design for (4:3 for iPad)
    static let targetAspectRatio: CGFloat = 4.0 / 3.0

    /// Minimum scene dimensions
    static let minSize = CGSize(width: 568, height: 320) // iPhone SE landscape

    /// Maximum scene dimensions
    static let maxSize = CGSize(width: 1366, height: 1024) // iPad Pro 12.9"

    /// Calculates optimal scene size that maintains aspect ratio
    static func calculate(for availableSize: CGSize) -> CGSize {
        // Ensure minimum size
        let width = max(availableSize.width, minSize.width)
        let height = max(availableSize.height, minSize.height)

        // Calculate scene size maintaining aspect ratio
        let availableAspect = width / height

        var sceneWidth: CGFloat
        var sceneHeight: CGFloat

        if availableAspect > targetAspectRatio {
            // View is wider than target - height is the constraint
            sceneHeight = min(height, maxSize.height)
            sceneWidth = sceneHeight * targetAspectRatio
        } else {
            // View is taller than target - width is the constraint
            sceneWidth = min(width, maxSize.width)
            sceneHeight = sceneWidth / targetAspectRatio
        }

        return CGSize(width: sceneWidth, height: sceneHeight)
    }

    /// Scale factor for game elements based on scene size
    static func scaleFactor(for sceneSize: CGSize) -> CGFloat {
        let baseWidth: CGFloat = 1024 // Original design width
        return sceneSize.width / baseWidth
    }
}

// MARK: - Responsive Font Sizes

struct ResponsiveFont {
    static func size(for horizontalSizeClass: UserInterfaceSizeClass?, base: CGFloat) -> CGFloat {
        let multiplier = horizontalSizeClass == .compact ? 0.9 : 1.0
        return base * multiplier
    }

    static func largeTitle(for horizontalSizeClass: UserInterfaceSizeClass?) -> Font {
        .system(size: size(for: horizontalSizeClass, base: 34), weight: .bold, design: .rounded)
    }

    static func title(for horizontalSizeClass: UserInterfaceSizeClass?) -> Font {
        .system(size: size(for: horizontalSizeClass, base: 28), weight: .bold, design: .rounded)
    }

    static func title2(for horizontalSizeClass: UserInterfaceSizeClass?) -> Font {
        .system(size: size(for: horizontalSizeClass, base: 22), weight: .bold, design: .rounded)
    }

    static func title3(for horizontalSizeClass: UserInterfaceSizeClass?) -> Font {
        .system(size: size(for: horizontalSizeClass, base: 20), weight: .semibold, design: .rounded)
    }

    static func headline(for horizontalSizeClass: UserInterfaceSizeClass?) -> Font {
        .system(size: size(for: horizontalSizeClass, base: 17), weight: .semibold, design: .rounded)
    }

    static func body(for horizontalSizeClass: UserInterfaceSizeClass?) -> Font {
        .system(size: size(for: horizontalSizeClass, base: 17), design: .rounded)
    }

    static func caption(for horizontalSizeClass: UserInterfaceSizeClass?) -> Font {
        .system(size: size(for: horizontalSizeClass, base: 12), design: .rounded)
    }
}
