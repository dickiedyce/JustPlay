import AppKit
import KeyboardShortcuts

enum ShortcutBindings {
    static func register(model: AppModel) {
        KeyboardShortcuts.onKeyUp(for: .playPause) {
            Task { @MainActor in
                model.playPause()
            }
        }

        KeyboardShortcuts.onKeyUp(for: .stopPlayback) {
            Task { @MainActor in
                model.stop()
            }
        }

        KeyboardShortcuts.onKeyUp(for: .replayLast) {
            Task { @MainActor in
                model.replayLast()
            }
        }

        KeyboardShortcuts.onKeyUp(for: .openPreferences) {
            Task { @MainActor in
                model.showPreferences()
            }
        }

        KeyboardShortcuts.onKeyUp(for: .openRecentFiles) {
            NSApp.activate(ignoringOtherApps: true)
        }

        if KeyboardShortcuts.getShortcut(for: .playPause) == nil {
            KeyboardShortcuts.setShortcut(.init(.p, modifiers: [.command, .option]), for: .playPause)
        }
        if KeyboardShortcuts.getShortcut(for: .stopPlayback) == nil {
            KeyboardShortcuts.setShortcut(.init(.s, modifiers: [.command, .option]), for: .stopPlayback)
        }
        if KeyboardShortcuts.getShortcut(for: .replayLast) == nil {
            KeyboardShortcuts.setShortcut(.init(.r, modifiers: [.command, .option]), for: .replayLast)
        }
    }
}

extension KeyboardShortcuts.Name {
    static let playPause = Self("playPause")
    static let stopPlayback = Self("stopPlayback")
    static let replayLast = Self("replayLast")
    static let openPreferences = Self("openPreferences")
    static let openRecentFiles = Self("openRecentFiles")
}
