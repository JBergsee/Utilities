//
//  File.swift
//  
//
//  Created by Johan Nyman on 2022-03-06.
//

import Foundation
import UIKit

public protocol StoryboardInstantiable {

    static var storyboardName: String { get }
    static var storyboardBundle: Bundle? { get }
    static var storyboardIdentifier: String? { get }
}

public extension StoryboardInstantiable {

    static var storyboardBundle: Bundle? { return nil }
    static var storyboardIdentifier: String? { return nil }

    static func makeFromStoryboard() -> Self {
        let storyboard = UIStoryboard(name: storyboardName, bundle: storyboardBundle)

        if let storyboardIdentifier = storyboardIdentifier {
            return storyboard.instantiateViewController(withIdentifier: storyboardIdentifier) as! Self
        } else {
            return storyboard.instantiateInitialViewController() as! Self
        }
    }
}
