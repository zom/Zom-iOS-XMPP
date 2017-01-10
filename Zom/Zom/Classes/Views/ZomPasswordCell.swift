//
//  UserInfoProfileCell.swift
//  ChatSecure
//
//  Created by Chris Ballinger on 10/31/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import UIKit

@objc(ZomPasswordCell)
public class ZomPasswordCell: UITableViewCell {
    
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var changeButton: UIButton!
    @IBOutlet weak var revealButton: UIButton!
    
    @IBAction func didPressRevealButton(sender: UIButton) {
        self.passwordTextField.secureTextEntry = !self.passwordTextField.secureTextEntry
    }
}
