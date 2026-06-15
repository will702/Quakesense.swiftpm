import CoreMotion

final class MotionManager: @unchecked Sendable {
    static let shared = MotionManager()

    private let motionManager = CMMotionManager()
    private(set) var currentTilt: CGFloat = 0

    #if DEBUG
    private var autoDriveTimer: Timer?
    #endif

    var isAvailable: Bool {
        motionManager.isAccelerometerAvailable
    }

    private init() {}

    @MainActor
    func startTiltUpdates() {
        #if DEBUG
        if MarketingCapture.isDriving {
            startSyntheticTilt()
            return
        }
        #endif
        guard isAvailable, !motionManager.isAccelerometerActive else { return }
        motionManager.accelerometerUpdateInterval = 1.0 / 60.0
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let data = data else { return }
            // In landscape, x-axis maps to left/right tilt
            self?.currentTilt = CGFloat(data.acceleration.x)
        }
    }

    @MainActor
    func stopTiltUpdates() {
        #if DEBUG
        autoDriveTimer?.invalidate()
        autoDriveTimer = nil
        #endif
        motionManager.stopAccelerometerUpdates()
        currentTilt = 0
    }

    #if DEBUG
    private func startSyntheticTilt() {
        let startTime = Date()
        autoDriveTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            let elapsed = Date().timeIntervalSince(startTime)
            self?.currentTilt = elapsed < 5.0 ? 0.35 : 0.0
        }
    }
    #endif
}
