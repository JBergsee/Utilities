//
//  SignatureViewController.swift
//  FlightBriefing
//
//  Created by Johan Nyman on 2022-07-16.
//  Copyright © 2022 JN Avionics. All rights reserved.
//

import UIKit

public class SignatureViewController: DrawViewController {

    @IBOutlet var signLabel: UILabel?
    @IBOutlet var headerLabel: UILabel?

    public var signText: String?
    public var headerText: String?

    public override func viewDidLoad() {
        super.viewDidLoad()
        signLabel?.text = signText ?? "Signature"
        headerLabel?.text = headerText ?? ""
    }

    // MARK: - Button Handling
    
    @IBAction func saveAndClose() {
        // Start by saving
        saveDrawing()
        
        // Tell delegate
        delegate?.drawingWasSaved(drawing)
        
        // Dismiss
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func discardAndClose() {
        // just dismiss
        dismiss(animated: true, completion: nil)
    }
}
