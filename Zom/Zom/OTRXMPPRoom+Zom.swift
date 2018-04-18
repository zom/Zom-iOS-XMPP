//
//  OTRXMPPRoom+Zom.swift
//  Zom
//
//  Created by N-Pex on 2018-04-18.
//

import Foundation

extension OTRXMPPRoom {
    
    open func grantPrivileges(_ occupant:OTRXMPPRoomOccupant, affiliation:RoomOccupantAffiliation) {
        guard let xmppRoom = self.xmppRoom(),
            let occupantRealJid = occupant.realJID
            else { return }
        xmppRoom.editPrivileges([XMPPRoom.item(withAffiliation: affiliation.stringValue, jid: occupantRealJid)])
    }
    
    open func revokeMembership(_ occupant:OTRXMPPRoomOccupant) {
        guard let xmppRoom = self.xmppRoom(),
            let occupantRealJid = occupant.realJID
            else { return }
        xmppRoom.editPrivileges([XMPPRoom.item(withAffiliation: RoomOccupantAffiliation.none.stringValue, jid: occupantRealJid)])
    }
    
    /** Do not call this within a yap transaction! */
    open func xmppRoom() -> XMPPRoom? {
        guard let roomManager = xmppRoomManager(),
            let roomJid = self.roomJID,
            let xmppRoom = roomManager.room(for: roomJid)
            else { return nil }
        return xmppRoom
    }
    
    open func xmppRoomManager() -> OTRXMPPRoomManager? {
        var xmpp: XMPPManager? = nil
        OTRDatabaseManager.shared.connections?.read.read { transaction in
            if let account = self.account(with: transaction) {
                xmpp = OTRProtocolManager.shared.protocol(for: account) as? XMPPManager
            }
        }
        return xmpp?.roomManager
    }
}
