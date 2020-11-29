//
//  Album+CoreDataClass.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 29/9/20.
//
//

import Foundation
import CoreData

@objc(Album)
public class Album: NSManagedObject {
    
    public func checkDownload(){
        isDownloaded = self.songArray.filter({ $0.downloaded == false}).isEmpty
    }

    @Published var isDownloaded: Bool = false {
        didSet{
            objectWillChange.send()
        }
    }
    
    public var hasDownloads: Bool {
        get{
            return !self.songArray.filter({ $0.downloaded == true}).isEmpty
        }
    }
}
