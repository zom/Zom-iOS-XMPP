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
        
        if let versionButton = self.tableView.tableFooterView as? UIButton {
            versionButton.backgroundColor = UIColor.clear
        }
        
        // Remove the right bar info button
        self.navigationItem.rightBarButtonItem = nil
    }
}
