//
//  MiniPlayer.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 29/10/20.
//

import SwiftUI

struct MiniPlayer: View {
    @ObservedObject var player: Player = Player.shared
    let animation: Namespace.ID
    @Binding var isExpanded: Bool
    @Binding var topMargin: CGRect
    @Binding var playerState: PlayerState
    var body: some View {
        HStack(alignment: isExpanded ? .top : .center){
            Image(uiImage:player.currentSongImage).resizable().aspectRatio(contentMode: .fit)
                .mask(RoundedRectangle(cornerRadius: isExpanded ? 8 : 4))
                .frame(width: playerState == .upNext && isExpanded ? 60 : nil)
            if !isExpanded{
                Text(player.currentSong?.song.name ?? "Not Playing")
                    .padding(.leading, 10)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .allowsHitTesting(false)
                Spacer()
                if !player.isPlaying{
                    Button(action:{
                        player.isPlaying.toggle()
                    }) {
                        Image(systemName:"play.fill").resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 20)
                    }.buttonStyle(BlueButtonStyle()).padding(.horizontal)
                }else{
                    Button(action:{
                        player.isPlaying.toggle()
                    }) {
                        Image(systemName:"pause.fill").resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 20)
                    }.buttonStyle(BlueButtonStyle()).padding(.horizontal)
                }
                Button(action: {
                    player.next()
                }) {
                    Image(systemName:"forward.fill").resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 20)
                }.buttonStyle(BlueButtonStyle())
            }
            if playerState == .upNext && isExpanded{
                Spacer().frame(height: 60)
            }
        }
        .padding(.horizontal, !isExpanded ? 15 : playerState == .upNext && isExpanded ? 30 : player.isPlaying ? topMargin.minY == 20 ? 35 : 15 : 80)
        .padding(.top, isExpanded ? playerState == .upNext ? topMargin.minY + 90 : nil : 10)
        .frame(height: !isExpanded ? 56 : playerState == .upNext ? 60 : UIScreen.main.bounds.height - (UIScreen.main.bounds.height / 3) - 40 - topMargin.minY)
        .animation(.default, value: player.isPlaying)
    }
}
