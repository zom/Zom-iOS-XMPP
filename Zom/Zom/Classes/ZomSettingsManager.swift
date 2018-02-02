//
//  ZomSettingsManager.swift
//  Zom
//
//  Created by N-Pex on 2016-05-26.
//
//

import ChatSecureCore

@objc open class ZomSettingsManager: OTRSettingsManager {
    @objc open var viewController:UIViewController?
    
    override open var settingsGroups: [OTRSettingsGroup] {
        get {
            var settingsGroups: [OTRSettingsGroup] = super.settingsGroups
            guard let groupOtherSettings = settingsGroups.filter({ (group) -> Bool in
                return group.title == OTHER_STRING()
            }).first,
                let indexOtherSettings = settingsGroups.index(of: groupOtherSettings)
                else { return settingsGroups }
            var settings:[OTRSetting] = []
            
            for setting in groupOtherSettings.settings.reversed() {
                if (setting is OTRShareSetting || setting is OTRLanguageSetting) {
                    settings.append(setting)
                }
            }
            
            let other = OTRSettingsGroup(title: groupOtherSettings.title, settings: settings)
            settingsGroups.remove(at: indexOtherSettings)
            settingsGroups.insert(other, at: indexOtherSettings)
            return settingsGroups
        }
    }
    
    public func refreshView() {
    }
}
