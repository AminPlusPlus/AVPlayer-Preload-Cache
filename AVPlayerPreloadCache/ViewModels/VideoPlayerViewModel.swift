import AVKit
import Combine
import Observation

@Observable
class VideoPlayerViewModel {
    var player: AVPlayer?
    private var endPlaybackCancellable: AnyCancellable?

    func setupPlayer(with videoURL: URL) {
        let playerItem: AVPlayerItem
        if let cachedPlayerItem = VideoCachingManager.shared.getCachedPlayerItem(for: videoURL) {
            playerItem = cachedPlayerItem
            print("Playing from Cache: \(cachedPlayerItem.asset)")
        } else {
            playerItem = AVPlayerItem(url: videoURL)
            self.player = AVPlayer(url: videoURL)
        }
        self.player = AVPlayer(playerItem: playerItem)
        
        endPlaybackCancellable = NotificationCenter.default.publisher(for: AVPlayerItem.didPlayToEndTimeNotification, object: playerItem)
            .sink { [weak self] _ in
                self?.player?.seek(to: .zero)
                self?.player?.play()
            }
    }

    deinit {
        player?.pause()
        endPlaybackCancellable?.cancel()
    }
}
