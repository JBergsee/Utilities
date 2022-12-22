//
//  MultiPageViewController.swift
//  JourneyLog
//
//  Created by Johan Nyman on 2022-02-14.
//

import Foundation
import UIKit


public protocol PageProviding: AnyObject {
    func viewControllerForPage(_ pageNumber: Int) -> UIViewController
    func numberOfPages() -> Int
    func titleForPage(_ nbr: Int) -> String
}



open class MultiPageViewController : UIViewController {
    
    @IBOutlet var scrollView:UIScrollView!
    @IBOutlet var segmentedControl:UISegmentedControl!
    @IBOutlet var pageControl:UIPageControl?
    
    //PageProvider
    public weak var pageProvider: PageProviding?
    
    // To be used when scrolls originate from the UIPageControl
    private var pageControlUsed:Bool = false
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        
        //Required for multiline text in segmented control
        UILabel.appearance(whenContainedInInstancesOf: [UISegmentedControl.self]).numberOfLines = 0
    }
    
    ///pageprovider must be set before calling super from subclasses
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupViewsAndControls()
    }
    
    //pageProvider must be set before calling this.
    private func setupViewsAndControls() {
        
        let numberOfPages = pageProvider?.numberOfPages() ?? 1
        
        // view controllers are created lazily
        
        //Set up scroll view
        scrollView?.isPagingEnabled = true;
        scrollView?.clipsToBounds = true; //Do not show anything outside the bounds, as this makes it really hard to debug...
        scrollView?.showsHorizontalScrollIndicator = false
        scrollView?.showsVerticalScrollIndicator = false
        scrollView?.scrollsToTop = false
        scrollView?.delegate = self
        
        //set up pagecontrol
        pageControl?.numberOfPages = numberOfPages
        pageControl?.currentPage = 0;
        
        //Set up segmentedControl
        if (segmentedControl != nil) {
            
            //Titles
            segmentedControl?.removeAllSegments() //In case they're set in IB
            
            for segment in 0...numberOfPages-1 {
                let segmentTitle = pageProvider?.titleForPage(segment)
                segmentedControl?.insertSegment(withTitle: segmentTitle, at: segment, animated: false)
            }
            
            //Set the action
            segmentedControl?.addTarget(self, action:#selector(changePage), for: .valueChanged)
        }
        
        //Pages are not yet created
        //A call to change viewport size is required
        
        //Select the first page for first view load
        segmentedControl.selectedSegmentIndex = 0
    }
    
    open override func viewDidLayoutSubviews() {
        //Set the correct scrollview width and prepare subviews.
        changeViewPortSize(newSize: scrollView.frame.size)
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        //Get the inputs from any active field...
        view.endEditing(false)
        
        super.viewDidDisappear(animated)
    }
    
    
    //MARK: - Handling rotation and resizing
    
    /*
     * When the device orientates, the size must be updated.
     * This must be called AFTER the scrollview frame has changed size.
     */
    
    func changeViewPortSize(newSize:CGSize) {
        
        //Reset scroll view contentsize
        // A page is the width of the scroll view
        
        let numberOfPages = pageProvider!.numberOfPages()
        
        scrollView.contentSize = CGSize(width: newSize.width * CGFloat(numberOfPages), height: newSize.height)
        
        //remove all old page views from scrollView.
        for subview in scrollView.subviews {
            subview.removeFromSuperview()
        }
        
        
        // load the visible page
        let currentPage = segmentedControl?.selectedSegmentIndex ?? 0
        goTo(currentPage) //Will also load pages on either side
        
    }
    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        super.viewWillTransition(to: size, with: coordinator)
        
        // Code here will execute before the rotation begins.
        // Equivalent to placing it in the deprecated method -[willRotateToInterfaceOrientation:duration:]
        
        coordinator.animate { context in
            // Place code here to perform animations during the rotation.
            // You can pass nil for this closure if not necessary.
            
            self.changeViewPortSize(newSize: self.scrollView.bounds.size)
            
        } completion: { context in
            // Code here will execute after the rotation has finished.
            // Equivalent to placing it in the deprecated method -[didRotateFromInterfaceOrientation:]
        }
    }
    
    //MARK: - Insert actual views
    
    open func loadScrollViewWithPageNbr(_ page:Int) {
        
        let numberOfPages = pageProvider!.numberOfPages()
        
        //check for valid page number
        guard page >= 0, page < numberOfPages else { return }
        
        //Get the viewController
        guard let controller = pageProvider?.viewControllerForPage(page) else { return }
        
        //And add as child controller
        addChild(controller)
        
        //Tell it will appear
        //Explicit call since we're already in the superview's viewWillAppear
        //But first, since this get's called when scrolling, save any possible input.
        controller.view.endEditing(false) //Asks the view and it's subviews to resign first responder.
        controller.viewWillAppear(true)
        
        // add the controller's view to the scroll view
        if (controller.view.superview == nil)
        {
            
            var frame = self.scrollView.frame //controller.view.frame;
            frame.origin.x = frame.size.width * CGFloat(page)
            frame.origin.y = 0;
            controller.view.frame = frame
            controller.view.autoresizesSubviews = true
            scrollView.addSubview(controller.view)
            
            //Invalidate views for redisplay
            controller.view.setNeedsLayout()
            
        }
        
    }
    
    //MARK: - Change pages
    
    func goTo(_ page: Int) {
        
        let numberOfPages = pageProvider!.numberOfPages()
        
        //check for valid page number
        guard page >= 0, page < numberOfPages else { return }
        
        // load the visible page and the page on either side of it (to avoid flashes when the user starts scrolling)
        
        loadScrollViewWithPageNbr(page - 1)
        loadScrollViewWithPageNbr(page)
        loadScrollViewWithPageNbr(page + 1)
        
        // update the scroll view to the appropriate page
        var viewPort = self.scrollView.bounds
        viewPort.origin.x = viewPort.size.width * CGFloat(page)
        viewPort.origin.y = 0 //sets us at the top of the page
        
        scrollView.scrollRectToVisible(viewPort, animated:true) //Changing bounds
        
        // Set the boolean used when scrolls originate externally, for example the UIPageControl or a button. See scrollViewDidScroll: above.
        pageControlUsed = true
        
        //Update the pagecontrol if another control was used
        pageControl?.currentPage = page
        
        //Update the segmented control if another control was used
        segmentedControl?.selectedSegmentIndex = page
    }
    
    ///This should be set as selector of the UIPageControl and UISegmentedControl
    @objc func changePage(sender:Any) {
        var page = 0;
        if let control = sender as? UISegmentedControl {
            page = control.selectedSegmentIndex
        } else if let control = sender as? UIPageControl {
            page = control.currentPage
        }
        
        goTo(page)
    }
    
    func increasePage() {
        
        let page = pageControl?.currentPage ?? 0
        self.goTo(page+1)
    }
    
    func decreasePage() {
        
        let page = pageControl?.currentPage ?? 0
        goTo(page-1)
        
    }
}


extension MultiPageViewController: UIScrollViewDelegate {
    
    public func scrollViewDidScroll(_ sender:UIScrollView) {
        // We don't want a "feedback loop" between the UIPageControl and the scroll delegate in
        // which a scroll event generated from the user hitting the page control triggers updates from
        // the delegate method. We use a boolean to disable the delegate logic when the page control is used.
        
        guard !pageControlUsed else {
            // do nothing - the scroll was initiated from the page control, not the user dragging
            return
        }
        
        // Switch the indicator when more than 50% of the previous/next page is visible
        let pageWidth = scrollView.frame.size.width
        let page = Int(floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1)
        
        //update pageControl
        pageControl?.currentPage = page
        
        //update the segmented control
        segmentedControl?.selectedSegmentIndex = page;
        
        // load the visible page and the page on either side of it (to avoid flashes when the user starts scrolling)
        loadScrollViewWithPageNbr(page - 1)
        loadScrollViewWithPageNbr(page)
        loadScrollViewWithPageNbr(page + 1)
        // A possible optimization would be to unload the views+controllers which are no longer visible
    }
    
    
    // At the begin of scroll dragging, reset the boolean used when scrolls originate from the UIPageControl
    public func scrollViewWillBeginDragging(_ scrollView:UIScrollView) {
        pageControlUsed = false
    }
    
    // At the end of scroll animation, reset the boolean used when scrolls originate from the UIPageControl
    public func scrollViewDidEndDecelerating(_ scrollView:UIScrollView) {
        pageControlUsed = false
    }
}
