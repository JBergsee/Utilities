//
//  File.swift
//  
//
//  Created by Johan Nyman on 2022-06-29.
//

import Foundation
import UIKit

public protocol StoryboardInstantiable {
    associatedtype VC
    
    static func initFromStoryboard() -> VC
    static func initFromStoryboard(identifier: String) -> VC
    
    static var storyboard:String {get}
    static var bundle:Bundle {get}
    static var identifier:String {get}
    
}

public extension StoryboardInstantiable {
    static func initFromStoryboard() -> VC {
        let storyboard = UIStoryboard(name: Self.storyboard, bundle: Self.bundle)
        return storyboard.instantiateViewController(withIdentifier: Self.identifier) as! VC
    }
    
    static func initFromStoryboard(identifier: String) -> VC {
        let storyboard = UIStoryboard(name: Self.storyboard, bundle: Self.bundle)
        return storyboard.instantiateViewController(withIdentifier: identifier) as! VC
    }
}
