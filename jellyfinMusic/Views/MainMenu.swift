//
//  MainMenu.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 25/10/20.
//

import SwiftUI

struct OfflineContent: View{
    @Binding var show: Bool
    @State private var appear = false
    
    init(show: Binding<Bool> = .constant(true)){
        self._show = show
    }
    
    var body: some View{
        HStack{
            Spacer()
            Text("Only showing downloaded content")
                .lineLimit(1)
                .foregroundColor(.white)
            Spacer()
        }.frame(height: 30)
        .background(Color("Purple"))
        .opacity(show ? 1 : 0)
        .animation(.default)
    }
}

struct MainMenu: View {
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(entity: Song.entity(), sortDescriptors: [
        NSSortDescriptor(keyPath: \Song.createDate, ascending: false)
    ]) var albums: FetchedResults<Song>
    @Binding var downloadedOnly: Bool
    init(downloadedOnly: Binding<Bool>) {
        self._downloadedOnly = downloadedOnly
        }
    var body: some View {
        ZStack(alignment: .top){
            List{
                NavigationLink(destination: Playlists(downloadsOnly: $downloadedOnly)){
                    HStack {
                        Image(systemName: "music.note.list")
                            .frame(width: 50, height: 10, alignment: .leading)
                            .foregroundColor(Color("Purple"))
                        Text("Playlists")
                    }
                    .padding(8)
                    .font(.system(size: 22, weight: .regular, design: .default))
                }
                .buttonStyle(PlainButtonStyle())
                NavigationLink(destination: ArtistList(downloadsOnly: $downloadedOnly)){
                    HStack {
                        Image(systemName: "music.mic")
                            .frame(width: 50, height: 10, alignment: .leading)
                            .foregroundColor(Color("Purple"))
                        Text("Artists")
                    }
                    .padding(8)
                    .font(.system(size: 22, weight: .regular, design: .default))
                }
                .buttonStyle(PlainButtonStyle())
                NavigationLink(destination: AlbumList(downloadsOnly: $downloadedOnly)){
                    HStack {
                        Image(systemName: "rectangle.stack")
                            .frame(width: 50, height: 10, alignment: .leading)
                            .foregroundColor(Color("Purple"))
                        Text("Albums")
                    }
                    .padding(8)
                    .font(.system(size: 22, weight: .regular, design: .default))
                }
                .buttonStyle(PlainButtonStyle())
                NavigationLink(destination: SongList(downloadsOnly: $downloadedOnly)){
                    HStack {
                        Image(systemName: "music.note")
                            .frame(width: 50, height: 10, alignment: .leading)
                            .foregroundColor(Color("Purple"))
                        Text("Songs")
                    }
                    .padding(8)
                    .font(.system(size: 22, weight: .regular, design: .default))
                }
                .buttonStyle(PlainButtonStyle())
                LazyVGrid(columns:Array(repeating: GridItem(.flexible(), spacing: 20), count: 2), spacing: 15){
                    if(albums.count > 0){
                        Section(header: Text("Recently Added").font(.system(size: 22, weight: .semibold)).frame(width: UIScreen.main.bounds.width - 30, alignment: .leading).padding(.top, 0).transition(.opacity)){
                            ForEach(albums.filter{ $0.downloaded }.compactMap({ $0.album }).uniques.prefix(20), id: \.self){ album in
                                if(album.id != nil){
                                    AlbumCover(album, downloadsOnly: $downloadedOnly)
                                }
                            }
                        }
                    }
//                    Spacer().frame(height: 80)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.top, 30)
            .listStyle(PlainListStyle())
        }
        .navigationBarTitle("Downloaded", displayMode: .inline)
    }
}

extension Array where Element: Hashable {
    var uniques: Array {
        var buffer = Array()
        var added = Set<Element>()
        for elem in self {
            if !added.contains(elem) {
                buffer.append(elem)
                added.insert(elem)
            }
        }
        return buffer
    }
}
