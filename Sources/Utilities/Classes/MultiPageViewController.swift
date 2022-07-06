//
//  MultiPageViewController.swift
//  JourneyLog
//
//  Created by Johan Nyman on 2022-02-14.
//

import Foundation
import UIKit

open class MultiPageViewController : UIViewController {
    
    
    @IBOutlet var scrollView:UIScrollView!
    @IBOutlet var segmentedControl:UISegmentedControl!
    @IBOutlet var pageControl:UIPageControl?
    
    // To be used when scrolls originate from the UIPageControl
    private var pageControlUsed:Bool = false
    
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        //dataSource outlet must be set in Nib, for example the files owner or the view controller containing the scroll view
        let numberOfPages = numberOfPages()
        
        // view controllers are created lazily
        
        //Set up scroll view
        self.scrollView?.isPagingEnabled = true;
        self.scrollView?.clipsToBounds = true; //Do not show anything outside the bounds, as this makes it really hard to debug...
        self.scrollView?.showsHorizontalScrollIndicator = false
        self.scrollView?.showsVerticalScrollIndicator = false
        self.scrollView?.scrollsToTop = false
        self.scrollView?.delegate = self
        
        //set up pagecontrol
        self.pageControl?.numberOfPages = numberOfPages
        self.pageControl?.currentPage = 0;
        
        //Set up segmentedControl
        if (self.segmentedControl != nil) {
            
            //Titles
            self.segmentedControl?.removeAllSegments() //In case they're set in IB
            
            for segment in 0...numberOfPages-1 {
                let segmentTitle = titleForPage(segment)
                self.segmentedControl?.insertSegment(withTitle: segmentTitle, at: segment, animated: false)
            }
            
            //Set the action
            self.segmentedControl?.addTarget(self, action:#selector(changePage), for: .valueChanged)
        }
        
        //Pages are not yet created
        //A call to change viewport size is required
        
        //Select the first page for first view load
        self.segmentedControl.selectedSegmentIndex = 0
    }
    
    open override func viewDidLayoutSubviews() {
        //Set the correct scrollview width and prepare subviews.
        changeViewPortSize(newSize: self.scrollView.frame.size)
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        //Get the inputs from any active field...
        self.view.endEditing(false)
        
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
        
        let numberOfPages = numberOfPages()
        
        self.scrollView.contentSize = CGSize(width: newSize.width * CGFloat(numberOfPages), height: newSize.height)
        
        //remove all old page views from scrollView.
        for subview in self.scrollView.subviews {
            subview.removeFromSuperview()
        }
        
        
        // load the visible page
        let currentPage = self.segmentedControl?.selectedSegmentIndex ?? 0
        self.goTo(currentPage) //Will also load pages on either side
        
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
    
    func loadScrollViewWithPageNbr(_ page:Int) {
        
        let numberOfPages = numberOfPages()
        
        //check for valid page number
        guard page >= 0, page < numberOfPages else { return }
        
        //Get the viewController
        let controller = viewControllerForPage(page)
        
        //And add as child controller
        self.addChild(controller)
        
        //Tell it will appear
        //Explicit call since we're already in the superview's viewWillAppear
        controller.viewWillAppear(true)
        
        // add the controller's view to the scroll view
        if (controller.view.superview == nil)
        {
            
            var frame = self.scrollView.frame //controller.view.frame;
            frame.origin.x = frame.size.width * CGFloat(page)
            frame.origin.y = 0;
            controller.view.frame = frame
            controller.view.autoresizesSubviews = true
            self.scrollView.addSubview(controller.view)
            
            //Invalidate views for redisplay
            controller.view.setNeedsLayout()
            
        }
        
    }
    
    //MARK: - Change pages
    
    func goTo(_ page: Int) {
        
        let numberOfPages = numberOfPages()
        
        //check for valid page number
        guard page >= 0, page < numberOfPages else { return }
        
        // load the visible page and the page on either side of it (to avoid flashes when the user starts scrolling)
        
        self.loadScrollViewWithPageNbr(page - 1)
        self.loadScrollViewWithPageNbr(page)
        self.loadScrollViewWithPageNbr(page + 1)
        
        // update the scroll view to the appropriate page
        var viewPort = self.scrollView.bounds
        viewPort.origin.x = viewPort.size.width * CGFloat(page)
        viewPort.origin.y = 0 //sets us at the top of the page
        
        self.scrollView.scrollRectToVisible(viewPort, animated:true) //Changing bounds
        
        // Set the boolean used when scrolls originate externally, for example the UIPageControl or a button. See scrollViewDidScroll: above.
        pageControlUsed = true
        
        //Update the pagecontrol if another control was used
        if (self.pageControl != nil) {
            self.pageControl?.currentPage = page
        }
        
        //Update the segmented control if another control was used
        if (self.segmentedControl != nil) {
            self.segmentedControl?.selectedSegmentIndex = page
        }
        
    }
    
    //This should be set as selector of the UIPageControl and UISegmentedControl
    @objc func changePage(sender:Any) {
        var page = 0;
        if let control = sender as? UISegmentedControl {
            page = control.selectedSegmentIndex
        } else if let control = sender as? UIPageControl {
            page = control.currentPage
        }
        
        self.goTo(page)
        
    }
    
    func increasePage() {
        
        let page = self.pageControl?.currentPage ?? 0
        self.goTo(page+1)
    }
    
    func decreasePage() {
        
        let page = self.pageControl?.currentPage ?? 0
        self.goTo(page-1)
        
    }
    
    
    
    //MARK: - Delegate, or to be overridden by subclasses.
    
    open func viewControllerForPage(_ pageNumber: Int) -> UIViewController {
        fatalError("\(self) must override viewControllerForPage")
    }
    
    open func numberOfPages() -> Int {
        fatalError("\(self) must override numberOfPages")
    }
    
    open func titleForPage(_ nbr: Int) -> String {
        fatalError("\(self) must override titleForPage")
    }
}


extension MultiPageViewController:UIScrollViewDelegate {
    
    public func scrollViewDidScroll(_ sender:UIScrollView) {
        // We don't want a "feedback loop" between the UIPageControl and the scroll delegate in
        // which a scroll event generated from the user hitting the page control triggers updates from
        // the delegate method. We use a boolean to disable the delegate logic when the page control is used.
        
        guard !pageControlUsed else {
            // do nothing - the scroll was initiated from the page control, not the user dragging
            return
        }
        
        // Switch the indicator when more than 50% of the previous/next page is visible
        let pageWidth = self.scrollView.frame.size.width
        let page = Int(floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1)
        
        //update pageControl
        self.pageControl?.currentPage = page
        
        //update the segmented control
        self.segmentedControl?.selectedSegmentIndex = page;
        
        // load the visible page and the page on either side of it (to avoid flashes when the user starts scrolling)
        self.loadScrollViewWithPageNbr(page - 1)
        self.loadScrollViewWithPageNbr(page)
        self.loadScrollViewWithPageNbr(page + 1)
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
