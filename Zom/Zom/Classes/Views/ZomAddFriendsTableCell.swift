//
//  ZomAddFriendsTableCell.swift
//  Zom
//
//  Created by N-Pex on 2018-03-26.
//

import UIKit

open class ZomAddFriendsTableCell: UITableViewCell {
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        avatarImageView.layer.cornerRadius = avatarImageView.frame.width / 2
        avatarImageView.layer.masksToBounds = true
    }
}
