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
 
 The first OMEMO key exists, which has trust level `.untrustedNew`, will be used, otherwise the
 first OTR fingerprint with this trust level will be used.
 */
class ZomVerificationViewController: UIViewController {

    @objc public var buddy: OTRBuddy?

    @IBOutlet weak var infoLb: UILabel!
    @IBOutlet weak var fingerprintLb: UILabel!
    @IBOutlet weak var avatarImg: UIImageView!
    @IBOutlet weak var checkmarkImg: UIImageView!
    @IBOutlet weak var matchBt: UIButton!
    @IBOutlet weak var noMatchBt: UIButton!
    @IBOutlet weak var overlayContainer: UIView!
    @IBOutlet weak var successCheckmarkLb: UILabel!
    @IBOutlet weak var trustedLb: UILabel!

    private var fingerprintContainer: NSObject?

    /**
     Convenience initializer which also sets `self.buddy` with the given argument.

     You can do this yourself, since `self.buddy` is public, but you need to do this, before
     `self.viewDidLoad()` was called!

     - parameter buddy: a OTRBuddy with a new OMEMO or OTR fingerprint.
    */
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
            db.asyncRead() { (transaction) in
                let allOmemoDevices = OTROMEMODevice.allDevices(
                    forParentKey: buddy.uniqueId,
                    collection: type(of: buddy).collection,
                    transaction: transaction
                ).filter() { (device) -> Bool in
                    return device.publicIdentityKeyData != nil && device.trustLevel == .untrustedNew
                }

                if let device = allOmemoDevices.first {
                    self.fingerprintContainer = device
                    self.setFingerprint(device.humanReadableFingerprint)
                }
                else if let account = buddy.account(with: transaction) {
                    let fingerprints = OTRProtocolManager.encryptionManager.otrKit.fingerprints(
                        forUsername: buddy.username,
                        accountName: account.username,
                        protocol: account.protocolTypeString()
                    ).filter() { (fingerprint) -> Bool in
                        return fingerprint.trustLevel == .untrustedNew
                    }

                    if let fingerprint = fingerprints.first {
                        self.fingerprintContainer = fingerprint
                        self.setFingerprint(
                            (fingerprint.fingerprint as NSData).humanReadableFingerprint())
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

        matchBt.titleLabel?.font = UIFont(name: "Material Icons", size: 40)

        noMatchBt.titleLabel?.text = NSLocalizedString("Codes don't match",
                                                       comment: "Verification scene button text")

        successCheckmarkLb.font = UIFont(name: "Material Icons", size: 40)

        trustedLb.text = NSLocalizedString("Trusted", comment: "Verification scene success text")
    }

    /**
     Callback, when user hits the "match" button.

     Sets the trust level of the OMEMO device key resp. the OTR fingerprint to `.trustedUser` and
     stores it.

     Will fade-in a green overlay displaying a checkmark and the text "Trusted".

     When animation is finished, dismisses this view controller.
    */
    @IBAction func match() {
        matchBt.isHighlighted = true

        if let device = fingerprintContainer as? OTROMEMODevice {
            device.trustLevel = .trustedUser
            store(device)
        }
        else if let fingerprint = fingerprintContainer as? OTRFingerprint {
            fingerprint.trustLevel = .trustedUser
            store(fingerprint)
        }

        if let window = view.window {
            overlayContainer.frame = window.frame
            window.addSubview(overlayContainer)
            UIView.transition(
                with: overlayContainer,
                duration: 0.5,
                options: .transitionCrossDissolve,
                animations: {
                    self.overlayContainer.isHidden = false
                },
                completion: { (_) in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.dismiss(animated: true) {
                            self.overlayContainer.removeFromSuperview()
                            self.overlayContainer.isHidden = true
                        }
                    }
                })
        }
    }

    /**
     Callback, when user hits the "Codes don't match" button.

     Sets the trust level of the OMEMO device key resp. the OTR fingerprint to `.untrusted` resp.
     `.untrustedUser` and stores it.

     Then dismisses this view controller.
    */
    @IBAction func noMatch() {
        if let device = fingerprintContainer as? OTROMEMODevice {
            device.trustLevel = .untrusted
            store(device)
        }
        else if let fingerprint = fingerprintContainer as? OTRFingerprint {
            fingerprint.trustLevel = .untrustedUser
            store(fingerprint)
        }

        self.dismiss(animated: true, completion: nil)
    }

    /**
     Store a given `OTROMEMODevice` to the database.
    */
    private func store(_ device: OTROMEMODevice) {
        if let db = OTRDatabaseManager.sharedInstance().readWriteDatabaseConnection {
            db.asyncReadWrite() { (transaction) in
                transaction.setObject(device, forKey: device.uniqueId,
                                      inCollection: type(of: device).collection)
            }
        }
    }

    /**
     Store a given `OTRFingerprint` to wherever OTRKit stores its fingerprints.
    */
    private func store(_ fingerprint: OTRFingerprint) {
        OTRProtocolManager.encryptionManager.otrKit.save(fingerprint)
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
