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
    public var account:OTRAccount? {
        didSet {
            guard let acct = account else {
                return;
            }
            self.viewHandler?.keyCollectionObserver.observe(acct.uniqueId, collection: OTRAccount.collection())
        }
    }
    private var avatarPicker:OTRAttachmentPicker?
    private var viewHandler:OTRYapViewHandler?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        if let connection = OTRDatabaseManager.sharedInstance().longLivedReadOnlyConnection {
            self.viewHandler = OTRYapViewHandler(databaseConnection: connection, databaseChangeNotificationName: DatabaseNotificationName.LongLivedTransactionChanges)
            if let accountKey = account?.uniqueId {
                self.viewHandler?.keyCollectionObserver.observe(accountKey, collection: OTRAccount.collection())
            }
            
            self.viewHandler?.delegate = self
        }
        
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.avatarImageView.layer.cornerRadius = CGRectGetWidth(self.avatarImageView.frame)/2;
        self.avatarImageView.userInteractionEnabled = true
        self.avatarImageView.clipsToBounds = true;
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.refreshAvatarImage(self.account)
    }
    
    func refreshAvatarImage(account:OTRAccount?) {
        
        if let account = self.account, let data = account.avatarData where data.length > 0 {
            self.avatarImageView.setImage(account.avatarImage(), forState: .Normal)
        } else {
            self.avatarImageView.setImage(UIImage(named: "onboarding_avatar", inBundle: OTRAssets.resourcesBundle(), compatibleWithTraitCollection: nil), forState: .Normal)
        }
    }
    
    @IBAction func avatarButtonPressed(sender: AnyObject) {
        let picker = OTRAttachmentPicker(parentViewController: self, delegate: self)
        self.avatarPicker = picker
        let view = sender as? UIView
        picker.showAlertControllerFromSourceView(view, withCompletion: nil)
    }
    
    /** Uses the global readOnlyDatabaseConnection to refetch the account object and refresh the avatar image view with that new object*/
    private func refreshViews() {
        guard let key = self.account?.uniqueId else {
            self.refreshAvatarImage(nil)
            return
        }
        var account:OTRAccount? = nil
        OTRDatabaseManager.sharedInstance().longLivedReadOnlyConnection?.asyncReadWithBlock({ (transaction) in
            account = OTRAccount .fetchObjectWithUniqueID(key, transaction: transaction)
            }, completionQueue: dispatch_get_main_queue()) {
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
