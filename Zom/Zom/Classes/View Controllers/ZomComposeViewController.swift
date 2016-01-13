//
//  ZomComposeViewController.swift
//  Zom
//
//  Created by N-Pex on 2015-11-24.
//
//

import UIKit
import ChatSecureCore

public class ZomComposeViewController: OTRComposeViewController {
    
    public override func addBuddy(accountsAbleToAddBuddies: [AnyObject]!) {
        if (accountsAbleToAddBuddies.count > 0)
        {
            let storyboard = UIStoryboard(name: "AddBuddy", bundle: nil)
            var vc:UIViewController? = nil
            if (accountsAbleToAddBuddies.count == 1) {
                vc = storyboard.instantiateViewControllerWithIdentifier("addNewBuddy")
                (vc as! ZomAddBuddyViewController).account = accountsAbleToAddBuddies[0] as? OTRAccount
                self.navigationController?.pushViewController(vc!, animated: true)
            } else {
                vc = storyboard.instantiateInitialViewController()
                self.navigationController?.presentViewController(vc!, animated: true, completion: nil)
            }
        }

    }
}