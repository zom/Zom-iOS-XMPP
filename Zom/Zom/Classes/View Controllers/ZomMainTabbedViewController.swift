//
//  ZomMainTabbedViewController.swift
//  Zom
//
//  Created by N-Pex on 2016-11-14.
//
//

import Foundation

public class ZomMainTabbedViewController: UITabBarController {
    
    private var chatsViewController:ZomConversationViewController? = nil
    private var friendsViewController:ZomComposeViewController? = nil
    private var meViewController:ZomMyQRViewController? = nil
    private var observerContext = 0
    private var observersRegistered:Bool = false
    
    convenience init() {
        self.init(nibName:nil, bundle:nil)
    }
    
    public func createTabs() {
        if let appDelegate = UIApplication.sharedApplication().delegate as? OTRAppDelegate {
            
            var newControllers:[UIViewController] = [];
            for child in childViewControllers {
                if (child.restorationIdentifier == "chats") {
                    chatsViewController = (appDelegate.conversationViewController as! ZomConversationViewController)
                    chatsViewController!.tabBarItem = child.tabBarItem
                    newControllers.append(chatsViewController!)
                } else if (child.restorationIdentifier == "friends") {
                    friendsViewController = ZomComposeViewController()
                    if (friendsViewController!.view != nil) {
                        friendsViewController!.tabBarItem = child.tabBarItem
                    }
                    friendsViewController?.delegate = appDelegate.splitViewCoordinator
                    newControllers.append(friendsViewController!)
                } else if (child.restorationIdentifier == "me") {
                    meViewController = child as? ZomMyQRViewController
                    newControllers.append(child)
                }
                else {
                    newControllers.append(child)
                }
            }
            setViewControllers(newControllers, animated: false)
        }
        
        // Hide the tab item text, but don't null it (we use it to build the top title)
        for item:UITabBarItem in self.tabBar.items! {
            item.selectedImage = item.image
            item.image = item.image!.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
            item.setTitleTextAttributes([NSForegroundColorAttributeName:UIColor.clearColor(),
                NSFontAttributeName:UIFont.systemFontOfSize(1)], forState: UIControlState.Normal)
            item.imageInsets = UIEdgeInsets(top: 5, left: 0, bottom: -5, right: 0)
        }
        
        // Show current tab by a small white top border
        tabBar.selectionIndicatorImage = createSelectionIndicator(UIColor.whiteColor(), size: CGSizeMake(tabBar.frame.width/CGFloat(tabBar.items!.count), tabBar.frame.height), lineHeight: 3.0)
        
        let backItem = UIBarButtonItem()
        backItem.title = ""
        navigationItem.backBarButtonItem = backItem
        
        // Show settings in right nav bar item
        let settingsItem = UIBarButtonItem(image: UIImage(named: "14-gear"), style: .Plain, target: self, action: #selector(self.settingsButtonPressed(_:)))
        navigationItem.rightBarButtonItem = settingsItem
    }
    
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        registerObservers()
    }
    
    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        registerObservers()
    }
    
    private func registerObservers() {
        if (!observersRegistered) {
            observersRegistered = true
            OTRProtocolManager.sharedInstance().addObserver(self, forKeyPath: "numberOfConnectedProtocols", options: NSKeyValueObservingOptions.New, context: &observerContext)
            OTRProtocolManager.sharedInstance().addObserver(self, forKeyPath: "numberOfConnectingProtocols", options: NSKeyValueObservingOptions.New, context: &observerContext)
            if (selectedViewController == meViewController) {
                populateMeTabController()
            }
        }
    }
    
    override public func viewWillDisappear(animated: Bool) {
        if (observersRegistered) {
            observersRegistered = false
            OTRProtocolManager.sharedInstance().removeObserver(self, forKeyPath: "numberOfConnectedProtocols", context: &observerContext)
            OTRProtocolManager.sharedInstance().removeObserver(self, forKeyPath: "numberOfConnectingProtocols", context: &observerContext)
            super.viewWillDisappear(animated)
        }
    }
    
    override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard context == &observerContext else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
            return
        }
        if (selectedViewController == meViewController) {
            // Maybe we need to update this!
            populateMeTabController()
        }
    }
    
    override public var selectedViewController: UIViewController? {
        didSet {
            updateTitle()
        }
    }
    
    override public var selectedIndex: Int {
        didSet {
            updateTitle()
        }
    }
    
    private func updateTitle() {
        if (selectedViewController != nil) {
            let appName = NSBundle.mainBundle().infoDictionary![kCFBundleNameKey as String] as! String
            self.navigationItem.title = appName + " | " + selectedViewController!.tabBarItem.title!
            if (selectedViewController == meViewController) {
                populateMeTabController()
            }
        }
    }
    
    private func createSelectionIndicator(color: UIColor, size: CGSize, lineHeight: CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(CGRectMake(0, 0, size.width, lineHeight))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    @IBAction func settingsButtonPressed(sender: AnyObject) {
        self.chatsViewController?.settingsButtonPressed(sender)
    }
    
    private func populateMeTabController() {
        if (meViewController != nil) {
            var account:OTRAccount?
            let accounts = OTRAccountsManager.allAccountsAbleToAddBuddies()
            if (accounts.count > 0)
            {
                account = accounts[0] as? OTRAccount
            }
            self.meViewController!.account = account
        }
    }
}
