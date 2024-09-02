import SwiftUI

@main
struct AVPlayerPreloadCacheApp: App {
    var body: some Scene {
        WindowGroup {
            ZStack {
                Color(white: 0.95)
                    .edgesIgnoringSafeArea(.all)
                VideoCarouselView()
            }
        }
        
    }
}
