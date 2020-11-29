//
//  SongItem.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 19/10/20.
//

import Foundation

struct SongItem: Codable, Hashable {
    let name, id, dateCreated: String
    let runTimeTicks, productionYear, indexNumber: Int?
    let parentIndexNumber: Int?
    let parentID: String
    let album, albumID, albumArtist: String
    let albumPrimaryImageTag: String?
    let albumArtists, genreItems, artistItems: [GenericItem]
    let userData: UserData
    
    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case id = "Id"
        case dateCreated = "DateCreated"
        case runTimeTicks = "RunTimeTicks"
        case productionYear = "ProductionYear"
        case indexNumber = "IndexNumber"
        case parentIndexNumber = "ParentIndexNumber"
        case parentID = "ParentId"
        case artistItems = "ArtistItems"
        case album = "Album"
        case albumID = "AlbumId"
        case albumPrimaryImageTag = "AlbumPrimaryImageTag"
        case albumArtist = "AlbumArtist"
        case albumArtists = "AlbumArtists"
        case genreItems = "GenreItems"
        case userData = "UserData"
    }
    
    init(song: Song) {
        self.name = song.name!
        self.id = song.id!
        self.dateCreated = "\(String(describing: song.createDate))"
        self.runTimeTicks = nil
        self.productionYear = Int(song.album!.productionYear)
        self.indexNumber = Int(song.trackNumber)
        self.parentIndexNumber = Int(song.diskNumber)
        self.parentID = (song.album?.id) ?? ""
        self.artistItems = song.artistsArray.map{GenericItem(name: $0.name!, id: $0.id!)}
        self.album = (song.album?.name) ?? ""
        self.albumID = (song.album?.id) ?? ""
        self.albumPrimaryImageTag = song.album?.albumImage
        self.albumArtist = (song.album?.albumArtist) ?? ""
        self.albumArtists = (song.album?.artistsArray.map{GenericItem(name: $0.name!, id: $0.id!)})!
        self.genreItems = []
        self.userData = UserData(isFavorite: song.isFavourite)
    }
}

struct UserData: Codable, Hashable {
    let isFavorite: Bool

    enum CodingKeys: String, CodingKey {
        case isFavorite = "IsFavorite"
    }
}
