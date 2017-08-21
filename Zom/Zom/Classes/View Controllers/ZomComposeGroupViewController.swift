//
//  ZomComposeGroupViewController.swift
//  Zom
//
//  Created by N-Pex on 2017-08-16.
//
//

import UIKit
import ChatSecureCore
import QRCodeReaderViewController

open class ZomComposeGroupViewController: OTRComposeGroupViewController, QRCodeReaderDelegate {
    
    var account:OTRAccount?
    var qrDelegate:OTRQRCodeReaderDelegate?
    
    open override func viewDidLoad() {
        if let appDelegate = ZomAppDelegate.appDelegate as? ZomAppDelegate {
            account = appDelegate.getDefaultAccount()
        }
        if let accountUniqueId = self.account?.uniqueId {
            super.filterOnAccount(accountUniqueId: accountUniqueId)
        }
        super.viewDidLoad()
    }

    override open func updateFiltering() {
        // Do nothing
    }
    
    @IBAction func didPressQRButton(sender: AnyObject) {
        //if !QRCodeReader.supportsMetadataObjectTypes([AVMetadataObjectTypeQRCode]) {
        //    return
        //}
        if let account = self.account {
            qrDelegate = OTRQRCodeReaderDelegate(account: account)
            qrDelegate?.completion = {() -> Void
                in
                self.dismiss(animated: true, completion: nil)
            }
            let reader = QRCodeReaderViewController(cancelButtonTitle: CANCEL_STRING())
            reader.delegate = qrDelegate
            reader.modalPresentationStyle = UIModalPresentationStyle.formSheet
            let nav = UINavigationController(rootViewController: reader)
            present(nav, animated: true, completion: nil)
        }
    }
}
