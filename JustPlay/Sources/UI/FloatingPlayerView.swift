import SwiftUI

struct FloatingPlayerView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(model.currentFileURL?.lastPathComponent ?? "No sound selected")
                .font(.headline)
                .lineLimit(1)

            HStack(spacing: 8) {
                Button {
                    model.skipBackward()
                } label: {
                    Text("⏪︎")
                }
                .accessibilityLabel("Skip backward")

                Button {
                    model.playPause()
                } label: {
                    Text(model.isPlaying ? "⏸︎" : "▶︎")
                }
                .accessibilityLabel(model.isPlaying ? "Pause" : "Play")

                Button {
                    model.stop()
                } label: {
                    Text("⏹︎")
                }
                .accessibilityLabel("Stop")

                Button {
                    model.replayLast()
                } label: {
                    Text("↻")
                }
                .accessibilityLabel("Replay last")

                Button {
                    model.skipForward()
                } label: {
                    Text("⏩︎")
                }
                .accessibilityLabel("Skip forward")
            }
            .font(.title3)

            HStack(spacing: 8) {
                Text(model.playbackElapsedLabel)
                    .font(.caption)
                    .monospacedDigit()

                Slider(
                    value: $model.playbackPositionSeconds,
                    in: model.playbackPositionRange,
                    onEditingChanged: { _ in
                        model.seek(to: model.playbackPositionSeconds)
                    }
                )

                Text(model.playbackRemainingLabel)
                    .font(.caption)
                    .monospacedDigit()
            }

            HStack {
                Text("Volume")
                Slider(value: $model.volume, in: 0...1)
            }
        }
        .padding(12)
        .frame(width: 320)
    }
}
