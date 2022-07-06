//
//  File.swift
//  
//
//  Created by Johan Nyman on 2022-07-01.
//

import UIKit



//To be implemented by e.g. TableViewController
public protocol NextPrevDetailViewDelegate {
    associatedtype DetailModelType
    
    func getNextAfter(actual:DetailModelType) -> DetailModelType?
    func getPreviousBefore(actual:DetailModelType) -> DetailModelType?
    func modelWasUpdated(actual:DetailModelType)
}


//To be implemented by the corresponding DetailViewController
public protocol NextPrevModelChanging: UIViewController, ModelConfigurable {
    associatedtype DetailModel
    associatedtype Delegate : NextPrevDetailViewDelegate where Delegate.DetailModelType == DetailModel
     
    var model:DetailModel { get set}
    var modelDelegate: Delegate? { get set }
    func showNext()
    func showPrevious()
    
    //buttons
    var nextButton:UIBarButtonItem? { get }
    var prevButton:UIBarButtonItem? { get }
    //(These can be changed to anything that has 'isEnabled')
    //To do set in another protocol (Enableable) in the future
}

public extension NextPrevModelChanging {
    
    func showNext() {
        //Get next model
        guard let newModel = modelDelegate?.getNextAfter(actual: model) else {
            //there is no more model
            nextButton?.isEnabled = false
            return
        }
        //Set the new model
        model = newModel
        //Reenable prev button
        prevButton?.isEnabled = true
        //Update View
        configureWith(model: model)
    }
    
    func showPrevious() {
        //Get previous model
        guard let newModel = modelDelegate?.getPreviousBefore(actual: model) else {
            //there is no more model
            prevButton?.isEnabled = false
            return
        }
        //Set the new model
        model = newModel
        //Reenable nextbutton
        nextButton?.isEnabled = true
        //Update View
        configureWith(model: model)
    }
}
