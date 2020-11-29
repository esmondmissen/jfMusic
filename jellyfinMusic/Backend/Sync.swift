//
//  Sync.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 19/10/20.
//

import Foundation
import SwiftUI
import CoreData
import Cache

class AsyncOperation: Operation {
    private var batch: [SongItem]
    
    init(batch: [SongItem]) {
        self.batch = batch
    }
    
    private let lockQueue = DispatchQueue(label: "sync.music.asyncoperation", attributes: .concurrent)
    
    override var isAsynchronous: Bool {
        return true
    }

    private var _isExecuting: Bool = false
    override private(set) var isExecuting: Bool {
        get {
            return lockQueue.sync { () -> Bool in
                return _isExecuting
            }
        }
        set {
            willChangeValue(forKey: "isExecuting")
            lockQueue.sync(flags: [.barrier]) {
                _isExecuting = newValue
            }
            didChangeValue(forKey: "isExecuting")
        }
    }

    private var _isFinished: Bool = false
    override private(set) var isFinished: Bool {
        get {
            return lockQueue.sync { () -> Bool in
                return _isFinished
            }
        }
        set {
            willChangeValue(forKey: "isFinished")
            lockQueue.sync(flags: [.barrier]) {
                _isFinished = newValue
            }
            didChangeValue(forKey: "isFinished")
        }
    }

    override func start() {
            guard !isCancelled else {
                finish()
                return
            }
        
            isFinished = false
            isExecuting = true
            main()
        }

        override func main() {
                var moc: NSManagedObjectContext? = nil
                DispatchQueue.main.sync {
                    moc = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
                }
            
                let privateMOC = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
                privateMOC.parent = moc!
                privateMOC.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                privateMOC.automaticallyMergesChangesFromParent = true
                privateMOC.perform { [self] in
                    
//                let deleteSongsRequest: NSFetchRequest<Song> = Song.fetchRequest()
//                    deleteSongsRequest.predicate = NSPredicate(format:"NOT (id IN %@)", allSongs.map{ $0.id })
//                do {
//                    let deletedSongs = try privateMOC.fetch(deleteSongsRequest)
//                    for song in deletedSongs{
//                        privateMOC.delete(song)
//                    }
//                    self.saveContext(forContext: privateMOC)
//                } catch{}
//
//                    let deleteAlbumsRequest: NSFetchRequest<Album> = Album.fetchRequest()
//                    deleteAlbumsRequest.predicate = NSPredicate(format:"songs.@count == 0")
//                    do {
//                        let deletedAlbums = try privateMOC.fetch(deleteAlbumsRequest)
//                        for album in deletedAlbums{
//                            privateMOC.delete(album)
//                        }
//                        self.saveContext(forContext: privateMOC)
//                    } catch{}
                    
                    let isoDateFormatter = ISO8601DateFormatter()
                    isoDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                    isoDateFormatter.formatOptions = [
                        .withFullDate,
                        .withFullTime,
                        .withDashSeparatorInDate,
                        .withFractionalSeconds]

                    if !batch.isEmpty{
                        guard !isCancelled else {
                                finish()
                                return
                            }
                        let albums = Dictionary(grouping: batch, by: { $0.albumID})
                        for groupedAlbum in albums{
                            let albumrequest: NSFetchRequest<Album> = Album.fetchRequest()
                            let albumPredicate = NSPredicate(format: "id = %@", groupedAlbum.value.first!.albumID)
                            albumrequest.predicate = albumPredicate
                            
                            do {
                                var album: Album? = nil
                                let existingAlbum = try privateMOC.fetch(albumrequest)
                                if existingAlbum.count > 0{
                                    album = existingAlbum[0]
                                }else{
                                    album = Album(context: privateMOC)
                                }
                                album!.name = groupedAlbum.value.first!.album
                                album!.id = groupedAlbum.value.first!.albumID
                                album!.albumArtist = groupedAlbum.value.first!.albumArtist
                                album!.albumImage = groupedAlbum.value.first!.albumPrimaryImageTag
                                album!.sortArtist = groupedAlbum.value.first!.albumArtist.replacingOccurrences(of: "The ", with: "")
                                album!.createdDate = album?.createdDate == nil ? getDate(groupedAlbum.value.first!.dateCreated) : getDate(groupedAlbum.value.first!.dateCreated)! > album!.createdDate! ? getDate(groupedAlbum.value.first!.dateCreated) : album?.createdDate
                                album!.productionYear = Int16(groupedAlbum.value.first!.productionYear ?? 0)
                                
                                let genres = Set(groupedAlbum.value.flatMap({ $0.genreItems }))
                                 //Delete existing genres that are not in the new data array
                                for existingGenre in album!.genreArray{
                                    if genres.filter({ $0.id == existingGenre.id}).isEmpty{
                                        privateMOC.delete(existingGenre)
                                    }
                                }
                                
                                for genre in genres{
                                    let grequest: NSFetchRequest<Genre> = Genre.fetchRequest()
                                    let predicate = NSPredicate(format: "id = %@", genre.id)
                                    grequest.predicate = predicate
                                       do {
                                          let existingGenres = try privateMOC.fetch(grequest)
                                        if existingGenres.count > 0{
                                            existingGenres[0].addToAlbums(album!)
                                        }else{
                                            let newGenre = Genre(context: privateMOC)
                                            newGenre.name = genre.name
                                            newGenre.id = genre.id
                                            newGenre.addToAlbums(album!)
                                        }
                                       } catch { }
                                }
                                
                                let albumArtists = Set(groupedAlbum.value.flatMap({ $0.albumArtists }))
                                
                                for artist in albumArtists{
                                    let arequest: NSFetchRequest<Artist> = Artist.fetchRequest()
                                    let predicate = NSPredicate(format: "id = %@", artist.id)
                                    arequest.predicate = predicate
                                       do {
                                          let existingArtist = try privateMOC.fetch(arequest)
                                        if existingArtist.count > 0{
                                            existingArtist[0].sortName = artist.name.replacingOccurrences(of: "The ", with: "")
                                            existingArtist[0].addToAlbums(album!)
                                        }else{
                                            let newArtist = Artist(context: privateMOC)
                                            newArtist.sortName = artist.name.replacingOccurrences(of: "The ", with: "")
                                            newArtist.name = artist.name
                                            newArtist.id = artist.id
                                            newArtist.addToAlbums(album!)
                                        }
                                       } catch { }
                                }
                                for song in groupedAlbum.value{
                                    let songRequest: NSFetchRequest<Song> = Song.fetchRequest()
                                    let predicate = NSPredicate(format: "id = %@", song.id)
                                    songRequest.predicate = predicate
                                        do {
                                            var songItem: Song? = nil
                                            let existingSong = try privateMOC.fetch(songRequest)
                                            if existingSong.count > 0{
                                                songItem = existingSong[0]
                                            }else{
                                                songItem = Song(context: privateMOC)
                                            }
                                            
                                            songItem!.name = song.name
                                            songItem!.altName = song.name.replacingOccurrences(of: "\\s?\\([\\w\\s]*\\)", with: "", options: .regularExpression)
                                            songItem!.id = song.id
                                            songItem!.trackNumber = Int16(song.indexNumber ?? 0)
                                            songItem!.diskNumber = Int16(song.parentIndexNumber ?? 0)
                                            songItem!.createDate = isoDateFormatter.date(from: song.dateCreated)
                                            songItem!.runTime = getRuntime(ticks: song.runTimeTicks!)
                                            songItem!.isFavourite = song.userData.isFavorite
                                            
                                            for artist in song.artistItems{
                                                let arequest: NSFetchRequest<Artist> = Artist.fetchRequest()
                                                let predicate = NSPredicate(format: "id = %@", artist.id)
                                                arequest.predicate = predicate
                                                   do {
                                                      let existingArtist = try privateMOC.fetch(arequest)
                                                    if existingArtist.count > 0{
                                                        existingArtist[0].sortName = artist.name.replacingOccurrences(of: "The ", with: "")
                                                        existingArtist[0].addToSongs(songItem!)
                                                    }else{
                                                        let newArtist = Artist(context: privateMOC)
                                                        newArtist.sortName = artist.name.replacingOccurrences(of: "The ", with: "")
                                                        newArtist.name = artist.name
                                                        newArtist.id = artist.id
                                                        newArtist.addToSongs(songItem!)
                                                    }
                                                   } catch { }
                                            }
                                            
                                            songItem!.album = album!
                                            
                                       } catch { }
                                }
                            } catch { }
                            self.saveContext(forContext: privateMOC)   
                        }
                    }
                    
                    try? moc!.save()
                    
                    self.finish()
            }
        }

    func finish() {
        isExecuting = false
        isFinished = true
    }
    
    private func saveContext(forContext context: NSManagedObjectContext) {
        if context.hasChanges {
            context.performAndWait {
                do {
                    try context.save()
                } catch {
                    let nserror = error as NSError
                    print("Error when saving !!! \(nserror.localizedDescription)")
                    print("Callstack :")
                    for symbol: String in Thread.callStackSymbols {
                        print(" > \(symbol)")
                    }
                }
            }
        }
    }
}
