//
//  ZomAddBuddyViewController.swift
//  Zom
//
//  Created by N-Pex on 2015-11-18.
//
//

import UIKit
import ChatSecureCore

public class ZomAddBuddyViewController: UIViewController, QRCodeReaderDelegate, OTRNewBuddyViewControllerDelegate {
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    public var account:OTRAccount? = nil
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var addButton: UIButton!
    
    var pageController:UIPageViewController?

    var previousSegmentedControlIndex:Int = 0
    var vcAdd:OTRNewBuddyViewController? = nil
    var vcQR:QRCodeReaderViewController? = nil
    var vcMyQR:OTRQRCodeViewController? = nil
    
    init(accountId : String) {
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = ZomTheme().lightThemeColor
        //[self createContentPages];
        
        
        //NSDictionary *options = [NSDictionary dictionaryWithObject:
        //[NSNumber numberWithInteger:UIPageViewControllerSpineLocationMin]
        //forKey: UIPageViewControllerOptionSpineLocationKey];
        pageController = UIPageViewController(transitionStyle: UIPageViewControllerTransitionStyle.Scroll, navigationOrientation: UIPageViewControllerNavigationOrientation.Horizontal, options: nil)
        //pageController.dataSource = self
        pageController!.view.frame = self.containerView.frame
        //pageController!.view.removeConstraints(pageController!.view.constraints)
        //pageController!.view.addConstraints(self.containerView.constraints)
        
        vcAdd = OTRNewBuddyViewController(accountId: account!.uniqueId)
        vcAdd!.delegate = self
        vcQR = QRCodeReaderViewController()
        vcQR!.delegate = self
        
        var types = Set<NSNumber>()
        types.insert(NSNumber(int: OTRFingerprintType.OTR.rawValue))
        self.account!.generateShareURLWithFingerprintTypes(types, completion: { (url, error) -> Void in
            if (url != nil && error == nil) {
                self.vcMyQR = OTRQRCodeViewController(QRString: url.absoluteString)
                self.vcMyQR?.view.backgroundColor = ZomTheme().lightThemeColor
            } else {
                self.segmentedControl.removeSegmentAtIndex(2, animated: false)
            }
        })
        
        pageController?.setViewControllers([vcAdd!], direction: UIPageViewControllerNavigationDirection.Forward, animated: true, completion: nil)

        self.addChildViewController(pageController!)
        self.view.addSubview(pageController!.view)
        pageController?.didMoveToParentViewController(self)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        pageController!.view.frame = self.containerView.frame
    }

    @IBAction func cancelButtonPressed(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func addButtonPressed(sender: AnyObject) {
        
        if (self.segmentedControl.selectedSegmentIndex == 0) {
            let vc:OTRNewBuddyViewController = pageController!.viewControllers![0] as! OTRNewBuddyViewController
            vc.performSelector(Selector("doneButtonPressed:"), withObject: self)
        }
    }
    
    @IBAction func segmentedControlValueChanged(sender: AnyObject) {
        
        var direction:UIPageViewControllerNavigationDirection = UIPageViewControllerNavigationDirection.Forward
        if (self.segmentedControl.selectedSegmentIndex < self.previousSegmentedControlIndex) {
            direction = UIPageViewControllerNavigationDirection.Reverse
        }
        self.previousSegmentedControlIndex = self.segmentedControl.selectedSegmentIndex
        
        if (self.segmentedControl.selectedSegmentIndex == 0) {
            pageController?.setViewControllers([vcAdd!], direction: direction, animated: true, completion: nil)
            self.addButton.hidden = false
        } else if (self.segmentedControl.selectedSegmentIndex == 1) {
            pageController?.setViewControllers([vcQR!], direction: direction, animated: true, completion: nil)
            self.addButton.hidden = true
        } else if (self.segmentedControl.selectedSegmentIndex == 2) {
            pageController?.setViewControllers([vcMyQR!], direction: direction, animated: true, completion: nil)
            self.addButton.hidden = true
        }
    }

    public func readerDidCancel(reader:QRCodeReaderViewController) {
        self.segmentedControl.selectedSegmentIndex = 0
        self.segmentedControlValueChanged(self.segmentedControl)
    }
    
    public func reader(reader:QRCodeReaderViewController, didScanResult result:String) {
        vcAdd!.populateFromQRResult(result)
        self.segmentedControl.selectedSegmentIndex = 0
        self.segmentedControlValueChanged(self.segmentedControl)
    }
    
    public func shouldDismissViewController(viewController: OTRNewBuddyViewController!) -> Bool {
        self.cancelButtonPressed(self) // Close
        return false
    }
}