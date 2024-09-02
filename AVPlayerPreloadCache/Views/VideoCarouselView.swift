import SwiftUI
import Combine

struct VideoCarouselView: View {
    private var viewModel = VideoCarouselViewModel()
    @State private var isFullVideoPresented = false
   
    var body: some View {
        VStack(alignment: .leading) {
            Text("Explore")
                .font(.system(.title, weight: .bold))
                .padding(.leading)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(viewModel.videoItems.enumerated()), id: \.element.id) { (index, item) in
                        VideoCarouselThumbnailView(imageURLString: item.thumbnailURL)
                            .tag(item.id)
                            .onTapGesture {
                                isFullVideoPresented.toggle()
                                viewModel.selectedIndex = index
                            }
                    }
                }
                .padding(.leading)
                .frame(height: 300)
            }
        }
        .onAppear {
            viewModel.loadVideoItems()
        }
        .task {
            _ = await VideoCachingManager.shared.preloadVideos(from: viewModel.videoItems.videoCarouselURLs)
        }
        .fullScreenCover(isPresented: $isFullVideoPresented) {
            FullVideoCarouselView(videoItems: viewModel.videoItems, selectedVideoIndex: viewModel.selectedIndex)
        }
    }
}

private struct VideoCarouselThumbnailView: View {
    let imageURLString: String
    var body: some View {
        AsyncImage(url: URL(string: imageURLString)) { phase in
            switch phase {
            case .empty:
                Color.white
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            case .failure(_):
                ZStack {
                    Color.white
                    Image(systemName: "photo")
                        .scaledToFit()
                }
                
            @unknown default:
                EmptyView()
            }
        }
        .frame(width: 160)
        .clipShape(.rect(cornerRadius: 25))
    }
}
