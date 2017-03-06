//
//  OMEMODeviceFingerprintCell.swift
//  ChatSecure
//
//  Created by Chris Ballinger on 10/14/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import UIKit

typealias CellAction = (_ cell:ZomFingerprintCell) -> Void

@objc(ZomFingerprintCell)
open class ZomFingerprintCell: UITableViewCell {
    
    @IBOutlet weak var fingerprintLabel: UILabel!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var qrButton: UIButton!
    
    var qrAction:CellAction?
    var shareAction:CellAction?
    
    @IBAction func qrButtonPressed(_ sender: UIButton) {
        if let action = self.qrAction {
            action(self)
        }
    }
    
    @IBAction func shareButtonPressed(_ sender: UIButton) {
        if let action = self.shareAction {
            action(self)
        }
    }
}
