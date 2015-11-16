//
//  ZomIntroViewController.swift
//  Zom
//
//  Created by N-Pex on 2015-11-11.
//
//

import UIKit
import ChatSecureCore

public class ZomIntroViewController: OTRWelcomeViewController {
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
        self.completionBlock = { (account, error) -> Void in
            if (error == nil) {
                if (account != nil) {
                    OTRInviteViewController.showInviteFromVC(self, withAccount: account)
                }
            }
        }
    }
    
    // MARK: - Navigation
    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "useExistingAccountSegue" {
            let vc: OTRExistingAccountViewController = segue.destinationViewController as! OTRExistingAccountViewController
            vc.completionBlock = self.completionBlock
        }
        super.prepareForSegue(segue, sender:sender)
    }
}