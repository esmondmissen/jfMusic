//
//  ProgressBar.swift
//  Music
//
//  Created by Esmond Missen on 24/7/20.
//

import SwiftUI

struct ProgressBar: View {
    private let totalHeight = CGFloat(30)
    @State private var prog: CGFloat = 0
    @State private var progNoAnim: CGFloat = 0
    @State private var resetPlayer: Bool = false
    @ObservedObject var player = Player.shared
    private let seekSize: CGFloat = 25
    @State private var seekStart: CGFloat = 0
    @State private var offset: CGFloat = -(25 / 2)
    @State private var elapsedOffset: CGFloat = -7.5
    @State private var durationOffset: CGFloat = -7.5
    @State private var canAnimate: Bool = false
    @State private var appeared: Bool = false
 
    var body: some View {
            GeometryReader { geometry in
                VStack(spacing: 1){
                    
                    ZStack(alignment: .leading) {
                        Rectangle().frame(width: geometry.size.width, height: 3)
                            .opacity(0.0)
                        Rectangle().fill(Color.clear).background(
                            Rectangle().frame(width: geometry.size.width - seekSize, height: 3)
                                .foregroundColor(Globals.colorLow)
                                .cornerRadius(1.5)
                        ).padding(.horizontal, seekSize / 2)
                        Rectangle().fill(Color.clear).frame(width: max(min(prog, progNoAnim), 0)).background(
                            Rectangle().frame(height: 3)
                                .foregroundColor(Globals.colorMed)
                                .cornerRadius(1.5)
                        ).padding(.horizontal, seekSize / 2)
                        .animation(Animation.linear(duration: Globals.playTimeInterval), value: canAnimate ? prog : nil)
                        Circle().fill(Color.black.opacity(0.0001))
                            .overlay(
                            Circle()
                                .fill(Globals.colorMed)
                                .frame(width: player.seeking ? seekSize : 7, height: player.seeking ? seekSize : 7)
                                .animation(.default, value: player.seeking)
                            )
                        .frame(width: seekSize, height: seekSize)
                        .offset(x:min(min(prog, progNoAnim), geometry.size.width), y: 0)
                            .animation(Animation.linear(duration: Globals.playTimeInterval), value: canAnimate ? prog : nil)
                            .onAppear{
                                prog = (CGFloat(player.playProgress > 1 ? 1 : player.playProgress)*(geometry.size.width - seekSize))
                                progNoAnim = prog
                                appeared = true
                            }
                        .onReceive(player.$trigger){ _ in
                                let temp = (CGFloat(player.playProgressAhead > 1 ? 1 : player.playProgressAhead)*(geometry.size.width - seekSize))
                                if canAnimate {
                                    if (temp > prog) || resetPlayer {
                                        progNoAnim = temp
                                        prog = temp
                                        resetPlayer = false
                                    }else{
                                        resetPlayer = true
                                        progNoAnim = temp
                                    }
                                }else{
                                    if appeared{
                                        canAnimate = true
                                    }
                                }
                        }
                        .gesture(DragGesture()
                                    .onChanged { gesture in
                                        if !player.seeking{
                                            player.seeking = true
                                            seekStart = prog
                                        }
                                        let temp = seekStart + gesture.translation.width
                                        if temp >= offset && temp <= geometry.size.width - seekSize{
                                            let progress = Double((seekStart + gesture.translation.width)/(geometry.size.width - seekSize))
                                            player.setTimeElapsed(progress: Double((progress < 0 ? 0 : progress > 1 ? 1 : progress)))
                                        }

                                    }
                                    .onEnded { gesture in
                                        let realProgress = (prog/(geometry.size.width - seekSize))
                                        player.seek(progress: Double(realProgress))
                                    }
                        )
                    }
                    HStack{
                        Text(player.timeElasped)
                            .frame(width: 50, height: nil, alignment: .leading)
                            .offset(y: elapsedOffset)
                            .animation(.linear(duration: 0.25), value: elapsedOffset)
                        Spacer()
                        Text("\(player.duration)")
                            .frame(width: 50, height: nil, alignment: .trailing)
                            .offset(y: durationOffset)
                            .animation(.linear(duration: 0.25), value: durationOffset)
                    }
                    .onReceive(player.$playProgressAhead, perform: { _ in
                            if prog < 50 && player.seeking{
                                    elapsedOffset = 0
                            }else{
                                    elapsedOffset = -7.5
                            }
                            if prog > geometry.size.width - seekSize - 50 && player.seeking {
                                    durationOffset = 0
                            }else{
                                    durationOffset = -7.5
                            }
                    })
                    .foregroundColor(Globals.colorMed).opacity(0.6)
                    .padding(.horizontal, seekSize / 2)
                    .font(.system(size: 13))
                    
                }
            }.frame(height:totalHeight)
    }
}

struct ProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        ProgressBar()
    }
}
