//
//  ZomShareController.swift
//  Zom
//
//  Created by N-Pex on 2016-05-19.
//
//

extension ShareControllerURLSource {
    
    @objc public static func swizzle() {
        let originalSelector = #selector(ShareControllerURLSource.activityViewController(_:subjectForActivityType:))
        let swizzledSelector = #selector(ShareControllerURLSource.zom_activityViewController(_:subjectForActivityType:))
        
        if let originalMethod = class_getInstanceMethod(self, originalSelector), let swizzledMethod = class_getInstanceMethod(self, swizzledSelector) {
            
            let didAddMethod = class_addMethod(self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
            
            if didAddMethod {
                class_replaceMethod(self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
            } else {
                method_exchangeImplementations(originalMethod, swizzledMethod)
            }
        }
    }
    
    @objc public func zom_activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: String?) -> String {
        let text = NSLocalizedString("Let's Zom!", comment: "String for sharing Zom link")
        return text
    }
}
