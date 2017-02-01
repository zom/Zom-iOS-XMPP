//
//  ZomCongratsViewController.swift
//  Zom
//
//  Created by N-Pex on 2017-01-24.
//
//

import UIKit
import ChatSecureCore
import MobileCoreServices

public class ZomCongratsViewController: UIViewController {

    @IBOutlet weak var avatarImageView:UIButton!
    public var account:OTRAccount?
    private var avatarPicker:OTRAttachmentPicker?
    private var viewHandler = OTRYapViewHandler(databaseConnection: OTRDatabaseManager.sharedInstance().readOnlyDatabaseConnection)

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.avatarImageView.layer.cornerRadius = CGRectGetWidth(self.avatarImageView.frame)/2;
        self.avatarImageView.userInteractionEnabled = true
        self.avatarImageView.clipsToBounds = true;
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.refreshAvatarImage(self.account)
        
        if let account = self.account {
            self.viewHandler.keyCollectionObserver.observe(account.uniqueId, collection: OTRAccount.collection())
        }
        
        
    }
    
    func refreshAvatarImage(account:OTRAccount?) {
        let defaultImage = { self.avatarImageView.setImage(UIImage(named: "onboarding_avatar", inBundle: OTRAssets.resourcesBundle(), compatibleWithTraitCollection: nil), forState: .Normal)}
        
        guard let account = self.account else {
            defaultImage()
            return
        }
        
        if let data = account.avatarData where data.length > 0 {
            self.avatarImageView.setImage(account.avatarImage(), forState: .Normal)
        } else {
            defaultImage()
        }
    }
    
    @IBAction func avatarButtonPressed(sender: AnyObject) {
        let picker = OTRAttachmentPicker(parentViewController: self, delegate: self)
        self.avatarPicker = picker
        picker.showAlertControllerWithCompletion(nil)
    }
    
    /** Uses the global readOnlyDatabaseConnection to refetch the account object and refresh the avatar image view with that new object*/
    private func refreshViews() {
        var account = self.account
        OTRDatabaseManager.sharedInstance().readOnlyDatabaseConnection .asyncReadWithBlock({ (transaction) in
            guard let key = self.account?.uniqueId else {
                return
            }
            
            account = OTRAccount .fetchObjectWithUniqueID(key, transaction: transaction)
            }) {
            self.account = account
            self.refreshAvatarImage(self.account)
        }
    }
}

extension ZomCongratsViewController: OTRYapViewHandlerDelegateProtocol {
    public func didReceiveChanges(handler: OTRYapViewHandler, key: String, collection: String) {
        if key == self.account?.uniqueId {
            self.refreshViews()
        }
    }
}

extension ZomCongratsViewController:OTRAttachmentPickerDelegate {
    public func attachmentPicker(attachmentPicker: OTRAttachmentPicker!, gotVideoURL videoURL: NSURL!) {
    }
    
    public func attachmentPicker(attachmentPicker: OTRAttachmentPicker!, gotPhoto photo: UIImage!, withInfo info: [NSObject : AnyObject]!) {
        
        guard let account = self.account else {
            return
        }
        
        if (OTRProtocolManager.sharedInstance().protocolForAccount(account) != nil) {
            if let xmppManager = OTRProtocolManager.sharedInstance().protocolForAccount(account) as? OTRXMPPManager {
                xmppManager.setAvatar(photo, completion: { (success) in
                    //We updated the avatar
                })
            }
        }
    }
    
    public func attachmentPicker(attachmentPicker: OTRAttachmentPicker!, preferredMediaTypesForSource source: UIImagePickerControllerSourceType) -> [String]! {
        return [kUTTypeImage as String]
    }
}
