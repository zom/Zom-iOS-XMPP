//
//  ZomMigratedBuddyHeaderView.swift
//  Zom
//
//  Created by N-Pex on 2017-05-01.
//
//

import UIKit
import ChatSecureCore

public class ZomMigratedBuddyHeaderView: MigratedBuddyHeaderView {
    @IBOutlet public var infoLabel: UILabel!
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.backgroundColor = OTRAppDelegate.appDelegate.theme.mainThemeColor
        switchButton.backgroundColor = UIColor.yellow
        if let text = infoLabel.text, text.contains("%@") {
            infoLabel.text = text.replacingOccurrences(of: "%@", with: self.forwardingJID?.bare() ?? "")
        }
    }
}
