//
//  UIApplication+Zom.swift
//  Zom
//
//  Created by N-Pex on 2018-06-25.
//

import UIKit
import ChatSecureCore

extension UIApplication {
    
    @objc public static func swizzle() {
        ZomUtil.swizzle(self, originalSelector: #selector(UIApplication.showConnectionErrorNotification(account:error:)), swizzledSelector:#selector(UIApplication.zom_showConnectionErrorNotification))
    }
    
    @objc public func zom_showConnectionErrorNotification(account: OTRXMPPAccount, error: NSError) {
        // Ignored, see issue #615.
    }
}
