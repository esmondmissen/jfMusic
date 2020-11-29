//
//  VolumeSlider.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 17/10/20.
//

import SwiftUI
import MediaPlayer

struct VolumeSlider: View {
    private let totalHeight = CGFloat(30)
    @State private var prog: CGFloat = 150
    @State private var soundLevel: Float = 0.5
    @State private var seekStart: CGFloat = 0
    @State private var seeking: Bool = false
    @ObservedObject private var volObserver = VolumeObserver()
    
    var body: some View {
        HStack(spacing: 20){
            Image(systemName: "speaker.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(Globals.colorMed)
                .frame(height: 12)
            GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle().frame(width: geometry.size.width , height: 3)
                            .foregroundColor(Globals.colorLow)
                            .opacity(Globals.componentOpacity / 2)
                            .cornerRadius(1)
                        Rectangle().frame(width: prog, height:3)
                            .foregroundColor(Globals.colorMed)
                            .animation(Animation.linear(duration: 0.1), value: prog)
                            .cornerRadius(1.5)
                        Circle()
                            .fill(Color.black.opacity(0.0001))
                            .overlay(Circle().fill(Globals.colorFull).frame(width: 20, height: 20))
                            .frame(width:50, height:50)
                            .offset(x: prog - 25, y: 0)
//                            .animation(Animation.linear(duration: 0.1), value: prog)
                                .onAppear{
                                    prog = (CGFloat(volObserver.volume * Float(geometry.size.width)))
                                }
                            .onReceive(volObserver.$volume){ val in
                                prog = (CGFloat(val * Float(geometry.size.width)))
                            }
                            .gesture(DragGesture(minimumDistance: 0)
                                .onChanged { gesture in
                                    if !seeking{
                                        seeking = true
                                        seekStart = prog
                                    }
                                    let temp = min(geometry.size.width , max( 0, seekStart + gesture.translation.width))
                                    MPVolumeView.setVolume(Float(temp / geometry.size.width))

                                }
                                        .onEnded{ _ in
                                            seeking = false
                                        }
                            )
                    }.padding(.vertical, 5)
            }.frame(height: 60)
            Image(systemName: "speaker.wave.3.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(Globals.colorMed)
                .frame(height: 12)
        }.frame(height:totalHeight)
    }
}

struct VolumeSlider_Previews: PreviewProvider {
    static var previews: some View {
        VolumeSlider()
    }
}
