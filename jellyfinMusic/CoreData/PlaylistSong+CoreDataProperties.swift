//
//  PlaylistSong+CoreDataProperties.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 11/10/20.
//
//

import Foundation
import CoreData


extension PlaylistSong {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PlaylistSong> {
        return NSFetchRequest<PlaylistSong>(entityName: "PlaylistSong")
    }

    @NSManaged public var playlistItemId: String?
    @NSManaged public var order: Int16
    @NSManaged public var song: Song?
    @NSManaged public var playlist: Playlist?

}

extension PlaylistSong : Identifiable {

}
