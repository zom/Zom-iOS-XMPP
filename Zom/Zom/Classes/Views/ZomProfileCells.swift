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
        userCell.avatarImageView.setImage(self.avatarImage, forState: .Normal)
        userCell.avatarImageView.layer.cornerRadius = CGRectGetWidth(userCell.avatarImageView.frame)/2;
        userCell.avatarImageView.userInteractionEnabled = true
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

struct ButtonCellInfo: ZomProfileViewCellInfoProtocol {
    
    enum ButtonCellType {
        case Verify(OTRFingerprint)
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
