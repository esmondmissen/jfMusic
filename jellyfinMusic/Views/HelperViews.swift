//
//  HelperViews.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 8/10/20.
//

import SwiftUI

struct CustomSectionView<Content: View>: View {
    let content: Content
    let title: String
    
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading){
            Text(title).font(.system(size: 22)).fontWeight(.semibold)
                .padding(.all, 0)
                .padding(.top, 15)
                .padding(.leading, 15)
            self.content
        }
    }
}

struct HorizontalList<Content: View>: View{
    
    let content: Content
    let spacing: CGFloat
    init(spacing: CGFloat = 15, @ViewBuilder content: () -> Content){
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View{
        ScrollView(.horizontal, showsIndicators: false){
            HStack(alignment: .top, spacing: spacing){
                Spacer().frame(width:0)
                self.content
                Spacer().frame(width:0)
            }
        }.gesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .global)
                .onChanged { gesture in
                    print(gesture)
                }

                .onEnded { _ in
                    print("Ended")
                }
        )
    }
}

struct DeleteVStack<Content: View>: View {
    
    let content: Content
    let color: Color
    let icon: Image
    @State private var open = false
    @State private var offset = CGSize.zero
    let action: (() -> Void)
    init(color: Color, icon: Image, action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.color = color
        self.icon = icon
        self.content = content()
        self.action = action
    }
    
    var body: some View{
        ZStack{
            HStack{
                Spacer().frame(width:UIScreen.main.bounds.width - 15 + self.offset.width)
                Button(action: action, label: {
                    ZStack{
                        self.color.overlay(HStack{
                            self.icon
                            Text("Delete")
                        }.transition(.opacity)
                        .foregroundColor(.white)
                        .frame(width: 80))
                    }
//                    .cornerRadius(8)
                    .frame(width: self.offset.width * -1)
                    .clipped()
                })
                
            }
//            .padding(.horizontal, 15)
            self.content
                .offset(x: offset.width)
                .gesture(
                    DragGesture(minimumDistance: 20, coordinateSpace: .global)
                        .onChanged { gesture in
                            if !self.open && gesture.translation.width < 0 {
                                self.offset = gesture.translation
                            }else if self.open && gesture.translation.width > 0 {
                                self.offset.width = -150 + gesture.translation.width
                            }
                        }

                        .onEnded { _ in
                            print(self.offset.width)
                            if ((!self.open && abs(self.offset.width) > 40) || (self.open && abs(self.offset.width) < 0)){
                                withAnimation{
                                    self.open = true
                                    self.offset.width = -150
                                }
                            }
                            else {
                                withAnimation{
                                    self.open = false
                                    self.offset = .zero
                                }
                            }
                        }
                )
        }
    }
}

struct EdgeBorder: Shape {

    var width: CGFloat
    var edge: Edge

    func path(in rect: CGRect) -> Path {
        var x: CGFloat {
            switch edge {
            case .top, .bottom, .leading: return rect.minX
            case .trailing: return rect.maxX - width
            }
        }

        var y: CGFloat {
            switch edge {
            case .top, .leading, .trailing: return rect.minY
            case .bottom: return rect.maxY - width
            }
        }

        var w: CGFloat {
            switch edge {
            case .top, .bottom: return rect.width
            case .leading, .trailing: return self.width
            }
        }

        var h: CGFloat {
            switch edge {
            case .top, .bottom: return self.width
            case .leading, .trailing: return rect.height
            }
        }

        return Path( CGRect(x: x, y: y, width: w, height: h) )
    }
}

extension View {
    func border(width: CGFloat, edge: Edge, color: Color) -> some View {
        ZStack {
            self
            EdgeBorder(width: width, edge: edge).foregroundColor(color)
        }
    }
}
