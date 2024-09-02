import AVFoundation

class VideoCachingManager: NSObject, AVAssetDownloadDelegate {
    static let shared = VideoCachingManager()
    private var videoCache = NSCache<NSURL, AVURLAsset>()
    private var downloadSession: AVAssetDownloadURLSession!
    
    private override init() {
        super.init()
        let configuration = URLSessionConfiguration.background(withIdentifier: "VideoDownloadSession")
        downloadSession = AVAssetDownloadURLSession(configuration: configuration, assetDownloadDelegate: self, delegateQueue: .main)
    }
    
    
    func preloadVideo(from url: URL){
        if let cachedAsset = videoCache.object(forKey: url as NSURL) {
            print("Asset already cached: \(cachedAsset)")
            return
        }
                
        loadAssetIfExists(at: url) { [weak self] videoURL in
            guard let self = self else { return }
            let asset = AVURLAsset(url: videoURL)
            self.videoCache.setObject(asset, forKey: url as NSURL)
            print("Asset loaded from local storage and cached: \(asset)")
        } notFound: { [weak self] in
            guard let self = self else { return  }
            let asset = AVURLAsset(url: url)
            let config = AVAssetDownloadConfiguration(asset: asset, title: url.absoluteString)
        
            let downloadTask = self.downloadSession.makeAssetDownloadTask(downloadConfiguration: config)
            downloadTask.resume()
        }
    }
    
    func getCachedPlayerItem(for url: URL) -> AVPlayerItem? {
        if let cachedAsset = videoCache.object(forKey: url as NSURL) {
            print("cachedAsset : \(cachedAsset.assetCache?.isPlayableOffline)")
            return AVPlayerItem(asset: cachedAsset)
        }
        return nil
    }
    
    func preloadVideos(from urls: [URL]) async {
        await withTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask {
                    self.preloadVideo(from: url)
                }
            }
        }
    }
    
    // AVAssetDownloadDelegate Methods
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        let url = assetDownloadTask.urlAsset.url as NSURL
        
        moveItemsToDownloadFolder(for: location, originalURLString: url.absoluteString ?? "____") { [weak self] destinationURL in
            self?.videoCache.setObject(AVURLAsset(url: destinationURL), forKey: url)
        }
        print("Downloaded video to: \(location)")
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("Failed to download video: \(error)")
        }
    }
    
    private func moveItemsToDownloadFolder(for assetURL: URL, originalURLString: String, completed: @escaping (URL) -> Void) {
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        // Extract the original filename from the original URL string
        guard let originalFilename = URL(string: originalURLString)?.lastPathComponent else {
            print("Invalid original URL string")
            return
        }
        
        // Define the destination URL with the original filename
        let destinationURL = documentDirectory.appendingPathComponent(originalFilename)
        
        // Ensure the source file exists
        guard fileManager.fileExists(atPath: assetURL.path) else {
            print("Source file does not exist at \(assetURL.path)")
            return
        }

        // Ensure the destination directory exists
        let destinationDirectory = destinationURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: destinationDirectory.path) {
            do {
                try fileManager.createDirectory(at: destinationDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating directory: \(error)")
                return
            }
        }

        // Handle existing file at destination
        if fileManager.fileExists(atPath: destinationURL.path) {
            do {
                try fileManager.removeItem(at: destinationURL)
            } catch {
                print("Error removing existing file: \(error)")
                return
            }
        }

        // Move and rename the file
        do {
            try fileManager.moveItem(at: assetURL, to: destinationURL)
            completed(destinationURL)
            print("Asset moved to: \(destinationURL)")
        } catch {
            print("Error moving asset: \(error)")
        }
    }
    
    private func loadAssetIfExists(at url: URL, found: @escaping (URL) -> Void, notFound: @escaping () -> Void) {
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let assetURL = documentDirectory.appendingPathComponent(url.lastPathComponent)

        if fileManager.fileExists(atPath: assetURL.path) {
            print("File exists at \(assetURL.path)")
            found(assetURL)

        } else {
            print("File does not exist at \(assetURL.path)")
            notFound()
        }
    }
}
