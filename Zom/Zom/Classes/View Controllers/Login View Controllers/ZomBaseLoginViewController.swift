//
//  ZomBaseLoginViewController.swift
//  Zom
//
//  Created by N-Pex on 2015-11-13.
//
//


import UIKit
import ChatSecureCore
import OTRAssets
import BButton

var ZomBaseLoginController_associatedObject1: UInt8 = 0
var ZomBaseLoginController_associatedObject2: UInt8 = 1
var ZomBaseLoginController_associatedObject3: UInt8 = 2
var ZomAccountMigrationViewController_associatedObject1: UInt8 = 3
var ZomAccountMigrationViewController_associatedObject2: UInt8 = 4

extension OTRBaseLoginViewController {
    
    @objc public static func swizzle() {
        ZomUtil.swizzle(self, originalSelector: #selector(OTRBaseLoginViewController.viewDidLoad), swizzledSelector:#selector(OTRBaseLoginViewController.zom_viewDidLoad))
    }

    @objc public func zom_viewDidLoad() {
        if object_getClass(self) === OTRBaseLoginViewController.self {
            object_setClass(self, ZomBaseLoginViewController.self)
            self.zom_viewDidLoad()
            (self as! ZomBaseLoginViewController).setupTableView()
        } else if object_getClass(self) === OTRAccountMigrationViewController.self {
            object_setClass(self, ZomAccountMigrationViewController.self)
            self.zom_viewDidLoad()
        } else {
            self.zom_viewDidLoad()
        }
    }
}


open class ZomBaseLoginViewController: OTRBaseLoginViewController {
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        if (onlyShowInfo) {
            self.title = "Account information"
        }
        if (self.createNewAccount) {
            if let nickname = self.form.formRow(withTag: kOTRXLFormNicknameTextFieldTag) {
                nickname.title = ""
            }
        }
    }

    open var onlyShowInfo:Bool {
        get {
            return objc_getAssociatedObject(self, &ZomBaseLoginController_associatedObject1) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &ZomBaseLoginController_associatedObject1, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    fileprivate var existingAccount:Bool {
        get {
            return objc_getAssociatedObject(self, &ZomBaseLoginController_associatedObject2) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &ZomBaseLoginController_associatedObject2, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    open var createNewAccount:Bool {
        get {
            return objc_getAssociatedObject(self, &ZomBaseLoginController_associatedObject3) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &ZomBaseLoginController_associatedObject3, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    fileprivate func setupTableView() -> Void {
        let nib:UINib = UINib(nibName: "ZomTableViewSectionHeader", bundle: nil)
        self.tableView.register(nib, forHeaderFooterViewReuseIdentifier: "zomTableSectionHeader")
    }
    
    open override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header:ZomTableViewSectionHeader = tableView.dequeueReusableHeaderFooterView(withIdentifier: "zomTableSectionHeader") as! ZomTableViewSectionHeader
        header.labelView.text = super.tableView(tableView, titleForHeaderInSection: section)
        return header
    }
 
    open override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let title:String? = super.tableView(tableView, titleForHeaderInSection: section)
        if (title == nil || title!.isEmpty) {
            return 0
        }
        return 50
    }
    
   open override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }
    
    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        if (onlyShowInfo) {
            cell.isUserInteractionEnabled = false
        }
        if let desc = self.form.formRow(atIndex: indexPath) {
                if (desc.tag == kOTRXLFormPasswordTextFieldTag) {
                    let font:UIFont? = UIFont(name: kFontAwesomeFont, size: 30)
                    if (font != nil) {
                        let button = UIButton(type: UIButtonType.custom)
                        button.titleLabel?.font = font
                        button.setTitle(NSString.fa_string(forFontAwesomeIcon: FAIcon.FAEye), for: UIControlState())
                        //if let appDelegate = UIApplication.sharedApplication().delegate as? ZomAppDelegate {
                        //    button.setTitleColor(appDelegate.theme.mainThemeColor, forState: UIControlState.Normal)
                        //} else {
                            button.setTitleColor(UIColor.black, for: UIControlState())
                        //}
                        button.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
                        button.addTarget(self, action: #selector(self.didPressEyeIcon(_:withEvent:)), for: UIControlEvents.touchUpInside)
                        cell.accessoryView = button
                    } else {
                        cell.accessoryType = UITableViewCellAccessoryType.detailButton
                    }
                    cell.isUserInteractionEnabled = true
                    if let xlCell = cell as? XLFormTextFieldCell {
                        xlCell.textField.isUserInteractionEnabled = !onlyShowInfo
                    }
                }
            }
        return cell
    }
    
    @objc func didPressEyeIcon(_ sender: UIControl!, withEvent: UIEvent!) {
        let indexPath = self.tableView.indexPathForRow(at: (withEvent.touches(for: sender)?.first?.location(in: self.tableView))!)
        if (indexPath != nil) {
            self.tableView.delegate?.tableView!(self.tableView, accessoryButtonTappedForRowWith: indexPath!)
        }
    }
    
    open override func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let usernameRow:XLFormRowDescriptor = self.form.formRow(withTag: kOTRXLFormNicknameTextFieldTag) {
            if let editCell = usernameRow.cell(forForm: self) as? XLFormTextFieldCell {
                if (editCell.textField == textField) {
                    if let text = textField.text?.characters.count {
                        if (text > 0) {
                            if let advancedRow:XLFormRowDescriptor = self.form.formRow(withTag: kOTRXLFormShowAdvancedTag) {
                                if (advancedRow.value as? Bool == false) {
                                    // Ok, if we are not showing advanced tab, enter means "go"
                                    self.loginButtonPressed(self.navigationItem.rightBarButtonItem as Any)
                                    return true
                                }
                            }
                        }
                    }
                }
            }
        }
        return super.textFieldShouldReturn(textField)
    }
    
    override open func loginButtonPressed(_ sender: Any) {
        if (onlyShowInfo) {
            dismiss(animated: true, completion: nil)
            return
        }
        existingAccount = (self.account != nil)
        super.loginButtonPressed(sender)
    }
    
    // If creating a new account, we may need to set display name to what
    // was originally entered
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if (self.createNewAccount) {
            if let nicknameRow:XLFormRowDescriptor = self.form.formRow(withTag: kOTRXLFormNicknameTextFieldTag) {
                if let editCell = nicknameRow.cell(forForm: self) as? XLFormTextFieldCell {
                    if (editCell.textField.text != nil && nicknameRow.value != nil) {
                        if (editCell.textField.text!.compare(nicknameRow.value as! String) != ComparisonResult.orderedSame) {
                            self.account?.displayName = editCell.textField.text!
                        }
                    }
                }
            }
        }

    }
    
    override open func pushInvite() {
        if (existingAccount) {
            dismiss(animated: true, completion: nil)
        } else {
            super.pushInvite()
        }
    }
}

@objc public protocol ZomAccountMigrationViewControllerAutoDelegateProtocol {
    func automaticMigrationDone(error:Error?) -> Void
}

open class ZomAccountMigrationViewController: OTRAccountMigrationViewController {

    open var useAutoMode:Bool {
        get {
            return objc_getAssociatedObject(self, &ZomAccountMigrationViewController_associatedObject1) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &ZomAccountMigrationViewController_associatedObject1, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    open var autoDelegate:ZomAccountMigrationViewControllerAutoDelegateProtocol? {
        get {
            return objc_getAssociatedObject(self, &ZomAccountMigrationViewController_associatedObject2) as? ZomAccountMigrationViewControllerAutoDelegateProtocol
        }
        set {
            objc_setAssociatedObject(self, &ZomAccountMigrationViewController_associatedObject2, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    override open func onMigrationComplete(_ success: Bool) {
        super.onMigrationComplete(success)
        if (success) {
            // Remember migration, at least for this session
            self.oldAccount.hasMigrated = true;
            
            // Set the migrated account as default!
            if let appDelegate = UIApplication.shared.delegate as? ZomAppDelegate {
                appDelegate.setDefaultAccount(account)
            }
            
            // Mute all old friends
            OTRDatabaseManager.shared.readWriteDatabaseConnection?.readWrite({ (transaction) in
                for buddy in self.oldAccount.allBuddies(with: transaction) {
                    buddy.muteExpiration = Date.distantFuture
                    buddy.save(with: transaction)
                }
                
                // Logout old account and disable auto-login
                self.oldAccount.autologin = false
                self.oldAccount.save(with: transaction)
            })
        }
        if useAutoMode {
            DispatchQueue.main.async {
                if let delegate = self.autoDelegate {
                    delegate.automaticMigrationDone(error: success ? nil : NSError(domain: "Failed", code: 1, userInfo: nil))
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(60)) {
            // Log out of old account after 1 minute
            if let xmpp = OTRProtocolManager.shared.protocol(for: self.oldAccount) as? XMPPManager,
                xmpp.loginStatus != OTRLoginStatus.disconnected {
                xmpp.disconnect()
            }
        }
    }
}
