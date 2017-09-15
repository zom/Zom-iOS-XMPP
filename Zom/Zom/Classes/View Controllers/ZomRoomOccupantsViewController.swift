//
//  ZomGroupInfoViewController.swift
//  Zom
//
//  Created by N-Pex on 2017-07-20.
//
//

import UIKit
import ChatSecureCore

open class ZomRoomOccupantsViewController : OTRRoomOccupantsViewController {
    
    @IBOutlet weak var qrCodeButton:UIButton?
    
    public override init(databaseConnection:YapDatabaseConnection, roomKey:String) {
        super.init(databaseConnection: databaseConnection, roomKey: roomKey)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        qrCodeButton?.backgroundColor = UIColor.white //reset this, set by appearance proxy
        
        // Hide the QR for now
        qrCodeButton?.isHidden = true
    }
    
    override open func viewOccupantInfo(_ occupant: OTRXMPPRoomOccupant) {
        guard let realJid = occupant.realJID, let room = self.room, let accountUniqueId = room.accountUniqueId else { return }
        var _account: OTRAccount? = nil
        var _buddy: OTRBuddy? = nil
        OTRDatabaseManager.shared.readOnlyDatabaseConnection?.read({ (transaction) in
            _account = OTRAccount.fetchObject(withUniqueID: accountUniqueId, transaction: transaction)
            _buddy = OTRBuddy.fetch(withUsername: realJid, withAccountUniqueId: accountUniqueId, transaction: transaction)
        })
        guard let account = _account, let buddy = _buddy else { return }

        let profileVC = ZomProfileViewController(nibName: nil, bundle: nil)
        let otrKit = OTRProtocolManager.sharedInstance().encryptionManager.otrKit
        let info = ZomProfileViewControllerInfo.createInfo(buddy, accountName: account.username, protocolString: account.protocolTypeString(), otrKit: otrKit, hasSession: true, calledFromGroup: true)
        profileVC.setupWithInfo(info: info)
        
        self.navigationController?.pushViewController(profileVC, animated: true)
    }
}
