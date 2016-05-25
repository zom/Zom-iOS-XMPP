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
        self.title = ""
        let storyboard = UIStoryboard(name: "Onboarding", bundle: OTRAssets.resourcesBundle())
        let vc = storyboard.instantiateViewControllerWithIdentifier("congrats")
        self.addChildViewController(vc)
        vc.view.frame = self.view.frame
        self.view.addSubview(vc.view)
    }
    
    @IBAction func settingsButtonPressed(sender: AnyObject) {
        self.skipPressed(sender)
    }
    
    override public func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        if let appDelegate = UIApplication.sharedApplication().delegate as? OTRAppDelegate {
            appDelegate.conversationViewController?.settingsButtonPressed(self)
        }
    }
}