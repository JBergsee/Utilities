//
//  File.swift
//  
//
//  Created by Johan Nyman on 2022-02-05.
//

import Foundation
import UIKit

public extension Double
{
    func toRadians() -> Double { return self * Double.pi / 180 }
    func toDegrees() -> Double { return self * 180 / Double.pi }
}



public extension UITextView {
    func addTextFieldBorder() {
        let borderColor : UIColor = UIColor.systemGray
        self.layer.borderWidth = 0.5
        self.layer.borderColor = borderColor.cgColor
        self.layer.cornerRadius = 5.0
    }
    func addSquareBorder() {
        let borderColor : UIColor = UIColor.label
        self.layer.borderWidth = 1.0
        self.layer.borderColor = borderColor.cgColor
        self.layer.cornerRadius = 0.0
    }

}



public extension UIView {
    
    func rotateAnimated(_ toValue: CGFloat, duration: CFTimeInterval = 0.2) {
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        
        animation.toValue = toValue
        animation.duration = duration == 0 ? 0.0001 : duration //a duration of zero will set the default value of 0.25, while our intent is to make it quick
        animation.isRemovedOnCompletion = false
        animation.fillMode = CAMediaTimingFillMode.forwards
        
        self.layer.add(animation, forKey: nil)
    }
}

public extension Bundle {
    // Name of the app - title under the icon.
    var displayName: String? {
            return object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
                object(forInfoDictionaryKey: "CFBundleName") as? String
    }
}


public extension Data {
  var prettySize: String {
    let formatter = ByteCountFormatter()
    formatter.countStyle = .binary
    return formatter.string(fromByteCount: Int64(count))
  }
}
