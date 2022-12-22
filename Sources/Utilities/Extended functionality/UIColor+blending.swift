//
//  File.swift
//  
//
//  Created by Johan Nyman on 2022-12-18.
//

import UIKit

public extension UIColor {
    
    static func blend(color1: UIColor, intensity1: CGFloat = 0.5, color2: UIColor, intensity2: CGFloat = 0.5) -> UIColor {
        let total = intensity1 + intensity2
        let l1 = intensity1/total
        let l2 = intensity2/total
        guard l1 > 0 else { return color2}
        guard l2 > 0 else { return color1}
        var (r1, g1, b1, a1): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        var (r2, g2, b2, a2): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        
        color1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        return UIColor(red: l1*r1 + l2*r2, green: l1*g1 + l2*g2, blue: l1*b1 + l2*b2, alpha: l1*a1 + l2*a2)
    }
    
    func simulatingAlpha(_ alpha: CGFloat, over color2: UIColor = .label) -> UIColor {
        return UIColor.simulatingAlpha(alpha, for: self, over: color2)
    }
    
    static func simulatingAlpha(_ alpha: CGFloat, for color1: UIColor, over color2: UIColor = .label) -> UIColor {
        
        let whiteComponents: [CGFloat] = [1.0, 1.0, 1.0, 1.0] //UIColor.white.cgColor.components only returns [1.0, 1.0]
        let blackComponents: [CGFloat] = [0.0, 0.0, 0.0, 1.0] //UIColor.black.cgColor.components only returns [0.0, 1.0]
        
        //set a valid default depending on interfaceStyle
        var rgba1: [CGFloat] = whiteComponents
        var rgba2: [CGFloat] = whiteComponents
        if UITraitCollection.current.userInterfaceStyle == .dark {
            rgba1 = blackComponents
            rgba2 = blackComponents
        }
        
        print(color1)
        print(color2)
        
        if let components = color1.cgColor.components, components.count > 2 {
            rgba1 = components
        }
        
        if let components = color2.cgColor.components, components.count > 2  {
            rgba2 = components
        }
        
        print(rgba1)
        print(rgba2)
        
        let r1: CGFloat = rgba1[0]
        let g1: CGFloat = rgba1[1]
        let b1: CGFloat = rgba1[2]
        
        let r2: CGFloat = rgba2[0]
        let g2: CGFloat = rgba2[1]
        let b2: CGFloat = rgba2[2]
        
        let r3 = ((1 - alpha) * r2) + (r1 * alpha)
        let g3 = ((1 - alpha) * g2) + (g1 * alpha)
        let b3 = ((1 - alpha) * b2) + (b1 * alpha)
        
        print("Simulated RGB: \(Int(r3 * 255)), \(Int(g3 * 255)), \(Int(b3 * 255))")
        
        let newComponents: [CGFloat] = [r3, g3, b3, 1.0]
        let space = CGColorSpace(name:CGColorSpace.sRGB)!
        guard let cgColor3 = CGColor(colorSpace: space, components: newComponents) else {
            print("Failed to create new CGColor in default color space")
            return color1
        }
        
        return UIColor(cgColor: cgColor3)
    }
}
