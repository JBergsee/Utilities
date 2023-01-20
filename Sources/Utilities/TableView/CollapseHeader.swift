//
//  CollapseHeader.swift
//  TheBestTableViewController
//
//  Created by Johan Nyman on 2022-07-05.
//

import UIKit

open class CollapseHeader: UITableViewHeaderFooterView, CollapseControlling, ModelConfigurable {
    
    @IBOutlet public var collapseButton: UIView?
    @IBOutlet public var collapseLabel: UILabel?
    @IBOutlet public var titleLabel: UILabel?
    
    public weak var delegate: CollapseControllingDelegate?
    public var section: Int = 0
    
    public var isCollapsed: Bool {
        delegate?.isCollapsed(section) ?? false //Open by default
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func awakeFromNib() {
        // Register taps on the collapsebutton
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapCollapse(_:)))
        collapseButton?.addGestureRecognizer(tapRecognizer)
        collapseButton?.isUserInteractionEnabled = true //false by default for UIImageView!
    }
    
    open func configureWith(model: Any) {
        guard let array = model as? [Any],
        let text = array.first as? String,
        let nbr = array.last as? Int else {
            return
        }
        titleLabel?.text = text + " (\(nbr) items)"
    }
    
    /// Trigger toggle section when tapping on the header
    @objc func tapCollapse(_ gestureRecognizer: UITapGestureRecognizer) {
        delegate?.toggleSection(section, for: self)
    }
    
    /// Trigger toggle section when tapping the button
    @IBAction open func collapseButtonTapped(_ sender: UIButton) {
        delegate?.toggleSection(section, for: self)
    }
    
    /// Called by the delegate with correct status
    open func setCollapsed(_ collapsed: Bool, animated: Bool) {
        //
        // Animate the arrow rotation (see UIView Extension)
        //
        //Let the arrow point down initially (expanded)
        collapseButton?.rotateAnimated(collapsed ? -.pi / 2 : 0.0 , duration: animated ? 0.3 : 0.0)
        
    }
}
