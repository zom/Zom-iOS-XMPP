//
//  ZomMainTabbedViewController.swift
//  Zom
//
//  Created by N-Pex on 2016-11-14.
//
//

import Foundation

open class ZomMainTabbedViewController: UITabBarController, OTRComposeViewControllerDelegate {
    
    private var chatsViewController:ZomConversationViewController? = nil
    private var friendsViewController:ZomComposeViewController? = nil
    private var meViewController:ZomProfileViewController? = nil
    private var observerContext = 0
    private var observersRegistered:Bool = false
    private var barButtonSettings:UIBarButtonItem?
    private var barButtonAddChat:UIBarButtonItem?
    
    convenience init() {
        self.init(nibName:nil, bundle:nil)
    }
    
    open func createTabs() {
        if let appDelegate = UIApplication.shared.delegate as? OTRAppDelegate {
            
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
                    friendsViewController?.delegate = self
                    newControllers.append(friendsViewController!)
                } else if (child.restorationIdentifier == "me") {
                    meViewController = ZomProfileViewController(nibName: nil, bundle: nil)
                    meViewController?.tabBarItem = child.tabBarItem
                    //meViewController = child as? ZomProfileViewController
                    newControllers.append(meViewController!)
                }
                else {
                    newControllers.append(child)
                }
            }
            setViewControllers(newControllers, animated: false)
        }
        
        // Create bar button items
        self.barButtonSettings = UIBarButtonItem(image: UIImage(named: "14-gear"), style: .plain, target: self, action: #selector(self.settingsButtonPressed(_:)))
        self.barButtonAddChat = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.add, target: self, action: #selector(self.didPressAddButton(_:)))
        
        // Hide the tab item text, but don't null it (we use it to build the top title)
        for item:UITabBarItem in self.tabBar.items! {
            item.selectedImage = item.image
            item.image = item.image!.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
            
            item.setTitleTextAttributes([NSForegroundColorAttributeName:UIColor.clear,
                                         NSFontAttributeName:UIFont.systemFont(ofSize: 1)], for: .normal)
            item.imageInsets = UIEdgeInsets(top: 5, left: 0, bottom: -5, right: 0)
        }
        
        // Show current tab by a small white top border
        
        tabBar.selectionIndicatorImage = createSelectionIndicator(UIColor.white, size: CGSize(width:tabBar.frame.width/CGFloat(tabBar.items!.count),height:tabBar.frame.height), lineHeight: 3.0)
        
        let backItem = UIBarButtonItem()
        backItem.title = ""
        navigationItem.backBarButtonItem = backItem
        
        updateRightButtons()
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerObservers()
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        registerObservers()
    }
    
    private func registerObservers() {
        if (!observersRegistered) {
            observersRegistered = true
            OTRProtocolManager.sharedInstance().addObserver(self, forKeyPath: "numberOfConnectedProtocols", options: NSKeyValueObservingOptions.new, context: &observerContext)
            OTRProtocolManager.sharedInstance().addObserver(self, forKeyPath: "numberOfConnectingProtocols", options: NSKeyValueObservingOptions.new, context: &observerContext)
            if (selectedViewController == meViewController) {
                populateMeTabController()
            }
        }
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        if (observersRegistered) {
            observersRegistered = false
            OTRProtocolManager.sharedInstance().removeObserver(self, forKeyPath: "numberOfConnectedProtocols", context: &observerContext)
            OTRProtocolManager.sharedInstance().removeObserver(self, forKeyPath: "numberOfConnectingProtocols", context: &observerContext)
            super.viewWillDisappear(animated)
        }
    }
    
    
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &observerContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        if (selectedViewController == meViewController) {
            // Maybe we need to update this!
            populateMeTabController()
        }
    }
    
    override open var selectedViewController: UIViewController? {
        didSet {
            updateTitle()
            updateRightButtons()
        }
    }
    
    override open var selectedIndex: Int {
        didSet {
            updateTitle()
            updateRightButtons()
        }
    }
    
    private func updateTitle() {
        if (selectedViewController != nil) {
            let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
            self.navigationItem.title = appName + " | " + selectedViewController!.tabBarItem.title!
            if (selectedViewController == meViewController) {
                populateMeTabController()
            }
        }
    }
    
    private func updateRightButtons() {
        if let add = barButtonAddChat, let settings = barButtonSettings {
            if (selectedIndex == 0) {
                navigationItem.rightBarButtonItems = [settings, add]
            }
            else {
                navigationItem.rightBarButtonItems = [settings]
            }
        }
    }
    
    private func createSelectionIndicator(_ color: UIColor, size: CGSize, lineHeight: CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        
        UIRectFill(CGRect(x: 0, y: 0, width: size.width, height: lineHeight))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    @IBAction func settingsButtonPressed(_ sender: AnyObject) {
        self.chatsViewController?.settingsButtonPressed(sender)
    }
    
    @IBAction func didPressAddButton(_ sender: AnyObject) {
        if let appDelegate = UIApplication.shared.delegate as? ZomAppDelegate {
            appDelegate.splitViewCoordinator.conversationViewController(appDelegate.conversationViewController, didSelectCompose: self)
        }
    }
    
    private func populateMeTabController() {
        if (meViewController != nil) {
            if let appDelegate = UIApplication.shared.delegate as? ZomAppDelegate,let account = appDelegate.getDefaultAccount() {
                let otrKit = OTRProtocolManager.sharedInstance().encryptionManager.otrKit
                self.meViewController?.info = ZomProfileViewControllerInfo.createInfo(account, protocolString: account.protocolTypeString(), otrKit: otrKit, qrAction: self.meViewController!.qrAction!, shareAction: self.meViewController!.shareAction)
            }
        }
    }
    
    // MARK: - OTRComposeViewControllerDelegate
    open func controller(_ viewController: OTRComposeViewController, didSelectBuddies buddies: [String]?, accountId: String?, name: String?) {
        if (buddies?.count == 1) {
            guard let buds = buddies,
                let accountKey = accountId else {
                    return
            }
            
            if (buds.count == 1) {
                if let buddyKey = buds.first {
                    
                    var buddy:OTRBuddy? = nil
                    var account:OTRAccount? = nil
                    OTRDatabaseManager.sharedInstance().readOnlyDatabaseConnection?.read { (transaction) -> Void in
                        buddy = OTRBuddy.fetchObject(withUniqueID: buddyKey, transaction: transaction)
                        account = OTRAccount.fetchObject(withUniqueID: accountKey, transaction: transaction)
                    }
                    if let b = buddy, let a = account {
                        let profileVC = ZomProfileViewController(nibName: nil, bundle: nil)
                        let otrKit = OTRProtocolManager.sharedInstance().encryptionManager.otrKit
                        profileVC.info = ZomProfileViewControllerInfo.createInfo(b, accountName: a.username, protocolString: a.protocolTypeString(), otrKit: otrKit, qrAction: profileVC.qrAction!, shareAction: profileVC.shareAction, hasSession: false)
                        self.navigationController?.pushViewController(profileVC, animated: true)
                    }
                }
            }
        }
    }
    
    open func controllerDidCancel(_ viewController: OTRComposeViewController) {
        
    }
}
