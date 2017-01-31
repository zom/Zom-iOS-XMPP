//
//  ZomShareController.swift
//  Zom
//
//  Created by N-Pex on 2016-05-19.
//
//

extension ShareControllerURLSource {
    public override class func initialize() {
        struct Static {
            static var token: dispatch_once_t = 0
        }
        
        // make sure this isn't a subclass
        if self !== ShareControllerURLSource.self {
            return
        }
        
        dispatch_once(&Static.token) {
            let originalSelector = #selector(ShareControllerURLSource.activityViewController(_:subjectForActivityType:))
            let swizzledSelector = #selector(ShareControllerURLSource.zom_activityViewController(_:subjectForActivityType:))
            
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
    
    public func zom_activityViewController(activityViewController: UIActivityViewController, subjectForActivityType activityType: String?) -> String {
        let text = NSLocalizedString("Let's Zom!", comment: "String for sharing Zom link")
        return text
    }
}
