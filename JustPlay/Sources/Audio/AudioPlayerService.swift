import AVFoundation
import Foundation

final class AudioPlayerService: NSObject, AVAudioPlayerDelegate {
    private var player: AVAudioPlayer?
    private var volumeRampTimer: Timer?

    var loopPlayback: Bool = false {
        didSet {
            player?.numberOfLoops = loopPlayback ? -1 : 0
        }
    }

    var onPlaybackEnded: (() -> Void)?

    var currentTime: TimeInterval {
        player?.currentTime ?? 0
    }

    var duration: TimeInterval {
        player?.duration ?? 0
    }

    var isPlaying: Bool {
        player?.isPlaying ?? false
    }

    func play(url: URL, fadeIn: Double) throws {
        if let player, player.url == url {
            player.numberOfLoops = loopPlayback ? -1 : 0
            if fadeIn > 0 {
                rampVolume(from: player.volume, to: 1.0, duration: fadeIn)
            }
            player.play()
            return
        }

        stop(fadeOut: 0)

        let newPlayer = try AVAudioPlayer(contentsOf: url)
        newPlayer.delegate = self
        newPlayer.prepareToPlay()
        newPlayer.numberOfLoops = loopPlayback ? -1 : 0
        player = newPlayer

        if fadeIn > 0 {
            newPlayer.volume = 0
            newPlayer.play()
            rampVolume(from: 0, to: 1.0, duration: fadeIn)
        } else {
            newPlayer.play()
        }
    }

    func pause() {
        player?.pause()
    }

    func stop(fadeOut: Double) {
        guard let player else { return }

        if fadeOut > 0, player.isPlaying {
            rampVolume(from: player.volume, to: 0.0, duration: fadeOut) { [weak self] in
                self?.player?.stop()
                self?.player?.currentTime = 0
                self?.onPlaybackEnded?()
            }
            return
        }

        player.stop()
        player.currentTime = 0
        onPlaybackEnded?()
    }

    func setVolume(_ value: Float) {
        player?.volume = max(0, min(1, value))
    }

    func seek(to time: TimeInterval) {
        guard let player else { return }
        let clamped = max(0, min(time, player.duration))
        player.currentTime = clamped
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onPlaybackEnded?()
    }

    private func rampVolume(from: Float, to: Float, duration: Double, completion: (() -> Void)? = nil) {
        volumeRampTimer?.invalidate()

        guard duration > 0, let player else {
            self.player?.volume = to
            completion?()
            return
        }

        let steps = max(1, Int(duration / 0.03))
        var currentStep = 0
        let increment = (to - from) / Float(steps)

        player.volume = from

        volumeRampTimer = Timer.scheduledTimer(withTimeInterval: duration / Double(steps), repeats: true) { [weak self] timer in
            guard let self, let player = self.player else {
                timer.invalidate()
                completion?()
                return
            }

            currentStep += 1
            if currentStep >= steps {
                player.volume = to
                timer.invalidate()
                completion?()
                return
            }

            player.volume = max(0, min(1, player.volume + increment))
        }
    }
}
