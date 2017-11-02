//
//  ZomMigrationSwizzles.swift
//  Zom
//
//  Created by N-Pex on 2017-05-23.
//
//

import ChatSecureCore

var OTRXMPPAccount_hasMigratedAssociatedObject: UInt8 = 0

extension OTRXMPPAccount {
    @objc public static func swizzle() {
        ZomUtil.swizzle(self, originalSelector: #selector(getter: OTRXMPPAccount.needsMigration), swizzledSelector:#selector(getter: OTRXMPPAccount.zom_needsMigration))
    }
    
    @objc public var zom_needsMigration: Bool {
        if hasMigrated {
            return false
        }
        return self.zom_needsMigration
    }
    
    open var hasMigrated:Bool {
        get {
            return objc_getAssociatedObject(self, &OTRXMPPAccount_hasMigratedAssociatedObject) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &OTRXMPPAccount_hasMigratedAssociatedObject, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

extension OTRAccountMigrator {
    @objc public static func swizzle() {
        ZomUtil.swizzle(self, originalSelector: #selector(OTRAccountMigrator.areBothAccountsAreOnline), swizzledSelector:#selector(OTRAccountMigrator.zom_areBothAccountAreOnline))
    }
    
    @objc public func zom_areBothAccountAreOnline() -> Bool {
        return true
    }
}
