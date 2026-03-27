import SwiftUI

struct HomeView: View {
    var appState: AppState
    var coordinator: RecordingCoordinator

    @State private var totalWords = 0
    @State private var appsUsed = 0
    @State private var averageWPM = 0
    @State private var timeSaved = 0
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: WaveTheme.spacingXL) {
                statsBar
                quickActions
                whatsNew
            }
            .padding(WaveTheme.spacingXL)
        }
        .onAppear {
            loadStats()
        }
    }

    // MARK: - Stats Bar

    private var statsBar: some View {
        HStack(spacing: 0) {
            StatItem(value: "\(averageWPM) WPM", label: "Average speed")
            Divider().frame(height: 30)
            StatItem(value: "\(totalWords)", label: "Words this week")
            Divider().frame(height: 30)
            StatItem(value: "\(appsUsed)", label: "Apps used")
            Divider().frame(height: 30)
            StatItem(value: "\(timeSaved) minutes", label: "Saved this week")
        }
        .cardStyle()
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: WaveTheme.spacingMD) {
            Text("Get started")
                .sectionHeader()

            VStack(spacing: 2) {
                QuickActionRow(
                    icon: "record.circle",
                    title: "Start recording",
                    subtitle: "Turn your voice to text with a single click.",
                    shortcut: "⌘⇧ Space"
                )

                QuickActionRow(
                    icon: "keyboard",
                    title: "Customize your shortcuts",
                    subtitle: "Change the keyboard shortcuts for Wave.",
                    shortcut: nil
                )

                QuickActionRow(
                    icon: "slider.horizontal.3",
                    title: "Choose a rewrite level",
                    subtitle: "Set how aggressively Wave cleans up your text.",
                    shortcut: nil
                )

                QuickActionRow(
                    icon: "book",
                    title: "Add vocabulary",
                    subtitle: "Teach Wave custom words, names, or industry terms.",
                    shortcut: nil
                )
            }
            .cardStyle()
        }
    }

    // MARK: - What's New

    private var whatsNew: some View {
        VStack(alignment: .leading, spacing: WaveTheme.spacingMD) {
            HStack {
                Text("What's new?")
                    .sectionHeader()
                Spacer()
                Button("View all changes") {}
                    .buttonStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundStyle(WaveTheme.accent)
            }

            VStack(alignment: .leading, spacing: WaveTheme.spacingSM) {
                HStack(alignment: .top) {
                    Text(formattedDate(Date()))
                        .font(.system(size: 12))
                        .foregroundStyle(WaveTheme.textTertiary)
                        .frame(width: 60, alignment: .leading)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Initial Release")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Voice-to-text with AI cleanup. Deepgram + Whisper for transcription, Claude + GPT for rewriting.")
                            .font(.system(size: 12))
                            .foregroundStyle(WaveTheme.textSecondary)
                        Button("Try it now") {}
                            .buttonStyle(.plain)
                            .font(.system(size: 12))
                            .foregroundStyle(WaveTheme.accent)
                            .padding(.top, 2)
                    }
                }
            }
            .cardStyle()
        }
    }

    // MARK: - Helpers

    private func loadStats() {
        let stats = (try? DatabaseManager.shared.fetchWeeklyStats()) ?? DatabaseManager.WeeklyStats()
        averageWPM = stats.averageWPM
        totalWords = stats.wordsThisWeek
        appsUsed = stats.uniqueApps
        timeSaved = stats.timeSavedMinutes
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let base = formatter.string(from: date)
        let day = Calendar.current.component(.day, from: date)
        let suffix: String
        switch day {
        case 1, 21, 31: suffix = "st"
        case 2, 22: suffix = "nd"
        case 3, 23: suffix = "rd"
        default: suffix = "th"
        }
        return "\(base)\(suffix)"
    }
}

// MARK: - Subviews

struct StatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(WaveTheme.textPrimary)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(WaveTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct QuickActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let shortcut: String?

    var body: some View {
        HStack(spacing: WaveTheme.spacingMD) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(WaveTheme.textSecondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(WaveTheme.textSecondary)
            }

            Spacer()

            if let shortcut {
                Text(shortcut)
                    .font(.system(size: 11, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(WaveTheme.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: WaveTheme.radiusInner))
            }
        }
        .padding(.vertical, WaveTheme.spacingSM)
    }
}
