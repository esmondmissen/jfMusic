//
//  NetworkManager.swift
//  jFin
//
//  Created by Esmond Missen on 27/7/20.
//

import Foundation
import SwiftUI
import Alamofire
import CoreData
import Cache
import UserNotifications
import Network
import AVFoundation

class NetworkingManager: ObservableObject{
    
    static let shared = NetworkingManager()
    let monitor = NWPathMonitor()
    public var session:Session

    let moc: NSManagedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    //Caching
    let diskConfig = DiskConfig(name: "JsonDiskCache")
    let memoryConfig = MemoryConfig(expiry: .never, countLimit: 1000, totalCostLimit: 1000)
    lazy var storage: Cache.Storage? = {
        return try? Cache.Storage<String, NetworkingManager.TopSongsResult>(diskConfig: diskConfig, memoryConfig: memoryConfig, transformer: TransformerFactory.forCodable(ofType: TopSongsResult.self))
    }()
    lazy var genericStorage: Cache.Storage? = {
        return try? Cache.Storage<String, [GenericItem]>(diskConfig: diskConfig, memoryConfig: memoryConfig, transformer: TransformerFactory.forCodable(ofType: [GenericItem].self))
    }()
    
    lazy var songItemStorage: Cache.Storage? = {
        return try? Cache.Storage<String, [SongItem]>(diskConfig: diskConfig, memoryConfig: memoryConfig, transformer: TransformerFactory.forCodable(ofType: [SongItem].self))
    }()
    
    @Published var authenticated:Bool = UserDefaults.standard.bool(forKey: "Authenticated")
    @Published var loaded:Bool = false
    @Published var syncing:Bool = false
    @Published var complete: Int = 0
    @Published var total: Int = 0
    @Published var online: Bool = true

    var quality: Double = UserDefaults.standard.double(forKey: "Quality"){
        didSet{
            UserDefaults.standard.set(quality, forKey: "Quality")
        }
    }
    
    private var _server: String = "" {
        didSet{
            let manager = ServerTrustManager(evaluators: [_server.replacingOccurrences(of: "http://", with: "").replacingOccurrences(of: "https://", with: ""): DisabledTrustEvaluator(), "jfinwebscrape.azurewebsites.net": DisabledTrustEvaluator()])
            session = Session(serverTrustManager: manager)
        }
    }
    var server: String {
        if _server != ""{
            return _server
        }
        let userRequest: NSFetchRequest<User> = User.fetchRequest()
        do {
            let users = try moc.fetch(userRequest)
            if users.isEmpty{
                return ""
            }else{
                _server = users[0].server!
                return users[0].server!
            }
        }catch{
            return ""
        }
    }
    
    private var _accessToken: String = ""
    var accessToken: String {
        if _accessToken != ""{
            return _accessToken
        }
        let userRequest: NSFetchRequest<User> = User.fetchRequest()
        do {
            let users = try moc.fetch(userRequest)
            if users.isEmpty{
                return ""
            }else{
                _accessToken = users[0].authToken!
                return users[0].authToken!
            }
        }catch{
            return ""
        }
    }
    
    private var _userId: String = ""
    var userId: String {
        if _userId != "" {
            return _userId
        }
        let userRequest: NSFetchRequest<User> = User.fetchRequest()
        do {
            let users = try moc.fetch(userRequest)
            if users.isEmpty{
                return ""
            }else{
                _userId = users[0].userId!
                return users[0].userId!
            }
        }catch{
            return ""
        }
    }
    
    private var _libraryId: String = ""
    var libraryId:String {
        if _libraryId != ""{
            return _libraryId
        }
        let userRequest: NSFetchRequest<User> = User.fetchRequest()
        do {
            let users = try moc.fetch(userRequest)
            if users.isEmpty{
                return ""
            }else{
                _libraryId = users[0].musicLibraryId ?? ""
                return users[0].musicLibraryId ?? ""
            }
        }catch{
            return ""
        }
    }
    
    private var _playlistId: String = ""
    var playlistId: String {
        if _playlistId != ""{
            return _playlistId
        }
        let userRequest: NSFetchRequest<User> = User.fetchRequest()
        do {
            let users = try moc.fetch(userRequest)
            if users.isEmpty{
                return ""
            }else{
                _playlistId = users[0].playlistLibraryId ?? ""
                return users[0].playlistLibraryId ?? ""
            }
        }catch{
            return ""
        }
    }
    
    
    private var cancelSync = false
    
    init() {
        let manager = ServerTrustManager(evaluators: ["jfinwebscrape.azurewebsites.net": DefaultTrustEvaluator()])
        session = Session(serverTrustManager: manager)

        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                DispatchQueue.main.async {
                    withAnimation{
                        self.online = true
                    }
                }
            } else {
                DispatchQueue.main.async {
                    withAnimation{
                        self.online = false
                    }
                }
            }
        }
        let queue = DispatchQueue(label: "Monitor")
        monitor.start(queue: queue)
    }
    
    func scheduleNotification(title: String, body: String) {
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        // show this notification five seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)

        // choose a random identifier
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        // add our notification request
        UNUserNotificationCenter.current().add(request)
    }
        
    private func saveUser(user: LoginResult, server: String, completion: @escaping (Bool) -> Void){
            let userRequest: NSFetchRequest<User> = User.fetchRequest()
            
            do {
                let users = try moc.fetch(userRequest)
                var localUser: User? = nil
                if users.isEmpty{
                    localUser = User(context: moc)
                }else{
                    localUser = users[0]
                }
                localUser!.userId = user.user.id
                self._userId = user.user.id
                localUser!.authToken = user.accessToken
                self._accessToken = user.accessToken
                localUser!.server = server
                self._server = server
                localUser!.serverId = user.serverID
                try self.moc.save()
                UserDefaults.standard.set(true, forKey: "Authenticated")
                completion(true)
                
            } catch{
                completion(false)
            }
    }
    
    public func signOut(){
        let privateMOC = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateMOC.parent = moc
        privateMOC.perform {

            UserDefaults.standard.set(false, forKey: "Authenticated")
            DispatchQueue.main.async {
                Player.shared.isPlaying = false
                Player.shared.songs.removeAll()
            }
            self.songItemStorage?.async.setObject([], forKey: "lastSync", completion: { _ in })
            self.deleteAllOfEntity("User")
            self.deleteAllOfEntity("Album")
            self.deleteAllOfEntity("Song")
            self.deleteAllOfEntity("Artist")
            self.deleteAllOfEntity("Playlist")
            self.deleteAllOfEntity("Genre")
            self._server = ""
            self._userId = ""
            self._accessToken = ""
            self._playlistId = ""
            self._libraryId = ""

            DispatchQueue.main.async {
                self.authenticated = false
            }
            
        }
    }
    
    func deleteAllOfEntity(_ entityName: String)-> Void{
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try moc.execute(deleteRequest)
        } catch let error as NSError {
            // TODO: handle the error
            print(error)
        }
    }
    
    func saveContext(forContext context: NSManagedObjectContext) {
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
    
    struct TopSongsResultElement: Codable {
        let index: Int
        let song: String
    }

    typealias TopSongsResult = [TopSongsResultElement]
    
    func getSimilarArtists(artist: Artist, downloadsOnly:Bool = false, completion: @escaping (([Artist]) -> Void)){
        
        let key = "similar\(String(describing: artist.id))"
        genericStorage?.async.entry(forKey: key, completion: { result in
            let jsonItem: [GenericItem]
            var haveData = false
            switch result {
                case .error:
                    print("Similar artists don't exist")
                case .value(let entry):
                    haveData = true
                    jsonItem = entry.object
                    let artistsIds = jsonItem.map{ $0.id }
                    
                    let artistsRequest: NSFetchRequest<Artist> = Artist.fetchRequest()
                    let predicate = NSPredicate(format: "id in (%@)", artistsIds)
                    artistsRequest.predicate = predicate
                        do {
                            let matchedArtists = try self.moc.fetch(artistsRequest).filter{ !downloadsOnly ? true : $0.songs!.contains(where: { song in
                                (song as! Song).downloaded == true
                            })}
                            completion(Array(matchedArtists.prefix(7)))
                        } catch {
                            let nserror = error as NSError
                            print("Error when saving !!! \(nserror.localizedDescription)")
                            print("Callstack :")
                            for symbol: String in Thread.callStackSymbols {
                                print(" > \(symbol)")
                            }
                        }
            }
            if !haveData{
                jfApiService.getSimilarArtists(id: artist.id!, completionHandler: { res in
                    switch result{
                    case let .value(res):
                        let artists = res.object
                        self.genericStorage?.async.setObject(artists, forKey: key, completion: { _ in })
                        
                        let artistsIds = artists.map{ $0.id }
                        
                        let artistsRequest: NSFetchRequest<Artist> = Artist.fetchRequest()
                        let predicate = NSPredicate(format: "id in (%@)", artistsIds)
                        artistsRequest.predicate = predicate
                            do {
                                let matchedArtists = try self.moc.fetch(artistsRequest).filter{ !downloadsOnly ? true : $0.songs?.contains(where: { (song) in
                                    return (song as! Song).downloaded
                                }) as! Bool}
                                completion(Array(matchedArtists.prefix(7)))
                            } catch {
                                let nserror = error as NSError
                                print("Error when saving !!! \(nserror.localizedDescription)")
                                print("Callstack :")
                                for symbol: String in Thread.callStackSymbols {
                                    print(" > \(symbol)")
                                }
                            }
                    case let .error(err):
                        print(err)
                    }
                })
            }
        })
    }
    
    func getTopSongs(artist: Artist, downloadsOnly:Bool = false, completion: @escaping (([Song]) -> Void)){

        let key = "topSongs_\(String(describing: artist.id))"
        storage?.async.entry(forKey: key, completion: { result in
            let jsonItem: TopSongsResult
            var haveData = false
            switch result {
                case .error:
                    print("Songs don't exist")
                case .value(let entry):
                    haveData = true
                    jsonItem = entry.object
                    
                    var songResults: [Song] = []
                    let songs = artist.albumsArray.flatMap({ $0.songArray }).filter{ downloadsOnly ? $0.downloaded : true}
                    
                    for topSong in jsonItem{
                        let m = songs.filter{ $0.name != nil && $0.name!.caseInsensitiveCompare(topSong.song.trimmingCharacters(in: .whitespacesAndNewlines)) == .orderedSame}
                        if m.count > 0{
                            songResults.append(m.first!)
                        }
                    }
                    
                    completion(songResults)
                    
            }
            // only check every 10 minutes
            if !haveData{
                DispatchQueue.global(qos: .background).async {
                    self.session.request(
                        "https://jfinwebscrape.azurewebsites.net/webscraper?artist=\(artist.name!.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)",
                        method: .get,
                        headers: nil).response { response in
                            switch response.result {
                                case let .success(data):
                                    var songResults: [Song] = []
                                    if data != nil{
                                        let item = try! JSONDecoder().decode(TopSongsResult.self, from: data!)
                                        self.storage?.async.setObject(item, forKey: key, completion: { _ in })
                                        
                                        let songs = artist.albumsArray.flatMap({ $0.songArray }).filter{ downloadsOnly ? $0.downloaded : true}
                                        
                                        for topSong in item{
    //                                        if topSong.song.
                                            let m = songs.filter{ $0.name != nil && $0.name!.caseInsensitiveCompare(topSong.song.trimmingCharacters(in: .whitespacesAndNewlines)) == .orderedSame}
                                            if m.count > 0{
                                                songResults.append(m.first!)
                                            }
                                        }
                                    }
                                    completion(songResults)
                                case .failure(_):
                                    print(response)
                            }
                        }.resume()
                }
            }
        })
    }

    func getMinutesDifferenceFromTwoDates(start: Date, end: Date) -> Int
       {

           let diff = Int(end.timeIntervalSince1970 - start.timeIntervalSince1970)

           let hours = diff / 3600
           let minutes = (diff - hours * 3600) / 60
           return minutes
       }

    func getAuthHeader() -> HTTPHeaders{
        return ["X-Emby-Token": self.accessToken]
    }

    func getAlbumArt(id: String, maxSize: Int? = nil) ->String{
        return "\(server)/Items/\(id)/Images/Primary\(maxSize != nil ? "?maxHeight=\(maxSize ?? 0)&maxWidth=\(maxSize ?? 0)&quality=80" : "")"
    }

    public func sync(){
        self.syncing = true
        jfApiService.allSongs(libraryId: self.libraryId, completionHandler: { result in
            //TODO: get library id
            switch result {
                case let .success(songs):
                    self.cancelSync = false
                    let operationQueue = OperationQueue()
                    operationQueue.maxConcurrentOperationCount = 1

                    let cacheSongs = try? self.songItemStorage!.object(forKey: "lastSync")
                    var cacheSongsUnwrapped: [SongItem] = cacheSongs ?? []
                    let batches = Array(Set(songs.items).subtracting(cacheSongsUnwrapped).sorted(by: { $0.dateCreated > $1.dateCreated })).chunked(into: 400)
                    var i = 0
                    for batch in batches{
                        
                        let syncOperation =  AsyncOperation(batch: batch)
                        
                        
                        var identifier: UIBackgroundTaskIdentifier!
                        identifier = UIApplication.shared.beginBackgroundTask(expirationHandler: {
                            syncOperation.cancel()
                            
                            if !self.cancelSync {
                                self.scheduleNotification(title: "Synchronization on hold", body: "We weren't able to finish syncing all your music. We will resume next time you open the app!")
                                operationQueue.cancelAllOperations()
                                DispatchQueue.main.async {
                                    self.syncing = false
                                }
                            }
                            self.cancelSync = true
                            
                            
                        })
                        
                        syncOperation.completionBlock = {
                            if !syncOperation.isCancelled{
                                i += 1
                                print("\(batches.count - i) remaining")
                                if batches.count - i == 0{
                                    DispatchQueue.main.async {
                                        self.syncing = false
                                    }
                                }
                                cacheSongsUnwrapped.append(contentsOf: batch)
                                self.songItemStorage?.async.setObject(cacheSongsUnwrapped, forKey: "lastSync", completion: { _ in })
                            }
                            UIApplication.shared.endBackgroundTask(identifier)
                        }
                        
                        operationQueue.addOperations([syncOperation], waitUntilFinished: false)
                    }
                    
                    if batches.count == 0{
                        DispatchQueue.main.async {
                            self.syncing = false
                        }
                    }
                    
                case let .failure(err):
                    self.syncing = false
                    print(err)
            }
            
        })
    }
    
    func authenticate(server: String, username: String, password: String, completion: @escaping (Bool) -> Void){
        self._server = server
        login(username: username, password: password, server: server){ login in
            switch login{
                case let .success(data):
                    self.saveUser(user: data, server: server, completion: { res in
                        if res {
                            DispatchQueue.main.async {
                                UserDefaults.standard.set(Double(256), forKey: "Quality")
                            }
                            completion(true)
                            
                        }
                    })
            case .failure:
                    print("Failed to login")
                    completion(false)
            }
        }
    }
    
    func getAppCurrentVersionNumber() -> String {
        let nsObject: AnyObject? = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as AnyObject?
        return nsObject as! String
    }

    func getRuntime(ticks:Int) -> String{
        let reference = Date();
        let myDate = Date(timeInterval: (Double(ticks)/10000000.0),
                            since: reference);
        
        let difference = Calendar.current.dateComponents([.hour, .minute], from: reference, to: myDate)
        var runtimeString: [String] = []
        if difference.hour ?? 0 > 0{
            runtimeString.append(difference.hour! > 1 ? "\(difference.hour!) hours" : "\(difference.hour!) hour")
        }
        if difference.minute ?? 0 > 0{
            runtimeString.append(difference.minute! > 1 ? "\(difference.minute!) minutes" : "\(difference.minute!) minute")
        }
//        let formattedString = String(format: "%02ld%02ld", difference.hour!, difference.minute!)
        
        return runtimeString.joined(separator: " ")
    }

    private func login(username: String, password: String, server: String, completion: @escaping (ResultCustom<LoginResult>) -> Void){

        let headers: HTTPHeaders = [
            "Accept": "application/json",
            "Content-Type": "application/json",
            "X-Emby-Authorization": "MediaBrowser Client=\"jFin\", Device=\"\(UIDevice.current.name.stripped)\", DeviceId=\"\(UIDevice.current.model)\", Version=\"\(getAppCurrentVersionNumber())\""
        ]
        let login = Login(username: username, password: password)
        let urlString = "\(server)/emby/Users/AuthenticateByName"
        session.request(urlString,
                   method: .post,
                   parameters: login,
                   encoder: JSONParameterEncoder.default,
                   headers: headers).response { response in
                        switch response.result {
                            case let .success(data):
                                do {
                                    let item = try JSONDecoder().decode(LoginResult.self, from: data!)
                                    completion(.success(value: item))
                                } catch {
                                    print(error)
                                    completion(.failure(value: .loginFailed))
                                }
                            case let .failure(error):
                                print(error)
                                completion(.failure(value: .unknown(error: error)))
                        }
                   }
    }
    
    
    // PLAYLISTS
    
    func syncPlaylists(completion: @escaping (Bool) -> Void){

        self.getViews(){ views in
            let playlist = views.filter({ $0.collectionType == "playlists"})
            if !playlist.isEmpty{
            self._playlistId = playlist.first!.id
             
        
        if self.playlistId != "" {
            let privateMOC = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            privateMOC.parent = self.moc
            privateMOC.perform {
                jfApiService.getItems(parentId: self.playlistId, completionHandler: { result in

                    switch (result){
                    case let .success(playlists):
                        let playlistRequest: NSFetchRequest<Playlist> = Playlist.fetchRequest()
                        let existingPlaylists = try! privateMOC.fetch(playlistRequest)

                        // Delete existing songs that are not in the new data array
                        for existingPlaylist in existingPlaylists{
                            if playlists.items.filter({ $0.id == existingPlaylist.id! }).isEmpty{
                                privateMOC.delete(existingPlaylist)
                            }
                        }
                        
                        for playlist in playlists.items{
                            jfApiService.getPlaylistItem(id: playlist.id){ plist in
                                switch (plist){
                                case let .success(playlistItem):
                                    var plist: Playlist? = nil
                                            let existingPlaylist = existingPlaylists.filter({ $0.id ?? "" == playlist.id })
                                            if existingPlaylist.count > 0{
                                                existingPlaylist[0].name = playlistItem.name
                                                existingPlaylist[0].id = playlistItem.id
                                                existingPlaylist[0].overview = playlistItem.overview
                                                plist = existingPlaylist[0]
                                            }else{
                                                plist = Playlist(context: privateMOC)
                                                plist!.name = playlistItem.name
                                                plist!.id = playlistItem.id
                                                plist!.sortName = playlistItem.sortName
                                                plist!.overview = playlistItem.overview
                                            }
                                    jfApiService.getPlaylistItems(id: playlistItem.id){ playlistResults in
                                        switch (playlistResults){
                                        case let .success(songs):
                                            // Delete existing songs that are not in the new data array
                                            for existingSong in plist!.playlistSongArray{
                                                if songs.items.filter({ $0.id == existingSong.playlistItemId}).isEmpty{
                                                    privateMOC.delete(existingSong)
                                                }
                                            }
                                            
                                            // Add update songs
                                            if !songs.items.isEmpty{
                                                var i = 0
                                                for song in songs.items{
                                                    let songRequest: NSFetchRequest<Song> = Song.fetchRequest()
                                                    let predicate = NSPredicate(format: "id = %@", song.id)
                                                    songRequest.predicate = predicate
                                                        do {
                                                            let existingSong = try privateMOC.fetch(songRequest)
                        //                                    plist!.sortIds! += "\(existingSong[0].id),"
                                                            if existingSong.count > 0{
                                                                let pSong = existingSong[0].playlistItems.filter({ $0.playlistItemId == song.playlistItemId!})
                                                                if pSong.isEmpty{
                                                                    let newPSong = PlaylistSong(context: privateMOC)
                                                                    newPSong.playlistItemId = song.playlistItemId!
                                                                    newPSong.song = existingSong[0]
                                                                    newPSong.playlist = plist!
                                                                    newPSong.order = Int16(i)
                                                                }else{
                                                                    pSong[0].order = Int16(i)
                                                                }
                                                                self.saveContext(forContext: privateMOC)
                                                            }
                                                       } catch { }
                                                    i += 1
                                                }
                                            }
                                        case .failure(_):
                                            print("Failed to get playlist songs")
                                    }
                                    }
                                    
                                    self.saveContext(forContext: privateMOC)
                                case .failure(_):
                                    print("Failed to get playlist")
                                }
                            }
                        }
                        completion(true)
                    case .failure(_):
                        print("Failed to get latest playlists")
                        completion(false)
                    }
                })
            }
        }
                
            }
        }
    }
    
    func savePrimaryLibrary(libraryId: String, completion: @escaping (Bool) -> Void){
            let userRequest: NSFetchRequest<User> = User.fetchRequest()
            
            do {
                let users = try moc.fetch(userRequest)
                var localUser: User? = nil
                if users.isEmpty{
                    completion(false)
                }else{
                    localUser = users[0]
                }
                localUser!.musicLibraryId = libraryId
                try self.moc.save()
                self.authenticated = true
                completion(true)
                
            } catch{
                completion(false)
            }
    }
    
    func getViews(completion: @escaping ([JFView]) -> Void){
        jfApiService.getViews(){res in
            switch res{
            case let .success(items):
                completion(items.items)
            case .failure(_):
                completion([])
            }
        }
    }
    
    func createPlaylist(name: String, completion: @escaping (Bool) -> Void){
        jfApiService.createPlaylist(name: name){ result in
            switch result{
            case let .success(res):
                let playlist = Playlist(context: self.moc)
                playlist.id = res.id
                playlist.name = name
                playlist.sortName = name
                try! self.moc.save()
                completion(true)
            case .failure(_):
                print("Failed to create playlist")
                completion(false)
            }
        }
    }
    
    func addToPlaylist(playlistId: String, itemId: String, completion: @escaping (Bool) -> Void){
        jfApiService.addToPlaylist(playlistId: playlistId, itemId: itemId, completionHandler: { result in
            completion(result)
        })
    }
    
    func movePlaylistItem(playlistId: String, itemId: String, newPosition: Int, completion: @escaping (Bool) -> Void){
        jfApiService.movePlaylistItem(playlistId: playlistId, itemId: itemId, newPosition: newPosition, completionHandler: { result in
            completion(result)
        })
    }
    
    func deleteFromPlaylist(playlistId: String, itemId: String, completion: @escaping (Bool) -> Void){
        jfApiService.deleteFromPlaylist(playlistId: playlistId, itemId: itemId, completionHandler: { result in
                completion(result)
        })
    }
    
    func deletePlaylist(playlistId: String, completion: @escaping (Bool) -> Void){
        jfApiService.deletePlaylist(playlistId: playlistId, completionHandler: { result in
                completion(result)
        })
    }
    
    func favouriteSong(song: Song, isFavourite: Bool, completion: @escaping (Bool) -> ()){
        let privateMOC = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateMOC.parent = moc
        privateMOC.perform {
            if isFavourite{
                jfApiService.favourite(id: song.id!, completionHandler: { result in
                    song.isFavourite = true
                    try? privateMOC.save()
                    completion(result)
                })
            }else{
                jfApiService.unfavourite(id: song.id!, completionHandler: { result in
                    song.isFavourite = false
                    try? privateMOC.save()
                    completion(result)
                })
            }
        }
        
    }
    // Playback
    func playSong(song: Song, from: From, downloaded: Bool = false){
        if from.type == .album{
            Player.shared.loadSongs((song.album?.songArray.filter{ downloaded ? $0.downloaded : true}.sorted(by: { $0.trackNumber < $1.trackNumber }))!, songId: song.id!)
        }else if from.type == .playlist{
            let playlistRequest: NSFetchRequest<PlaylistSong> = PlaylistSong.fetchRequest()
            let predicate = NSPredicate(format: "playlist.id = %@", from.id)
            playlistRequest.predicate = predicate
                do {
                    let existingPLaylist = try moc.fetch(playlistRequest)
                    let songs = existingPLaylist.sorted(by: { $0.order < $1.order}).filter{ downloaded ? $0.song!.downloaded : true}.compactMap({ $0.song! })
                    Player.shared.loadSongs(songs, songId: song.id!)
                }catch {}
        }else if from.type == .topSongs{
            self.getTopSongs(artist: (song.album?.artistsArray.first)!, downloadsOnly: downloaded, completion: { songs in
                DispatchQueue.main.async {
                    Player.shared.loadSongs(songs, songId: song.id!)
                    Player.shared.isPlaying = true
                }
            })
            return
        }else if from.type == .allSongs{
            Player.shared.loadSongs([song])
        }
        Player.shared.isPlaying = true
    }
    
    func playNext(song: Song){
        Player.shared.appendSongsNext([song])
    }
    
    func playLast(song: Song){
        Player.shared.appendSongsEnd([song])
    }
    
    func instantMix(id: String, downloadsOnly: Bool){
        jfApiService.getInstantMix(id: id, completionHandler: { result in
            switch (result){
            case let .success(songs):
                let songIds = songs.items.map({ $0.id })
                let songsRequest: NSFetchRequest<Song> = Song.fetchRequest()
                let predicate = NSPredicate(format: "id in (%@)", songIds)
                songsRequest.predicate = predicate
                do {
                    var matchedSongs = try self.moc.fetch(songsRequest).filter{ !downloadsOnly ? true : $0.downloaded }
                    matchedSongs.shuffle()
                    Player.shared.loadSongs(matchedSongs, songId: id)
                    Player.shared.isPlaying = true
                } catch {
                    let nserror = error as NSError
                    print("Error when saving !!! \(nserror.localizedDescription)")
                    print("Callstack :")
                    for symbol: String in Thread.callStackSymbols {
                        print(" > \(symbol)")
                    }
                }
            case .failure(_):
                print("Could not get instant mix songs")
            }
        })
    }
}

extension String {

    var stripped: String {
        let okayChars = Set("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890+-=().!_")
        return self.filter {okayChars.contains($0) }
    }
}
