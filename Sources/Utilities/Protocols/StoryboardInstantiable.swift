//
//  File.swift
//  
//
//  Created by Johan Nyman on 2022-06-29.
//

import Foundation
import UIKit

@MainActor public protocol StoryboardInstantiable where Self: UIViewController {
    
    static func initFromStoryboard() -> Self
    static func initFromStoryboard(identifier: String) -> Self
    
    static var storyboard:String { get }
    static var bundle:Bundle { get }
    static var identifier:String { get }
    
}

public extension StoryboardInstantiable {
    static func initFromStoryboard() -> Self {
        let storyboard = UIStoryboard(name: Self.storyboard, bundle: Self.bundle)
        return storyboard.instantiateViewController(withIdentifier: Self.identifier) as! Self
    }
    
    static func initFromStoryboard(identifier: String) -> Self {
        let storyboard = UIStoryboard(name: Self.storyboard, bundle: Self.bundle)
        return storyboard.instantiateViewController(withIdentifier: identifier) as! Self
    }
}
