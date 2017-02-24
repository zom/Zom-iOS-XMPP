//
//  ZomIntroViewController.swift
//  Zom
//
//  Created by N-Pex on 2015-11-11.
//
//

import UIKit
import ChatSecureCore

open class ZomIntroViewController: OTRWelcomeViewController {
    
    open var showCancelButton:Bool = false
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
        if (showCancelButton) {
            self.navigationController!.setNavigationBarHidden(false, animated: animated)
            self.navigationItem.setHidesBackButton(true, animated: false)
        }
    }
    
    // MARK: - Navigation
    override open func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let login = segue.destination as? ZomBaseLoginViewController {
            if segue.identifier == "useExistingAccountSegue" {
                login.form = OTRXLFormCreator.form(for: OTRAccountType.jabber, createAccount: false)
                login.loginHandler = OTRXMPPLoginHandler()
                if let zomNavController = self.navigationController as? ZomOnboardingNavigationController {
                    zomNavController.createdNewAccount = false
                }
            } else {
                login.createNewAccount = true
                if let zomNavController = self.navigationController as? ZomOnboardingNavigationController {
                    zomNavController.createdNewAccount = true
                }
            }
        }
        super.prepare(for: segue, sender:sender)
    }
    
    @IBAction func cancelButtonPressed(_ sender: AnyObject) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
}
