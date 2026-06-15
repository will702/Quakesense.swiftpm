import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var onboarding = OnboardingManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var showResetConfirmation = false
    @State private var showResetSuccess = false

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Audio Section
                Section {
                    VolumeSliderRow(
                        title: String(localized: "Ambient"),
                        icon: "wind",
                        value: $settings.ambientVolume,
                        color: .blue
                    )

                    VolumeSliderRow(
                        title: String(localized: "Sound Effects"),
                        icon: "speaker.wave.2.fill",
                        value: $settings.sfxVolume,
                        color: .orange
                    )

                    VolumeSliderRow(
                        title: String(localized: "UI Sounds"),
                        icon: "bell.fill",
                        value: $settings.uiVolume,
                        color: .green
                    )
                } header: {
                    Label(String(localized: "Audio"), systemImage: "speaker.wave.3.fill")
                        .font(.headline)
                } footer: {
                    Text(String(localized: "Adjust volume levels for different audio types"))
                        .font(.caption)
                }

                // MARK: - Haptics Section
                Section {
                    Toggle(isOn: $settings.hapticEnabled) {
                        Label(String(localized: "Enable Haptics"), systemImage: "hand.tap.fill")
                    }
                    .tint(AppColors.primaryAccent)

                    if settings.hapticEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label(String(localized: "Intensity"), systemImage: "waveform")
                                Spacer()
                                Text("\(Int(settings.hapticIntensity * 100))%")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .monospacedDigit()
                            }

                            Slider(
                                value: $settings.hapticIntensity,
                                in: 0.1...1.0,
                                step: 0.1
                            ) {
                                Text(String(localized: "Haptic Intensity"))
                            } minimumValueLabel: {
                                Image(systemName: "waveform.path.ecg")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } maximumValueLabel: {
                                Image(systemName: "waveform.path.ecg")
                                    .font(.title3)
                                    .foregroundColor(AppColors.primaryAccent)
                            }
                            .tint(AppColors.primaryAccent)
                            .disabled(!settings.hapticEnabled)
                        }

                        // Test haptic button
                        Button(action: testHaptic) {
                            HStack {
                                Image(systemName: "iphone.radiowaves.left.and.right")
                                Text(String(localized: "Test Haptic Feedback"))
                            }
                            .foregroundColor(AppColors.primaryAccent)
                        }
                        .disabled(!settings.hapticEnabled)
                    }
                } header: {
                    Label(String(localized: "Haptics"), systemImage: "iphone.radiowaves.left.and.right")
                        .font(.headline)
                }

                // MARK: - Controls Section
                Section {
                    Toggle(isOn: $settings.tiltControlEnabled) {
                        Label(String(localized: "Tilt Control"), systemImage: "gyroscope")
                    }
                    .tint(AppColors.primaryAccent)
                    .disabled(!MotionManager.shared.isAvailable)

                    if !MotionManager.shared.isAvailable {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.secondary)
                            Text(String(localized: "Accelerometer not available on this device"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Label(String(localized: "Controls"), systemImage: "gamecontroller.fill")
                        .font(.headline)
                } footer: {
                    Text(String(localized: "Tilt your device to move during the aftershock phase. Touch controls always remain available."))
                        .font(.caption)
                }

                // MARK: - Accessibility Section
                Section {
                    Toggle(isOn: $settings.reducedMotion) {
                        Label(String(localized: "Reduce Motion"), systemImage: "figure.walk.motion")
                    }
                    .tint(AppColors.primaryAccent)

                    if UIAccessibility.isReduceMotionEnabled {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(String(localized: "System Reduce Motion is enabled"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    if UIAccessibility.isDarkerSystemColorsEnabled {
                        HStack {
                            Image(systemName: "circle.lefthalf.filled")
                                .foregroundColor(.blue)
                            Text(String(localized: "High Contrast mode active — enhanced visibility"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Label(String(localized: "Accessibility"), systemImage: "accessibility")
                        .font(.headline)
                } footer: {
                    Text(String(localized: "Reduce motion replaces screen shake with color pulsing. Enable 'Increase Contrast' in iOS Settings > Accessibility > Display for enhanced game visibility."))
                        .font(.caption)
                }

                // MARK: - Tutorial Section
                Section {
                    Button(action: replayTutorial) {
                        HStack {
                            Label(String(localized: "Replay Tutorial"), systemImage: "play.circle.fill")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Label(String(localized: "Help"), systemImage: "questionmark.circle.fill")
                        .font(.headline)
                }

                // MARK: - Reset Section
                Section {
                    Button(action: { showResetConfirmation = true }) {
                        Label(String(localized: "Reset All Progress"), systemImage: "arrow.counterclockwise.circle.fill")
                            .foregroundColor(.red)
                    }

                    Button(action: resetSettings) {
                        Label(String(localized: "Reset Settings to Default"), systemImage: "gear.circle.fill")
                            .foregroundColor(.orange)
                    }
                } header: {
                    Label(String(localized: "Reset"), systemImage: "exclamationmark.triangle.fill")
                        .font(.headline)
                } footer: {
                    Text("Resetting progress will clear all unlocked rooms, achievements, and statistics. This cannot be undone.")
                        .font(.caption)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(.body, design: .rounded).weight(.semibold))
                }
            }
            .alert("Reset All Progress?", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    performFullReset()
                }
            } message: {
                Text("This will permanently delete all unlocked rooms, achievements, and game statistics. This action cannot be undone.")
            }
            .overlay(
                Group {
                    if showResetSuccess {
                        ResetSuccessToast()
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            )
        }
        .onAppear {
            settings.applyAudioSettings()
            settings.applyHapticSettings()
        }
    }

    // MARK: - Actions

    private func testHaptic() {
        HapticManager.shared.playImpact()
    }

    private func replayTutorial() {
        onboarding.resetOnboarding()
        dismiss()

        // Show onboarding after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // The onboarding will show automatically when ContentView detects incomplete onboarding
        }
    }

    private func resetSettings() {
        settings.resetToDefaults()
        settings.applyAudioSettings()
        settings.applyHapticSettings()

        showResetToast()
    }

    private func performFullReset() {
        settings.resetAllProgress()

        showResetToast()
    }

    private func showResetToast() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showResetSuccess = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeOut(duration: 0.3)) {
                showResetSuccess = false
            }
        }
    }
}

// MARK: - Volume Slider Row

struct VolumeSliderRow: View {
    let title: String
    let icon: String
    @Binding var value: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(title, systemImage: icon)
                Spacer()
                Text("\(Int(value * 100))%")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }

            Slider(
                value: $value,
                in: 0...1,
                step: 0.05
            ) {
                Text("\(title) Volume")
            } minimumValueLabel: {
                Image(systemName: "speaker.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } maximumValueLabel: {
                Image(systemName: "speaker.wave.3.fill")
                    .font(.caption)
                    .foregroundColor(color)
            }
            .tint(color)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Reset Success Toast

struct ResetSuccessToast: View {
    var body: some View {
        VStack {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(.title2))
                    .foregroundColor(AppColors.correctAction)

                Text("Reset Complete")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.correctAction.opacity(0.4), lineWidth: 2)
            )
            .padding(.horizontal, 20)
            .padding(.top, 16)

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
