//
//  ZomBuddyInfoCell.swift
//  Zom
//
//  Created by N-Pex on 2016-05-17.
//
//

import UIKit

public class ZomBuddyInfoCell: OTRBuddyInfoCell {
    override public func setThread(thread: OTRThreadOwner!, withAccountName accountName: String!) {
        if (OTRAccountsManager.allAccountsAbleToAddBuddies().count < 2) {
            // Hide the account name if there is only one
            super.setThread(thread, withAccountName: "")
        } else {
            super.setThread(thread, withAccountName: accountName)
        }
        
        if let xmppBuddy = thread as? OTRXMPPBuddy {
            // Move account info to account and use identifier for full jid
            self.accountLabel.text = self.identifierLabel.text
            self.identifierLabel.text = xmppBuddy.username
        }
    }
    
    override public func updateConstraints() {
        let firstTime:Bool = !self.addedConstraints
        super.updateConstraints()
        if (firstTime) {
            // If we only have the name, remove all extra constraints and align that in the center Y position
            //
            if ((self.identifierLabel.text == "" || self.identifierLabel.text == nil) &&
                (self.accountLabel.text == "" || self.accountLabel.text == nil)) {
                var removeThese:[NSLayoutConstraint] = [NSLayoutConstraint]()
                for constraint:NSLayoutConstraint in self.constraints {
                    if ((constraint.firstItem as? NSObject != nil && constraint.firstItem as! NSObject == self.nameLabel) || (constraint.secondItem as? NSObject != nil && constraint.secondItem as! NSObject == self.nameLabel)) {
                        if (constraint.active && (constraint.firstAttribute == NSLayoutAttribute.Top || constraint.firstAttribute == NSLayoutAttribute.Bottom)) {
                            removeThese.append(constraint)
                        }
                    }
                }
                self.removeConstraints(removeThese)
                let c:NSLayoutConstraint = NSLayoutConstraint(item: self.nameLabel, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: self.nameLabel.superview, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0)
                self.addConstraint(c);
            }
        }
    }
}