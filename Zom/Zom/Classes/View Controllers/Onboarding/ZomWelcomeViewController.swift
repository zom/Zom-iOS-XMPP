//
//  ZomWelcomeViewController.swift
//  Zom
//
//  Created by N-Pex on 2015-11-10.
//
//

import UIKit
import ChatSecureCore

open class ZomWelcomeViewController: OTRWelcomeViewController, ZomPickLanguageViewControllerDelegate, UINavigationControllerDelegate {
    
    var languagePickNavController:UINavigationController? = nil
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.delegate = self
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // If we already have an account, this is "Add account" and not initial onboarding. So, we need to allow the user to cancel out of this flow. Also, don't show this first welcome screen.
        var hasAccounts:Bool = false
        OTRDatabaseManager.sharedInstance().readOnlyDatabaseConnection?.read { (transaction) in
            if (transaction.numberOfKeys(inCollection: OTRAccount.collection()) > 0) {
                hasAccounts = true
            }
        }
        if (hasAccounts) {
            let navigationController = self.navigationController
            _ = navigationController?.popViewController(animated: false)
            let vc:ZomIntroViewController = self.storyboard?.instantiateViewController(withIdentifier: "introViewController") as! ZomIntroViewController
            vc.showCancelButton = true
            navigationController?.pushViewController(vc, animated: false)
        }
    }
    
    // MARK: - Navigation
    override open func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender:sender)
        if segue.identifier == "pickLanguageSegue" {
            let settingsManager: OTRSettingsManager = OTRSettingsManager()
            let languageSetting = settingsManager.setting(forOTRSettingKey: kOTRSettingKeyLanguage)
            let selectLanguageVC = segue.destination as! ZomPickLanguageViewController
            selectLanguageVC.otrSetting = languageSetting
            selectLanguageVC.delegate = self
        }

    }

    open func dismissViewController(_ wasSaved: Bool) {
        if (wasSaved) {
            let sb = UIStoryboard(name: "Onboarding", bundle: OTRAssets.resourcesBundle())
            // Recreate the storyboard with the new language
            let vc:UINavigationController = sb.instantiateInitialViewController() as! UINavigationController
            vc.modalPresentationStyle = UIModalPresentationStyle.formSheet;
            let presenting = self.navigationController!.presentingViewController
            self.navigationController?.dismiss(animated: false, completion: nil)
            presenting?.present(vc, animated: true, completion: nil)
            vc.viewControllers.first!.performSegue(withIdentifier: "introSegue", sender: self)
        } else {
            _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    open func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if (viewController.isKind(of: ZomIntroViewController.self)) {
            var didChangeArray:Bool = false
            var vcArray = self.navigationController?.viewControllers
            
            for index in stride(from: vcArray!.count - 1, to: 0, by: -1) {
                let vc:UIViewController = vcArray![index]
                if (vc is ZomPickLanguageViewController) {
                    didChangeArray = true
                    vcArray!.remove(at: index)
                }
            }
            if (didChangeArray) {
                self.navigationController?.setViewControllers(vcArray!, animated: false)
            }
        }
    }
    
    open func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        print("WillShow")
    }
}
