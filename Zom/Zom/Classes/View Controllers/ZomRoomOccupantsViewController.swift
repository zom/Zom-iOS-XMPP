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
    
    open override func didSelectFooterCell(type: String) {
        switch type {
        case "cellGroupLeave":
            let alert = UIAlertController(title: NSLocalizedString("Leave group?", comment: "Title for leave group prompt"), message: NSLocalizedString("Your group chat history will be wiped away. To keep these chats, archive the group instead.", comment: "Message for leave group prompt"), preferredStyle: .alert)
            let archiveAction = UIAlertAction(title: ARCHIVE_STRING(), style: .default, handler: { (action: UIAlertAction) -> Void in
                if let delegate = self.delegate {
                    delegate.didArchiveRoom(self)
                }
            })
            let leaveAction = UIAlertAction(title: NSLocalizedString("Leave", comment: "Option to leave a group chat"), style: .default, handler: { (action: UIAlertAction) -> Void in
                super.didSelectFooterCell(type: "cellGroupLeave")
            })
            let cancelAction = UIAlertAction(title: CANCEL_STRING(), style: .cancel, handler: nil)
            alert.addAction(archiveAction)
            alert.addAction(leaveAction)
            alert.addAction(cancelAction)
            present(alert, animated: true, completion: nil)
            return
        default: break
        }
        super.didSelectFooterCell(type: type)
    }
    
    override open func viewOccupantInfo(_ occupant: OTRXMPPRoomOccupant) {
        guard let realJid = occupant.realJID, let room = self.room, let accountUniqueId = room.accountUniqueId else { return }
        var _account: OTRAccount? = nil
        var _buddy: OTRBuddy? = nil
        OTRDatabaseManager.shared.readOnlyDatabaseConnection?.read({ (transaction) in
            _account = OTRAccount.fetchObject(withUniqueID: accountUniqueId, transaction: transaction)
            _buddy = OTRXMPPBuddy.fetchBuddy(jid: realJid, accountUniqueId: accountUniqueId, transaction: transaction)
        })
        guard let account = _account, let buddy = _buddy else { return }

        let profileVC = ZomProfileViewController(nibName: nil, bundle: nil)
        let otrKit = OTRProtocolManager.encryptionManager.otrKit
        let info = ZomProfileViewControllerInfo.createInfo(buddy, accountName: account.username, protocolString: account.protocolTypeString(), otrKit: otrKit, hasSession: true, calledFromGroup: true, showAllFingerprints: false)
        profileVC.setupWithInfo(info: info)
        
        self.navigationController?.pushViewController(profileVC, animated: true)
    }
}
