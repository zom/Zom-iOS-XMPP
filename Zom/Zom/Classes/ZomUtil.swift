//
//  ZomUtil.swift
//  Zom
//
//  Created by N-Pex on 2016-08-25.
//
//

import UIKit
import ChatSecureCore

open class ZomUtil {
    open class func swizzle(_ clazz:AnyClass, originalSelector:Selector, swizzledSelector:Selector) -> Void {
        if let originalMethod = class_getInstanceMethod(clazz, originalSelector),
            let swizzledMethod = class_getInstanceMethod(clazz, swizzledSelector) {
            
            let didAddMethod = class_addMethod(clazz, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
            
            if didAddMethod {
                class_replaceMethod(clazz, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
            } else {
                method_exchangeImplementations(originalMethod, swizzledMethod)
            }
        }
    }
}


