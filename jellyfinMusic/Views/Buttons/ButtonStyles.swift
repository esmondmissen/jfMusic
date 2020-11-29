//
//  ButtonStyles.swift
//  Music
//
//  Created by Esmond Missen on 21/7/20.
//

import SwiftUI

struct LargeButtonStyle: ButtonStyle {
    var bgColor: Color

    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding(15)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(bgColor)
        )
            .scaleEffect(configuration.isPressed ? 0.95: 1)
            .foregroundColor(.primary)
    }
}
struct PlainListButtonStyle: ButtonStyle {
    var bgColor: Color = Color.gray

    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding(0)
            .background(
                Rectangle()
                    .fill(bgColor.opacity(configuration.isPressed ? 0.3: 0))
        )
        .foregroundColor(.primary)
    }
}
struct BlueButtonStyle: ButtonStyle {
    var size:CGFloat = 40
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .frame(width: size, height: size)
            .foregroundColor(configuration.isPressed ? Color.gray : .primary)
            .scaleEffect(configuration.isPressed ? 0.7: 1)
            .background(Circle().fill(Color.black.opacity(configuration.isPressed ? 0.2: 0.001)))
            .animation(.spring(), value: configuration.isPressed)
    }
}

struct SmallTransparent: ButtonStyle {
    @Binding var active:Bool
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(configuration.isPressed ? Color.gray : .primary)
            .scaleEffect(configuration.isPressed ? 0.7: 1)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(active ? 0.2: 0.001)))
            .animation(.spring(), value: configuration.isPressed)
            .animation(.spring(), value: active)
    }
}

struct ButtonScaleEffect: ButtonStyle {
    private var scale: CGFloat
    init(scale: CGFloat = 1.2) {
        self.scale = scale
    }
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .background(Color.black.opacity(0.0001))
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(), value: configuration.isPressed)
    }
}

struct PlayerButton: View {
    
    @Binding var active:Bool
    @State private var size: CGFloat
    let action: (() -> Void)
    @Binding var icon: String
    let padding: CGFloat
    init(icon: String, active: Binding<Bool>, height: CGFloat = 15, action: @escaping () -> Void, padding: CGFloat = 10){
        self._active = active
        self.action = action
        self._icon = Binding<String>(get: { icon }, set: { _ = $0 })
        self._size = State(initialValue: height)
        self.padding = padding
    }
    
    init(icon: Binding<String>, active: Binding<Bool>, height: CGFloat = 15, action: @escaping () -> Void, padding: CGFloat = 10){
        self._active = active
        self.action = action
        self._icon = icon
        self._size = State(initialValue: height)
        self.padding = padding
    }
    
    var body: some View{
        Button(action: action ){
            Image(systemName: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height:size)
                .padding(padding)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(active ? 0.2: 0)))
                .animation(.default, value: icon)
        }
        .buttonStyle(ButtonScaleEffect())
    }
}
