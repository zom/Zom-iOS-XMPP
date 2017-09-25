//
//  ZomBuddy.swift
//  Zom
//
//  Created by N-Pex on 2016-06-17.
//
//

import UIKit
import ChatSecureCore

extension OTRBuddy {
    
    @objc public static func swizzle() {
        ZomUtil.swizzle(self, originalSelector: #selector(getter: OTRUserInfoProfile.displayName), swizzledSelector:#selector(OTRBuddy.zom_getDisplayName))
    }
    
    func zom_getDisplayName() -> String? {
        let originalDisplayName = self.zom_getDisplayName()
        let account = self.username
        if (originalDisplayName == nil || account.compare(originalDisplayName!) == ComparisonResult.orderedSame) {
            let split = account.components(separatedBy: "@")
            if (split.count > 0) {
                var displayName = split[0]
                
                // Strip hex digits at end?
                let regex = try! NSRegularExpression(pattern: "\\.[a-fA-F0-9]{4,8}$", options: [])
                displayName = regex.stringByReplacingMatches(in: displayName, options: [], range: NSMakeRange(0, displayName.characters.count), withTemplate: "")
                
                self.displayName = displayName
                return displayName
            }
        }
        return originalDisplayName
    }
}
