//
//  ZomSettingsViewController.swift
//  Zom
//
//  Created by N-Pex on 2016-06-16.
//
//

import UIKit
import ChatSecureCore

open class ZomSettingsViewController : OTRSettingsViewController {

    open override func viewDidLoad() {
        super.viewDidLoad()
        
        // Override the account cell to provide a "move account" option at the bottom
        //
        let nib = UINib(nibName: "XMPPAccountCellWithMove", bundle: OTRAssets.resourcesBundle)
        self.tableView.register(nib, forCellReuseIdentifier: XMPPAccountCell.cellIdentifier())
        
        if let versionButton = self.tableView.tableFooterView as? UIButton {
            versionButton.backgroundColor = UIColor.clear
        }
        
        // Remove the right bar info button
        self.navigationItem.rightBarButtonItem = nil
    }

    open override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
         return UITableViewAutomaticDimension
    }
    
    @IBAction open func didTapMoveAccountButton(_ sender: Any) {
        var object:AnyObject? = sender as AnyObject
        while let o = object, !(o is XMPPAccountCell) {
            object = o.superview
        }
        if let cell = object as? UITableViewCell, let indexPath = self.tableView.indexPath(for: cell) {
            if let account = super.account(at: indexPath) {
                let migrateVC = OTRAccountMigrationViewController(oldAccount: account)
                self.navigationController?.pushViewController(migrateVC, animated: true)
            }
        }
    }
}
