//
//  Song+CoreDataClass.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 29/9/20.
//
//

import Foundation
import CoreData
import SwiftUI

@objc(Song)
public class Song: NSManagedObject {
    

    
    @Published public var downloading: Bool = false{
        didSet{
            objectWillChange.send()
        }
    }
    @Published public var progress: CGFloat = 0 {
        didSet{
            objectWillChange.send()
        }
    }
    
    public func download(){
        if !self.downloaded{
            Downloader.shared.download(song: self)
        }
    }
    
    public func removeDownload(){
        Downloader.shared.deleteDownload(song: self)
    }
}
