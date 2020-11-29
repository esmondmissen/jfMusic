//
//  Playlist+CoreDataClass.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 11/10/20.
//

import Foundation
import CoreData

@objc(Playlist)
public class Playlist: Downloadable {

}


public class Downloadable: NSManagedObject {
    @NSManaged public var songs: NSSet?
}
