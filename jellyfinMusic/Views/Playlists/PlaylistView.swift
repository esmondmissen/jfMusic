//
//  PlaylistView.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 25/10/20.
//

import SwiftUI

struct PlaylistView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var nw: NetworkingManager = NetworkingManager.shared
    let playlist: Playlist
    let imageWidth = UIScreen.main.bounds.width/1.5
    @State var showingAlert: Bool = false
    @Environment(\.managedObjectContext) var moc
    var fetchRequest: FetchRequest<PlaylistSong>
    
    init(album: Playlist) {
        self.playlist = album
        fetchRequest = FetchRequest<PlaylistSong>(entity: PlaylistSong.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \PlaylistSong.order, ascending: true)], predicate: NSPredicate(format: "playlist.id = %@", album.id!))
    }
    
    var body: some View {
        ScrollView(.vertical) {
                LazyVStack(spacing:0) {
                    HStack{
                        Spacer()
                            Rectangle()
                                .fill(Color.clear)
                                .background(
                                    AsyncImage(
                                        url: URL(string:NetworkingManager.shared.getAlbumArt(id: self.playlist.id ?? ""))!,
                                        placeholder: { Rectangle().fill(Color.gray.opacity(0.2))
                                            .overlay(
                                                Image(systemName: "music.note")
                                                    .resizable()
                                                    .foregroundColor(Color.gray.opacity(0.3))
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: imageWidth * 0.375)
                                            )},
                                       image: {
                                        Image(uiImage: $0).resizable()
                                            .renderingMode(.original)
                                       }
                                    )
                                    .cornerRadius(8)
                                    .frame(width:imageWidth, height: imageWidth)
                                    .aspectRatio(contentMode: .fit)
                            ).frame(width: imageWidth, height: imageWidth, alignment: .center)
                        Spacer()
                    }.zIndex(4).padding(.bottom, 10)
                    VStack{
                        HStack(alignment:.center){
                            Spacer()
                            VStack(alignment:.center, spacing:3){
                                Text(playlist.name ?? "").lineLimit(1)
                                    .font(.system(size: 20, weight: .bold, design: .default))
                            }
                            Spacer()
                        }.padding(.top, 10)

                        HStack(alignment:.center, spacing:15){
                            Button(action: {
                                if !fetchRequest.wrappedValue.isEmpty{
                                    nw.playSong(song: fetchRequest.wrappedValue.first!.song!, from: From(name: playlist.name!, id: playlist.id!, type: .playlist))
                                }
                            }){
                                HStack{
                                    Image(systemName: "play.fill")
                                    Text("Play")
                                        .fontWeight(.bold)
                                }.foregroundColor(Color("PrimaryFont")).frame(minWidth: 0, maxWidth: UIScreen.main.bounds.width/2)
                            }.buttonStyle(LargeButtonStyle(bgColor: Color("Primary")))
                            Button(action: {
                                if !fetchRequest.wrappedValue.isEmpty{
                                    nw.playSong(song: fetchRequest.wrappedValue.randomElement()!.song!, from: From(name: playlist.name!, id: playlist.id!, type: .playlist))
                                    Player.shared.playmode = .random
                                }
                            }){
                                HStack{
                                    Image(systemName: "shuffle")
                                    Text("Shuffle")
                                        .fontWeight(.bold)
                                }.foregroundColor(Color("PrimaryFont"))
                                .frame(minWidth: 0, maxWidth: UIScreen.main.bounds.width/2)
                            }.buttonStyle(LargeButtonStyle(bgColor: Color("Primary")))
                        }.padding(.all, 15)
                        List{
                            ForEach(fetchRequest.wrappedValue, id: \.id) { song in
                                Button(action: {
                                    nw.playSong(song: song.song!, from: From(name: playlist.name!, id: playlist.id!, type: .playlist))
                                }){
                                    SongContextMenu(song: song.song!){
                                        SongViewCompact2(song: song.song!, border: false)
                                    }
                                }.buttonStyle(PlainListButtonStyle())
                            }.onDelete(perform: deleteItems)
                            .onMove(perform: move)
                        }.frame(height: CGFloat(fetchRequest.wrappedValue.count) * 66)
                        VStack(alignment: .leading){
                            Text("\(playlist.songs?.count ?? 0) Song\(playlist.songs?.count ?? 0 == 1 ? "" : "s")")
                                .foregroundColor(.gray).multilineTextAlignment(.leading)
                        }.padding(.all, 15)
                        Spacer()
                            .frame(width: 100, height: 100, alignment: .center)
                    }.navigationBarItems(trailing: EditButton())
                }
                .offset(y: -35)
                .padding(.top, 15)
            }
    }
    
    func deleteItems(at offsets: IndexSet){
        let item = fetchRequest.wrappedValue[offsets.first!]
        nw.deleteFromPlaylist(playlistId: self.playlist.id!, itemId: item.playlistItemId!){ _ in }
        moc.delete(item)
        try! moc.save()
    }
    
    func move(from source: IndexSet, to destination: Int) {
        let item = fetchRequest.wrappedValue[source.first!]
        item.order = Int16(destination)

        let updateItems = fetchRequest.wrappedValue.sorted(by: { $0.order < $1.order || ($0.order == $1.order && $0.id == item.id )})
        for index in 0...updateItems.count - 1{
            updateItems[index].order = Int16(index)
        }
        try! moc.save()
        nw.movePlaylistItem(playlistId: playlist.id!, itemId: item.playlistItemId!, newPosition: Int(item.order), completion: { _ in })
    }
}
