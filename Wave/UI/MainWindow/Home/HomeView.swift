import AppKit
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
            VStack(alignment: .leading, spacing: Wave.spacing.s24) {
                statsBar
                quickActions
                whatsNew
            }
            .padding(Wave.spacing.s24)
        }
        .onAppear {
            loadStats()
        }
    }

    // MARK: - Stats Bar

    private var statsBar: some View {
        HStack(spacing: 0) {
            statCell(value: "\(averageWPM) WPM", label: "AVERAGE SPEED")
            Divider()
                .frame(height: 36)
                .foregroundStyle(Wave.colors.border)
            statCell(value: "\(totalWords)", label: "WORDS THIS WEEK")
            Divider()
                .frame(height: 36)
                .foregroundStyle(Wave.colors.border)
            statCell(value: "\(appsUsed)", label: "APPS USED")
            Divider()
                .frame(height: 36)
                .foregroundStyle(Wave.colors.border)
            statCell(value: "\(timeSaved) min", label: "SAVED THIS WEEK")
        }
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: Wave.spacing.s4) {
            Text(value)
                .waveFont(Wave.font.displayLarge)
                .foregroundStyle(Wave.colors.textPrimary)
                .monospacedDigit()
            Text(label)
                .waveFont(Wave.font.caption)
                .foregroundStyle(Wave.colors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Wave.spacing.s16)
        .padding(.vertical, Wave.spacing.s12)
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: Wave.spacing.s12) {
            WaveSectionHeader("Get Started")

            WaveCard(style: .standard, padding: 0) {
                VStack(spacing: 0) {
                    WaveListItem(
                        title: "Start recording",
                        subtitle: "Turn your voice to text with a single click.",
                        leading: "record.circle"
                    ) {
                        Text("⌘⇧ Space")
                            .waveFont(Wave.font.micro)
                            .foregroundStyle(Wave.colors.textTertiary)
                            .padding(.horizontal, Wave.spacing.s8)
                            .padding(.vertical, Wave.spacing.s4)
                            .background(Wave.colors.surfaceSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: Wave.radius.r4))
                    }

                    Divider().foregroundStyle(Wave.colors.border)

                    WaveListItem(
                        title: "Customize your shortcuts",
                        subtitle: "Change the keyboard shortcuts for Wave.",
                        leading: "keyboard"
                    )

                    Divider().foregroundStyle(Wave.colors.border)

                    WaveListItem(
                        title: "Choose a rewrite level",
                        subtitle: "Set how aggressively Wave cleans up your text.",
                        leading: "slider.horizontal.3"
                    )

                    Divider().foregroundStyle(Wave.colors.border)

                    WaveListItem(
                        title: "Add vocabulary",
                        subtitle: "Teach Wave custom words, names, or industry terms.",
                        leading: "book"
                    )
                }
            }
        }
    }

    // MARK: - What's New

    private var whatsNew: some View {
        WaveCard(style: .hero) {
            VStack(alignment: .leading, spacing: Wave.spacing.s16) {
                WaveSectionHeader(
                    "What's New",
                    trailing: AnyView(
                        WaveButton("View all changes", kind: .ghost) {
                            NSWorkspace.shared.open(Self.releasesURL)
                        }
                    )
                )

                HStack(alignment: .top, spacing: Wave.spacing.s12) {
                    Text(Self.latestRelease.date)
                        .waveFont(Wave.font.captionLight)
                        .foregroundStyle(Wave.colors.textTertiary)
                        .frame(width: 60, alignment: .leading)

                    VStack(alignment: .leading, spacing: Wave.spacing.s4) {
                        Text(Self.latestReleaseTitle)
                            .waveFont(Wave.font.bodySemibold)
                            .foregroundStyle(Wave.colors.textPrimary)
                        Text(Self.latestRelease.summary)
                            .waveFont(Wave.font.body)
                            .foregroundStyle(Wave.colors.textSecondary)
                    }
                }
            }
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

    // MARK: - Release note

    /// What the What's New card shows. Written down rather than fetched: Wave
    /// makes no network calls of its own, and the card this replaces printed
    /// today's date beside a description of a stack the app no longer uses.
    /// Update it in the same commit that moves CFBundleShortVersionString.
    static let latestRelease = (
        date: "Sep 11",
        summary: "A rewrite level picked from the menu bar survives a relaunch now. This card used to print today's date beside a description of a stack Wave dropped in 0.7.0, so it says what shipped instead."
    )

    static var latestReleaseTitle: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        return "Version \(version)"
    }

    static let releasesURL = URL(string: "https://github.com/advegaf/wave/releases")!
}
