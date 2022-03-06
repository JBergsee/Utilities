//
//  File.swift
//  
//
//  Created by Johan Nyman on 2022-02-05.
//

import Foundation
import UIKit
import OSLog

public extension Double
{
    func toRadians() -> Double { return self * Double.pi / 180 }
    func toDegrees() -> Double { return self * 180 / Double.pi }
}

@objc
public extension FileManager {
    static var documentsDirectory: URL {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        Logger.functionality.log("Document directory: \(path)")
        return path
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

public extension Notification.Name {
    
    //Notification names
    static let NOTIFICATIONSOMETHINGHAPPENED = Notification.Name("Something Happened")
    
    func post(object: Any? = nil, userInfo: [AnyHashable : Any]? = nil) {
        NotificationCenter.default.post(name: self, object: object, userInfo: userInfo)
    }
    
    @discardableResult
    func onPost(object: Any? = nil, queue: OperationQueue? = nil, using: @escaping (Notification) -> Void) -> NSObjectProtocol {
        return NotificationCenter.default.addObserver(forName: self, object: object, queue: queue, using: using)
    }
    
    /*
     Now when you want to post a norification with no details, which is the most common usage, you just do:
     Notification.Name.NOTIFICATIONSOMETHINGHAPPENED.post()
     
     And to "catch" it you just do:
     Notification.Name.NOTIFICATIONSOMETHINGHAPPENED.onPost { [weak self] note in
     guard let `self` = self else { return }
     // Do your stuff here
     }
     
     */
}

