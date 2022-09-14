//
//  File.swift
//  
//
//  Created by Johan Nyman on 2022-09-12.
//

import UIKit

public extension UIImage {
    
    func isLandscape() -> Bool {
        let aspectRatio = size.width/size.height
        return aspectRatio > 1
    }
    
    func isPortrait() -> Bool {
        return !isLandscape()
    }
    
    /// Scales the image proportionally so longest dimension (width or height) is maxDimension points
    func scaleDownTo(maxDimension: CGFloat) -> UIImage {
        
        guard maxDimension < size.width,
              maxDimension < size.height else {
                  //Already too small
                  return self
              }

        //Find out portrait landscape and use that to find scale factor
        let scaleFactor = isLandscape() ? maxDimension / size.width : maxDimension / size.height
        
        let newSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { (context) in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
     func prettyPrintedSize() -> String {
        let jpeg = jpegData(compressionQuality: 1.0)
        //let png = pngData()
         return "(\(self.size.width),\(self.size.height)), jpeg: \(jpeg?.prettySize ?? "[no]")"
    }
}
