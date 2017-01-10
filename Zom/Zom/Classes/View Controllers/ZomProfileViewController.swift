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

extension OTRBuddy {
    func zom_inviteLink(otrFingerprint:String?) -> NSURL {
        
        var fingerprints = [String:String]()
        if let otrFprint = otrFingerprint {
            fingerprints[OTRAccount.fingerprintStringTypeForFingerprintType(.OTR)] = otrFprint
        }
        
        return NSURL.otr_shareLink(NSURL.otr_shareBaseURL().absoluteString!, username: self.username, fingerprints: fingerprints)
    }
}

/** All the idenitifiers for each cell that is possible in a ProfileViewController */
internal enum ZomProfileViewCellIdentifier:String {
    case ProfileCell = "ProfileCell"
    case FingerprintCell = "FingerprintCell"
    case ButtonCell = "ButtonCell"
    case PasswordCell = "PasswordCell"
    
    static let allValues = [ProfileCell,FingerprintCell,ButtonCell,PasswordCell]
    
    enum ClassOrNib {
        case Nib(UINib)
        case Class(AnyClass)
    }
    
    /** Get the cell class or nib depending on the identifier type */
    static func classOrNib(identifier:ZomProfileViewCellIdentifier) -> ClassOrNib {
        let resourceBundle = OTRAssets.resourcesBundle()
        switch identifier {
        case .ProfileCell :
            return .Nib(UINib(nibName: "ZomUserInfoProfileCell", bundle: resourceBundle))
        case FingerprintCell:
            return .Nib(UINib(nibName: "ZomFingerprintCell", bundle: resourceBundle))
        case PasswordCell :
            return .Nib(UINib(nibName: "ZomPasswordCell", bundle: resourceBundle))
        case .ButtonCell:
            return .Class(UITableViewCell.self)
        }
    }
}

/** 
 This protocol defines the funtion for any cell info struct/object.
 The Cell info should contain all the data necesssary to build the UITableViewCell of its type.
 */
protocol ZomProfileViewCellInfoProtocol {
    
    /** 
     Called from `func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell`.
     */
    func configure(cell:UITableViewCell)
    
    /** The cell type for this cell info */
    func cellIdentifier() -> ZomProfileViewCellIdentifier
    
    /** The cell height. If nil then UITableViewAutomaticDimension is used */
    func cellHeight() -> CGFloat?
}

/** This contains all teh information necessary to build the ZomProfileViewController */
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

/** This struct contains all the information for a table section  */
struct TableSectionInfo {
    /** The title of the section */
    let title:String?
    /** The cells in the section */
    let cells:[ZomProfileViewCellInfoProtocol]?
}

/** Contains all the information necessary to render the user cell */
struct UserCellInfo: ZomProfileViewCellInfoProtocol {
    
    let avatarImage:UIImage?
    let title:String
    let subtitle:String?
    
    static let kCellHeight:CGFloat = 90
    
    func configure(cell: UITableViewCell) {
        guard let userCell = cell as? ZomUserInfoProfileCell else {
            return
        }
        
        userCell.displayNameLabel.text = self.title
        userCell.usernameLabel.text = self.subtitle
        userCell.avatarImageView.image = self.avatarImage
        userCell.avatarImageView.layer.cornerRadius = CGRectGetWidth(userCell.avatarImageView.frame)/2;
        userCell.avatarImageView.clipsToBounds = true;
        userCell.selectionStyle = .None
    }
    
    func cellIdentifier() -> ZomProfileViewCellIdentifier {
        return .ProfileCell
    }
    
    func cellHeight() -> CGFloat? {
        return UserCellInfo.kCellHeight
    }
}

struct FingerprintCellInfo: ZomProfileViewCellInfoProtocol {
    
    let fingerprint:String
    let qrAction:((info:FingerprintCellInfo)->Void)?
    let shareAction:((info:FingerprintCellInfo)->Void)?
    private let shareImage = UIImage(named: "OTRShareIcon", inBundle: OTRAssets.resourcesBundle(), compatibleWithTraitCollection: nil)?.imageWithRenderingMode(.AlwaysTemplate)
    
    func configure(cell: UITableViewCell) {
        guard let fingerprintCell = cell as? ZomFingerprintCell else {
            return
        }
        fingerprintCell.shareButton.setImage(self.shareImage, forState: .Normal)
        fingerprintCell.qrButton.setImage(UIImage(named: "zom_qrcode_placeholder", inBundle: OTRAssets.resourcesBundle(), compatibleWithTraitCollection: nil), forState: .Normal)
        fingerprintCell.fingerprintLabel.text = fingerprint
        fingerprintCell.qrAction = {cell in
            if let action = self.qrAction {
                action(info:self)
            }
        }
        fingerprintCell.shareAction = {cell in
            if let action = self.shareAction {
                action(info:self)
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

struct ButtonCellInfo: ZomProfileViewCellInfoProtocol {
    
    enum ButtonCellType {
        case Verify
        case Refresh
        case StartChat
        
        func text() -> String {
            switch self {
            case .Verify : return NSLocalizedString("Verify Contact", comment: "Button label to verify contact security")
            case .Refresh: return NSLocalizedString("Refresh Session", comment: "Button label to refresh an OTR session")
            case .StartChat: return NSLocalizedString("Start Chat", comment: "Button label to start a chat")
            }
        }
    }
    
    let type:ButtonCellType
    
    func configure(cell:UITableViewCell) {
        cell.textLabel?.text = self.type.text()
        cell.textLabel?.textColor = UIButton(type: .System).titleColorForState(.Normal)
    }
    func cellIdentifier() -> ZomProfileViewCellIdentifier {
        return .ButtonCell
    }
    func cellHeight() -> CGFloat? {
        return nil
    }
}

struct PasswordCellInfo: ZomProfileViewCellInfoProtocol {
    let password:String
    
    func configure(cell: UITableViewCell) {
        guard let passwordCell = cell as? ZomPasswordCell else {
            return
        }
        passwordCell.passwordTextField.text = self.password
        
        passwordCell.changeButton.titleLabel?.font = UIFont(name: "FontAwesome", size: 30)
        passwordCell.changeButton.setTitle(NSString.fa_stringForFontAwesomeIcon(.FAEdit), forState: UIControlState.Normal)
        passwordCell.revealButton.titleLabel?.font = UIFont(name: "FontAwesome", size: 30)
        passwordCell.revealButton.setTitle(NSString.fa_stringForFontAwesomeIcon(.FAEye), forState: UIControlState.Normal)
        passwordCell.selectionStyle = .None
    }
    
    func cellIdentifier() -> ZomProfileViewCellIdentifier {
        return .PasswordCell
    }
    
    func cellHeight() -> CGFloat? {
        return nil
    }
}

class ZomProfileTableViewSource:NSObject, UITableViewDataSource, UITableViewDelegate {
    
    var info:ZomProfileViewControllerInfo
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

class ZomProfileViewController : UIViewController {
    
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
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
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
    }
    
    @IBAction func didPressChangePasswordButton(sender: UIButton) {
        let alert = UIAlertController(title: NSLocalizedString("Change password", comment: "Title for change password alert"), message: NSLocalizedString("Please enter your new password", comment: "Message for change password alert"), preferredStyle: UIAlertControllerStyle.Alert)
        passwordChangeDelegate = PasswordChangeTextFieldDelegate(alert: alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK button"), style: UIAlertActionStyle.Default, handler: {(action: UIAlertAction!) in
            if let user = self.info?.user {
                switch user {
                case let .Account(account):
                    if let xmppManager = OTRProtocolManager.sharedInstance().protocolForAccount(account) {
                        print("Ok, got the manager. Now what? I'd like to cast this to a OTRXMPPManager and get xmppStream.")
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
            let tf1:UITextField = alert.textFields![0]
            let tf2:UITextField = alert.textFields![1]
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
    
}
