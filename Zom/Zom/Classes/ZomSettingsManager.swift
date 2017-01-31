//
//  ZomSettingsManager.swift
//  Zom
//
//  Created by N-Pex on 2016-05-26.
//
//

import ChatSecureCore

public class ZomSettingsManager: OTRSettingsManager {
    override public var settingsGroups: [OTRSettingsGroup] {
        get {
            var settingsGroups: [OTRSettingsGroup] = super.settingsGroups
            guard let groupOtherSettings = settingsGroups.last else { return [] }
            var settings:[AnyObject] = []
            for index in (groupOtherSettings.settings.endIndex-1).stride(through: groupOtherSettings.settings.startIndex, by: -1) {
                let setting = groupOtherSettings.settings[index]
                if (setting.isKindOfClass(OTRShareSetting) || setting.isKindOfClass(OTRLanguageSetting)) {
                    settings.append(setting)
                }
            }
            let other = OTRSettingsGroup(title: groupOtherSettings.title, settings: settings)
            settingsGroups.removeLast()
            settingsGroups.append(other)
            return settingsGroups
        }
    }
}
