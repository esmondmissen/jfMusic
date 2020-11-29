//
//  Partical.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 17/10/20.
//

import SwiftUI
import UIKit
import AnimatedGradientView
import UIImageColors

extension Collection {
    func choose(_ n: Int) -> ArraySlice<Element> { shuffled().prefix(n) }
}
func hexStringFromColor(color: UIColor) -> String {
    let components = color.cgColor.components
    if components?.count ?? 0 >= 3{
        let r: CGFloat = components?[0] ?? 0.0
        let g: CGFloat = components?[1] ?? 0.0
        let b: CGFloat = components?[2] ?? 0.0

        let hexString = String.init(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
        return hexString
    }else{
        return components?[0] == 1 ? "#ffffff" : "#000000"
    }
 }
struct EmitterView: UIViewRepresentable {
    
    @Binding var colors: UIImageColors
    @Binding var isPlaying: Bool
    @Binding var visible: Bool
    
    func makeUIView(context: Context) -> AnimatedGradientView {
        print("Gradient Init")
        let animatedGradient = AnimatedGradientView(frame: CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        animatedGradient.direction = .up
        animatedGradient.animationDuration = 10
        animatedGradient.autoAnimate = false
        animatedGradient.layer.masksToBounds = true
        
        return animatedGradient
    }

    func updateUIView(_ uiView: AnimatedGradientView, context: Context) {
        
        if isPlaying{
            let matches = (Set(uiView.colors).intersection(Set(arrayLiteral: [self.colors.primary!, self.colors.secondary!])).count)
            if matches == 0{
//                uiView.stopAnimating()
                uiView.colors = [[self.colors.primary!, self.colors.secondary!], [self.colors.primary!, self.colors.background!, self.colors.detail!]]
//                uiView.animationValues = [(colors: [self.colors.primary!, self.colors.background!].map{ hexStringFromColor(color: $0) }, .up, .axial),
//                                          (colors: [self.colors.background!, self.colors.secondary!, self.colors.primary!].map{ hexStringFromColor(color: $0) }, .upRight, .axial)]
//                uiView.startAnimating()
                uiView.direction = .downLeft
            }
//            if visible && uiView.direction != .downLeft {
//                print("Starting Animation")
//                uiView.direction = .downLeft
//                uiView.startAnimating()
//            }else if !visible && uiView.direction == .downLeft{
//                print("Stopping Animation")
//                uiView.stopAnimating()
//                uiView.direction = .up
//            }
        }else{
//                print("Stopping Animation")
//                uiView.stopAnimating()
//                uiView.direction = .up
        }
    }

    typealias UIViewType = AnimatedGradientView
    
}

//struct TestEmitterLayer: View {
//    var body: some View {
//        EmitterView()        // << usage !!
//    }
//}
