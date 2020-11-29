//
//  User+CoreDataProperties.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 15/10/20.
//
//

import Foundation
import CoreData


extension User {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User")
    }

    @NSManaged public var userId: String?
    @NSManaged public var serverId: String?
    @NSManaged public var authToken: String?
    @NSManaged public var server: String?
    @NSManaged public var playlistLibraryId: String?
    @NSManaged public var musicLibraryId: String?

}

extension User : Identifiable {

}
