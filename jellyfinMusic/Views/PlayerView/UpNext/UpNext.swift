//
//  UpNext.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 20/10/20.
//

import SwiftUI

struct UpNext: View {
    
    @ObservedObject var player: Player = Player.shared
    @Binding var appear: Bool
    let animation: Namespace.ID
    
    var body: some View {
        VStack(spacing: 0){
            HStack(spacing: 0){
                Spacer().frame(width: 60)
                VStack(alignment: .leading){
                    Spacer()
                    GeometryReader{ geo in
                        DemoSlideText(width: geo.size.width){
                            Text(player.currentSong?.song.name ?? "Not Playing")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    GeometryReader{ geo in
                        DemoSlideText(width: geo.size.width){
                            Text(player.currentSong?.song.artistLong ?? " ")
                                .font(.system(size: 14, weight: .regular))
                                .lineLimit(1)
                                .foregroundColor(Color.white.opacity(0.6))
                                .padding(.trailing, 30)
                        }
                    }
                    Spacer()
                }
//                .matchedGeometryEffect(id: "largeName", in: animation)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .topLeading)
                Spacer().frame(width: 30)
                Button(action: {}, label: {
                    Circle().fill(Color.white.opacity(0.2))
                        .overlay(
                            Image(systemName: "ellipsis")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(.white)
                                .frame(width: 18)
                        ).frame(width: 26)
                }).frame(width: 26, height: 26)
//                .matchedGeometryEffect(id: "ellipse", in: animation)
            }
            .frame(height: 60)
            .padding(.bottom, 10)
            .padding(.horizontal, 30)
            if appear{
                VStack(spacing: 0){
                    HStack{
                        VStack(alignment: .leading, spacing: 5){
                            Text("Up Next")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
//                            if let song = Player.shared.currentSong{
//                                if song.from.type == .album || song.from.type == .playlist || song.from.type == .topSongs{
//                                    Text("From \(song.from.name)")
//                                        .font(.system(size: 12, weight: .light, design: .default))
//                                        .foregroundColor(Color.white.opacity(0.9))
//                                        .lineLimit(1)
//                                        .truncationMode(.tail)
//                                }
//                            }
                        }
                        Spacer()
                        PlayerButton(icon: "shuffle", active: Binding<Bool>(get: { Player.shared.playmode == .random }, set: { _ = $0 }), action: {
                            Player.shared.playmode.toggle()
                        }).foregroundColor(Color.white)
                        PlayerButton(icon: Player.shared.repeatMode == .repeatOne ? "repeat.1" : "repeat", active: Binding<Bool>(get: { Player.shared.repeatMode != .none }, set: { _ = $0 }), action: {
                            Player.shared.repeatMode.toggle()
                        }).foregroundColor(Color.white)
                    }.padding(.bottom, 5)
                    .padding(.horizontal, 30)
                DemoDragRelocateView()
                    .background(Color.clear)
                    .padding(.horizontal, 0)
                    .mask(VStack(spacing: 0){
                        LinearGradient(gradient: Gradient(colors: [.black, .white]), startPoint: .top, endPoint: .bottom)
                            .frame(height: 7)
                        Color.white
                        LinearGradient(gradient: Gradient(colors: [.white, .black]), startPoint: .top, endPoint: .bottom)
                            .frame(height: 65)
                    }.compositingGroup().luminanceToAlpha())
                }.transition(AnyTransition.opacity.combined(with: .move(edge: .bottom)))
                .animation(.spring(), value: appear)
            }
                Spacer()
            
        }
    }
}
