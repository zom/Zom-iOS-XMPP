//
//  ZomFingerprintVerificationCell.swift
//  Zom
//
//  Created by Benjamin Erhart on 07.03.18.
//

import UIKit
import FormatterKit

/**
 Cell to be used in `ZomVerificationDetailViewController`.

 Shows details of an `OMEMODevice` or `OTRFingerprint`.

 The user can toggle the trust state of a key aka. fingerprint aka. device using the provided
 `self.trustStatusSwitch` except on expired OMEMO keys.
*/
class ZomFingerprintVerificationCell: UITableViewCell {

    @IBOutlet weak var untrustedBadge: UILabel!
    @IBOutlet weak var trustedBadge: UILabel!
    @IBOutlet weak var infoLb: UILabel!
    @IBOutlet weak var trustStatusSwitch: UISwitch!
    @IBOutlet weak var fingerprintLb: UILabel!

    weak var delegate :ZomVerificationDetailViewController?

    private var omemoDevice: OMEMODevice?
    private var otrFingerprint: OTRFingerprint?

    override func awakeFromNib() {
        super.awakeFromNib()

        // Enforce the color. It's not enough in the XIB, propably because of the themeing.
        trustStatusSwitch.onTintColor = UIColor(a: 255, red: 63, green: 210, blue: 79)

        untrustedBadge.font = UIFont(name: "Material Icons", size: 17)
        trustedBadge.font = UIFont(name: "Material Icons", size: 17)
    }

    /**
     Set up this cell with an `OMEMODevice` key.

     - parameter device: The `OMEMODevice`
    */
    func set(_ device: OMEMODevice) {
        omemoDevice = device
        let trusted = device.isTrusted()

        untrustedBadge.isHidden = trusted
        trustedBadge.isHidden = !trusted

        var infos: [String] = []

        let interval = -Date().timeIntervalSince(device.lastSeenDate)
        infos.append(TTTTimeIntervalFormatter().string(forTimeInterval: interval))

        if device.isExpired() {
            infos.append(NSLocalizedString("Expired", comment: "Describing trust state of OMEMO key"))
        }
        else {
            infos.append(getTrustStateString(trusted))
        }

        infoLb.text = infos.joined(separator: ". ")

        trustStatusSwitch.isOn = trusted
        trustStatusSwitch.isEnabled = !device.isExpired()

        setFingerprint(device.humanReadableFingerprint, isNew: device.trustLevel == .untrustedNew)
    }

    /**
     Set up this cell with an `OTRFingerprint`.

     - parameter fingerprint: The `OTRFingerprint`
    */
    func set(_ fingerprint: OTRFingerprint) {
        otrFingerprint = fingerprint
        let trusted = fingerprint.isTrusted()

        untrustedBadge.isHidden = trusted
        trustedBadge.isHidden = !trusted

        infoLb.text = getTrustStateString(trusted)

        trustStatusSwitch.isOn = trusted
        trustStatusSwitch.isEnabled = true

        setFingerprint((fingerprint.fingerprint as NSData).humanReadableFingerprint(),
                       isNew: fingerprint.trustLevel == .untrustedNew)
    }

    /**
     Callback for trust status `UISwitch` toggle.

     (Un-)trusts current OMEMO or OTR key, depending on the new toggle state.

     Rerenders cell.
    */
    @IBAction func trustChanged() {
        if let device = omemoDevice {
            device.trustLevel = trustStatusSwitch.isOn ? .trustedUser : .untrusted
            set(device)
            ZomFingerprintBaseViewController.store(device)
        }
        else if let fingerprint = otrFingerprint {
            fingerprint.trustLevel = trustStatusSwitch.isOn ? .trustedUser : .untrustedUser
            set(fingerprint)
            ZomFingerprintBaseViewController.store(fingerprint)
        }

        delegate?.trustChanged()
    }

    /**
     Return "Trusted" or "Untrusted" depending on `trusted` argument.

     - parameter trusted: If trusted or not.
    */
    private func getTrustStateString(_ trusted: Bool) -> String {
        return trusted
            ? NSLocalizedString("Trusted", comment: "Describing trust state of OMEMO/OTR key")
            : NSLocalizedString("Untrusted", comment: "Describing trust state of OMEMO/OTR key")
    }

    /**
     Set text content of label which should contain a fingerprint.

     Copious amounts of letter and line spacing are used.

     - parameter text: The fingerprint.
     - parameter isNew: Will be printed in bold, if a new key.
    */
    func setFingerprint(_ text: String, isNew: Bool) {
        ZomFingerprintBaseViewController.setFingerprint(fingerprintLb, text: text,
                                                        alignment: .natural, bold: isNew)
    }
}
