//
//  AlbumList.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 3/10/20.
//

import SwiftUI
import SwiftlySearch

struct AlbumList: View {
    @ObservedObject var nw: NetworkingManager = NetworkingManager.shared
    @Environment(\.managedObjectContext) var moc
    @State var searchText = ""
    @Binding var downloadsOnly: Bool
    @FetchRequest(entity: Album.entity(), sortDescriptors: [
                    NSSortDescriptor(keyPath: \Album.sortArtist, ascending: true)
    ]) var albums: FetchedResults<Album>
    
    init(downloadsOnly: Binding<Bool> = .constant(false)){
        self._downloadsOnly = downloadsOnly
    }
    
    var body: some View {
        ZStack(alignment: .top){
            
            ScrollView{
                LazyVGrid(columns:Array(repeating: GridItem(.flexible(), spacing: 20), count: 2), spacing: 15){
                    Spacer().frame(height: downloadsOnly ? 5 : 0)
                    Spacer().frame(height: downloadsOnly ? 5 : 0)
                    ForEach(albums.filter{ downloadsOnly ? $0.hasDownloads : true && searchText == "" ? true : ($0.name?.localizedStandardContains(searchText) ?? false) || ($0.albumArtist!.localizedStandardContains(searchText))}, id: \.self){ album in
                        AlbumCover(album, downloadsOnly: $downloadsOnly)
                    }
                }.padding(.horizontal, 15)
            }.navigationTitle("Albums").padding(.top, downloadsOnly ? 30 : 0)
        }
    }
}

struct AlbumList_Previews: PreviewProvider {
    static var previews: some View {
        AlbumList()
    }
}
