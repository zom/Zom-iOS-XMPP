//
//  ZomVerificationViewController.swift
//  Zom
//
//  Created by Benjamin Erhart on 22.02.18.
//

import UIKit

/**
 Scene for verification of the latest fingerprint of a buddy.

 Use the `convenience init(buddy: OTRBuddy)` or set `self.buddy` immediately after init!

 If OMEMO keys exist, the fingerprint of the first one of these will always be used.
 Fallback to the first OTR key only, when no OMEMO key is found.
 */
class ZomVerificationViewController: UIViewController {

    @objc public var buddy: OTRBuddy?

    @IBOutlet weak var infoLb: UILabel!
    @IBOutlet weak var fingerprintLb: UILabel!
    @IBOutlet weak var avatarImg: UIImageView!
    @IBOutlet weak var checkmarkImg: UIImageView!
    @IBOutlet weak var matchBt: UIButton!
    @IBOutlet weak var noMatchBt: UIButton!

    @objc convenience init(buddy: OTRBuddy) {
        self.init()
        self.buddy = buddy
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let titleView = OTRTitleSubtitleView(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        titleView.titleLabel.text = NSLocalizedString("Compare Codes",
                                                      comment: "Title for code verification scene")
        titleView.subtitleLabel.text = buddy?.username
        navigationItem.titleView = titleView

        infoLb.text = NSLocalizedString(
            "Make sure this code matches your friend's latest Zom code on their phone.",
            comment: "Description for code verification scene")

        if let buddy = buddy, let db = OTRDatabaseManager.sharedInstance().readOnlyDatabaseConnection {
            db.asyncRead() { (transaction: YapDatabaseReadTransaction) in
                let allOmemoDevices = OTROMEMODevice.allDevices(
                    forParentKey: buddy.uniqueId,
                    collection: type(of: buddy).collection,
                    transaction: transaction
                ).filter() { (device) -> Bool in
                    return device.publicIdentityKeyData != nil && device.trustLevel != .removed
                }

                if let device = allOmemoDevices.first {
                    self.setFingerprint(device.humanReadableFingerprint)
                }
                else if let account = buddy.account(with: transaction) {
                    let allFingerprints = OTRProtocolManager.encryptionManager.otrKit.fingerprints(
                        forUsername: buddy.username, accountName: account.username,
                        protocol: account.protocolTypeString())

                    if let fingerprint = allFingerprints.first {
                        self.setFingerprint((fingerprint.fingerprint as NSData).humanReadableFingerprint())
                    }
                    else {
                        self.setFingerprintError()
                    }
                }
                else {
                    self.setFingerprintError()
                }
            }
        }
        else {
            setFingerprintError()
        }

        avatarImg.image = buddy?.avatarImage

        //TODO: This is not the correct badge, yet.
        checkmarkImg.image = OTRImages.checkmark(with: UIColor.black).withRenderingMode(.alwaysTemplate)

        //TODO: This is not the correct button, yet.
        matchBt.setImage(OTRImages.checkmark(with: UIColor.darkGray),
                         for: .normal)

        noMatchBt.titleLabel?.text = NSLocalizedString("Codes don't match",
                                                       comment: "Verification scene button text")
    }

    /**
     Callback, when user hit the "match" button.
    */
    @IBAction func match() {
    }

    /**
     Callback, when user hit the "Codes don't match" button.
    */
    @IBAction func noMatch() {
    }

    /**
     Set text content of `self.fingerprintLb`.

     Copious amounts of letter and line spacing are used.

     Thread-safe.

     - parameter text: Falls back to an error message, if nil.
    */
    private func setFingerprint(_ text: String?) {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 10
        style.alignment = .center

        let string = text ?? NSLocalizedString(
            "CODE ERROR",
            comment: "Error message instead of key fingerprint which could not be read")

        DispatchQueue.main.async {
            self.fingerprintLb.attributedText = NSAttributedString(
                string: string.localizedUppercase,
                attributes: [.kern: 3, .paragraphStyle: style])
        }
    }

    /**
     Set an error message instead of a fingerprint to `self.fingerprintLb`.
    */
    private func setFingerprintError() {
        setFingerprint(nil)
    }
}
