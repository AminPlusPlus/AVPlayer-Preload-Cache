import SwiftUI
import AVKit

struct VideoPlayerView: View {
    private var player: AVPlayer?
    private var viewModel = VideoPlayerViewModel()
    @Environment(\.dismiss) var dismiss
    
    init(videoURL: URL) {
        viewModel.setupPlayer(with: videoURL)
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if let player = viewModel.player {
                AVControllerVideoPlayerView(player: player)
                    .edgesIgnoringSafeArea(.all)
                    .onVisibilityChanged{ seen in
                        if seen {
                            viewModel.player?.play()
                            Logger.logMessage("Seen : \(String(describing: viewModel.player?.currentItem?.isPlaybackBufferFull))")
                        } else {
                            viewModel.player?.pause()
                        }
                    }
            } else {
                Text("Unable to load video")
            }
            
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(.black)
                    .frame(width: 44, height: 44)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(radius: 2)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 50)
            .padding(.leading, 20)
        }
    }
}
