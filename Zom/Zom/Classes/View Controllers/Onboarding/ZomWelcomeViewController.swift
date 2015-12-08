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
    
    // MARK: - Navigation
    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender:sender)
        if segue.identifier == "pickLanguageSegue" {
            let settingsManager: OTRSettingsManager = OTRSettingsManager()
            let languageSetting: OTRListSetting = settingsManager.settingForOTRSettingKey(kOTRSettingKeyLanguage) as! OTRListSetting
            let selectLanguageVC = segue.destinationViewController as! ZomPickLanguageViewController
            selectLanguageVC.otrSetting = languageSetting
            selectLanguageVC.delegate = self
        }

    }

    public func dismissViewController(wasSaved: Bool) {
        if (wasSaved) {
            self.performSegueWithIdentifier("introSegue", sender: self)
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
}