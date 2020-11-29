//
//  ArtistContextMenu.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 3/11/20.
//

import SwiftUI

struct ArtistContextMenu<Content:View>: View {
    @ObservedObject var nw: NetworkingManager = NetworkingManager.shared
    let content: Content
    var artistId: String
    init(artistId: String, @ViewBuilder content: () -> Content){
        self.artistId = artistId
        self.content = content()
    }
    var body: some View{
        content
            .contextMenu(menuItems: {
                Button(action: {
                    nw.instantMix(id: artistId, downloadsOnly: false)
                }, label: {
                    HStack{
                        Text("Instant Mix")
                        Image(systemName: "list.star")
                    }
                })
            })
    }
}
