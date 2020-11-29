//
//  LargeControls.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 20/10/20.
//

import SwiftUI

struct LargeControls: View {
    
    @ObservedObject var player: Player = Player.shared
    
    var body: some View {
        HStack{
            Spacer()
            Button(action:{player.previous()}){
                Image(systemName:"backward.fill").resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 25)
            }.buttonStyle(ButtonScaleEffect())
            Spacer()
            PlayerButton(icon: Binding<String>(get: { player.isPlaying ? "pause.fill" : "play.fill" }, set: { _ = $0 }), active: Binding<Bool>(get: { false }, set: { _ = $0 }), height: 40, action: {
                player.isPlaying.toggle()
            }, padding: 0).frame(width: 40)
            Spacer()
            Button(action:{player.next()}){
                Image(systemName:"forward.fill").resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 25)
            }.buttonStyle(ButtonScaleEffect())
            Spacer()
        }.foregroundColor(.white)
    }
}

struct LargeControls_Previews: PreviewProvider {
    static var previews: some View {
        LargeControls()
    }
}
