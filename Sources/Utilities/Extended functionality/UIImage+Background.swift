//
//  File.swift
//  
//
//  Created by Johan Nyman on 2022-12-16.
//

import UIKit


// Source: https://stackoverflow.com/questions/28299886/how-to-set-a-background-color-in-uiimage-in-swift-programming

public extension UIImage {
    func withBackground(color: UIColor, opaque: Bool = true) -> UIImage {
        guard size.width > 0,
              size.height > 0 else {
            return UIImage()
        }
        UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
        
        guard let ctx = UIGraphicsGetCurrentContext(), let image = cgImage else { return self }
        defer { UIGraphicsEndImageContext() }
        
        let rect = CGRect(origin: .zero, size: size)
        ctx.setFillColor(color.cgColor)
        ctx.fill(rect)
        ctx.concatenate(CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: size.height))
        ctx.draw(image, in: rect)
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}
