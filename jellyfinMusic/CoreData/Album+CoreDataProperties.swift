//
//  Album+CoreDataProperties.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 29/9/20.
//
//

import Foundation
import CoreData
import UIKit

extension Album {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Album> {
        return NSFetchRequest<Album>(entityName: "Album")
    }

    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var sortArtist: String?
    @NSManaged public var sortName: String?
    @NSManaged public var albumImage: String?
    @NSManaged public var createdDate: Date?
    @NSManaged public var albumArtist: String?
    @NSManaged public var albumArtists: NSSet?
    @NSManaged public var productionYear: Int16
    @NSManaged public var songs: NSSet?
    @NSManaged public var genres: NSSet?
    @NSManaged public var keepDownloaded: Bool
    @NSManaged public var color1: NSData?
    @NSManaged public var color2: NSData?

    public var wrappedProductionYear: String{
        if productionYear != 0{
            return "\(productionYear)"
        }
        return ""
    }

    public var wrappedName: String {
        name ?? "Unknown Album"
    }
    
    public var wrappedId: String {
        id ?? ""
    }
    
//    public var wrappedDate: String{
//        createdDate ?? ""
//    }
    
    public var wrappedGenres: String{
        let set = genres as? Set<Genre> ?? []
        return set.filter{ $0.name != nil && $0.name != ""}.map{ $0.name! }.sorted(by: { $0 < $1 }).joined(separator: ", ")
    }
    
    public var artistsArray: [Artist] {
        let set = albumArtists as? Set<Artist> ?? []
        
        return set.sorted{
            $0.name ?? "" < $1.name ?? ""
        }
    }
    
    public var songArray: [Song] {
        let set = songs as? Set<Song> ?? []
        
        return set.sorted{
            $0.wrappedName < $1.wrappedName
        }
    }
    
    public var genreArray: [Genre] {
        let set = genres as? Set<Genre> ?? []
        
        return set.sorted{
            $0.wrappedName < $1.wrappedName
        }
    }
}

// MARK: Generated accessors for albumArtists
extension Album {

    @objc(addAlbumArtistsObject:)
    @NSManaged public func addToAlbumArtists(_ value: Artist)

    @objc(removeAlbumArtistsObject:)
    @NSManaged public func removeFromAlbumArtists(_ value: Artist)

    @objc(addAlbumArtists:)
    @NSManaged public func addToAlbumArtists(_ values: NSSet)

    @objc(removeAlbumArtists:)
    @NSManaged public func removeFromAlbumArtists(_ values: NSSet)

}

// MARK: Generated accessors for genres
extension Album {

    @objc(addGenresObject:)
    @NSManaged public func addToGenres(_ value: Genre)

    @objc(removeGenresObject:)
    @NSManaged public func removeFromGenres(_ value: Genre)

    @objc(addGenres:)
    @NSManaged public func addToGenres(_ values: NSSet)

    @objc(removeGenres:)
    @NSManaged public func removeFromGenres(_ values: NSSet)

}

// MARK: Generated accessors for songs
extension Album {

    @objc(addSongsObject:)
    @NSManaged public func addToSongs(_ value: Song)

    @objc(removeSongsObject:)
    @NSManaged public func removeFromSongs(_ value: Song)

    @objc(addSongs:)
    @NSManaged public func addToSongs(_ values: NSSet)

    @objc(removeSongs:)
    @NSManaged public func removeFromSongs(_ values: NSSet)

}

extension Album {
    func convertToStruct() -> AlbumViewModel {
        AlbumViewModel(
            name: self.name!,
            albumArtist: self.albumArtist!,
            id: self.id!,
            genre: self.wrappedGenres,
            productionYear: Int(self.productionYear),
            songs: Array(self.songArray.map{ $0.convertToStruct() })
        )
    }
}


struct AlbumViewModel: Identifiable {
    let name, albumArtist, id, genre: String
    let productionYear: Int?
    let songs: [SongViewModel]
}
