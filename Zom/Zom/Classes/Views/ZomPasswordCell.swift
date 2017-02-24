//
//  UserInfoProfileCell.swift
//  ChatSecure
//
//  Created by Chris Ballinger on 10/31/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import UIKit

@objc(ZomPasswordCell)
open class ZomPasswordCell: UITableViewCell {
    
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var changeButton: UIButton!
    @IBOutlet weak var revealButton: UIButton!
    
    @IBAction func didPressRevealButton(_ sender: UIButton) {
        self.passwordTextField.isSecureTextEntry = !self.passwordTextField.isSecureTextEntry
    }
}
