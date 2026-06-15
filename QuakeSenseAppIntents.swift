import AppIntents

// MARK: - Start Earthquake Drill Intent (SSC: App Intents / Siri shortcut)

/// App Intent that opens QuakeSense for an earthquake drill. Exposed as an App Shortcut
/// so users can say "Start earthquake drill" or "Open QuakeSense" via Siri or the Shortcuts app.
struct StartEarthquakeDrillIntent: AppIntent {
    static let title: LocalizedStringResource = "Start earthquake drill"
    static let description = IntentDescription("Opens QuakeSense to practice earthquake survival.")

    func perform() async throws -> some IntentResult {
        // Opening the app is handled by the system when this shortcut is invoked.
        return .result()
    }
}

// MARK: - App Shortcuts Provider

/// Provides App Shortcuts so QuakeSense appears in Shortcuts, Spotlight, and Siri
/// without any user configuration (SSC: Apple platform integration).
struct QuakeSenseShortcuts: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartEarthquakeDrillIntent(),
            phrases: [
                "Start earthquake drill in \(.applicationName)",
                "Open \(.applicationName)",
                "Launch \(.applicationName)"
            ],
            shortTitle: "Start earthquake drill",
            systemImageName: "bolt.shield.fill"
        )
    }
}
