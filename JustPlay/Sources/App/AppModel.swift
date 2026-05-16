import AppKit
import Foundation
import ServiceManagement
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var isPlaying = false
    @Published private(set) var currentFileURL: URL?
    @Published var recentFiles: [URL]
    @Published var playbackPositionSeconds: Double = 0
    @Published var playbackDurationSeconds: Double = 0

    @Published var defaultSoundPath: String {
        didSet { saveString(defaultSoundPath, key: Keys.defaultSoundPath) }
    }

    @Published var loopPlayback: Bool {
        didSet {
            audioPlayer.loopPlayback = loopPlayback
            saveBool(loopPlayback, key: Keys.loopPlayback)
        }
    }

    @Published var autoPlayOnLaunch: Bool {
        didSet { saveBool(autoPlayOnLaunch, key: Keys.autoPlayOnLaunch) }
    }

    @Published var autoPlayOnFileOpen: Bool {
        didSet { saveBool(autoPlayOnFileOpen, key: Keys.autoPlayOnFileOpen) }
    }

    @Published var openAtLogin: Bool {
        didSet {
            guard openAtLogin != oldValue else { return }
            saveBool(openAtLogin, key: Keys.openAtLogin)
            applyOpenAtLoginPreference(enabled: openAtLogin, previousValue: oldValue)
        }
    }

    @Published var stopPlaybackOnWindowClose: Bool {
        didSet { saveBool(stopPlaybackOnWindowClose, key: Keys.stopPlaybackOnWindowClose) }
    }

    @Published var volume: Double {
        didSet {
            let clamped = max(0.0, min(1.0, volume))
            if clamped != volume {
                volume = clamped
                return
            }
            audioPlayer.setVolume(Float(clamped))
            saveDouble(clamped, key: Keys.volume)
        }
    }

    @Published var fadeInDuration: Double {
        didSet { saveDouble(max(0.0, fadeInDuration), key: Keys.fadeInDuration) }
    }

    @Published var fadeOutDuration: Double {
        didSet { saveDouble(max(0.0, fadeOutDuration), key: Keys.fadeOutDuration) }
    }

    @Published var recentRetentionLimit: Int {
        didSet {
            let normalized = max(1, recentRetentionLimit)
            if normalized != recentRetentionLimit {
                recentRetentionLimit = normalized
                return
            }
            saveInt(normalized, key: Keys.recentRetentionLimit)
            recentFiles = historyStore.trimmed(to: normalized)
            persistRecentFiles()
        }
    }

    @Published var forgetMissingFilesAutomatically: Bool {
        didSet { saveBool(forgetMissingFilesAutomatically, key: Keys.forgetMissingFilesAutomatically) }
    }

    @Published var keepFloatingWindowOnTop: Bool {
        didSet {
            saveBool(keepFloatingWindowOnTop, key: Keys.keepFloatingWindowOnTop)
            FloatingPlayerWindowController.shared.setFloating(keepFloatingWindowOnTop)
        }
    }

    @Published var floatingOpacity: Double {
        didSet {
            let clamped = max(0.35, min(1.0, floatingOpacity))
            if clamped != floatingOpacity {
                floatingOpacity = clamped
                return
            }
            saveDouble(clamped, key: Keys.floatingOpacity)
            FloatingPlayerWindowController.shared.setOpacity(clamped)
        }
    }

    private let defaults: UserDefaults
    private let audioPlayer: AudioPlayerService
    private var historyStore: HistoryStore
    private var playbackTimer: Timer?
    private var openURLsObserver: NSObjectProtocol?

    init(
        defaults: UserDefaults = .standard,
        audioPlayer: AudioPlayerService = AudioPlayerService()
    ) {
        self.defaults = defaults
        self.audioPlayer = audioPlayer

        self.defaultSoundPath = defaults.string(forKey: Keys.defaultSoundPath) ?? ""
        self.loopPlayback = defaults.bool(forKey: Keys.loopPlayback)
        self.autoPlayOnLaunch = defaults.bool(forKey: Keys.autoPlayOnLaunch)
        if defaults.object(forKey: Keys.autoPlayOnFileOpen) == nil {
            self.autoPlayOnFileOpen = true
        } else {
            self.autoPlayOnFileOpen = defaults.bool(forKey: Keys.autoPlayOnFileOpen)
        }
        if defaults.object(forKey: Keys.openAtLogin) == nil {
            self.openAtLogin = Self.currentOpenAtLoginState()
        } else {
            self.openAtLogin = defaults.bool(forKey: Keys.openAtLogin)
        }
        if defaults.object(forKey: Keys.stopPlaybackOnWindowClose) == nil {
            self.stopPlaybackOnWindowClose = true
        } else {
            self.stopPlaybackOnWindowClose = defaults.bool(forKey: Keys.stopPlaybackOnWindowClose)
        }

        let storedVolume = defaults.object(forKey: Keys.volume) as? Double ?? 0.8
        self.volume = max(0.0, min(1.0, storedVolume))

        self.fadeInDuration = max(0.0, defaults.object(forKey: Keys.fadeInDuration) as? Double ?? 0.0)
        self.fadeOutDuration = max(0.0, defaults.object(forKey: Keys.fadeOutDuration) as? Double ?? 0.0)
        let initialRetentionLimit = max(1, defaults.object(forKey: Keys.recentRetentionLimit) as? Int ?? 10)
        self.recentRetentionLimit = initialRetentionLimit
        self.forgetMissingFilesAutomatically = defaults.bool(forKey: Keys.forgetMissingFilesAutomatically)
        self.keepFloatingWindowOnTop = defaults.bool(forKey: Keys.keepFloatingWindowOnTop)
        self.floatingOpacity = max(0.35, min(1.0, defaults.object(forKey: Keys.floatingOpacity) as? Double ?? 0.95))

        let recentURLs = Self.decodeURLs(from: defaults.array(forKey: Keys.recentFiles) as? [String] ?? [])
        let initialHistoryStore = HistoryStore(initial: recentURLs, retentionLimit: initialRetentionLimit)
        self.historyStore = initialHistoryStore
        self.recentFiles = initialHistoryStore.trimmed(to: initialRetentionLimit)

        self.audioPlayer.loopPlayback = loopPlayback
        self.audioPlayer.setVolume(Float(volume))

        ShortcutBindings.register(model: self)
        observePlayerState()
        observeOpenFileRequests()
        startPlaybackTimerIfNeeded()
        refreshPlaybackPosition()

        if autoPlayOnLaunch, let url = defaultSoundURL, FileManager.default.fileExists(atPath: url.path) {
            play(url: url)
        }
    }

    var defaultSoundURL: URL? {
        guard !defaultSoundPath.isEmpty else { return nil }
        return URL(fileURLWithPath: defaultSoundPath)
    }

    deinit {
        playbackTimer?.invalidate()
        if let observer = openURLsObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    var playbackPositionRange: ClosedRange<Double> {
        0...max(playbackDurationSeconds, 0.1)
    }

    var playbackElapsedLabel: String {
        Self.formatTime(playbackPositionSeconds)
    }

    var playbackRemainingLabel: String {
        let remaining = max(0, playbackDurationSeconds - playbackPositionSeconds)
        return "-\(Self.formatTime(remaining))"
    }

    func seek(to seconds: Double) {
        audioPlayer.seek(to: seconds)
        refreshPlaybackPosition()
    }

    func skipBackward(seconds: Double = 10) {
        seek(to: playbackPositionSeconds - seconds)
    }

    func skipForward(seconds: Double = 10) {
        seek(to: playbackPositionSeconds + seconds)
    }

    func handleOpenedFiles(_ urls: [URL]) {
        let supportedExtensions = Set(SupportedAudioTypes.supportedExtensions.map { $0.lowercased() })
        guard let url = urls.first(where: { supportedExtensions.contains($0.pathExtension.lowercased()) }) else {
            return
        }

        if autoPlayOnFileOpen {
            play(url: url)
            return
        }

        currentFileURL = url
        isPlaying = false
        historyStore.record(url: url)
        recentFiles = historyStore.trimmed(to: recentRetentionLimit)
        persistRecentFiles()
        refreshPlaybackPosition()
        FloatingPlayerWindowController.shared.show(model: self)
        FloatingPlayerWindowController.shared.setOpacity(floatingOpacity)
        FloatingPlayerWindowController.shared.setFloating(keepFloatingWindowOnTop)
    }

    func chooseAndPlayFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = SupportedAudioTypes.all
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.prompt = "Open"

        if panel.runModal() == .OK, let fileURL = panel.url {
            play(url: fileURL)
        }
    }

    func setDefaultSoundFromPanel() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = SupportedAudioTypes.all
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.prompt = "Select"

        if panel.runModal() == .OK, let fileURL = panel.url {
            defaultSoundPath = fileURL.path
        }
    }

    func playDefaultSoundIfAvailable() {
        guard let url = defaultSoundURL else { return }
        play(url: url)
    }

    func play(url: URL) {
        do {
            try audioPlayer.play(url: url, fadeIn: fadeInDuration)
            currentFileURL = url
            historyStore.record(url: url)
            recentFiles = historyStore.trimmed(to: recentRetentionLimit)
            persistRecentFiles()
            isPlaying = true
            refreshPlaybackPosition()
            FloatingPlayerWindowController.shared.show(model: self)
            FloatingPlayerWindowController.shared.setOpacity(floatingOpacity)
            FloatingPlayerWindowController.shared.setFloating(keepFloatingWindowOnTop)
        } catch {
            NSSound.beep()
        }
    }

    func playPause() {
        if isPlaying {
            audioPlayer.pause()
            isPlaying = false
            refreshPlaybackPosition()
            return
        }

        if let currentFileURL {
            do {
                try audioPlayer.play(url: currentFileURL, fadeIn: 0)
                isPlaying = true
                refreshPlaybackPosition()
            } catch {
                NSSound.beep()
            }
        } else {
            playDefaultSoundIfAvailable()
        }
    }

    func stop() {
        audioPlayer.stop(fadeOut: fadeOutDuration)
        isPlaying = false
        refreshPlaybackPosition()
    }

    func replayLast() {
        guard let url = recentFiles.first ?? currentFileURL else { return }
        play(url: url)
    }

    func clearHistory() {
        historyStore.clear()
        recentFiles.removeAll()
        persistRecentFiles()
    }

    func cleanMissingFilesFromHistory() {
        guard forgetMissingFilesAutomatically else { return }
        let existing = recentFiles.filter { FileManager.default.fileExists(atPath: $0.path) }
        historyStore.replace(with: existing)
        recentFiles = historyStore.trimmed(to: recentRetentionLimit)
        persistRecentFiles()
    }

    func showPreferences() {
        PreferencesWindowController.shared.show(model: self)
    }

    func toggleFloatingWindow() {
        FloatingPlayerWindowController.shared.toggle(model: self)
        FloatingPlayerWindowController.shared.setOpacity(floatingOpacity)
        FloatingPlayerWindowController.shared.setFloating(keepFloatingWindowOnTop)
    }

    func hideFloatingWindow() {
        FloatingPlayerWindowController.shared.hide()
    }

    func handleFloatingWindowClosed() {
        guard stopPlaybackOnWindowClose, isPlaying else { return }
        stop()
    }

    private func persistRecentFiles() {
        let paths = recentFiles.map(\.path)
        defaults.set(paths, forKey: Keys.recentFiles)
    }

    private func observePlayerState() {
        audioPlayer.onPlaybackEnded = { [weak self] in
            Task { @MainActor in
                self?.isPlaying = false
                self?.refreshPlaybackPosition()
            }
        }
    }

    private static func currentOpenAtLoginState() -> Bool {
        switch SMAppService.mainApp.status {
        case .enabled, .requiresApproval:
            return true
        default:
            return false
        }
    }

    private func applyOpenAtLoginPreference(enabled: Bool, previousValue: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSSound.beep()
            openAtLogin = previousValue
            saveBool(previousValue, key: Keys.openAtLogin)
        }
    }

    private func observeOpenFileRequests() {
        openURLsObserver = NotificationCenter.default.addObserver(
            forName: .justPlayOpenURLs,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let urls = notification.userInfo?["urls"] as? [URL] else { return }
            self?.handleOpenedFiles(urls)
        }
    }

    private func startPlaybackTimerIfNeeded() {
        guard playbackTimer == nil else { return }
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshPlaybackPosition()
            }
        }
    }

    private func refreshPlaybackPosition() {
        playbackDurationSeconds = max(0, audioPlayer.duration)
        playbackPositionSeconds = min(max(0, audioPlayer.currentTime), playbackDurationSeconds)
    }

    private static func formatTime(_ seconds: Double) -> String {
        let totalSeconds = max(0, Int(seconds.rounded()))
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func saveString(_ value: String, key: String) {
        defaults.set(value, forKey: key)
    }

    private func saveBool(_ value: Bool, key: String) {
        defaults.set(value, forKey: key)
    }

    private func saveInt(_ value: Int, key: String) {
        defaults.set(value, forKey: key)
    }

    private func saveDouble(_ value: Double, key: String) {
        defaults.set(value, forKey: key)
    }

    private static func decodeURLs(from paths: [String]) -> [URL] {
        paths.map { URL(fileURLWithPath: $0) }
    }

    private enum Keys {
        static let defaultSoundPath = "defaultSoundPath"
        static let loopPlayback = "loopPlayback"
        static let autoPlayOnLaunch = "autoPlayOnLaunch"
        static let autoPlayOnFileOpen = "autoPlayOnFileOpen"
        static let openAtLogin = "openAtLogin"
        static let stopPlaybackOnWindowClose = "stopPlaybackOnWindowClose"
        static let volume = "volume"
        static let fadeInDuration = "fadeInDuration"
        static let fadeOutDuration = "fadeOutDuration"
        static let recentFiles = "recentFiles"
        static let recentRetentionLimit = "recentRetentionLimit"
        static let forgetMissingFilesAutomatically = "forgetMissingFilesAutomatically"
        static let keepFloatingWindowOnTop = "keepFloatingWindowOnTop"
        static let floatingOpacity = "floatingOpacity"
    }
}
