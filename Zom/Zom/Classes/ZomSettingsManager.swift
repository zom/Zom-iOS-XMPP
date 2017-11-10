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
            guard let groupOtherSettings = settingsGroups.last else { return [] }
            var settings:[Any] = []
            
            for index in stride(from: groupOtherSettings.settings.endIndex-1, to: groupOtherSettings.settings.startIndex, by: -1) {
                let setting = groupOtherSettings.settings[index]
                if (setting is OTRShareSetting || setting is OTRLanguageSetting) {
                    settings.append(setting)
                }
            }
            
            if let other = OTRSettingsGroup(title: groupOtherSettings.title, settings: settings) {
                settingsGroups.removeLast()
                settingsGroups.append(other)
            }
            return settingsGroups
        }
    }
    
    public func refreshView() {
    }
}
