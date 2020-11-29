//
//  SongViews.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 8/10/20.
//

import SwiftUI

struct SongViewCompact: View {
    @ObservedObject var nw: NetworkingManager = NetworkingManager.shared
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var song: Song
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
                    Text("\(song.album!.wrappedName) - \(song.album!.wrappedProductionYear)")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                Spacer()
                if !song.downloaded && nw.online{
                    HStack(spacing: 0){
                    if song.downloading == true{
                        LoaderCircle(progress: $song.progress)
                            .frame(width: 18, height: 18, alignment: .trailing)
                            .animation(.default, value: song.downloading)
                    }else{
                        Image(systemName: "plus")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(Color("Purple"))
                            .frame(height: 18, alignment: .trailing)
                            .animation(.default, value: song.downloading)
                            .onTapGesture {
                                song.downloading = true
                                song.download()
                            }
                    }
                        Spacer().frame(width: 10)
                    }
                }
            }
            .border(width: 0.25, edge: .bottom, color: colorScheme == .dark ? Color.gray.opacity(0.6) : .gray)
        }.background(Color.black.opacity(0.0001))
        
    }
}


struct SongViewCompact_Previews: PreviewProvider {
    static var previews: some View {
        SongViewCompact(song: Song())
    }
}
