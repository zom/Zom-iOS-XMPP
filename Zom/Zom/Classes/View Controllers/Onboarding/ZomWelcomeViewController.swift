//
//  ZomWelcomeViewController.swift
//  Zom
//
//  Created by N-Pex on 2015-11-10.
//
//

import UIKit
import ChatSecureCore

public class ZomWelcomeViewController: OTRWelcomeViewController, OTRSettingDelegate {
    
    // MARK: - Navigation
    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender:sender)
        if segue.identifier == "selectLanguageSegue" {
            let navController: UINavigationController = segue.destinationViewController as! UINavigationController
            let settingsManager: OTRSettingsManager = OTRSettingsManager()
            let languageSetting: OTRListSetting = settingsManager.settingForOTRSettingKey(kOTRSettingKeyLanguage) as! OTRListSetting
            let selectLanguageVC = OTRLanguageListSettingViewController()
            selectLanguageVC.otrSetting = languageSetting
            languageSetting.delegate = self;
            navController.showViewController(selectLanguageVC, sender: navController)
        }
    }

    // MARK: OTRSettingDelegate
    public func refreshView() {
        self.performSegueWithIdentifier("introSegue", sender: self)
    }
    
    public func otrSetting(setting: OTRSetting!, showDetailViewControllerClass viewControllerClass: AnyClass!) {
    }
}