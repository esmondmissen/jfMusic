//
//  Helpers.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 19/10/20.
//

import Foundation
import UIKit
import MediaPlayer

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

let isoDateFormatter = ISO8601DateFormatter()
func getDate(_ date: String) -> Date? {
    isoDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    isoDateFormatter.formatOptions = [
        .withFullDate,
        .withFullTime,
        .withDashSeparatorInDate,
        .withFractionalSeconds]
    return isoDateFormatter.date(from: date)
}


func getRuntime(ticks:Int) -> String{
    let reference = Date();
    let myDate = Date(timeInterval: (Double(ticks)/10000000.0),
                        since: reference);
    
    let difference = Calendar.current.dateComponents([.minute, .second], from: reference, to: myDate)

    return "\(difference.minute!):\(difference.second!)"
}

extension UIColor {
    private func makeColor(componentDelta: CGFloat) -> UIColor {
            var red: CGFloat = 0
            var blue: CGFloat = 0
            var green: CGFloat = 0
            var alpha: CGFloat = 0
            
            // Extract r,g,b,a components from the
            // current UIColor
            getRed(
                &red,
                green: &green,
                blue: &blue,
                alpha: &alpha
            )
            
            // Create a new UIColor modifying each component
            // by componentDelta, making the new UIColor either
            // lighter or darker.
            return UIColor(
                red: add(componentDelta, toComponent: red),
                green: add(componentDelta, toComponent: green),
                blue: add(componentDelta, toComponent: blue),
                alpha: alpha
            )
        }
    private func add(_ value: CGFloat, toComponent: CGFloat) -> CGFloat {
            return max(0, min(1, toComponent + value))
        }
        func lighter(componentDelta: CGFloat = 0.1) -> UIColor {
            return makeColor(componentDelta: componentDelta)
        }
        
        func darker(componentDelta: CGFloat = 0.1) -> UIColor {
            return makeColor(componentDelta: -1*componentDelta)
        }
    func getColorDifference() -> CGFloat {
        // get the current color's red, green, blue and alpha values
        var red:CGFloat = 0
        var green:CGFloat = 0
        var blue:CGFloat = 0
        var alpha:CGFloat = 0
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    
    // get the fromColor's red, green, blue and alpha values
//        var fromRed:CGFloat = 0
//        var fromGreen:CGFloat = 0
//        var fromBlue:CGFloat = 0
//        var fromAlpha:CGFloat = 0
//        fromColor.getRed(&fromRed, green: &fromGreen, blue: &fromBlue, alpha: &fromAlpha)
     
        return (red + green + blue)
//        let redValue = (max(red, fromRed) - min(red, fromRed)) * 255
//        let greenValue = (max(green, fromGreen) - min(green, fromGreen)) * 255
//        let blueValue = (max(blue, fromBlue) - min(blue, fromBlue)) * 255
//
//        return Int(redValue + greenValue + blueValue)
  }
}

//extension MPVolumeView {
//    static func setVolume(_ volume: Float) -> Void {
//        let volumeView = MPVolumeView()
//        let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
//
//        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
//            slider?.value = volume
//        }
//    }
//}

final class VolumeObserver: ObservableObject {

    @Published var volume: Float = AVAudioSession.sharedInstance().outputVolume

    // Audio session object
    private let session = AVAudioSession.sharedInstance()

    // Observer
    private var progressObserver: NSKeyValueObservation!

    func subscribe() {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            try session.setActive(true, options: [])
        } catch {
            print("cannot activate session")
        }

        progressObserver = session.observe(\.outputVolume) { [self] (session, value) in
            DispatchQueue.main.async {
                self.volume = session.outputVolume
            }
        }
    }

    func unsubscribe() {
        self.progressObserver.invalidate()
    }

    init() {
        subscribe()
    }
}

enum MyError: Error {
    case notImplemented(String)
}
