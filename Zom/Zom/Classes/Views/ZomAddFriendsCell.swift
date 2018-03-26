//
//  ZomAddFriendsCell.swift
//  Zom
//
//  Created by N-Pex on 07.03.18.
//

import UIKit
import FormatterKit

/**
 A cell used as supplementary view to add group chat members you are not yet friends with.
 */
open class ZomAddFriendsCell: UICollectionReusableView {
    @objc public static let reuseIdentifier = "addFriendsCell"
    
    let maxNumberOfAvatarsShown = 5
    
    @objc @IBOutlet open weak var titleLabel:UILabel!
    @objc @IBOutlet open weak var avatarImageStackView:UIStackView!
    @objc @IBOutlet open weak var actionButton:UIButton!
    
    open var buddies:[OTRXMPPBuddy]?
    open var actionButtonCallback:((_ buddies:[OTRXMPPBuddy]?) -> Void)?
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        for view in subviews {
            if let label = view as? UILabel {
                if label.numberOfLines == 0 {
                    label.preferredMaxLayoutWidth = label.bounds.width
                }
            }
        }
    }
    
    @objc open func populate(buddies:[OTRXMPPBuddy], actionButtonCallback:(([OTRXMPPBuddy]?) -> Void)?) {
        self.buddies = buddies
        
        if buddies.count > 0 {
            titleLabel.text = String(format:NSLocalizedString("%d people are not your friends.", comment: "Label for addFriends supplementary view when n > 1"), buddies.count)
        } else {
            titleLabel.text = String(format:NSLocalizedString("%@ is not your friend.", comment: "Label for addFriends supplementary view when n = 1"), buddies[0].displayText())
        }
        
        for buddy in buddies {
            if (avatarImageStackView.arrangedSubviews.count <= maxNumberOfAvatarsShown) {
                let avatarImageView = UIImageView()
                avatarImageView.autoSetDimensions(to: CGSize(width: 44, height: 44))
                avatarImageView.image = buddy.avatarImage
                avatarImageView.layer.cornerRadius = 22
                avatarImageView.layer.masksToBounds = true
                
                // Insert at 0 to get right Z-ordering
                avatarImageStackView.insertSubview(avatarImageView, at: 0)
                avatarImageStackView.insertArrangedSubview(avatarImageView, at: 0)
            }
        }
        self.actionButtonCallback = actionButtonCallback
    }
    
    @IBAction open func didTapActionButton(_ sender: Any) {
        if let callback = actionButtonCallback {
            callback(self.buddies)
        }
    }
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        for view in avatarImageStackView.subviews {
            if view is UIImageView {
                avatarImageStackView.removeArrangedSubview(view)
                view.removeFromSuperview()
            }
        }
    }
}


