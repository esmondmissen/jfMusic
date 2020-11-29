//
//  AlbumView.swift
//  jFin
//
//  Created by Esmond Missen on 30/7/20.
//

import SwiftUI

struct AlbumView: View {
    @ObservedObject var nw: NetworkingManager = NetworkingManager.shared
    @ObservedObject var album: Album
    @Binding var downloadsOnly: Bool
    @State var selectedSong: Song? = nil
    @State var updateContextMenu: Bool = false
    @State var addToPlaylist: Bool = false
    @Environment(\.managedObjectContext) var moc
    let variousAlbum: Bool
    let imageWidth = UIScreen.main.bounds.width/1.5
    init(album: Album, downloadsOnly: Binding<Bool> = .constant(false)){
        self.album = album
        variousAlbum = album.albumArtist == "Various Artists"
        self._downloadsOnly = downloadsOnly
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
                                        url: URL(string:NetworkingManager.shared.getAlbumArt(id: self.album.id!))!,
                                        placeholder: { PlaceholderImage(imageWidth: imageWidth) },
                                       image: {
                                        Image(uiImage: $0).resizable()
                                            .renderingMode(.original)
                                       }
                                    )
                                    .frame(width:imageWidth, height: imageWidth)
                                    .aspectRatio(contentMode: .fit)
                                    .shadow(radius: 50)
                            ).frame(width: imageWidth, height: imageWidth, alignment: .center)
                        Spacer()
                    }.zIndex(4).padding(.bottom, 10)
                    VStack{
                        HStack(alignment:.center){
                            Spacer()
                            VStack(alignment:.center, spacing:3){
                                Text(album.name!).lineLimit(1)
                                    .font(.system(size: 20, weight: .bold, design: .default))
                                HStack{
                                    ForEach(album.artistsArray, id: \.self){ artist in
                                        NavigationLink(destination: ArtistOverview(artist: artist, downloadsOnly: $downloadsOnly)){
                                            Text(artist.name ?? "")
                                                .font(.system(size: 20, weight: .medium, design: .default))
                                            .foregroundColor(Color("Purple"))
                                        }
                                        if ((album.artistsArray.last!.id ?? "1") != (artist.id ?? "2")){
                                            Text("and").foregroundColor(.gray)
                                        }
                                    }
                                }
                                HStack(alignment: .center, spacing: 0, content: {
                                    if !variousAlbum && !album.genreArray.isEmpty {
                                        Text(album.wrappedGenres.uppercased())
                                        if album.productionYear != 0{
                                            Text(" · ")
                                        }
                                    }
                                    Text(album.wrappedProductionYear)
                                }).font(.system(size: 11, weight: .semibold, design: .default)).foregroundColor(.gray)
                                .animation(.spring())
                            }
                            Spacer()
                        }.padding(.top, 10)

                        HStack(alignment:.center, spacing:15){
                            Button(action: {
//                                NetworkingManager.shared.playAlbum(albumId: album.id)
                            }){
                                HStack{
                                    Image(systemName: "play.fill")
                                    Text("Play")
                                        .fontWeight(.bold)
                                }.foregroundColor(Color("PrimaryFont")).frame(minWidth: 0, maxWidth: UIScreen.main.bounds.width/2)
                            }.buttonStyle(LargeButtonStyle(bgColor: Color("Primary")))
                            Button(action: {
//                                NetworkingManager.shared.playAlbum(albumId: album.id, shuffle: true)
                            }){
                                HStack{
                                    Image(systemName: "shuffle")
                                    Text("Shuffle")
                                        .fontWeight(.bold)
                                }.foregroundColor(Color("PrimaryFont"))
                                .frame(minWidth: 0, maxWidth: UIScreen.main.bounds.width/2)
                            }.buttonStyle(LargeButtonStyle(bgColor: Color("Primary")))
                        }.padding(.all, 15)
                        LazyVStack(spacing: 0){
                            ForEach(album.songArray.filter{ self.downloadsOnly ? $0.downloaded : true }.sorted(by: {
                                if $0.diskNumber != $1.diskNumber{
                                    return $0.diskNumber < $1.diskNumber
                                }else{
                                    return $0.trackNumber < $1.trackNumber 
                                }
                            }), id: \.id) { song in
                            Button(action:{
                                nw.playSong(song: song, from: From(name: album.name!, id: album.id!, type: .album), downloaded: downloadsOnly)
                            }){
                                SongViewWithDownload(song: song, parentType: .album)
                                    .padding(0)
//                                    .contextMenu {
//                                        Button(action: {
//                                            self.selectedSong = song
//                                            nw.favouriteSong(song: song, isFavourite: !song.isFavourite){ res in
//                                                print("successfully \(song.isFavourite ? "loved" : "unloved") song")
//                                                updateContextMenu.toggle()
//                                            }
//                                        }, label: {
//                                            Text(song.isFavourite ? "Unlove" : "Love")
//                                                .rotationEffect(updateContextMenu ? .degrees(-00) : .degrees(-360))
//                                            Image(systemName: song.isFavourite ? "heart.slash" : "heart")
//                                        })
//                                        Button(action: {
//                                            self.selectedSong = song
//                                            addToPlaylist = true
//                                                    }) {
//                                                        Text("Add to Playlist")
//                                                        Image(systemName: "music.note.list")
//                                                    }
//                                        Button(action: {
//                                            nw.playNext(song: song, from: From(name: album.name!, id: album.id!, type: .album))
//                                                    }) {
//                                                        Text("Play Next")
//                                                        Image(systemName: "text.insert")
//                                                    }
//                                        Button(action: {
//                                            nw.playLast(song: song, from: From(name: album.name!, id: album.id!, type: .album))
//                                                    }) {
//                                                        Text("Play Last")
//                                                        Image(systemName: "text.append")
//                                                    }
//                                        Button(action: {
//                                            if song.downloaded{
//                                                song.removeDownload()
//                                            }else{
//                                                song.download()
//                                            }
//                                                    }) {
//                                            Text(song.downloaded ? "Remove Download" : "Download")
//                                            Image(systemName: song.downloaded ? "trash" : "plus")
//                                        }
//                                    }
                            }.buttonStyle(PlainListButtonStyle()).padding(0)
                            .disabled(!nw.online && !song.downloaded)
                            .opacity(!nw.online && !song.downloaded ? 0.4 : 1)
                        }

                        }.sheet(isPresented: $addToPlaylist, content: {
                            AddToPlaylist(action: {
                                nw.addToPlaylist(playlistId: $0, itemId: selectedSong!.id!, completion: { _ in
                                    self.addToPlaylist = false
                                })
                            }).environment(\.managedObjectContext, self.moc)
                        })
                        VStack(alignment: .leading){
                            Text("\(album.songs!.count) Song\(album.songs!.count == 1 ? "" : "s")")
                                .foregroundColor(.gray).multilineTextAlignment(.leading)
                        }.padding(.all, 15)
                        Spacer()
                            .frame(width: 100, height: 100, alignment: .center)
                    }
                }
                .offset(y: downloadsOnly ? 30 : -35)
                .padding(.top, 15)
            }
        .navigationBarTitle("", displayMode: downloadsOnly ? .inline : .large)
//        .toolbar {
//                ToolbarItem(placement: .primaryAction) {
//                    if !album.isDownloaded {
//                        Button(action: {
//                            for song in album.songArray{
//                                song.download()
//                            }
//                        }, label: {
//                            Image(systemName: "plus")
//                                .resizable()
//                                .aspectRatio(contentMode: .fit)
//                                .foregroundColor(Color("Purple"))
//                                .frame(width: 18)
//                        })
//                    }
//            }
//        }
    }
}
