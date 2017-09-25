//
//  OTRXMPPRoomManager.swift
//  Zom
//
//  Created by N-Pex on 2017-09-11.
//
//

import ChatSecureCore

extension OTRXMPPRoomManager {
    public static func swizzle() {
        ZomUtil.swizzle(self, originalSelector: #selector(getter: OTRXMPPRoomManager.conferenceServicesJID), swizzledSelector:#selector(getter: OTRXMPPRoomManager.zom_conferenceServicesJID))
    }
    
    public var zom_conferenceServicesJID: [String] {
        let array = self.zom_conferenceServicesJID
        if array.count == 0 {
            return ["conference.zom.im"]
        }
        return array
    }
}
