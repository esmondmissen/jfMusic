//
//  ArtistList.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 7/10/20.
//

import SwiftUI

struct ArtistList: View {
    @ObservedObject var nw: NetworkingManager = NetworkingManager.shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.managedObjectContext) var moc
    @Binding var downloadsOnly: Bool
    @State var searchText = ""
    @FetchRequest(entity: Artist.entity(), sortDescriptors: [
        NSSortDescriptor(keyPath: \Artist.sortName, ascending: true)
    ]) var artists: FetchedResults<Artist>
    
    init(downloadsOnly: Binding<Bool> = .constant(false)){
        self._downloadsOnly = downloadsOnly
    }
    
    var body: some View {
        ZStack(alignment: .top){
            ScrollView(showsIndicators: true){
                LazyVStack{
                    ForEach(artists.filter{ downloadsOnly ? $0.hasSongs : true}.filter { !$0.albumsArray.isEmpty && searchText == "" ? true : $0.name!.localizedStandardContains(searchText) }, id: \.id){ artist in
                    NavigationLink(destination:ArtistOverview(artist: artist, downloadsOnly: $downloadsOnly)){
                        ArtistContextMenu(artistId: artist.id!){
                        HStack{
                            AsyncImage(
                                url: URL(string:nw.getAlbumArt(id: artist.id!, maxSize: 100))!,
                                placeholder: { Rectangle().fill(colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.2))
                                    .overlay(Image(systemName: "person.fill")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(height: 38)
                                                .offset(y: 6)
                                                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.2)))
                                },
                               image: {
                                Image(uiImage: $0).resizable()
                                    .renderingMode(.original)
                               }
                            )
                            .frame(width:46, height: 46)
                            .cornerRadius(23)
                            .aspectRatio(contentMode: .fit)
                            HStack{
                                Text(artist.name!)
                                    .foregroundColor(.primary).padding(.leading, 10)
                                Spacer()
                            }.border(width: 0.25, edge: .bottom, color: colorScheme == .dark ? Color.gray.opacity(0.6) : .gray)
                        }
                        }
                    }
                }
            }.padding(.leading, 15).padding(.top, downloadsOnly ? 35 : 0)
            }
        }
        .navigationBarTitle("Artists")
//        .navigationBarSearch(self.$searchText, placeholder: "Find in Artists")
    }
}

struct ArtistList_Previews: PreviewProvider {
    static var previews: some View {
        ArtistList()
    }
}
