//
//  Playlists.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 10/10/20.
//

import SwiftUI

struct Playlists: View {
    @State var showingDetail = false
    @Binding var downloadsOnly: Bool
    @ObservedObject var nw: NetworkingManager = NetworkingManager.shared
    @Environment(\.managedObjectContext) var moc
    @State var searchText = ""
    @FetchRequest(entity: Playlist.entity(), sortDescriptors: [
        NSSortDescriptor(keyPath: \Playlist.sortName, ascending: true)
    ]) var playlists: FetchedResults<Playlist>
    
    init(downloadsOnly: Binding<Bool> = .constant(false)){
        self._downloadsOnly = downloadsOnly
    }
    
    var body: some View {
        ZStack(alignment: .top){
            ScrollView{
                LazyVStack(spacing: 0, pinnedViews: downloadsOnly ? [.sectionHeaders] : []){
                    Button(action: {
                            self.showingDetail.toggle()}, label: {
                    HStack{
                        Rectangle().fill(LinearGradient(gradient: Gradient(colors: [Color("Purple").opacity(0.4), Color(red:21/255, green: 145/255, blue: 209/255).opacity(0.5)]), startPoint: .top, endPoint: .trailing))
                            .overlay(
                                Image(systemName: "plus")
                                    .resizable()
                                    .foregroundColor(Color.gray.opacity(0.3))
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 40)
                                    .blendMode(.multiply)
                            )
                            .frame(width: 80, height: 80)
                            .cornerRadius(4)
                        HStack{
                            Text("New Playlist...")
                                .foregroundColor(Color("Purple"))
                            Spacer()
                        }.frame(height:95).border(width: 0.25, edge: .top, color: .gray)
                        .border(width: 0.25, edge: .bottom, color: .gray)
                    }
                    }).sheet(isPresented: $showingDetail) {
                        NavigationView {
                            NewPlaylist()
                        }
                    }
                        .padding(.vertical, 7.5)
                        .padding(.leading, 15)
                        ForEach(self.playlists.filter({ downloadsOnly ? $0.id != nil && $0.songArray.contains(where: { song in song.downloaded}) : $0.id != nil}), id: \.self){ playlist in
                        NavigationLink(
                            destination: PlaylistView(album: playlist),
                            label: {
                                HStack{
                                    AsyncImage(
                                        url: URL(string:NetworkingManager.shared.getAlbumArt(id: playlist.id!))!,
                                        placeholder: { Rectangle().fill(Color.gray.opacity(0.2))
                                            .overlay(
                                                Image(systemName: "music.note")
                                                    .resizable()
                                                    .foregroundColor(Color.gray.opacity(0.3))
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 30)
                                                    
                                            ) },
                                       image: {
                                        Image(uiImage: $0).resizable()
                                            .renderingMode(.original)
                                       }
                                    )
                                    .frame(width: 80, height: 80)
                                    .cornerRadius(4)
                                    .aspectRatio(contentMode: .fit)
                                    HStack{
                                        Text(playlist.name!)
                                            .foregroundColor(.primary)
                                        Spacer()
                                    }.frame(height:95).border(width: 0.25, edge: .bottom, color: .gray)
                                }
                                
                            })
                            .contextMenu {
                                Button(action: {
                                    nw.instantMix(id: playlist.id!, downloadsOnly: false)
                                }, label: {
                                    HStack{
                                        Text("Instant Mix")
                                        Image(systemName: "list.star")
                                    }
                                })
                                Button(action: {
                                    nw.deletePlaylist(playlistId: playlist.id!, completion: { res in
                                        if res{
                                            moc.delete(playlist)
                                            try! moc.save()
                                        }
                                    })
                                }) {
                                    Text("Delete from Library")
                                    Image(systemName: "trash")
                                }
                            }
                            .padding(.vertical, 7.5)
                            .padding(.leading, 15)
                        }.animation(.default)
                        .transition(.opacity)
                        Spacer().frame(width:50, height: UIScreen.main.bounds.height - 110 * CGFloat(self.playlists.filter({ $0.id != nil}).count + 2))
                }
            }
            .padding(.top, downloadsOnly ? 30 : 0)
            .navigationBarTitle("Playlists", displayMode: downloadsOnly ? .inline : .large)
            .onAppear{
                NetworkingManager.shared.syncPlaylists(completion: {_ in
                    print("Complete!")
                })
            }
        }
    }
}

struct AddToPlaylist: View {
    @State var showingDetail = false
    @ObservedObject var nw: NetworkingManager = NetworkingManager.shared
    @Environment(\.managedObjectContext) var moc
    @State var searchText = ""
    @FetchRequest(entity: Playlist.entity(), sortDescriptors: [
        NSSortDescriptor(keyPath: \Playlist.sortName, ascending: true)
    ]) var playlists: FetchedResults<Playlist>
    let action: ((String) -> Void)
    init(action: @escaping (String) -> Void){
        self.action = action
    }
    
    var body: some View {
        ScrollView{
            LazyVStack{
                Button(action: {
                        self.showingDetail.toggle()}, label: {
                HStack{
                    Image("Placeholder").resizable().aspectRatio(contentMode: .fit)
                        .frame(width: 80)
                    Text("New Playlist...")
                        .foregroundColor(Color("Purple"))
                    Spacer()
                    }
                }).sheet(isPresented: $showingDetail) {
                    NavigationView {
                        NewPlaylist()
//                            .environment(\.managedObjectContext, self.moc)
                    }
                }
                ForEach(self.playlists, id: \.self){ playlist in
                    Button(action: {
                        self.action(playlist.id!)
                    }){
                        HStack{
                            Image("Placeholder").resizable().aspectRatio(contentMode: .fit)
                                .frame(width: 80)
                            Text(playlist.name!)
                            Spacer()
                        }
                    }
                }
            }.padding(.vertical, 7.5)
            .padding(.horizontal, 15)
        }.navigationBarTitle("Playlists", displayMode: .large)
        .onAppear{
            NetworkingManager.shared.syncPlaylists(completion: {_ in })
        }
    }
}

struct NewPlaylist: View{
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.managedObjectContext) var moc
    @State private var songs: [Song] = []
    @State private var name = ""
    @State private var description = ""
    @State private var selectSongs = false
    let imageWidth = (UIScreen.main.bounds.width - (global.padding * 2) - 20) / 2
    var body: some View{
        ScrollView{
            VStack{
                Spacer()
                Rectangle().fill(Color.gray.opacity(0.2))
                    .frame(width: imageWidth, height: imageWidth)
                    .overlay(
                        Image(systemName: "music.note")
                            .resizable()
                            .foregroundColor(Color.gray.opacity(0.3))
                            .aspectRatio(contentMode: .fit)
                            .frame(width: imageWidth * 0.375)
                    )
                TextField("Playlist Name", text: $name)
                    .font(.system(size: 20, weight: .semibold, design: .default))
                    .multilineTextAlignment(.center)
                    .padding(15)
                Divider()
                TextField("Description", text: $description)
                    .padding(.all, 15)
                
//                Button(action: { self.selectSongs = true }, label: {
//                        HStack{
//                            Image(systemName: "plus.circle.fill")
//                                .resizable()
//                                .aspectRatio(contentMode: .fit)
//                                .frame(width: 20)
//                                .foregroundColor(.green)
//                            Text("Add Music")
//                                .foregroundColor(Color("Purple"))
//                            Spacer()
//                        }.padding(.all, 15)
//                }).sheet(isPresented: $selectSongs){
//                        NavigationView{
//                            List{
//                                NavigationLink(destination: ArtistList()){
//                                    HStack {
//                                        Image(systemName: "music.mic")
//                                            .frame(width: 50, height: 10, alignment: .leading)
//                                            .foregroundColor(Color("Purple"))
//                                        Text("Artists")
//                                    }
//                                    .padding(8)
//                                    .font(.system(size: 22, weight: .regular, design: .default))
//                                }
//                                NavigationLink(destination: AlbumList()){
//                                    HStack {
//                                        Image(systemName: "rectangle.stack")
//                                            .frame(width: 50, height: 10, alignment: .leading)
//                                            .foregroundColor(Color("Purple"))
//                                        Text("Albums")
//                                    }
//                                    .padding(8)
//                                    .font(.system(size: 22, weight: .regular, design: .default))
//                                }
//                            }
//                        }
//                    }
//                    .frame(width: UIScreen.main.bounds.width)
                    
                List{
                }
            }.padding(.vertical, 15)
            .navigationBarItems(leading: Button("Cancel"){
                self.presentationMode.wrappedValue.dismiss()
                }.foregroundColor(Color("Purple"))
            .font(.system(size: 17, weight: .regular, design: .default)),
                                trailing: Button("Done"){
                                    if self.name != "" {
                                        NetworkingManager.shared.createPlaylist(name: self.name, completion: { success in
                                            if success{
                                                self.presentationMode.wrappedValue.dismiss()
                                            }
                                        })
                                    }
                }.font(.system(size: 17, weight: .semibold, design: .default))
            .foregroundColor(Color("Purple")))
                    .navigationBarTitle("New Playlist", displayMode: .inline)
        }
    }
}
