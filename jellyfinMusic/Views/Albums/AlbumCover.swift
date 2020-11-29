//
//  AlbumCover.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 30/9/20.
//

import SwiftUI
//import SwURL

struct global{
    public static let padding: CGFloat = 15
}

struct AlbumCover: View{
    @ObservedObject var nw: NetworkingManager = NetworkingManager.shared
    @Environment(\.colorScheme) var colorScheme
    let album: Album
    @State private var isActive: Bool = false
    @State private var visible: Bool = false
    @State private var addToPlaylist: Bool = false
    @Binding var downloadsOnly: Bool
    let showYear: Bool
    let imageWidth = (UIScreen.main.bounds.width - (global.padding * 2) - 20) / 2
    init(_ album: Album, showYear: Bool = false, downloadsOnly: Binding<Bool> = .constant(false)) {
        self.album = album
        self.showYear = showYear
        self._downloadsOnly = downloadsOnly
    }
    var body: some View{
//        GeometryReader { (geometry) in
        VStack(alignment: .leading){
            if album.albumImage != nil {
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
            }else{
                PlaceholderImage(imageWidth: imageWidth)
                    .frame(width:imageWidth, height: imageWidth)
                    .aspectRatio(contentMode: .fit)
            }
            Text(album.name!)
                .onTapGesture(){
                    isActive = true
                }
            Text((showYear ? "\(album.productionYear)" : album.albumArtist)!)
                .foregroundColor(.gray)
                .onTapGesture(){
                    isActive = true
                }
            NavigationLink(destination: AlbumView(album: album, downloadsOnly: $downloadsOnly), isActive: $isActive){
                EmptyView()
            }
            .hidden()
        }.font(.system(size: 16))
        .lineLimit(1)
        .truncationMode(.tail)
        .onTapGesture(){
            isActive = true
        }
        .contextMenu {
            Button(action: {
                addToPlaylist = true
                        }) {
                            Text("Add to Playlist")
                            Image(systemName: "music.note.list")
                        }
        }
        .sheet(isPresented: $addToPlaylist, content: {
            AddToPlaylist(action: {
                nw.addToPlaylist(playlistId: $0, itemId: album.id!, completion: { _ in
                    self.addToPlaylist = false
                })
            })
        })
        }
}


struct PlaceholderImage: View{
    var imageWidth: CGFloat? = nil
    var body: some View{
        GeometryReader{ geo in
            Rectangle().fill(Color.gray.opacity(0.2))
                .overlay(
                    Image(systemName: "music.note")
                        .resizable()
                        .foregroundColor(Color.gray.opacity(0.3))
                        .aspectRatio(contentMode: .fit)
                        .frame(width: imageWidth != nil ? imageWidth!  * 0.375 : (geo.size.width > 0 ? geo.size.width : 1) * 0.375 )
                        
                )
                .frame(width:imageWidth, height: imageWidth)
                .aspectRatio(contentMode: .fit)
        }
    }
}
