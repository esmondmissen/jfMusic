//
//  Generic.swift
//  jFin
//
//  Created by Esmond Missen on 30/7/20.
//

import Foundation

public struct ResultSet<T:Codable>: Codable {
    let items: [T]
    let totalRecordCount, startIndex: Int

    enum CodingKeys: String, CodingKey {
        case items = "Items"
        case totalRecordCount = "TotalRecordCount"
        case startIndex = "StartIndex"
    }
}
