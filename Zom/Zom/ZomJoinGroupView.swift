//
//  ZomJoinGroupView.swift
//  Zom
//
//  Created by N-Pex on 2018-04-04.
//

import UIKit

open class ZomJoinGroupView: UIView {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var declineButton: UIButton!
    
    open var acceptButtonCallback:(() -> Void)?
    open var declineButtonCallback:(() -> Void)?
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = GlobalTheme.shared.mainThemeColor
        // Initialization code
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        self.acceptButton.layer.cornerRadius = self.acceptButton.frame.height / 2
    }
    
    @IBAction func joinGroupAccept(sender: AnyObject) {
        if let callback = self.acceptButtonCallback {
            callback()
        }
    }
    
    @IBAction func joinGroupDecline(sender: AnyObject) {
        if let callback = self.declineButtonCallback {
            callback()
        }
    }
}
