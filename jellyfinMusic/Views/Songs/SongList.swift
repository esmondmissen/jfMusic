//
//  SongList.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 15/10/20.
//

import SwiftUI

struct SongList: View {
    @ObservedObject var nw: NetworkingManager = NetworkingManager.shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.managedObjectContext) var moc
    @State var searchText = ""
    @State private var sort: Int = 0
    @Binding var downloadsOnly: Bool
    @FetchRequest(entity: Song.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Song.name, ascending: true)]) var songsName: FetchedResults<Song>
    @FetchRequest(entity: Song.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Song.album?.sortArtist, ascending: true)]) var songsArt: FetchedResults<Song>
    @FetchRequest(entity: Song.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Song.album?.createdDate, ascending: false)]) var songsDate: FetchedResults<Song>
    
    init(downloadsOnly: Binding<Bool> = .constant(false)){
        self._downloadsOnly = downloadsOnly
    }
    
    var body: some View {
        ScrollView(showsIndicators: false){
        LazyVStack{
            ForEach((sort == 0 ? songsName : sort == 1 ? songsDate : songsArt).filter { (downloadsOnly ? $0.downloaded : true) && searchText == "" ? true : $0.name!.localizedStandardContains(searchText) }, id: \.id){ song in
                if song.album != nil {
                    Button(action: {
                        nw.playSong(song: song, from: From(name: "", id: "", type: .allSongs))
                    }){
                        SongContextMenu(song:song){
                            SongViewCompact2(song: song)
                                .frame(width: UIScreen.main.bounds.width)
                        }
                    }
                    .buttonStyle(PlainListButtonStyle())
                }
            }
            Spacer().frame(height: 80)
        }.padding(.leading, 15).padding(.top, downloadsOnly ? 35 : 0)
        }.navigationBarTitle("Songs")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Picker(selection: $sort, label: Text("Sorting options")) {
                        Text("Title").tag(0)
                        Text("Recently Added").tag(1)
                        Text("Artist").tag(2)
                    }
                }
                label: {
                    Text("Sort")
                }
            }
        }
    }
}
