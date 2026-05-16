import KeyboardShortcuts
import SwiftUI

private enum PreferencesTab: String, CaseIterable, Identifiable {
    case soundFile
    case playback
    case history
    case shortcuts

    var id: String { rawValue }

    var title: String {
        switch self {
        case .soundFile: return "Sound File"
        case .playback: return "Playback"
        case .history: return "History"
        case .shortcuts: return "Shortcuts"
        }
    }

    var icon: String {
        switch self {
        case .soundFile: return "music.note"
        case .playback: return "play.circle"
        case .history: return "clock.arrow.circlepath"
        case .shortcuts: return "keyboard"
        }
    }
}

struct PreferencesView: View {
    @ObservedObject var model: AppModel
    @State private var selectedTab: PreferencesTab = .soundFile

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 24) {
                ForEach(PreferencesTab.allCases) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 16, weight: .medium))
                            Text(tab.title)
                                .font(.caption)
                        }
                        .foregroundStyle(selectedTab == tab ? Color.accentColor : Color.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 10)

            Divider()

            Group {
                switch selectedTab {
                case .soundFile:
                    soundFileTab
                case .playback:
                    playbackTab
                case .history:
                    historyTab
                case .shortcuts:
                    shortcutsTab
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding()
        }
    }

    private var soundFileTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Default sound")
                Spacer()
                Button("Choose...") {
                    model.setDefaultSoundFromPanel()
                }
            }

            if let url = model.defaultSoundURL {
                Text(url.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Text("Supported formats: \(SupportedAudioTypes.extensionsDescription)")
                .foregroundStyle(.secondary)

            Text("File associations are registered in the app bundle document types.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Toggle("Loop playback", isOn: $model.loopPlayback)
            Toggle("Auto-play default sound on launch", isOn: $model.autoPlayOnLaunch)
            Toggle("Auto-play files when opened from Finder", isOn: $model.autoPlayOnFileOpen)
            Toggle("Open at login", isOn: $model.openAtLogin)
        }
    }

    private var playbackTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Volume")
                Slider(value: $model.volume, in: 0...1)
                Text("\(Int(model.volume * 100))%")
                    .monospacedDigit()
                    .frame(width: 44, alignment: .trailing)
            }

            HStack {
                Text("Fade-in (s)")
                Slider(value: $model.fadeInDuration, in: 0...10, step: 1)
                Text(String(format: "%.1f", model.fadeInDuration))
                    .monospacedDigit()
                    .frame(width: 40, alignment: .trailing)
            }

            HStack {
                Text("Fade-out (s)")
                Slider(value: $model.fadeOutDuration, in: 0...10, step: 1)
                Text(String(format: "%.1f", model.fadeOutDuration))
                    .monospacedDigit()
                    .frame(width: 40, alignment: .trailing)
            }

            Text("Play/Pause behavior: resume current selection when available.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Stop behavior: stop and reset playback position to start.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Toggle("Stop playback when closing a floating window", isOn: $model.stopPlaybackOnWindowClose)

            Toggle("Keep floating player above other windows", isOn: $model.keepFloatingWindowOnTop)

            HStack {
                Text("Floating window opacity")
                Slider(value: $model.floatingOpacity, in: 0.35...1.0)
                Text("\(Int(model.floatingOpacity * 100))%")
                    .monospacedDigit()
                    .frame(width: 44, alignment: .trailing)
            }
        }
    }

    private var historyTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            Stepper("Recent files retained: \(model.recentRetentionLimit)", value: $model.recentRetentionLimit, in: 1...50)

            Toggle("Forget missing files automatically", isOn: $model.forgetMissingFilesAutomatically)

            List(model.recentFiles, id: \.self) { url in
                Text(url.lastPathComponent)
            }
            .frame(minHeight: 140)

            HStack {
                Button("Clear history") {
                    model.clearHistory()
                }
                Button("Clean missing files") {
                    model.cleanMissingFilesFromHistory()
                }
            }
        }
    }

    private var shortcutsTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            shortcutRow("Play/Pause current sound", name: .playPause)
            shortcutRow("Stop playback", name: .stopPlayback)
            shortcutRow("Replay last sound", name: .replayLast)
            shortcutRow("Open Preferences", name: .openPreferences)
            shortcutRow("Open Recent Files", name: .openRecentFiles)

            Text("Defaults: Play/Pause Cmd+Opt+P, Stop Cmd+Opt+S, Replay Cmd+Opt+R")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func shortcutRow(_ title: String, name: KeyboardShortcuts.Name) -> some View {
        HStack {
            Text(title)
            Spacer()
            KeyboardShortcuts.Recorder(for: name)
        }
    }
}
