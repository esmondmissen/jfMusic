//
//  Genre+CoreDataProperties.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 1/10/20.
//
//

import Foundation
import CoreData


extension Genre {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Genre> {
        return NSFetchRequest<Genre>(entityName: "Genre")
    }

    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var albums: NSSet?

    public var wrappedName: String {
        name ?? ""
    }
}

// MARK: Generated accessors for albums
extension Genre {

    @objc(addAlbumsObject:)
    @NSManaged public func addToAlbums(_ value: Album)

    @objc(removeAlbumsObject:)
    @NSManaged public func removeFromAlbums(_ value: Album)

    @objc(addAlbums:)
    @NSManaged public func addToAlbums(_ values: NSSet)

    @objc(removeAlbums:)
    @NSManaged public func removeFromAlbums(_ values: NSSet)

}

extension Genre : Identifiable {

}
