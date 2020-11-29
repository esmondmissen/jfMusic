//
//  SlideText.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 21/10/20.
//

import SwiftUI

struct DemoSlideText<Content: View>: View {
    @ObservedObject var player: Player = Player.shared
    private let content: Content
    @State private var rect1: CGRect = CGRect()
    private let animate: Bool
    @State private var alignment: Alignment = .leading
    private let width: CGFloat
    
    init(width: CGFloat, animate: Bool = false, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.width = width
        self.animate = animate
    }
    
    var body: some View {
        HStack {
            VStack{
                content
                    .padding(.horizontal, 15)
                    .background(GeometryGetter(rect: $rect1))
            }
            .fixedSize()
            .frame(width: rect1.width > width ? rect1.width : width, alignment: .leading)
            
            content
                .padding(.horizontal, 15)
                .fixedSize()
                .frame(width: width, alignment: .leading)
                
        }
        .fixedSize()
        .frame(width: width, alignment: alignment)
        .mask(
            HStack(spacing:0){
                LinearGradient(gradient: Gradient(colors: [Color.black, Color.white]), startPoint: .leading, endPoint: .trailing).frame(width: 15)
                Color.white
                LinearGradient(gradient: Gradient(colors: [Color.white, Color.black]), startPoint: .leading, endPoint: .trailing)
                    .frame(width: 15)
            }.compositingGroup().luminanceToAlpha() )
        .clipped()
        .onReceive(player.animationTimer, perform: { _ in
            if animate || rect1.width > width{
                withAnimation(.linear(duration: 5)){
                    alignment = alignment == .leading ? .trailing : .leading
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    alignment = .leading
                }
            }
        })
    }
}

struct GeometryGetter: View {
    @Binding var rect: CGRect
    init(rect: Binding<CGRect>){
        self._rect = rect
    }
    
    var body: some View {
        GeometryReader { (g) -> Path in
            DispatchQueue.main.async { // avoids warning: 'Modifying state during view update.' Doesn't look very reliable, but works.
                    self.rect = g.frame(in: .global)
            }
            return Path() // could be some other dummy view
        }
    }
}

struct SafeAreaGeometryGetter: View {
    @Binding var rect: CGRect
    @Binding var done: Bool
    init(rect: Binding<CGRect>, done: Binding<Bool>){
        self._rect = rect
        self._done = done
    }
    
    var body: some View {
        GeometryReader { (g) -> Path in
            if !done{
                DispatchQueue.main.async { // avoids warning: 'Modifying state during view update.' Doesn't look very reliable, but works.
                        self.rect = g.frame(in: .global)
                    if self.rect.minY > 0{
                        done = true
                    }
                }
            }
            return Path() // could be some other dummy view
        }
    }
}
