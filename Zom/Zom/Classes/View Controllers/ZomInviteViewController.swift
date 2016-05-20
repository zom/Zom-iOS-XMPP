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
    public override func qrButtonPressed(sender: AnyObject!) {
        let storyboard = UIStoryboard(name: "AddBuddy", bundle: nil)
        if let vc:ZomAddBuddyViewController? = storyboard.instantiateViewControllerWithIdentifier("addNewBuddy") as? ZomAddBuddyViewController {
            vc!.account = super.account
            vc!.showQRTab()
            self.navigationController?.pushViewController(vc!, animated: true)
        }
    }
}