//
//  ZomBaseLoginViewController.swift
//  Zom
//
//  Created by N-Pex on 2015-11-13.
//
//


import UIKit
import ChatSecureCore

public class ZomBaseLoginViewController: OTRBaseLoginViewController {
    
    public override func viewDidLoad() {
        super.viewDidLoad()
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
}
