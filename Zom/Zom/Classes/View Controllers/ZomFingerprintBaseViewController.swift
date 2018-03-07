//
//  FingerprintBaseViewController.swift
//  Zom
//
//  Created by Benjamin Erhart on 06.03.18.
//

import UIKit

/**
 Base class for `ZomVerificationViewController` and `ZomVerificationDetailViewController`.

 Before `viewDidLoad` is called, a `self.buddy` should be set.
 You can also set `self.omemoDevices` and `self.otrFingerprints` to save database accesses. If you
 don't, they will be populated for you in `viewDidLoad`.
*/
class ZomFingerprintBaseViewController: UIViewController {

    @objc var buddy: OTRBuddy?
    @objc var omemoDevices: [OMEMODevice] = []
    @objc var otrFingerprints : [OTRFingerprint] = []

    @IBOutlet weak var avatarImg: UIImageView!
    @IBOutlet weak var checkmarkImg: UIImageView!

    /**
     Convenience initializer which also sets `self.buddy` with the given argument.

     You can do this yourself, since `self.buddy` is internal public, but you need to do this,
     before `self.viewDidLoad()` was called!

     - parameter buddy: a OTRBuddy with a new OMEMO or OTR fingerprint.
    */
    @objc convenience init(buddy: OTRBuddy?) {
        self.init()
        self.buddy = buddy
    }

    /**
     Convenience initializer which also sets `self.buddy`, `self.omemoDevices` and
     `self.otrFingerprints` with the given arguments.

     You can do this yourself, since all of these are internal public, but you need to do this,
     before `self.viewDidLoad()` was called!

     - parameter buddy: a OTRBuddy with a new OMEMO or OTR fingerprint.
     - parameter omemoDevices: a list of OMEMODevices of that buddy.
     - parameter otrFingerprints: a list of OTRFingerprints of that buddy.
    */
    @objc convenience init(buddy: OTRBuddy?, omemoDevices: [OMEMODevice]?, otrFingerprints: [OTRFingerprint]?) {
        self.init()
        self.buddy = buddy
        self.omemoDevices = omemoDevices ?? []
        self.otrFingerprints = otrFingerprints ?? []
    }

    /**
     Load all `OMEMODevice`s and `OTRFingerprint`s of the set `OTRBuddy`, *if* they are not set,
     yet.
    */
    override func viewDidLoad() {
        super.viewDidLoad()

        if omemoDevices.count < 1 && otrFingerprints.count < 1,
            let buddy = buddy, let db = OTRDatabaseManager.sharedInstance().readConnection {
            db.asyncRead() { (transaction) in
                self.omemoDevices = OMEMODevice.allDevices(
                    forParentKey: buddy.uniqueId,
                    collection: type(of: buddy).collection,
                    transaction: transaction)
                    .filter() { (device) -> Bool in
                        return device.publicIdentityKeyData != nil && device.trustLevel != .removed
                    }

                if let account = buddy.account(with: transaction) {
                    self.otrFingerprints = OTRProtocolManager.encryptionManager.otrKit.fingerprints(
                        forUsername: buddy.username,
                        accountName: account.username,
                        protocol: account.protocolTypeString())
                }

                DispatchQueue.main.async {
                    self.fingerprintsLoaded()
                }
            }
        }
        else {
            fingerprintsLoaded()
        }

        let titleView = OTRTitleSubtitleView(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        titleView.titleLabel.textColor = UIColor.white
        titleView.subtitleLabel.textColor = UIColor.white
        titleView.subtitleLabel.text = buddy?.username
        navigationItem.titleView = titleView

        avatarImg.image = buddy?.avatarImage

        //TODO: This is not the correct badge, yet.
        checkmarkImg.image = OTRImages.checkmark(with: UIColor.black).withRenderingMode(.alwaysTemplate)
    }

    /**
     Callback for when all `OMEMODevice`s and `OTRFingerprint`s of a given `OTRBuddy` are loaded.

     This needs to be overridden in your parent class!
    */
    func fingerprintsLoaded() {
        preconditionFailure("This method must be overridden")
    }

    /**
     Store a given `OMEMODevice` to the database.

     - parameter device: A `OMEMODevice` to store.
    */
    static func store(_ device: OMEMODevice) {
        if let db = OTRDatabaseManager.sharedInstance().writeConnection {
            db.asyncReadWrite() { (transaction) in
                transaction.setObject(device, forKey: device.uniqueId,
                                      inCollection: type(of: device).collection)
            }
        }
    }

    /**
     Store a given `OTRFingerprint` to wherever OTRKit stores its fingerprints.

     - parameter fingerprint: A `OTRFingerprint` to store.
    */
    static func store(_ fingerprint: OTRFingerprint) {
        OTRProtocolManager.encryptionManager.otrKit.save(fingerprint)
    }

    /**
     Set text content of label which should contain a fingerprint.

     Copious amounts of letter and line spacing are used.

     - parameter label: The `UILabel` to use.
     - parameter text: Falls back to an error message, if nil.
     - parameter alignment: Alignment used.
     - parameter bold: If bold system font should be used.
    */
    static func setFingerprint(_ label: UILabel, text: String?, alignment: NSTextAlignment, bold: Bool) {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 10
        style.alignment = alignment

        var attributes: [NSAttributedStringKey : Any] = [.kern: 3, .paragraphStyle: style]

        if bold {
            attributes[.font] = UIFont.boldSystemFont(ofSize: label.font.pointSize)
        }

        let string = text ?? NSLocalizedString(
            "CODE ERROR",
            comment: "Error message instead of key fingerprint which could not be read")

        label.attributedText = NSAttributedString(string: string.localizedUppercase,
                                                  attributes: attributes)
    }

    /**
     - returns: the buddy' `displayName` or "your buddy" as a default value, if no buddy or no
                `displayName`.
    */
    func buddyName() -> String {
        if let name = buddy?.displayName, !name.isEmpty {
            return name
        }

        return NSLocalizedString("your buddy", comment: "Verification scene default buddy name")
    }
}
