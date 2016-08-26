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
    public override class func initialize() {
        struct Static {
            static var token: dispatch_once_t = 0
        }
        
        // make sure this isn't a subclass
        if self !== OTRSettingsViewController.self {
            return
        }
        
        dispatch_once(&Static.token) {
            ZomUtil.swizzle(self, originalSelector: #selector(OTRSettingsViewController.presentViewController(_:animated:completion:)), swizzledSelector:#selector(OTRSettingsViewController.zom_presentViewController(_:animated:completion:)))
            ZomUtil.swizzle(self, originalSelector: #selector(OTRSettingsViewController.logoutAccount(_:sender:)), swizzledSelector: #selector(OTRSettingsViewController.zom_logoutAccount(_:sender:)))
        }
    }
    
    var accountForInformation:OTRAccount? {
        get {
            return objc_getAssociatedObject(self, &AssociatedObjectHandle) as? OTRAccount ?? nil
        }
        set {
            objc_setAssociatedObject(self, &AssociatedObjectHandle, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func zom_logoutAccount(account:OTRAccount?, sender:AnyObject?) {
        self.accountForInformation = account
        self.zom_logoutAccount(account, sender: sender)
    }
    
    func zom_presentViewController(viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?) {
        if (viewControllerToPresent.isKindOfClass(UIAlertController.self)) {
            // Currently pretty ugly way to find the alert for "logout account", TODO: change this!
            //
            let alert:UIAlertController = viewControllerToPresent as! UIAlertController
            if (alert.title == nil) {
                let infoAction = UIAlertAction(title: "Show information", style: UIAlertActionStyle.Default, handler: { (action) in
                    if (self.accountForInformation != nil) {
                        let login = OTRBaseLoginViewController(forAccount: self.accountForInformation)
                        object_setClass(login, ZomBaseLoginViewController.self)
                        login.showsCancelButton = false
                        (login as! ZomBaseLoginViewController).onlyShowInfo = true
                        let nav = UINavigationController(rootViewController: login)
                        nav.modalPresentationStyle = UIModalPresentationStyle.FormSheet
                        self.presentViewController(nav, animated: true, completion: nil)
                    }
                })
                alert.addAction(infoAction)
            }
        }
        self.zom_presentViewController(viewControllerToPresent, animated: flag, completion: completion)
    }
}