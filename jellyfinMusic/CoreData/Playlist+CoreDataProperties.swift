//
//  Playlist+CoreDataProperties.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 11/10/20.
//

import Foundation
import CoreData


extension Playlist {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Playlist> {
        return NSFetchRequest<Playlist>(entityName: "Playlist")
    }

    @NSManaged public var name: String?
    @NSManaged public var id: String?
    @NSManaged public var overview: String?
    @NSManaged public var sortName: String?
    @NSManaged public var keepDownloaded: Bool

    public var playlistSongArray: [PlaylistSong] {
        let set = songs as? Set<PlaylistSong> ?? []
        return Array(set)
    }
    
    public var songArray: [Song] {
        let set = songs as? Set<PlaylistSong> ?? []

        return set.sorted{
            $0.order < $1.order
        }.map{ $0.song! }
    }    
}

extension Playlist : Identifiable {
    @objc(addPlaylistSongsObject:)
    @NSManaged public func addToPlaylistSongs(_ value: PlaylistSong)

    @objc(removePlaylistSongsObject:)
    @NSManaged public func removeFromPlaylistSongs(_ value: PlaylistSong)

    @objc(addPlaylistSong:)
    @NSManaged public func addToPlaylistSong(_ values: NSSet)

    @objc(removePlaylistSong:)
    @NSManaged public func removeFromPlaylistSong(_ values: NSSet)
}
