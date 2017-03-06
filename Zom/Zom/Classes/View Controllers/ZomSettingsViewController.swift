//
//  ZomSettingsViewController.swift
//  Zom
//
//  Created by N-Pex on 2016-06-16.
//
//

import UIKit
import ChatSecureCore
import ObjectiveC

// Declare a global var to produce a unique address as the assoc object handle
var AssociatedObjectHandle: UInt8 = 0

extension OTRSettingsViewController {
    private static var swizzle: () {
        ZomUtil.swizzle(self, originalSelector: #selector(OTRSettingsViewController.present), swizzledSelector:#selector(OTRSettingsViewController.zom_presentViewController(_:animated:completion:)))
        ZomUtil.swizzle(self, originalSelector: #selector(OTRSettingsViewController.logoutAccount(_:sender:)), swizzledSelector: #selector(OTRSettingsViewController.zom_logoutAccount(_:sender:)))

    }
    
    open override class func initialize() {
        
        // make sure this isn't a subclass
        if self !== OTRSettingsViewController.self {
            return
        }
        
        OTRSettingsViewController.swizzle
    }
    
    var accountForInformation:OTRAccount? {
        get {
            return objc_getAssociatedObject(self, &AssociatedObjectHandle) as? OTRAccount ?? nil
        }
        set {
            objc_setAssociatedObject(self, &AssociatedObjectHandle, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func zom_logoutAccount(_ account:OTRAccount?, sender:AnyObject?) {
        self.accountForInformation = account
        self.zom_logoutAccount(account, sender: sender)
    }
    
    func zom_presentViewController(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?) {
        if (viewControllerToPresent is UIAlertController) {
            // Currently pretty ugly way to find the alert for "logout account", TODO: change this!
            //
            let alert:UIAlertController = viewControllerToPresent as! UIAlertController
            if (alert.title == nil) {
                let infoAction = UIAlertAction(title: NSLocalizedString("Show information", comment: "Account option to show more information"), style: UIAlertActionStyle.default, handler: { (action) in
                    if (self.accountForInformation != nil) {
                        guard let login = OTRBaseLoginViewController(for: self.accountForInformation) else {
                            return
                        }
                        object_setClass(login, ZomBaseLoginViewController.self)
                        login.showsCancelButton = false
                        (login as! ZomBaseLoginViewController).onlyShowInfo = true
                        let nav = UINavigationController(rootViewController: login)
                        nav.modalPresentationStyle = UIModalPresentationStyle.formSheet
                        self.present(nav, animated: true, completion: nil)
                    }
                })
                alert.addAction(infoAction)
                if let appDelegate = UIApplication.shared.delegate as? ZomAppDelegate {
                    if (self.accountForInformation?.uniqueId != appDelegate.getDefaultAccount()?.uniqueId) {
                        let setDefaultAction = UIAlertAction(title: NSLocalizedString("Set as default", comment: "Account option to set as default"), style: UIAlertActionStyle.default, handler: { (action) in
                            if (self.accountForInformation != nil) {
                                if let appDelegate = UIApplication.shared.delegate as? ZomAppDelegate {
                                    appDelegate.setDefaultAccount(self.accountForInformation)
                                }
                            }
                        })
                        alert.addAction(setDefaultAction)
                    }
                }
            }
        }
        self.zom_presentViewController(viewControllerToPresent, animated: flag, completion: completion)
    }
}
