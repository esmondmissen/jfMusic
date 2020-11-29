//
//  AirplayButton.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 26/10/20.
//

import Foundation
import UIKit
import SwiftUI
import AVKit

struct AirPlayView: UIViewRepresentable {

    func makeUIView(context: Context) -> UIView {

        let routePickerView = AVRoutePickerView()
        routePickerView.backgroundColor = UIColor.clear
        routePickerView.activeTintColor = UIColor.red
        routePickerView.tintColor = UIColor.white

        return routePickerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
    }
}
