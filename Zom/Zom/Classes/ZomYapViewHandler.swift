//
//  ZomYapViewHandler.swift
//  Zom
//
//  Created by N-Pex on 2016-08-25.
//
//

import UIKit
import ChatSecureCore
import YapDatabase.YapDatabaseView;
import YapDatabase.YapDatabaseFullTextSearch;
import YapDatabase.YapDatabaseFilteredView;

extension OTRYapViewHandler {
    
    struct OTRYapViewHandlerConstants {
        static let zomviewname = "ZomCharDatabaseView"
    }
    
    private static var swizzle: () {
        let filtering = YapDatabaseViewFiltering.withObjectBlock { (transaction, group, collection, key, object) -> Bool in
            if let message = object as? OTRBaseMessage {
                if message.messageError() != nil {
                    return false
                }
            }
            return true
        }
        let filteredView:YapDatabaseFilteredView = YapDatabaseFilteredView(parentViewName: OTRChatDatabaseViewExtensionName, filtering: filtering, versionTag: "0")
        if (OTRDatabaseManager.sharedInstance().database?.registerExtension(filteredView, withName: OTRYapViewHandlerConstants.zomviewname, sendNotification: false))! {
            ZomUtil.swizzle(self, originalSelector: #selector(OTRYapViewHandler.setup(_:groups:)), swizzledSelector:#selector(OTRYapViewHandler.zom_setup(_:groups:)))
            ZomUtil.swizzle(self, originalSelector: #selector(OTRYapViewHandler.setup(_:groupBlock:sortBlock:)), swizzledSelector: #selector(OTRYapViewHandler.zom_setup(_:groupBlock:sortBlock:)))
        }
    }
    
    open override class func initialize() {
        
        // make sure this isn't a subclass
        if self !== OTRYapViewHandler.self {
            return
        }
        OTRYapViewHandler.swizzle
    }
    
    public func zom_setup(_ view:String,groups:[String]) {
        if view.compare(OTRChatDatabaseViewExtensionName) == ComparisonResult.orderedSame {
            zom_setup(OTRYapViewHandlerConstants.zomviewname, groups: groups)
        } else {
            zom_setup(view, groups: groups)
        }
    }
    
    public func zom_setup(_ view:String, groupBlock:YapDatabaseViewMappingGroupFilter, sortBlock:YapDatabaseViewMappingGroupSort) {
        if view.compare(OTRChatDatabaseViewExtensionName) == ComparisonResult.orderedSame {
            zom_setup(OTRYapViewHandlerConstants.zomviewname, groupBlock: groupBlock, sortBlock: sortBlock);
        } else {
            zom_setup(view, groupBlock: groupBlock, sortBlock: sortBlock);
        }
    }
}
