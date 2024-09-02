import Foundation
import Observation

@Observable
final class VideoCarouselViewModel {
    var selectedIndex: Int = 0
    var videoItems: [VideoItem] = []
    
    func loadVideoItems() {
        if let items = VideoItem.loadJson(filename: "mock-video-items") {
            videoItems = items
        }
    }
}

extension Array where Element == VideoItem {
    var videoCarouselURLs: [URL] {
        self.compactMap { URL(string: $0.videoURL) }
    }
}
