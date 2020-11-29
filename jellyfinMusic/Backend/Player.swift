//
//  Player.swift
//  jFin
//
//  Created by Esmond Missen on 31/7/20.
//

import Foundation
import SwiftUI
import Combine
import AVFoundation
import MediaPlayer
import SDWebImage
import UIImageColors
import Cache
import HLSion

public class Globals{
    public static let playTimeInterval: Double = 1
    public static let componentOpacity: Double = 0.7
    public static let colorLow: Color = Color(Color.RGBColorSpace.displayP3, white: (0.35), opacity: 1)
    public static let colorMed: Color = Color(Color.RGBColorSpace.displayP3, white: (0.7), opacity: 1)
    public static let colorFull: Color = Color(Color.RGBColorSpace.displayP3, white: (1), opacity: 1)
}

open class AVPlayerItemId: AVPlayerItem, Identifiable{
    public let id = UUID().uuidString
    public var initialOrder: Int
    public let song: Song
    public let playSessionId: String
    
    init(song: Song, localAsset: AVURLAsset, order: Int){
        self.playSessionId = "\(Double.random(in: 0..<1496213367201))".replacingOccurrences(of: ".", with: "")
        self.song = song
        self.initialOrder = order
        super.init(asset: localAsset, automaticallyLoadedAssetKeys: nil)
    }
    
    init(song: Song, order: Int){
        let seshId = "\(Double.random(in: 0..<1496213367201))".replacingOccurrences(of: ".", with: "")
        self.playSessionId = seshId
        self.song = song
        self.initialOrder = order
        let headers: [String: String] = [ "X-Emby-Token": NetworkingManager.shared.accessToken ]
        let assetItem = AVURLAsset(url: AVPlayerItemId.getStream(songId: song.id!, sessionId: seshId), options: ["AVURLAssetHTTPHeaderFieldsKey": headers, AVURLAssetPreferPreciseDurationAndTimingKey : true])
        super.init(asset: assetItem, automaticallyLoadedAssetKeys: nil)
    }
    
    private static func getStream(songId: String, sessionId: String) -> URL{
        let container = "opus,mp3,aac,m4a,flac,webma,webm,wav,ogg,mpa,wma"
        let bitRate = String(format: "%.0f", NetworkingManager.shared.quality)

        return URL(string: "\(NetworkingManager.shared.server)/Audio/\(songId)/main.m3u8?UserId=\(NetworkingManager.shared.userId)&DeviceId=iPhone&MaxStreamingBitrate=\(bitRate)&Container=\(container)&TranscodingProtocol=hls&AudioCodec=aac&PlaySessionId=\(sessionId)&SegmentContainer=mpegts")!
    }
}

public struct From{
    let name: String
    let id: String
    let type: parentType
}

public enum parentType{
    case album, playlist, allSongs, topSongs, artist
}

class Player: ObservableObject {

    static let shared = Player()
    let session = AVAudioSession.sharedInstance()
    
    public enum PlayMode {
        case random, ordered
        
        mutating public func toggle() {
            switch self {
            case .random:
                self = .ordered
            case .ordered:
                self = .random
            }
        }
    }
    
    public enum RepeatMode {
        case none, reapeatAll, repeatOne
        
        mutating public func toggle() {
            switch self {
            case .none:
                self = .reapeatAll
            case .reapeatAll:
                self = .repeatOne
            case .repeatOne:
                self = .none
            }
        }
    }
    
    @Published public var songs: [AVPlayerItemId] = [] {
        didSet {
            if player != nil {
                if let current = player?.currentItem{
                    for queuedItem in player?.items() ?? []{
                        if queuedItem != current || !isPlaying{
                            player?.remove(queuedItem)
                        }
                    }
                    songIndex = songs.firstIndex(where: {(current as! AVPlayerItemId).song.id == $0.song.id}) ?? 0
                    for song in songs[(currentSong != nil ? (songIndex + 1) : songIndex)...]{
                        player!.insert(song, after: nil)
                    }
                }else{
                    player?.removeAllItems()
                    player = AVQueuePlayer(items: Array(songs[songIndex...].map{ self.toPlayerItem($0.song, order: $0.initialOrder) }))
                }
                currentSong = songs[songIndex]
            }else if !songs.isEmpty{
                player = AVQueuePlayer(items: songs)
                player?.preventsDisplaySleepDuringVideoPlayback = false
                currentSong = songs[songIndex]
                setupBackgroundPlay()
            }
        }
    }
    
    @Published public var history: [AVPlayerItemId] = [] {
        didSet{
            if history.count > 100{
                history.removeFirst(-100 + history.count)
            }
        }
    }
    
    public func removeSong(song: AVPlayerItemId){
        player?.remove(song)
        let index = Player.shared.songs.sorted{ $0.initialOrder < $1.initialOrder }.firstIndex(of: song)!
        songs.remove(at: index)
        if songs.count >= index{
            for nextSong in songs.sorted(by: { $0.initialOrder < $1.initialOrder })[index...]{
                nextSong.initialOrder += -1
            }
        }
    }
    
    @Published public var currentSong: AVPlayerItemId?
    {
        didSet {
            duration = currentSong?.song.runTime ?? "0:00"
            timeElasped = "0:00"
        }
    }
    public var songIndex: Int = 0
    private let placeholderImage = UIImage(named: "Placeholder")!
    @Published public var currentSongImage: UIImage = UIImage(named: "Placeholder")! {
        didSet{
            currentSongImage.getColors { colors in
                if colors != nil && self.currentSongImage != self.placeholderImage {
                    self.colors = colors!
                    let temp: [UIColor] = [colors!.background!, colors!.detail!, colors!.primary!, colors!.secondary!]
                        .sorted{ $0.getColorDifference() < $1.getColorDifference() }
                    self.color = Color(temp[Int.random(in: 1...2)])
                }
              }
        }
    }
    
    @Published public var isPlaying = false {
        didSet {
            if isPlaying {
                setupBackgroundPlay()
            }
            
            isPlaying ? player?.play() : player?.pause()
            setupPlayTimer()
            MPNowPlayingInfoCenter.default().playbackState = isPlaying ? .playing : .paused
        }
    }
    @Published public var color: Color = .purple
    @Published public var colors: UIImageColors = UIImageColors(background: .black, primary: .red, secondary: .purple, detail: .blue)
    @Published public var playmode = PlayMode.ordered {
        didSet{
                // order or shuffle the songs
                var newOrder = playmode == .random ? self.songs.shuffled() : self.songs.sorted(by: { $0.initialOrder < $1.initialOrder})
                if currentSong != nil{
                    if playmode == .random {
                        self.songIndex = 0
                        // place the currently playing song at 0
                        newOrder.move(currentSong!, to: 0)
                    }else{
                        self.songIndex = currentSong!.initialOrder
                        print(self.songIndex)
                    }
                    self.currentSong = player?.currentItem as? AVPlayerItemId
                }
                self.songs = newOrder
        }
    }
    @Published public var repeatMode = RepeatMode.none
    @Published public var duration = "0:00"
    @Published public var timeElasped = "0:00"
    @Published public var playProgress: Float = 0
    @Published public var playProgressAhead: Float = 0
    @Published public var trigger: Bool = false
    @Published public var seeking: Bool = false {
        didSet{
            if !seeking{
                refreshPlayingInfo()
            }
        }
    }
    
    private var player: AVQueuePlayer?
    private var timeTimer: Timer?
    @Published public var animationTimer = Timer.publish(every: 9, on: .main, in: .common).autoconnect()
    init() {
        let nc = NotificationCenter.default
        nc.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                               object: player?.currentItem,
                                               queue: .main) { [weak self] _ in
                                                guard let self = self else { return }
                                                switch self.playmode {
                                                case .random:
                                                    self.currentSong = self.songs.randomElement()
                                                    self.isPlaying = true
                                                case .ordered:
                                                    // scheduleNext check repeat1 mode
                                                    self.scheduleNext()
                                                }
        }
        
        nc.addObserver(self,
                           selector: #selector(handleInterruption),
                           name: AVAudioSession.interruptionNotification,
                           object: player?.currentItem)
        
        self.setupRemoteCommands()
    }
    
    @objc func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
        }

        // Switch over the interruption type.
        switch type {

        case .began:
            print("Interuption began")
            isPlaying = false
            
        case .ended:
            print("Interuption ended")
           // An interruption ended. Resume playback, if appropriate.

            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                // Interruption ended. Playback should resume.
                print("Should resume")
            }else{
                if let time = player?.currentTime(), player?.currentItem != nil{
                    self.player?.removeAllItems()
                    self.currentSong = nil
                    self.songs.append(contentsOf: [])
                    player?.seek(to: time)
                    print("seeked to \(time)")
                }
            }
        default: ()
        }
    }
    
    private func addToHistory() -> Void {
        if currentSong != nil && history.last?.song.id != currentSong!.song.id{
            history.insert(currentSong!, at: history.count)
        }
    }

    public func loadSongs(_ songs: [Song], songId: String? = nil){

        addToHistory()
        
        self.isPlaying = false
        self.currentSong = nil
        let queueItems = songs.enumerated().map { (index, element) in
            return toPlayerItem(element, order: index)
        }
        
        // Order of the following operations are important
        player = player ?? AVQueuePlayer()
        player?.preventsDisplaySleepDuringVideoPlayback = false
        player?.removeAllItems()
        songIndex = songs.firstIndex(where: { $0.id == songId}) ?? 0
        self.songs = queueItems
    }
    
    private func toPlayerItem(_ song : Song, order: Int) -> AVPlayerItemId{
        // See if the item is marked as downloaded
        if song.downloaded{
            let hlsion = HLSion(url: song.downloadUrl, name: song.id!)
            if let localUrl = hlsion.localUrl{
                let localAsset = AVURLAsset(url: localUrl)
                return AVPlayerItemId(song: song, localAsset: localAsset, order: order)

            }
            song.downloaded = false
            //TODO save this change
        }
        //Fallback to streaming or cache if we reach here
        return AVPlayerItemId(song: song, order: order)
    }
    
    public func appendSongsNext(_ songs: [Song]){
        var index = -1
        if currentSong != nil{
            index = self.songs.sorted{ $0.initialOrder < $1.initialOrder }.firstIndex(of: currentSong!)!
        }
        
        let songItems = songs.enumerated().map { (orderIndex, element) in
            return toPlayerItem(element, order: orderIndex + index + 1)
        }
        for song in self.songs.sorted(by: { $0.initialOrder < $1.initialOrder })[(index + 1)...]{
            song.initialOrder += songs.count
        }
        self.songs.insert(contentsOf: songItems, at: index + 1)
        print(self.songs.map({ $0.song.name! + " - \($0.initialOrder)"}))
    }

    public func appendSongsEnd(_ songs: [Song]){
        self.songs.append(contentsOf: songs.enumerated().map { (index, element) in
            return toPlayerItem(element, order: index + self.songs.count)
        })
    }

    public func scheduleNext() {
        changeSong(newIndex: repeatMode == .repeatOne ? 0 : 1)
    }
    
    public func next() {
        changeSong(newIndex: 1)
    }
    
    public func next(song: AVPlayerItemId) {
        changeSong(newIndex: songs.firstIndex(of: song)! - songIndex)
    }
    
    public func previous() {
        if timeElasped < "0:02"{
            changeSong(newIndex: -1)
        }else{
            seek(progress: 0.0)
        }
    }
    
    private func changeSong(newIndex: Int, skipping: Bool = false) {
            playProgressAhead = 0
            playProgress = 0
        
            guard let current = currentSong,
                  var index = songs.firstIndex(where: { $0.id == current.id } ) else {
                    return
            }
            if !skipping{
                addToHistory()
            }
            index += newIndex
            if index < songs.count {
                let newSong = songs[index]
                currentSong = newSong
                songIndex = index
                if newIndex > 0 {
                    // Going foward
                    for _ in 1...newIndex {
                        player?.advanceToNextItem()
                    }
                }else if newIndex < 0 {
                    player?.insert(newSong, after: player?.currentItem)
                    let currentItem = player?.currentItem
                    player?.advanceToNextItem()
                    if currentItem != nil{
                        player?.insert(currentItem!, after: player?.currentItem)
                    }
                }else if repeatMode == .repeatOne{
//                    self.appendSongsNext([newSong.song])
//                    player?.advanceToNextItem()
                }
            }else{
                songIndex = 0
                isPlaying = false
                if songs.count > 0{
                    self.loadSongs(songs.map{ $0.song })
                    if repeatMode == .reapeatAll{
                        self.isPlaying = true
                    }
                }
            }
        setupBackgroundPlay()
    }
    
    private func setupRemoteCommands() {
        MPRemoteCommandCenter.shared().playCommand.addTarget { [weak self] event in
            if self?.isPlaying == false {
                self?.isPlaying = true
                return .success
            }
            return .commandFailed
        }

        MPRemoteCommandCenter.shared().pauseCommand.addTarget { [weak self] event in
            if self?.isPlaying == true {
                self?.isPlaying = false
                return .success
            }
            return .commandFailed
        }
        
        MPRemoteCommandCenter.shared().nextTrackCommand.addTarget { [weak self] event in
            self?.next()
            return .success
        }
        
        MPRemoteCommandCenter.shared().previousTrackCommand.addTarget { [weak self] event in
            self?.previous()
            return .success
        }
    }
    
    private func setupBackgroundPlay() {
        if let currentItem = currentSong {
            do {
                try session.setCategory(AVAudioSession.Category.playback, options: [])
                try session.setActive(true, options: [])
            } catch {
                print("Failed to set session active")
            }
            UIApplication.shared.beginReceivingRemoteControlEvents()
            
            SDWebImageDownloader.shared.downloadImage(with:
                                                        jfApiService.songImage(
                                                            id: (currentItem.song.album?.id!)!, maxSize: 500))
            { [weak self] (image, _, _, _) in
                if let image = image {
                    if self?.currentSongImage.pngData() != image.pngData(){
                        self?.currentSongImage = image
                    }
                }else{
                    self?.currentSongImage = self!.placeholderImage
                }
                
                    let info: [String: Any] =
                        [MPMediaItemPropertyArtist: currentItem.song.album?.albumArtist ?? "",
                         MPMediaItemPropertyAlbumTitle: currentItem.song.album?.name ?? "",
                         MPMediaItemPropertyTitle: currentItem.song.name!,
                         MPMediaItemPropertyArtwork: MPMediaItemArtwork(boundsSize: CGSize(width: 500, height: 500),
                                                                        requestHandler: { (size: CGSize) -> UIImage in
                                                                            return (self?.currentSongImage)!
                         })]
                    MPNowPlayingInfoCenter.default().playbackState = self?.isPlaying ?? false ? MPNowPlayingPlaybackState.playing : .paused
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = info
                
            }
            
        }else{
            self.isPlaying = false
        }
    }
    
    private func setupPlayTimer() {
        if isPlaying {
            if timeTimer != nil {
                timeTimer?.invalidate()
                timeTimer = nil
            }
            timeTimer = Timer.scheduledTimer(withTimeInterval: Globals.playTimeInterval,
                                             repeats: true,
                                             block:
                { [weak self] timer in
                    self?.refreshPlayingInfo()
                })
        } else {
            timeTimer?.invalidate()
            timeTimer = nil
        }
    }
    
    
    public func getRemainingTime() -> Double{
        if let duration = player?.currentItem?.duration.seconds,
           let playTime = player?.currentItem?.currentTime().seconds,
           !duration.isNaN, !playTime.isNaN{
            
            return duration - playTime - 0.1
        }
        return Double(0)
    }
    
    public func setTimeElapsed(progress: Double){
        if let duration = player?.currentItem?.duration.seconds{
            let playTimeSecs = Int(duration * progress)
            let playTimeSeconds = Int(playTimeSecs % 3600) % 60
            let playTimeMinutes = Int(playTimeSecs % 3600) / 60
            let timeElapsedString = "\(playTimeMinutes):\(String(format: "%02d", playTimeSeconds))"
            self.timeElasped = timeElapsedString
            
            if(self.player != nil && self.player!.status == AVPlayer.Status.readyToPlay && self.player!.currentItem!.status == AVPlayerItem.Status.readyToPlay) {
                self.playProgress = Float(progress)
                self.playProgressAhead = Float(progress)
            }else{
                self.playProgress = 0
                self.playProgressAhead = 0
            }
            self.trigger = false
        }
    }
    
    public func seek(progress: Double){
        if let duration = player?.currentItem?.duration.seconds {
            let playTimeSecs = Double(duration * progress)
            self.player?.seek(to: CMTime(seconds: playTimeSecs, preferredTimescale: 1), completionHandler: { _ in
                self.playProgressAhead = Float(progress)
                self.seeking = false
                self.trigger = true
            })
        }else{
            self.seeking = false
        }
    }
    
    private func refreshPlayingInfo() {
        if !seeking, let duration = player?.currentItem?.duration.seconds,
            let playTime = player?.currentItem?.currentTime().seconds,
            !duration.isNaN, !playTime.isNaN {
            let durationSecs = Int(duration)
            let durationSeconds = Int(durationSecs % 3600 ) % 60
            let durationMinutes = Int(durationSecs % 3600) / 60
            let durationString = "\(durationMinutes):\(String(format: "%02d", durationSeconds))"
            self.duration = durationString
            
            let playTimeSecs = Int(playTime)
            let playTimeSeconds = Int(playTimeSecs % 3600) % 60
            let playTimeMinutes = Int(playTimeSecs % 3600) / 60
            let timeElapsedString = "\(playTimeMinutes):\(String(format: "%02d", playTimeSeconds))"
            self.timeElasped = timeElapsedString
            
            if(self.player != nil && self.player!.status == AVPlayer.Status.readyToPlay && self.player!.currentItem!.status == AVPlayerItem.Status.readyToPlay) {
                self.playProgress = Float(playTime) / Float(duration)
                self.playProgressAhead = Float(playTime + Globals.playTimeInterval) / Float(duration)
            }else{
                self.playProgress = 0
                self.playProgressAhead = 0
            }
            self.trigger = false

            var infos = MPNowPlayingInfoCenter.default().nowPlayingInfo
            infos?[MPMediaItemPropertyPlaybackDuration] = duration
            infos?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = playTime
            MPNowPlayingInfoCenter.default().nowPlayingInfo = infos
        }
    }
}

extension Array where Element: Equatable
{
    mutating func move(_ element: Element, to newIndex: Index) {
        if let oldIndex: Int = self.firstIndex(of: element) { self.move(from: oldIndex, to: newIndex) }
    }
}

extension Array
{
    mutating func move(from oldIndex: Index, to newIndex: Index) {
        // Don't work for free and use swap when indices are next to each other - this
        // won't rebuild array and will be super efficient.
        if oldIndex == newIndex { return }
        if abs(newIndex - oldIndex) == 1 { return self.swapAt(oldIndex, newIndex) }
        self.insert(self.remove(at: oldIndex), at: newIndex)
    }
}
