//
//  ZomMessagesViewController.swift
//  Zom
//
//  Created by N-Pex on 2015-11-11.
//
//

import UIKit
import ChatSecureCore
import JSQMessagesViewController
import OTRAssets
import BButton
import MBProgressHUD

open class ZomMessagesViewController: OTRMessagesHoldTalkViewController, UIGestureRecognizerDelegate, ZomPickStickerViewControllerDelegate, SupplementaryViewHandlerDelegate, OTRYapViewHandlerDelegateProtocol {
    
    private var hasFixedTitleViewConstraints:Bool = false
    private var attachmentPickerController:OTRAttachmentPicker? = nil
    private var attachmentPickerView:AttachmentPicker? = nil
    private var attachmentPickerTapRecognizer:UITapGestureRecognizer? = nil
    private var joinGroupView:ZomJoinGroupView?
    private var preparingView:UIView?
    private var pendingApprovalView:UIView?
    private var singleCheckIcon:UIImage? = UIImage(named: "ic_sent_grey")
    private var doubleCheckIcon:UIImage? = UIImage(named: "ic_delivered_grey")
    private var clockIcon:UIImage? = UIImage(named: "ic_message_wait_grey")
    private var shieldIcon:UIImage?
    
    // These are for swiping through all images in the thread
    private var galleryLoadingIndicator:MBProgressHUD?
    private var galleryHandler:ZomGalleryHandler?
    private var galleryReferenceView:UIView?
   
    private var groupOccupantsViewHandler:OTRYapViewHandler?
    private let supplementaryViewKindOccupantAdded = ZomAddFriendsCell.reuseIdentifier + "_dynamic"
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        let materialFont = UIFont(name: "MaterialIcons-Regular", size: 30)
        if let mic = self.microphoneButton {
            mic.titleLabel?.font = materialFont
            mic.setTitle("", for: .normal)
            self.keyboardButton?.frame = mic.frame // Make same size as mic
        }
        self.cameraButton?.titleLabel?.font = materialFont
        self.cameraButton?.setTitle("", for: .normal)
        self.keyboardButton?.titleLabel?.font = materialFont
        self.keyboardButton?.setTitle("", for: .normal)
        
        self.supplementaryViewHandler?.addSupplementaryViewKind(kind: ZomAddFriendsCell.reuseIdentifier, nibName: "ZomAddFriendsCell")
        self.supplementaryViewHandler?.addSupplementaryViewKind(kind: supplementaryViewKindOccupantAdded, nibName: "ZomAddFriendsCell")
        self.supplementaryViewHandler?.delegate = self
    }
    
    open override func setThreadKey(_ key: String?, collection: String?) {
        super.setThreadKey(key, collection: collection)
        if isGroupChat(), let connection = connections?.longLivedRead, let key = key {
            self.groupOccupantsViewHandler = OTRYapViewHandler(databaseConnection: connection)
            if let viewHandler = self.groupOccupantsViewHandler {
                viewHandler.delegate = self
                viewHandler.setup(DatabaseExtensionName.groupOccupantsViewName.name(), groups: [key])
            }
            
            // Shown this one before?
            var hasSeenGroup = false
            OTRDatabaseManager.shared.connections?.read.read({ (transaction) in
                if let room = self.room(with: transaction) {
                    hasSeenGroup = room.hasSeenGroup(transaction: transaction)
                }
            })
            updateJoinGroupView(!hasSeenGroup)
        } else {
            self.groupOccupantsViewHandler?.delegate = nil
            self.groupOccupantsViewHandler = nil
        }
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Don't allow sending to archived
        super.connections?.read.read { (transaction) in
            if let threadOwner = self.threadObject(with: transaction), threadOwner.isArchived {
                self.inputToolbar.isHidden = true
            } else {
                self.inputToolbar.isHidden = false
            }
        }
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        // Reset the pending approval view
        if pendingApprovalView != nil {
            pendingApprovalView?.removeFromSuperview()
            pendingApprovalView = nil
        }
        super.viewDidDisappear(animated)
    }
    
    open func attachmentPicker(_ attachmentPicker: OTRAttachmentPicker!, addAdditionalOptions alertController: UIAlertController!) {
        
        let sendStickerAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("Sticker", comment: "Label for button to open up sticker library and choose sticker"), style: UIAlertActionStyle.default, handler: { (UIAlertAction) -> Void in
            let storyboard = UIStoryboard(name: "StickerShare", bundle: Bundle.main)
            let vc = storyboard.instantiateInitialViewController()
            self.present(vc!, animated: true, completion: nil)
        })
        alertController.addAction(sendStickerAction)
    }

    @IBAction func unwindPickSticker(_ unwindSegue: UIStoryboardSegue) {
    }
    
    open func didPickSticker(_ sticker: String, inPack pack: String) {
        super.didPressSend(super.sendButton, withMessageText: ":" + pack + "-" + sticker + ":", senderId: super.senderId, senderDisplayName: super.senderDisplayName, date: Date())
    }
    
    override open func refreshTitleView() -> Void {
        super.refreshTitleView()
        if (OTRAccountsManager.allAccounts().count < 2) {
            // Hide the account name if only one
            if let view = self.navigationItem.titleView as? OTRTitleSubtitleView {
                view.subtitleLabel.isHidden = true
                view.subtitleImageView.isHidden = true
                if (!hasFixedTitleViewConstraints && view.constraints.count > 0) {
                    var removeThese:[NSLayoutConstraint] = [NSLayoutConstraint]()
                    for constraint:NSLayoutConstraint in view.constraints {
                        if ((constraint.firstItem as? NSObject != nil && constraint.firstItem as! NSObject == view.titleLabel) || (constraint.secondItem as? NSObject != nil && constraint.secondItem as! NSObject == view.titleLabel)) {
                            if (constraint.isActive && (constraint.firstAttribute == NSLayoutAttribute.top || constraint.firstAttribute == NSLayoutAttribute.bottom)) {
                                removeThese.append(constraint)
                            }
                        }
                    }
                    view.removeConstraints(removeThese)
                    let c:NSLayoutConstraint = NSLayoutConstraint(item: view.titleLabel, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: view.titleLabel.superview, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0)
                    view.addConstraint(c);
                    hasFixedTitleViewConstraints = true
                }
            }
        }
    }
    
    override open func didPressAccessoryButton(_ sender: UIButton!) {
        if (sender == self.cameraButton) {
            let pickerView = getPickerView()
            self.view.addSubview(pickerView)
            var newFrame = pickerView.frame;
            let toolbarBottom = self.inputToolbar.frame.origin.y + self.inputToolbar.frame.size.height
            newFrame.origin.y = toolbarBottom - newFrame.size.height;
            UIView.animate(withDuration: 0.3, animations: {
                pickerView.frame = newFrame;
            }) 
        } else {
            super.didPressAccessoryButton(sender)
        }
    }
    
    func getPickerView() -> UIView {
        if (self.attachmentPickerView == nil) {
            self.attachmentPickerView = UINib(nibName: "AttachmentPicker", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as? AttachmentPicker
            self.attachmentPickerView!.frame.size.width = self.view.frame.width
            self.attachmentPickerView!.frame.size.height = 100
            let toolbarBottom = self.inputToolbar.frame.origin.y + self.inputToolbar.frame.size.height
            self.attachmentPickerView!.frame.origin.y = toolbarBottom // Start hidden (below screen)
         
            if (!UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary)) {
                self.attachmentPickerView!.removePhotoButton()
            }
            if (!UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)) {
                self.attachmentPickerView!.removeCameraButton()
            }
            
            self.attachmentPickerTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.onTap(_:)))
            self.attachmentPickerTapRecognizer!.cancelsTouchesInView = true
            self.attachmentPickerTapRecognizer!.delegate = self
            self.view.addGestureRecognizer(self.attachmentPickerTapRecognizer!)
        }
        return self.attachmentPickerView!
    }
    
    @objc func onTap(_ sender: UIGestureRecognizer) {
        closePickerView()
    }
    
    func closePickerView() {
        // Tapped outside attachment picker. Close it.
        if (self.attachmentPickerTapRecognizer != nil) {
            self.view.removeGestureRecognizer(self.attachmentPickerTapRecognizer!)
            self.attachmentPickerTapRecognizer = nil
        }
        if (self.attachmentPickerView != nil) {
            var newFrame = self.attachmentPickerView!.frame;
            let toolbarBottom = self.inputToolbar.frame.origin.y + self.inputToolbar.frame.size.height
            newFrame.origin.y = toolbarBottom
            UIView.animate(withDuration: 0.3, animations: {
                    self.attachmentPickerView!.frame = newFrame;
                },
                                       completion: { (success) in
                                        self.attachmentPickerView?.removeFromSuperview()
                                        self.attachmentPickerView = nil
            })
        }
    }
    
    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @IBAction func attachmentPickerSelectPhotoWithSender(_ sender: AnyObject) {
        closePickerView()
        attachmentPicker().showImagePicker(for: UIImagePickerControllerSourceType.photoLibrary)
    }
    
    @IBAction func attachmentPickerTakePhotoWithSender(_ sender: AnyObject) {
        closePickerView()
        attachmentPicker().showImagePicker(for: UIImagePickerControllerSourceType.camera)
    }
    
    @IBAction func attachmentPickerStickerWithSender(_ sender: AnyObject) {
        closePickerView()
        let storyboard = UIStoryboard(name: "StickerShare", bundle: Bundle.main)
        let vc = storyboard.instantiateInitialViewController()
        self.present(vc!, animated: true, completion: nil)
    }
    
    override open func setupInfoButton() {
        let image = UIImage(named: "OTRInfoIcon", in: OTRAssets.resourcesBundle, compatibleWith: nil)
        if self.isGroupChat() {
            super.setupInfoButton()
            self.navigationItem.rightBarButtonItem?.image = image
            return
        }
        let item = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(infoButtonPressed(_:)))
        self.navigationItem.rightBarButtonItem = item
    }
    
    
    @objc open override func infoButtonPressed(_ sender: Any?) {

        var threadOwner: OTRThreadOwner? = nil
        var _account: OTRAccount? = nil
        self.connections?.read.read { (t) in
            threadOwner = self.threadObject(with: t)
            _account = self.account(with: t)
        }
        guard let buddy = threadOwner as? OTRBuddy, let account = _account else {
            return
        }
        let profileVC = ZomProfileViewController(nibName: nil, bundle: nil)
        let otrKit = OTRProtocolManager.encryptionManager.otrKit
        let info = ZomProfileViewControllerInfo.createInfo(buddy, accountName: account.username, protocolString: account.protocolTypeString(), otrKit: otrKit, hasSession: true, calledFromGroup: self.isGroupChat(), showAllFingerprints: false)
        profileVC.setupWithInfo(info: info)
        
        self.navigationController?.pushViewController(profileVC, animated: true)
    }
    
    override open func deliveryStatusString(forMessage message: OTRMessageProtocol) -> NSAttributedString? {
        let result = super.deliveryStatusString(forMessage: message)
        if let result = result {
            if result.string.starts(with: NSString.fa_string(forFontAwesomeIcon: .FAClockO)) {
                if let clock = self.clockIcon {
                    let attachment = self.textAttachment(image: clock, fontSize: 12)
                    return NSAttributedString(attachment: attachment)
                }
            } else if result.string.starts(with: NSString.fa_string(forFontAwesomeIcon: .FACheck)) {
                if let doubleCheck = self.doubleCheckIcon {
                    let attachment = self.textAttachment(image: doubleCheck, fontSize: 12)
                    return NSAttributedString(attachment: attachment)
                }
            }
        }
        // Upstream does not show single checks for send items, but we do.
        if result == nil,
            !message.isMessageIncoming,
            message.isMessageSent {
            if let singleCheck = self.singleCheckIcon {
                let attachment = self.textAttachment(image: singleCheck, fontSize: 12)
                return NSAttributedString(attachment: attachment)
            }
        }
        return result
    }
    
    open override func encryptionStatusString(forMessage message: OTRMessageProtocol) -> NSAttributedString? {
        switch message.messageSecurity {
        case .OMEMO: fallthrough
        case .OTR:
            let attachment = textAttachment(image: getTintedShieldIcon(), fontSize: 12)
            return NSAttributedString(attachment: attachment)
        default:
            return nil
        }
    }
    
    override open func didUpdateState() {
        super.didUpdateState()
        
        // If no buttons, show + and microphone, but disabled
        if self.inputToolbar?.contentView?.leftBarButtonItem == nil {
            self.inputToolbar?.contentView?.leftBarButtonItem = self.cameraButton
            self.inputToolbar?.contentView?.leftBarButtonItem.isEnabled = false
        }
        if self.inputToolbar?.contentView?.rightBarButtonItem == nil {
            self.inputToolbar?.contentView?.rightBarButtonItem = self.microphoneButton
            self.inputToolbar?.contentView?.rightBarButtonItem.isEnabled = false
        }
        
        if isGroupChat() {
            self.pendingApprovalView?.removeFromSuperview()
            self.pendingApprovalView = nil
            self.updatePreparingView(false)
        } else {
        self.connections?.read.asyncRead { [weak self] (transaction) in
            guard let strongSelf = self else { return }
            guard let threadKey = strongSelf.threadKey else { return }
            guard let buddy = transaction.object(forKey: threadKey, inCollection: strongSelf.threadCollection) as? OTRBuddy else { return }
            
            DispatchQueue.main.async {
                if (strongSelf.state.isThreadOnline && buddy.preferredSecurity != OTRSessionSecurity.plaintextOnly) {
                    // Find out if we have previous fingerprints, i.e. if this is
                    // THE VERY FIRST encrypted session we are trying to create.
                    let otrMessageTransportSecurity = buddy.bestTransportSecurity(with: transaction)
                    if (otrMessageTransportSecurity != OTRMessageTransportSecurity.plaintext && otrMessageTransportSecurity != OTRMessageTransportSecurity.plaintextWithOTR) {
                        // We have fingerprints, hide the preparing view
                        strongSelf.updatePreparingView(false)
                    } else {
                        strongSelf.updatePreparingView(true)
                    }
                } else {
                    // Plaintext only, don't show the preparing view
                    strongSelf.updatePreparingView(false)
                }
                
                if let xmppbuddy = buddy as? OTRXMPPBuddy, xmppbuddy.pendingApproval || xmppbuddy.subscription != .both {
                    if strongSelf.pendingApprovalView == nil {
                        strongSelf.pendingApprovalView = UINib(nibName: "WaitingForApprovalView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as? UIView
                        strongSelf.view.addSubview(strongSelf.pendingApprovalView!)
                    }
                    strongSelf.pendingApprovalView!.frame = strongSelf.view.bounds
                    strongSelf.view.bringSubview(toFront: strongSelf.pendingApprovalView!)
                } else {
                    if strongSelf.pendingApprovalView != nil {
                        strongSelf.pendingApprovalView?.removeFromSuperview()
                        strongSelf.pendingApprovalView = nil
                    }
                }
            }
        }
        }
    }
    
    func updatePreparingView(_ show:Bool) {
        if (!show) {
            if let view = self.preparingView {
                UIView.animate(withDuration: 0.5, animations: {
                    self.preparingView?.alpha = 0.0
                }, completion: { (success) in
                    view.isHidden = true
                })
                self.preparingView = nil
            }
        } else {
            if (self.preparingView == nil) {
                self.preparingView = UINib(nibName: "PreparingSessionView",
                    bundle: Bundle.main
                    ).instantiate(withOwner: nil, options: nil)[0] as? UIView
                let size = self.preparingView?.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
                self.preparingView?.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: size!.height)
                self.preparingView?.alpha = 0.0
                self.view.addSubview(self.preparingView!)
            }
            if let view = self.preparingView {
                view.isHidden = false
                UIView.animate(withDuration: 0.5, animations: {
                    self.preparingView?.alpha = 1
                }, completion: { (success) in
                })
            }
        }
    }
    
    func updateJoinGroupView(_ show:Bool) {
        if (!show) {
            if let view = self.joinGroupView {
                UIView.animate(withDuration: 0.5, animations: {
                    view.alpha = 0.0
                }, completion: { (success) in
                    view.isHidden = true
                })
                self.joinGroupView = nil
            }
        } else {
            if (self.joinGroupView == nil) {
                self.joinGroupView = UINib(nibName: "ZomJoinGroupView",
                                           bundle: Bundle.main
                    ).instantiate(withOwner: nil, options: nil)[0] as? ZomJoinGroupView
                if let joinGroupView = self.joinGroupView {
                    var roomName = ""
                    connections?.read.read({ (transaction) in
                        if let room = self.room(with: transaction) {
                            roomName = room.subject ?? room.roomJID?.bare ?? ""
                        }
                    })
                    joinGroupView.titleLabel.text = String(format: NSLocalizedString("Someone invited you to the ´%@´ group.", comment: "Title of screen for joining/not joining group"), roomName)
                    joinGroupView.acceptButtonCallback = {() -> Void in
                        self.connections?.write.readWrite({ (transaction) in
                            if let room = self.room(with: transaction) {
                                room.setHasSeenGroup(hasSeen: true, transaction: transaction)
                            }
                        })
                        DispatchQueue.main.async {
                            self.updateJoinGroupView(false)
                        }
                    }
                    joinGroupView.declineButtonCallback = {() -> Void in
                        var roomJid:XMPPJID? = nil
                        var xmpp:XMPPManager? = nil
                        self.connections?.read.read({ (transaction) in
                            if let room = self.room(with: transaction),
                                let account = room.account(with: transaction) {
                                roomJid = room.roomJID
                                xmpp = OTRProtocolManager.shared.protocol(for: account) as? XMPPManager
                            }
                        })
                        if let roomJid = roomJid, let xmpp = xmpp {
                            xmpp.roomManager.leaveRoom(roomJid)
                            self.didLeaveRoom(nil)
                        }
                    }
                    self.view.addSubview(joinGroupView)
                    joinGroupView.autoPinEdgesToSuperviewEdges()
                }
            }
        }
    }
    
    override open func didPressMigratedSwitch() {
        // Archive this convo
        self.connections?.write.readWrite { (transaction) in
            let thread = self.threadObject(with: transaction)
            if let buddy = thread as? OTRXMPPBuddy {
                buddy.isArchived = true
                buddy.save(with: transaction)
            }
        }
        super.didPressMigratedSwitch()
    }
    
    open override func didSetupMappings(_ handler: OTRYapViewHandler) {
        if let groupHandler = self.groupOccupantsViewHandler, groupHandler == handler {
            return
        }
        
        super.didSetupMappings(handler)
        let numberMappingsItems = handler.mappings?.numberOfItems(inSection: 0) ?? 0
        if numberMappingsItems > 0 {
            self.checkRangeForMigrationMessage(range: NSMakeRange(0, Int(numberMappingsItems)))
        }
        if let occupantsNotFriends = occupantsNotFriends(), occupantsNotFriends.count > 0 {
            if let lastIndexPath = self.collectionView.lastIndexPath() {
                self.supplementaryViewHandler?.addSupplementaryView(indexPath: lastIndexPath, supplementaryView: ZomAddFriendsCell.reuseIdentifier, userData: nil)
            }
        }
    }
    
    func occupantsNotFriends() -> [OTRXMPPBuddy]? {
        var ret:[OTRXMPPBuddy]? = nil
        if isGroupChat() {
            // Any people you are not friends with?
            self.connections?.ui.read({ (transaction) in
                if let room = self.room(with: transaction), let account = self.account(with: transaction) {
                    let allOccupants = room.allOccupants(transaction)
                    ret = allOccupants.flatMap({ (occupant) -> OTRXMPPBuddy? in
                        return occupant.buddy(with: transaction)
                    }).filter({ (buddy) -> Bool in
                        return buddy.username != account.username && buddy.trustLevel != .roster
                    })
                }
            })
        }
        return ret
    }
    
    open override func didReceiveChanges(_ handler: OTRYapViewHandler, sectionChanges: [YapDatabaseViewSectionChange], rowChanges: [YapDatabaseViewRowChange]) {
        if let groupHandler = self.groupOccupantsViewHandler, groupHandler == handler {
            if rowChanges.count > 0 {
                var newOccupants:[OTRXMPPRoomOccupant] = []
                for rowChange in rowChanges {
                    if rowChange.type == .insert {
                        if let indexPath = rowChange.newIndexPath, let occupant = groupHandler.object(indexPath) as? OTRXMPPRoomOccupant {
                            newOccupants.append(occupant)
                        }
                    }
                }
                if newOccupants.count > 0 {
                    var newNonBuddies:[OTRXMPPBuddy]? = nil
                    self.connections?.read.read({ (transaction) in
                        if let account = self.account(with: transaction) {
                            newNonBuddies = newOccupants.flatMap({ (occupant) -> OTRXMPPBuddy? in
                                return occupant.buddy(with: transaction)
                            }).filter({ (buddy) -> Bool in
                                return buddy.username != account.username && buddy.trustLevel != .roster
                            })
                        }
                    })
                    if let newNonBuddies = newNonBuddies, newNonBuddies.count > 0, let lastIndexPath = self.collectionView.lastIndexPath() {
                        self.supplementaryViewHandler?.addSupplementaryView(indexPath: lastIndexPath, supplementaryView: supplementaryViewKindOccupantAdded, userData: newNonBuddies as AnyObject)
                        self.collectionView.reloadItems(at: [lastIndexPath])
                    }
                }
            }
            return
        }
//        var collectionViewNumberOfItems = 0
//        var numberMappingsItems = 0
//        if rowChanges.count > 0 {
//            collectionViewNumberOfItems = self.collectionView.numberOfItems(inSection: 0)
//            numberMappingsItems = Int(self.viewHandler.mappings?.numberOfItems(inSection: 0) ?? 0)
//        }
        super.didReceiveChanges(handler, sectionChanges: sectionChanges, rowChanges: rowChanges)
//        if numberMappingsItems > collectionViewNumberOfItems, numberMappingsItems > 0 {
//                self.checkRangeForMigrationMessage(range: NSMakeRange(collectionViewNumberOfItems, numberMappingsItems - collectionViewNumberOfItems))
//        }
    }
    
    // If we find any incoming migration link messages, show the "your friend has migrated" header
    // to allow the user to start chatting with the new account instead.
    func checkRangeForMigrationMessage(range: NSRange) {
        // Remove this for now, the async nature of it causes crashes with invalid indexpaths in the call to self.message below.
//        DispatchQueue.global().async {
//
//            let types: NSTextCheckingResult.CheckingType = [.link]
//            let detector = try? NSDataDetector(types: types.rawValue)
//                for i in range.location..<(range.location + range.length) {
//                    if let message = self.message(at: IndexPath(row: i, section: 0)), message.isMessageIncoming, let text = message.messageText {
//
//                        detector?.enumerateMatches(in: text, range: NSMakeRange(0, text.utf16.count)) {
//                            (result, _, _) in
//                            if let res = result, let url = res.url, let nsurl = NSURL(string: url.absoluteString) {
//                                if nsurl.otr_isInviteLink {
//                                    nsurl.otr_decodeShareLink({ (jid, queryItems:[URLQueryItem]?) in
//                                        if let jid = jid, let query = queryItems, NSURL.otr_queryItemsContainMigrationHint(query) {
//                                            DispatchQueue.main.async {
//                                                self.showJIDForwardingHeader(withNewJID: jid)
//                                            }
//                                        }
//                                    })
//                                }
//                            }
//                        }
//                    }
//                }
//        }
    }
    
    func textAttachment(image: UIImage, fontSize: CGFloat) -> NSTextAttachment {
        var font:UIFont? = UIFont(name: kFontAwesomeFont, size: fontSize)
        if (font == nil) {
            font = UIFont.systemFont(ofSize: fontSize)
        }
        let textAttachment = NSTextAttachment()
        textAttachment.image = image
        let aspect = image.size.width / image.size.height
        let height = font?.capHeight
        textAttachment.bounds = CGRect(x:0,y:0,width:(height! * aspect),height:height!).integral
        return textAttachment
    }
    
    func getTintedShieldIcon() -> UIImage {
        if (self.shieldIcon == nil) {
            let image = UIImage.init(named: "ic_security_white_36pt")
            self.shieldIcon = image?.tint(UIColor.lightGray, blendMode: CGBlendMode.multiply)
        }
        return shieldIcon!
    }
    
    override open func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        let ret = super.collectionView(collectionView, messageDataForItemAt: indexPath)
        if let ret = ret, let text = ret.text?() {
            if ZomStickerMessage.isValidStickerShortCode(text) {
                return ZomStickerMessage(message: ret)
            }
        }
        return ret
    }
    
    private func rotateRefreshView(_ button:UIButton, revolutions:Int) {
        if let label = button.titleLabel {
            UIView.animate(withDuration: 0.4, delay: 0, options: .curveLinear, animations: {
                label.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
            }, completion: { (done) in
                UIView.animate(withDuration: 0.4, delay: 0, options: .curveLinear, animations: {
                    label.transform = CGAffineTransform(rotationAngle: 2 * CGFloat.pi)
                }, completion: { (done) in
                    label.transform = CGAffineTransform(rotationAngle: 0)
                    if (revolutions == 0) {
                        // Done
                        button.backgroundColor = UIColor.white
                        let attributedString = NSMutableAttributedString(string: "")
                        let range = NSRange(location: 0, length: attributedString.length)
                        attributedString.addAttribute(NSAttributedStringKey.foregroundColor, value: GlobalTheme.shared.mainThemeColor, range: range)
                        button.setAttributedTitle(attributedString, for: .normal)
                        button.isUserInteractionEnabled = false
                    } else {
                        self.rotateRefreshView(button, revolutions:revolutions - 1)
                    }
                })
            })
        }
    }
    
    @IBAction func didPressReinvite(_ sender: AnyObject) {
        var threadOwner: OTRThreadOwner? = nil
        var _account: OTRAccount? = nil
        self.connections?.read.read { (t) in
            threadOwner = self.threadObject(with: t)
            _account = self.account(with: t)
        }
        guard let buddy = threadOwner as? OTRBuddy, let account = _account, let manager = OTRProtocolManager.shared.protocol(for: account) else {
            return
        }
        manager.add(buddy)

        // Rotate the refresh button 5 times, then show a check mark (as a progress indicator)
        if let button = sender as? UIButton {
            rotateRefreshView(button, revolutions:5)
        }
    }
    
    open override func showImage(_ imageItem: OTRImageItem?, from collectionView: JSQMessagesCollectionView, at indexPath: IndexPath) {
        guard let dbConnection = OTRDatabaseManager.shared.readConnection, let threadIdentifier = self.threadKey else {return}
        galleryHandler = ZomGalleryHandler(connection: dbConnection)
        galleryReferenceView = self.view
        if let cell = self.collectionView?.cellForItem(at: indexPath) as? JSQMessagesCollectionViewCell {
            galleryReferenceView = cell.mediaView
        }
        galleryHandler?.fetchImagesAsync(for: threadIdentifier, initialPhoto: imageItem, delegate: self)
    }
    
    override open func newDeviceButtonPressed(_ buddyUniqueId: String) {
        super.newDeviceButtonPressed(buddyUniqueId)
    }
    
    public func supplementaryViewInfo(kind: String, for collectionView: UICollectionView, at indexPath: IndexPath, userData:AnyObject?) -> OTRMessagesCollectionSupplementaryViewInfo? {
        if kind == ZomAddFriendsCell.reuseIdentifier || kind == supplementaryViewKindOccupantAdded {
            if let supplementaryViewInfo = self.supplementaryViewHandler?.createSupplementaryViewInfo(collectionView, kind: kind, populationCallback: { (cell) in
                self.populateAddFriendsCell(cell: cell, indexPath: indexPath, kind: kind, userData: userData, forSizingOnly: true)
            }, tag: nil, tagBehavior: .none) {
                return supplementaryViewInfo
            }
        }
        return nil
    }
    
    public func supplementaryView(kind: String, for collectionView: UICollectionView, at indexPath: IndexPath, userData:AnyObject?) -> UICollectionReusableView? {
        if kind == ZomAddFriendsCell.reuseIdentifier || kind == supplementaryViewKindOccupantAdded {
            let cell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: kind, for: indexPath)
            populateAddFriendsCell(cell: cell, indexPath: indexPath, kind: kind, userData: userData, forSizingOnly: false)
            return cell
        }
        return nil
    }
}

extension ZomMessagesViewController: ZomGalleryHandlerDelegate {
    public func galleryHandlerDidStartFetching(_ galleryHandler: ZomGalleryHandler) {
        self.galleryLoadingIndicator = MBProgressHUD.showAdded(to: self.view, animated: true)
        self.galleryLoadingIndicator?.detailsLabel.text = NSLocalizedString("Cancel", comment: "Cancel loading gallery view")
        let tap = UITapGestureRecognizer(target: self, action: #selector(cancelGalleryFetching))
        self.galleryLoadingIndicator?.addGestureRecognizer(tap)
    }
    
    @objc func cancelGalleryFetching() {
        galleryHandler?.cancelFetching()
        galleryLoadingIndicator?.hide(animated: true)
        galleryLoadingIndicator = nil
    }
    
    public func galleryHandlerDidFinishFetching(_ galleryHandler: ZomGalleryHandler, images: [ZomPhotoStreamImage], initialImage: ZomPhotoStreamImage?) {
        galleryLoadingIndicator?.hide(animated: true)
        galleryLoadingIndicator = nil
        if let referenceImageView = galleryReferenceView as? UIImageView, let initialImage = initialImage {
            initialImage.thumbnailImage = referenceImageView.image
        }
        let browser = ZomPhotosViewController(photos: galleryHandler.images, initialPhoto:initialImage, referenceView:galleryReferenceView)
        self.present(browser, animated: true, completion: nil)
    }
}

extension ZomMessagesViewController: ZomBatchAddFriendsViewControllerDelegate, ZomAddFriendViewControllerDelegate {
    fileprivate func populateAddFriendsCell(cell:UICollectionReusableView?, indexPath:IndexPath, kind:String, userData:AnyObject?, forSizingOnly:Bool) {
        guard let addFriendsCell = cell as? ZomAddFriendsCell else { return }
        let nonBuddies = userData as? [OTRXMPPBuddy] ?? occupantsNotFriends()
        guard let occupantsNotFriends = nonBuddies, occupantsNotFriends.count > 0 else { return }
        
        // Set callback only for "real" cell, not when sizing
        var acceptButtonCallback:((_ buddies:[OTRXMPPBuddy]?) -> Void)? = nil
        if !forSizingOnly {
            acceptButtonCallback = {[unowned self] (buddies) in
                guard let buddies = buddies else { return }
                if buddies.count == 1 {
                    let vc = ZomAddFriendViewController()
                    vc.userData = (kind, indexPath)
                    vc.setBuddy(buddies[0])
                    vc.delegate = self
                    vc.modalPresentationStyle = .overFullScreen
                    vc.modalTransitionStyle = .crossDissolve
                    self.present(vc, animated: true, completion: nil)
                } else {
                    let vc = ZomBatchAddFriendsViewController()
                    vc.setBuddies(buddies)
                    vc.delegate = self
                    vc.modalPresentationStyle = .overFullScreen
                    vc.modalTransitionStyle = .crossDissolve
                    self.present(vc, animated: true, completion: nil)
                }
            }
        }
        
        addFriendsCell.populate(buddies: occupantsNotFriends, actionButtonCallback: acceptButtonCallback)
    }
    
    func didSelectBuddy(_ buddy: OTRXMPPBuddy, from viewController: UIViewController) {
        self.didSelectBuddies([buddy], from: viewController)
        if let vc = viewController as? ZomAddFriendViewController, let (kind, indexPath) = vc.userData as? (String, IndexPath) {
            DispatchQueue.main.async {
                self.supplementaryViewHandler?.removeSupplementaryView(indexPath: indexPath, supplementaryView: kind)
                self.collectionView.reloadData()
            }
        }
    }

    func didNotSelectBuddy(from viewController: UIViewController) {
        if let vc = viewController as? ZomAddFriendViewController, let (kind, indexPath) = vc.userData as? (String, IndexPath) {
            DispatchQueue.main.async {
                self.supplementaryViewHandler?.removeSupplementaryView(indexPath: indexPath, supplementaryView: kind)
                self.collectionView.reloadData()
            }
        }
    }
    
    func didSelectBuddies(_ buddies: [OTRXMPPBuddy], from viewController:UIViewController) {
        var manager:XMPPManager? = nil
        connections?.ui.read { (transaction) in
            if let account = self.account(with: transaction) {
                manager = OTRProtocolManager.shared.protocol(for: account) as? XMPPManager
            }
        }
        if let manager = manager {
            manager.addBuddies(buddies)
            DispatchQueue.main.async {
                let vc = ZomAddFriendRequestedViewController()
                vc.modalPresentationStyle = .overFullScreen
                vc.modalTransitionStyle = .crossDissolve
                viewController.dismiss(animated: true) {
                    self.present(vc, animated: true, completion: {
                        self.supplementaryViewHandler?.removeSupplementaryViewsOfType(type: ZomAddFriendsCell.reuseIdentifier)
                        self.collectionView.reloadData()
                    })
                }
            }
        } // else TODO handle error case
    }
    
    func didNotSelectBuddies(from viewController: UIViewController) {
    }

}
