//
//  ZomCongratsViewController.swift
//  Zom
//
//  Created by N-Pex on 2017-01-24.
//
//

import UIKit
import ChatSecureCore

public class ZomCongratsViewController: UIViewController, OTRAttachmentPickerDelegate {

    @IBOutlet weak var avatarImageView:UIButton!
    public var account:OTRAccount!
    private var avatarPicker:OTRAttachmentPicker?

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.avatarImageView.layer.cornerRadius = CGRectGetWidth(self.avatarImageView.frame)/2;
        self.avatarImageView.userInteractionEnabled = true
        self.avatarImageView.clipsToBounds = true;
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if (account.avatarData == nil || account.avatarData.length == 0) {
            self.avatarImageView.setImage(UIImage(named: "onboarding_avatar", inBundle: OTRAssets.resourcesBundle(), compatibleWithTraitCollection: nil), forState: .Normal)
        } else {
            self.avatarImageView.setImage(account.avatarImage(), forState: .Normal)
        }
    }
    
    @IBAction func avatarButtonPressed(sender: AnyObject) {
        avatarPicker = OTRAttachmentPicker(parentViewController: self, delegate: self)
        avatarPicker!.showAlertControllerWithCompletion(nil)
    }
    
    public func attachmentPicker(attachmentPicker: OTRAttachmentPicker!, gotVideoURL videoURL: NSURL!) {
    }
    
    public func attachmentPicker(attachmentPicker: OTRAttachmentPicker!, gotPhoto photo: UIImage!, withInfo info: [NSObject : AnyObject]!) {
        self.account.avatarData = UIImagePNGRepresentation(photo)
    }
}
