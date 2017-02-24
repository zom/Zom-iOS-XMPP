//
//  ZomBuddyInfoCell.swift
//  Zom
//
//  Created by N-Pex on 2016-05-17.
//
//

import UIKit

open class ZomBuddyInfoCell: OTRBuddyInfoCell {
    
    override open func updateConstraints() {
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
                        if (constraint.isActive && (constraint.firstAttribute == NSLayoutAttribute.top || constraint.firstAttribute == NSLayoutAttribute.bottom)) {
                            removeThese.append(constraint)
                        }
                    }
                }
                self.removeConstraints(removeThese)
                let c:NSLayoutConstraint = NSLayoutConstraint(item: self.nameLabel, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: self.nameLabel.superview, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0)
                self.addConstraint(c);
            }
        }
    }
}
