//
//  LoaderCircle.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 23/10/20.
//

import SwiftUI

struct LoaderCircle: View {
    @Binding var progress: CGFloat
        @State private var appear = false
        var body: some View {
            ZStack {
                Circle()
                    .stroke(lineWidth: 3)
                    .opacity(0.3)
                    .foregroundColor(Color("Purple"))
                Circle()
                    .rotation(Angle(degrees: -90))
                    .trim(from: 0.0, to: progress)
                        .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        .foregroundColor(Color("Purple"))
            }
            .opacity(appear ? 1 : 0)
            .animation(.default, value: appear)
            .onAppear(){
                appear = true
            }
        }
}

struct LoaderCircle_Previews: PreviewProvider {
    static var previews: some View {
        LoaderCircle(progress: .constant(0.45))
            .frame(width: 18, height: 18)
    }
}
