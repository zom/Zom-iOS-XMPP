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

    convenience init() {
        self.init(nibName:nil, bundle:nil)
        //createTabs()
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
                } else {
                    newControllers.append(child)
                }
            }
            appDelegate.settingsViewController.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(named: "ic_me"), tag: 0)
            newControllers.append(appDelegate.settingsViewController)
            setViewControllers(newControllers, animated: false)
        }
        for item:UITabBarItem in self.tabBar.items! {
            item.selectedImage = item.image
            item.image = item.image!.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
        }
        let backItem = UIBarButtonItem()
        backItem.title = ""
        navigationItem.backBarButtonItem = backItem
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
        }
    }
}
