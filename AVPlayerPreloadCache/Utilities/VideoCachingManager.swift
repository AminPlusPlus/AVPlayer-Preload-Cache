import AVFoundation

public class VideoCachingManager: NSObject  {
    static let shared = VideoCachingManager()
    private var videoCache = NSCache<NSURL, AVURLAsset>()
    private var downloadSession: AVAssetDownloadURLSession!
    
    private override init() {
        super.init()
        let configuration = URLSessionConfiguration.background(withIdentifier: "VideoDownloadSession")
        downloadSession = AVAssetDownloadURLSession(configuration: configuration, assetDownloadDelegate: self, delegateQueue: .main)
    }
    
    /// Preloads a video asset from the given URL by first checking the cache, then local storage,
    /// and finally initiating a download if the asset is not found.
    /// - Parameter url: The URL of the video asset to preload.
    /// - Discussion:
    ///   - If the asset is already cached, the method exits early.
    ///   - If not cached, the method checks if the asset exists in local storage. If found,
    ///     it loads the asset from the local file and caches it.
    ///   - If the asset is neither cached nor found locally, it initiates a download
    ///     using `AVAssetDownloadURLSession` and caches the asset upon successful download.
    func preloadVideo(from url: URL){
        if let cachedAsset = videoCache.object(forKey: url as NSURL) {
            Logger.logMessage("Asset already cached: \(cachedAsset)")
            return
        }
                
        loadAssetIfExists(at: url) { [weak self] videoURL in
            guard let self = self else { return }
            let asset = AVURLAsset(url: videoURL)
            self.videoCache.setObject(asset, forKey: url as NSURL)
            Logger.logMessage("Asset loaded from local storage and cached: \(asset)")
        } notFound: { [weak self] in
            guard let self = self else { return  }
            let asset = AVURLAsset(url: url)
            let config = AVAssetDownloadConfiguration(asset: asset, title: url.absoluteString)
        
            let downloadTask = self.downloadSession.makeAssetDownloadTask(downloadConfiguration: config)
            downloadTask.resume()
        }
    }
    
    /// Retrieves a cached AVPlayerItem for the given URL if it exists in the cache.
    /// - Parameter url: The URL of the video asset to retrieve.
    /// - Returns: An AVPlayerItem created from the cached AVURLAsset if found, otherwise returns nil.
    /// - Discussion: This method checks the `videoCache` for an AVURLAsset corresponding to the provided URL.
    ///   If a cached asset is found, it creates and returns an AVPlayerItem using this asset.
    ///   If no cached asset is available, the method returns nil, indicating that the asset needs to be loaded or downloaded.
    func getCachedPlayerItem(for url: URL) -> AVPlayerItem? {
        if let cachedAsset = videoCache.object(forKey: url as NSURL) {
            Logger.logMessage("Cached Asset for \(url) : \(String(describing: cachedAsset.assetCache?.isPlayableOffline))")
            return AVPlayerItem(asset: cachedAsset)
        }
        return nil
    }
    
    /// Preloads multiple video assets asynchronously using a task group.
    func preloadVideos(from urls: [URL]) async {
        await withTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask {
                    self.preloadVideo(from: url)
                }
            }
        }
    }
}

//MARK: - AVAssetDownloadDelegate
 extension VideoCachingManager: AVAssetDownloadDelegate {
    
    // AVAssetDownloadDelegate Methods
     public func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        let url = assetDownloadTask.urlAsset.url as NSURL
        
        moveItemsToDownloadFolder(for: location, originalURLString: url.absoluteString ?? "____") { [weak self] destinationURL in
            self?.videoCache.setObject(AVURLAsset(url: destinationURL), forKey: url)
        }
        Logger.logMessage("Downloaded video to: \(location)")
    }
    
     public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            Logger.logMessage("Failed to download video: \(error)", level: .error)
        }
    }
    
    private func moveItemsToDownloadFolder(for assetURL: URL, originalURLString: String, completed: @escaping (URL) -> Void) {
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        // Extract the original filename from the original URL string
        guard let originalFilename = URL(string: originalURLString)?.lastPathComponent else {
            Logger.logMessage("Invalid original URL string \(originalURLString)", level: .error)
            return
        }
        
        // Define the destination URL with the original filename
        let destinationURL = documentDirectory.appendingPathComponent(originalFilename)
        
        // Ensure the source file exists
        guard fileManager.fileExists(atPath: assetURL.path) else {
            Logger.logMessage("Source file does not exist at \(assetURL.path)", level: .error)
            return
        }

        // Ensure the destination directory exists
        let destinationDirectory = destinationURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: destinationDirectory.path) {
            do {
                try fileManager.createDirectory(at: destinationDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                Logger.logMessage("Error creating directory: \(error)", level: .error)
                return
            }
        }

        // Handle existing file at destination
        if fileManager.fileExists(atPath: destinationURL.path) {
            do {
                try fileManager.removeItem(at: destinationURL)
            } catch {
                Logger.logMessage("Error removing existing file: \(error)", level: .error)
                return
            }
        }

        // Move and rename the file
        do {
            try fileManager.moveItem(at: assetURL, to: destinationURL)
            completed(destinationURL)
            Logger.logMessage("Asset moved to: \(destinationURL)")
        } catch {
            Logger.logMessage("Error moving asset: \(error)", level: .error)
        }
    }
    
    //Checks if the video asset exists locally and calls the appropriate closure.
    private func loadAssetIfExists(at url: URL, found: @escaping (URL) -> Void, notFound: @escaping () -> Void) {
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let assetURL = documentDirectory.appendingPathComponent(url.lastPathComponent)

        if fileManager.fileExists(atPath: assetURL.path) {
            Logger.logMessage("File exists at \(assetURL.path)")
            found(assetURL)
        } else {
            Logger.logMessage("File does not exist at \(assetURL.path)")
            notFound()
        }
    }
}
