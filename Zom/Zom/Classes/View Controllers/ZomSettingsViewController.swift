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
    
    public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == (tableView.numberOfSections - 1) {
                return versionString()
        }
        return nil
    }
    
    func versionString() -> String {
        return String(format: "%@ %@ (%@)", VERSION_STRING(),
                      (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "",
                      (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "")
    }
}
