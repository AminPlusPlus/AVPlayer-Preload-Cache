import SwiftUI

struct FullVideoCarouselView: View {
    let videoItems: [VideoItem]
    let selectedVideoIndex: Int
    var body: some View {
        GeometryReader { proxy in
            ScrollViewReader { scrollViewProxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 0) {
                        ForEach(videoItems.indices, id: \.self) { index in
                            VideoPlayerView(videoURL: videoItems.videoCarouselURLs[index])
                                .frame(width: proxy.size.width)
                                .tag(index)
                            
                        }
                    }
                    .frame(height: proxy.size.height)
                }
                .onAppear {
                    scrollViewProxy.scrollTo(selectedVideoIndex, anchor: .center)
                }
                .scrollTargetBehavior(.paging)
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}
