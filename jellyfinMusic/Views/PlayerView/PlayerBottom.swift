//
//  PlayerBottom.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 20/10/20.
//

import SwiftUI
import UniformTypeIdentifiers
import CoreData


struct PlayerBottom: View {
    
    @ObservedObject var player: Player = Player.shared
//    let geo: GeometryProxy
    @Binding var playerState: PlayerState
    @State private var rect1: CGRect = CGRect()
    
    let spacing: CGFloat
    var body: some View {
        VStack(spacing: spacing){
            ProgressBar().padding(.horizontal, 30 - 12.5)
//            Spacer()
            LargeControls()
//            Spacer()
            

            VolumeSlider().padding(.horizontal, 30)
                
//            Spacer()
            ZStack(alignment: .bottom){
                HStack{
//                    Spacer()
//                    Button(action: {}){
//                        Image(systemName: "quote.bubble")
//                            .resizable()
//                            .aspectRatio(contentMode: .fit)
//                            .frame(height:20)
//                            .padding(10)
//                    }
                    Spacer()
                    AirPlayView().frame(width: 20, height: 20).padding(10)
                    Spacer()
                    
                    PlayerButton(icon: Binding<String>(get: { player.currentSong?.song.isFavourite ?? false ? "heart.fill" : "heart" }, set: { _ = $0 }), active: Binding<Bool>(get: { false }, set: { _ = $0 }), height: 20, action: {
                        NetworkingManager.shared.favouriteSong(song: (player.currentSong?.song)!, isFavourite: !(player.currentSong?.song.isFavourite)!, completion:  {_ in })
                    }).disabled(player.currentSong == nil)
                    
                    Spacer()
                    PlayerButton(icon: "list.bullet", active: Binding<Bool>(get: { playerState == PlayerState.upNext }, set: { _ = $0 }), action: {
                        withAnimation(.spring()){
                            playerState = playerState == .upNext ? .albumArt : .upNext
                        }
                    })
                    Spacer()
                }.foregroundColor(Color.white.opacity(0.8))
            }
        }
        .compositingGroup()
//        .frame(height: geo.size.height)
//        .background(VStack{
//                        Image("test").resizable().aspectRatio(contentMode: .fill)
//            }
//            .offset(y: -rect1.minY)
//            .background(GeometryGetter(rect: $rect1))
//            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
//        )
//        .clipped()
        
    }
}

