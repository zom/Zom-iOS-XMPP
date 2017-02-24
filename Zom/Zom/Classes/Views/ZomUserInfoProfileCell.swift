//
//  UserInfoProfileCell.swift
//  ChatSecure
//
//  Created by Chris Ballinger on 10/31/16.
//  Copyright © 2016 Chris Ballinger. All rights reserved.
//

import UIKit

@objc(ZomUserInfoProfileCell)
open class ZomUserInfoProfileCell: UITableViewCell {

    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIButton!
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
}
