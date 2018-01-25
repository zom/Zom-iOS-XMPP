//
//  ZomMainTabbedViewController.swift
//  Zom
//
//  Created by N-Pex on 2016-11-14.
//
//

import Foundation

open class ZomMainTabbedViewController: UITabBarController, OTRComposeViewControllerDelegate, ZomMigrationInfoViewControllerDelegateProtocol, ZomAccountMigrationViewControllerAutoDelegateProtocol {
    
    private var chatsViewController:ZomConversationViewController? = nil
    private var friendsViewController:ZomComposeViewController? = nil
    private var meViewController:ZomProfileViewController? = nil
    private var observerContext = 0
    private var observersRegistered:Bool = false
    private var barButtonSettings:UIBarButtonItem?
    private var barButtonAddChat:UIBarButtonItem?
    private var chatsViewControllerTitleView:UIView?
    private var friendsViewControllerTitleView:UIView?
    private var automaticMigrationViewController:UIViewController?
    
    convenience init() {
        self.init(nibName:nil, bundle:nil)
    }
    
    @objc open func createTabs() {
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
            
            item.setTitleTextAttributes([NSAttributedStringKey.foregroundColor:UIColor.clear,
                                         NSAttributedStringKey.font:UIFont.systemFont(ofSize: 1)], for: .normal)
            item.imageInsets = UIEdgeInsets(top: 5, left: 0, bottom: -5, right: 0)
        }
        
        // Show current tab by a small white top border
        
        tabBar.selectionIndicatorImage = createSelectionIndicator(UIColor.white, size: CGSize(width:tabBar.frame.width/CGFloat(tabBar.items!.count),height:tabBar.frame.height), lineHeight: 3.0)
        
        let backItem = UIBarButtonItem()
        backItem.title = ""
        navigationItem.backBarButtonItem = backItem
        
        updateRightButtons()
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

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        registerObservers()
        updateTitle()
    }
    
    override open func viewDidDisappear(_ animated: Bool) {
        if (observersRegistered) {
            observersRegistered = false
            OTRProtocolManager.sharedInstance().removeObserver(self, forKeyPath: "numberOfConnectedProtocols", context: &observerContext)
            OTRProtocolManager.sharedInstance().removeObserver(self, forKeyPath: "numberOfConnectingProtocols", context: &observerContext)
            super.viewDidDisappear(animated)
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
            if selectedViewController == chatsViewController {
                // Get the title view from the child
                if chatsViewControllerTitleView == nil {
                    chatsViewControllerTitleView = chatsViewController?.navigationItem.titleView
                    if let titleView = chatsViewControllerTitleView {
                        for subview:UIView in titleView.subviews {
                            subview.tintColor = UIColor.white
                        }
                    }
                }
                self.navigationItem.titleView = chatsViewControllerTitleView
            } else if selectedViewController == friendsViewController {
                // Get the title view from the child
                if friendsViewControllerTitleView == nil {
                    friendsViewControllerTitleView = friendsViewController?.navigationItem.titleView
                    if let titleView = friendsViewControllerTitleView {
                        for subview:UIView in titleView.subviews {
                            subview.tintColor = UIColor.white
                        }
                    }
                }
                self.navigationItem.titleView = friendsViewControllerTitleView
            } else {
                self.navigationItem.titleView = nil
            }
        } else {
            self.navigationItem.titleView = nil
        }
    }
    
    private func updateRightButtons() {
        if let add = barButtonAddChat, let settings = barButtonSettings {
            if (selectedIndex == 0 || selectedIndex == 1) {
                navigationItem.rightBarButtonItems = [add]
            } else if (selectedIndex == 3) {
                navigationItem.rightBarButtonItems = [settings]
            } else {
                navigationItem.rightBarButtonItems = []
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
                let otrKit = OTRProtocolManager.encryptionManager.otrKit
                let info = ZomProfileViewControllerInfo.createInfo(account, protocolString: account.protocolTypeString(), otrKit: otrKit)
                self.meViewController?.setupWithInfo(info: info)
            }
        }
    }
    
    // MARK: - OTRComposeViewControllerDelegate
    open func controller(_ viewController: OTRComposeViewController, didSelectBuddies buddies: [String]?, accountId: String?, name: String?) {
        guard let buds = buddies else { return }
        if (buds.count == 1) {
            guard let accountKey = accountId else { return }
            
            if let buddyKey = buds.first {
                
                var buddy:OTRBuddy? = nil
                var account:OTRAccount? = nil
                OTRDatabaseManager.sharedInstance().readOnlyDatabaseConnection?.read { (transaction) -> Void in
                    buddy = OTRBuddy.fetchObject(withUniqueID: buddyKey, transaction: transaction)
                    account = OTRAccount.fetchObject(withUniqueID: accountKey, transaction: transaction)
                }
                if let b = buddy, let a = account {
                    let profileVC = ZomProfileViewController(nibName: nil, bundle: nil)
                    let otrKit = OTRProtocolManager.encryptionManager.otrKit
                    let info = ZomProfileViewControllerInfo.createInfo(b, accountName: a.username, protocolString: a.protocolTypeString(), otrKit: otrKit, hasSession: false, calledFromGroup: false, showAllFingerprints: false)
                    profileVC.setupWithInfo(info: info)
                    self.navigationController?.pushViewController(profileVC, animated: true)
                }
            }
        } else if (buds.count > 1) {
            let delegate = ZomAppDelegate.appDelegate.splitViewCoordinator
            viewController.navigationController?.popViewController(animated: true)
            delegate.controller(viewController, didSelectBuddies: buddies, accountId: accountId, name: name)
        }
    }
    
    open func controllerDidCancel(_ viewController: OTRComposeViewController) {
        
    }
    
    @IBAction func startAutoMigrationButtonPressed(_ sender: AnyObject) {
        startAutomaticMigration()
    }
    
    @IBAction func showMigrationInfoButtonPressed(_ sender: AnyObject) {
        performSegue(withIdentifier: "showMigrationInfo", sender: self)
    }
    
    public func startAutomaticMigration() {
        guard let migrationView = chatsViewController?.migrationInfoHeaderView as? ZomMigrationInfoHeaderView, let oldAccount = migrationView.account, self.automaticMigrationViewController == nil else { return }
        chatsViewController?.migrationStep = 1
        let migrateVC = OTRAccountMigrationViewController(oldAccount: oldAccount)
        migrateVC.showsCancelButton = true
        migrateVC.modalPresentationStyle = .none
        automaticMigrationViewController = UINavigationController(rootViewController: migrateVC)
        self.addChildViewController(automaticMigrationViewController!)
        migrateVC.viewDidLoad()
        if let zomMigrate = migrateVC as? ZomAccountMigrationViewController {
            zomMigrate.useAutoMode = true
            zomMigrate.autoDelegate = self
        }
        migrateVC.viewWillAppear(false)
        migrateVC.loginButtonPressed(self)
    }
    
    public func startAssistedMigration() {
        chatsViewController?.didPressStartMigrationButton(self)
    }

    @IBAction func migrationDoneButtonPressed(_ sender: AnyObject) {
        chatsViewController?.migrationStep = 0
        if let vc = self.automaticMigrationViewController {
            vc.removeFromParentViewController()
        }
        self.automaticMigrationViewController = nil
    }
    
    public func automaticMigrationDone(error: Error?) {
        chatsViewController?.migrationStep = 2
    }
    
    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let migrationViewController = segue.destination as? ZomMigrationInfoViewController {
            migrationViewController.delegate = self
        }
    }
}
