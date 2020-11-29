//
//  SongViewCompact2.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 25/10/20.
//

import SwiftUI

struct SongViewCompact2: View {
    @Environment(\.colorScheme) var colorScheme
    let song: Song
    let border: Bool
    init(song: Song, border: Bool = true) {
        self.song = song
        self.border = border
    }
    var body: some View {
        HStack(spacing: 15){
            AsyncImage(
                url: URL(string:NetworkingManager.shared.getAlbumArt(id: self.song.album!.id!))!,
                placeholder: { Rectangle().fill(Color.black) },
               image: {
                Image(uiImage: $0).resizable()
                    .renderingMode(.original)
               }
            )
            .frame(width:46, height: 46)
            .cornerRadius(4)
            .padding(.vertical, 4)
            .aspectRatio(contentMode: .fit)
            HStack(spacing: 0){
                VStack(alignment: .leading, spacing: 3){
                    Text(song.name!)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Text("\(song.album!.albumArtist!)")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                Spacer()
            }
            .border(width: border ? 0.25 : 0, edge: .bottom, color: colorScheme == .dark ? Color.gray.opacity(0.6) : .gray)
        }.background(Color.black.opacity(0.0001))
    }
}
