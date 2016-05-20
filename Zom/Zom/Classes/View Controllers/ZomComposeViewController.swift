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
    
    public static var openInGroupMode:Bool = false
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        if (ZomComposeViewController.openInGroupMode) {
            ZomComposeViewController.openInGroupMode = false
            self.switchSelectionMode()
        }
    }
    
    public override func addBuddy(accountsAbleToAddBuddies: [OTRAccount]?) {
        if let accounts = accountsAbleToAddBuddies {
            if (accounts.count > 0)
            {
                let storyboard = UIStoryboard(name: "AddBuddy", bundle: nil)
                var vc:UIViewController? = nil
                if (accounts.count == 1) {
                    vc = storyboard.instantiateViewControllerWithIdentifier("addNewBuddy")
                    (vc as! ZomAddBuddyViewController).account = accounts[0]
                    self.navigationController?.pushViewController(vc!, animated: true)
                } else {
                    vc = storyboard.instantiateInitialViewController()
                    self.navigationController?.presentViewController(vc!, animated: true, completion: nil)
                }
            }
        }

    }
}