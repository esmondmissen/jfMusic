//
//  AlbumArt.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 20/10/20.
//

import SwiftUI

struct AlbumArt: View {
    @ObservedObject var player: Player = Player.shared
    let animation: Namespace.ID
    var body: some View {
            ZStack{
                HStack{
                        Image(uiImage:player.currentSongImage).resizable().aspectRatio(contentMode: .fit)
                            .mask(RoundedRectangle(cornerRadius: 8))
                            .matchedGeometryEffect(id: "art", in: animation)
                            .shadow(color: Color.black.opacity(0.5), radius: player.isPlaying ? 30 : 10, x: 0, y: player.isPlaying ? 20: 5)
                            .animation(.default, value: player.isPlaying)
                }.padding(player.isPlaying ? 15 : 80)
            }
    }
}
