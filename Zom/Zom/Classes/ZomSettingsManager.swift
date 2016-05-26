//
//  ZomSettingsManager.swift
//  Zom
//
//  Created by N-Pex on 2016-05-26.
//
//

extension OTRSettingsManager {
    public override class func initialize() {
        struct Static {
            static var token: dispatch_once_t = 0
        }
        
        // make sure this isn't a subclass
        if self !== OTRSettingsManager.self {
            return
        }
        
        dispatch_once(&Static.token) {
            let originalSelector = #selector(OTRSettingsManager.populateSettings)
            let swizzledSelector = #selector(OTRSettingsManager.zom_populateSettings)
            
            let originalMethod = class_getInstanceMethod(self, originalSelector)
            let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
            
            let didAddMethod = class_addMethod(self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
            
            if didAddMethod {
                class_replaceMethod(self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
            } else {
                method_exchangeImplementations(originalMethod, swizzledMethod)
            }
        }
    }
    
    public func zom_populateSettings() -> Void {
        zom_populateSettings() // Call original(!)
        if let groupOtherSettings:OTRSettingsGroup = self.settingsGroups.lastObject as? OTRSettingsGroup {
            var settings:[AnyObject] = []
            for index in (groupOtherSettings.settings.endIndex-1).stride(through: groupOtherSettings.settings.startIndex, by: -1) {
                let setting = groupOtherSettings.settings[index]
                if (!setting.isKindOfClass(OTRFeedbackSetting) && !setting.isKindOfClass(OTRDonateSetting)) {
                    settings.append(setting)
                }
            }
            self.settingsGroups.removeLastObject()
            self.settingsGroups.addObject(OTRSettingsGroup(title: groupOtherSettings.title, settings: settings))
        }
    }
}