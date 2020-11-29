//
//  ArtistOverview.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 25/10/20.
//

import SwiftUI

struct ArtistOverview: View {
    @ObservedObject var nw: NetworkingManager = NetworkingManager.shared
    let artist: Artist
    @Binding var downloadsOnly: Bool
    @State private var songs: [Song] = []
    @State private var similar: [Artist] = []
    @State private var updateContextMenu: Bool = false
    init(artist: Artist, downloadsOnly: Binding<Bool> = .constant(false)){
        self.artist = artist
        self._downloadsOnly = downloadsOnly
    }
    var body: some View {
        ScrollView{
            VStack{
                if !songs.isEmpty{
                    CustomSectionView("Top Songs"){
                        HorizontalList{
                            ForEach(0...Int(self.songs.count > 8 ? 2 : self.songs.count > 4 ? 1 : 0), id: \.self){ index in
                                LazyVStack(alignment: .leading, spacing: 0){
                                    if index == 0{
                                        ForEach(self.songs[0...(4 * index) + min(3, songs.count - 1)], id: \.id){ song in
                                            Button(action: {
                                                nw.playSong(song: song, from: From(name: "Top Songs - \(song.album!.albumArtist!)", id: "", type: .topSongs))
                                            }){
                                                SongContextMenu(song: song){
                                                    SongViewCompact(song: song)
                                                        .frame(width: UIScreen.main.bounds.width - 15 * 3)
                                                        .animation(Animation.default.delay(0.25))
                                                        .transition(.opacity)
                                                }
                                                .buttonStyle(PlainListButtonStyle())
                                            }
                                        }
                                    }else {
                                        ForEach(self.songs[4 * index...(4 * index) + min(3, songs.dropFirst(4 * index).count - 1)], id: \.id){ song in
                                            Button(action: {
                                                nw.playSong(song: song, from: From(name: "Top Songs - \(song.album!.albumArtist!)", id: "", type: .topSongs))
                                            }){
                                                SongContextMenu(song: song){
                                                    SongViewCompact(song: song)
                                                        .frame(width: UIScreen.main.bounds.width - 15 * 3)
                                                        .animation(Animation.default.delay(0.25))
                                                        .transition(.opacity)
                                                }
                                            }
                                            .buttonStyle(PlainListButtonStyle())
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                if !artist.albumsArray.filter{ downloadsOnly ? $0.hasDownloads : true}.isEmpty{
                    CustomSectionView("Albums"){
                        HorizontalList{
                            ForEach(artist.albumsArray.filter{ downloadsOnly ? $0.hasDownloads : true}, id: \.self){ album in
                                AlbumCover(album, showYear: true, downloadsOnly: $downloadsOnly)
                                    .frame(width: UIScreen.main.bounds.width/2 - (15 * 2))
                            }
                        }
                    }
                }
                if !artist.appearsArray.filter{ downloadsOnly ? $0.hasDownloads : true}.isEmpty{
                    CustomSectionView("Appears On"){
                        HorizontalList{
                            ForEach(artist.appearsArray.filter{ downloadsOnly ? $0.hasDownloads : true}, id: \.self){ album in
                                AlbumCover(album, showYear: true, downloadsOnly: $downloadsOnly)
                                    .frame(width: UIScreen.main.bounds.width/2 - (15 * 2))
                            }
                        }
                    }
                }
                if !similar.isEmpty{
                    CustomSectionView("Similar Artists"){
                        HorizontalList{
                            ForEach(self.similar, id: \.self){ simArt in
                                NavigationLink(destination: ArtistOverview(artist: simArt, downloadsOnly: $downloadsOnly)){
                                    VStack(alignment: .center){
                                        AsyncImage(
                                            url: URL(string:nw.getAlbumArt(id: simArt.id!))!,
                                            placeholder: { Rectangle().fill(Color.black) },
                                           image: {
                                            Image(uiImage: $0).resizable()
                                                .renderingMode(.original)
                                           }
                                        )
                                        .frame(width:126, height: 126)
                                        .aspectRatio(contentMode: .fit)
                                        .cornerRadius(63)
                                        Text(simArt.name!)
                                            .foregroundColor(.primary)
                                            .multilineTextAlignment(.center)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .frame(width:126).lineLimit(2)
                                    }
                                }
                            }
                        }
                    }
                }
                Spacer().frame(height: 80)
            }
        }.navigationBarTitle(artist.name!, displayMode: downloadsOnly ? .inline : .large)
        .padding(.top, downloadsOnly ? 30 : 0)
        .onAppear(){
            nw.getTopSongs(artist: artist, downloadsOnly: self.downloadsOnly, completion: { songs in
                self.songs = songs
            })
            nw.getSimilarArtists(artist: artist, downloadsOnly: self.downloadsOnly, completion: { artists in
                self.similar = artists
            })
        }
    }
}

