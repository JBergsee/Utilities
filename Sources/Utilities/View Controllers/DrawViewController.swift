//
//  DrawViewController.swift
//
//
//  Created by Johan Nyman on 2022-09-12.
//

import UIKit
import PencilKit


@objc
public protocol DrawViewControllerDelegate {
    @objc func drawingWasSaved(_ drawing: PKDrawing?)
}

@objcMembers
open class DrawViewController: UIViewController {

    public weak var delegate: DrawViewControllerDelegate?

    @IBOutlet public var canvas: PKCanvasView!

    private var toolPicker: PKToolPicker = PKToolPicker()

    private var drawingExist: Bool = false

    public var isEmpty: Bool {
        get {
            drawingExist == false
        }
    }

    //To set and get what's on the canvas.
    public var drawing: PKDrawing? {
        didSet {
            drawingExist = drawing != nil
            
            //Forward to the canvas (if view is loaded)
            if viewIfLoaded != nil {
                canvas.drawing = drawing ?? PKDrawing()
                //Must also be done before the view appears, since this might be called before the view is actually loaded,
            }
         }
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        //Configure the canvas
        canvas.drawingPolicy = .anyInput
        usePen()

        //Set ourselves as delegate to keep focus for undo/redo
        canvas.delegate = self

        //Make a new drawing or set if already set
        canvas.drawing = drawing ?? PKDrawing()
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //Set canvas as first responder for undo/redo to work
        canvas.becomeFirstResponder()
    }

}

extension DrawViewController: PKCanvasViewDelegate {

    public func canvasViewDidBeginUsingTool(_ canvasView: PKCanvasView) {
        //Set first responder status
        canvas.becomeFirstResponder()
    }

    public func canvasViewDidEndUsingTool(_ canvasView: PKCanvasView) {
        drawingExist = true //Something has been drawn (or erased)
    }
}


//MARK: - Tool Handling

public extension DrawViewController {

    @IBAction func usePen() {
        canvas.tool = PKInkingTool(.pen,
                                   color: .black,
                                   width: 4.0)
        //Black color is actually white in dark mode. If this is ever corrected by Apple, change to labelColor.
    }

    @IBAction func useEraser() {
        canvas.tool = PKEraserTool(.bitmap)
    }

    @IBAction func showTools() {
        toolPicker.setVisible(true, forFirstResponder: canvas )
        toolPicker.addObserver(canvas)
        canvas.becomeFirstResponder()
        //Set the previously selected tool from the picker.
        canvas.tool = toolPicker.selectedTool
    }

    @IBAction func hideTools() {
        toolPicker.setVisible(false, forFirstResponder: canvas)
        toolPicker.removeObserver(canvas)
    }

    @IBAction func toggleTools() {
        if toolPicker.isVisible {
            hideTools()
        } else {
            showTools()
        }
    }
}

//MARK: - Button Handling
public extension DrawViewController {

    @IBAction func clearDrawing() {
        //Set a new canvas by changing internally
        drawing = nil
        //This will replace the canvas
        drawingExist = false
    }

    @IBAction func saveDrawing() {
        //Save in property
        drawing = canvas.drawing
    }

}
