//
//  OTRXMPPRoom+Zom.swift
//  Zom
//
//  Created by N-Pex on 2018-04-05.
//

import UIKit

extension OTRXMPPRoom {
    
    private static let META_HAS_SEEN_GROUP = "has_seen_group"
    
    /**
     An extension method indicating if we have ever viewed this group. Used to show a "really join?" type of view the first time we try to view the group. Implemented by storing a bool in the metadata for the OTRXMPPRoom object
     */
    public func hasSeenGroup(transaction: YapDatabaseReadTransaction) -> Bool {
        let meta = transaction.metadata(forKey: self.uniqueId, inCollection: OTRXMPPRoom.collection)
        if let dict = meta as? [String:Any] {
            return dict[OTRXMPPRoom.META_HAS_SEEN_GROUP] as? Bool ?? false
        }
        return false
    }
    
    public func setHasSeenGroup(hasSeen:Bool, transaction: YapDatabaseReadWriteTransaction) {
        let meta = transaction.metadata(forKey: self.uniqueId, inCollection: OTRXMPPRoom.collection)
        if var dict = meta as? [String:Any] {
            dict[OTRXMPPRoom.META_HAS_SEEN_GROUP] = hasSeen
            transaction.replaceMetadata(dict, forKey: self.uniqueId, inCollection: OTRXMPPRoom.collection)
        } else {
            let dict = [OTRXMPPRoom.META_HAS_SEEN_GROUP: false]
            transaction.replaceMetadata(dict, forKey: self.uniqueId, inCollection: OTRXMPPRoom.collection)
        }
    }
}
