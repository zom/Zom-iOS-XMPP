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
        navigationItem.title = NSLocalizedString("Choose a Friend", comment: "When selecting friend")
    }
    
    public override func canAddBuddies() -> Bool {
        if (parentViewController is UINavigationController) {
            // When opened from the "chats" tab, we don't want to show the "Add friend" button!
            return false
        }
        return true; // Always show add
    }
    
    public override func addBuddy(accountsAbleToAddBuddies: [OTRAccount]?) {
        if let accounts = accountsAbleToAddBuddies {
            if (accounts.count > 0)
            {
                ZomNewBuddyViewController.addBuddyToDefaultAccount(self.navigationController)
            }
        }
    }
}
