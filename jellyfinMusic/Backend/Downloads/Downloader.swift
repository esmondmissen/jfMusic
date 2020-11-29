//
//  Downloader.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 24/10/20.
//

import Foundation
import CoreData
import SwiftUI
import HLSion

public class Downloader{
    
    static let shared: Downloader = Downloader()
    private let moc: NSManagedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    public func download(song: Song){
        withAnimation{
            song.downloading = true
        }
            print("Starting")
            let item = HLSion(url: song.downloadUrl, options: [ "AVURLAssetHTTPHeaderFieldsKey" : ["X-Emby-Token": NetworkingManager.shared.accessToken] ], name: song.id!)
            try? item.deleteAsset()
            if item.localUrl == nil {
                item.download { (progressPercentage) in
                    withAnimation{
                        song.progress = CGFloat(progressPercentage)
                    }
                }
                .finish { (relativePath) in
                    withAnimation{
                        song.downloaded = true
                        song.downloading = false
                    }
                    try? self.moc.save()
                    song.album?.checkDownload()
                }.onError { (error) in
                    withAnimation{
                        song.downloading = false
                    }
                    print(error)
                }
            }else{
                withAnimation{
                    song.downloaded = true
                    song.downloading = false
                }
                try? self.moc.save()
                song.album?.checkDownload()
            }
    }
    
    public func deleteDownload(song: Song){
            print("Starting")
            let item = HLSion(url: song.downloadUrl, options: [ "AVURLAssetHTTPHeaderFieldsKey" : ["X-Emby-Token": NetworkingManager.shared.accessToken] ], name: song.id!)

            if item.localUrl != nil {
                
                if ((try? item.deleteAsset()) != nil){
                    withAnimation{
                        song.downloaded = false
                        song.downloading = false
                    }
                    try? self.moc.save()
                    song.album?.checkDownload()
                }
                
            }
    }
}
