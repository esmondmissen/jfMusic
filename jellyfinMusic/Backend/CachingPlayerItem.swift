//
//  CachingPlayerItem.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 22/10/20.
//

import Foundation
import AVFoundation
import AVKit
import Cache

class AudioPlayerWorker {
    var player: AVPlayer?
    let diskConfig = DiskConfig(name: "DiskCache")
    let memoryConfig = MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10)

    lazy var storage: Cache.Storage? = {
        return try? Cache.Storage<String, Data>(diskConfig: diskConfig, memoryConfig: memoryConfig, transformer: TransformerFactory.forData())
    }()


    // MARK: - Logic
    func downloadVideo(_ url: URL) {
        let configuration = URLSessionConfiguration.background(withIdentifier: "Test")
        configuration.httpAdditionalHeaders = [
            "X-Emby-Token": NetworkingManager.shared.accessToken
         ]
        
        let downloadSession = AVAssetDownloadURLSession(configuration: configuration,
                                                        assetDownloadDelegate: nil,
                                  delegateQueue: OperationQueue.main)
        // HLS Asset URL
        let asset = AVURLAsset(url: url)

        // Create new AVAssetDownloadTask for the desired asset
        let downloadTask = downloadSession.makeAssetDownloadTask(asset: asset,
                                                                 assetTitle: "Test",
                                                                 assetArtworkData: nil,
                                                                 options: nil)
        // Start task and begin download
        downloadTask?.resume()
    }
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        UserDefaults.standard.set(location.relativePath, forKey: "assetPath")
        print("Done")
    }

    
    /// Plays a track either from the network if it's not cached or from the cache.
    func play(with item: PlayableV2) {
        
//        let headers: [String: String] = [ "X-Emby-Token": NetworkingManager.shared.accessToken ]
//        let hlAsset = AVURLAsset(url: item.getStreamingURL(), options: ["AVURLAssetHTTPHeaderFieldsKey": headers, AVURLAssetPreferPreciseDurationAndTimingKey : true])
//
//        let backgroundConfiguration = URLSessionConfiguration.background(withIdentifier: "audioDOwnload")
//        let assetURLSession = AVAssetDownloadURLSession(configuration: backgroundConfiguration, assetDownloadDelegate: self, delegateQueue: OperationQueue.main)
//
//        let assetDownloadTask = assetURLSession.makeAssetDownloadTask(asset: hlsAsset, assetTitle: "Test", assetArtworkData: nil, options: [])!
//
        // Trying to retrieve a track from cache asynchronously.
        
        
        
        print("test")
        let url = item.getStreamingURL()
        print(url)
        let hlsion = HLSion(url: url, options: [ "AVURLAssetHTTPHeaderFieldsKey" : ["X-Emby-Token": NetworkingManager.shared.accessToken] ], name: item.song.id!).download { (progressPercentage) in
            // call while each file downloaded.
            print(progressPercentage)
        }.finish { (relativePath) in
            print("Finish")
            // call when complete or cancel download task finish.
        }.onError { (error) in
            print("Error")
            // call when error finish.
        }
        
        guard let localUrl = hlsion.localUrl else {
            // This instance not yet downloaded.
            return
        }
        let localAsset = AVURLAsset(url: localUrl)
        let playerItem = AVPlayerItem(asset: localAsset)
        do{
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, policy: .default, options: [ ])
            print("Does this mean success?")
        }catch{
            print(error)
        }
        
        do{
            try AVAudioSession.sharedInstance().setActive(true, options: [])
        }catch{
            print(error)
        }
            UIApplication.shared.beginReceivingRemoteControlEvents()
        
        player = AVPlayer(playerItem: playerItem)
        player?.play()
        
        
        
//        DownloadManager.shared.setupAssetDownload(item.getStreamingURL())
//        downloadVideo()
        
        
//        storage?.async.entry(forKey: item.song.id!, completion: { result in
//            let playerItem: CachingPlayerItem
//            switch result {
//            case .error:
//                // The track is not cached.
//                playerItem = CachingPlayerItem(item: item)
//            case .value(let entry):
//                // The track is cached.
//                playerItem = CachingPlayerItem(data: entry.object, mimeType: "audio/mpeg", fileExtension: "mp3")
//                print(playerItem)
//            }
//            playerItem.delegate = self
//            Player.shared.player = AVQueuePlayer(items: [playerItem])
//
//        })
    }

}

// MARK: - CachingPlayerItemDelegate
extension AudioPlayerWorker: CachingPlayerItemDelegate {
    func playerItem(_ playerItem: CachingPlayerItem, didFinishDownloadingData data: Data) {
        // A track is downloaded. Saving it to the cache asynchronously.
        storage?.async.setObject(data, forKey: (playerItem.item?.song.id!)!, completion: { _ in })
    }
    func playerItem(_ playerItem: CachingPlayerItem, didDownloadBytesSoFar bytesDownloaded: Int, outOf bytesExpected: Int) {
        // A track is downloaded. Saving it to the cache asynchronously.
        print(Decimal(bytesDownloaded/bytesExpected))
    }
    
    func playerItemReadyToPlay(_ playerItem: CachingPlayerItem) {
        print("Ready to play")
        
        Player.shared.player!.play()
    }
    
    func playerItem(_ playerItem: CachingPlayerItem, downloadingFailedWith error: Error){
        print("Download Error")
    }
}

fileprivate extension URL {
    
    func withScheme(_ scheme: String) -> URL? {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        components?.scheme = scheme
        return components?.url
    }
    
}

@objc protocol CachingPlayerItemDelegate {
    
    /// Is called when the media file is fully downloaded.
    @objc optional func playerItem(_ playerItem: CachingPlayerItem, didFinishDownloadingData data: Data)
    
    /// Is called every time a new portion of data is received.
    @objc optional func playerItem(_ playerItem: CachingPlayerItem, didDownloadBytesSoFar bytesDownloaded: Int, outOf bytesExpected: Int)
    
    /// Is called after initial prebuffering is finished, means
    /// we are ready to play.
    @objc optional func playerItemReadyToPlay(_ playerItem: CachingPlayerItem)
    
    /// Is called when the data being downloaded did not arrive in time to
    /// continue playback.
    @objc optional func playerItemPlaybackStalled(_ playerItem: CachingPlayerItem)
    
    /// Is called on downloading error.
    @objc optional func playerItem(_ playerItem: CachingPlayerItem, downloadingFailedWith error: Error)
    
}

open class CachingPlayerItem: AVPlayerItem {
    
    class ResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate, URLSessionDelegate, URLSessionDataDelegate, URLSessionTaskDelegate {
        
        var playingFromData = false
        var mimeType: String? // is required when playing from Data
        var session: URLSession?
        var mediaData: Data?
        var response: URLResponse?
        var pendingRequests = Set<AVAssetResourceLoadingRequest>()
        weak var owner: CachingPlayerItem?
        
        func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
            
            if playingFromData {
                
                // Nothing to load.
                
            } else if session == nil {
                
                // If we're playing from a url, we need to download the file.
                // We start loading the file on first request only.
                guard let initialUrl = owner?.url else {
                    fatalError("internal inconsistency")
                }

                startDataRequest(with: URL(string:"\(initialUrl)".replacingOccurrences(of: "hjjp", with: "http"))!)
            }
            
            pendingRequests.insert(loadingRequest)
            processPendingRequests()
            return true
            
        }
        
        func startDataRequest(with url: URL) {
            let configuration = URLSessionConfiguration.default
            configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            configuration.httpAdditionalHeaders = [
                "X-Emby-Token": NetworkingManager.shared.accessToken
             ]
            session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
            session?.dataTask(with: url).resume()
        }
        
        func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
            pendingRequests.remove(loadingRequest)
        }
        
        // MARK: URLSession delegate
        
        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
            mediaData?.append(data)
            processPendingRequests()
            owner?.delegate?.playerItem?(owner!, didDownloadBytesSoFar: mediaData!.count, outOf: Int(dataTask.countOfBytesExpectedToReceive))
        }
        
        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
            completionHandler(Foundation.URLSession.ResponseDisposition.allow)
            mediaData = Data()
            self.response = response
            processPendingRequests()
        }
        
        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            if let errorUnwrapped = error {
                owner?.delegate?.playerItem?(owner!, downloadingFailedWith: errorUnwrapped)
                return
            }
            processPendingRequests()
            print(mediaData!.count)
            print(String(decoding: mediaData!, as: UTF8.self))
            owner?.delegate?.playerItem?(owner!, didFinishDownloadingData: mediaData!)
        }
        
        // MARK: -
        
        func processPendingRequests() {
            
            // get all fullfilled requests
            let requestsFulfilled = Set<AVAssetResourceLoadingRequest>(pendingRequests.compactMap {
                self.fillInContentInformationRequest($0.contentInformationRequest)
                if self.haveEnoughDataToFulfillRequest($0.dataRequest!) {
                    $0.finishLoading()
                    return $0
                }
                return nil
            })
        
            // remove fulfilled requests from pending requests
            _ = requestsFulfilled.map { self.pendingRequests.remove($0) }

        }
        
        func fillInContentInformationRequest(_ contentInformationRequest: AVAssetResourceLoadingContentInformationRequest?) {
            
            // if we play from Data we make no url requests, therefore we have no responses, so we need to fill in contentInformationRequest manually
            if playingFromData {
                contentInformationRequest?.contentType = self.mimeType
                contentInformationRequest?.contentLength = Int64(mediaData!.count)
                contentInformationRequest?.isByteRangeAccessSupported = true
                return
            }
            
            guard let responseUnwrapped = response else {
                // have no response from the server yet
                return
            }
            
            contentInformationRequest?.contentType = responseUnwrapped.mimeType
            contentInformationRequest?.contentLength = responseUnwrapped.expectedContentLength
            contentInformationRequest?.isByteRangeAccessSupported = true
            
        }
        
        func haveEnoughDataToFulfillRequest(_ dataRequest: AVAssetResourceLoadingDataRequest) -> Bool {
            
            let requestedOffset = Int(dataRequest.requestedOffset)
            let requestedLength = dataRequest.requestedLength
            let currentOffset = Int(dataRequest.currentOffset)
            
            guard let songDataUnwrapped = mediaData,
                songDataUnwrapped.count > currentOffset else {
                // Don't have any data at all for this request.
                return false
            }
            
            let bytesToRespond = min(songDataUnwrapped.count - currentOffset, requestedLength)
            let dataToRespond = songDataUnwrapped.subdata(in: Range(uncheckedBounds: (currentOffset, currentOffset + bytesToRespond)))
            dataRequest.respond(with: dataToRespond)
            
            return songDataUnwrapped.count >= requestedLength + requestedOffset
            
        }
        
        deinit {
            session?.invalidateAndCancel()
        }
        
    }
    
    fileprivate let resourceLoaderDelegate = ResourceLoaderDelegate()
    fileprivate let url: URL
    fileprivate let initialScheme: String?
    fileprivate var customFileExtension: String?
    
    weak var delegate: CachingPlayerItemDelegate?
    
    open func download() {
        if resourceLoaderDelegate.session == nil {
            resourceLoaderDelegate.startDataRequest(with: url)
        }
    }
    
    private let cachingPlayerItemScheme = "cachingPlayerItemScheme"
    var item: PlayableV2? = nil
    convenience init(item: PlayableV2){
        
        self.init(url: item.getStreamingURL())
        self.item = item
    }
    
    convenience init(item: PlayableV2, customFileExtension: String?){
        
        self.init(url: item.getStreamingURL(), customFileExtension: customFileExtension)
        self.item = item
    }
    
    /// Is used for playing remote files.
    convenience init(url: URL) {
        self.init(url: url, customFileExtension: nil)
    }
    
    /// Override/append custom file extension to URL path.
    /// This is required for the player to work correctly with the intended file type.
    init(url: URL, customFileExtension: String?) {
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let scheme = components.scheme,
            var urlWithCustomScheme = url.withScheme(cachingPlayerItemScheme) else {
            fatalError("Urls without a scheme are not supported")
        }
        
        self.url = url
        self.initialScheme = scheme
        
        if let ext = customFileExtension {
            urlWithCustomScheme.deletePathExtension()
            urlWithCustomScheme.appendPathExtension(ext)
            self.customFileExtension = ext
        }
        print(url)
//        let asset = AVURLAsset(url: urlWithCustomScheme)
        let headers: [String: String] = [
            "X-Emby-Token": NetworkingManager.shared.accessToken
         ]
        let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers, AVURLAssetPreferPreciseDurationAndTimingKey : true])
        asset.resourceLoader.setDelegate(resourceLoaderDelegate, queue: DispatchQueue.main)
        super.init(asset: asset, automaticallyLoadedAssetKeys: nil)
        
        resourceLoaderDelegate.owner = self
        
        addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playbackStalledHandler), name:NSNotification.Name.AVPlayerItemPlaybackStalled, object: self)
        
    }
    
    /// Is used for playing from Data.
    init(data: Data, mimeType: String, fileExtension: String) {
        
        guard let fakeUrl = URL(string: cachingPlayerItemScheme + "://whatever/file.\(fileExtension)") else {
            fatalError("internal inconsistency")
        }
        
        self.url = fakeUrl
        self.initialScheme = nil
        
        resourceLoaderDelegate.mediaData = data
        resourceLoaderDelegate.playingFromData = true
        resourceLoaderDelegate.mimeType = mimeType
        
        let asset = AVURLAsset(url: fakeUrl)
        asset.resourceLoader.setDelegate(resourceLoaderDelegate, queue: DispatchQueue.main)
        super.init(asset: asset, automaticallyLoadedAssetKeys: nil)
        resourceLoaderDelegate.owner = self
        
        addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playbackStalledHandler), name:NSNotification.Name.AVPlayerItemPlaybackStalled, object: self)
        
    }
    
    // MARK: KVO
    
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        delegate?.playerItemReadyToPlay?(self)
    }
    
    // MARK: Notification hanlers
    
    @objc func playbackStalledHandler() {
        delegate?.playerItemPlaybackStalled?(self)
    }

    // MARK: -
    
    override init(asset: AVAsset, automaticallyLoadedAssetKeys: [String]?) {
        fatalError("not implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        removeObserver(self, forKeyPath: "status")
        resourceLoaderDelegate.session?.invalidateAndCancel()
    }
    
}

class DownloadManager:NSObject {

static var shared = DownloadManager()
private var config: URLSessionConfiguration!
private var downloadSession: AVAssetDownloadURLSession!

override private init() {
    super.init()
    config = URLSessionConfiguration.background(withIdentifier: "\(Bundle.main.bundleIdentifier!).background")
    downloadSession = AVAssetDownloadURLSession(configuration: config, assetDownloadDelegate: self, delegateQueue: OperationQueue.main)
}

func setupAssetDownload(_ url: URL) {
    let options = [AVURLAssetAllowsCellularAccessKey: false]
    let headers: [String: String] = [ "X-Emby-Token": NetworkingManager.shared.accessToken ]
    let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])

    // Create new AVAssetDownloadTask for the desired asset
    let downloadTask = downloadSession.makeAssetDownloadTask(asset: asset,
                                                             assetTitle: "Test Download",
                                                             assetArtworkData: nil,
                                                             options: nil)
    // Start task and begin download
    downloadTask?.resume()
}

func restorePendingDownloads() {
    // Grab all the pending tasks associated with the downloadSession
    downloadSession.getAllTasks { tasksArray in
        // For each task, restore the state in the app
        for task in tasksArray {
            guard let downloadTask = task as? AVAssetDownloadTask else { break }
            // Restore asset, progress indicators, state, etc...
            let asset = downloadTask.urlAsset
            downloadTask.resume()
        }
    }
}

func playOfflineAsset() -> AVURLAsset? {
    guard let assetPath = UserDefaults.standard.value(forKey: "assetPath") as? String else {
        // Present Error: No offline version of this asset available
        return nil
    }
    let baseURL = URL(fileURLWithPath: NSHomeDirectory())
    let assetURL = baseURL.appendingPathComponent(assetPath)
    let asset = AVURLAsset(url: assetURL)
    if let cache = asset.assetCache, cache.isPlayableOffline {
        return asset
        // Set up player item and player and begin playback
    } else {
        return  nil
        // Present Error: No playable version of this asset exists offline
    }
}

func getPath() -> String {
    return UserDefaults.standard.value(forKey: "assetPath") as? String ?? ""
}

func deleteOfflineAsset() {
    do {
        let userDefaults = UserDefaults.standard
        if let assetPath = userDefaults.value(forKey: "assetPath") as? String {
            let baseURL = URL(fileURLWithPath: NSHomeDirectory())
            let assetURL = baseURL.appendingPathComponent(assetPath)
            try FileManager.default.removeItem(at: assetURL)
            userDefaults.removeObject(forKey: "assetPath")
        }
    } catch {
        print("An error occured deleting offline asset: \(error)")
    }
}
}

extension DownloadManager: AVAssetDownloadDelegate {
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange) {
        var percentComplete = 0.0
        // Iterate through the loaded time ranges
        for value in loadedTimeRanges {
        // Unwrap the CMTimeRange from the NSValue
        let loadedTimeRange = value.timeRangeValue
        // Calculate the percentage of the total expected asset duration
        percentComplete += loadedTimeRange.duration.seconds / timeRangeExpectedToLoad.duration.seconds
    }
        percentComplete *= 100

    debugPrint("Progress \( assetDownloadTask) \(percentComplete)")

    let params = ["percent": percentComplete]
    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "completion"), object: nil, userInfo: params)
    // Update UI state: post notification, update KVO state, invoke callback, etc.
}

func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
    // Do not move the asset from the download location
    UserDefaults.standard.set(location.relativePath, forKey: "assetPath")
}

func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
    debugPrint("Download finished: \(location)")
}

func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    debugPrint("Task completed: \(task), error: \(String(describing: error))")

    guard error == nil else { return }
    guard let task = task as? AVAssetDownloadTask else { return }

    print("DOWNLOAD: FINISHED")
}
}
