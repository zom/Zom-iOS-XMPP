//
//  ZomNewBuddyViewController.swift
//  Zom
//
//  Created by N-Pex on 2015-12-04.
//
//

import UIKit
import ChatSecureCore

public class ZomNewBuddyViewController: OTRNewBuddyViewController {
    @IBOutlet weak var shareSmsButton: UIButton!
    @IBOutlet weak var shareLinkTopConstraint: NSLayoutConstraint!
    
    private var shouldShowSmsButton:Bool = true
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.showSmsButton(self.shouldShowSmsButton)
    }
    
    public func showSmsButton(show:Bool) {
        self.shouldShowSmsButton = show
        if (self.isViewLoaded()) {
            if (show) {
                self.shareSmsButton.hidden = false
                self.shareLinkTopConstraint.priority = 850
            } else {
                self.shareSmsButton.hidden = true
                self.shareLinkTopConstraint.priority = 950
            }
        }
    }
}
 