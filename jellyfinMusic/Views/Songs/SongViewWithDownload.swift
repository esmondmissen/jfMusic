//
//  SongViewWithDownload.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 25/10/20.
//

import SwiftUI

struct SongViewWithDownload: View{
    @Environment(\.managedObjectContext) var moc
    @ObservedObject var nw: NetworkingManager = NetworkingManager.shared
    @ObservedObject var song: Song
    @State var updateContextMenu: Bool = false
    let parentType: parentType
    init(song: Song, parentType: parentType){
        self.song = song
        self.parentType = parentType
    }
    var body: some View{
        VStack(spacing: 0) {
            HStack(){
                SongContextMenu(song: song){
                    Button(action: {
                        nw.playSong(song: song, from: From(name: "", id: "", type: parentType))
                    }){
                        Text("\(song.trackNumber )").opacity(0.6)
                            .padding(.trailing, 5)
                        VStack(alignment: .leading, spacing: 3){
                            Text(song.wrappedNameFeat)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        Spacer()
                    }
                }
                if !song.downloaded && nw.online{
                    HStack(spacing: 0){
                    if song.downloading == true{
                        LoaderCircle(progress: $song.progress)
                            .frame(width: 18, height: 18, alignment: .trailing)
                            .animation(.default, value: song.downloading)
                    }else{
                        Image(systemName: "plus")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(Color("Purple"))
                            .frame(height: 18, alignment: .trailing)
                            .animation(.default, value: song.downloading)
                            .onTapGesture {
                                song.downloading = true
                                song.download()
                            }
                    }
                        Spacer().frame(width: 10)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
            Divider()
             .frame(height: 1)
                .padding(0)
        }.padding(.horizontal, 10).padding(.vertical, 0).background(Color.black.opacity(0.0001)).cornerRadius(8)
    }
}
