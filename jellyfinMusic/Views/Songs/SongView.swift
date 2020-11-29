//
//  SongView.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 25/10/20.
//

import SwiftUI

struct SongView<Content: View>: View{
    @Environment(\.colorScheme) var colorScheme
    let content: Content
    let song: Song
    init(song: Song, @ViewBuilder content: () -> Content){
        self.song = song
        self.content = content()
    }
    var body: some View{
        VStack(spacing: 0) {
            HStack(){
                Text("\(song.trackNumber )").opacity(0.6)
                    .padding(.trailing, 5)
                VStack(alignment: .leading, spacing: 3){
                    Text(song.wrappedNameFeat)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                Spacer()
                self.content
            }
            .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
            Divider()
             .frame(height: 1)
                .padding(0)
        }.padding(.horizontal, 10).padding(.vertical, 0).background(Color.black.opacity(0.0001)).cornerRadius(8)
    }
}
