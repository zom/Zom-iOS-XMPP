//
//  ZomUnknownSenderMessageCell.swift
//  Zom
//
//  Created by N-Pex on 2017-08-29.
//
//

import UIKit
import BButton

open class ZomUnknownSenderMessageCell: UICollectionViewCell {
    @IBOutlet weak var titleView: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nicknameView: UILabel!
    @IBOutlet weak var usernameView: UILabel!
    
    var acceptAction:((_ cell:ZomUnknownSenderMessageCell) -> Void)?
    var denyAction:((_ cell:ZomUnknownSenderMessageCell) -> Void)?
    
    @IBAction func acceptButtonPressed(_ sender: UIButton) {
        if let action = self.acceptAction {
            action(self)
        }
    }
    
    @IBAction func denyButtonPressed(_ sender: UIButton) {
        if let action = self.denyAction {
            action(self)
        }
    }
}
