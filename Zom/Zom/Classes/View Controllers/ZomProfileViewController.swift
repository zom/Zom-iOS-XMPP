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
    func zom_inviteLink(_ otrFingerprint:String?) -> URL {
        
        var fingerprints = [String:String]()
        if let otrFprint = otrFingerprint {
            fingerprints[OTRAccount.fingerprintStringType(for: .OTR)] = otrFprint
        }
        
        return NSURL.otr_shareLink(NSURL.otr_shareBase().absoluteString, username: self.username, fingerprints: fingerprints)
    }
}



/** This contains all the information necessary to build the ZomProfileViewController */
struct ZomProfileViewControllerInfo {
    
    struct zomOTRKitInfo {
        /** The OTRKit username optional because accounts don't have a username just an account name */
        let username:String?
        let accountName:String
        let protocolString:String
    }
    
    /** Since a profile can be for a user or a buddy this contains some of those differences */
    enum User {
        case buddy(OTRBuddy)
        case account(OTRAccount)
        
        //TODO: completion block should be removed once we can change account invite link to non-async
        static func shareURL(_ user:User,fingerprint:String?,completion:@escaping (_ url:URL?)->Void) {
            switch user {
            case let .buddy(buddy) :
                let inviteURL = buddy.zom_inviteLink(fingerprint)
                completion(inviteURL)
            case let .account(account):
                let fingerprints = Set(arrayLiteral: NSNumber(value: OTRFingerprintType.OTR.rawValue))
                account.generateShareURL(withFingerprintTypes: fingerprints, completion: { (url, error) in
                    completion(url)
                })
                return
            }
        }
        
        func databaseObject() -> OTRYapDatabaseObject {
            switch self {
            case .buddy(let buddy): return buddy
            case .account(let account): return account
            }
        }
        
        func yapKey() -> String {
            return self.databaseObject().uniqueId
        }
        func yapCollection() -> String {
            return type(of: self.databaseObject()).collection()
        }
    }
    
    /** The sections of table view which contain the rows */
    let tableSections:[TableSectionInfo]
    let user:User
    let otrKit:OTRKit
    let otrKitInfo:zomOTRKitInfo
    let hasSession:Bool
    
    /** Fetch the row info at a given indexpath */
    func infoAtIndexPath(_ indexPath:IndexPath) -> ZomProfileViewCellInfoProtocol? {
        let section = indexPath.section
        let row = indexPath.row
        
        if let sectionInfo = self.sectionAtIndex(section) {
            if let cells = sectionInfo.cells {
                if(cells.indices.contains(row)) {
                    return cells[row]
                }
            }
        }
        return nil
    }
    
    func sectionAtIndex(_ index:Int) -> TableSectionInfo? {
        if (self.tableSections.indices.contains(index)) {
           return self.tableSections[index]
        }
        return nil
    }
    
    /** use this static function to create the info object for a buddy */
    static func createInfo(_ buddy:OTRBuddy,accountName:String,protocolString:String,otrKit:OTRKit,qrAction:((FingerprintCellInfo)->Void)?,shareAction:((FingerprintCellInfo)->Void)?,hasSession:Bool) -> ZomProfileViewControllerInfo {
        
        let userCell = UserCellInfo(avatarImage: buddy.avatarImage(), title: buddy.threadName(), subtitle: buddy.username)
        
        
        
        let allFingerprints = otrKit.fingerprints(forUsername: buddy.username, accountName: accountName, protocol: protocolString)

        let fingerprintSectionCells = allFingerprints.flatMap { (fingerprint) -> [ZomProfileViewCellInfoProtocol] in
            var result:[ZomProfileViewCellInfoProtocol] = [FingerprintCellInfo(fingerprint: fingerprint, qrAction: qrAction, shareAction: shareAction)]
            if (!fingerprint.isTrusted()) {
                result.append(ButtonCellInfo(type: ButtonCellInfo.ButtonCellType.verify(fingerprint)))
            }
            return result
        }
        
        var sections = [TableSectionInfo(title: nil, cells: [userCell,(hasSession ? ButtonCellInfo(type:.refresh) : ButtonCellInfo(type:.startChat))])]
        if (fingerprintSectionCells.count > 0 ) {
            sections.append(TableSectionInfo(title: NSLocalizedString("Secure Identity", comment: "Table view section header"), cells: fingerprintSectionCells))
        }
        return ZomProfileViewControllerInfo(tableSections: sections,user: .buddy(buddy), otrKit: otrKit,otrKitInfo: zomOTRKitInfo(username: buddy.username, accountName: accountName, protocolString: protocolString), hasSession: hasSession)
    }
    
    /** Use this static function to create the info object for the "ME" tab */
    static func createInfo(_ account:OTRAccount,protocolString:String,otrKit:OTRKit,qrAction:((FingerprintCellInfo)->Void)?,shareAction:((FingerprintCellInfo)->Void)?) -> ZomProfileViewControllerInfo {
        
        let fingerprint = otrKit.fingerprint(forAccountName: account.username, protocol: protocolString)
        let displayName = account.displayName ?? account.username!
        let userCell = UserCellInfo(avatarImage: account.avatarImage(), title: displayName, subtitle: account.username)
        let passwordCellInfo = PasswordCellInfo(password:account.password)
        var sections = [TableSectionInfo(title: nil, cells: [userCell,passwordCellInfo])]
        if let fprint = fingerprint {
            let fingerprintSectionCells:[ZomProfileViewCellInfoProtocol] = [FingerprintCellInfo(fingerprint: fprint, qrAction: qrAction, shareAction: shareAction)]
            sections.append(TableSectionInfo(title: NSLocalizedString("Secure Identity", comment: "Table view section header"), cells: fingerprintSectionCells))
        }
        return ZomProfileViewControllerInfo(tableSections: sections, user: .account(account), otrKit: otrKit,otrKitInfo: zomOTRKitInfo(username: nil, accountName: account.username, protocolString: protocolString), hasSession: false)
    }
}


struct FingerprintCellInfo: ZomProfileViewCellInfoProtocol {
    
    let fingerprint:OTRFingerprint
    let qrAction:((_ info:FingerprintCellInfo)->Void)?
    let shareAction:((_ info:FingerprintCellInfo)->Void)?
    fileprivate let shareImage = UIImage(named: "OTRShareIcon", in: OTRAssets.resourcesBundle(), compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
    
    func configure(_ cell: UITableViewCell) {
        guard let fingerprintCell = cell as? ZomFingerprintCell else {
            return
        }
        fingerprintCell.shareButton.setImage(self.shareImage, for: UIControlState())
        fingerprintCell.qrButton.setImage(UIImage(named: "zom_qrcode_placeholder", in: OTRAssets.resourcesBundle(), compatibleWith: nil), for: UIControlState())
        fingerprintCell.fingerprintLabel.text = (fingerprint.fingerprint as NSData).humanReadableFingerprint()
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
        return 90
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
    
    let info:ZomProfileViewControllerInfo
    var controller:ZomProfileViewController
    var relaodData:(() -> Void)?
    
    init(info:ZomProfileViewControllerInfo, controller:ZomProfileViewController) {
        self.info = info
        self.controller = controller
    }
    
    //MARK: UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return info.tableSections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return info.tableSections[section].cells?.count ?? 0;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let object = info.infoAtIndexPath(indexPath) {
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
        return self.info.sectionAtIndex(section)?.title
    }
    
    //MARK: UITableviewDelegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.info.infoAtIndexPath(indexPath)?.cellHeight() ?? UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let object = self.info.infoAtIndexPath(indexPath) as? ButtonCellInfo  else {
            return
        }
        
        switch object.type {
        case let .verify(fingerprint):
            // Set active fingerprint as trusted
            fingerprint.trustLevel = .trustedUser
            OTRProtocolManager.sharedInstance().encryptionManager.save(fingerprint)
            self.relaodData?()
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
        }
    }
}

open class ZomProfileViewController : UIViewController {
    
    fileprivate var avatarPicker:OTRAttachmentPicker?
    fileprivate var readOnlyDatabaseConnection = OTRDatabaseManager.sharedInstance().longLivedReadOnlyConnection
    fileprivate var viewHandler:OTRYapViewHandler?
    
    let tableView = UITableView(frame: CGRect.zero, style: .grouped)
    fileprivate var tableViewSource:ZomProfileTableViewSource?
    var info:ZomProfileViewControllerInfo? {
        didSet {
            self.tableViewSource = ZomProfileTableViewSource(info: self.info!, controller: self)
            self.tableViewSource?.relaodData = {
                if let n = self.info {
                    switch n.user {
                    case let .buddy(buddy):
                        self.info = ZomProfileViewControllerInfo.createInfo(buddy, accountName: n.otrKitInfo.accountName, protocolString: n.otrKitInfo.protocolString, otrKit: n.otrKit,qrAction:self.qrAction, shareAction: self.shareAction, hasSession: n.hasSession)
                    case let .account(account):
                        self.info = ZomProfileViewControllerInfo.createInfo(account, protocolString: n.otrKitInfo.protocolString, otrKit: n.otrKit, qrAction: self.qrAction, shareAction: self.shareAction)
                    }
                }
            }
            self.tableView.delegate = self.tableViewSource
            self.tableView.dataSource = self.tableViewSource
            self.tableView.reloadData()
            
            if let yapKey = self.info?.user.yapKey(), let yapCollection = self.info?.user.yapCollection() {
                //TODO: Remove all previous key collection pairs
                self.viewHandler?.keyCollectionObserver.observe(yapKey, collection: yapCollection)
            }
        }
    }
    var qrAction:((FingerprintCellInfo) -> Void)?
    var shareAction:((FingerprintCellInfo) -> Void)?
    var passwordChangeDelegate:PasswordChangeTextFieldDelegate? = nil
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        qrAction = { [weak self] fingerprintInfo in
            
            
            guard let user = self?.info?.user else {
                return
            }
    
            ZomProfileViewControllerInfo.User.shareURL(user, fingerprint: (fingerprintInfo.fingerprint.fingerprint as NSData).humanReadableFingerprint() , completion: { (url) in
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
        
        shareAction = { [weak self] fingerprintInfo in
            guard let user = self?.info?.user else {
                return
            }
            
            ZomProfileViewControllerInfo.User.shareURL(user, fingerprint: nil, completion: { (url) in
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
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
        
        if let connection = self.readOnlyDatabaseConnection {
            self.viewHandler = OTRYapViewHandler(databaseConnection: connection, databaseChangeNotificationName: DatabaseNotificationName.LongLivedTransactionChanges)
            self.viewHandler?.delegate = self
        }
        
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.setStatusBarHidden(false, with: .none)
    }
    
    @IBAction func didPressChangePasswordButton(_ sender: UIButton) {
        let alert = UIAlertController(title: NSLocalizedString("Change password", comment: "Title for change password alert"), message: NSLocalizedString("Please enter your new password", comment: "Message for change password alert"), preferredStyle: UIAlertControllerStyle.alert)
        passwordChangeDelegate = PasswordChangeTextFieldDelegate(alert: alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK button"), style: UIAlertActionStyle.default, handler: {(action: UIAlertAction!) in
            if let user = self.info?.user {
                switch user {
                case let .account(account):
                    if let xmppManager = OTRProtocolManager.sharedInstance().protocol(for: account) as? OTRXMPPManager,
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
        
        func textFieldDidChange(_ textField: UITextField){
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
        if let user = self.info?.user {
            switch user {
            case .account(_):
                // Keep strong reference
                avatarPicker = OTRAttachmentPicker(parentViewController: self.tabBarController?.navigationController, delegate: self)
                avatarPicker!.showAlertController(completion: nil)
                break
            default:
                break
            }
        }
    }
    
    
}

extension ZomProfileViewController: OTRAttachmentPickerDelegate {
    public func attachmentPicker(_ attachmentPicker: OTRAttachmentPicker!, gotVideoURL videoURL: URL!) {
        
    }
    
    public func attachmentPicker(_ attachmentPicker: OTRAttachmentPicker!, gotPhoto photo: UIImage!, withInfo info: [AnyHashable: Any]!) {
        if let user = self.info?.user {
            switch user {
            case let .account(account):
                if let xmppManager = OTRProtocolManager.sharedInstance().protocol(for: account) as? OTRXMPPManager {
                    xmppManager.setAvatar(photo, completion: { [weak self] (success) in
                        self?.tableViewSource?.relaodData?()
                        })
                }
                break
            default:
                break
            }
        }
    }
    
    public func attachmentPicker(_ attachmentPicker: OTRAttachmentPicker!, preferredMediaTypesFor source: UIImagePickerControllerSourceType) -> [String]! {
        return [kUTTypeImage as String]
    }
}

extension ZomProfileViewController: OTRYapViewHandlerDelegateProtocol {
    public func didReceiveChanges(_ handler: OTRYapViewHandler, key: String, collection: String) {
        
        guard let info = self.info else {
            return
        }
        
        //The User object has changed. New info on the buddy and account
        var newObject:OTRYapDatabaseObject?
        self.readOnlyDatabaseConnection?.read { (transaction) in
            newObject = transaction.object(forKey: key, inCollection: collection) as? OTRYapDatabaseObject
        }
        
        switch newObject {
        case let account as OTRAccount:
            self.info = ZomProfileViewControllerInfo.createInfo(account, protocolString: account.protocolTypeString(), otrKit: info.otrKit, qrAction: self.qrAction, shareAction: self.shareAction)
            break
        case let buddy as OTRBuddy:
            var account:OTRAccount? = nil
            self.readOnlyDatabaseConnection?.read({ (transaction) in
                account = OTRAccount.fetch(withUniqueID: buddy.accountUniqueId, transaction: transaction)
            })
            if let account = account {
               self.info = ZomProfileViewControllerInfo.createInfo(buddy, accountName: account.username, protocolString: account.protocolTypeString(), otrKit: info.otrKit, qrAction: self.qrAction, shareAction: self.shareAction, hasSession: info.hasSession)
            }
            
            break
        default: break
        }
    }
}
