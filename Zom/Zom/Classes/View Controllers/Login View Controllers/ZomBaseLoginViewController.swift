//
//  ZomBaseLoginViewController.swift
//  Zom
//
//  Created by N-Pex on 2015-11-13.
//
//


import UIKit
import ChatSecureCore


extension OTRBaseLoginViewController {
    public override class func initialize() {
        struct Static {
            static var token: dispatch_once_t = 0
        }
        
        // make sure this isn't a subclass
        if self !== OTRBaseLoginViewController.self {
            return
        }
        
        dispatch_once(&Static.token) {
            zom_swizzle(#selector(OTRBaseLoginViewController.viewDidLoad), swizzledSelector:#selector(OTRBaseLoginViewController.zom_viewDidLoad))
        }
    }

    public func zom_viewDidLoad() {
        object_setClass(self, ZomBaseLoginViewController.self)
        self.zom_viewDidLoad()
        (self as! ZomBaseLoginViewController).setupTableView()
    }

    private class func zom_swizzle(originalSelector:Selector, swizzledSelector:Selector) -> Void {
        let originalMethod = class_getInstanceMethod(self, originalSelector)
        let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
        
        let didAddMethod = class_addMethod(self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
        
        if didAddMethod {
            class_replaceMethod(self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
}


public class ZomBaseLoginViewController: OTRBaseLoginViewController {
    
    private var existingAccount:Bool = false
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }

    private func setupTableView() -> Void {
        let nib:UINib = UINib(nibName: "ZomTableViewSectionHeader", bundle: nil)
        self.tableView.registerNib(nib, forHeaderFooterViewReuseIdentifier: "zomTableSectionHeader")
    }
    
    public override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header:ZomTableViewSectionHeader = tableView.dequeueReusableHeaderFooterViewWithIdentifier("zomTableSectionHeader") as! ZomTableViewSectionHeader
        header.labelView.text = self.tableView(tableView, titleForHeaderInSection: section)
        return header
    }
    
    public override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let title:String? = self.tableView(tableView, titleForHeaderInSection: section)
        if (title == nil || title!.isEmpty) {
            return 0
        }
        return 50
    }
    
    override public func textFieldDidEndEditing(textField: UITextField) {
        super.textFieldDidEndEditing(textField)
        if let usernameRow:XLFormRowDescriptor = self.form.formRowWithTag(kOTRXLFormNicknameTextFieldTag) {
            if let editCell = usernameRow.cellForFormController(self) as? XLFormTextFieldCell {
                if (editCell.textField == textField) {
                    if let text = textField.text?.characters.count {
                        if (text > 0) {
                            if let advancedRow:XLFormRowDescriptor = self.form.formRowWithTag(kOTRXLFormShowAdvancedTag) {
                                if (advancedRow.value as? Bool == false) {
                                    // Ok, if we are not showing advanced tab, enter means "go"
                                    self.loginButtonPressed(self.navigationItem.rightBarButtonItem)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    override public func loginButtonPressed(sender: AnyObject!) {
        existingAccount = (self.account != nil)
        super.loginButtonPressed(sender)
    }
    
    override public func pushInviteViewController() {
        if (existingAccount) {
            dismissViewControllerAnimated(true, completion: nil)
        } else {
            super.pushInviteViewController()
        }
    }
}
