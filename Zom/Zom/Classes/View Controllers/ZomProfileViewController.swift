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

internal enum ZomProfileViewCellIdentifier:String {
    case ProfileCell = "ProfileCell"
    case FingerprintCell = "FingerprintCell"
    case ButtonCell = "ButtonCell"
    
    static let allValues = [ProfileCell,FingerprintCell,ButtonCell]
    
    func cellNib() -> UINib? {
        let resourceBundle = OTRAssets.resourcesBundle()
        switch self {
        case .ProfileCell :
            return UINib(nibName: "ZomUserInfoProfileCell", bundle: resourceBundle)
        case FingerprintCell:
            return UINib(nibName: "ZomFingerprintCell", bundle: resourceBundle)
        default:
            return nil
        }
    }
    
    func cellClass() -> AnyClass? {
        switch self {
        case .ButtonCell:
            return UITableViewCell.self
        default:
            return nil
        }
    }
        
}

protocol ZomProfileViewCellInfoProtocol {
    
    func configure(cell:UITableViewCell)
    func cellIdentifier() -> ZomProfileViewCellIdentifier
    func cellHeight() -> CGFloat?
}

/**  */
struct ZomProfileViewControllerInfo {
    
    struct zomOTRKitInfo {
        let username:String
        let accountName:String
        let protocolString:String
    }
    
    let tableSections:[TableSectionInfo]
    let buddy:OTRBuddy
    let otrKit:OTRKit
    let otrKitInfo:zomOTRKitInfo

    
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
    static func createInfo(buddy:OTRBuddy,accountName:String,protocolString:String,otrKit:OTRKit,qrAction:((FingerprintCellInfo)->Void)?,shareAction:((FingerprintCellInfo)->Void)?, completion:(ZomProfileViewControllerInfo)->Void) {
        
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
                
                
                var sections = [TableSectionInfo(title: nil, cells: [userCell,ButtonCellInfo(type:.Refresh)])]
                if (fingerprintSectionCells?.count > 0 ) {
                    sections.append(TableSectionInfo(title: NSLocalizedString("Secure Identity", comment: "Table view section header"), cells: fingerprintSectionCells))
                }
                let profileInfo = ZomProfileViewControllerInfo(tableSections: sections,buddy: buddy, otrKit: otrKit,otrKitInfo: zomOTRKitInfo(username: buddy.username, accountName: accountName, protocolString: protocolString))
                completion(profileInfo)
                
            })
        }
    }
    
    /** use this static function to create the info object for a buddy */
    static func createInfo(account:OTRAccount,protocolString:String,otrKit:OTRKit,qrAction:((FingerprintCellInfo)->Void)?,shareAction:((FingerprintCellInfo)->Void)?, completion:(ZomProfileViewControllerInfo)->Void) {

        if let appDelegate = UIApplication.sharedApplication().delegate as? ZomAppDelegate {
            let account:OTRAccount = appDelegate.getDefaultAccount()
            OTRDatabaseManager.sharedInstance().readWriteDatabaseConnection.readWriteWithBlock { (transaction) in
                if let buddy = OTRXMPPBuddy.fetchBuddyWithUsername(account.username, withAccountUniqueId: account.uniqueId, transaction: transaction) {
                    let userCell = UserCellInfo(avatarImage: buddy.avatarImage(), title: buddy.threadName(), subtitle: buddy.username)
                    
                    //Once all fingerprints works in later (already exists in later OTRKit commit. Move to fetching all fingerprints
                    otrKit.activeFingerprintForUsername(buddy.username, accountName: account.username, protocol: protocolString) { (fingerprint) in
                        otrKit.activeFingerprintIsVerifiedForUsername(buddy.username, accountName: account.username, protocol: protocolString, completion: { (verified) in
                            var fingerprintSectionCells:[ZomProfileViewCellInfoProtocol]? = nil
                            if let fprint = fingerprint {
                                
                                fingerprintSectionCells = [FingerprintCellInfo(fingerprint: fprint,qrAction: qrAction, shareAction: shareAction)]
                                if (!verified) {
                                    fingerprintSectionCells?.append(ButtonCellInfo(type:.Verify))
                                }
                            }
                            
                            var sections = [TableSectionInfo(title: nil, cells: [userCell])]
                            if (fingerprintSectionCells?.count > 0 ) {
                                sections.append(TableSectionInfo(title: NSLocalizedString("Secure Identity", comment: "Table view section header"), cells: fingerprintSectionCells))
                            }
                            let profileInfo = ZomProfileViewControllerInfo(tableSections: sections,buddy: buddy, otrKit: otrKit,otrKitInfo: zomOTRKitInfo(username: buddy.username, accountName: account.username, protocolString: protocolString))
                            completion(profileInfo)
                            
                        })
                    }

                }
            }
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
        
        func text() -> String {
            switch self {
            case .Verify : return NSLocalizedString("Verify Contact", comment: "Button label to verify contact security")
            case .Refresh: return NSLocalizedString("Refresh Session", comment: "Button labe to refresh an OTR session")
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

class ZomProfileTableViewSource:NSObject, UITableViewDataSource, UITableViewDelegate {
    
    var info:ZomProfileViewControllerInfo
    var relaodData:(() -> Void)?
    
    init(info:ZomProfileViewControllerInfo) {
        self.info = info
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
            self.tableViewSource = ZomProfileTableViewSource(info: self.info!)
            self.tableViewSource?.relaodData = {
                if let n = self.info {
                    ZomProfileViewControllerInfo.createInfo(n.buddy, accountName: n.otrKitInfo.accountName, protocolString: n.otrKitInfo.protocolString, otrKit: n.otrKit,qrAction:self.qrAction, shareAction: self.shareAction, completion: { (newInfo) in
                        // Set the new info
                        self.info = newInfo
                    })
                }
                
            }
            self.tableView.delegate = self.tableViewSource
            self.tableView.dataSource = self.tableViewSource
            self.tableView.reloadData()
        }
    }
    var qrAction:((FingerprintCellInfo) -> Void)?
    var shareAction:((FingerprintCellInfo) -> Void)?
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        qrAction = { [weak self] fingerprintInfo in
            guard let buddy = self?.info?.buddy else  {
                return
            }
            let inviteURL = buddy.zom_inviteLink(fingerprintInfo.fingerprint)
            let qrViewController = OTRQRCodeViewController(QRString: inviteURL.absoluteString)
            let navigationController = UINavigationController(rootViewController: qrViewController)
            self?.presentViewController(navigationController, animated: true, completion: nil)
        }
        
        shareAction = { [weak self] fingerprintInfo in
            guard let buddy = self?.info?.buddy else  {
                return
            }
            let inviteURL = buddy.zom_inviteLink(fingerprintInfo.fingerprint)
            let activityViewController = UIActivityViewController(activityItems: [inviteURL], applicationActivities: nil)
            if let view = self?.view {
                activityViewController.popoverPresentationController?.sourceView = view;
                activityViewController.popoverPresentationController?.sourceRect = view.bounds;
            }
            
            self?.presentViewController(activityViewController, animated: true, completion: nil)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        
        ZomProfileViewCellIdentifier.allValues.forEach { (cellIdentifier) in
            if let nib = cellIdentifier.cellNib() {
                self.tableView.registerNib(nib, forCellReuseIdentifier: cellIdentifier.rawValue)
            } else if let cellClass = cellIdentifier.cellClass() {
                self.tableView.registerClass(cellClass, forCellReuseIdentifier: cellIdentifier.rawValue)
            }
        }
        
        self.view.addSubview(self.tableView)
        self.tableView.autoPinEdgesToSuperviewEdges()
        
    }
}
