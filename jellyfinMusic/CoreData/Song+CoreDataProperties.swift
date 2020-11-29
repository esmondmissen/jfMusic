//
//  Song+CoreDataProperties.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 29/9/20.
//
//

import Foundation
import CoreData


extension Song {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Song> {
        return NSFetchRequest<Song>(entityName: "Song")
    }

    @NSManaged public var name: String?
    @NSManaged public var altName: String?
    @NSManaged public var id: String?
    @NSManaged public var runTime: String?
    @NSManaged public var trackNumber: Int16
    @NSManaged public var diskNumber: Int16
    @NSManaged public var album: Album?
    @NSManaged public var playlists: NSSet?
    @NSManaged public var artists: NSSet?
    @NSManaged public var createDate: Date?
    @NSManaged public var downloaded: Bool
    @NSManaged public var isFavourite: Bool
    

    public var wrappedName: String {
        name ?? "Unknown Song"
    }
    
    public var wrappedNameFeat: String {
        var songName = ""
        if name != nil {
            songName = name!
            
            if featuring != ""{
                songName += " (\(featuring))"
            }
        }
        return songName
    }
    
    public var wrappedaltName: String {
        altName ?? ""
    }
    
    public var wrappedId: String {
        id ?? ""
    }
    
    public var featuring: String {
        let set = artists as? Set<Artist> ?? []
        let feat = set.subtracting(album!.artistsArray)
        if feat.isEmpty{
            return ""
        }
        
        return "\(specialAlbum ? "" : "feat. ") \(feat.map({ $0.name! }).sorted(by: { $0 < $1}).joined(separator: ", "))"
    }
    
    public var artistsArray: [Artist]{
        let set = artists as? Set<Artist> ?? []
        return Array(set)
    }
    
    public var playlistItems: [PlaylistSong]{
        let set = playlists as? Set<PlaylistSong> ?? []
        return Array(set)
    }
    
    private var specialAlbum: Bool {
        return album!.sortArtist == "Various Artists"
    }
    
    public var artistShort: String {
        var artistName = ""
        
        if specialAlbum{
            artistName = featuring
        }else{
            artistName = (album?.albumArtist!)!
        }
        
        return artistName
    }
    
    public var artistLong: String {
        var artistName = artistShort
        
        if !specialAlbum && featuring != ""{
            artistName += " \(featuring)"
        }
        
        return artistName
    }
    
    public var downloadUrl: URL {
        let container = "opus,mp3,aac,m4a,flac,webma,webm,wav,ogg,mpa,wma"
        let bitRate = String(format: "%.0f", NetworkingManager.shared.quality)
        let url = "\(NetworkingManager.shared.server)/Audio/\(self.id!)/main.m3u8?UserId=\(NetworkingManager.shared.userId)&DeviceId=iPhone&MaxStreamingBitrate=\(bitRate)&Container=\(container)&TranscodingProtocol=hls&AudioCodec=aac&SegmentContainer=mpegts&PlaySessionId=\(Int.random(in: 0..<1012345604564302))"
        
        return URL(string: url)!
    }
    
    var song: SongItem {
        get{
            return SongItem(song: self)
        }
    }
    
}

extension Song : Identifiable {
    
    @objc(addPlaylistObject:)
    @NSManaged public func addToPlaylist(_ value: Playlist)

    @objc(removePlaylistObject:)
    @NSManaged public func removeFromPlaylist(_ value: Playlist)

    @objc(addPlaylist:)
    @NSManaged public func addToPlaylist(_ values: NSSet)

    @objc(removePlaylist:)
    @NSManaged public func removeFromPlaylist(_ values: NSSet)
    
}

extension Song {
    func convertToStruct() -> SongViewModel {
        SongViewModel(name: self.name!, artist: self.artistLong, id: self.id!)
    }
}
struct SongViewModel: Identifiable{
    let name, artist, id: String
}
