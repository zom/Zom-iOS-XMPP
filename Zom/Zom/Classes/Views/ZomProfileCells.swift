//
//  ZomProfileCells.swift
//  Zom
//
//  Created by David Chiles on 1/26/17.
//
//

import Foundation


/** All the idenitifiers for each cell that is possible in a ProfileViewController */
internal enum ZomProfileViewCellIdentifier:String {
    case ProfileCell = "ProfileCell"
    case FingerprintCell = "FingerprintCell"
    case ButtonCell = "ButtonCell"
    case PasswordCell = "PasswordCell"
    
    static let allValues = [ProfileCell,FingerprintCell,ButtonCell,PasswordCell]
    
    enum ClassOrNib {
        case nib(UINib)
        case `class`(AnyClass)
    }
    
    /** Get the cell class or nib depending on the identifier type */
    static func classOrNib(_ identifier:ZomProfileViewCellIdentifier) -> ClassOrNib {
        let resourceBundle = OTRAssets.resourcesBundle
        switch identifier {
        case .ProfileCell :
            return .nib(UINib(nibName: "ZomUserInfoProfileCell", bundle: resourceBundle))
        case FingerprintCell:
            return .nib(UINib(nibName: "ZomFingerprintCell", bundle: resourceBundle))
        case PasswordCell :
            return .nib(UINib(nibName: "ZomPasswordCell", bundle: resourceBundle))
        case .ButtonCell:
            return .class(UITableViewCell.self)
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
    func configure(_ cell:UITableViewCell)
    
    /** The cell type for this cell info */
    func cellIdentifier() -> ZomProfileViewCellIdentifier
    
    /** The cell height. If nil then UITableViewAutomaticDimension is used */
    func cellHeight() -> CGFloat?
}

/** This struct contains all the information for a table section  */
struct TableSectionInfo {
    /** The title of the section */
    let title:String?
    /** The cells in the section */
    let cells:[ZomProfileViewCellInfoProtocol]?
}

//After swift 3.1 use `where Element == TableSectionInfo`
extension Array  {
    func sectionAtIndex(_ index:Int) -> Element? {
        if (self.indices.contains(index)) {
            return self[index]
        }
        return nil
    }
    
    /** Fetch the row info at a given indexpath */
    func infoAtIndexPath(_ indexPath:IndexPath) -> ZomProfileViewCellInfoProtocol? {
        let section = indexPath.section
        let row = indexPath.row
        
        if let sectionInfo = self.sectionAtIndex(section) as? TableSectionInfo {
            if let cells = sectionInfo.cells {
                if(cells.indices.contains(row)) {
                    return cells[row]
                }
            }
        }
        return nil
    }
}

/** Contains all the information necessary to render the user cell */
struct UserCellInfo: ZomProfileViewCellInfoProtocol {
    
    let avatarImage:UIImage?
    let title:String
    let subtitle:String?
    
    static let kCellHeight:CGFloat = 90
    
    func configure(_ cell: UITableViewCell) {
        guard let userCell = cell as? ZomUserInfoProfileCell else {
            return
        }
        
        userCell.displayNameLabel.text = self.title
        userCell.usernameLabel.text = self.subtitle
        userCell.avatarImageView.setImage(self.avatarImage, for: .normal)
        userCell.avatarImageView.layer.cornerRadius = userCell.avatarImageView.frame.width/2;
        userCell.avatarImageView.isUserInteractionEnabled = true
        userCell.avatarImageView.clipsToBounds = true;
        userCell.selectionStyle = .none
    }
    
    func cellIdentifier() -> ZomProfileViewCellIdentifier {
        return .ProfileCell
    }
    
    func cellHeight() -> CGFloat? {
        return UserCellInfo.kCellHeight
    }
}

struct ButtonCellInfo: ZomProfileViewCellInfoProtocol {
    
    enum ButtonCellType {
        case otrVerify(OTRFingerprint)
        case omemoVerify(OTROMEMODevice)
        case refresh
        case startChat
        case showMore(Int)
        
        func text() -> String {
            switch self {
            case .omemoVerify: fallthrough
            case .otrVerify : return NSLocalizedString("Verify Contact", comment: "Button label to verify contact security")
            case .refresh: return NSLocalizedString("Refresh Session", comment: "Button label to refresh an OTR session")
            case .startChat: return NSLocalizedString("Start Chat", comment: "Button label to start a chat")
            case .showMore(let num):
                return String(format: NSLocalizedString("Show %d more", comment: "Button label to show all fingerprints"), num)
            }
        }
    }
    
    let type:ButtonCellType
    
    func configure(_ cell:UITableViewCell) {
        cell.textLabel?.text = self.type.text()
        cell.textLabel?.textColor = UIButton(type: .system).titleColor(for: .normal)
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
    
    func configure(_ cell: UITableViewCell) {
        guard let passwordCell = cell as? ZomPasswordCell else {
            return
        }
        passwordCell.passwordTextField.text = self.password
        
        passwordCell.changeButton.titleLabel?.font = UIFont(name: "FontAwesome", size: 30)
        passwordCell.changeButton.setTitle(NSString.fa_string(forFontAwesomeIcon: .FAEdit), for: UIControlState.normal)
        passwordCell.revealButton.titleLabel?.font = UIFont(name: "FontAwesome", size: 30)
        passwordCell.revealButton.setTitle(NSString.fa_string(forFontAwesomeIcon: .FAEye), for: UIControlState.normal)
        passwordCell.selectionStyle = .none
    }
    
    func cellIdentifier() -> ZomProfileViewCellIdentifier {
        return .PasswordCell
    }
    
    func cellHeight() -> CGFloat? {
        return nil
    }
}
