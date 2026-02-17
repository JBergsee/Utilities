//
//  File.swift
//  
//
//  Created by Johan Nyman on 2022-07-01.
//

import UIKit



//To be implemented by e.g. TableViewController
@MainActor public protocol NextPrevDetailViewDelegate: AnyObject {
    associatedtype DetailModelType
    
    func getNextAfter(actual:DetailModelType) -> DetailModelType?
    func getPreviousBefore(actual:DetailModelType) -> DetailModelType?
    func modelWasUpdated(actual:DetailModelType)
}


//To be implemented by the corresponding DetailViewController
public protocol NextPrevModelChanging: UIViewController, ModelConfigurable {
    associatedtype DetailModel
    associatedtype Delegate : NextPrevDetailViewDelegate where Delegate.DetailModelType == DetailModel
     
    var model: DetailModel { get set}
    var modelDelegate: Delegate? { get set }
    func showNext()
    func showPrevious()
    
    //buttons
    var nextButton: UIBarButtonItem? { get }
    var prevButton: UIBarButtonItem? { get }
    //(These can be changed to anything that has 'isEnabled')
    //To do set in another protocol (Enableable) in the future
    
    ///To be called in configureWith(model: Any)
    func updateNextPrevButtons()
}

@MainActor public extension NextPrevModelChanging {
    
    func showNext() {
        //Update any possible textfield
        view.endEditing(false)
        
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
        //Update any possible textfield
        view.endEditing(false)

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
    
    func updateNextPrevButtons() {
        //Do we have a previous one?
        if modelDelegate?.getPreviousBefore(actual: model) != nil {
            prevButton?.isEnabled = true
        } else {
            prevButton?.isEnabled = false
        }
        
        //Do we have a next one?
        if modelDelegate?.getNextAfter(actual: model) != nil {
            nextButton?.isEnabled = true
        } else {
            nextButton?.isEnabled = false
        }
    }
}
