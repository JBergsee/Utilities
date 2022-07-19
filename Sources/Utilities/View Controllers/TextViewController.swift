//
//  TextViewController.swift
//  
//
//  Created by Johan Nyman on 2022-05-12.
//

import UIKit

@objc public class TextViewController: UIViewController {

    @IBOutlet var textView:UITextView!

    public var text:String?
    public var rightMenuButtons:[UIBarButtonItem] {
        get {
            navigationItem.rightBarButtonItems ?? []
        }
        set {
            navigationItem.setRightBarButtonItems(newValue, animated: false)
        }
    }
 
    public override func viewWillAppear(_ animated:Bool) {
        textView.text = text

        //        //A bug in iOS SDK resets the font when using settext and property selectable = NO,
        //        // therefore we set it programmatically here
        //        UIFont * font = [UIFont systemFontOfSize:17.0];
        //        self.textView.font = font;

        super.viewWillAppear(animated)
    }
    

    @IBAction func close() {
        presentingViewController?.dismiss(animated: true)
    }
    
    public static func showTextViewWith(text:String, from viewController:UIViewController, with rightBarButtons:[UIBarButtonItem]? = nil) {
        let storyboard = UIStoryboard(name: "Views", bundle: .module)
        let navController = storyboard.instantiateViewController(withIdentifier: "TextNavController") as! UINavigationController
        let tvvc = navController.topViewController as! TextViewController
        tvvc.text = text
        tvvc.rightMenuButtons = rightBarButtons ?? []
        viewController.present(navController, animated: true, completion: nil)
    }
}
