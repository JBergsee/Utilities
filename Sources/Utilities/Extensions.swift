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

@objc
public extension FileManager {
    static var documentsDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    static var applicationSupportDirectory: URL {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        return paths[0]
    }
}

//Can be used to get paper Log Nr PPS_Flight summary string, or the NOTAM D) item (temporary times)
public extension String {
    func slice(from: String, to: String) -> String? {
        guard let fromRange = from.isEmpty ? startIndex..<startIndex : range(of: from) else { return nil }
        guard let toRange = to.isEmpty ? endIndex..<endIndex : range(of: to, range: fromRange.upperBound..<endIndex) else { return nil }
        return String(self[fromRange.upperBound..<toRange.lowerBound])
    }
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
