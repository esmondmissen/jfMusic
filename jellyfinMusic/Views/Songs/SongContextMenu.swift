//
//  SongContextMenu.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 2/11/20.
//

import SwiftUI

struct SongContextMenu<Content: View>: View{
    @ObservedObject var nw: NetworkingManager = NetworkingManager.shared
    let content: Content
    @ObservedObject var song: Song
    init(song: Song, @ViewBuilder content: () -> Content){
        self.song = song
        self.content = content()
    }
    var body: some View{
        content
            .contextMenu(menuItems: {
                songOptions(song: song)
            })
    }
}


struct songOptions: View{
    @ObservedObject var nw: NetworkingManager = NetworkingManager.shared
    @Environment(\.managedObjectContext) var moc
    @Environment(\.colorScheme) var colorScheme
    @State var updateContextMenu: Bool = false
    @ObservedObject var song: Song
    var body: some View{
            Button(action: {
                nw.favouriteSong(song: song, isFavourite: !song.isFavourite){ res in
                    updateContextMenu.toggle()
                }
            }, label: {
                HStack{
                    Text(song.isFavourite ? "Unfavourite" : "Favourite")
                        .rotationEffect(updateContextMenu ? .degrees(-00) : .degrees(-360))
                    Image(systemName: song.isFavourite ? "heart.slash" : "heart")
                }
            })
            Button(action: {}) {
                HStack{
                    Text("Add to Playlist")
                    Image(systemName: "music.note.list")
                }
            }
            Button(action: {
                nw.playNext(song: song)
            }, label: {
                HStack{
                    Text("Play Next")
                    Image(systemName: "text.insert")
                }
            })
            Button(action: {
                nw.playLast(song: song)
            }, label: {
                HStack{
                    Text("Play Last")
                    Image(systemName: "text.append")
                }
            })
            Button(action: {
                nw.instantMix(id: song.id!, downloadsOnly: false)
            }, label: {
                HStack{
                    Text("Instant Mix")
                    Image(systemName: "list.star")
                }
            })
            Button(action: {
                if song.downloaded{
                    song.removeDownload()
                }else{
                    song.download()
                }
            }, label: {
                HStack{
                    Text(song.downloaded ? "Remove Download" : "Download")
                    Image(systemName: song.downloaded ? "trash" : "plus")
                }
            })
            
        }
}
