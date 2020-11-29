//
//  UpNextList.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 25/10/20.
//

import SwiftUI
import UniformTypeIdentifiers
import CoreData
import CoreHaptics

struct DemoDragRelocateView: View {
    @StateObject private var model = Player.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var dragging: AVPlayerItemId?
    @State private var rect1: CGRect = CGRect()
    @State private var mask: Rectangle = Rectangle()
    @State private var activeId: String = ""
    var body: some View {
        ScrollView(showsIndicators: false){
            LazyVStack(spacing: 0) {
                    ForEach(model.songs.filter{ model.songs.firstIndex(of: $0)! > model.songIndex }, id: \.self) { song in
                        miniUpNextSong(song: song, activeId: $activeId)
                            .onDrag {
                                self.dragging = song
                                return NSItemProvider(object: String(song.id) as NSString)
                            }
                    .onDrop(of: [UTType.text], delegate: DragRelocateDelegate(item: song, listData: $model.songs, current: $dragging))
                    .mask(dragging?.id == song.id ? Color.white.opacity(0.4) : Color.white)

                    .onTapGesture(count: 1, perform: {
                        Player.shared.next(song: song)
                    })
                }
                    Spacer().frame(height: 100)
            }.animation(.default, value: model.songs)
        }
        .onDrop(of: [UTType.text], delegate: DropOutsideDelegate(current: $dragging))
        
    }
}

struct miniUpNextSong: View{
    let song: AVPlayerItemId
    @Binding var activeId: String
    @State private var offset: CGFloat = 0
    @State private var offsetY: CGFloat = 0
    @State private var active: Bool = false
    @State private var scaleSize: CGFloat = 1.2
    @State private var haptic: Bool = false
    
    private let rightPadding: CGFloat = -8
    var body: some View{
        ZStack{
        HStack(spacing: 15){
            Spacer().frame(width: 15)
            AsyncImage(
                url: URL(string:NetworkingManager.shared.getAlbumArt(id: (song.song.album?.id!)!))!,
                placeholder: { Rectangle().fill(Color.black) },
               image: {
                Image(uiImage: $0).resizable()
                    .renderingMode(.original)
               }
            )
            .frame(width:40, height: 40)
            .cornerRadius(4)
            .padding(.vertical, 4)
            .aspectRatio(contentMode: .fit)
            HStack(spacing: 0){
                VStack(alignment: .leading, spacing: 3){
                    Text(song.song.name!)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text("\(song.song.artistShort)")
                        .font(.system(size: 13))
                        .foregroundColor(Color.white.opacity(0.6))
                        .lineLimit(1)
                }
                Spacer()
            }
        }
        .background(Color.black.opacity(0.0001))
        .offset(x: activeId == song.id ? offset : 0, y: offsetY)
        .animation(.default, value: offset)
//        .animation(.default, value: offsetY)
        .animation(.default, value: activeId)
        .gesture(
            DragGesture()
                .onChanged{ gesture in
                    if gesture.translation.width < 0 {
                        offset = gesture.translation.width
//                        offsetY = gesture.translation.height
                        if activeId != song.id && gesture.translation.width < -10{
                            activeId = song.id
                        }
                        if offset + 162 < rightPadding && !haptic{
                            haptic = true
                            let impactMed = UIImpactFeedbackGenerator(style: .medium)
                                impactMed.impactOccurred()
                        }else if offset + 162 >= rightPadding && haptic{
                            haptic = false
                            let impactMed = UIImpactFeedbackGenerator(style: .medium)
                                impactMed.impactOccurred()
                        }
                    }else{
                        offset = 0
                    }
                }
                .onEnded{ gesture in
                    if offset + 162 < rightPadding{
                        Player.shared.removeSong(song: song)
                    }
                    else if offset < -60{
                        offset = -80
                    }else{
                        offset = 0
                    }
                }
        )
            HStack{
                Spacer()
                Button(action: {
                    Player.shared.removeSong(song: song)
                }, label: {
                    // 38.4 16.2
                    Circle().fill(offset + 162 < rightPadding ? .red :Color.white.opacity(0.2))
                        .overlay(
                            Image(systemName: "multiply")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(.white)
                                .frame(width: 12)
                        ).frame(width: 32)
                }).frame(width: 32, height: 32)
            }.offset(x: activeId == song.id ? getOffset() : 50)
            .animation(.easeIn(duration:0.2), value: offset)
            .animation(.easeIn(duration:0.2), value: activeId)
            .animation(.easeIn(duration:0.2), value: scaleSize)
        }
    }
    private func getOffset() -> CGFloat{
        return (max(offset + 50, -30))
    }
}

struct DropOutsideDelegate: DropDelegate {
    @Binding var current: AVPlayerItemId?
        
    func performDrop(info: DropInfo) -> Bool {
        current = nil
        return true
    }
}

struct DragRelocateDelegate: DropDelegate {
    let item: AVPlayerItemId
    @Binding var listData: [AVPlayerItemId]
    @Binding var current: AVPlayerItemId?

    func dropEntered(info: DropInfo) {
        if item != current {
            let from = listData.firstIndex(of: current!)!
            let to = listData.firstIndex(of: item)!
            if listData[to].id != current!.id {
                listData.move(fromOffsets: IndexSet(integer: from),
                    toOffset: to > from ? to + 1 : to)
            }
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        self.current = nil
        return true
    }
}

//MARK: - GridItem

struct GridItemView: View {
    var d: AVPlayerItemId

    var body: some View {
        SongViewCompact2(song: d.song)
    }
}
