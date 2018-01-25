//
//  ZomProfileViewController.swift
//  Zom
//
//  Created by David Chiles on 12/12/16.
//
//

import Foundation
import PureLayout
import OTRAssets
import MobileCoreServices
import FormatterKit

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


extension OTRBuddy {
    func zom_inviteLink(_ fingerprint:Fingerprint?) -> URL? {
        guard let jid = XMPPJID(string: self.username) else { return nil }
        var queryItems = [URLQueryItem]()
        if let fprint = fingerprint {
            switch fprint {
            case .OTR(let otrFingerprint):
                queryItems.append(URLQueryItem(name: OTRAccount.fingerprintStringType(for: .OTR)!, value: (otrFingerprint.fingerprint as NSData).humanReadableFingerprint()))
                break
            default:
                break
            }
        }
        return NSURL.otr_shareLink(NSURL.otr_shareBase, jid: jid , queryItems: queryItems)
    }
}

enum Fingerprint {
    case OTR(OTRFingerprint)
    case OMEMO(OTROMEMODevice)
    
    func fingerprintString() -> String {
        switch self {
        case .OTR(let fingerprint):
            return (fingerprint.fingerprint as NSData).humanReadableFingerprint()
        case .OMEMO(let device):
            return device.humanReadableFingerprint
        }
    }
    
    func isTrusted() -> Bool {
        switch self {
        case .OTR(let fingerprint):
            return fingerprint.isTrusted()
        case .OMEMO(let device):
            return device.isTrusted()
        }
    }
    
    func lastSeen() -> Date {
        switch self {
        case .OTR:
            return Date.distantPast
        case .OMEMO(let device):
            return device.lastSeenDate
        }
    }
    
    func lastSeenDisplayString() -> String {
        switch self {
        case .OTR:
            return "OTR"
        case .OMEMO(let device):
            let intervalFormatter = TTTTimeIntervalFormatter()
            let interval = -Date().timeIntervalSince(device.lastSeenDate)
            let since = intervalFormatter.string(forTimeInterval: interval)
            return "OMEMO: " + since!
        }
    }
}

struct FingerprintCellInfo: ZomProfileViewCellInfoProtocol {
    
    let fingerprint:Fingerprint
    let qrAction:((_ info:FingerprintCellInfo)->Void)?
    let shareAction:((_ info:FingerprintCellInfo)->Void)?
    fileprivate let shareImage = UIImage(named: "OTRShareIcon", in: OTRAssets.resourcesBundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
    let showLastSeen:Bool
    
    func configure(_ cell: UITableViewCell) {
        guard let fingerprintCell = cell as? ZomFingerprintCell else {
            return
        }
        fingerprintCell.shareButton.setImage(self.shareImage, for: UIControlState())
        fingerprintCell.qrButton.setImage(UIImage(named: "zom_qrcode_placeholder", in: Bundle.main, compatibleWith: nil), for: UIControlState())
        fingerprintCell.fingerprintLabel.text = fingerprint.fingerprintString()
        if showLastSeen {
            fingerprintCell.lastSeenLabel.text = fingerprint.lastSeenDisplayString()
            fingerprintCell.lastSeenLabelHeight.constant = 20
        } else {
            fingerprintCell.lastSeenLabel.text = ""
            fingerprintCell.lastSeenLabelHeight.constant = 0
        }
        fingerprintCell.qrAction = {cell in
            if let action = self.qrAction {
                action(self)
            }
        }
        fingerprintCell.shareAction = {cell in
            if let action = self.shareAction {
                action(self)
            }
        }
    }
    
    func cellIdentifier() -> ZomProfileViewCellIdentifier {
        return .FingerprintCell
    }
    
    func cellHeight() -> CGFloat? {
        var height:CGFloat = 90
        if showLastSeen {
            height += 20
        }
        return height
    }
}

enum ButtonCellType {
    case verify(OTRFingerprint)
    case refresh
    case startChat
    
    func text() -> String {
        switch self {
        case .verify : return NSLocalizedString("Verify Contact", comment: "Button label to verify contact security")
        case .refresh: return NSLocalizedString("Refresh Session", comment: "Button label to refresh an OTR session")
        case .startChat: return NSLocalizedString("Start Chat", comment: "Button label to start a chat")
        }
    }
}

class ZomProfileTableViewSource:NSObject, UITableViewDataSource, UITableViewDelegate {
    
    let tableSections:[TableSectionInfo]
    var info:ZomProfileViewControllerInfo
    var controller:ZomProfileViewController
    var relaodData:(() -> Void)?
    var toggleShowAll:(() -> Void)?

    init(info:ZomProfileViewControllerInfo, tableSections:[TableSectionInfo], controller:ZomProfileViewController) {
        self.info = info
        self.tableSections = tableSections
        self.controller = controller
    }
    
    //MARK: UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return tableSections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableSections[section].cells?.count ?? 0;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let object = self.tableSections.infoAtIndexPath(indexPath) {
            let cell = tableView.dequeueReusableCell(withIdentifier: object.cellIdentifier().rawValue, for: indexPath)
            // Lay it out
            cell.setNeedsUpdateConstraints()
            cell.updateConstraintsIfNeeded()
            cell.setNeedsLayout()
            cell.layoutIfNeeded()
            object.configure(cell)
            return cell
        }
        
        //This should never happen
        return tableView.dequeueReusableCell(withIdentifier: "", for: indexPath)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.tableSections.sectionAtIndex(section)?.title
    }
    
    //MARK: UITableviewDelegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.tableSections.infoAtIndexPath(indexPath)?.cellHeight() ?? UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let object = self.tableSections.infoAtIndexPath(indexPath) as? ButtonCellInfo  else {
            return
        }
        
        switch object.type {
        case let .otrVerify(fingerprint):
            // Set active fingerprint as trusted
            fingerprint.trustLevel = .trustedUser
            OTRProtocolManager.encryptionManager.save(fingerprint)
            self.relaodData?()
            break
        case let .omemoVerify(dev):
            
            OTRDatabaseManager.sharedInstance().readWriteDatabaseConnection?.asyncReadWrite({ (transaction) in
                let device = OTROMEMODevice.fetchObject(withUniqueID: dev.uniqueId, transaction: transaction)
                device?.trustLevel = .trustedUser
                device?.save(with: transaction)
            }, completionBlock: { 
                self.relaodData?()
            })
            break
         case .refresh:
            
            //TODO: We should at some point listen for encryption change notification to refresh the table view with new fingerprint informatoin
            guard let username = self.info.otrKitInfo.username else {
                return
            }
            self.info.otrKit.initiateEncryption(withUsername: username, accountName: self.info.otrKitInfo.accountName, protocol: self.info.otrKitInfo.protocolString)
            break
        case .startChat:
            //TODO: We should at some point listen for encryption change notification to refresh the table view with new fingerprint informatoin
            // TODO: close and start chat! Possibly via
            if let appDelegate = UIApplication.shared.delegate as? ZomAppDelegate {
                switch self.info.user {
                case let .buddy(buddy) :
                    _ = controller.navigationController?.popViewController(animated: true)
                    appDelegate.splitViewCoordinator.enterConversationWithBuddy(buddy.uniqueId)
                default:
                    return
                }
            }
            break
        case .showMore(_):
            self.toggleShowAll?()
            break
        }
    }
}

open class ZomProfileViewController : UIViewController {
    
    fileprivate var avatarPicker:OTRAttachmentPicker? = nil
    
    
    let tableView = UITableView(frame: CGRect.zero, style: .grouped)
    fileprivate var tableViewSource:ZomProfileTableViewSource? = nil
    var profileObserver:ZomProfileViewObserver? = nil
    var passwordChangeDelegate:PasswordChangeTextFieldDelegate? = nil
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        
        ZomProfileViewCellIdentifier.allValues.forEach { (cellIdentifier) in
            switch ZomProfileViewCellIdentifier.classOrNib(cellIdentifier) {
                case let .class(cellClass) :
                    self.tableView.register(cellClass, forCellReuseIdentifier: cellIdentifier.rawValue)
                break
                case let .nib(cellNib):
                    self.tableView.register(cellNib, forCellReuseIdentifier: cellIdentifier.rawValue)
                break
            }
        }
        
        self.view.addSubview(self.tableView)
        self.tableView.autoPinEdgesToSuperviewEdges()
    }
    
    func setupWithInfo(info:ZomProfileViewControllerInfo) {
        let qrAction:(FingerprintCellInfo)->Void = { [weak self] fingerprintInfo in
            
            User.shareURL(info.user, fingerprint: fingerprintInfo.fingerprint , completion: { (url) in
                guard let inviteURL = url else {
                    return
                }
                guard let qrViewController = OTRQRCodeViewController(qrString: inviteURL.absoluteString) else {
                    return
                }
                let navigationController = UINavigationController(rootViewController: qrViewController)
                self?.present(navigationController, animated: true, completion: nil)
            })
        }

        let shareAction:(FingerprintCellInfo) -> Void = { [weak self] fingerprintInfo in
            
            User.shareURL(info.user, fingerprint: fingerprintInfo.fingerprint, completion: { (url) in
                guard let inviteURL = url else {
                    return
                }
                let activityViewController = UIActivityViewController(activityItems: [inviteURL], applicationActivities: nil)
                if let view = self?.view {
                    activityViewController.popoverPresentationController?.sourceView = view;
                    activityViewController.popoverPresentationController?.sourceRect = view.bounds;
                }
                
                self?.present(activityViewController, animated: true, completion: nil)
            })
        }

        self.profileObserver = ZomProfileViewObserver(info:info,qrAction:qrAction,shareAction:shareAction)
        self.profileObserver?.delegate = self
        self.updateTableView()
    }
    
    func updateTableView() {
        guard let info = self.profileObserver?.info, let tableSections = self.profileObserver?.tableSections else {
            return
        }
        self.tableViewSource = ZomProfileTableViewSource(info: info, tableSections: tableSections, controller: self)
        self.tableViewSource?.relaodData = { [weak self] in
            self?.profileObserver?.reloadInfo()
            self?.updateTableView()
        }
        self.tableViewSource?.toggleShowAll = { [weak self] in
            if let observer = self?.profileObserver {
                observer.showAllFingerprints = !observer.showAllFingerprints
            }
            self?.profileObserver?.reloadInfo()
            self?.updateTableView()
        }
        self.tableView.dataSource = self.tableViewSource
        self.tableView.delegate = self.tableViewSource
        self.tableView.reloadData()
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.setStatusBarHidden(false, with: .none)
    }
    
    @IBAction func didPressChangePasswordButton(_ sender: UIButton) {
        let alert = UIAlertController(title: NSLocalizedString("Change password", comment: "Title for change password alert"), message: NSLocalizedString("Please enter your new password", comment: "Message for change password alert"), preferredStyle: UIAlertControllerStyle.alert)
        passwordChangeDelegate = PasswordChangeTextFieldDelegate(alert: alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK button"), style: UIAlertActionStyle.default, handler: {(action: UIAlertAction!) in
            if let user = self.profileObserver?.info.user {
                switch user {
                case let .account(account):
                    if let xmppManager = OTRProtocolManager.sharedInstance().protocol(for: account) as? XMPPManager,
                        let newPassword = alert.textFields?.first?.text {
                        xmppManager.changePassword(newPassword, completion: { (success, error) in
                            DispatchQueue.main.async(execute: { 
                                //Update password textfield with new password
                                self.tableViewSource?.relaodData?()
                            })
                            
                        })
                    }
                    break
                default:
                    break
                }
            }
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel button"), style: UIAlertActionStyle.cancel, handler: nil))
        alert.addTextField(configurationHandler: {(textField: UITextField!) in
            textField.placeholder = NSLocalizedString("Password:", comment: "Prompt for new password")
            textField.isSecureTextEntry = true
            textField.addTarget(self.passwordChangeDelegate, action: #selector(PasswordChangeTextFieldDelegate.textFieldDidChange(_:)), for: UIControlEvents.editingChanged)
        })
        alert.addTextField(configurationHandler: {(textField: UITextField!) in
            textField.placeholder = NSLocalizedString("Confirm New Password", comment: "Prompt for confirm password")
            textField.isSecureTextEntry = true
            textField.addTarget(self.passwordChangeDelegate, action: #selector(PasswordChangeTextFieldDelegate.textFieldDidChange(_:)), for: UIControlEvents.editingChanged)
        })
        alert.actions[0].isEnabled = false
        self.present(alert, animated: true, completion: nil)
    }

    class PasswordChangeTextFieldDelegate: NSObject, UITextFieldDelegate {
        var alert:UIAlertController
        
        @objc func textFieldDidChange(_ textField: UITextField){
            guard let tf1 = alert.textFields?[0] else {
                return
            }
            guard let tf2 = alert.textFields?[1] else {
                return
            }
            if (tf1.text?.characters.count > 0 && tf2.text?.characters.count > 0 &&
                tf1.text!.compare(tf2.text!) == ComparisonResult.orderedSame) {
                alert.actions[0].isEnabled = true
            } else {
                alert.actions[0].isEnabled = false
            }
        }
        
        init(
            alert:UIAlertController
            ) {
            self.alert = alert
        }
    }
    
    @IBAction func didTapAvatarImageWithSender(_ sender: UIButton) {
        if let user = self.profileObserver?.info.user {
            switch user {
            case .account(_):
                // Keep strong reference
                if let parentViewController = self.tabBarController?.navigationController {
                    avatarPicker = OTRAttachmentPicker(parentViewController: parentViewController as! UIViewController & UIPopoverPresentationControllerDelegate, delegate: self)
                    avatarPicker!.showAlertController(fromSourceView: sender, withCompletion: nil)
                }
                break
            default:
                break
            }
        }
    }
}

extension ZomProfileViewController: OTRAttachmentPickerDelegate {
    public func attachmentPicker(_ attachmentPicker: OTRAttachmentPicker, gotVideoURL videoURL: URL) {
        
    }
    
    public func attachmentPicker(_ attachmentPicker: OTRAttachmentPicker, gotPhoto photo: UIImage, withInfo info: [AnyHashable: Any]) {
        if let user = self.profileObserver?.info.user {
            switch user {
            case let .account(account):
                if let xmppManager = OTRProtocolManager.sharedInstance().protocol(for: account) as? XMPPManager {
                    xmppManager.setAvatar(photo, completion: { (success) in
                        })
                }
                break
            default:
                break
            }
        }
    }
    
    public func attachmentPicker(_ attachmentPicker: OTRAttachmentPicker, preferredMediaTypesFor source: UIImagePickerControllerSourceType) -> [String] {
        return [kUTTypeImage as String]
    }
}

extension ZomProfileViewController: ZomProfileViewObserverDelegate {
    func didUpdateTableSections(observer: ZomProfileViewObserver) {
        self.updateTableView()
    }
}
