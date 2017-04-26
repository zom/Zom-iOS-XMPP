//
//  ZomAccountDetailViewController.swift
//  Zom
//
//  Created by N-Pex on 2017-04-26.
//
//

import UIKit
import ChatSecureCore

open class ZomAccountDetailViewController : AccountDetailViewController {
    
    var showSetAsDefaultOption = false
    let setAsDefaultTableSection = 4
    
    override open func viewDidLoad() {
        updateShowAsDefaultOption()
        super.viewDidLoad()
    }
    
    func updateShowAsDefaultOption() {
        if let appDelegate = UIApplication.shared.delegate as? ZomAppDelegate {
            showSetAsDefaultOption = (self.account.uniqueId != appDelegate.getDefaultAccount()?.uniqueId)
        }
    }
    
    override open func numberOfSections(in tableView: UITableView) -> Int {
        return super.numberOfSections(in: tableView) + (showSetAsDefaultOption ? 1 : 0)
    }
    
    private func superSectionNumber(_ section: Int) -> Int {
         return (showSetAsDefaultOption && section > setAsDefaultTableSection) ? (section - 1) : section
    }
    
    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (showSetAsDefaultOption && section == setAsDefaultTableSection) {
            return 1
        }
        return super.tableView(tableView, numberOfRowsInSection: superSectionNumber(section))
    }
    
    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (showSetAsDefaultOption && indexPath.section == setAsDefaultTableSection) {
            return setAsDefaultCell(account: account, tableView: tableView, indexPath: indexPath)
        }
        let newIndexPath = IndexPath(row: indexPath.row, section: superSectionNumber(indexPath.section))
        return super.tableView(tableView, cellForRowAt: newIndexPath)
    }
    
    open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (showSetAsDefaultOption && indexPath.section == setAsDefaultTableSection) {
            return
        }
        let newIndexPath = IndexPath(row: indexPath.row, section: superSectionNumber(indexPath.section))
        super.tableView(tableView, didSelectRowAt: newIndexPath)
    }
    
    open override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (showSetAsDefaultOption && indexPath.section == setAsDefaultTableSection) {
            return UITableViewAutomaticDimension
        }
        let newIndexPath = IndexPath(row: indexPath.row, section: superSectionNumber(indexPath.section))
        return super.tableView(tableView, heightForRowAt: newIndexPath)
    }
    
    func setAsDefaultCell(account: OTRXMPPAccount, tableView: UITableView, indexPath: IndexPath) -> SingleButtonTableViewCell {
        let cell = singleButtonCell(account: account, tableView: tableView, indexPath: indexPath)
        cell.button.setTitle(NSLocalizedString("Set as default", comment: "Account option to set as default"), for: .normal)
        cell.buttonAction = { [weak self] (cell, sender) in
            guard let strongSelf = self else { return }
            if let appDelegate = UIApplication.shared.delegate as? ZomAppDelegate {
                appDelegate.setDefaultAccount(strongSelf.account)
                strongSelf.updateShowAsDefaultOption()
                strongSelf.tableView.reloadData()
            }
        }
        return cell
    }
}
