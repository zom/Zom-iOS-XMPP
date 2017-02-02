//
//  ZomInviteViewController.swift
//  Zom
//
//  Created by N-Pex on 2016-05-19.
//
//

import UIKit
import ChatSecureCore

public class ZomInviteViewController: OTRInviteViewController {
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // Don't show the upstream view
        self.view.hidden = true
        
        // Only show congrats for new account!
        var showCongratsView = true
        if let zomNavController = self.navigationController as? ZomOnboardingNavigationController {
            showCongratsView = (zomNavController.createdNewAccount == nil || zomNavController.createdNewAccount!)
        }
        
        if (showCongratsView) {
            let alreadyAdded = isShowingCongrats()
            if (!alreadyAdded) {
                self.title = ""
                let storyboard = UIStoryboard(name: "Onboarding", bundle: OTRAssets.resourcesBundle())
                let vc:ZomCongratsViewController = storyboard.instantiateViewControllerWithIdentifier("congrats") as! ZomCongratsViewController
                vc.account = self.account
                vc.restorationIdentifier = "congrats"
                self.addChildViewController(vc)
                vc.didMoveToParentViewController(self)
                vc.view.frame = self.view.frame
                self.view.addSubview(vc.view)
            }
            self.view.hidden = false
        } else {
            // TODO, jump straight to invite
            showInviteFriends()
        }
    }
    
    private func showInviteFriends() {
        super.skipPressed(self)
        /*
        if (!isShowingInviteFriends()) {
            let storyboard = UIStoryboard(name: "Onboarding", bundle: OTRAssets.resourcesBundle())
            let vc:ZomNewBuddyViewController = storyboard.instantiateViewControllerWithIdentifier("inviteFriends") as! ZomNewBuddyViewController
            vc.account = self.account
            self.addChildViewController(vc)
            vc.didMoveToParentViewController(self)
            vc.view.frame = self.view.frame
            if let appDelegate = UIApplication.sharedApplication().delegate as? OTRAppDelegate {
                vc.view.backgroundColor = appDelegate.theme.mainThemeColor
                vc.view.tintColor = UIColor.whiteColor()
                vc.addToolbar.barTintColor = appDelegate.theme.mainThemeColor
                vc.addToolbar.tintColor = UIColor.whiteColor()
                vc.imageView?.image = UIImage(named: "PitchInvite", inBundle: NSBundle.mainBundle(), compatibleWithTraitCollection: nil)
                vc.addFriendsLabel?.textColor = UIColor.whiteColor()
                vc.addFriendsLabel?.tintColor = UIColor.whiteColor()
                for barButtonItem in vc.addToolbar.items! {
                    if let button = barButtonItem.customView as? UIButton {
                        button.tintColor = UIColor.whiteColor()
                    }
                }
            }
            self.view.addSubview(vc.view)
            self.view.hidden = false
        }
        */
    }
    
    @IBAction func settingsButtonPressed(sender: AnyObject) {
        self.skipPressed(sender)
        if let appDelegate = UIApplication.sharedApplication().delegate as? OTRAppDelegate {
            if let conversationController = appDelegate.conversationViewController {
                
                // Open settings
                conversationController.settingsButtonPressed(self)
                
                // On iPads, make sure the the split view controller shows the settings pane
                if let navigationController = conversationController.navigationController {
                    if let opener = navigationController.parentViewController {
                        if let splitController = opener as? UISplitViewController{
                            if (!splitController.collapsed) {
                                let btn = splitController.displayModeButtonItem()
                                btn.target?.performSelector(btn.action, withObject: btn)
                            }
                        }
                    }
                }
            }
        }
    }
    
    public override func skipPressed(sender: AnyObject!) {
        /*if (isShowingCongrats()) {
            let congratsViewController = getCongratsViewController()
            congratsViewController!.view.removeFromSuperview()
            congratsViewController!.removeFromParentViewController()
            congratsViewController!.didMoveToParentViewController(nil)
            showInviteFriends()
        } else {*/
            super.skipPressed(sender)
        //}
    }
    
    private func isShowingCongrats() -> Bool {
        return getCongratsViewController() != nil
    }
    
    private func getCongratsViewController() -> ZomCongratsViewController? {
        for controller in self.childViewControllers {
            if (controller.isKindOfClass(ZomCongratsViewController.self)) {
                return controller as? ZomCongratsViewController
            }
        }
        return nil
    }
    
    private func isShowingInviteFriends() -> Bool {
        return getInviteFriendsViewController() != nil
    }
    
    private func getInviteFriendsViewController() -> ZomNewBuddyViewController? {
        for controller in self.childViewControllers {
            if (controller.isKindOfClass(ZomNewBuddyViewController.self)) {
                return controller as? ZomNewBuddyViewController
            }
        }
        return nil
    }
}
