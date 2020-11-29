//
//  ContentView.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 29/9/20.
//

import SwiftUI
import NavigationBarLargeTitleItems

struct ContentView: View {
    @ObservedObject var nw: NetworkingManager = NetworkingManager.shared
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(entity: Album.entity(), sortDescriptors: [
                    NSSortDescriptor(keyPath: \Album.createdDate, ascending: false)
    ]) var albums: FetchedResults<Album>
    
    @State private var rect1: CGRect = CGRect()
    @State private var selection: String? = UserDefaults.standard.bool(forKey: "StartAtDownloads") ? "downloads" : nil
    @State private var accountSheet: Bool = false
    @State private var safeArea: CGRect = CGRect()
    @State private var showPlayer: Bool = false
    var body: some View {
        let downloadsOnly = Binding<Bool>(get: { return self.selection != nil },
                                          set: { _ = $0 })
        if !nw.authenticated {
                LoginView()
                    .transition(.opacity)
            }else{
                ZStack(alignment: .top){
                    NavigationView{
                        ZStack(alignment: .top){
                            
                            List{
                                NavigationLink(destination: Playlists()){
                                    HStack {
                                        Image(systemName: "music.note.list")
                                            .frame(width: 50, height: 10, alignment: .leading)
                                            .foregroundColor(Color("Purple"))
                                        Text("Playlists")
                                    }
                                    .padding(8)
                                    .font(.system(size: 22, weight: .regular, design: .default))
                                }
                                NavigationLink(destination: ArtistList()){
                                    HStack {
                                        Image(systemName: "music.mic")
                                            .frame(width: 50, height: 10, alignment: .leading)
                                            .foregroundColor(Color("Purple"))
                                        Text("Artists")
                                    }
                                    .padding(8)
                                    .font(.system(size: 22, weight: .regular, design: .default))
                                }
                                NavigationLink(destination: AlbumList()){
                                    HStack {
                                        Image(systemName: "rectangle.stack")
                                            .frame(width: 50, height: 10, alignment: .leading)
                                            .foregroundColor(Color("Purple"))
                                        Text("Albums")
                                    }
                                    .padding(8)
                                    .font(.system(size: 22, weight: .regular, design: .default))
                                }
                                NavigationLink(destination: SongList()){
                                    HStack {
                                        Image(systemName: "music.note")
                                            .frame(width: 50, height: 10, alignment: .leading)
                                            .foregroundColor(Color("Purple"))
                                        Text("Songs")
                                    }
                                    .padding(8)
                                    .font(.system(size: 22, weight: .regular, design: .default))
                                }//MainMenu
                                    NavigationLink(destination: MainMenu(downloadedOnly: downloadsOnly), tag: "downloads", selection: $selection){
                                    HStack {
                                        Image(systemName: "arrow.down.circle")
                                            .frame(width: 50, height: 10, alignment: .leading)
                                            .foregroundColor(Color("Purple"))
                                        Text("Downloaded")
                                    }
                                    .padding(8)
                                    .font(.system(size: 22, weight: .regular, design: .default))
                                }
                                Button(action: {
                                    if !nw.syncing{
                                        nw.sync()
                                    }
                                }){
                                        HStack {
                                            Image(systemName: "arrow.clockwise.icloud")
                                                .frame(width: 50, height: 10, alignment: .leading)
                                                .foregroundColor(Color("Purple"))
                                            Text(nw.syncing ? "Syncing" + (nw.total == 0 ? "" : " (\(nw.complete)/\(nw.total))") : "Sync")
                                        }
                                }
                                .padding(8)
                                .font(.system(size: 22, weight: .regular, design: .default))
                                LazyVGrid(columns:Array(repeating: GridItem(.flexible(), spacing: 20), count: 2), spacing: 15){
                                    if(albums.count > 0){
                                        Section(header: Text("Recently Added").font(.system(size: 22, weight: .semibold)).frame(width: UIScreen.main.bounds.width - 30, alignment: .leading).padding(.top, 20).transition(.opacity)){
                                            ForEach(albums.prefix(20), id: \.self){ album in
                                                if(album.id != nil){
                                                    AlbumCover(album)
                                                }
                                            }
                                        }
                                    }
                                }
                                Spacer().frame(height: 80)
                        }
                        .animation(nil)
                        .listStyle(PlainListStyle())
                            .navigationBarTitle("Library", displayMode: .inline)
                            .toolbar{
                                Button(action: {
                                     accountSheet = true
                                }) {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .foregroundColor(Color("Purple"))
                                }
                                .sheet(isPresented: $accountSheet, content: {
                                Account().onDisappear(){
                                    accountSheet = false
                                } })
                                
                            }
                            
                            Spacer().frame(height: 30).padding(0).background(GeometryGetter(rect: $rect1))
                    }
                    }
                OfflineContent(show: downloadsOnly).padding(0).position(x: UIScreen.main.bounds.width / 2, y:rect1.origin.y - rect1.size.height)
                    if showPlayer{
                        PlayerViewOld(initSafeArea: $safeArea)
                    }
                }
                .background(SafeAreaGeometryGetter(rect: $safeArea, done: $showPlayer))
                .transition(.opacity)
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
