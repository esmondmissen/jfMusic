//
//  Views.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 8/11/20.
//

import Foundation

struct JFView: Codable, Hashable {
    let name, id, collectionType: String

    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case id = "Id"
        case collectionType = "CollectionType"
    }
}
