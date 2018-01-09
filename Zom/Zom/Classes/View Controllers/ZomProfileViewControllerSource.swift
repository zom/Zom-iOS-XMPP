//
//  ZomProfileViewControllerSource.swift
//  Zom
//
//  Created by David Chiles on 3/14/17.
//
//

import Foundation

/** Since a profile can be for a user or a buddy this contains some of those differences */
enum User {
    case buddy(OTRBuddy)
    case account(OTRAccount)
    
    //TODO: completion block should be removed once we can change account invite link to non-async
    static func shareURL(_ user:User,fingerprint:Fingerprint?,completion:@escaping (_ url:URL?)->Void) {
        switch user {
        case let .buddy(buddy) :
            let inviteURL = buddy.zom_inviteLink(fingerprint)
            completion(inviteURL)
            break
        case let .account(account):
            //TODO: Need to support OMEMO fingerprints
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
        return type(of: self.databaseObject()).collection
    }
}

struct ZomOTRKitInfo {
    /** The OTRKit username optional because accounts don't have a username just an account name */
    let username:String?
    let accountName:String
    let protocolString:String
}

protocol ZomProfileViewObserverDelegate:class {
    func didUpdateTableSections(observer:ZomProfileViewObserver) -> Void
}

class ZomProfileViewObserver: NSObject {
    
    let qrAction:((FingerprintCellInfo)->Void)?
    let shareAction:((FingerprintCellInfo)->Void)?
    
    weak var delegate:ZomProfileViewObserverDelegate? = nil
    
    fileprivate(set) var tableSections:[TableSectionInfo]?
    fileprivate(set) var info: ZomProfileViewControllerInfo
    
    fileprivate var readOnlyDatabaseConnection = OTRDatabaseManager.sharedInstance().longLivedReadOnlyConnection
    fileprivate var viewHandler:OTRYapViewHandler?
    var showAllFingerprints = false
    
    init(info:ZomProfileViewControllerInfo ,qrAction:((FingerprintCellInfo)->Void)?,shareAction:((FingerprintCellInfo)->Void)?) {
        self.info = info
        
        self.qrAction = qrAction
        self.shareAction = shareAction
        
        

        super.init()
        self.tableSections = self.generateSections(info: info, qrAction: qrAction, shareAction: shareAction)
        if let connection = self.readOnlyDatabaseConnection {
            self.viewHandler = OTRYapViewHandler(databaseConnection: connection, databaseChangeNotificationName: DatabaseNotificationName.LongLivedTransactionChanges)
            self.viewHandler?.delegate = self
        }
        self.viewHandler?.keyCollectionObserver.observe(info.user.yapKey(), collection: info.user.yapCollection())
    }
    
    func reloadInfo() {
        //The user object has changed so we to fetch it again and regenerate the tableview sections
        let key = self.info.user.yapKey()
        let collection = self.info.user.yapCollection()
        
        var newObject:OTRYapDatabaseObject?
        self.readOnlyDatabaseConnection?.read { (transaction) in
            newObject = transaction.object(forKey: key, inCollection: collection) as? OTRYapDatabaseObject
        }
        
        var usr:User? = nil
        switch newObject {
        case let account as OTRAccount:
            usr = .account(account)
            break
        case let buddy as OTRBuddy:
            usr = .buddy(buddy)
            break
        default:
            break
        }
        
        guard let user = usr else {
            return
        }
        
        self.info = ZomProfileViewControllerInfo(user: user, otrKit: self.info.otrKit, otrKitInfo: self.info.otrKitInfo, hasSession: self.info.hasSession, calledFromGroup: self.info.calledFromGroup, showAllFingerprints: self.showAllFingerprints)
        self.tableSections = self.generateSections(info: self.info, qrAction: self.qrAction, shareAction: self.shareAction)
        self.delegate?.didUpdateTableSections(observer: self)
    }
    
    
    func generateSections(info:ZomProfileViewControllerInfo, qrAction:((FingerprintCellInfo)->Void)?,shareAction:((FingerprintCellInfo)->Void)?) -> [TableSectionInfo] {
        
        var allOMEMODevices:[Fingerprint]? = nil
        self.readOnlyDatabaseConnection?.read({ (transaction) in
            allOMEMODevices = OTROMEMODevice.allDevices(forParentKey: info.user.yapKey(), collection: info.user.yapCollection(), transaction: transaction).filter({ (device) -> Bool in
                return device.publicIdentityKeyData != nil
            }).map({ (device) -> Fingerprint in
                return .OMEMO(device)
            })
        })
        allOMEMODevices?.sort(by: { (o1, o2) -> Bool in
            return o1.lastSeen().compare(o2.lastSeen()) != ComparisonResult.orderedAscending
        })
        
        var sections = [TableSectionInfo]()
        
        switch info.user {
        case .buddy(let buddy):
            let userCell = UserCellInfo(avatarImage: buddy.avatarImage, title: buddy.threadName, subtitle: buddy.username)
            var allFingerprints = info.otrKit.fingerprints(forUsername: buddy.username, accountName: info.otrKitInfo.accountName, protocol: info.otrKitInfo.protocolString).map({ (fingerprint) -> Fingerprint in
                return .OTR(fingerprint)
            })
            var mostRecent = allFingerprints.first
            if let devices = allOMEMODevices {
                allFingerprints += devices
                mostRecent = devices.first
            }
            
            // Show all, or just most recent
            var shownFingerprints:[Fingerprint] = []
            if info.showAllFingerprints {
                shownFingerprints.append(contentsOf: allFingerprints)
            } else if let mostRecent = mostRecent {
                shownFingerprints.append(mostRecent)
            }
            
            var fingerprintSectionCells = self.generateFingerprintCells(fingerprints: shownFingerprints)
            if !info.showAllFingerprints, allFingerprints.count > 1 {
                fingerprintSectionCells.append(ButtonCellInfo(type:.showMore(allFingerprints.count - 1)))
            }
            
            var cells:[ZomProfileViewCellInfoProtocol] = [userCell]
            if !info.calledFromGroup {
                cells.append((info.hasSession ? ButtonCellInfo(type:.refresh) : ButtonCellInfo(type:.startChat)))
            }
            sections += [TableSectionInfo(title: nil, cells: cells)]
            if (fingerprintSectionCells.count > 0 ) {
                sections.append(TableSectionInfo(title: NSLocalizedString("Secure Identity", comment: "Table view section header"), cells: fingerprintSectionCells))
            }
            
        case .account(let account):
            let displayName = account.displayName
            let userCell = UserCellInfo(avatarImage: account.avatarImage(), title: displayName, subtitle: account.username)
            let passwordCellInfo = PasswordCellInfo(password:account.password!)
            sections += [TableSectionInfo(title: nil, cells: [userCell,passwordCellInfo])]
            if let fingerprint = info.otrKit.fingerprint(forAccountName: account.username, protocol: info.otrKitInfo.protocolString) {
                
                var allFingerprints = [Fingerprint.OTR(fingerprint)]
                if let xmpp = OTRProtocolManager.sharedInstance().protocol(for: account) as? XMPPManager, let myBundle = xmpp.omemoSignalCoordinator?.fetchMyBundle(), var devices = allOMEMODevices {
                    let thisDevice = OTROMEMODevice(deviceId: NSNumber(value: myBundle.deviceId as UInt32), trustLevel: .trustedUser, parentKey: account.uniqueId, parentCollection: type(of: account).collection, publicIdentityKeyData: myBundle.identityKey, lastSeenDate: Date())
                    
                    devices = devices.filter({ (fingerprint) -> Bool in
                        switch fingerprint {
                        case .OMEMO(let device):
                            return device.deviceId != thisDevice.deviceId
                        default: return true
                        }
                    })
                    allFingerprints.append(.OMEMO(thisDevice))
                    allFingerprints += devices
                }
                
                // Show all, or just most recent
                var shownFingerprints:[Fingerprint] = []
                if info.showAllFingerprints {
                    shownFingerprints.append(contentsOf: allFingerprints)
                } else if let mostRecent = allFingerprints.first {
                    shownFingerprints.append(mostRecent)
                }
                
                var fingerprintSectionCells = self.generateFingerprintCells(fingerprints: shownFingerprints)
                if !info.showAllFingerprints, allFingerprints.count > 1 {
                    fingerprintSectionCells.append(ButtonCellInfo(type:.showMore(allFingerprints.count - 1)))
                }

                sections.append(TableSectionInfo(title: NSLocalizedString("Secure Identity", comment: "Table view section header"), cells: fingerprintSectionCells))
                
            }
            
        }
        return sections
    }
    
    func generateFingerprintCells(fingerprints:[Fingerprint]) -> [ZomProfileViewCellInfoProtocol] {
        return fingerprints.flatMap { (fingerprint) -> [ZomProfileViewCellInfoProtocol] in
            var result:[ZomProfileViewCellInfoProtocol] = [FingerprintCellInfo(fingerprint: fingerprint, qrAction: qrAction, shareAction: shareAction, showLastSeen: showAllFingerprints)]
            if (!fingerprint.isTrusted()) {
                switch fingerprint {
                case.OMEMO(let device):
                    result.append(ButtonCellInfo(type: ButtonCellInfo.ButtonCellType.omemoVerify(device)))
                    break
                case.OTR(let fingerprint):
                    result.append(ButtonCellInfo(type: ButtonCellInfo.ButtonCellType.otrVerify(fingerprint)))
                    break
                }
                
            }
            return result
        }
    }
    
}

extension ZomProfileViewObserver: OTRYapViewHandlerDelegateProtocol {
    func didReceiveChanges(_ handler: OTRYapViewHandler, key: String, collection: String) {
        
        self.reloadInfo()
    }
}

/** This contains all the information necessary to build the ZomProfileViewController */
struct ZomProfileViewControllerInfo {
    
    
    /** The sections of table view which contain the rows */
    
    let user:User
    let otrKit:OTRKit
    let otrKitInfo:ZomOTRKitInfo
    let hasSession:Bool
    let calledFromGroup:Bool
    var showAllFingerprints:Bool
    
    /** use this static function to create the info object for a buddy */
    static func createInfo(_ buddy:OTRBuddy,accountName:String,protocolString:String,otrKit:OTRKit,hasSession:Bool,calledFromGroup:Bool,showAllFingerprints:Bool) -> ZomProfileViewControllerInfo {
        return ZomProfileViewControllerInfo(user: .buddy(buddy), otrKit: otrKit,otrKitInfo: ZomOTRKitInfo(username: buddy.username, accountName: accountName, protocolString: protocolString), hasSession: hasSession, calledFromGroup: calledFromGroup, showAllFingerprints: showAllFingerprints)
    }
    
    /** Use this static function to create the info object for the "ME" tab */
    static func createInfo(_ account:OTRAccount,protocolString:String,otrKit:OTRKit) -> ZomProfileViewControllerInfo {
        return ZomProfileViewControllerInfo(user: .account(account), otrKit: otrKit,otrKitInfo: ZomOTRKitInfo(username: nil, accountName: account.username, protocolString: protocolString), hasSession: false, calledFromGroup: false, showAllFingerprints: false)
    }
}
