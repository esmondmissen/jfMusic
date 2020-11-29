//
//  Artist+CoreDataProperties.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 29/9/20.
//
//

import Foundation
import CoreData


extension Artist {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Artist> {
        return NSFetchRequest<Artist>(entityName: "Artist")
    }

    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var sortName: String?
    @NSManaged public var albums: NSSet?
    @NSManaged public var songs: NSSet?
    
    public var hasSongs: Bool {
        let set = songs as? Set<Song> ?? []
        return set.contains(where: { song in song.downloaded && song.album?.albumArtist == self.name})
    }
    
    public var albumsArray: [Album] {
        let set = albums as? Set<Album> ?? []
        
        return set.sorted{
            $0.productionYear < $1.productionYear
        }
    }
    
    public var appearsArray: [Album] {
        let set = songs as? Set<Song> ?? []
        let albumSet = albums as? Set<Album> ?? []
        let appearAlbums = Set(set.map({ $0.album! })).subtracting(albumSet)
        return appearAlbums.sorted{
            $0.productionYear < $1.productionYear
        }
    }
}

// MARK: Generated accessors for albums
extension Artist {

    @objc(addAlbumsObject:)
    @NSManaged public func addToAlbums(_ value: Album)

    @objc(removeAlbumsObject:)
    @NSManaged public func removeFromAlbums(_ value: Album)

    @objc(addAlbums:)
    @NSManaged public func addToAlbums(_ values: NSSet)

    @objc(removeAlbums:)
    @NSManaged public func removeFromAlbums(_ values: NSSet)
    
    @objc(addSongsObject:)
    @NSManaged public func addToSongs(_ value: Song)

    @objc(removeSongsObject:)
    @NSManaged public func removeFromSongs(_ value: Song)

    @objc(addSongs:)
    @NSManaged public func addToSongs(_ values: NSSet)

    @objc(removeSongs:)
    @NSManaged public func removeFromSongs(_ values: NSSet)

}

extension Artist : Identifiable {

}
