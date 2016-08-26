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
    public override class func initialize() {
        struct Static {
            static var token: dispatch_once_t = 0
        }
        
        // make sure this isn't a subclass
        if self !== OTRBuddy.self {
            return
        }
        
        dispatch_once(&Static.token) {
            ZomUtil.swizzle(self, originalSelector: Selector("displayName"), swizzledSelector:#selector(OTRBuddy.zom_getDisplayName))
        }
    }
    
    func zom_getDisplayName() -> String? {
        let originalDisplayName = self.zom_getDisplayName()
        let account = self.username
        if (account != nil && (originalDisplayName == nil || account.compare(originalDisplayName!) == NSComparisonResult.OrderedSame)) {
            let split = account.componentsSeparatedByString("@")
            if (split.count > 0) {
                var displayName = split[0]
                
                // Strip hex digits at end?
                let regex = try! NSRegularExpression(pattern: "\\.[a-fA-F0-9]{4,8}$", options: [])
                displayName = regex.stringByReplacingMatchesInString(displayName, options: [], range: NSMakeRange(0, displayName.characters.count), withTemplate: "")
                
                self.setDisplayName(displayName)
                return displayName
            }
        }
        return originalDisplayName
    }
}