//
//  ArtistInfoLarge.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 29/10/20.
//

import SwiftUI

struct ArtistInfoLarge: View {
    @ObservedObject var player: Player = Player.shared
    @ObservedObject var nw = NetworkingManager.shared
    @State private var updateContextMenu = false
    let animation: Namespace.ID
    let song : Song? = (Player.shared.currentSong)?.song
    var body: some View {
        VStack(spacing: 12.5){
            Spacer().frame(height: 5)
            HStack{
                VStack(alignment: .leading, spacing: 0){
                    GeometryReader{ geo in
                        DemoSlideText(width: geo.size.width){
                            HStack(spacing: 0){
                                Text(player.currentSong?.song.wrappedNameFeat ?? "Not Playing")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                                Spacer()
                                }
                        }
                    }.frame(height: 30)
                    GeometryReader{ geo in
                        DemoSlideText(width: geo.size.width){
                            HStack(spacing: 0){
                                Text(player.currentSong?.song.artistShort ?? " ")
                                    .font(.system(size: 22, weight: .regular))
                                    .foregroundColor(Color.white.opacity(0.6))
                                Spacer()
                            }
                        }
                    }.frame(height: 30)
                }
                .matchedGeometryEffect(id: "largeName", in: animation)
                Spacer().frame(width: 30)
                Menu{
                    if song != nil {
                        Button(action: {
                            nw.favouriteSong(song: song!, isFavourite: !song!.isFavourite){ res in
                                updateContextMenu.toggle()
                            }
                        }, label: {
                            HStack{
                                Text(song!.isFavourite ? "Unfavourite" : "Favourite")
                                    .rotationEffect(updateContextMenu ? .degrees(-00) : .degrees(-360))
                                Image(systemName: song!.isFavourite ? "heart.slash" : "heart")
                            }
                        })
                        Button(action: {}) {
                            HStack{
                                Text("Add to Playlist")
                                Image(systemName: "music.note.list")
                            }
                        }
                        Button(action: {
                            nw.playNext(song: song!)
                        }, label: {
                            HStack{
                                Text("Play Next")
                                Image(systemName: "text.insert")
                            }
                        })
                        Button(action: {
                            nw.playLast(song: song!)
                        }, label: {
                            HStack{
                                Text("Play Last")
                                Image(systemName: "text.append")
                            }
                        })
                        Button(action: {
                            nw.instantMix(id: song!.id!, downloadsOnly: false)
                        }, label: {
                            HStack{
                                Text("Instant Mix")
                                Image(systemName: "list.star")
                            }
                        })
                        Button(action: {
                            if song!.downloaded{
                                song!.removeDownload()
                            }else{
                                song!.download()
                            }
                        }, label: {
                            HStack{
                                Text(song!.downloaded ? "Remove Download" : "Download")
                                Image(systemName: song!.downloaded ? "trash" : "plus")
                            }
                        })
                    }
                } label: {
                    Circle().fill(Color.white.opacity(0.2))
                        .overlay(
                    Image(systemName: "ellipsis")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.white)
                        .frame(width: 18)
                        ).frame(width: 26)
                }
                .matchedGeometryEffect(id: "ellipse", in: animation)
            }.padding(.trailing, 30).padding(.leading, 15)
        }
    }
}
