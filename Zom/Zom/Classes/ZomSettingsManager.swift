//
//  ZomSettingsManager.swift
//  Zom
//
//  Created by N-Pex on 2016-05-26.
//
//

import ChatSecureCore
import AcknowList

@objc open class ZomSettingsManager: OTRSettingsManager, OTRSettingDelegate {
    @objc open var viewController:UIViewController?
    
    override open var settingsGroups: [OTRSettingsGroup] {
        get {
            var settingsGroups: [OTRSettingsGroup] = super.settingsGroups
            guard let groupOtherSettings = settingsGroups.last else { return [] }
            var settings:[Any] = []
            
            for index in stride(from: groupOtherSettings.settings.endIndex-1, to: groupOtherSettings.settings.startIndex, by: -1) {
                let setting = groupOtherSettings.settings[index]
                if (setting is OTRShareSetting || setting is OTRLanguageSetting) {
                    settings.append(setting)
                }
            }
            
            // Add the acknoledgements link
            let acknowledgements = OTRViewSetting(title: AcknowLocalization.localizedTitle(), description: "", viewControllerClass: AcknowListViewController.self)
            acknowledgements?.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
            acknowledgements?.delegate = self
            settings.append(acknowledgements!)
            
            if let other = OTRSettingsGroup(title: groupOtherSettings.title, settings: settings) {
                settingsGroups.removeLast()
                settingsGroups.append(other)
            }
            return settingsGroups
        }
    }
    
    public func otrSetting(_ setting: OTRSetting!, showDetailViewControllerClass viewControllerClass: AnyClass!) {
        
        let path = Bundle.main.path(forResource: "Pods-ZomPods-Zom-acknowledgements", ofType: "plist")
        let vcAcknowledgements = AcknowListViewController(acknowledgementsPlistPath: path)
        self.viewController?.navigationController?.pushViewController(vcAcknowledgements, animated: true)
    }
    
    public func refreshView() {
    }
}
