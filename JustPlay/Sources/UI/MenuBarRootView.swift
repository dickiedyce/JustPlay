import SwiftUI

struct MenuBarRootView: View {
    @ObservedObject var model: AppModel

    @ViewBuilder
    var body: some View {
        Button(model.isPlaying ? "Pause" : "Play") {
            model.playPause()
        }

        Button("Open...") {
            model.chooseAndPlayFile()
        }

        Button("Stop") {
            model.stop()
        }

        Button("Replay Last") {
            model.replayLast()
        }

        Divider()

        Text("Recent Files")

        if model.recentFiles.isEmpty {
            Text("No Recent Files")
        } else {
            ForEach(model.recentFiles, id: \.self) { url in
                Button(url.lastPathComponent) {
                    model.play(url: url)
                }
            }
        }

        Divider()

        Button("Show/Hide Floating Player") {
            model.toggleFloatingWindow()
        }

        Button("Preferences...") {
            model.showPreferences()
        }

        Divider()

        Button("Quit JustPlay") {
            NSApplication.shared.terminate(nil)
        }
        .onAppear {
            model.cleanMissingFilesFromHistory()
        }
    }
}
