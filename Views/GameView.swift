import SwiftUI
import SpriteKit

struct GameView: View {
    let magnitude: Double
    let scenarioType: ScenarioType
    let onFinish: (EnhancedDebriefReport) -> Void

    @StateObject private var decisionEngine: DecisionEngine
    @State private var scene: QuakeScene?
    @State private var coordinator: GameViewCoordinator?
    @State private var availableSize: CGSize = .zero

    init(magnitude: Double, scenarioType: ScenarioType = .standard, onFinish: @escaping (EnhancedDebriefReport) -> Void) {
        self.magnitude = magnitude
        self.scenarioType = scenarioType
        self.onFinish = onFinish
        let scenario = QuakeScenario(magnitude: magnitude, roomType: "livingRoom", scenarioType: scenarioType)
        _decisionEngine = StateObject(wrappedValue: DecisionEngine(scenario: scenario))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(red: 0xFA/255, green: 0xF8/255, blue: 0xF5/255)
                    .ignoresSafeArea()

                if let scene = scene {
                    SpriteView(scene: scene)
                        .ignoresSafeArea()
                        .transition(.opacity)
                } else {
                    ProgressView("Preparing room...")
                        .foregroundColor(.secondary)
                }
            }
            .onAppear {
                // Store available size for scene setup
                availableSize = geo.size
                // Defer scene setup to next run loop so the loading UI shows first
                DispatchQueue.main.async {
                    setupScene(size: geo.size)
                }
            }
            .onChange(of: geo.size) { newSize in
                // Handle size changes (e.g., rotation, multitasking)
                if availableSize != newSize {
                    availableSize = newSize
                    updateSceneSize(newSize)
                }
            }
            .onDisappear {
                scene?.removeAllActions()
                scene?.removeAllChildren()
                AudioManager.shared.stopAll()
                HapticManager.shared.stopAll()
            }
        }
    }

    private func setupScene(size: CGSize) {
        let scenario = QuakeScenario(magnitude: magnitude, roomType: "livingRoom", scenarioType: scenarioType)
        let newScene = QuakeScene(scenario: scenario, decisionEngine: decisionEngine, size: size)
        let coord = GameViewCoordinator(onFinish: onFinish)
        newScene.quakeDelegate = coord
        self.coordinator = coord
        self.scene = newScene
    }

    private func updateSceneSize(_ newSize: CGSize) {
        guard let scene = scene else { return }

        // Calculate new scene size maintaining aspect ratio
        let newSceneSize = RoomLayout.dynamicSceneSize(for: newSize)

        // Update scene size
        scene.size = newSceneSize

        // Notify scene that size changed (for repositioning elements)
        scene.handleSizeChange(newSize: newSceneSize)
    }
}

// MARK: - Coordinator

@MainActor
final class GameViewCoordinator: QuakeSceneDelegate {
    let onFinish: (EnhancedDebriefReport) -> Void

    init(onFinish: @escaping (EnhancedDebriefReport) -> Void) {
        self.onFinish = onFinish
    }

    nonisolated func quakeSceneDidFinish(report: EnhancedDebriefReport) {
        Task { @MainActor in
            self.onFinish(report)
        }
    }
}
