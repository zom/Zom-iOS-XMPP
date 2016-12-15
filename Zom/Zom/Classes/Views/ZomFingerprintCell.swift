//
//  OMEMODeviceFingerprintCell.swift
//  ChatSecure
//
//  Created by Chris Ballinger on 10/14/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import UIKit

typealias CellAction = (cell:ZomFingerprintCell) -> Void

@objc(ZomFingerprintCell)
public class ZomFingerprintCell: UITableViewCell {
    
    @IBOutlet weak var fingerprintLabel: UILabel!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var qrButton: UIButton!
    
    var qrAction:CellAction?
    var shareAction:CellAction?
    
    @IBAction func qrButtonPressed(sender: UIButton) {
        if let action = self.qrAction {
            action(cell: self)
        }
    }
    
    @IBAction func shareButtonPressed(sender: UIButton) {
        if let action = self.shareAction {
            action(cell:self)
        }
    }
}
