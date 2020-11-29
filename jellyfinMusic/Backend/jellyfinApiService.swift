//
//  jellyfinApiService.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 29/9/20.
//

import Foundation
import Combine
import Alamofire

public struct jfApiService {
    
    private static var cache: [String: Codable] = [:]
    
    public enum Field{
        case AudioInfo
        case SeriesInfo
        case ParentId
        case PrimaryImageAspectRatio
        case BasicSyncInfo
        case Genres
        case DateCreated
    }
    
    public enum ItemType{
        case MusicAlbum
        case MusicArtist
    }
    
    public struct JFRequest{
        let url: String
        let method: HTTPMethod
        let returns: Codable.Type?
    }
    
    private enum Endpoint {
        case albums(recursive: Bool = true, fields: [Field]? = [.Genres, .DateCreated])
        case artist(id: String)
        case similarArtists(id: String)
        case songs(albumId:String)
        case allSongs(libraryId: String)
        case songsImage(id: String, maxSize: Int? = nil)
        case createPlaylist(name: String, ids: String = "")
        case getPlaylistItems(id: String)
        case deletePlaylist(playlistId: String)
        case addToPlaylist(playlistId: String, itemId: String)
        case reorderPlaylsitItem(playlistId: String, itemId: String, newPosition: Int)
        case views
        case item(id: String)
        case items(parentId: String)
        case deleteFromPlaylist(playlistId: String, itemId: String)
        case favourite(id: String)
        case unfavourite(id: String)
        case instantMix(id: String)

        public func getInfo() -> JFRequest {
            switch self {
            case let .albums(recursive, fields):
                return JFRequest(url: "/users/\(NetworkingManager.shared.userId)/Items?Recursive=\(recursive)&IncludeItemTypes=\(ItemType.MusicAlbum)&SortBy=DateCreated&SortOrder=Descending&Fields=\(fields!.map{String(describing: $0)}.joined(separator: ","))",
                                 method: HTTPMethod.get,
                                 returns: ResultSet<AlbumResult>.self)

                
            case let .artist(id):
                return JFRequest(url: "/users/\(NetworkingManager.shared.userId)/Items/\(id)",
                                 method: HTTPMethod.get,
                                 returns: ResultSet<ArtistResult>.self)
                
            case let .songs(albumId):
                return JFRequest(url: "/users/\(NetworkingManager.shared.userId)/Items?IncludeItemTypes=Audio&ParentId=\(albumId)",
                                 method: .get,
                                 returns: ResultSet<SongResult>.self)
                
            case let .allSongs(libraryId):
                return JFRequest(url: "/Users/\(NetworkingManager.shared.userId)/Items?SortBy=DateCreated&SortOrder=Descending&IncludeItemTypes=Audio&Recursive=true&Fields=AudioInfo%2CParentId%2CDateCreated%2CGenres&StartIndex=0&ImageTypeLimit=0&ParentId=\(libraryId)",
                                 method: .get,
                                 returns: ResultSet<SongResult>.self)
                
            case let .songsImage(id, maxSize):
                return JFRequest(url: "/Items/\(id)/Images/Primary\(maxSize != nil ? "?maxHeight=\(maxSize ?? 0)&maxWidth=\(maxSize ?? 0)&quality=80" : "")", method: .get,
                    returns: nil)
                
            case let .similarArtists(id):
                return JFRequest(url: "/Items/\(id)/Similar?limit=50",
                                 method: .get,
                                 returns: ResultSet<GenericItem>.self)
                
            case let .createPlaylist(name, ids):
                return JFRequest(url: "/Playlists?Name=\(name.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)\(ids != "" ? "&Ids=\(ids)" : "")&userId=\(NetworkingManager.shared.userId)",
                                 method: .post,
                                 returns: Id.self)
                
            case .views:
                return JFRequest(url: "/Users/\(NetworkingManager.shared.userId)/Views",
                                 method: .get,
                                 returns: ResultSet<JFView>.self)
                
            case let .item(id):
                return JFRequest(url: "/Users/\(NetworkingManager.shared.userId)/Items/\(id)",
                                 method: .get,
                                 returns: PlaylistItem.self)
                
            case let .items(parentId):
                return JFRequest(url: "/Users/\(NetworkingManager.shared.userId)/Items?ParentId=\(parentId)&SortBy=IsFolder%2CSortName&SortOrder=Ascending",
                                 method: .get,
                                 returns: ResultSet<GenericItem>.self)
                
            case let .getPlaylistItems(id):
                return JFRequest(url: "/Playlists/\(id)/Items?UserId=\(NetworkingManager.shared.userId)",
                                 method: .get,
                                 returns: ResultSet<SongResult>.self)
                
            case let .instantMix(id):
                return JFRequest(url: "/Items/\(id)/InstantMix?UserId=\(NetworkingManager.shared.userId)&Limit=100",
                                 method: .get,
                                 returns: ResultSet<GenericItem>.self)
                
            case let .deleteFromPlaylist(playlistId, itemId):
                return JFRequest(url: "/Playlists/\(playlistId)/Items?EntryIds=\(itemId)",
                                 method: .delete,
                                 returns: nil)
                
            case let .addToPlaylist(playlistId, itemId):
                return JFRequest(url: "/Playlists/\(playlistId)/Items?Ids=\(itemId)&userId=\(NetworkingManager.shared.userId)",
                                 method: .post,
                                 returns: nil)
                
            case let .deletePlaylist(playlistId):
                return JFRequest(url: "/Items/\(playlistId)",
                                 method: .delete,
                                 returns: nil)
                
            case let .reorderPlaylsitItem(playlistId, itemId, newPosition):
                return JFRequest(url: "/Playlists/\(playlistId)/Items/\(itemId)/Move/\(newPosition)",
                                 method: .post,
                                 returns: nil)
                
            case let .favourite(id):
                return JFRequest(url: "/Users/\(NetworkingManager.shared.userId)/FavoriteItems/\(id)",
                                 method: .post,
                                 returns: nil)
                
            case let .unfavourite(id):
                return JFRequest(url: "/Users/\(NetworkingManager.shared.userId)/FavoriteItems/\(id)",
                                 method: .delete,
                                 returns: nil)
        }
        }
    }
    static func getAlbums(completionHandler: @escaping (Result<ResultSet<AlbumResult>, APIError>) -> Void){
        let info = Endpoint.albums().getInfo()
        jfApiService.fetch(type: ResultSet<AlbumResult>.self, url: URL(string:NetworkingManager.shared.server +  info.url)!, method: info.method, completionHandler: { result in
            completionHandler(result)
        })
    }
    static func getArtist(id: String, completionHandler: @escaping (Result<ArtistResult, APIError>) -> Void){
        let info = Endpoint.artist(id: id).getInfo()
        jfApiService.fetch(type: ArtistResult.self, url: URL(string:NetworkingManager.shared.server +  info.url)!, method: info.method, completionHandler: { result in
            completionHandler(result)
        })
    }
    static func getSimilarArtists(id: String, completionHandler: @escaping (Result<ResultSet<GenericItem>, APIError>) -> Void){
        let info = Endpoint.similarArtists(id: id).getInfo()
        jfApiService.fetch(type: ResultSet<GenericItem>.self, url: URL(string:NetworkingManager.shared.server +  info.url)!, method: info.method, completionHandler: { result in
            completionHandler(result)
        })
    }
    static func getSongs(albumId: String, completionHandler: @escaping (Result<ResultSet<SongItem>, APIError>) -> Void){
        let info = Endpoint.songs(albumId: albumId).getInfo()
        jfApiService.fetch(type: ResultSet<SongItem>.self, url: URL(string:NetworkingManager.shared.server +  info.url)!, method: info.method, completionHandler: { result in
            completionHandler(result)
        })
    }
    static func allSongs(libraryId: String, completionHandler: @escaping (Result<ResultSet<SongItem>, APIError>) -> Void){
        let info = Endpoint.allSongs(libraryId: libraryId).getInfo()
        jfApiService.fetch(type: ResultSet<SongItem>.self, url: URL(string:NetworkingManager.shared.server +  info.url)!, method: info.method, completionHandler: { result in
            completionHandler(result)
        })
    }
    static func songImage(id: String, maxSize: Int? = nil) -> URL{
        let info = Endpoint.songsImage(id: id, maxSize: maxSize).getInfo()
        return URL(string:NetworkingManager.shared.server + info.url)!
    }
    static func createPlaylist(name: String, ids: String = "", completionHandler: @escaping (Result<Id, APIError>) -> Void){
        let info = Endpoint.createPlaylist(name: name, ids: ids).getInfo()
        jfApiService.fetch(type: Id.self, url: URL(string:NetworkingManager.shared.server +  info.url)!, method: info.method, completionHandler: { result in
            completionHandler(result)
        })
    }
    static func getPlaylistItems(id: String, completionHandler: @escaping (Result<ResultSet<SongResult>, APIError>) -> Void){
        let info = Endpoint.getPlaylistItems(id: id).getInfo()
        jfApiService.fetch(type: ResultSet<SongResult>.self, url: URL(string:NetworkingManager.shared.server +  info.url)!, method: info.method, completionHandler: { result in
            completionHandler(result)
        })
    }
    static func getItems(parentId: String, completionHandler: @escaping (Result<ResultSet<GenericItem>, APIError>) -> Void){
        let info = Endpoint.items(parentId: parentId).getInfo()
        jfApiService.fetch(type: ResultSet<GenericItem>.self, url: URL(string:NetworkingManager.shared.server +  info.url)!, method: info.method, completionHandler: { result in
            completionHandler(result)
        })
    }
    
    static func getPlaylistItem(id: String, completionHandler: @escaping (Result<PlaylistItem, APIError>) -> Void){
        let info = Endpoint.item(id: id).getInfo()
        jfApiService.fetch(type: PlaylistItem.self, url: URL(string:NetworkingManager.shared.server +  info.url)!, method: info.method, completionHandler: { result in
            completionHandler(result)
        })
    }
    
    static func getInstantMix(id: String, completionHandler: @escaping (Result<ResultSet<GenericItem>, APIError>) -> Void){
        let info = Endpoint.instantMix(id: id).getInfo()
        jfApiService.fetch(type: ResultSet<GenericItem>.self, url: URL(string:NetworkingManager.shared.server +  info.url)!, method: info.method, completionHandler: { result in
            completionHandler(result)
        })
    }
    
    static func favourite(id: String, completionHandler: @escaping (Bool) -> Void){
        let info = Endpoint.favourite(id: id).getInfo()
        jfApiService.fetch(url: URL(string:NetworkingManager.shared.server +  info.url)!, method: info.method, completionHandler: { result in
            completionHandler(result)
        })
    }
    
    static func unfavourite(id: String, completionHandler: @escaping (Bool) -> Void){
        let info = Endpoint.unfavourite(id: id).getInfo()
        jfApiService.fetch(url: URL(string:NetworkingManager.shared.server +  info.url)!, method: info.method, completionHandler: { result in
            completionHandler(result)
        })
    }
    
    static func getViews(completionHandler: @escaping (Result<ResultSet<JFView>, APIError>) -> Void){
        let info = Endpoint.views.getInfo()
        jfApiService.fetch(type: ResultSet<JFView>.self, url: URL(string:NetworkingManager.shared.server +  info.url)!, method: info.method, completionHandler: { result in
            completionHandler(result)
        })
    }
    
    static func addToPlaylist(playlistId: String, itemId: String, completionHandler: @escaping (Bool) -> Void){
        let info = Endpoint.addToPlaylist(playlistId: playlistId, itemId: itemId).getInfo()
        jfApiService.fetch(url: URL(string:NetworkingManager.shared.server +  info.url)!, method: info.method, completionHandler: { result in
            completionHandler(result)
        })
    }
    
    static func movePlaylistItem(playlistId: String, itemId: String, newPosition: Int, completionHandler: @escaping (Bool) -> Void){
        let info = Endpoint.reorderPlaylsitItem(playlistId: playlistId, itemId: itemId, newPosition: newPosition).getInfo()
        jfApiService.fetch(url: URL(string:NetworkingManager.shared.server +  info.url)!, method: info.method, completionHandler: { result in
            completionHandler(result)
        })
    }
    
    static func deleteFromPlaylist(playlistId: String, itemId: String, completionHandler: @escaping (Bool) -> Void){
        let info = Endpoint.deleteFromPlaylist(playlistId: playlistId, itemId: itemId).getInfo()
        jfApiService.fetch(url: URL(string:NetworkingManager.shared.server +  info.url)!, method: info.method, completionHandler: { result in
            completionHandler(result)
        })
    }
    
    static func deletePlaylist(playlistId: String, completionHandler: @escaping (Bool) -> Void){
        let info = Endpoint.deletePlaylist(playlistId: playlistId).getInfo()
        jfApiService.fetch(url: URL(string:NetworkingManager.shared.server +  info.url)!, method: info.method, completionHandler: { result in
            completionHandler(result)
        })
    }
    
    private static let decoder = JSONDecoder()
    
    private static func fetch<T: Codable>(type: T.Type, url: URL, method: HTTPMethod, completionHandler: @escaping (Result<T, APIError>) -> Void) {
        NetworkingManager.shared.session.request(url,
            method: method,
            headers: NetworkingManager.shared.getAuthHeader()).response { response in
                print("\(url.path)")
                switch response.result {
                    case let .success(data):
                        let item = try! JSONDecoder().decode(type, from: data!)
                        completionHandler(.success(item))
                    case .failure(_):
                        completionHandler(.failure(.unknown))
                }
            }
    }
    private static func fetch(url: URL, method: HTTPMethod, completionHandler: @escaping (Bool) -> Void) {
        NetworkingManager.shared.session.request(url,
        method: method,
        headers: NetworkingManager.shared.getAuthHeader()).response { response in
            switch response.result {
                case .success(_):
                    completionHandler(true)
                case .failure(_):
                    completionHandler(false)
            }
        }
    }
}
public enum APIError: Error {
    case unknown
    case message(reason: String), parseError(reason: String), networkError(reason: String)

    static func processResponse(data: Data, response: URLResponse) throws -> Data {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown
        }
        if (httpResponse.statusCode == 404) {
            throw APIError.message(reason: "Resource not found");
        }
        return data
    }

}
