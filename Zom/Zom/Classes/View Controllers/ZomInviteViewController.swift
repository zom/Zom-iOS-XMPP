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
        } else {
            // TODO, jump straight to invite
        }
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
        if (isShowingCongrats()) {
            let congratsViewController = getCongratsViewController()
            congratsViewController!.view.removeFromSuperview()
            congratsViewController!.removeFromParentViewController()
            congratsViewController!.didMoveToParentViewController(nil)
        } else {
            super.skipPressed(sender)
        }
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
}
