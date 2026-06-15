import SwiftUI

struct AnimatedBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if reduceMotion || SettingsManager.shared.isReducedMotionEnabled {
            staticBackground
        } else {
            animatedContent
        }
    }

    private var staticBackground: some View {
        LinearGradient(
            colors: [Color(hex: 0xF2F2F7), Color(hex: 0xE8E8ED), Color(hex: 0xF2F2F7)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var animatedContent: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                // Light gradient base
                let gradient = Gradient(colors: [
                    Color(hex: 0xF2F2F7),
                    Color(hex: 0xE8E8ED),
                    Color(hex: 0xF2F2F7)
                ])
                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .linearGradient(
                        gradient,
                        startPoint: .zero,
                        endPoint: CGPoint(x: 0, y: size.height)
                    )
                )

                // Destroyed buildings background texture (very subtle)
                if let resolved = context.resolveSymbol(id: "buildings") {
                    context.draw(resolved, at: CGPoint(x: size.width / 2, y: size.height * 0.65))
                }

                // Seismic wave lines (blue, slightly higher opacity for light bg)
                drawSeismicWave(
                    context: context, size: size, time: time,
                    yOffset: size.height * 0.35, amplitude: 8, frequency: 2.0,
                    speed: 0.4, opacity: 0.12, lineWidth: 1.5
                )
                drawSeismicWave(
                    context: context, size: size, time: time,
                    yOffset: size.height * 0.55, amplitude: 12, frequency: 1.5,
                    speed: -0.3, opacity: 0.09, lineWidth: 2.0
                )
                drawSeismicWave(
                    context: context, size: size, time: time,
                    yOffset: size.height * 0.75, amplitude: 6, frequency: 2.5,
                    speed: 0.5, opacity: 0.07, lineWidth: 1.0
                )

                // Floating particle dots (soft blue/gray)
                drawParticles(context: context, size: size, time: time)
            } symbols: {
                destroyedBuildingsSymbol
                    .tag("buildings")
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Helpers

    // Destroyed buildings image as a Canvas symbol
    private var destroyedBuildingsSymbol: some View {
        Image("destroyed_buildings")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: 500, maxHeight: 200)
            .opacity(0.06)
    }

    private func drawSeismicWave(
        context: GraphicsContext, size: CGSize, time: Double,
        yOffset: CGFloat, amplitude: CGFloat, frequency: CGFloat,
        speed: CGFloat, opacity: Double, lineWidth: CGFloat
    ) {
        var path = Path()
        let step: CGFloat = 4
        let phase = time * Double(speed)

        for x in stride(from: 0, through: size.width, by: step) {
            let relativeX = x / size.width
            let y = yOffset + sin((relativeX * CGFloat(frequency) * .pi * 2) + CGFloat(phase) * .pi * 2) * amplitude
            if x == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        context.stroke(
            path,
            with: .color(Color(hex: 0x007AFF).opacity(opacity)),
            lineWidth: lineWidth
        )
    }

    private func drawParticles(context: GraphicsContext, size: CGSize, time: Double) {
        // Deterministic particles using index-based seeding
        let particleCount = 15
        for i in 0..<particleCount {
            let seed = Double(i)
            let baseX = fmod(seed * 137.508, 1.0) * Double(size.width) // golden angle distribution
            let speed = 12.0 + fmod(seed * 41.3, 20.0) // 12-32 pts/sec upward
            let particleSize = 2.0 + fmod(seed * 23.7, 3.0) // 2-5 pts
            let baseOpacity = 0.08 + fmod(seed * 17.1, 0.15) // 0.08-0.23

            // Cycle period based on speed — particle resets when it passes top
            let cycleDuration = Double(size.height + 40) / speed
            let progress = fmod(time + seed * 7.3, cycleDuration) / cycleDuration

            // Y goes from bottom+20 to top-20
            let y = Double(size.height + 20) - progress * Double(size.height + 40)

            // Subtle horizontal drift
            let x = baseX + sin(time * 0.3 + seed * 2.1) * 8

            // Fade in/out near edges
            let fadeIn = min(progress * 5, 1.0)
            let fadeOut = min((1 - progress) * 5, 1.0)
            let opacity = baseOpacity * fadeIn * fadeOut

            let rect = CGRect(
                x: x - particleSize / 2,
                y: y - particleSize / 2,
                width: particleSize,
                height: particleSize
            )
            // Soft blue/gray particles instead of white
            context.fill(
                Path(ellipseIn: rect),
                with: .color(Color(hex: 0x007AFF).opacity(opacity))
            )
        }
    }
}
