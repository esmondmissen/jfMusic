//
//  Player.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 15/10/20.
//

import SwiftUI
import MediaPlayer
import UIKit

struct PlayerViewOld: View {
    static let transitionTime: Double = 0.22
    private let animationType = Animation.easeOut(duration: transitionTime)
    @Binding var safeArea: CGRect
    @State private var height: CGFloat = 1
    @State private var startPos : CGPoint = .zero
    @State private var isSwipping = false
    @State private var isExpanded = false {
        didSet{
            height = isExpanded ? 0 : playerCollapsedHeight()
            if !isExpanded{
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + PlayerViewOld.transitionTime) {
                    prepareExpand = false
                }
            }
        }
    }
    @State private var prepareExpand = false
    @State private var playerState: PlayerState = .albumArt
    @State private var backgroundColor: Color = .black
    @Namespace private var animation
    @ObservedObject var player: Player = Player.shared
    
    init(initSafeArea: Binding<CGRect>) {
        self._safeArea = initSafeArea
    }
    
    func playerCollapsedHeight() -> CGFloat{
        return UIScreen.main.bounds.height - 76 - (UIScreen.main.bounds.height - safeArea.maxY)
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack{
                    ZStack(alignment: .top){
                        // Background of PLayer
                        VStack{
                            Color.clear.frame(height: isExpanded ? safeArea.minY : 0)
                            Spacer()
                        }.background(
                            ZStack{
                                Blur(style: .systemMaterial)
                                backgroundColor
                                    .colorMultiply(Color(red: 0.38, green: 0.38, blue: 0.38, opacity: 1))
                                    .saturation(2)
                                .opacity(isExpanded ? 1 : 0)
//                                    .colorMultiply(backgroundColor)
//                                    .saturation(3)
                                .animation(.default, value: backgroundColor)
                                .onReceive(player.$color, perform: { val in
                                    backgroundColor = val
                                })
                            }
                        ).cornerRadius( !isSwipping && isExpanded ? 0 : isExpanded ? 38 : 5)
                        
                        // Controls of expanded player
                        if prepareExpand{
                            ZStack(alignment: .bottom){
                                    VStack(spacing: 0){
                                        PlayerBottom(playerState: $playerState, spacing: 28)
                                            .compositingGroup()
                                            .blendMode(.luminosity)
                                        Spacer().frame(width: UIScreen.main.bounds.width, height: safeArea.minY == 20 ? 10 : safeArea.minY + 20)
                                    }
                                VStack(spacing: 0){
                                    Spacer().frame(width: UIScreen.main.bounds.width, height: safeArea.minY + 20)
                                    ZStack{
                                        
                                            VStack(spacing: 0){
                                                if playerState == .albumArt {
                                                    Spacer().frame(height: UIScreen.main.bounds.height - (UIScreen.main.bounds.height / 3) - 40 - safeArea.minY - (safeArea.minY + 40))
                                                    ArtistInfoLarge(animation: animation)
                                                        .padding(.bottom, 10)
                                                        .transition(AnyTransition.opacity.combined(with: .move(edge: .top)))
                                                        .animation(.default, value: playerState)
                                                }
                                            }
                                        ZStack(alignment: .top){
                                            if playerState == .upNext {
                                                HStack{
//                                                    Image(uiImage:player.currentSongImage).resizable().aspectRatio(contentMode: .fit)
//                                                        .clipShape(RoundedRectangle(cornerRadius: 3))
//                                                        .matchedGeometryEffect(id: "art", in: animation)
//                                                        .shadow(color: Color.black.opacity(0.5), radius: 3, x: 0, y: 0)
                                                    Spacer()
                                                }.frame(height: 60).padding(.horizontal, 30)
                                                UpNext(appear: Binding<Bool>( get: { playerState != .albumArt }, set: { _ = $0 }), animation: animation)
                                                    .transition(AnyTransition.opacity.combined(with: .move(edge: .bottom)))
                                            }
                                        }
                                    }
                                    Spacer()
                                    Spacer().frame(height: (UIScreen.main.bounds.height / 3))
                                }
                            }.frame(height: UIScreen.main.bounds.height)
                            .onAppear{
                                print("Expand = true")
                                isExpanded = true
                            }
                            
                        }
                        MiniPlayer(animation: animation, isExpanded: $isExpanded, topMargin: $safeArea, playerState: $playerState)
                    }
                    .animation(animationType, value: isExpanded)
                    .animation(animationType, value: prepareExpand)
                    .frame(height: UIScreen.main.bounds.height)
                    .offset(y: height)
                    .gesture(
                        DragGesture(minimumDistance: 30, coordinateSpace: .global)
                            .onChanged { gesture in
                                if !self.isSwipping {
                                    self.startPos = gesture.location
                                    self.isSwipping.toggle()
                                }
                                if isExpanded && gesture.translation.height >= 0{
                                    height = gesture.translation.height
                                }
                            }

                            .onEnded { gesture in
                                if self.startPos.y <  gesture.location.y {
                                    isExpanded = false
                                }
                                else {
                                    if !prepareExpand{
                                        prepareExpand = true
                                    }else{
                                        isExpanded = true
                                    }
                                }
                                self.isSwipping.toggle()
                            }
                    )
                    .onTapGesture {
                        prepareExpand = true
                    }
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear(){
            height = playerCollapsedHeight()
        }
    }
}


struct Blur: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemMaterial
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}
