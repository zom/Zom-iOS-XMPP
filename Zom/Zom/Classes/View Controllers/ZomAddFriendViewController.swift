//
//  ZomAddFriendViewController.swift
//  Zom
//
//  Created by N-Pex on 2018-03-26.
//

import Foundation

protocol ZomAddFriendViewControllerDelegate {
    func didSelectBuddy(_ buddy: OTRXMPPBuddy, from viewController:UIViewController)
    func didNotSelectBuddy(from viewController:UIViewController)
}

class ZomAddFriendViewController: UIViewController {
    
    public var delegate:ZomAddFriendViewControllerDelegate?
    
    public var buddy:OTRXMPPBuddy?
    public var userData:Any?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        avatarImageView.layer.cornerRadius = avatarImageView.frame.height / 2
        avatarImageView.layer.masksToBounds = true
        avatarImageView.image = buddy?.avatarImage
        titleLabel.text = String(format: NSLocalizedString("Add %@ as friend?", comment: "Title in dialog to add one friend from group"), buddy?.displayName ?? "")
    }
    
    public func setBuddy(_ buddy:OTRXMPPBuddy) {
        self.buddy = buddy
    }

    @IBAction func didPressCancel(_ sender: UIButton) {
        if let delegate = self.delegate {
            delegate.didNotSelectBuddy(from:self)
        }
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didPressAdd(_ sender: UIButton) {
        if let delegate = self.delegate, let buddy = self.buddy {
            delegate.didSelectBuddy(buddy, from: self)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
}
