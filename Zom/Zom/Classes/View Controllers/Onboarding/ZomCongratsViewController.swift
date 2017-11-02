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

open class ZomCongratsViewController: UIViewController {

    @IBOutlet weak var avatarImageView:UIButton!
    open var account:OTRAccount? {
        didSet {
            guard let acct = account else {
                return;
            }
            self.viewHandler?.keyCollectionObserver.observe(acct.uniqueId, collection: OTRAccount.collection)
        }
    }
    private var avatarPicker:OTRAttachmentPicker?
    private var viewHandler:OTRYapViewHandler?
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        if let connection = OTRDatabaseManager.sharedInstance().longLivedReadOnlyConnection {
            self.viewHandler = OTRYapViewHandler(databaseConnection: connection, databaseChangeNotificationName: DatabaseNotificationName.LongLivedTransactionChanges)
            if let accountKey = account?.uniqueId {
                self.viewHandler?.keyCollectionObserver.observe(accountKey, collection: OTRAccount.collection)
            }
            
            self.viewHandler?.delegate = self
        }
        
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.avatarImageView.layer.cornerRadius = self.avatarImageView.frame.width/2;
        self.avatarImageView.isUserInteractionEnabled = true
        self.avatarImageView.clipsToBounds = true;
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.refreshAvatarImage(account: self.account)
    }
    
    func refreshAvatarImage(account:OTRAccount?) {
        
        if let account = self.account, let data = account.avatarData, data.count > 0 {
            self.avatarImageView.setImage(account.avatarImage(), for: .normal)
        } else {
            self.avatarImageView.setImage(UIImage(named: "onboarding_avatar", in: OTRAssets.resourcesBundle, compatibleWith: nil), for: .normal)
        }
    }
    
    @IBAction func avatarButtonPressed(_ sender: AnyObject) {
        let picker = OTRAttachmentPicker(parentViewController: self, delegate: self)
        self.avatarPicker = picker
        if let view = sender as? UIView {
            picker.showAlertController(fromSourceView: view, withCompletion: nil)
        }
    }
    
    /** Uses the global readOnlyDatabaseConnection to refetch the account object and refresh the avatar image view with that new object*/
    fileprivate func refreshViews() {
        guard let key = self.account?.uniqueId else {
            self.refreshAvatarImage(account: nil)
            return
        }
        var account:OTRAccount? = nil
        OTRDatabaseManager.sharedInstance().longLivedReadOnlyConnection?.asyncRead({ (transaction) in
            account = OTRAccount.fetchObject(withUniqueID:key, transaction: transaction)
            }, completionQueue: DispatchQueue.main) {
                self.account = account
                self.refreshAvatarImage(account: self.account)
        }
    }
}

extension ZomCongratsViewController: OTRYapViewHandlerDelegateProtocol {
    public func didReceiveChanges(_ handler: OTRYapViewHandler, key: String, collection: String) {
        if key == self.account?.uniqueId {
            self.refreshViews()
        }
    }
}

extension ZomCongratsViewController:UIPopoverPresentationControllerDelegate {
    public func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
        if popoverPresentationController.sourceView == nil {
            popoverPresentationController.sourceView = self.avatarImageView
        }
    }
}

extension ZomCongratsViewController:OTRAttachmentPickerDelegate {

    public func attachmentPicker(_ attachmentPicker: OTRAttachmentPicker, gotVideoURL videoURL: URL) {
        
    }
    
    public func attachmentPicker(_ attachmentPicker: OTRAttachmentPicker, gotPhoto photo: UIImage, withInfo info: [AnyHashable : Any]) {
        
        guard let account = self.account else {
            return
        }
        
        if (OTRProtocolManager.sharedInstance().protocol(for: account) != nil) {
            if let xmppManager = OTRProtocolManager.sharedInstance().protocol(for: account) as? OTRXMPPManager {
                xmppManager.setAvatar(photo, completion: { (success) in
                    //We updated the avatar
                })
            }
        }
    }
    
    public func attachmentPicker(_ attachmentPicker: OTRAttachmentPicker, preferredMediaTypesFor source: UIImagePickerControllerSourceType) -> [String] {
        return [kUTTypeImage as String]
    }
}
