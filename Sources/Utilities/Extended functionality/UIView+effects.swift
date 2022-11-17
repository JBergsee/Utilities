//
//  File.swift
//  
//
//  Created by Johan Nyman on 2022-11-15.
//

import UIKit

public extension UIView {
    
    func addShadow(color: CGColor = UIColor.label.cgColor, opacity: Float = 0.8, offset: CGSize = CGSize(width: 0,height: 0), radius: CGFloat = 7) {
        layer.shadowColor = color
        layer.masksToBounds = false
        layer.shadowOpacity = opacity
        layer.shadowOffset = offset
        layer.shadowRadius = radius
    }
}

public extension UIView {
    
    func rotateAnimated(_ toValue: CGFloat, duration: CFTimeInterval = 0.2) {
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        
        animation.toValue = toValue
        animation.duration = duration == 0 ? 0.0001 : duration //a duration of zero will set the default value of 0.25, while the intent probably is to make it quick
        animation.isRemovedOnCompletion = false
        animation.fillMode = CAMediaTimingFillMode.forwards
        
        self.layer.add(animation, forKey: nil)
    }
}
