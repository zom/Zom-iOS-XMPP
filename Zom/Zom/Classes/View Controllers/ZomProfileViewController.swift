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

extension OTRBuddy {
    func zom_inviteLink(otrFingerprint:String?) -> NSURL {
        
        var fingerprints = [String:String]()
        if let otrFprint = otrFingerprint {
            fingerprints[OTRAccount.fingerprintStringTypeForFingerprintType(.OTR)] = otrFprint
        }
        
        return NSURL.otr_shareLink(NSURL.otr_shareBaseURL().absoluteString!, username: self.username, fingerprints: fingerprints)
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
        case Buddy(OTRBuddy)
        case Account(OTRAccount)
        
        //TODO: completion block should be removed once we can change account invite link to non-async
        static func shareURL(user:User,fingerprint:String?,completion:(url:NSURL?)->Void) {
            switch user {
            case let .Buddy(buddy) :
                let inviteURL = buddy.zom_inviteLink(fingerprint)
                completion(url:inviteURL)
            case let .Account(account):
                let fingerprints = Set(arrayLiteral: NSNumber(int: OTRFingerprintType.OTR.rawValue))
                account.generateShareURLWithFingerprintTypes(fingerprints, completion: { (url, error) in
                    completion(url: url)
                })
                return
            }
        }
        
        func databaseObject() -> OTRYapDatabaseObject {
            switch self {
            case Buddy(let buddy): return buddy
            case Account(let account): return account
            }
        }
        
        func yapKey() -> String {
            return self.databaseObject().uniqueId
        }
        func yapCollection() -> String {
            return self.databaseObject().dynamicType.collection()
        }
    }
    
    /** The sections of table view which contain the rows */
    let tableSections:[TableSectionInfo]
    let user:User
    let otrKit:OTRKit
    let otrKitInfo:zomOTRKitInfo
    let hasSession:Bool
    
    /** Fetch the row info at a given indexpath */
    func infoAtIndexPath(indexPath:NSIndexPath) -> ZomProfileViewCellInfoProtocol? {
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
    
    func sectionAtIndex(index:Int) -> TableSectionInfo? {
        if (self.tableSections.indices.contains(index)) {
           return self.tableSections[index]
        }
        return nil
    }
    
    /** use this static function to create the info object for a buddy */
    static func createInfo(buddy:OTRBuddy,accountName:String,protocolString:String,otrKit:OTRKit,qrAction:((FingerprintCellInfo)->Void)?,shareAction:((FingerprintCellInfo)->Void)?,hasSession:Bool,completion:(ZomProfileViewControllerInfo)->Void) {
        
        let userCell = UserCellInfo(avatarImage: buddy.avatarImage(), title: buddy.threadName(), subtitle: buddy.username)
        
        
        
        //Once all fingerprints works in later (already exists in later OTRKit commit. Move to fetching all fingerprints
        otrKit.activeFingerprintForUsername(buddy.username, accountName: accountName, protocol: protocolString) { (fingerprint) in
            otrKit.activeFingerprintIsVerifiedForUsername(buddy.username, accountName: accountName, protocol: protocolString, completion: { (verified) in
                var fingerprintSectionCells:[ZomProfileViewCellInfoProtocol]? = nil
                if let fprint = fingerprint {
                    
                    fingerprintSectionCells = [FingerprintCellInfo(fingerprint: fprint,qrAction: qrAction, shareAction: shareAction)]
                    if (!verified) {
                        fingerprintSectionCells?.append(ButtonCellInfo(type:.Verify))
                    }
                }
                
                
                var sections = [TableSectionInfo(title: nil, cells: [userCell,(hasSession ? ButtonCellInfo(type:.Refresh) : ButtonCellInfo(type:.StartChat))])]
                if (fingerprintSectionCells?.count > 0 ) {
                    sections.append(TableSectionInfo(title: NSLocalizedString("Secure Identity", comment: "Table view section header"), cells: fingerprintSectionCells))
                }
                let profileInfo = ZomProfileViewControllerInfo(tableSections: sections,user: .Buddy(buddy), otrKit: otrKit,otrKitInfo: zomOTRKitInfo(username: buddy.username, accountName: accountName, protocolString: protocolString), hasSession: hasSession)
                completion(profileInfo)
                
            })
        }
    }
    
    /** Use this static function to create the info object for the "ME" tab */
    static func createInfo(account:OTRAccount,protocolString:String,otrKit:OTRKit,qrAction:((FingerprintCellInfo)->Void)?,shareAction:((FingerprintCellInfo)->Void)?, completion:(ZomProfileViewControllerInfo)->Void) {
        
        otrKit.fingerprintForAccountName(account.username, protocol: protocolString) { (fingerprint) in
            let displayName = account.displayName ?? account.username!
            let userCell = UserCellInfo(avatarImage: account.avatarImage(), title: displayName, subtitle: account.username)
            let passwordCellInfo = PasswordCellInfo(password:account.password)
            var sections = [TableSectionInfo(title: nil, cells: [userCell,passwordCellInfo])]
            if let fprint = fingerprint {
                let fingerprintSectionCells:[ZomProfileViewCellInfoProtocol] = [FingerprintCellInfo(fingerprint: fprint, qrAction: qrAction, shareAction: shareAction)]
                sections.append(TableSectionInfo(title: NSLocalizedString("Secure Identity", comment: "Table view section header"), cells: fingerprintSectionCells))
            }
            let profileInfo = ZomProfileViewControllerInfo(tableSections: sections, user: .Account(account), otrKit: otrKit,otrKitInfo: zomOTRKitInfo(username: nil, accountName: account.username, protocolString: protocolString), hasSession: false)
            completion(profileInfo)
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
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return info.tableSections.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return info.tableSections[section].cells?.count ?? 0;
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let object = info.infoAtIndexPath(indexPath) {
            let cell = tableView.dequeueReusableCellWithIdentifier(object.cellIdentifier().rawValue, forIndexPath: indexPath)
            // Lay it out
            cell.setNeedsUpdateConstraints()
            cell.updateConstraintsIfNeeded()
            cell.setNeedsLayout()
            cell.layoutIfNeeded()
            object.configure(cell)
            return cell
        }
        
        //This should never happen
        return tableView.dequeueReusableCellWithIdentifier("", forIndexPath: indexPath)
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.info.sectionAtIndex(section)?.title
    }
    
    //MARK: UITableviewDelegate
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return self.info.infoAtIndexPath(indexPath)?.cellHeight() ?? UITableViewAutomaticDimension
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        guard let object = self.info.infoAtIndexPath(indexPath) else {
            return
        }
        
        switch object {
        case let buttonCellInfo as ButtonCellInfo where buttonCellInfo.type == .Verify:
            //TODO: Once OTRKit is updated this needs to verify the specific fingerprint
            // Set active fingerprint as trusted
            self.info.otrKit.setActiveFingerprintVerificationForUsername(self.info.otrKitInfo.username, accountName: self.info.otrKitInfo.accountName, protocol: self.info.otrKitInfo.protocolString, verified: true) {
                    self.relaodData?()
                }
            break
         case let buttonCellInfo as ButtonCellInfo where buttonCellInfo.type == .Refresh:
            //TODO: We should at some point listen for encryption change notification to refresh the table view with new fingerprint informatoin
            self.info.otrKit.initiateEncryptionWithUsername(self.info.otrKitInfo.username, accountName: self.info.otrKitInfo.accountName, protocol: self.info.otrKitInfo.protocolString)
            break
        case let buttonCellInfo as ButtonCellInfo where buttonCellInfo.type == .StartChat:
            //TODO: We should at some point listen for encryption change notification to refresh the table view with new fingerprint informatoin
            // TODO: close and start chat! Possibly via
            if let appDelegate = UIApplication.sharedApplication().delegate as? ZomAppDelegate {
                switch self.info.user {
                case let .Buddy(buddy) :
                    controller.navigationController?.popViewControllerAnimated(true)
                    appDelegate.splitViewCoordinator.enterConversationWithBuddy(buddy.uniqueId)
                default:
                    return
                }
            }
            break
        default:
            break
        }
    }
}

public class ZomProfileViewController : UIViewController {
    
    private var avatarPicker:OTRAttachmentPicker?
    //FIXME: After big merge should use shared read-only connection
    private var readOnlyDatabaseConnection:YapDatabaseConnection = OTRDatabaseManager.sharedInstance().newConnection()
    private var viewHandler:OTRYapViewHandler?
    
    let tableView = UITableView(frame: CGRectZero, style: .Grouped)
    private var tableViewSource:ZomProfileTableViewSource?
    var info:ZomProfileViewControllerInfo? {
        didSet {
            self.tableViewSource = ZomProfileTableViewSource(info: self.info!, controller: self)
            self.tableViewSource?.relaodData = {
                if let n = self.info {
                    switch n.user {
                    case let .Buddy(buddy):
                        ZomProfileViewControllerInfo.createInfo(buddy, accountName: n.otrKitInfo.accountName, protocolString: n.otrKitInfo.protocolString, otrKit: n.otrKit,qrAction:self.qrAction, shareAction: self.shareAction, hasSession: n.hasSession, completion: { (newInfo) in
                            // Set the new info
                            self.info = newInfo
                        })
                    case let .Account(account):
                        ZomProfileViewControllerInfo.createInfo(account, protocolString: n.otrKitInfo.protocolString, otrKit: n.otrKit, qrAction: self.qrAction, shareAction: self.shareAction, completion: { (newInfo) in
                            self.info = newInfo
                        })
                    }
                }
            }
            self.tableView.delegate = self.tableViewSource
            self.tableView.dataSource = self.tableViewSource
            self.tableView.reloadData()
            
            if let yapKey = self.info?.user.yapKey(), yapCollection = self.info?.user.yapCollection() {
                //TODO: Remove all previous key collection pairs
                self.viewHandler?.keyCollectionObserver.observe(yapKey, collection: yapCollection)
            }
        }
    }
    var qrAction:((FingerprintCellInfo) -> Void)?
    var shareAction:((FingerprintCellInfo) -> Void)?
    var passwordChangeDelegate:PasswordChangeTextFieldDelegate? = nil
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        qrAction = { [weak self] fingerprintInfo in
            
            
            guard let user = self?.info?.user else {
                return
            }
    
            ZomProfileViewControllerInfo.User.shareURL(user, fingerprint: fingerprintInfo.fingerprint, completion: { (url) in
                guard let inviteURL = url else {
                    return
                }
                let qrViewController = OTRQRCodeViewController(QRString: inviteURL.absoluteString)
                let navigationController = UINavigationController(rootViewController: qrViewController)
                self?.presentViewController(navigationController, animated: true, completion: nil)
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
                
                self?.presentViewController(activityViewController, animated: true, completion: nil)
            })
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        
        ZomProfileViewCellIdentifier.allValues.forEach { (cellIdentifier) in
            switch ZomProfileViewCellIdentifier.classOrNib(cellIdentifier) {
                case let .Class(cellClass) :
                self.tableView.registerClass(cellClass, forCellReuseIdentifier: cellIdentifier.rawValue)
                break
                case let .Nib(cellNib):
                self.tableView.registerNib(cellNib, forCellReuseIdentifier: cellIdentifier.rawValue)
                break
            }
        }
        
        self.view.addSubview(self.tableView)
        self.tableView.autoPinEdgesToSuperviewEdges()
        
        self.viewHandler = OTRYapViewHandler(databaseConnection: self.readOnlyDatabaseConnection)
        self.viewHandler?.delegate = self
    }
    
    @IBAction func didPressChangePasswordButton(sender: UIButton) {
        let alert = UIAlertController(title: NSLocalizedString("Change password", comment: "Title for change password alert"), message: NSLocalizedString("Please enter your new password", comment: "Message for change password alert"), preferredStyle: UIAlertControllerStyle.Alert)
        passwordChangeDelegate = PasswordChangeTextFieldDelegate(alert: alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK button"), style: UIAlertActionStyle.Default, handler: {(action: UIAlertAction!) in
            if let user = self.info?.user {
                switch user {
                case let .Account(account):
                    if let xmppManager = OTRProtocolManager.sharedInstance().protocolForAccount(account) as? OTRXMPPManager,
                        newPassword = alert.textFields?.first?.text {
                        xmppManager.changePassword(newPassword, completion: { (success, error) in
                            dispatch_async(dispatch_get_main_queue(), { 
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
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel button"), style: UIAlertActionStyle.Cancel, handler: nil))
        alert.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
            textField.placeholder = NSLocalizedString("Password:", comment: "Prompt for new password")
            textField.secureTextEntry = true
            textField.addTarget(self.passwordChangeDelegate, action: #selector(PasswordChangeTextFieldDelegate.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        })
        alert.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
            textField.placeholder = NSLocalizedString("Confirm New Password", comment: "Prompt for confirm password")
            textField.secureTextEntry = true
            textField.addTarget(self.passwordChangeDelegate, action: #selector(PasswordChangeTextFieldDelegate.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        })
        alert.actions[0].enabled = false
        self.presentViewController(alert, animated: true, completion: nil)
    }

    class PasswordChangeTextFieldDelegate: NSObject, UITextFieldDelegate {
        var alert:UIAlertController
        
        func textFieldDidChange(textField: UITextField){
            guard let tf1 = alert.textFields?[0] else {
                return
            }
            guard let tf2 = alert.textFields?[1] else {
                return
            }
            if (tf1.text?.characters.count > 0 && tf2.text?.characters.count > 0 &&
                tf1.text!.compare(tf2.text!) == NSComparisonResult.OrderedSame) {
                alert.actions[0].enabled = true
            } else {
                alert.actions[0].enabled = false
            }
        }
        
        init(
            alert:UIAlertController
            ) {
            self.alert = alert
        }
    }
    
    @IBAction func didTapAvatarImageWithSender(sender: UIButton) {
        if let user = self.info?.user {
            switch user {
            case .Account(_):
                // Keep strong reference
                avatarPicker = OTRAttachmentPicker(parentViewController: self.tabBarController?.navigationController, delegate: self)
                avatarPicker!.showAlertControllerWithCompletion(nil)
                break
            default:
                break
            }
        }
    }
    
    
}

extension ZomProfileViewController: OTRAttachmentPickerDelegate {
    public func attachmentPicker(attachmentPicker: OTRAttachmentPicker!, gotVideoURL videoURL: NSURL!) {
        
    }
    
    public func attachmentPicker(attachmentPicker: OTRAttachmentPicker!, gotPhoto photo: UIImage!, withInfo info: [NSObject : AnyObject]!) {
        if let user = self.info?.user {
            switch user {
            case let .Account(account):
                if let xmppManager = OTRProtocolManager.sharedInstance().protocolForAccount(account) as? OTRXMPPManager {
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
    
    public func attachmentPicker(attachmentPicker: OTRAttachmentPicker!, preferredMediaTypesForSource source: UIImagePickerControllerSourceType) -> [String]! {
        return [kUTTypeImage as String]
    }
}

extension ZomProfileViewController: OTRYapViewHandlerDelegateProtocol {
    public func didReceiveChanges(handler: OTRYapViewHandler, key: String, collection: String) {
        
        guard let info = self.info else {
            return
        }
        
        //The User object has changed. New info on the buddy and account
        var newObject:OTRYapDatabaseObject?
        self.readOnlyDatabaseConnection.readWithBlock { (transaction) in
            newObject = transaction.objectForKey(key, inCollection: collection) as? OTRYapDatabaseObject
        }
        
        switch newObject {
        case let account as OTRAccount:
            ZomProfileViewControllerInfo.createInfo(account, protocolString: account.protocolTypeString(), otrKit: info.otrKit, qrAction: self.qrAction, shareAction: self.shareAction, completion: { (newInfo) in
                self.info = newInfo
            })
            break
        case let buddy as OTRBuddy:
            var account:OTRAccount? = nil
            self.readOnlyDatabaseConnection.readWithBlock({ (transaction) in
                account = OTRAccount.fetchObjectWithUniqueID(buddy.accountUniqueId, transaction: transaction)
            })
            if let account = account {
                ZomProfileViewControllerInfo.createInfo(buddy, accountName: account.username, protocolString: account.protocolTypeString(), otrKit: info.otrKit, qrAction: self.qrAction, shareAction: self.shareAction, hasSession: info.hasSession , completion: { (newInfo) in
                    self.info
                })
            }
            
            break
        default: break
        }
    }
}
