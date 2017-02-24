//
//  ZomWelcomeViewController.swift
//  Zom
//
//  Created by N-Pex on 2015-11-10.
//
//

import UIKit
import ChatSecureCore

public class ZomWelcomeViewController: OTRWelcomeViewController, ZomPickLanguageViewControllerDelegate, UINavigationControllerDelegate {
    
    var languagePickNavController:UINavigationController? = nil
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.delegate = self
    }
    
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // If we already have an account, this is "Add account" and not initial onboarding. So, we need to allow the user to cancel out of this flow. Also, don't show this first welcome screen.
        var hasAccounts:Bool = false
        OTRDatabaseManager.sharedInstance().readOnlyDatabaseConnection?.readWithBlock { (transaction) in
            if (transaction.numberOfKeysInCollection(OTRAccount.collection()) > 0) {
                hasAccounts = true
            }
        }
        if (hasAccounts) {
            let navigationController = self.navigationController
            navigationController?.popViewControllerAnimated(false)
            let vc:ZomIntroViewController = self.storyboard?.instantiateViewControllerWithIdentifier("introViewController") as! ZomIntroViewController
            vc.showCancelButton = true
            navigationController?.pushViewController(vc, animated: false)
        }
    }
    
    // MARK: - Navigation
    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender:sender)
        if segue.identifier == "pickLanguageSegue" {
            let settingsManager: OTRSettingsManager = OTRSettingsManager()
            let languageSetting = settingsManager.settingForOTRSettingKey(kOTRSettingKeyLanguage)
            let selectLanguageVC = segue.destinationViewController as! ZomPickLanguageViewController
            selectLanguageVC.otrSetting = languageSetting
            selectLanguageVC.delegate = self
        }

    }

    public func dismissViewController(wasSaved: Bool) {
        if (wasSaved) {
            if let sb:UIStoryboard = UIStoryboard(name: "Onboarding", bundle: OTRAssets.resourcesBundle()) {
                // Recreate the storyboard with the new language
                let vc:UINavigationController = sb.instantiateInitialViewController() as! UINavigationController
                vc.modalPresentationStyle = UIModalPresentationStyle.FormSheet;
                let presenting = self.navigationController!.presentingViewController
                self.navigationController?.dismissViewControllerAnimated(false, completion: nil)
                presenting?.presentViewController(vc, animated: true, completion: nil)
                vc.viewControllers.first!.performSegueWithIdentifier("introSegue", sender: self)
            }
            else {
                self.performSegueWithIdentifier("introSegue", sender: self)
            }
        } else {
            self.navigationController?.popViewControllerAnimated(true)
        }
    }
    
    public func navigationController(navigationController: UINavigationController, didShowViewController viewController: UIViewController, animated: Bool) {
        if (viewController.isKindOfClass(ZomIntroViewController)) {
            var didChangeArray:Bool = false
            var vcArray = self.navigationController?.viewControllers
            for index in (vcArray!.count - 1).stride(through: 0, by: -1) {
                let vc:UIViewController = vcArray![index]
                if (vc.isKindOfClass(ZomPickLanguageViewController)) {
                    didChangeArray = true
                    vcArray!.removeAtIndex(index)
                }
            }
            if (didChangeArray) {
                self.navigationController?.setViewControllers(vcArray!, animated: false)
            }
        }
    }
    
    public func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
        print("WillShow")
    }
}
