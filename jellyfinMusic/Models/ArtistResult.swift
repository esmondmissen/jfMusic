//
//  ArtistResult.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 29/9/20.
//

import Foundation

struct ArtistResult: Codable {
    let name, serverID, id, dateCreated, sortName: String
    let overview: String?
    let genreItems: [GenreItem]
    let imageTags: ImageTags
    let backdropImageTags: [String]

    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case serverID = "ServerId"
        case id = "Id"
        case dateCreated = "DateCreated"
        case sortName = "SortName"
        case overview = "Overview"
        case genreItems = "GenreItems"
        case imageTags = "ImageTags"
        case backdropImageTags = "BackdropImageTags"
    }
}

struct GenreItem: Codable {
    let name, id: String

    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case id = "Id"
    }
}

struct ImageTags: Codable, Hashable {
    let primary, banner, logo: String?

    enum CodingKeys: String, CodingKey {
        case primary = "Primary"
        case banner = "Banner"
        case logo = "Logo"
    }
}

struct AlbumResult: Codable {
    let name, serverID, id, dateCreated, albumArtist: String
    let genres: [String]
    let runTimeTicks: Int64
    let productionYear: Int?
    let genreItems, artistItems, albumArtists: [GenericItem]
    let imageTags: ImageTags

    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case serverID = "ServerId"
        case id = "Id"
        case dateCreated = "DateCreated"
        case genres = "Genres"
        case runTimeTicks = "RunTimeTicks"
        case productionYear = "ProductionYear"
        case genreItems = "GenreItems"
        case artistItems = "ArtistItems"
        case albumArtist = "AlbumArtist"
        case albumArtists = "AlbumArtists"
        case imageTags = "ImageTags"
    }
    
    static func == (lhs: AlbumResult, rhs: AlbumResult) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name
    }
}

struct Id: Codable, Hashable {
    let id: String

    enum CodingKeys: String, CodingKey {
        case id = "Id"
    }
}

struct GenericItem: Codable, Hashable {
    let name, id: String

    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case id = "Id"
    }
}

struct PlaylistItem: Codable, Hashable{
    let name, id, sortName: String
    let overview: String?
    
    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case id = "Id"
        case overview = "Overview"
        case sortName = "SortName"
    }
}

public struct SongResult: Codable, Hashable {
    
    let name, serverID, id, albumId, album: String
    let playlistItemId: String?
    let runTimeTicks: Int
    let productionYear, indexNumber, parentIndexNumber: Int?
    let artists: [String]
    let artistItems: [GenericItem]
//    var userData: UserData?
    
    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case serverID = "ServerId"
        case id = "Id"
        case runTimeTicks = "RunTimeTicks"
        case productionYear = "ProductionYear"
        case indexNumber = "IndexNumber"
        case parentIndexNumber = "ParentIndexNumber"
        case artists = "Artists"
        case artistItems = "ArtistItems"
        case albumId = "AlbumId"
//        case userData = "UserData"
        case album = "Album"
        case playlistItemId = "PlaylistItemId"
    }
}

struct LoginResult: Codable {
    let user: UserResult
    let sessionInfo: SessionInfo
    let accessToken, serverID: String

    enum CodingKeys: String, CodingKey {
        case user = "User"
        case sessionInfo = "SessionInfo"
        case accessToken = "AccessToken"
        case serverID = "ServerId"
    }
}

struct Login: Encodable {
    let username: String
    let password: String
    enum CodingKeys: String, CodingKey {
        case username = "Username"
        case password = "Pw"
    }
}

enum ResultCustom<T> {
    case success(value: T)
    case failure(value: JellyFinError)
}

enum JellyFinError: Error {
    case unknown(error: Error? = nil)
    case loginFailed
    case notAuthenticated(error: String = "Make sure the user is authenticated")
}
struct UserResult: Codable {
    let name, serverID, id: String
    let hasPassword, hasConfiguredPassword, hasConfiguredEasyPassword, enableAutoLogin: Bool
    let lastLoginDate, lastActivityDate: String
//    let configuration: Configuration
//    let policy: Policy

    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case serverID = "ServerId"
        case id = "Id"
        case hasPassword = "HasPassword"
        case hasConfiguredPassword = "HasConfiguredPassword"
        case hasConfiguredEasyPassword = "HasConfiguredEasyPassword"
        case enableAutoLogin = "EnableAutoLogin"
        case lastLoginDate = "LastLoginDate"
        case lastActivityDate = "LastActivityDate"
//        case configuration = "Configuration"
//        case policy = "Policy"
    }
}

struct SessionInfo: Codable {
//    let playState: PlayState
//    let capabilities: Capabilities
    let remoteEndPoint, id, userID, userName: String
    let client, lastActivityDate, lastPlaybackCheckIn, deviceName: String
    let deviceID, applicationVersion: String
    let isActive, supportsMediaControl, supportsRemoteControl, hasCustomDeviceName: Bool
    let serverID: String

    enum CodingKeys: String, CodingKey {
//        case playState = "PlayState"
//        case capabilities = "Capabilities"
        case remoteEndPoint = "RemoteEndPoint"
        case id = "Id"
        case userID = "UserId"
        case userName = "UserName"
        case client = "Client"
        case lastActivityDate = "LastActivityDate"
        case lastPlaybackCheckIn = "LastPlaybackCheckIn"
        case deviceName = "DeviceName"
        case deviceID = "DeviceId"
        case applicationVersion = "ApplicationVersion"
        case isActive = "IsActive"
        case supportsMediaControl = "SupportsMediaControl"
        case supportsRemoteControl = "SupportsRemoteControl"
        case hasCustomDeviceName = "HasCustomDeviceName"
        case serverID = "ServerId"
    }
}
