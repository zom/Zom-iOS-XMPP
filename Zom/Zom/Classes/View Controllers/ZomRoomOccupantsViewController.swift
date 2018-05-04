//
//  ZomGroupInfoViewController.swift
//  Zom
//
//  Created by N-Pex on 2017-07-20.
//
//

import UIKit
import ChatSecureCore

open class ZomRoomOccupantsViewController : OTRRoomOccupantsViewController, ZomTransferOwnershipViewControllerDelegate {

    @IBOutlet weak var qrCodeButton:UIButton?
    
    public override init(databaseConnection:YapDatabaseConnection, roomKey:String) {
        super.init(databaseConnection: databaseConnection, roomKey: roomKey)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        // Remove group condig option for now, issue #589
        if let index = headerRows.index(of: "cellGroupOMEMOConfig") {
            headerRows.remove(at: index)
        }
        
        qrCodeButton?.backgroundColor = UIColor.white //reset this, set by appearance proxy
        
        // Hide the QR for now
        qrCodeButton?.isHidden = true
    }
    
    // Dont show the i accessory view
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if cell is OTRBuddyInfoCheckableCell {
            cell.accessoryView = nil
            cell.accessoryType = .none
        }
    }
    
    open override func didSelectFooterCell(type: String) {
        switch type {
        case "cellGroupLeave":
            let alert = UIAlertController(title: NSLocalizedString("Leave Group?", comment: "Title for leave group prompt"), message: NSLocalizedString("Your group chat history will be wiped away. To keep these chats, archive the group instead.", comment: "Message for leave group prompt"), preferredStyle: .alert)
            let archiveAction = UIAlertAction(title: ARCHIVE_STRING(), style: .default, handler: { (action: UIAlertAction) -> Void in
                if let delegate = self.delegate {
                    delegate.didArchiveRoom(self)
                }
            })
            let leaveAction = UIAlertAction(title: NSLocalizedString("Leave", comment: "Option to leave a group chat"), style: .default, handler: { (action: UIAlertAction) -> Void in
                if self.ownOccupant()?.affiliation == .owner {
                    self.transferOwnershipAndLeave()
                } else {
                    self.doLeave()
                }
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
        OTRDatabaseManager.shared.readConnection?.read({ (transaction) in
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
    
    func doLeave() {
        super.didSelectFooterCell(type: "cellGroupLeave")
    }
    
    func transferOwnershipAndLeave() {
        let ownOccupant = self.ownOccupant()
        var occupants:[OTRXMPPRoomOccupant] = []
        if let viewHandler = self.viewHandler,
            let mappings = viewHandler.mappings {
                    for section in 0..<mappings.numberOfSections() {
                        for row in 0..<mappings.numberOfItems(inSection: section) {
                            if let roomOccupant = viewHandler.object(IndexPath(row: Int(row), section: Int(section))) as? OTRXMPPRoomOccupant {
                                
                                var isYou = false
                                if let ownOccupant = ownOccupant, ownOccupant.jid?.full == roomOccupant.jid?.full {
                                    isYou = true
                                }
                                if !isYou {
                                    occupants.append(roomOccupant)
                                }
                            }
                        }
                    }
                }
        guard occupants.count > 0 else {
            doLeave()
            return
        }
        
        let vc = ZomTransferOwnershipViewController()
        vc.setOccupants(occupants)
        vc.delegate = self
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        self.present(vc, animated: true, completion: nil)
    }
    
    func didSelectOccupants(_ occupants: [OTRXMPPRoomOccupant], from viewController: UIViewController) {
        viewController.dismiss(animated: true) {
            for occupant in occupants {
                self.grantPrivileges(occupant, affiliation: .owner)
            }
            self.doLeave()
        }
    }
    
    func didNotSelectOccupants(from viewController: UIViewController) {
        // Do nothing
    }
}
